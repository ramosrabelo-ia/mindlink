"""
MindLink - Projecao de leitos-dia por municipio (v2 - Holt-Winters)

Le o historico observado da view MINDLINK_APP.VW_MINDLINK_PRESSAO,
preenche buracos no calendario mensal, e treina um modelo de
suavizacao exponencial (Holt-Winters) por municipio -- com tendencia
e sazonalidade quando ha historico suficiente, caindo para um modelo
mais simples quando nao ha. Grava a previsao mensal (nao somada) na
tabela MINDLINK_PROJECAO_LEITOS, incluindo o metodo usado e um
intervalo de confianca aproximado.

Requisitos:
    pip install oracledb pandas numpy statsmodels

Variaveis de ambiente esperadas (mesmo padrao do .env do repo):
    ORACLE_USER, ORACLE_PASSWORD, ORACLE_DSN,
    ORACLE_WALLET_PATH, ORACLE_WALLET_PASSWORD
"""

import os
import warnings
import oracledb
import pandas as pd
import numpy as np
from statsmodels.tsa.holtwinters import ExponentialSmoothing, SimpleExpSmoothing
from dotenv import load_dotenv

warnings.filterwarnings("ignore")
load_dotenv()

# ---- configuracao ----
HORIZONTE_MESES = 6           # quantos periodos a frente prever
MIN_PONTOS_SAZONAL = 24       # >= isso: Holt-Winters com sazonalidade anual
MIN_PONTOS_TENDENCIA = 8      # >= isso (e < sazonal): so tendencia, sem sazonalidade
                               # abaixo disso: fallback para media historica


def get_connection():
    return oracledb.connect(
        user=os.environ["ORACLE_USER"],
        password=os.environ["ORACLE_PASSWORD"],
        dsn=os.environ["ORACLE_DSN"],
        config_dir=os.environ["ORACLE_WALLET_PATH"],
        wallet_location=os.environ["ORACLE_WALLET_PATH"],
        wallet_password=os.environ["ORACLE_WALLET_PASSWORD"],
    )


def carregar_historico(conn):
    """Agrega por municipio + periodo (a view e por estabelecimento/CNES)."""
    query = """
        SELECT
            codigo_ibge,
            MAX(nome_municipio) AS nome_municipio,
            id_tempo,
            SUM(saldo_leitos_dia_proxy) AS valor
        FROM mindlink_app.vw_mindlink_pressao
        WHERE saldo_leitos_dia_proxy IS NOT NULL
        GROUP BY codigo_ibge, id_tempo
        ORDER BY codigo_ibge, id_tempo
    """
    df = pd.read_sql(query, conn)
    df.columns = df.columns.str.lower()
    return df


def id_tempo_para_periodo(id_tempo):
    ano, mes = divmod(int(id_tempo), 100)
    return pd.Period(year=ano, month=mes, freq="M")


def periodo_para_id_tempo(periodo):
    return periodo.year * 100 + periodo.month


def preparar_serie(grupo):
    """Converte para serie mensal continua, preenchendo buracos por interpolacao."""
    grupo = grupo.sort_values("id_tempo")
    indice = grupo["id_tempo"].apply(id_tempo_para_periodo)
    serie = pd.Series(grupo["valor"].values, index=indice)

    faixa_completa = pd.period_range(serie.index.min(), serie.index.max(), freq="M")
    serie = serie.reindex(faixa_completa)
    serie = serie.interpolate(limit_direction="both")
    return serie


def prever_serie(serie):
    """Escolhe o metodo conforme o tamanho do historico disponivel."""
    n = len(serie)

    if n < 3:
        # historico curto demais para qualquer suavizacao: media simples,
        # sem depender do statsmodels (evita erro de dimensao em series minusculas)
        media = float(np.nanmean(serie.values))
        desvio = float(np.nanstd(serie.values)) if n > 1 else 0.0
        previsto = np.full(HORIZONTE_MESES, media)
        return np.clip(previsto, 0, None), desvio, "media_simples"

    try:
        if n >= MIN_PONTOS_SAZONAL:
            modelo = ExponentialSmoothing(
                serie.values, trend="add", seasonal="add", seasonal_periods=12,
                initialization_method="estimated",
            ).fit()
            metodo = "holt_winters_sazonal"

        elif n >= MIN_PONTOS_TENDENCIA:
            modelo = ExponentialSmoothing(
                serie.values, trend="add", seasonal=None,
                initialization_method="estimated",
            ).fit()
            metodo = "holt_tendencia"

        else:
            modelo = SimpleExpSmoothing(
                serie.values, initialization_method="estimated"
            ).fit()
            metodo = "media_suavizada"

        previsto = np.asarray(modelo.forecast(HORIZONTE_MESES)).ravel()
        previsto = np.clip(previsto, 0, None)

        residuos = serie.values - modelo.fittedvalues
        desvio = np.std(residuos) if len(residuos) > 1 else 0.0

    except Exception:
        # statsmodels falhou de forma inesperada nessa serie: cai para media simples
        # em vez de perder o municipio inteiro
        media = float(np.nanmean(serie.values))
        desvio = float(np.nanstd(serie.values))
        previsto = np.full(HORIZONTE_MESES, media)
        previsto = np.clip(previsto, 0, None)
        metodo = "media_simples_fallback"

    return previsto, desvio, metodo


def prever_municipio(grupo):
    serie = preparar_serie(grupo)
    previsto, desvio, metodo = prever_serie(serie)

    ids_futuros = [
        periodo_para_id_tempo(p)
        for p in pd.period_range(serie.index[-1] + 1, periods=HORIZONTE_MESES, freq="M")
    ]

    return pd.DataFrame({
        "codigo_ibge": grupo["codigo_ibge"].iloc[0],
        "nome_municipio": grupo["nome_municipio"].iloc[0],
        "id_tempo_previsto": ids_futuros,
        "valor_previsto": previsto,
        "intervalo_inf": np.clip(previsto - desvio, 0, None),
        "intervalo_sup": previsto + desvio,
        "metodo": metodo,
    })


def gerar_projecoes(df_historico):
    resultados = []
    for codigo_ibge, grupo in df_historico.groupby("codigo_ibge"):
        try:
            resultados.append(prever_municipio(grupo))
        except Exception as e:
            print(f"  [aviso] falhou para codigo_ibge={codigo_ibge}: {e}")
    return pd.concat(resultados, ignore_index=True)


def preparar_tabela(conn):
    with conn.cursor() as cur:
        cur.execute("""
            SELECT COUNT(*) FROM user_tables
            WHERE table_name = 'MINDLINK_PROJECAO_LEITOS'
        """)
        existe = cur.fetchone()[0]

        if not existe:
            cur.execute("""
                CREATE TABLE mindlink_projecao_leitos (
                    codigo_ibge        VARCHAR2(6),
                    nome_municipio     VARCHAR2(120),
                    id_tempo_previsto  NUMBER(6,0),
                    valor_previsto     NUMBER,
                    intervalo_inf      NUMBER,
                    intervalo_sup      NUMBER,
                    metodo             VARCHAR2(30),
                    gerado_em          DATE DEFAULT SYSDATE,
                    CONSTRAINT pk_mindlink_projecao PRIMARY KEY (codigo_ibge, id_tempo_previsto)
                )
            """)
        else:
            # tabela ja existe de uma versao anterior: garante a coluna nova
            try:
                cur.execute("ALTER TABLE mindlink_projecao_leitos ADD metodo VARCHAR2(30)")
            except oracledb.DatabaseError as e:
                if "ORA-01430" not in str(e):  # coluna ja existe: ignora
                    raise
        conn.commit()


def carregar_projecoes(conn, df_proj):
    with conn.cursor() as cur:
        cur.execute("ALTER SESSION DISABLE PARALLEL DML")
        cur.execute("DELETE FROM mindlink_projecao_leitos")
        cur.executemany(
            """
            INSERT INTO mindlink_projecao_leitos
                (codigo_ibge, nome_municipio, id_tempo_previsto,
                 valor_previsto, intervalo_inf, intervalo_sup, metodo)
            VALUES (:1, :2, :3, :4, :5, :6, :7)
            """,
            df_proj[["codigo_ibge", "nome_municipio", "id_tempo_previsto",
                     "valor_previsto", "intervalo_inf", "intervalo_sup",
                     "metodo"]].values.tolist(),
        )
        conn.commit()


def main():
    conn = get_connection()
    try:
        historico = carregar_historico(conn)
        print(f"{len(historico)} linhas de historico, "
              f"{historico['codigo_ibge'].nunique()} municipios.")

        projecoes = gerar_projecoes(historico)
        print(f"{len(projecoes)} linhas de previsao geradas.")
        print(projecoes["metodo"].value_counts().to_string())

        preparar_tabela(conn)
        carregar_projecoes(conn, projecoes)
        print("Tabela MINDLINK_PROJECAO_LEITOS atualizada com sucesso.")
    finally:
        conn.close()


if __name__ == "__main__":
    main()
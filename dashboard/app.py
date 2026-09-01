from __future__ import annotations

import os
from pathlib import Path
from typing import Any

import oracledb
from dotenv import load_dotenv
from flask import Flask, jsonify, render_template, request


ROOT = Path(__file__).resolve().parents[1]
load_dotenv(ROOT / ".env")
oracledb.defaults.fetch_lobs = False

DATA_MODE = os.getenv("MINDLINK_DATA_MODE", "demo").strip().lower()
AI_PROFILE = os.getenv("MINDLINK_AI_PROFILE", "MINDLINK_SELECT_AI").strip()
AI_ENABLED = os.getenv("MINDLINK_SELECT_AI_ENABLED", "false").lower() == "true"

app = Flask(__name__, template_folder="templates", static_folder="static")


def _wallet_path() -> str | None:
    raw = os.getenv("ORACLE_WALLET_PATH", "").strip()
    if not raw:
        return None
    path = Path(raw)
    if not path.is_absolute():
        path = ROOT / path
    return str(path.resolve())


def get_connection() -> oracledb.Connection:
    required = {name: os.getenv(name, "").strip() for name in (
        "ORACLE_USER", "ORACLE_PASSWORD", "ORACLE_DSN"
    )}
    missing = [name for name, value in required.items() if not value]
    if missing:
        raise RuntimeError("Configuração Oracle ausente: " + ", ".join(missing))

    wallet = _wallet_path()
    kwargs: dict[str, Any] = {
        "user": required["ORACLE_USER"],
        "password": required["ORACLE_PASSWORD"],
        "dsn": required["ORACLE_DSN"],
    }
    if wallet:
        kwargs.update(
            config_dir=wallet,
            wallet_location=wallet,
            wallet_password=os.getenv("ORACLE_WALLET_PASSWORD", ""),
        )
    return oracledb.connect(**kwargs)


def query(sql: str, params: dict[str, Any] | None = None) -> list[dict[str, Any]]:
    with get_connection() as connection, connection.cursor() as cursor:
        cursor.execute(sql, params or {})
        columns = [item[0].lower() for item in cursor.description]
        return [dict(zip(columns, row)) for row in cursor.fetchall()]


def _demo_payload() -> dict[str, Any]:
    return {
        "mode": "demo",
        "notice": "Dados demonstrativos. Não representam disponibilidade de leitos em tempo real.",
        "kpis": {
            "internacoes": 3305,
            "obitos": 191,
            "permanencia_dias": 76304,
            "hospitais": 281,
        },
        "trend": [
            {"competencia": "2024-01", "internacoes": 262, "obitos": 12},
            {"competencia": "2024-04", "internacoes": 279, "obitos": 14},
            {"competencia": "2024-07", "internacoes": 301, "obitos": 17},
            {"competencia": "2024-10", "internacoes": 322, "obitos": 18},
            {"competencia": "2025-01", "internacoes": 337, "obitos": 20},
            {"competencia": "2025-04", "internacoes": 361, "obitos": 23},
        ],
        "pressure": [
            {"municipio": "São Paulo", "hospital": "Hospital demonstrativo A", "pressao_pct": 74.2},
            {"municipio": "Campinas", "hospital": "Hospital demonstrativo B", "pressao_pct": 62.8},
            {"municipio": "Sorocaba", "hospital": "Hospital demonstrativo C", "pressao_pct": 51.4},
        ],
        "comorbidities": [
            {"cid": "J69", "descricao": "Pneumonite por sólidos e líquidos", "internacoes": 188},
            {"cid": "I63", "descricao": "Infarto cerebral", "internacoes": 141},
            {"cid": "S72", "descricao": "Fratura do fêmur", "internacoes": 96},
        ],
        "predictions": [],
    }


def _oracle_payload() -> dict[str, Any]:
    kpis = query("""
        SELECT SUM(QTD_INTERNACOES) INTERNACOES,
               SUM(QTD_OBITOS) OBITOS,
               SUM(DIAS_PERMANENCIA) PERMANENCIA_DIAS,
               COUNT(DISTINCT CNES) HOSPITAIS
          FROM FATO_INTERNACAO_MENSAL
    """)[0]
    trend = query("""
        SELECT TO_CHAR(TO_DATE(f.ID_TEMPO || '01', 'YYYYMMDD'), 'YYYY-MM') COMPETENCIA,
               SUM(f.QTD_INTERNACOES) INTERNACOES,
               SUM(f.QTD_OBITOS) OBITOS
          FROM FATO_INTERNACAO_MENSAL f
         GROUP BY f.ID_TEMPO
         ORDER BY f.ID_TEMPO
    """)
    pressure = query("""
        SELECT NOME_MUNICIPIO MUNICIPIO,
               NOME_ESTABELECIMENTO HOSPITAL,
               PRESSAO_DEMENCIA_PCT PRESSAO_PCT
          FROM VW_PRESSAO_HOSPITALAR
         WHERE ID_TEMPO = (SELECT MAX(ID_TEMPO) FROM VW_PRESSAO_HOSPITALAR)
           AND PRESSAO_DEMENCIA_PCT IS NOT NULL
         ORDER BY PRESSAO_DEMENCIA_PCT DESC
         FETCH FIRST 10 ROWS ONLY
    """)
    comorbidities = query("""
        SELECT f.CID_SECUNDARIO CID,
               MAX(d.DESCRICAO_CID) DESCRICAO,
               SUM(f.QTD_INTERNACOES_COM_COMORBIDADE) INTERNACOES
          FROM FATO_COMORBIDADE_MENSAL f
          JOIN DIM_DIAGNOSTICO d ON d.CODIGO_CID = f.CID_SECUNDARIO
         GROUP BY f.CID_SECUNDARIO
         ORDER BY INTERNACOES DESC
         FETCH FIRST 8 ROWS ONLY
    """)
    predictions = query("""
        SELECT p.ID_TEMPO_PREVISTO COMPETENCIA,
               p.CNES,
               e.NOME_ESTABELECIMENTO HOSPITAL,
               p.HORIZONTE_MESES,
               p.PRESSAO_PREVISTA_PCT,
               p.NIVEL_RISCO,
               p.MODELO
          FROM PREVISAO_PRESSAO_TRIMESTRAL p
          JOIN DIM_ESTABELECIMENTO e ON e.CNES = p.CNES
         ORDER BY p.DATA_GERACAO DESC, p.PRESSAO_PREVISTA_PCT DESC
         FETCH FIRST 20 ROWS ONLY
    """)
    return {
        "mode": "oracle",
        "notice": "Indicador de pressão é uma proxy analítica, não disponibilidade de leitos em tempo real.",
        "kpis": kpis,
        "trend": trend,
        "pressure": pressure,
        "comorbidities": comorbidities,
        "predictions": predictions,
    }


@app.get("/")
def home():
    return render_template("dashboard.html")


@app.get("/api/health")
def health():
    return jsonify({"status": "ok", "mode": DATA_MODE, "select_ai_enabled": AI_ENABLED})


@app.get("/api/dashboard")
def dashboard_data():
    try:
        payload = _oracle_payload() if DATA_MODE == "oracle" else _demo_payload()
        return jsonify(payload)
    except Exception as exc:
        return jsonify({"error": "Falha ao consultar o Oracle.", "detail": str(exc)}), 503


@app.post("/api/select-ai")
def select_ai():
    body = request.get_json(silent=True) or {}
    prompt = str(body.get("pergunta", "")).strip()
    if not prompt:
        return jsonify({"error": "Informe uma pergunta."}), 400
    if len(prompt) > 500:
        return jsonify({"error": "A pergunta deve ter até 500 caracteres."}), 400
    if DATA_MODE != "oracle" or not AI_ENABLED:
        return jsonify({
            "error": "Select AI ainda não está ativo neste ambiente.",
            "required": "MINDLINK_DATA_MODE=oracle e MINDLINK_SELECT_AI_ENABLED=true",
        }), 503

    try:
        with get_connection() as connection, connection.cursor() as cursor:
            result: dict[str, Any] = {}
            for action, key in (("showsql", "sql"), ("narrate", "resposta")):
                cursor.execute(
                    """SELECT DBMS_CLOUD_AI.GENERATE(
                           prompt => :prompt,
                           profile_name => :profile,
                           action => :action
                         ) FROM dual""",
                    {"prompt": prompt, "profile": AI_PROFILE, "action": action},
                )
                result[key] = cursor.fetchone()[0]
        result.update(profile=AI_PROFILE, mode="oracle")
        return jsonify(result)
    except Exception as exc:
        return jsonify({"error": "Falha no Oracle Select AI.", "detail": str(exc)}), 503


def create_app() -> Flask:
    return app


if __name__ == "__main__":
    app.run(host="127.0.0.1", port=int(os.getenv("PORT", "5000")), debug=False)


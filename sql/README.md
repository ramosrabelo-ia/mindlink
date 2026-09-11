# SQL Oracle

## Ordem principal

1. `01_ddl_mindlink_sprint3.sql`: cria staging, dimensões, fatos, constraints, índices e views.
2. `02_dml_mindlink_sprint3.sql`: carga utilizada na Sprint 3 e promoção para o modelo analítico.
3. `03_ml_previsao_mindlink.sql`: projeção de leitos-dia por município. **É um script Python** (apesar da extensão `.sql`), executado fora do banco; grava a previsão na tabela `MINDLINK_PROJECAO_LEITOS`, consumida diretamente pela página "Planejamento Preditivo" do Oracle APEX.

Os arquivos 01 e 02 exigem Oracle Database compatível e devem ser executados em schema autorizado. Faça backup ou utilize um schema de desenvolvimento antes de qualquer recarga.

## Camada preditiva (`03_ml_previsao_mindlink.sql`)

> O arquivo tem extensão `.sql` por convenção do diretório, mas o conteúdo é Python. Rode-o com o interpretador Python, não no SQL Developer.

### Por que mudou

A versão anterior criava um modelo de suavização exponencial (ESM / OML4SQL), o pacote `PKG_MINDLINK_PREVISAO` e o job `JOB_MINDLINK_PREVISAO` dentro do banco. No Autonomous Database em uso, esse modelo passou a falhar com `ORA-40342`. A camada preditiva foi movida para um job Python externo, com regressão de tendência, que alimenta uma tabela simples lida pelo APEX. A tabela `PREVISAO_PRESSAO_TRIMESTRAL` continua definida no arquivo 01, mas não é mais populada por esta etapa.

### Pré-requisitos

```bash
pip install oracledb pandas numpy scikit-learn python-dotenv
```

Variáveis de ambiente (arquivo `sql/.env`, não versionado — veja `../.env.example`):

| Variável | Uso |
|---|---|
| `ORACLE_USER`, `ORACLE_PASSWORD` | credenciais do schema |
| `ORACLE_DSN` | alias do `tnsnames.ora` (ex.: `mindlink_high`) |
| `ORACLE_WALLET_PATH` | pasta da Wallet (ex.: `../Wallet`) |
| `ORACLE_WALLET_PASSWORD` | senha da Wallet |

### O que o script faz

1. Lê o histórico observado de `MINDLINK_APP.VW_MINDLINK_PRESSAO` e agrega o `SALDO_LEITOS_DIA_PROXY` por município (`CODIGO_IBGE`) e competência (`ID_TEMPO`, formato `AAAAMM`).
2. Para cada município, ajusta uma regressão linear de tendência sobre a série. Séries com menos de 4 pontos (`MIN_PONTOS_REGRESSAO`) usam a média histórica como fallback.
3. Projeta os próximos 6 meses (`HORIZONTE_MESES`), limita valores negativos a zero e deriva um intervalo a partir do desvio-padrão da série.
4. Cria a tabela `MINDLINK_PROJECAO_LEITOS` se ela não existir e substitui todo o conteúdo pela previsão nova (`DELETE` + `INSERT`).

### Executar

```bash
cd sql
python 03_ml_previsao_mindlink.sql
```

### Saída — `MINDLINK_PROJECAO_LEITOS`

| Coluna | Conteúdo |
|---|---|
| `CODIGO_IBGE`, `NOME_MUNICIPIO` | município projetado |
| `ID_TEMPO_PREVISTO` | competência prevista (`AAAAMM`) |
| `VALOR_PREVISTO` | leitos-dia projetados |
| `INTERVALO_INF`, `INTERVALO_SUP` | faixa em torno da projeção |
| `GERADO_EM` | data da geração |

> A projeção é uma tendência linear simples por município, não um modelo preditivo validado para produção. Serve para orientar planejamento, com as mesmas limitações da proxy de pressão descritas no [README principal](../README.md).

As versões anteriores da camada preditiva (modelo ESM em PL/SQL, pacote `PKG_MINDLINK_PREVISAO`, job `JOB_MINDLINK_PREVISAO` e views `VW_MINDLINK_PREVISAO*`) continuam recuperáveis pelo histórico do Git.

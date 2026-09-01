# Dashboard MindLink

O dashboard usa Flask como camada de API. O navegador nunca recebe credenciais e nunca se conecta diretamente ao Oracle.

## Executar sem Oracle

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
python -m dashboard.app
```

Abra `http://127.0.0.1:5000`. O padrão é `MINDLINK_DATA_MODE=demo` e todo o conteúdo aparece identificado como demonstrativo.

## Conectar ao Oracle

1. Copie `.env.example` para `.env`.
2. Preencha usuário, senha, DSN e caminho do Wallet fora do GitHub.
3. Defina `MINDLINK_DATA_MODE=oracle`.
4. Execute novamente `python -m dashboard.app`.

Para habilitar perguntas em linguagem natural, execute e valide `sql/03_select_ai_setup.sql` no Database Actions e depois defina:

```text
MINDLINK_SELECT_AI_ENABLED=true
MINDLINK_AI_PROFILE=MINDLINK_SELECT_AI
```

## Rotas

| Rota | Função |
|---|---|
| `GET /api/health` | Informa modo de dados e status do Select AI |
| `GET /api/dashboard` | Entrega KPIs, série temporal, pressão, comorbidades e previsões |
| `POST /api/select-ai` | Retorna SQL gerado (`showsql`) e resposta (`narrate`) |


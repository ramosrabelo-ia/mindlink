# Evidências visuais

Esta pasta recebe apenas evidências técnicas selecionadas e sanitizadas da entrega.

## Checklist de arquivos

| Evidência | Status | O que deve aparecer |
|---|---|---|
| DAG Airflow concluída | Pendente de inclusão | Cinco tasks em `SUCCESS` e identificação da DAG |
| Log do ETL demonstrativo | Pendente de inclusão | Execução `--demo`, validações e arquivos gerados |
| Conexão Airflow → Oracle | Pendente de inclusão | Sucesso da conexão, sem Wallet ou credenciais |
| Contagem da staging | Pendente de inclusão | `STG_MINDLINK_INTERNACOES = 3305` |
| Objetos Oracle | Pendente de inclusão | Stagings, dimensões, fatos e views relevantes |
| Select AI | Pendente de validação | Pergunta, SQL gerado e resposta, sem segredos |

## Regras

- remover usuários, senhas, tokens, OCIDs, endereços privados e conteúdo do Wallet;
- usar nomes descritivos, por exemplo `01_airflow_dag_success.png`;
- evitar prints repetidos ou que não provem um critério da entrega;
- registrar neste arquivo a origem e o significado de cada imagem incluída.


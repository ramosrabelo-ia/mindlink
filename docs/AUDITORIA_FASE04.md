# Auditoria técnica — Fase 04

Auditoria do pacote técnico da MindLink realizada em 1º de setembro de 2026. O objetivo é localizar cada evidência, verificar sua função e impedir que estrutura criada seja apresentada como execução comprovada.

## Inventário: o que existe e onde deve morar

| Item | Local oficial | Situação auditada | Observação |
|---|---|---|---|
| `STG_*`, `DIM_*` e `FATO_*` | Oracle Autonomous AI Database | Evidenciadas na Sprint 3; sem reexecução Oracle nesta auditoria | DDL e DML reproduzíveis estão em `sql/`. |
| `PREVISAO_PRESSAO_TRIMESTRAL` | Oracle Autonomous AI Database | Estrutura criada no DDL; carga/modelo não comprovados | Não apresentar como previsão operacional entregue. |
| Dados que alimentaram as tabelas | Oracle; cópia técnica incorporada ao DML | A carga documentada está em `sql/02_dml_mindlink_sprint3.sql` | Bases brutas, Wallet e credenciais não devem ser versionados. |
| DDL | `sql/01_ddl_mindlink_sprint3.sql` | Presente | Cria stagings, dimensões, fatos, previsão, índices e views. |
| DML | `sql/02_dml_mindlink_sprint3.sql` | Presente | Registra a carga da entrega e promove staging para o modelo analítico. |
| ETL Python | `src/mindlink_etl_sprint3_oracle.py` | Presente e validado localmente em modo `--demo` | O ETL não substitui o DDL; a estrutura Oracle deve existir antes da carga. |
| DAG Airflow | `dags/mindlink_primeira_dag.py` | Presente; execução anterior documentada | Executa ETL demonstrativo e consulta a staging Oracle já carregada. |
| Notebook | `notebooks/EC_Sprint_3_MindLink_SheLeads_ML_FINAL.ipynb` | Presente | Evidência analítica; não equivale a modelo preditivo de produção. |
| Airflow, ambiente virtual e logs locais | Computador/ambiente de execução | Não devem ser migrados integralmente | GitHub guarda requisitos, DAG e instruções; logs úteis devem virar evidência sanitizada. |
| Relatórios e capturas | `docs/evidencias/` | Pasta organizada; arquivos visuais ainda precisam ser selecionados | Não incluir credenciais, Wallet, URLs privadas ou dados sensíveis. |

## Resultado da validação sem Oracle

Comando auditado:

```bash
python src/mindlink_etl_sprint3_oracle.py --demo
python -m pytest -q
```

Resultado reproduzido:

| Verificação | Resultado |
|---|---:|
| AIHs sintéticas analisadas | 3.000 |
| Registros relacionados à demência | 542 |
| Agregações em `STG_MINDLINK_INTERNACOES` | 526 |
| Agregações em `STG_MINDLINK_COMORBIDADES` | 603 |
| Competências | 24 (`202401–202512`) |
| Testes automatizados | 3 aprovados |

Esses números são sintéticos e provam o funcionamento do código. Eles não são resultados epidemiológicos do SIH/SUS e não substituem as contagens anteriormente evidenciadas no Oracle.

## Contagens Oracle documentadas na Sprint 3

| Camada | Objeto | Registros documentados |
|---|---|---:|
| Staging | `STG_MINDLINK_INTERNACOES` | 3.305 |
| Staging | `STG_MINDLINK_COMORBIDADES` | 1.868 |
| Staging | `STG_MINDLINK_CAPACIDADE` | 6.637 |
| Dimensão | `DIM_TEMPO` | 24 |
| Dimensão | `DIM_MUNICIPIO` | 170 |
| Dimensão | `DIM_ESTABELECIMENTO` | 281 |
| Dimensão | `DIM_DIAGNOSTICO` | 423 |
| Dimensão | `DIM_FAIXA_ETARIA` | 6 |
| Fato | `FATO_INTERNACAO_MENSAL` | 3.305 |
| Fato | `FATO_COMORBIDADE_MENSAL` | 1.868 |
| Fato | `FATO_CAPACIDADE_MENSAL` | 6.637 |

Essas contagens pertencem à evidência da entrega Oracle. Como o banco estava indisponível nesta auditoria, elas não foram consultadas novamente.

## Pendências objetivas

1. Reexecutar as consultas de contagem e integridade quando o Oracle estiver disponível.
2. Selecionar e sanitizar os prints da DAG, logs e Database Actions.
3. Copiar somente as evidências visuais necessárias para `docs/evidencias/` e preencher o manifesto da pasta.
4. Validar o perfil do Select AI sem versionar segredos.
5. Treinar e avaliar o modelo antes de afirmar que há previsão de três meses carregada.


/*
  MindLink — configuração do Oracle Select AI
  Execute bloco a bloco no Database Actions usando o mesmo schema dos objetos.
  Nunca cole uma chave real neste arquivo versionado.
*/

-- 1. Crie previamente uma credencial compatível com o provedor escolhido.
-- Exemplo conceitual, NÃO execute com o placeholder:
-- BEGIN
--   DBMS_CLOUD.CREATE_CREDENTIAL(
--     credential_name => 'MINDLINK_AI_CRED',
--     username => 'PROVIDER',
--     password => '<CHAVE_FORA_DO_GITHUB>'
--   );
-- END;
-- /

-- 2. Comentários semânticos usados pelo perfil com comments=true.
COMMENT ON TABLE FATO_INTERNACAO_MENSAL IS
'Internacoes mensais do SIH/SUS associadas a demencia no diagnostico principal ou secundario, agregadas por competencia, hospital, CID, faixa etaria e sexo.';
COMMENT ON COLUMN FATO_INTERNACAO_MENSAL.QTD_INTERNACOES IS
'Quantidade agregada de internacoes; nao corresponde necessariamente a pacientes unicos.';
COMMENT ON COLUMN FATO_INTERNACAO_MENSAL.DIAS_PERMANENCIA IS
'Soma dos dias de permanencia das internacoes agregadas.';
COMMENT ON TABLE FATO_CAPACIDADE_MENSAL IS
'Capacidade cadastrada no CNES por competencia e hospital. Leito cadastrado nao significa leito livre.';
COMMENT ON TABLE VW_PRESSAO_HOSPITALAR IS
'Proxy experimental de pressao: dias de permanencia por demencia divididos por leitos-dia SUS cadastrados. Nao representa ocupacao total nem disponibilidade em tempo real.';
COMMENT ON TABLE VW_CANDIDATOS_REALOCACAO IS
'Ranking analitico de capacidade relativa. Nao constitui indicacao clinica ou ordem de transferencia.';
COMMENT ON TABLE PREVISAO_PRESSAO_TRIMESTRAL IS
'Previsoes de pressao para horizontes de um a tres meses. Linhas so devem existir depois de modelo treinado e validado.';

-- 3. Substitua owner, provider, credential_name e model antes de executar.
-- Para preservar instalações anteriores, use um nome de perfil versionado.
BEGIN
  DBMS_CLOUD_AI.CREATE_PROFILE(
    profile_name => 'MINDLINK_SELECT_AI',
    attributes => q'~{
      "provider": "<PROVIDER>",
      "credential_name": "MINDLINK_AI_CRED",
      "model": "<MODELO_SUPORTADO>",
      "comments": true,
      "object_list": [
        {"owner":"<SCHEMA>","name":"FATO_INTERNACAO_MENSAL"},
        {"owner":"<SCHEMA>","name":"FATO_COMORBIDADE_MENSAL"},
        {"owner":"<SCHEMA>","name":"FATO_CAPACIDADE_MENSAL"},
        {"owner":"<SCHEMA>","name":"DIM_TEMPO"},
        {"owner":"<SCHEMA>","name":"DIM_MUNICIPIO"},
        {"owner":"<SCHEMA>","name":"DIM_ESTABELECIMENTO"},
        {"owner":"<SCHEMA>","name":"DIM_DIAGNOSTICO"},
        {"owner":"<SCHEMA>","name":"VW_PRESSAO_HOSPITALAR"},
        {"owner":"<SCHEMA>","name":"VW_CANDIDATOS_REALOCACAO"},
        {"owner":"<SCHEMA>","name":"PREVISAO_PRESSAO_TRIMESTRAL"}
      ]
    }~'
  );
END;
/

-- 4. Validação auditável: primeiro veja o SQL; depois gere a resposta.
SELECT DBMS_CLOUD_AI.GENERATE(
  prompt => 'Quais hospitais tiveram maior proxy de pressao no periodo mais recente?',
  profile_name => 'MINDLINK_SELECT_AI',
  action => 'showsql'
) AS SQL_GERADO FROM DUAL;

SELECT DBMS_CLOUD_AI.GENERATE(
  prompt => 'Quais hospitais tiveram maior proxy de pressao no periodo mais recente?',
  profile_name => 'MINDLINK_SELECT_AI',
  action => 'narrate'
) AS RESPOSTA FROM DUAL;


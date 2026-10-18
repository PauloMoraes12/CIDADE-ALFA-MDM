-- ============================================================
-- PROJETO: CIDADE ALFA - MASTER DATA MANAGEMENT
-- ETAPA 15: VALIDACAO ANTES DA CARGA MDM V2
-- DATA: 16/10/2026
-- OBJETIVO: Registrar o estado dos seis cidadaos antes da V2
-- ============================================================

-- ETAPA 01: CONSULTAR AS DATAS DE NASCIMENTO DA V1

SELECT ID_GOLD_CIDADAO, -- Identifica o registro mestre
       NR_CPF_CIDADAO, -- Apresenta o CPF do cidadao
       TO_CHAR(DT_NASCIMENTO, 'DD/MM/YYYY') AS DATA_NASCIMENTO -- Exibe a data de nascimento
FROM T_MDM_CIDADAO -- Consulta a tabela mestre
WHERE ID_GOLD_CIDADAO IN (1, 9, 28, 58, 76, 78) -- Seleciona os seis registros investigados
ORDER BY ID_GOLD_CIDADAO; -- Organiza os resultados

-- RESULTADO OBSERVADO EM 16/10/2026:
-- 6 registros retornados.
-- Todos apresentaram DT_NASCIMENTO = NULL.
-- Os CPFs foram conferidos com os registros da investigacao anterior.
-- Evidencia: evidencias/15_validacao_antes_carga_mdm_v2.png

-- CONCLUSAO:
-- A V1 manteve seis datas nulas, apesar da existencia
-- de datas validas em pelo menos uma das fontes.
-- Esses seis registros serao utilizados para validar
-- a nova regra de sobrevivencia de datas da V2.
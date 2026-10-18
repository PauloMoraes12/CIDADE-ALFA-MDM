-- ============================================================
-- PROJETO: CIDADE ALFA - MASTER DATA MANAGEMENT
-- ETAPA 18: VALIDACAO DOS IDENTIFICADORES MESTRES
-- DATA: 16/10/2026
-- ============================================================

-- ETAPA 01: VERIFICAR IDS MESTRES DUPLICADOS

SELECT
    ID_GOLD_CIDADAO, -- Identificador mestre do cidadao
    COUNT(*) AS QUANTIDADE -- Conta quantas vezes o ID aparece
FROM T_MDM_CIDADAO -- Consulta a tabela mestre
GROUP BY ID_GOLD_CIDADAO -- Agrupa os registros pelo identificador
HAVING COUNT(*) > 1; -- Retorna somente IDs repetidos


-- ============================================================
-- RESULTADO E EVIDENCIA - ETAPA 18
-- ============================================================

-- RESULTADO OBSERVADO:
-- Nenhuma linha retornada.
-- Quantidade de IDs mestres duplicados: 0.

-- CONCLUSAO:
-- Nao foram identificados IDs mestres duplicados
-- na tabela T_MDM_CIDADAO.

-- EVIDENCIA 18.01:
-- Arquivo: evidencias/18_01_validacao_ids_duplicados.png
-- Comprova a ausencia de IDs mestres duplicados.
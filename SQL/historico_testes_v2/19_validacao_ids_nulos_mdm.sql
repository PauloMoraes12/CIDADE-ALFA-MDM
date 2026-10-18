-- ============================================================
-- PROJETO: CIDADE ALFA - MASTER DATA MANAGEMENT
-- ETAPA 19: VALIDACAO DE IDS MESTRES NULOS
-- DATA: 16/10/2026
-- ============================================================

-- ETAPA 01: VERIFICAR IDENTIFICADORES MESTRES NULOS

SELECT
    COUNT(*) AS TOTAL_IDS_NULOS -- Conta os registros sem identificador mestre
FROM T_MDM_CIDADAO -- Consulta a tabela mestre de cidadaos
WHERE ID_GOLD_CIDADAO IS NULL; -- Filtra os identificadores nulos

-- RESULTADO OBSERVADO:
-- TOTAL_IDS_NULOS: 0.

-- CONCLUSAO:
-- Todos os 100 registros possuem identificador mestre.
-- Nenhum ID_GOLD_CIDADAO nulo foi encontrado.
-- Validacao de integridade aprovada.

-- EVIDENCIA 19.01:
-- Arquivo: evidencias/19_01_validacao_ids_nulos.png
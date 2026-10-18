-- ============================================================
-- PROJETO: CIDADE ALFA - MASTER DATA MANAGEMENT
-- ETAPA 20: VALIDACAO DAS DATAS DE NASCIMENTO
-- DATA: 16/10/2026
-- ============================================================

-- ETAPA 01: CONTAR DATAS DE NASCIMENTO NULAS

SELECT
    COUNT(*) AS TOTAL_CIDADAOS, -- Conta todos os cidadaos
    COUNT(DT_NASCIMENTO) AS DATAS_PREENCHIDAS, -- Conta datas nao nulas
    COUNT(*) - COUNT(DT_NASCIMENTO) AS DATAS_NULAS -- Conta datas nulas
FROM T_MDM_CIDADAO; -- Consulta a tabela mestre


-- RESULTADO OBSERVADO:
-- TOTAL_CIDADAOS: 100
-- DATAS_PREENCHIDAS: 94
-- DATAS_NULAS: 6

-- CONCLUSAO:
-- A tabela manteve as seis datas nulas apos o ROLLBACK.
-- A carga V2 corrigiu essas datas durante o teste.
-- As alteracoes do teste nao foram persistidas.

-- EVIDENCIA:
-- evidencias/20_01_validacao_datas_nascimento_nulas.png
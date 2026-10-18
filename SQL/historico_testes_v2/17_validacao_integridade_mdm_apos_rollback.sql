-- ============================================================
-- PROJETO: CIDADE ALFA - MASTER DATA MANAGEMENT
-- ETAPA 17: VALIDACAO DE INTEGRIDADE APOS ROLLBACK
-- DATA: 16/10/2026
-- ============================================================

-- ETAPA 01: VERIFICAR QUANTIDADE E UNICIDADE DOS CPFS

SELECT
    COUNT(*) AS TOTAL_REGISTROS, -- Conta todos os registros da tabela
    COUNT(DISTINCT NR_CPF_CIDADAO) AS CPFS_UNICOS, -- Conta os CPFs distintos
    COUNT(*) - COUNT(DISTINCT NR_CPF_CIDADAO) AS DIFERENCA -- Calcula a diferenca entre os totais
FROM T_MDM_CIDADAO; -- Consulta a tabela mestre


-- ETAPA 02: VERIFICAR CPFS NULOS

SELECT
    COUNT(*) AS TOTAL_CPFS_NULOS -- Conta registros sem CPF
FROM T_MDM_CIDADAO -- Consulta a tabela mestre
WHERE NR_CPF_CIDADAO IS NULL; -- Filtra os CPFs nulos



-- ============================================================
-- RESULTADOS OBSERVADOS - ETAPA 17
-- ============================================================

-- TOTAL_REGISTROS: 100
-- CPFS_UNICOS: 100
-- DIFERENCA: 0
-- TOTAL_CPFS_NULOS: 0

-- CONCLUSAO:
-- A tabela T_MDM_CIDADAO possui 100 registros.
-- Todos os registros possuem CPF preenchido.
-- Nao foram identificados CPFs duplicados.
-- A integridade dos CPFs foi preservada apos o teste da V2.


-- ============================================================
-- EVIDENCIAS DA ETAPA 17
-- ============================================================

-- EVIDENCIA 17.01:
-- Arquivo: evidencias/17_01_validacao_total_registros_cpfs_unicos.png
-- Comprova 100 registros, 100 CPFs distintos e diferenca zero.

-- EVIDENCIA 17.02:
-- Arquivo: evidencias/17_02_validacao_cpfs_nulos.png
-- Comprova que nenhum registro possui CPF nulo.
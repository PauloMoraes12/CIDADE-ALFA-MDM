SELECT 'PREFEITURA' AS ORIGEM,      -- Identifica a fonte Prefeitura
       COUNT(*) AS TOTAL            -- Conta os registros
FROM T_SRC_PREFEITURA_CIDADAO       -- Consulta a Prefeitura

UNION ALL                           -- Combina os resultados

SELECT 'RECEITA FEDERAL',           -- Identifica a fonte Receita
       COUNT(*)                     -- Conta os registros
FROM T_SRC_RECEITA_FEDERAL          -- Consulta a Receita

UNION ALL                           -- Combina com a terceira consulta

SELECT 'MDM CIDADAO',               -- Identifica a tabela mestre
       COUNT(*)                     -- Conta os registros consolidados
FROM T_MDM_CIDADAO;                 -- Consulta a tabela mestre
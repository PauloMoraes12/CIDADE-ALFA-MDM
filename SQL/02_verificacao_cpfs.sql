SELECT                                  -- Inicia a consulta da Prefeitura
    'PREFEITURA' AS ORIGEM,              -- Identifica a origem dos dados
    COUNT(*) AS TOTAL_REGISTROS,         -- Conta todas as linhas da tabela
    COUNT(DISTINCT CPF_PREFEITURA)       -- Conta os CPFs distintos
        AS CPFS_UNICOS                   -- Define o nome da coluna de resultado
FROM T_SRC_PREFEITURA_CIDADAO            -- Consulta a tabela da Prefeitura

UNION ALL                                -- Combina os resultados das duas fontes

SELECT                                  -- Inicia a consulta da Receita Federal
    'RECEITA FEDERAL' AS ORIGEM,         -- Identifica a origem dos dados
    COUNT(*) AS TOTAL_REGISTROS,         -- Conta todas as linhas da tabela
    COUNT(DISTINCT CPF_RECEITA)          -- Conta os CPFs distintos
        AS CPFS_UNICOS                   -- Define o nome da coluna de resultado
FROM T_SRC_RECEITA_FEDERAL;              -- Consulta a tabela da Receita Federal
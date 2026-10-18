SELECT                                  -- Inicia a consulta da Prefeitura
    'PREFEITURA' AS ORIGEM,              -- Identifica a fonte
    COUNT(*) AS TOTAL_REGISTROS,         -- Conta todas as linhas
    COUNT(CPF_PREFEITURA)                -- Conta os CPFs nao nulos
        AS CPFS_PREENCHIDOS,             -- Nomeia a coluna de CPFs preenchidos
    COUNT(*) - COUNT(CPF_PREFEITURA)     -- Calcula os CPFs nulos
        AS CPFS_NULOS                   -- Nomeia a coluna de CPFs nulos
FROM T_SRC_PREFEITURA_CIDADAO            -- Consulta a Prefeitura

UNION ALL                                -- Combina os resultados

SELECT                                  -- Inicia a consulta da Receita
    'RECEITA FEDERAL' AS ORIGEM,         -- Identifica a fonte
    COUNT(*) AS TOTAL_REGISTROS,         -- Conta todas as linhas
    COUNT(CPF_RECEITA)                   -- Conta os CPFs nao nulos
        AS CPFS_PREENCHIDOS,             -- Nomeia a coluna de CPFs preenchidos
    COUNT(*) - COUNT(CPF_RECEITA)        -- Calcula os CPFs nulos
        AS CPFS_NULOS                   -- Nomeia a coluna de CPFs nulos
FROM T_SRC_RECEITA_FEDERAL;              -- Consulta a Receita Federal
SELECT
    P.CPF_PREFEITURA AS CPF,              -- Mostra o CPF usado para relacionar os cadastros
    P.NOME_CIDADAO AS NOME_PREFEITURA,    -- Mostra o nome registrado na Prefeitura
    R.NOME_COMPLETO AS NOME_RECEITA       -- Mostra o nome registrado na Receita
FROM T_SRC_PREFEITURA_CIDADAO P           -- Define a Prefeitura como P
INNER JOIN T_SRC_RECEITA_FEDERAL R        -- Relaciona os dados da Receita, chamada R
    ON P.CPF_PREFEITURA = R.CPF_RECEITA   -- Associa os registros pelo CPF
WHERE P.NOME_CIDADAO <> R.NOME_COMPLETO   -- Seleciona somente nomes diferentes
ORDER BY P.NOME_CIDADAO;                  -- Organiza os resultados por nome

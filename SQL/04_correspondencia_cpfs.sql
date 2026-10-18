SELECT
    COUNT(*) AS TOTAL_CORRESPONDENCIAS  -- Conta os pares de registros encontrados
FROM T_SRC_PREFEITURA_CIDADAO P         -- Define a Prefeitura com o apelido P
INNER JOIN T_SRC_RECEITA_FEDERAL R      -- Relaciona a tabela da Receita, apelido R
    ON P.CPF_PREFEITURA = R.CPF_RECEITA; -- Compara os CPFs das duas fontes
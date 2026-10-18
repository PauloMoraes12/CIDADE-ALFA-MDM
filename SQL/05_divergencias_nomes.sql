SELECT
    COUNT(*) AS TOTAL_DIVERGENCIAS       -- Conta os pares com nomes diferentes
FROM T_SRC_PREFEITURA_CIDADAO P          -- Define a Prefeitura com apelido P
INNER JOIN T_SRC_RECEITA_FEDERAL R       -- Relaciona os dados da Receita
    ON P.CPF_PREFEITURA = R.CPF_RECEITA   -- Identifica os cidadaos pelo CPF
WHERE P.NOME_CIDADAO <> R.NOME_COMPLETO;  -- Filtra nomes diferentes

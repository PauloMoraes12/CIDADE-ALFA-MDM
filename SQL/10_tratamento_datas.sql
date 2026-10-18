
SELECT
    R.ID_LINHA AS ID_RECEITA,                  -- Identifica o registro da Receita Federal
    R.DT_NASCIMENTO AS DATA_RECEITA_ORIGINAL,  -- Exibe a data original da Receita
    P.DT_NASC_PREF AS DATA_PREFEITURA,        -- Exibe a data original da Prefeitura

    TO_CHAR(                                  -- Converte a data final em texto formatado
        COALESCE(                             -- Escolhe a primeira data não nula
            TO_DATE(                          -- Tenta converter a data da Receita
                R.DT_NASCIMENTO
                    DEFAULT NULL ON CONVERSION ERROR, -- Retorna NULL se a data for inválida
                'DD/MM/YYYY'                  -- Formato da data na Receita Federal
            ),
            TO_DATE(                          -- Tenta converter a data da Prefeitura
                P.DT_NASC_PREF
                    DEFAULT NULL ON CONVERSION ERROR, -- Retorna NULL se a data for inválida
                'MM/DD/YYYY'                  -- Formato da data na Prefeitura
            )
        ),
        'DD/MM/YYYY'                          -- Exibe dia, mês e ano com quatro dígitos
    ) AS DATA_CONSOLIDADA                     -- Define o nome da coluna final

FROM T_SRC_RECEITA_FEDERAL R                  -- Consulta a Receita Federal, apelido R

INNER JOIN T_SRC_PREFEITURA_CIDADAO P        -- Relaciona os registros da Prefeitura
    ON R.CPF_RECEITA = P.CPF_PREFEITURA       -- Encontra o mesmo cidadão pelo CPF

WHERE R.ID_LINHA IN (26, 74, 99)             -- Seleciona os três registros com datas inválidas

ORDER BY R.ID_LINHA;                         -- Organiza os resultados pelo identificador


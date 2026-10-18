SELECT
    P.CPF_PREFEITURA AS CPF,                 -- Identifica o cidadão pelo CPF
    P.DT_NASC_PREF AS DATA_PREFEITURA,       -- Mostra a data original da Prefeitura
    R.DT_NASCIMENTO AS DATA_RECEITA,         -- Mostra a data original da Receita

    TO_CHAR(                                 -- Formata a data consolidada
        COALESCE(                            -- Escolhe a primeira data não nula
            TO_DATE(                         -- Tenta converter a data da Receita
                R.DT_NASCIMENTO
                    DEFAULT NULL ON CONVERSION ERROR, -- Retorna NULL se inválida
                'DD/MM/YYYY'                 -- Formato utilizado pela Receita
            ),
            TO_DATE(                         -- Tenta converter a data da Prefeitura
                P.DT_NASC_PREF
                    DEFAULT NULL ON CONVERSION ERROR, -- Retorna NULL se inválida
                'MM/DD/YYYY'                 -- Formato utilizado pela Prefeitura
            )
        ),
        'DD/MM/YYYY'                         -- Exibe o ano com quatro dígitos
    ) AS DATA_CONSOLIDADA                    -- Nomeia a data final

FROM T_SRC_PREFEITURA_CIDADAO P              -- Consulta a Prefeitura

INNER JOIN T_SRC_RECEITA_FEDERAL R           -- Relaciona os dados da Receita
    ON P.CPF_PREFEITURA = R.CPF_RECEITA      -- Associa os registros pelo CPF

WHERE P.DT_NASC_PREF IS NULL;                -- Seleciona os cidadãos sem data na Prefeitura
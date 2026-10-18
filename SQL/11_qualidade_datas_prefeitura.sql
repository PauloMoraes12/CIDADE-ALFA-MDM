SELECT
    COUNT(*) AS TOTAL_REGISTROS,             -- Conta todos os cidadãos da Prefeitura
    COUNT(DT_NASC_PREF) AS DATAS_PREENCHIDAS, -- Conta as datas não nulas
    COUNT(*) - COUNT(DT_NASC_PREF)           -- Calcula quantas datas são nulas
        AS DATAS_NULAS,                     -- Nomeia a coluna de datas ausentes
    SUM(                                    -- Soma os indicadores de datas inválidas
        CASE                                -- Inicia a avaliação de cada registro
            WHEN DT_NASC_PREF IS NOT NULL   -- Considera apenas datas preenchidas
             AND VALIDATE_CONVERSION(       -- Verifica se a data pode ser convertida
                DT_NASC_PREF AS DATE,       -- Define o tipo de destino como DATE
                'MM/DD/YYYY'                -- Usa o formato original da Prefeitura
             ) = 0                          -- Identifica datas preenchidas inválidas
            THEN 1                          -- Conta uma ocorrência inválida
            ELSE 0                          -- Não conta datas válidas ou nulas
        END                                 -- Finaliza a condição
    ) AS DATAS_INVALIDAS                    -- Nomeia o total de datas inválidas
FROM T_SRC_PREFEITURA_CIDADAO;              -- Consulta a tabela da Prefeitura

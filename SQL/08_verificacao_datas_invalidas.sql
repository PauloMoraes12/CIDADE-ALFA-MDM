SELECT                                         -- Inicia a consulta
    COUNT(*) AS TOTAL_REGISTROS,                -- Conta todos os registros
    SUM(                                        -- Soma os resultados da condicao
        CASE                                    -- Inicia uma avaliacao condicional
            WHEN VALIDATE_CONVERSION(           -- Verifica se o texto pode virar uma data
                DT_NASCIMENTO AS DATE,          -- Informa a coluna e o tipo desejado
                'DD/MM/YYYY'                    -- Define o formato esperado
            ) = 0                              -- Identifica valores que nao podem ser convertidos
            THEN 1                             -- Conta 1 para cada data invalida
            ELSE 0                             -- Conta 0 para cada data valida
        END                                     -- Finaliza a avaliacao condicional
    ) AS DATAS_INVALIDAS                       -- Nomeia o resultado
FROM T_SRC_RECEITA_FEDERAL;                    -- Consulta a tabela da Receita
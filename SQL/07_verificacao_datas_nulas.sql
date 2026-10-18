SELECT                                  -- Inicia a consulta
    COUNT(*) AS TOTAL_REGISTROS,         -- Conta todos os cidadãos
    COUNT(DT_NASCIMENTO)                 -- Conta as datas não nulas
        AS DATAS_PREENCHIDAS,            -- Nomeia a coluna do resultado
    COUNT(*) - COUNT(DT_NASCIMENTO)      -- Calcula as datas nulas
        AS DATAS_NULAS                  -- Nomeia a coluna de datas nulas
FROM T_SRC_RECEITA_FEDERAL;              -- Consulta os dados da Receita Federal
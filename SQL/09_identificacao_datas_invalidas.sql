SELECT                                    -- Inicia a consulta
    ID_LINHA,                             -- Mostra o identificador do registro
    DT_NASCIMENTO                         -- Mostra a data de nascimento original
FROM T_SRC_RECEITA_FEDERAL                -- Consulta os dados da Receita Federal
WHERE VALIDATE_CONVERSION(                -- Verifica se a conversao e possivel
    DT_NASCIMENTO AS DATE,                -- Tenta interpretar o valor como data
    'DD/MM/YYYY'                          -- Define o formato esperado
) = 0;                                    -- Retorna apenas datas invalidas

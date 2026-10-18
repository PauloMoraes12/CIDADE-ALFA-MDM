        -- INICIO DA VALIDACAO DOS SEIS REGISTROS COM DATAS INVESTIGADAS NA V2
        DBMS_OUTPUT.PUT_LINE('VALIDACAO DAS DATAS - V2'); -- Exibe o titulo da validacao

        FOR r_validacao IN ( -- Percorre os seis registros investigados na V2 para verificar suas datas de nascimento
            SELECT ID_GOLD_CIDADAO, -- Identifica o cidadao
                TO_CHAR(DT_NASCIMENTO, 'DD/MM/YYYY') AS DATA_NASCIMENTO -- Formata a data para exibicao
            FROM T_MDM_CIDADAO -- Consulta os registros processados pela V2 para verificar as datas de nascimento
            WHERE ID_GOLD_CIDADAO IN (1, 9, 28, 58, 76, 78) -- Filtra os seis casos investigados
            ORDER BY ID_GOLD_CIDADAO -- Organiza pelo identificador
        ) LOOP -- Inicia a exibicao dos resultados
            DBMS_OUTPUT.PUT_LINE( -- Escreve o resultado no painel de saida
                'ID: ' || r_validacao.ID_GOLD_CIDADAO || -- Exibe o identificador
                ' | Data: ' || NVL(r_validacao.DATA_NASCIMENTO, 'NULL') -- Exibe a data ou NULL
            ); -- Finaliza a mensagem
        END LOOP; -- Encerra a validacao das seis datas
        -- FIM DA VALIDACAO DOS SEIS REGISTROS COM DATAS INVESTIGADAS NA V2
        -- ============================================================
        -- VALIDACAO V2 - REGRA 5: NR_IDADE
        -- Objetivo: Conferir idades calculadas antes do ROLLBACK
        -- ============================================================

        FOR r_idade IN (
            SELECT
                COUNT(*) AS total_cidadaos,
                COUNT(nr_idade) AS idades_preenchidas,
                COUNT(*) - COUNT(nr_idade) AS idades_nulas,
                SUM(
                    CASE
                        WHEN dt_nascimento IS NOT NULL
                            AND nr_idade IS NOT NULL
                            AND nr_idade <>
                                EXTRACT(YEAR FROM SYSDATE)
                                - EXTRACT(YEAR FROM dt_nascimento)
                                - CASE
                                    WHEN TO_CHAR(SYSDATE, 'MMDD') <
                                        TO_CHAR(dt_nascimento, 'MMDD')
                                    THEN 1
                                    ELSE 0
                                END
                        THEN 1
                        ELSE 0
                    END
                ) AS idades_incorretas
            FROM T_MDM_CIDADAO
        ) LOOP
            DBMS_OUTPUT.PUT_LINE('VALIDACAO DE IDADES - V2');
            DBMS_OUTPUT.PUT_LINE('Total de cidadaos: ' || r_idade.total_cidadaos);
            DBMS_OUTPUT.PUT_LINE('Idades preenchidas: ' || r_idade.idades_preenchidas);
            DBMS_OUTPUT.PUT_LINE('Idades nulas: ' || r_idade.idades_nulas);
            DBMS_OUTPUT.PUT_LINE('Idades incorretas: ' || r_idade.idades_incorretas);
        END LOOP;

        -- ============================================================
        -- VALIDACAO V2 - REGRA 6: NM_FAIXA_ETARIA
        -- Objetivo: Conferir a classificacao das faixas etarias
        -- ============================================================

        FOR r_faixa IN (
            SELECT
                COUNT(*) AS total_cidadaos,
                COUNT(nm_faixa_etaria) AS faixas_preenchidas,
                COUNT(*) - COUNT(nm_faixa_etaria) AS faixas_nulas,
                SUM(
                    CASE
                        WHEN DECODE(
                            nm_faixa_etaria,
                            CASE
                                WHEN nr_idade IS NULL THEN NULL
                                WHEN nr_idade BETWEEN 0 AND 2 THEN 'BEBE'
                                WHEN nr_idade BETWEEN 3 AND 11 THEN 'CRIANCA'
                                WHEN nr_idade BETWEEN 12 AND 17 THEN 'ADOLESCENTE'
                                WHEN nr_idade BETWEEN 18 AND 59 THEN 'ADULTO'
                                WHEN nr_idade >= 60 THEN 'IDOSO'
                                ELSE NULL
                            END,
                            0, 1
                        ) = 1 THEN 1
                        ELSE 0
                    END
                ) AS faixas_incorretas
            FROM T_MDM_CIDADAO
        ) LOOP
            DBMS_OUTPUT.PUT_LINE('VALIDACAO DE FAIXAS ETARIAS - V2');
            DBMS_OUTPUT.PUT_LINE('Total de cidadaos: ' || r_faixa.total_cidadaos);
            DBMS_OUTPUT.PUT_LINE('Faixas preenchidas: ' || r_faixa.faixas_preenchidas);
            DBMS_OUTPUT.PUT_LINE('Faixas nulas: ' || r_faixa.faixas_nulas);
            DBMS_OUTPUT.PUT_LINE('Faixas incorretas: ' || r_faixa.faixas_incorretas);
        END LOOP;

        -- ============================================================
        -- VALIDACAO V2 - REGRA 7: NM_SEXO
        -- Objetivo: Conferir a padronizacao e as divergencias de sexo
        -- ============================================================

        FOR r_sexo IN (
            SELECT
                COUNT(*) AS total_cidadaos,
                COUNT(m.nm_sexo) AS sexos_preenchidos,
                SUM(
                    CASE
                        WHEN m.nm_sexo <>
                            CASE UPPER(TRIM(r.sexo))
                                WHEN 'M' THEN 'MASCULINO'
                                WHEN 'F' THEN 'FEMININO'
                                ELSE 'NAO_INFORMADO'
                            END
                            OR m.nm_sexo IS NULL
                        THEN 1
                        ELSE 0
                    END
                ) AS sexos_incorretos
            FROM T_MDM_CIDADAO m
            JOIN T_SRC_RECEITA_FEDERAL r
                ON r.cpf_receita = m.nr_cpf_cidadao_mascara
        ) LOOP
            DBMS_OUTPUT.PUT_LINE('VALIDACAO DE SEXO - V2');
            DBMS_OUTPUT.PUT_LINE('Total de cidadaos: ' || r_sexo.total_cidadaos);
            DBMS_OUTPUT.PUT_LINE('Sexos preenchidos: ' || r_sexo.sexos_preenchidos);
            DBMS_OUTPUT.PUT_LINE('Sexos incorretos: ' || r_sexo.sexos_incorretos);
        END LOOP;

        -- ============================================================
        -- VALIDACAO V2 - REGRA 7: DIVERGENCIAS DE NM_SEXO
        -- Objetivo: Conferir a sinalizacao das divergencias
        -- ============================================================

        FOR r_div_sexo IN (
            SELECT
                COUNT(*) AS divergencias_encontradas,
                SUM(
                    CASE
                        WHEN m.fl_divergencia <> 'SIM'
                            OR m.fl_divergencia IS NULL
                            OR m.ds_divergencia IS NULL
                            OR INSTR(
                                m.ds_divergencia,
                                'Sexo divergente, ausente ou invalido'
                            ) = 0
                        THEN 1
                        ELSE 0
                    END
                ) AS divergencias_nao_sinalizadas
            FROM T_MDM_CIDADAO m
            JOIN T_SRC_PREFEITURA_CIDADAO p
                ON p.cpf_prefeitura = m.nr_cpf_cidadao_mascara
            JOIN T_SRC_RECEITA_FEDERAL r
                ON r.cpf_receita = p.cpf_prefeitura
            WHERE
                UPPER(TRIM(r.sexo)) NOT IN ('M', 'F')
                OR TRIM(r.sexo) IS NULL
                OR TRIM(p.sexo_pref) NOT IN ('1', '2')
                OR TRIM(p.sexo_pref) IS NULL
                OR (UPPER(TRIM(r.sexo)) = 'M'
                    AND TRIM(p.sexo_pref) = '2')
                OR (UPPER(TRIM(r.sexo)) = 'F'
                    AND TRIM(p.sexo_pref) = '1')
        ) LOOP
            DBMS_OUTPUT.PUT_LINE('VALIDACAO DE DIVERGENCIAS DE SEXO - V2');
            DBMS_OUTPUT.PUT_LINE(
                'Divergencias encontradas: ' ||
                r_div_sexo.divergencias_encontradas
            );
            DBMS_OUTPUT.PUT_LINE(
                'Divergencias nao sinalizadas: ' ||
                r_div_sexo.divergencias_nao_sinalizadas
            );
        END LOOP;


        -- ============================================================
        -- VALIDACAO V2 - REGRA 8: NM_ESTADO_CIVIL
        -- Objetivo: Conferir a padronizacao do estado civil
        -- ============================================================

        FOR r_estado_civil IN (
            SELECT
                COUNT(*) AS total_cidadaos,
                COUNT(m.nm_estado_civil) AS estados_preenchidos,
                SUM(
                    CASE
                        WHEN m.nm_estado_civil IS NULL
                            OR m.nm_estado_civil <>
                                CASE UPPER(TRIM(r.estado_civil))
                                    WHEN 'S' THEN 'SOLTEIRO'
                                    WHEN 'C' THEN 'CASADO'
                                    WHEN 'D' THEN 'DIVORCIADO'
                                    WHEN 'V' THEN 'VIUVO'
                                    WHEN 'U' THEN 'UNIAO_ESTAVEL'
                                    ELSE 'NAO_INFORMADO'
                                END
                        THEN 1
                        ELSE 0
                    END
                ) AS estados_incorretos
            FROM T_MDM_CIDADAO m
            JOIN T_SRC_RECEITA_FEDERAL r
                ON r.cpf_receita = m.nr_cpf_cidadao_mascara
        ) LOOP
            DBMS_OUTPUT.PUT_LINE('VALIDACAO DE ESTADO CIVIL - V2');
            DBMS_OUTPUT.PUT_LINE('Total de cidadaos: ' || r_estado_civil.total_cidadaos);
            DBMS_OUTPUT.PUT_LINE('Estados preenchidos: ' || r_estado_civil.estados_preenchidos);
            DBMS_OUTPUT.PUT_LINE('Estados incorretos: ' || r_estado_civil.estados_incorretos);
        END LOOP;


        -- ============================================================
        -- VALIDACAO V2 - REGRA 9: NM_ESCOLARIDADE
        -- Objetivo: Conferir a padronizacao da escolaridade
        -- Origem: T_SRC_RECEITA_FEDERAL.ESCOLARIDADE
        -- Destino: T_MDM_CIDADAO.NM_ESCOLARIDADE
        -- Consulta somente leitura
        -- ============================================================

        FOR r_escolaridade IN (
            SELECT
                COUNT(*) AS total_cidadaos,
                COUNT(m.nm_escolaridade) AS escolaridades_preenchidas,
                COUNT(*) - COUNT(m.nm_escolaridade) AS escolaridades_nulas,
                SUM(
                    CASE
                        WHEN DECODE(
                            m.nm_escolaridade,
                            CASE
                                WHEN TRIM(r.escolaridade) IS NOT NULL
                                THEN UPPER(
                                    TRIM(
                                        REGEXP_REPLACE(
                                            TRIM(r.escolaridade),
                                            '^[0-9]+[[:space:]]*-[[:space:]]*',
                                            ''
                                        )
                                    )
                                )
                                ELSE NULL
                            END,
                            0, 1
                        ) = 1
                        THEN 1
                        ELSE 0
                    END
                ) AS escolaridades_incorretas
            FROM T_MDM_CIDADAO m
            JOIN T_SRC_RECEITA_FEDERAL r
                ON r.cpf_receita = m.nr_cpf_cidadao_mascara
        ) LOOP
            DBMS_OUTPUT.PUT_LINE('VALIDACAO DE ESCOLARIDADE - V2');
            DBMS_OUTPUT.PUT_LINE('Total de cidadaos: ' || r_escolaridade.total_cidadaos);
            DBMS_OUTPUT.PUT_LINE('Escolaridades preenchidas: ' || r_escolaridade.escolaridades_preenchidas);
            DBMS_OUTPUT.PUT_LINE('Escolaridades nulas: ' || r_escolaridade.escolaridades_nulas);
            DBMS_OUTPUT.PUT_LINE('Escolaridades incorretas: ' || r_escolaridade.escolaridades_incorretas);
        END LOOP;


        -- ============================================================
        -- VALIDACAO V2 - REGRA 10: DT_CARGA
        -- Objetivo: Conferir a data e hora do processamento
        -- Origem: SYSDATE
        -- Destino: T_MDM_CIDADAO.DT_CARGA
        -- Consulta somente leitura
        -- ============================================================

        FOR r_carga IN (
            SELECT
                COUNT(*) AS total_cidadaos,
                COUNT(dt_carga) AS datas_preenchidas,
                COUNT(*) - COUNT(dt_carga) AS datas_nulas,
                MIN(dt_carga) AS primeira_data,
                MAX(dt_carga) AS ultima_data
            FROM T_MDM_CIDADAO
        ) LOOP
            DBMS_OUTPUT.PUT_LINE('VALIDACAO DE DATA DA CARGA - V2');
            DBMS_OUTPUT.PUT_LINE('Total de cidadaos: ' || r_carga.total_cidadaos);
            DBMS_OUTPUT.PUT_LINE('Datas preenchidas: ' || r_carga.datas_preenchidas);
            DBMS_OUTPUT.PUT_LINE('Datas nulas: ' || r_carga.datas_nulas);
            DBMS_OUTPUT.PUT_LINE(
                'Primeira data: ' ||
                TO_CHAR(r_carga.primeira_data, 'DD/MM/YYYY HH24:MI:SS')
            );
            DBMS_OUTPUT.PUT_LINE(
                'Ultima data: ' ||
                TO_CHAR(r_carga.ultima_data, 'DD/MM/YYYY HH24:MI:SS')
            );
        END LOOP;


        -- ============================================================
        -- VALIDACAO V2 - REGRA 1: ID_GOLD_CIDADAO
        -- Objetivo: Verificar preenchimento e unicidade dos IDs
        -- Destino: T_MDM_CIDADAO.ID_GOLD_CIDADAO
        -- Consulta somente leitura
        -- ============================================================

        FOR r_id IN (
            SELECT
                COUNT(*) AS total_cidadaos,
                COUNT(id_gold_cidadao) AS ids_preenchidos,
                COUNT(*) - COUNT(id_gold_cidadao) AS ids_nulos,
                COUNT(id_gold_cidadao)
                    - COUNT(DISTINCT id_gold_cidadao) AS ids_duplicados
            FROM T_MDM_CIDADAO
        ) LOOP
            DBMS_OUTPUT.PUT_LINE('VALIDACAO DE ID GOLD - V2');
            DBMS_OUTPUT.PUT_LINE('Total de cidadaos: ' || r_id.total_cidadaos);
            DBMS_OUTPUT.PUT_LINE('IDs preenchidos: ' || r_id.ids_preenchidos);
            DBMS_OUTPUT.PUT_LINE('IDs nulos: ' || r_id.ids_nulos);
            DBMS_OUTPUT.PUT_LINE('IDs duplicados: ' || r_id.ids_duplicados);
        END LOOP;


        -- ============================================================
        -- VALIDACAO V2 - REGRA 2: NR_CPF_CIDADAO
        -- Objetivo: Verificar preenchimento, formato e unicidade do CPF
        -- Destino: T_MDM_CIDADAO.NR_CPF_CIDADAO
        -- Consulta somente leitura
        -- ============================================================

        FOR r_cpf IN (
            SELECT
                COUNT(*) AS total_cidadaos,
                COUNT(nr_cpf_cidadao) AS cpfs_preenchidos,
                COUNT(*) - COUNT(nr_cpf_cidadao) AS cpfs_nulos,
                COUNT(nr_cpf_cidadao)
                    - COUNT(DISTINCT nr_cpf_cidadao) AS cpfs_duplicados,
                SUM(
                    CASE
                        WHEN nr_cpf_cidadao IS NOT NULL
                            AND LENGTH(TO_CHAR(nr_cpf_cidadao)) <> 11
                        THEN 1
                        ELSE 0
                    END
                ) AS cpfs_formato_incorreto
            FROM T_MDM_CIDADAO
        ) LOOP
            DBMS_OUTPUT.PUT_LINE('VALIDACAO DE CPF - V2');
            DBMS_OUTPUT.PUT_LINE('Total de cidadaos: ' || r_cpf.total_cidadaos);
            DBMS_OUTPUT.PUT_LINE('CPFs preenchidos: ' || r_cpf.cpfs_preenchidos);
            DBMS_OUTPUT.PUT_LINE('CPFs nulos: ' || r_cpf.cpfs_nulos);
            DBMS_OUTPUT.PUT_LINE('CPFs duplicados: ' || r_cpf.cpfs_duplicados);
            DBMS_OUTPUT.PUT_LINE('CPFs com formato incorreto: ' || r_cpf.cpfs_formato_incorreto);
        END LOOP;


        -- ============================================================
        -- VALIDACAO V2 - REGRA 3: NM_CIDADAO
        -- Objetivo: Verificar preenchimento e padronizacao dos nomes
        -- Destino: T_MDM_CIDADAO.NM_CIDADAO
        -- Consulta somente leitura
        -- ============================================================

        FOR r_nome IN (
            SELECT
                COUNT(*) AS total_cidadaos,
                COUNT(nm_cidadao) AS nomes_preenchidos,
                COUNT(*) - COUNT(nm_cidadao) AS nomes_nulos,
                SUM(
                    CASE
                        WHEN nm_cidadao IS NOT NULL
                            AND nm_cidadao <> UPPER(TRIM(nm_cidadao))
                        THEN 1
                        ELSE 0
                    END
                ) AS nomes_fora_padrao
            FROM T_MDM_CIDADAO
        ) LOOP
            DBMS_OUTPUT.PUT_LINE('VALIDACAO DE NOMES - V2');
            DBMS_OUTPUT.PUT_LINE('Total de cidadaos: ' || r_nome.total_cidadaos);
            DBMS_OUTPUT.PUT_LINE('Nomes preenchidos: ' || r_nome.nomes_preenchidos);
            DBMS_OUTPUT.PUT_LINE('Nomes nulos: ' || r_nome.nomes_nulos);
            DBMS_OUTPUT.PUT_LINE('Nomes fora do padrao: ' || r_nome.nomes_fora_padrao);
        END LOOP;


        -- ============================================================
        -- VALIDACAO V2 - REGRA 3: DIVERGENCIAS DE NM_CIDADAO
        -- Objetivo: Verificar a sinalizacao de nomes divergentes
        -- entre Prefeitura e Receita Federal
        -- Consulta somente leitura
        -- ============================================================

        FOR r_nome_div IN (
            SELECT
                COUNT(*) AS divergencias_encontradas,
                SUM(
                    CASE
                        WHEN m.fl_divergencia <> 'SIM'
                            OR m.fl_divergencia IS NULL
                            OR m.ds_divergencia IS NULL
                        THEN 1
                        ELSE 0
                    END
                ) AS divergencias_nao_sinalizadas
            FROM T_MDM_CIDADAO m
            JOIN T_SRC_PREFEITURA_CIDADAO p
                ON REGEXP_REPLACE(p.cpf_prefeitura, '[^0-9]', '')
                = LPAD(TO_CHAR(m.nr_cpf_cidadao), 11, '0')
            JOIN T_SRC_RECEITA_FEDERAL r
                ON r.cpf_receita = m.nr_cpf_cidadao_mascara
            WHERE UPPER(TRIM(p.nome_cidadao))
                <> UPPER(TRIM(r.nome_completo))
        ) LOOP
            DBMS_OUTPUT.PUT_LINE('VALIDACAO DE DIVERGENCIAS DE NOMES - V2');
            DBMS_OUTPUT.PUT_LINE(
                'Divergencias encontradas: ' ||
                r_nome_div.divergencias_encontradas
            );
            DBMS_OUTPUT.PUT_LINE(
                'Divergencias nao sinalizadas: ' ||
                r_nome_div.divergencias_nao_sinalizadas
            );
        END LOOP;


        -- ============================================================
        -- VALIDACAO V2 - REGRA 11: FL_DIVERGENCIA
        -- Objetivo: Verificar preenchimento, dominio e coerencia da flag
        -- Destino: T_MDM_CIDADAO.FL_DIVERGENCIA
        -- Consulta somente leitura
        -- ============================================================

        FOR r_flag IN (
            SELECT
                COUNT(*) AS total_cidadaos,
                COUNT(fl_divergencia) AS flags_preenchidas,
                SUM(
                    CASE
                        WHEN fl_divergencia IS NULL
                            OR fl_divergencia NOT IN ('SIM', 'NAO')
                        THEN 1
                        ELSE 0
                    END
                ) AS flags_invalidas,
                SUM(
                    CASE
                        WHEN fl_divergencia = 'SIM'
                            AND ds_divergencia IS NULL
                        THEN 1
                        WHEN fl_divergencia = 'NAO'
                            AND ds_divergencia IS NOT NULL
                        THEN 1
                        ELSE 0
                    END
                ) AS flags_incoerentes,
                SUM(CASE WHEN fl_divergencia = 'SIM' THEN 1 ELSE 0 END) AS total_sim,
                SUM(CASE WHEN fl_divergencia = 'NAO' THEN 1 ELSE 0 END) AS total_nao
            FROM T_MDM_CIDADAO
        ) LOOP
            DBMS_OUTPUT.PUT_LINE('VALIDACAO DE FL_DIVERGENCIA - V2');
            DBMS_OUTPUT.PUT_LINE('Total de cidadaos: ' || r_flag.total_cidadaos);
            DBMS_OUTPUT.PUT_LINE('Flags preenchidas: ' || r_flag.flags_preenchidas);
            DBMS_OUTPUT.PUT_LINE('Flags invalidas: ' || r_flag.flags_invalidas);
            DBMS_OUTPUT.PUT_LINE('Flags incoerentes: ' || r_flag.flags_incoerentes);
            DBMS_OUTPUT.PUT_LINE('Registros com SIM: ' || r_flag.total_sim);
            DBMS_OUTPUT.PUT_LINE('Registros com NAO: ' || r_flag.total_nao);
        END LOOP;


        -- ============================================================
        -- VALIDACAO V2 - REGRA 12: DS_DIVERGENCIA
        -- Objetivo: Verificar descricoes e mensagens das divergencias
        -- Destino: T_MDM_CIDADAO.DS_DIVERGENCIA
        -- Consulta somente leitura
        -- ============================================================

        FOR r_descricao IN (
            SELECT
                COUNT(*) AS total_cidadaos,

                SUM(
                    CASE
                        WHEN fl_divergencia = 'SIM'
                            AND ds_divergencia IS NOT NULL
                        THEN 1 ELSE 0
                    END
                ) AS descricoes_preenchidas,

                SUM(
                    CASE
                        WHEN fl_divergencia = 'SIM'
                            AND ds_divergencia IS NULL
                        THEN 1 ELSE 0
                    END
                ) AS descricoes_ausentes,

                SUM(
                    CASE
                        WHEN fl_divergencia = 'NAO'
                            AND ds_divergencia IS NOT NULL
                        THEN 1 ELSE 0
                    END
                ) AS descricoes_indevidas,

                SUM(
                    CASE
                        WHEN LENGTH(ds_divergencia) > 4000
                        THEN 1 ELSE 0
                    END
                ) AS descricoes_acima_limite

            FROM T_MDM_CIDADAO
        ) LOOP
            DBMS_OUTPUT.PUT_LINE('VALIDACAO DE DS_DIVERGENCIA - V2');
            DBMS_OUTPUT.PUT_LINE('Total de cidadaos: ' || r_descricao.total_cidadaos);
            DBMS_OUTPUT.PUT_LINE('Descricoes preenchidas: ' || r_descricao.descricoes_preenchidas);
            DBMS_OUTPUT.PUT_LINE('Descricoes ausentes: ' || r_descricao.descricoes_ausentes);
            DBMS_OUTPUT.PUT_LINE('Descricoes indevidas: ' || r_descricao.descricoes_indevidas);
            DBMS_OUTPUT.PUT_LINE('Descricoes acima do limite: ' || r_descricao.descricoes_acima_limite);
        END LOOP;


        -- ============================================================
        -- VALIDACAO FINAL V2 - MENSAGENS DE DIVERGENCIA DE NOMES
        -- Objetivo: Conferir a descricao especifica da Regra 3
        -- Consulta somente leitura
        -- ============================================================

        FOR r_msg_nome IN (
            SELECT
                COUNT(*) AS nomes_divergentes,
                SUM(
                    CASE
                        WHEN m.fl_divergencia <> 'SIM'
                            OR m.fl_divergencia IS NULL
                            OR m.ds_divergencia IS NULL
                            OR INSTR(
                                m.ds_divergencia,
                                'Nome do cidadao divergente entre a Receita Federal e a Prefeitura.'
                            ) = 0
                        THEN 1
                        ELSE 0
                    END
                ) AS mensagens_incorretas
            FROM T_MDM_CIDADAO m
            JOIN T_SRC_PREFEITURA_CIDADAO p
                ON p.cpf_prefeitura = m.nr_cpf_cidadao_mascara
            JOIN T_SRC_RECEITA_FEDERAL r
                ON r.cpf_receita = p.cpf_prefeitura
            WHERE UPPER(TRIM(p.nome_cidadao))
                <> UPPER(TRIM(r.nome_completo))
        ) LOOP
            DBMS_OUTPUT.PUT_LINE('VALIDACAO FINAL DAS MENSAGENS DE NOMES - V2');
            DBMS_OUTPUT.PUT_LINE('Nomes divergentes: ' || r_msg_nome.nomes_divergentes);
            DBMS_OUTPUT.PUT_LINE('Mensagens incorretas: ' || r_msg_nome.mensagens_incorretas);
        END LOOP;

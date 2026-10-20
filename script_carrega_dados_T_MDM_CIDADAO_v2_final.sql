-- ============================================================
-- BLOCO ANONIMO PL/SQL
-- Projeto  : Cidade Alfa  Master Data Management
-- Objetivo : Carga e transformacao de dados na T_MDM_CIDADAO
-- Origem   : T_SRC_PREFEITURA_CIDADAO(principal) + T_SRC_RECEITA_FEDERAL
-- Destino  : T_MDM_CIDADAO
-- ============================================================
SET SERVEROUTPUT ON SIZE 1000000

DECLARE
    -- -- Cursor principal � leitura apenas de algumas colunas da tabela de cidad�o da Prefeitura ------
    CURSOR c_seleciona_cidadao_prefeitura IS
        SELECT 	p.cpf_prefeitura,
				p.nome_cidadao,
				p.dt_nasc_pref,
				p.sexo_pref,
				p.email_pref,
				p.telefone_pref
		 FROM   t_src_prefeitura_cidadao p;

    -- -- Variavel do tipo RECORD que referencia a tabela T_MDM_CIDADAO ---------------
   v_rec_mdm_cidadao       T_MDM_CIDADAO%ROWTYPE;
   v_rec_mdm_cidadao_vazio T_MDM_CIDADAO%ROWTYPE;

    -- -- Variavel para busca na Receita Federal ---------------
   v_rec_receita       T_SRC_RECEITA_FEDERAL%ROWTYPE;
   v_rec_receita_vazio T_SRC_RECEITA_FEDERAL%ROWTYPE; -- Declara um registro auxiliar com os campos inicialmente nulos

	-- Variavel que converte a data de nascimento da prefeitura para o tipo de dado number
    v_dt_nasc_pref 	    DATE := NULL;
    v_dt_nasc_receita DATE := NULL; -- Armazena a data de nascimento convertida da Receita Federal
	
    -- -- Contadores de auditoria ------------------------------
    v_total_lidos       NUMBER := 0;

    v_total_inseridos   NUMBER := 0;
    v_total_atualizados NUMBER := 0;
    v_total_erros       NUMBER := 0;

BEGIN
/*
    DBMS_OUTPUT.PUT_LINE('============================================');
    DBMS_OUTPUT.PUT_LINE('INICIO DA CARGA para a a tabela T_MDM_CIDADAO');
    DBMS_OUTPUT.PUT_LINE('Data/Hora: ' || TO_CHAR(SYSDATE,'DD/MM/YYYY HH24:MI:SS'));
    DBMS_OUTPUT.PUT_LINE('============================================');
*/
    -- -- Loop principal e um registro da Prefeitura por vez ---
    FOR r_cidadao_prefeitura IN  c_seleciona_cidadao_prefeitura LOOP

		-- Limpa todas as variaveis record para cada linha existente no cursor r_cidadao_prefeitura
		v_rec_mdm_cidadao := v_rec_mdm_cidadao_vazio;
        v_dt_nasc_pref := NULL; -- Limpa a data da Prefeitura antes de processar o proximo cidadao
        v_dt_nasc_receita := NULL; -- Limpa a data da Receita antes de processar o proximo cidadao
        v_rec_receita := v_rec_receita_vazio; -- Reinicia os campos da Receita antes de processar o proximo cidadao
                
        -- ============================================================
        -- REGRA 11: FL_DIVERGENCIA
        -- Origem: Validacoes realizadas durante o processamento MDM
        -- Destino: T_MDM_CIDADAO.FL_DIVERGENCIA
        -- Tipo de dado: VARCHAR2(3)
        -- Obrigatoriedade: SIM
        -- Objetivo: Indicar se o registro apresenta alguma divergencia
        -- Transformacao: Atribuir SIM ou NAO conforme as validacoes
        -- Tratamento: Inicializar com NAO para cada cidadao processado
        -- Divergencia: Alterar para SIM quando uma regra identificar erro
        -- Registro: Quando NAO, DS_DIVERGENCIA deve permanecer NULL
        -- ============================================================
		v_rec_mdm_cidadao.fl_divergencia := 'NAO'; 


        -- ============================================================
        -- REGRA 12: DS_DIVERGENCIA
        -- Origem: Mensagens geradas pelas validacoes das regras MDM
        -- Destino: T_MDM_CIDADAO.DS_DIVERGENCIA
        -- Tipo de dado: VARCHAR2(4000)
        -- Obrigatoriedade: NAO
        -- Objetivo: Descrever as divergencias identificadas no registro
        -- Transformacao: Concatenar as mensagens das validacoes
        -- Tratamento: Inicializar com NULL para cada cidadao processado
        -- Divergencia: Registrar os motivos quando FL_DIVERGENCIA = SIM
        -- Registro: Manter NULL quando FL_DIVERGENCIA = NAO
        -- ============================================================
		
        v_total_lidos := v_total_lidos + 1;

        -- ============================================================
        -- REGRA 2: NR_CPF_CIDADAO
        -- Origem principal: T_SRC_PREFEITURA_CIDADAO.CPF_PREFEITURA
        -- Destino: T_MDM_CIDADAO.NR_CPF_CIDADAO
        -- Tipo de dado: NUMBER
        -- Obrigatoriedade: SIM
        -- Objetivo: Padronizar o CPF para armazenamento numerico
        -- Transformacao: Remover pontos, hifens e barras
        -- Conversao: Converter o resultado para NUMBER
        -- Tratamento: CPF invalido deve ser identificado na validacao
        -- Divergencia: Nao prevista na regra oficial
        -- ============================================================
        v_rec_mdm_cidadao.nr_cpf_cidadao := TO_NUMBER( -- Converte o CPF para NUMBER
            REPLACE( -- Remove barras
                REPLACE( -- Remove hifens
                    REPLACE( -- Remove pontos
                        TRIM(r_cidadao_prefeitura.CPF_PREFEITURA),
                        '.', ''
                    ),
                    '-', ''
                ),
                '/', ''
            )
        );
		v_rec_mdm_cidadao.nr_cpf_cidadao_mascara := r_cidadao_prefeitura.CPF_PREFEITURA;
		
		--DBMS_OUTPUT.PUT_LINE( 'CPF CONVERTIDO: ' || v_rec_mdm_cidadao.nr_cpf_cidadao || ' CPF antigo: ' || r_cidadao_prefeitura.CPF_PREFEITURA );


        -- ============================================================
        -- CONSULTA AUXILIAR: RECEITA FEDERAL
        -- Origem: T_SRC_RECEITA_FEDERAL
        -- Destino temporario: v_rec_receita
        -- Objetivo: Localizar o cidadao pelo CPF da Prefeitura
        -- Tratamento: Registrar divergencia quando o CPF nao existir
        -- ============================================================

        BEGIN -- Inicia o bloco exclusivo da consulta

            SELECT * -- Seleciona o registro da Receita Federal
            INTO v_rec_receita -- Armazena os dados encontrados
            FROM t_src_receita_federal -- Tabela consultada
            WHERE cpf_receita = r_cidadao_prefeitura.CPF_PREFEITURA -- Localiza pelo CPF
            AND ROWNUM = 1; -- Limita a um registro

        EXCEPTION -- Trata a ausencia do CPF na Receita

            WHEN NO_DATA_FOUND THEN -- Nenhum registro encontrado

                v_rec_mdm_cidadao.fl_divergencia := 'SIM'; -- Marca divergencia

                v_rec_mdm_cidadao.ds_divergencia :=
                    v_rec_mdm_cidadao.ds_divergencia || -- Preserva mensagens anteriores
                    'CPF nao encontrado na Receita Federal. '; -- Registra o motivo

END; -- Finaliza a consulta auxiliar
                
        -- ============================================================
        -- REGRA 3: NM_CIDADAO
        -- Origem principal: T_SRC_RECEITA_FEDERAL.NOME_COMPLETO
        -- Origem de comparacao: T_SRC_PREFEITURA_CIDADAO.NOME_CIDADAO
        -- Destino: T_MDM_CIDADAO.NM_CIDADAO
        -- Tipo de dado: VARCHAR2(200)
        -- Obrigatoriedade: SIM
        -- Objetivo: Padronizar o nome e identificar divergencias
        -- Transformacao: Aplicar UPPER e TRIM aos nomes
        -- Tratamento: Priorizar Receita quando os nomes forem iguais
        -- Tratamento: Usar Prefeitura se Receita estiver sem nome ou houver divergencia
        -- Divergencia: Registrar nome ausente ou diferente entre as fontes
        -- ============================================================
			
			-- Define o nome usando a Receita como prioridade e a Prefeitura como alternativa
			v_rec_mdm_cidadao.nm_cidadao := NVL(
                UPPER(TRIM(v_rec_receita.nome_completo)), -- Prioriza o nome da Receita
                UPPER(TRIM(r_cidadao_prefeitura.nome_cidadao)) -- Usa a Prefeitura se a Receita estiver sem nome
            );
			
			IF TRIM(r_cidadao_prefeitura.nome_cidadao) IS NULL THEN -- Verifica nome ausente na Prefeitura
                v_rec_mdm_cidadao.fl_divergencia := 'SIM'; -- Sinaliza a divergencia

                v_rec_mdm_cidadao.ds_divergencia :=
                    v_rec_mdm_cidadao.ds_divergencia || -- Preserva mensagens anteriores
                    'Nome do cidadão não localizado na base de dados da Prefeitura. '; -- Mensagem exigida pela FIAP
            END IF; -- Finaliza a verificacao do nome da Prefeitura

            IF TRIM(v_rec_receita.nome_completo) IS NULL THEN -- Verifica nome ausente na Receita
                v_rec_mdm_cidadao.fl_divergencia := 'SIM'; -- Sinaliza a divergencia

                v_rec_mdm_cidadao.ds_divergencia :=
                v_rec_mdm_cidadao.ds_divergencia || -- Preserva mensagens anteriores
                'Nome do cidadao ausente na Receita Federal. '; -- Registra a ausencia
			ELSIF TRIM(r_cidadao_prefeitura.nome_cidadao) IS NOT NULL -- Prefeitura possui nome
                AND UPPER(TRIM(r_cidadao_prefeitura.nome_cidadao)) <> -- Compara os nomes normalizados
                    UPPER(TRIM(v_rec_receita.nome_completo)) THEN -- Receita possui nome
                        v_rec_mdm_cidadao.nm_cidadao := UPPER(TRIM(r_cidadao_prefeitura.nome_cidadao)); -- Prioriza o nome da Prefeitura quando existe divergencia
                        v_rec_mdm_cidadao.fl_divergencia := 'SIM';
                        v_rec_mdm_cidadao.ds_divergencia := v_rec_mdm_cidadao.ds_divergencia ||
                        'Nome do cidadao divergente entre a Receita Federal e a Prefeitura. ';
			END IF;

        -- ============================================================
        -- REGRA 4: DT_NASCIMENTO
        -- Origem principal: T_SRC_RECEITA_FEDERAL.DT_NASCIMENTO
        -- Formato Receita Federal: DD/MM/YYYY
        -- Origem de comparacao: T_SRC_PREFEITURA_CIDADAO.DT_NASC_PREF
        -- Formato Prefeitura: MM/DD/YYYY
        -- Destino: T_MDM_CIDADAO.DT_NASCIMENTO
        -- Tipo de dado: DATE
        -- Obrigatoriedade: NAO
        -- Objetivo: Validar e comparar as datas de nascimento das fontes
        -- Transformacao: Converter os textos para DATE com TO_DATE
        -- Tratamento: Gravar NULL quando alguma data for ausente ou invalida
        -- Divergencia: Gravar NULL quando as datas forem diferentes
        -- Registro: Marcar FL_DIVERGENCIA = SIM e informar o motivo
        -- ============================================================

            IF TRIM(v_rec_receita.DT_NASCIMENTO) IS NOT NULL THEN -- Verifica se a Receita informou uma data
                v_dt_nasc_receita := TO_DATE( -- Tenta converter a data da Receita
                    TRIM(v_rec_receita.DT_NASCIMENTO) DEFAULT NULL ON CONVERSION ERROR, -- Retorna NULL se a conversao falhar
                    'FXDD/MM/YYYY'); -- Exige o formato exato de data da Receita Federal
            END IF; -- Finaliza a validacao da Receita

            IF TRIM(r_cidadao_prefeitura.DT_NASC_PREF) IS NOT NULL THEN -- Verifica se a Prefeitura informou uma data
                v_dt_nasc_pref := TO_DATE( -- Tenta converter a data da Prefeitura
                    TRIM(r_cidadao_prefeitura.DT_NASC_PREF) DEFAULT NULL ON CONVERSION ERROR, -- Retorna NULL se a conversao falhar
                    'FXMM/DD/YYYY'); -- Exige o formato exato da data da Prefeitura
            END IF; -- Finaliza a validacao da Prefeitura

            IF v_dt_nasc_receita IS NOT NULL -- Verifica se a Receita possui data valida
                AND v_dt_nasc_pref IS NOT NULL -- Verifica se a Prefeitura possui data valida
                AND v_dt_nasc_receita = v_dt_nasc_pref THEN -- Confirma que as datas sao iguais

                v_rec_mdm_cidadao.dt_nascimento := v_dt_nasc_receita; -- Grava a data validada

            ELSE -- Executa quando alguma data e invalida, ausente ou diferente

                v_rec_mdm_cidadao.dt_nascimento := NULL; -- Nao grava uma data sem concordancia

            END IF; -- Finaliza a escolha da data

            IF v_dt_nasc_pref IS NULL THEN -- Verifica data ausente ou invalida na Prefeitura
                v_rec_mdm_cidadao.fl_divergencia := 'SIM'; -- Sinaliza divergencia

                v_rec_mdm_cidadao.ds_divergencia :=
                    v_rec_mdm_cidadao.ds_divergencia || -- Preserva mensagens anteriores
                    'Data de nascimento não localizada na base de dados da Prefeitura. '; -- Mensagem da FIAP
            END IF; -- Finaliza verificacao da Prefeitura

            IF v_dt_nasc_receita IS NULL THEN -- Verifica data ausente ou invalida na Receita
                v_rec_mdm_cidadao.fl_divergencia := 'SIM'; -- Sinaliza divergencia

                v_rec_mdm_cidadao.ds_divergencia :=
                    v_rec_mdm_cidadao.ds_divergencia || -- Preserva mensagens anteriores
                    'Data de nascimento ausente ou invalida na Receita Federal. '; -- Registra problema
            END IF; -- Finaliza verificacao da Receita

            IF v_dt_nasc_receita IS NOT NULL -- Receita possui data valida
                AND v_dt_nasc_pref IS NOT NULL -- Prefeitura possui data valida
                AND v_dt_nasc_receita <> v_dt_nasc_pref THEN -- Datas diferentes

                v_rec_mdm_cidadao.fl_divergencia := 'SIM'; -- Sinaliza divergencia

                v_rec_mdm_cidadao.ds_divergencia :=
                    v_rec_mdm_cidadao.ds_divergencia || -- Preserva mensagens anteriores
                    'Data de nascimento divergente entre a Receita Federal e a Prefeitura. '; -- Mensagem da FIAP
            END IF; -- Finaliza comparacao das datas
                
        -- ============================================================
        -- REGRA 5: NR_IDADE
        -- Origem: T_MDM_CIDADAO.DT_NASCIMENTO
        -- Destino: T_MDM_CIDADAO.NR_IDADE
        -- Tipo de dado: NUMBER(3)
        -- Obrigatoriedade: NAO
        -- Objetivo: Calcular a idade atual do cidadao em anos completos
        -- Transformacao: Calcular a diferenca entre a data atual e o nascimento
        -- Tratamento: Gravar NULL quando a data for ausente ou invalida
        -- Validacao: Nao calcular idade para datas futuras
        -- Divergencia: Marcar FL_DIVERGENCIA = SIM quando a idade for invalida
        -- Registro: Acrescentar o motivo em DS_DIVERGENCIA
        -- ============================================================

        IF v_rec_mdm_cidadao.dt_nascimento IS NOT NULL -- Verifica se existe uma data valida
            AND v_rec_mdm_cidadao.dt_nascimento <= TRUNC(SYSDATE) THEN -- Impede calcular idade de quem ainda nao nasceu
            v_rec_mdm_cidadao.nr_idade := -- Calcula a idade em anos completos
                EXTRACT(YEAR FROM SYSDATE) - EXTRACT(YEAR FROM v_rec_mdm_cidadao.dt_nascimento) -- Calcula a diferenca de anos
                - CASE -- Verifica se o aniversario ja ocorreu
                    WHEN TO_CHAR(SYSDATE, 'MMDD') <
                        TO_CHAR(v_rec_mdm_cidadao.dt_nascimento, 'MMDD') THEN 1 -- Ainda nao fez aniversario
                    ELSE 0 -- Ja fez aniversario
                END; -- Finaliza o calculo da idade
        ELSE -- Executa quando nao e possivel calcular a idade
            v_rec_mdm_cidadao.nr_idade := NULL; -- Mantem a idade nula

            v_rec_mdm_cidadao.fl_divergencia := 'SIM'; -- Sinaliza idade invalida

            v_rec_mdm_cidadao.ds_divergencia :=
                v_rec_mdm_cidadao.ds_divergencia || -- Preserva as divergencias anteriores
                'Idade do cidadao(ã) invalida e o conteudo foi gravado como nulo. '; -- Registra o motivo
        END IF; -- Finaliza a regra de idade


        -- ============================================================
        -- REGRA 6: NM_FAIXA_ETARIA
        -- Origem: T_MDM_CIDADAO.NR_IDADE
        -- Destino: T_MDM_CIDADAO.NM_FAIXA_ETARIA
        -- Tipo de dado: VARCHAR2(20)
        -- Obrigatoriedade: NAO
        -- Objetivo: Classificar o cidadao conforme sua idade
        -- Transformacao: Aplicar as faixas etarias definidas pela FIAP
        -- Faixa 0 a 2 anos: BEBE
        -- Faixa 3 a 11 anos: CRIANCA
        -- Faixa 12 a 17 anos: ADOLESCENTE
        -- Faixa 18 a 59 anos: ADULTO
        -- Faixa 60 anos ou mais: IDOSO
        -- Tratamento: Gravar NULL quando a idade for invalida ou ausente
        -- Divergencia: Marcar FL_DIVERGENCIA = SIM para idade invalida
        -- Registro: Acrescentar o motivo em DS_DIVERGENCIA
        -- ============================================================

        CASE -- Inicia a classificacao da faixa etaria
            WHEN v_rec_mdm_cidadao.nr_idade IS NULL THEN -- Idade nao calculada
                v_rec_mdm_cidadao.nm_faixa_etaria := NULL; -- Mantem a faixa etaria nula
                v_rec_mdm_cidadao.fl_divergencia := 'SIM'; -- Sinaliza faixa etaria invalida
                v_rec_mdm_cidadao.ds_divergencia :=
                v_rec_mdm_cidadao.ds_divergencia || -- Preserva as divergencias anteriores
                'Faixa etaria invalida e o conteudo foi gravado como nulo. '; -- Registra o motivo

            WHEN v_rec_mdm_cidadao.nr_idade BETWEEN 0 AND 2 THEN -- De 0 a 2 anos
                v_rec_mdm_cidadao.nm_faixa_etaria := 'BEBE'; -- Classifica como bebe

            WHEN v_rec_mdm_cidadao.nr_idade BETWEEN 3 AND 11 THEN -- De 3 a 11 anos
                v_rec_mdm_cidadao.nm_faixa_etaria := 'CRIANCA'; -- Classifica como crianca

            WHEN v_rec_mdm_cidadao.nr_idade BETWEEN 12 AND 17 THEN -- De 12 a 17 anos
                v_rec_mdm_cidadao.nm_faixa_etaria := 'ADOLESCENTE'; -- Classifica como adolescente

            WHEN v_rec_mdm_cidadao.nr_idade BETWEEN 18 AND 59 THEN -- De 18 a 59 anos
                v_rec_mdm_cidadao.nm_faixa_etaria := 'ADULTO'; -- Classifica como adulto

            WHEN v_rec_mdm_cidadao.nr_idade >= 60 THEN -- A partir de 60 anos
                v_rec_mdm_cidadao.nm_faixa_etaria := 'IDOSO'; -- Classifica como idoso
            
            ELSE -- Trata idades fora dos intervalos validos
                v_rec_mdm_cidadao.nm_faixa_etaria := NULL; -- Nao atribui classificacao

                v_rec_mdm_cidadao.fl_divergencia := 'SIM'; -- Sinaliza faixa etaria invalida

                v_rec_mdm_cidadao.ds_divergencia :=
                v_rec_mdm_cidadao.ds_divergencia || -- Preserva divergencias anteriores
                'Faixa etaria invalida e o conteudo foi gravado como nulo. '; -- Registra o motivo
        END CASE; -- Finaliza a classificacao
        -- ----------------------------------------------------

        -- ============================================================
        -- REGRA 7: NM_SEXO
        -- Origem principal: T_SRC_RECEITA_FEDERAL.SEXO
        -- Origem de comparacao: T_SRC_PREFEITURA_CIDADAO.SEXO_PREF
        -- Destino: T_MDM_CIDADAO.NM_SEXO
        -- Tipo de dado: VARCHAR2(20)
        -- Obrigatoriedade: SIM
        -- Objetivo: Padronizar o sexo e identificar divergencias
        -- Transformacao Receita: M = MASCULINO / F = FEMININO
        -- Comparacao Prefeitura: 1 = MASCULINO / 2 = FEMININO
        -- Tratamento: Gravar NAO_INFORMADO para codigo ausente ou invalido
        -- Divergencia: Identificar valores ausentes, invalidos ou diferentes
        -- Registro: Marcar FL_DIVERGENCIA = SIM e informar o motivo
        -- ============================================================

        CASE UPPER(TRIM(v_rec_receita.sexo)) -- Verifica o sexo informado pela Receita Federal
            WHEN 'M' THEN -- Codigo masculino
                v_rec_mdm_cidadao.nm_sexo := 'MASCULINO'; -- Converte para masculino
            WHEN 'F' THEN -- Codigo feminino
                v_rec_mdm_cidadao.nm_sexo := 'FEMININO'; -- Converte para feminino
            ELSE -- Codigo ausente ou desconhecido
                v_rec_mdm_cidadao.nm_sexo := 'NAO_INFORMADO'; -- Define valor padrao
        END CASE; -- Finaliza a conversao do sexo


        -- ============================================================
        -- REGRA 7: VERIFICACAO DE DIVERGENCIA DO SEXO
        -- Prefeitura: 1 = Masculino / 2 = Feminino
        -- Receita: M = Masculino / F = Feminino
        -- ============================================================

        IF UPPER(TRIM(v_rec_receita.sexo)) NOT IN ('M', 'F') -- Verifica codigo invalido na Receita
            OR TRIM(v_rec_receita.sexo) IS NULL -- Identifica sexo ausente ou preenchido apenas com espacos na Receita
            OR TRIM(r_cidadao_prefeitura.sexo_pref) NOT IN ('1', '2') -- Verifica codigo invalido na Prefeitura
            OR TRIM(r_cidadao_prefeitura.sexo_pref) IS NULL -- Verifica ausencia de sexo ou espacos na Prefeitura
            OR (UPPER(TRIM(v_rec_receita.sexo)) = 'M' -- Receita informa masculino
                AND TRIM(r_cidadao_prefeitura.sexo_pref) = '2') -- Prefeitura informa feminino
            OR (UPPER(TRIM(v_rec_receita.sexo)) = 'F' -- Receita informa feminino
                AND TRIM(r_cidadao_prefeitura.sexo_pref) = '1') -- Prefeitura informa masculino
        THEN -- Identifica divergencia ou valor invalido

            v_rec_mdm_cidadao.fl_divergencia := 'SIM'; -- Sinaliza divergencia

            v_rec_mdm_cidadao.ds_divergencia :=
                v_rec_mdm_cidadao.ds_divergencia ||
                'Sexo divergente, ausente ou invalido entre Receita Federal e Prefeitura. '; -- Registra o motivo

        END IF; -- Finaliza a verificacao

        -- ============================================================
        -- REGRA 8: NM_ESTADO_CIVIL
        -- Origem: T_SRC_RECEITA_FEDERAL.ESTADO_CIVIL
        -- Destino: T_MDM_CIDADAO.NM_ESTADO_CIVIL
        -- Tipo de dado: VARCHAR2(20)
        -- Obrigatoriedade: NAO
        -- Objetivo: Padronizar o estado civil informado pela Receita
        -- Transformacao: Converter os codigos para valores descritivos
        -- Codigo S: SOLTEIRO(A)
        -- Codigo C: CASADO(A)
        -- Codigo D: DIVORCIADO(A)
        -- Codigo V: VIÚVO(A)
        -- Codigo U: UNIÃO ESTÁVEL
        -- Tratamento: Gravar NAO_INFORMADO para codigo ausente ou invalido
        -- Divergencia: Marcar FL_DIVERGENCIA = SIM para codigo invalido
        -- Registro: Acrescentar o motivo em DS_DIVERGENCIA
        -- ============================================================
        CASE UPPER(TRIM(v_rec_receita.ESTADO_CIVIL))
            WHEN 'S' THEN v_rec_mdm_cidadao.nm_estado_civil := 'SOLTEIRO'; -- Solteiro(a)
            WHEN 'C' THEN v_rec_mdm_cidadao.nm_estado_civil := 'CASADO'; -- Casado(a)
            WHEN 'D' THEN v_rec_mdm_cidadao.nm_estado_civil := 'DIVORCIADO'; -- Divorciado(a)
            WHEN 'V' THEN v_rec_mdm_cidadao.nm_estado_civil := 'VIUVO'; -- Viuvo(a)
            WHEN 'U' THEN v_rec_mdm_cidadao.nm_estado_civil := 'UNIAO_ESTAVEL'; -- Uniao estavel
           
		ELSE
           v_rec_mdm_cidadao.nm_estado_civil := 'NAO_INFORMADO';
           v_rec_mdm_cidadao.fl_divergencia  := 'SIM';
           v_rec_mdm_cidadao.ds_divergencia  := v_rec_mdm_cidadao.ds_divergencia ||
           'Dominio de estado civil nao reconhecido, sendo gravado como NAO_INFORMADO. ';
        END CASE;
                
        -- ============================================================
        -- REGRA 9: NM_ESCOLARIDADE
        -- Origem: T_SRC_RECEITA_FEDERAL.ESCOLARIDADE
        -- Destino: T_MDM_CIDADAO.NM_ESCOLARIDADE
        -- Tipo de dado: VARCHAR2(30)
        -- Obrigatoriedade: NAO
        -- Objetivo: Padronizar a escolaridade informada pela Receita
        -- Transformacao: Remover o prefixo numerico e o hifen
        -- Padronizacao: Aplicar UPPER e TRIM ao texto resultante
        -- Tratamento: Gravar NULL quando a escolaridade estiver ausente
        -- Divergencia: Nao se aplica comparacao entre fontes
        -- Registro: Nao gerar divergencia apenas por escolaridade ausente
        -- ============================================================

        IF TRIM(v_rec_receita.escolaridade) IS NOT NULL THEN -- Verifica se existe escolaridade
            v_rec_mdm_cidadao.nm_escolaridade := UPPER( -- Converte a descricao para maiusculas
                TRIM( -- Remove espacos no inicio e no fim
                    REGEXP_REPLACE( -- Remove o codigo numerico e o hifen iniciais
                        TRIM(v_rec_receita.escolaridade), -- Obtem o valor original
                        '^[0-9]+[[:space:]]*-[[:space:]]*', '' -- Retira o prefixo numerico
                    )
                )
            ); -- Finaliza a transformacao
        ELSE -- Executa quando a origem esta vazia
            v_rec_mdm_cidadao.nm_escolaridade := NULL; -- Mantem o destino nulo
        END IF; -- Finaliza a regra de escolaridade

        -- ============================================================
        -- REGRA 10: DT_CARGA
        -- Origem: Data e hora do servidor Oracle
        -- Destino: T_MDM_CIDADAO.DT_CARGA
        -- Tipo de dado: DATE
        -- Obrigatoriedade: SIM
        -- Objetivo: Registrar quando o registro mestre foi processado
        -- Transformacao: Utilizar a funcao SYSDATE
        -- Tratamento: Atualizar a data e hora em cada processamento
        -- Divergencia: Nao se aplica
        -- ============================================================
		v_rec_mdm_cidadao.dt_carga := SYSDATE; -- Registra a data e hora atuais da carga no formato DATE

		-- ============================================================
        -- REGRA 1: ID_GOLD_CIDADAO
        -- Origem: Sequencia SQ_MDM_CIDADAO
        -- Destino: T_MDM_CIDADAO.ID_GOLD_CIDADAO
        -- Tipo de dado: NUMBER
        -- Obrigatoriedade: SIM
        -- Objetivo: Identificar de forma unica cada registro mestre
        -- Transformacao: Gerar SQ_MDM_CIDADAO.NEXTVAL apenas no INSERT
        -- Tratamento: Preservar o identificador existente no UPDATE
        -- Divergencia: Nao se aplica
        -- ============================================================

        -- ============================================================
        -- GRAVACAO NA T_MDM_CIDADAO
        -- Estrategia V2: Primeiro executar UPDATE pelo CPF
        -- Tratamento: Se nenhum registro for atualizado, executar INSERT
        -- ============================================================
        BEGIN -- Inicia o bloco de gravacao V2
            UPDATE T_MDM_CIDADAO SET -- Tenta atualizar o cidadao existente
                NM_CIDADAO = v_rec_mdm_cidadao.nm_cidadao, -- Atualiza o nome
                DT_NASCIMENTO = v_rec_mdm_cidadao.dt_nascimento, -- Atualiza a data de nascimento
                NR_IDADE = v_rec_mdm_cidadao.nr_idade, -- Atualiza a idade calculada do cidadao
                NM_FAIXA_ETARIA = v_rec_mdm_cidadao.nm_faixa_etaria, -- Atualiza a classificacao etaria do cidadao
                NM_SEXO = v_rec_mdm_cidadao.nm_sexo, -- Atualiza o sexo normalizado do cidadao
                NM_ESTADO_CIVIL = v_rec_mdm_cidadao.nm_estado_civil, -- Atualiza o estado civil
                NM_ESCOLARIDADE = v_rec_mdm_cidadao.nm_escolaridade, -- Atualiza a escolaridade normalizada do cidadao
                DT_CARGA = v_rec_mdm_cidadao.dt_carga, -- Atualiza a data da carga
                FL_DIVERGENCIA = v_rec_mdm_cidadao.fl_divergencia, -- Atualiza a flag
                DS_DIVERGENCIA = v_rec_mdm_cidadao.ds_divergencia -- Atualiza a descricao
            WHERE NR_CPF_CIDADAO = v_rec_mdm_cidadao.nr_cpf_cidadao; -- Localiza pelo CPF

            IF SQL%ROWCOUNT > 0 THEN -- Verifica se algum registro foi atualizado
                v_total_atualizados := v_total_atualizados + SQL%ROWCOUNT; -- Conta as atualizacoes
            ELSE -- Executa quando o CPF ainda nao existe no MDM
                INSERT INTO T_MDM_CIDADAO ( -- Insere um novo cidadao
                    ID_GOLD_CIDADAO, -- Identificador do registro mestre
                    NR_CPF_CIDADAO, -- CPF numerico
                    NR_CPF_CIDADAO_MASCARA, -- CPF formatado
                    NM_CIDADAO, -- Nome do cidadao
                    DT_NASCIMENTO, -- Data de nascimento
                    NR_IDADE, -- Idade calculada do cidadao
                    NM_FAIXA_ETARIA, -- Classificacao etaria do cidadao
                    NM_SEXO, -- Sexo normalizado do cidadao
                    NM_ESTADO_CIVIL, -- Estado civil
                    NM_ESCOLARIDADE, -- Escolaridade normalizada do cidadao
                    DT_CARGA, -- Data da carga
                    FL_DIVERGENCIA, -- Indicador de divergencia
                    DS_DIVERGENCIA -- Descricao das divergencias
                ) VALUES ( -- Inicia os valores do novo registro
                    SQ_MDM_CIDADAO.NEXTVAL, -- Gera ID somente para insercao
                    v_rec_mdm_cidadao.nr_cpf_cidadao, -- Informa o CPF numerico
                    v_rec_mdm_cidadao.nr_cpf_cidadao_mascara, -- Informa o CPF formatado
                    v_rec_mdm_cidadao.nm_cidadao, -- Informa o nome
                    v_rec_mdm_cidadao.dt_nascimento, -- Informa a data de nascimento
                    v_rec_mdm_cidadao.nr_idade, -- Informa a idade calculada do cidadao
                    v_rec_mdm_cidadao.nm_faixa_etaria, -- Informa a classificacao etaria do cidadao
                    v_rec_mdm_cidadao.nm_sexo, -- Informa o sexo normalizado do cidadao
                    v_rec_mdm_cidadao.nm_estado_civil, -- Informa o estado civil
                    v_rec_mdm_cidadao.nm_escolaridade, -- Informa a escolaridade normalizada do cidadao
                    v_rec_mdm_cidadao.dt_carga, -- Informa a data da carga
                    v_rec_mdm_cidadao.fl_divergencia, -- Informa a flag
                    v_rec_mdm_cidadao.ds_divergencia -- Informa a descricao
                ); -- Finaliza a insercao

                v_total_inseridos := v_total_inseridos + 1; -- Conta a nova insercao
            END IF; -- Finaliza a decisao entre atualizar e inserir

        EXCEPTION -- Inicia o tratamento de erros
            WHEN OTHERS THEN -- Captura erros inesperados de gravacao
                v_total_erros := v_total_erros + 1; -- Conta o erro
                DBMS_OUTPUT.PUT_LINE( -- Exibe o erro encontrado
                    'ERRO NA GRAVACAO CPF: ' || v_rec_mdm_cidadao.nr_cpf_cidadao || -- Identifica o CPF
                    ' | Erro: ' || SQLERRM -- Mostra a mensagem do Oracle
                ); -- Finaliza a mensagem
                RAISE; -- Interrompe a carga para permitir o ROLLBACK geral
        END; -- Finaliza o bloco de gravacao V2

/*
		DBMS_OUTPUT.PUT_LINE( v_rec_mdm_cidadao.id_gold_cidadao || chr(10) || v_rec_mdm_cidadao.nr_cpf_cidadao || chr(10) || 
		v_rec_mdm_cidadao.nr_cpf_cidadao_mascara
		|| chr(10) || v_rec_mdm_cidadao.nm_cidadao || chr(10) || v_rec_mdm_cidadao.fl_divergencia || chr(10) || v_rec_mdm_cidadao.ds_divergencia
		|| chr(10) || v_rec_mdm_cidadao.dt_nascimento || chr(10) || v_rec_mdm_cidadao.nm_estado_civil || chr(10) || v_rec_mdm_cidadao.dt_carga);
*/

		END LOOP; -- fim cursor

        
        COMMIT;
        -- ROLLBACK;

    -- -- Relatorio final --------------------------------------
    DBMS_OUTPUT.PUT_LINE(' ');
    DBMS_OUTPUT.PUT_LINE('============================================');
    DBMS_OUTPUT.PUT_LINE('RESULTADO DO PROCESSAMENTO: CARGA NA TABELA T_MDM_CIDADAO');
    DBMS_OUTPUT.PUT_LINE('============================================');
    DBMS_OUTPUT.PUT_LINE('Registros lidos              : ' || v_total_lidos);
    DBMS_OUTPUT.PUT_LINE('Inseridos com sucesso        : ' || v_total_inseridos);
    DBMS_OUTPUT.PUT_LINE('Atualizados (UPDATE)         : ' || v_total_atualizados);
    DBMS_OUTPUT.PUT_LINE('Erros                        : ' || v_total_erros);
    DBMS_OUTPUT.PUT_LINE('Data/Hora termino            : ' ||
                          TO_CHAR(SYSDATE,'DD/MM/YYYY HH24:MI:SS'));
    DBMS_OUTPUT.PUT_LINE('============================================');

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('ERRO CRITICO COM CARGA INTERROMPIDA: ' || SQLERRM);
        RAISE; -- Repassa o erro ao SQL Developer para indicar que a carga falhou
END;
/
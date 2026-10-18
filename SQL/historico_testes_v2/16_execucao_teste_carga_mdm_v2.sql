-- ============================================================
-- PROJETO: CIDADE ALFA - MASTER DATA MANAGEMENT
-- ETAPA 16: EXECUCAO DE TESTE DA CARGA MDM V2
-- DATA: 16/10/2026
-- CONEXAO: FIAP_TESTE_MDM_V2
-- ============================================================

-- OBJETIVO:
-- Testar a nova regra de sobrevivencia das datas de nascimento.
-- Verificar a atualizacao dos registros existentes.
-- Preservar os dados originais utilizando ROLLBACK.

-- ETAPA 01: VERIFICACOES ANTES DA EXECUCAO
-- Sessao Oracle confirmada: 35395439.
-- Conversao de data invalida testada: resultado NULL.
-- Transacao ativa antes da carga: NULL.

-- ETAPA 02: EXECUCAO DA CARGA V2
-- Script executado: script_carrega_dados_T_MDM_CIDADAO_v2.sql
-- Ferramenta: Oracle SQL Developer.
-- Comando utilizado: F5.
-- COMMIT permaneceu comentado.
-- ROLLBACK permaneceu ativo.

-- ETAPA 03: RESULTADOS OBSERVADOS
-- Registros lidos: 100.
-- Registros inseridos: 0.
-- Registros atualizados: 100.
-- Erros: 0.
-- Procedimento PL/SQL concluido com sucesso.

-- ETAPA 04: VALIDACAO DAS DATAS DURANTE A CARGA
-- ID 1  : 19/03/2000.
-- ID 9  : 03/11/1965.
-- ID 28 : 18/09/1948.
-- ID 58 : 26/02/1977.
-- ID 76 : 27/07/1951.
-- ID 78 : 17/08/1983.
-- As seis datas foram preenchidas corretamente durante o teste.

-- ETAPA 05: VERIFICACAO APOS O ROLLBACK
-- A consulta abaixo verifica os valores atualmente armazenados.

SELECT ID_GOLD_CIDADAO, -- Identificador do registro mestre
       TO_CHAR(DT_NASCIMENTO, 'DD/MM/YYYY') AS DATA_NASCIMENTO -- Data armazenada
FROM T_MDM_CIDADAO -- Tabela mestre de cidadaos
WHERE ID_GOLD_CIDADAO IN (1, 9, 28, 58, 76, 78) -- Seis registros investigados
ORDER BY ID_GOLD_CIDADAO; -- Ordenacao pelo identificador

-- RESULTADO DA ETAPA 05:
-- Consulta executada apos o ROLLBACK.
-- Foram retornados os seis registros investigados.
-- IDs encontrados: 1, 9, 28, 58, 76 e 78.
-- Todos apresentaram DATA_NASCIMENTO sem valor (NULL).
-- O ROLLBACK desfez as correcoes das seis datas.
-- A tabela manteve os valores anteriores para esses registros.

-- EVIDENCIA:
-- evidencias/16_execucao_teste_carga_mdm_v2.png
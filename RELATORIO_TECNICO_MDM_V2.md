> **Nota sobre a distribuição pública:** este relatório documenta o projeto acadêmico completo. Arquivos CSV cadastrais e capturas originais mencionados no texto não acompanham esta versão pública, por precaução de privacidade e direitos de uso.

# RELATÓRIO TÉCNICO — CIDADE ALFA | MDM V2

## 1. Introdução

O projeto **Cidade Alfa — Master Data Management (MDM)** tem como objetivo integrar, padronizar e consolidar informações cadastrais de cidadãos provenientes de duas fontes de dados: a Prefeitura e a Receita Federal.

A solução utiliza **Oracle Database e PL/SQL** para processar os registros de origem e manter uma tabela mestre denominada `T_MDM_CIDADAO`, responsável por representar os dados consolidados dos cidadãos.

### 1.1 Objetivo da versão V2

A versão V2 foi desenvolvida para aprimorar o processamento da tabela mestre, implementando e validando as 12 regras de negócio definidas para o projeto.

Entre as principais melhorias estão:

- Padronização e tratamento dos dados cadastrais.
- Comparação de informações entre Prefeitura e Receita Federal.
- Identificação e descrição de divergências entre as fontes.
- Cálculo de idade e classificação por faixa etária.
- Atualização dos registros existentes sem substituir seus identificadores.
- Inserção de novos cidadãos somente quando não encontrados na tabela mestre.
- Tratamento de erros e controle transacional.

### 1.2 Tecnologias utilizadas

| Tecnologia | Aplicação no projeto |
|---|---|
| Oracle Database | Armazenamento das tabelas de origem e da tabela mestre |
| PL/SQL | Implementação das regras de negócio e processamento da carga |
| Oracle SQL Developer | Execução dos scripts e validação dos resultados |
| Visual Studio Code | Desenvolvimento e organização dos arquivos SQL |
| SQL | Consultas, atualizações, inserções e verificações de qualidade |

### 1.3 Escopo da validação

Foram verificadas as 12 regras de negócio, incluindo integridade dos identificadores, padronização cadastral, consistência das informações e registro de divergências.

A execução final de teste, realizada em **17/10/2026 às 22:51:44**, apresentou os seguintes resultados:

| Indicador | Resultado |
|---|---:|
| Registros lidos | 100 |
| Registros atualizados | 100 |
| Registros inseridos | 0 |
| Erros | 0 |

O processamento PL/SQL foi concluído com sucesso.

**Observação:** durante os testes, o comando `COMMIT` permaneceu comentado e o `ROLLBACK` ativo. Portanto, as alterações da V2 foram verificadas durante a execução, mas não foram confirmadas permanentemente no banco de dados.

**Execução definitiva da V2 — 18/10/2026**

Após a conclusão dos testes, foi realizado um backup da versão V1 na tabela `T_MDM_CIDADAO_BACKUP_V1`, contendo 100 registros, e uma cópia física em formato CSV.

Em 18/10/2026, às 16:04:29, o script da V2 foi executado com `COMMIT` ativo, apresentando os seguintes resultados:

| Indicador | Resultado |
|---|---:|
| Registros lidos | 100 |
| Registros atualizados | 100 |
| Registros inseridos | 0 |
| Erros | 0 |

O procedimento PL/SQL foi concluído com sucesso. Uma consulta posterior à tabela `T_MDM_CIDADAO` confirmou 100 cidadãos, 94 idades preenchidas, 94 faixas etárias preenchidas e 100 escolaridades preenchidas.



## 2. Arquitetura e fluxo de dados

### 2.1 Estrutura das fontes de dados

O projeto Cidade Alfa utiliza duas tabelas de origem e uma tabela mestre, armazenadas no Oracle Database.

| Tabela | Função |
|---|---|
| `T_SRC_PREFEITURA_CIDADAO` | Fonte principal da carga, utilizada para percorrer os cidadãos e obter os dados da Prefeitura. |
| `T_SRC_RECEITA_FEDERAL` | Fonte complementar, consultada para comparar e consolidar as informações cadastrais. |
| `T_MDM_CIDADAO` | Tabela mestre que armazena os registros consolidados e os indicadores de divergência. |

O CPF é utilizado como referência para localizar os registros correspondentes entre as fontes e identificar cidadãos já existentes na tabela mestre.

### 2.2 Fluxo de processamento

O processamento é realizado por um bloco anônimo PL/SQL, seguindo a sequência:

1. O cursor principal consulta os cidadãos da tabela `T_SRC_PREFEITURA_CIDADAO`.
2. Para cada cidadão, as variáveis auxiliares são reinicializadas.
3. O CPF é normalizado para formato numérico.
4. O sistema consulta o registro correspondente na tabela `T_SRC_RECEITA_FEDERAL`.
5. As regras de negócio são aplicadas para padronizar e comparar os dados.
6. As divergências identificadas são registradas nos campos `FL_DIVERGENCIA` e `DS_DIVERGENCIA`.
7. O sistema procura o CPF na tabela mestre `T_MDM_CIDADAO`.
8. Quando o cidadão já existe, seus dados são atualizados por meio de `UPDATE`.
9. Quando o cidadão não existe, um novo registro é criado por meio de `INSERT`, utilizando a sequência `SQ_MDM_CIDADAO.NEXTVAL`.
10. Ao final, são apresentados os contadores de registros lidos, inseridos, atualizados e erros.

### 2.3 Estratégia de atualização da V2

A versão V2 utiliza a estratégia **UPDATE antes de INSERT**, permitindo atualizar os cidadãos existentes sem substituir seus identificadores mestres.

O campo `ID_GOLD_CIDADAO` é preservado nas atualizações. A sequência `SQ_MDM_CIDADAO` é utilizada somente na inserção de novos registros.

Essa abordagem evita a criação desnecessária de novos identificadores para cidadãos que já estão cadastrados.

### 2.4 Controle transacional

Durante a fase de testes da V2, o comando `COMMIT` permaneceu comentado e o `ROLLBACK` ativo. Essa configuração permitiu verificar o processamento e as regras de negócio sem persistir as alterações na tabela mestre.

Após a conclusão das validações e a criação dos backups da V1, o script foi atualizado para utilizar `COMMIT` ao final do processamento normal.

Em 18/10/2026, a V2 foi executada definitivamente, com 100 registros atualizados e zero erros. As alterações foram confirmadas no Oracle Database.

O comando `ROLLBACK` foi mantido no tratamento de exceções (`EXCEPTION`) para desfazer alterações pendentes caso ocorra um erro crítico durante o processamento.

### 2.5 Ambiente de desenvolvimento

| Componente | Identificação |
|---|---|
| Projeto | Cidade Alfa — MDM V2 |
| SGBD | Oracle Database |
| Ferramenta de execução | Oracle SQL Developer |
| Ferramenta de edição | Visual Studio Code |
| Conexão de testes | `FIAP_TESTE_MDM_V2` |
| Schema | `RM572297` |
| Script principal | `script_carrega_dados_T_MDM_CIDADAO_v2_final.sql` |
| Arquivo de validações | `validacoes_T_MDM_CIDADAO_v2.sql` |

O arquivo de validações foi separado do script principal para preservar o histórico das verificações realizadas. Seus trechos PL/SQL foram originalmente executados dentro do bloco de carga e não constituem, isoladamente, um script independente de execução.



## 3. Regras de negócio — MDM V2

A versão V2 do projeto Cidade Alfa implementa 12 regras de negócio para consolidar, padronizar e validar os dados cadastrais dos cidadãos.

### 3.1 Resumo das 12 regras

| Regra | Campo de destino | Tipo de dado | Obrigatório | Tratamento implementado |
|---|---|---|---|---|
| 1 | `ID_GOLD_CIDADAO` | NUMBER | Sim | Preserva o ID no UPDATE; utiliza sequência somente no INSERT. |
| 2 | `NR_CPF_CIDADAO` | NUMBER | Sim | Remove a pontuação e converte o CPF para número. |
| 3 | `NM_CIDADAO` | VARCHAR2(200) | Sim | Padroniza nomes e identifica diferenças entre as fontes. |
| 4 | `DT_NASCIMENTO` | DATE | Não | Converte e compara datas; registra NULL quando ausentes, inválidas ou divergentes. |
| 5 | `NR_IDADE` | NUMBER(3) | Não | Calcula a idade em anos completos. |
| 6 | `NM_FAIXA_ETARIA` | VARCHAR2(20) | Não | Classifica os cidadãos conforme a idade. |
| 7 | `NM_SEXO` | VARCHAR2(20) | Sim | Converte códigos e identifica divergências. |
| 8 | `NM_ESTADO_CIVIL` | VARCHAR2(20) | Não | Converte códigos para descrições padronizadas. |
| 9 | `NM_ESCOLARIDADE` | VARCHAR2(30) | Não | Remove o prefixo numérico e padroniza o texto. |
| 10 | `DT_CARGA` | DATE | Sim | Registra a data e a hora do processamento. |
| 11 | `FL_DIVERGENCIA` | VARCHAR2(3) | Sim | Identifica registros com divergência: SIM ou NAO. |
| 12 | `DS_DIVERGENCIA` | VARCHAR2(4000) | Não | Armazena as mensagens explicativas das divergências. |

### 3.2 Regras de identificação e cadastro

**Regra 1 — ID_GOLD_CIDADAO**

Identificador único do registro mestre. Durante o UPDATE, o identificador existente é preservado. No INSERT, um novo identificador é gerado por `SQ_MDM_CIDADAO.NEXTVAL`.

**Regra 2 — NR_CPF_CIDADAO**

O CPF da Prefeitura é utilizado como referência principal. Sua pontuação é removida antes da conversão para NUMBER.

Como o campo é numérico, CPFs que começam com zero não preservam esse zero na representação numérica. A recuperação da representação com 11 dígitos pode ser realizada com `LPAD(TO_CHAR(NR_CPF_CIDADAO), 11, '0')`.

**Regra 3 — NM_CIDADAO**

Os nomes são normalizados com `UPPER` e `TRIM`. Quando as fontes apresentam nomes diferentes, o nome da Prefeitura é utilizado na tabela mestre e a divergência é registrada.

### 3.3 Regras de nascimento e classificação etária

**Regra 4 — DT_NASCIMENTO**

As datas de nascimento são interpretadas conforme os formatos de cada fonte:

- Receita Federal: `DD/MM/YYYY`.
- Prefeitura: `MM/DD/YYYY`.

As datas são convertidas e comparadas. Quando uma delas está ausente, é inválida ou apresenta diferença em relação à outra fonte, o destino recebe NULL e o motivo é registrado.

**Regra 5 — NR_IDADE**

A idade é calculada em anos completos a partir da data de nascimento validada e da data atual do servidor.

Quando não é possível realizar o cálculo, o campo permanece NULL e a divergência é registrada.

**Regra 6 — NM_FAIXA_ETARIA**

| Idade | Classificação |
|---|---|
| 0 a 2 anos | BEBE |
| 3 a 11 anos | CRIANCA |
| 12 a 17 anos | ADOLESCENTE |
| 18 a 59 anos | ADULTO |
| 60 anos ou mais | IDOSO |

Quando a idade está ausente ou é inválida, a faixa etária permanece NULL.

### 3.4 Regras de padronização cadastral

**Regra 7 — NM_SEXO**

Os códigos da Receita Federal são convertidos em MASCULINO ou FEMININO e comparados com os códigos da Prefeitura.

Valores ausentes, inválidos ou diferentes são identificados como divergências. Quando não é possível reconhecer o código da Receita, o destino recebe `NAO_INFORMADO`.

**Regra 8 — NM_ESTADO_CIVIL**

Os códigos da Receita Federal são convertidos conforme o domínio:

| Código | Valor padronizado |
|---|---|
| S | SOLTEIRO |
| C | CASADO |
| D | DIVORCIADO |
| V | VIUVO |
| U | UNIAO_ESTAVEL |
| Ausente ou inválido | NAO_INFORMADO |

Códigos não reconhecidos geram registro de divergência.

**Regra 9 — NM_ESCOLARIDADE**

A escolaridade informada pela Receita Federal é padronizada por meio da remoção do prefixo numérico e do hífen inicial, seguida da aplicação de `UPPER` e `TRIM`.

Quando o campo de origem está vazio, o destino permanece NULL.

### 3.5 Regras de auditoria e divergências

**Regra 10 — DT_CARGA**

A data e a hora do processamento são registradas por meio da função `SYSDATE`.

**Regra 11 — FL_DIVERGENCIA**

O campo é inicializado com `NAO` para cada cidadão e alterado para `SIM` quando alguma regra identifica uma divergência.

**Regra 12 — DS_DIVERGENCIA**

Armazena as mensagens geradas pelas validações, permitindo identificar os motivos das divergências encontradas.

Quando `FL_DIVERGENCIA = 'NAO'`, o campo permanece NULL.

As mensagens são concatenadas quando um mesmo cidadão apresenta mais de uma divergência.



## 4. Resultados das validações — MDM V2

### 4.1 Resumo das validações

As 12 regras de negócio foram verificadas durante o desenvolvimento da V2, utilizando os 100 registros processados.

| Regra | Campo | Resultado da validação |
|---|---|---|
| 1 | ID_GOLD_CIDADAO | 100 preenchidos, 0 nulos e 0 duplicados. |
| 2 | NR_CPF_CIDADAO | 100 preenchidos, 0 nulos e 0 duplicados. |
| 3 | NM_CIDADAO | 100 preenchidos, 0 fora do padrão UPPER/TRIM. |
| 4 | DT_NASCIMENTO | 6 registros com data nula, todos investigados. |
| 5 | NR_IDADE | 94 idades preenchidas, 6 nulas e 0 cálculos incorretos. |
| 6 | NM_FAIXA_ETARIA | 94 classificações preenchidas, 6 nulas e 0 classificações incorretas. |
| 7 | NM_SEXO | 100 preenchidos, 0 valores incorretos. |
| 8 | NM_ESTADO_CIVIL | 100 preenchidos, 0 valores incorretos. |
| 9 | NM_ESCOLARIDADE | 100 preenchidos, 0 valores incorretos. |
| 10 | DT_CARGA | 100 preenchidos, 0 nulos. |
| 11 | FL_DIVERGENCIA | 33 registros SIM, 67 registros NAO e 0 inconsistências identificadas. |
| 12 | DS_DIVERGENCIA | 33 descrições preenchidas para registros sinalizados e 0 descrições indevidas. |

### 4.2 Investigação das datas de nascimento

Foram identificados 6 cidadãos cuja data de nascimento foi gravada como NULL:

**IDs:** 1, 9, 28, 58, 76 e 78.

A investigação identificou:

- 3 registros com data inválida na Receita Federal, contendo `99/99/9999`.
- 3 registros com data de nascimento ausente na Prefeitura.

Os 6 casos foram tratados conforme a Regra 4, preservando NULL na data de nascimento e registrando as divergências correspondentes.

Como consequência, esses registros também permaneceram com idade e faixa etária nulas.

### 4.3 Divergências de nomes

A comparação entre Prefeitura e Receita Federal identificou:

| Indicador | Resultado |
|---|---:|
| Nomes divergentes | 27 |
| Divergências sem sinalização | 0 |
| Mensagens obrigatórias ausentes | 0 |

Todos os 27 casos foram identificados e registrados conforme a Regra 3.

### 4.4 Divergências de sexo

Foi identificada 1 divergência entre os códigos de sexo das duas fontes.

A divergência foi sinalizada corretamente, sem registros divergentes sem sinalização.

### 4.5 Indicadores gerais de divergência

| Indicador | Quantidade |
|---|---:|
| Total de cidadãos | 100 |
| Registros com divergência (`SIM`) | 33 |
| Registros sem divergência (`NAO`) | 67 |
| Registros `SIM` sem descrição | 0 |
| Registros `NAO` com descrição indevida | 0 |

As divergências identificadas podem envolver mais de um campo no mesmo cidadão. Por isso, a contagem de ocorrências por regra não deve ser interpretada como uma soma de cidadãos distintos.

### 4.6 Execução final do script

Após a separação dos blocos de validação, o script principal foi executado novamente em **17/10/2026 às 22:51:44**.

O Oracle SQL Developer apresentou:

```text
Registros lidos              : 100
Inseridos com sucesso        : 0
Atualizados (UPDATE)         : 100
Erros                        : 0

Procedimento PL/SQL concluído com sucesso.
```

A execução confirmou que o script principal continuou funcionando após a reorganização.

Como o `ROLLBACK` permaneceu ativo, as atualizações realizadas nesse teste não foram persistidas no banco de dados.

**Execução definitiva com COMMIT — 18/10/2026**

Após a conclusão das validações e a criação dos backups da V1, o script principal foi executado em 18/10/2026, às 16:04:29, com `COMMIT` ativo.

O processamento apresentou os seguintes resultados:

| Indicador | Resultado |
|---|---:|
| Registros lidos | 100 |
| Registros inseridos | 0 |
| Registros atualizados | 100 |
| Erros | 0 |

O procedimento PL/SQL foi concluído com sucesso.

Uma consulta posterior à tabela `T_MDM_CIDADAO` confirmou a disponibilidade dos dados tratados pela V2, com 100 cidadãos, 94 idades preenchidas, 94 faixas etárias preenchidas e 100 escolaridades preenchidas.

A execução definitiva foi documentada nas evidências `EVIDENCIA_V2_19_EXECUCAO_DEFINITIVA_COMMIT.png` e `EVIDENCIA_V2_20_VALIDACAO_APOS_COMMIT.png`.


### 4.7 Validação da persistência e limitações dos resultados

Durante o desenvolvimento, as validações foram realizadas com `ROLLBACK`, permitindo testar as regras de negócio sem modificar permanentemente a tabela mestre.

Após a conclusão dos testes e a criação dos backups da V1, foi realizada a execução definitiva da V2 em 18/10/2026, com `COMMIT` ativo.

A consulta de validação realizada posteriormente confirmou:

| Indicador | Resultado |
|---|---:|
| Total de cidadãos | 100 |
| Idades preenchidas | 94 |
| Faixas etárias preenchidas | 94 |
| Escolaridades preenchidas | 100 |

Esses resultados confirmam a disponibilidade dos dados tratados pela V2 na tabela `T_MDM_CIDADAO`.

O arquivo separado de validações preserva os testes utilizados durante o desenvolvimento, mas seus trechos PL/SQL não são executáveis isoladamente sem adaptação.

As validações foram realizadas sobre um conjunto de 100 registros, não abrangendo testes de desempenho ou escalabilidade com volumes maiores de dados.


### 4.8 Views analíticas — MDM V2

Após a execução definitiva da V2, foram criadas e validadas duas views analíticas no Oracle Database.

**View 1 — Quantidade de cidadãos por faixa etária e escolaridade**

A view `VW_MDM_QTD_FX_ETARIA_ESCOLARIDADE` agrupa os cidadãos por faixa etária e escolaridade.

A consulta retornou 16 agrupamentos, totalizando 100 cidadãos.

| Faixa etária | Quantidade |
|---|---:|
| ADULTO | 57 |
| IDOSO | 37 |
| Não informada (NULL) | 6 |
| **Total** | **100** |

O maior agrupamento foi ADULTO com escolaridade POS, contendo 20 cidadãos.

**View 2 — Quantidade de cidadãos por estado civil**

A view `VW_MDM_QTD_ESTADO_CIVIL` apresentou cinco categorias:

| Estado civil | Quantidade |
|---|---:|
| DIVORCIADO | 27 |
| UNIAO_ESTAVEL | 25 |
| SOLTEIRO | 18 |
| CASADO | 17 |
| VIUVO | 13 |
| **Total** | **100** |

As duas views foram validadas por consultas SQL, e seus resultados foram documentados nas evidências 21 e 22.

Os scripts de criação estão armazenados na pasta `SQL/` do projeto.


## 5. Evidências e histórico dos testes

### 5.1 Organização das evidências

Durante o desenvolvimento da V2, foram produzidos scripts de validação e capturas de tela dos resultados apresentados pelo Oracle SQL Developer.

As evidências foram organizadas para permitir a rastreabilidade das verificações realizadas nas 12 regras de negócio.

O histórico dos testes foi preservado em diretórios específicos:

- `SQL/historico_testes_v2/`: arquivos SQL utilizados durante as investigações.
- `EVIDENCIAS/historico_testes_v2/`: capturas de tela dos testes históricos.
- `EVIDENCIAS/`: capturas dos resultados principais e das validações finais.


### 5.2 Inventário das evidências principais

| Arquivo | Conteúdo comprovado |
|---|---|
| `EVIDENCIA_V2_01_CARGA_100_ATUALIZADOS_0_ERROS.png` | Processamento de 100 registros, com 100 atualizações e zero erros. |
| `EVIDENCIA_V2_02_VALIDACAO_6_DATAS_NASCIMENTO.png` | Investigação dos seis registros com data de nascimento nula. |
| `EVIDENCIA_V2_03_VALIDACAO_NR_IDADE.png` | Verificação do cálculo das idades. |
| `EVIDENCIA_V2_04_VALIDACAO_FAIXA_ETARIA.png` | Verificação da classificação por faixa etária. |
| `EVIDENCIA_V2_05_VALIDACAO_NM_SEXO.png` | Validação da padronização do sexo. |
| `EVIDENCIA_V2_06_DIVERGENCIAS_NM_SEXO.png` | Investigação da divergência de sexo. |
| `EVIDENCIA_V2_07_VALIDACAO_ESTADO_CIVIL.png` | Validação do domínio de estado civil. |
| `EVIDENCIA_V2_08_VALIDACAO_ESCOLARIDADE.png` | Validação da escolaridade padronizada. |
| `EVIDENCIA_V2_09_VALIDACAO_DT_CARGA.png` | Verificação da data e hora da carga. |
| `EVIDENCIA_V2_10_VALIDACAO_ID_GOLD.png` | Verificação dos identificadores mestres. |
| `EVIDENCIA_V2_11_VALIDACAO_CPF.png` | Verificação do preenchimento e da unicidade dos CPFs. |
| `EVIDENCIA_V2_12_VALIDACAO_NM_CIDADAO.png` | Validação da padronização dos nomes. |
| `EVIDENCIA_V2_13_DIVERGENCIAS_NM_CIDADAO.png` | Investigação das 27 divergências de nomes. |
| `EVIDENCIA_V2_14_VALIDACAO_FL_DIVERGENCIA.png` | Verificação dos indicadores SIM e NAO. |
| `EVIDENCIA_V2_15_VALIDACAO_DS_DIVERGENCIA.png` | Verificação das descrições das divergências. |
| `EVIDENCIA_V2_16_VALIDACAO_FINAL_MENSAGENS_NOMES.png` | Conferência das mensagens de divergência de nomes. |
| `EVIDENCIA_V2_17_EXECUCAO_SCRIPT_FINAL.png` | Execução final do script reorganizado, com 100 atualizações e zero erros. |
| `EVIDENCIA_V2_18_ANALISE_FAIXA_ETARIA_ESCOLARIDADE.png` | Consulta analítica com 16 agrupamentos por faixa etária e escolaridade. |
| `EVIDENCIA_V2_19_EXECUCAO_DEFINITIVA_COMMIT.png` | Execução definitiva da V2 em 18/10/2026, com 100 atualizações e zero erros. |
| `EVIDENCIA_V2_20_VALIDACAO_APOS_COMMIT.png` | Validação dos dados após o COMMIT: 100 cidadãos, 94 idades, 94 faixas etárias e 100 escolaridades preenchidas. |
| `EVIDENCIA_V2_21_VALIDACAO_VIEW_FAIXA_ETARIA_ESCOLARIDADE.png` | Validação da view analítica por faixa etária e escolaridade, com 16 agrupamentos e 100 cidadãos. |
| `EVIDENCIA_V2_22_VALIDACAO_VIEW_ESTADO_CIVIL.png` | Validação da view analítica por estado civil, com 5 categorias e 100 cidadãos. |

### 5.3 Arquivos SQL utilizados

| Arquivo | Finalidade |
|---|---|
| `script_carrega_dados_T_MDM_CIDADAO_v2_final.sql` | Versão organizada do processamento principal. |
| `validacoes_T_MDM_CIDADAO_v2.sql` | Preservação dos blocos de validação utilizados durante os testes. |
| `VALIDACAO_V2_02_6_DATAS_NASCIMENTO.sql` | Investigação específica das seis datas de nascimento nulas. |
| `SQL/cria_view_qtd_total_fx_etaria_escolaridade.sql` | Criação e validação da view por faixa etária e escolaridade, com 16 agrupamentos e 100 cidadãos. |
| `SQL/cria_view_qtd_total_estado_civil.sql` | Criação e validação da view por estado civil, com 5 categorias e 100 cidadãos. |

### 5.4 Rastreabilidade

As evidências permitem relacionar as regras de negócio aos resultados observados durante o processamento.

As capturas de tela documentam as verificações realizadas, enquanto os arquivos SQL preservam a lógica utilizada para executar e investigar os testes.

O script principal foi separado dos blocos de validação para facilitar sua leitura, manutenção e apresentação.

O arquivo de validações contém trechos originalmente integrados ao bloco PL/SQL e deve ser tratado como histórico técnico, não como um script autônomo pronto para execução.

### 5.5 Situação da versão V2

Ao término do desenvolvimento e da execução definitiva:

- As 12 regras de negócio foram implementadas e validadas.
- O script principal foi organizado e separado do histórico de validações.
- A versão V1 foi preservada na tabela `T_MDM_CIDADAO_BACKUP_V1`, com 100 registros, e em um arquivo CSV.
- A execução definitiva da V2 foi realizada em 18/10/2026, às 16:04:29.
- O processamento apresentou 100 registros atualizados, nenhuma inserção e zero erros.
- O comando `COMMIT` foi ativado para confirmar as alterações.
- O `ROLLBACK` foi mantido no tratamento de exceções.
- Uma consulta posterior confirmou 100 cidadãos, 94 idades preenchidas, 94 faixas etárias preenchidas e 100 escolaridades preenchidas.
- As evidências da execução definitiva e da validação foram registradas na pasta `EVIDENCIAS/`.

**Status:** V2 implementada, validada e persistida no Oracle Database.



## 6. Conclusão técnica e limitações

### 6.1 Resultados alcançados

O desenvolvimento da versão V2 do projeto Cidade Alfa — Master Data Management permitiu implementar e validar as 12 regras de negócio definidas para o processamento dos dados cadastrais.

A solução integrou informações provenientes da Prefeitura e da Receita Federal, utilizando Oracle Database e PL/SQL para padronizar, comparar e consolidar os registros na tabela mestre `T_MDM_CIDADAO`.

Os testes realizados demonstraram:

- Processamento de 100 registros de origem.
- Atualização de 100 registros existentes.
- Nenhuma inserção adicional durante os testes.
- Nenhum erro registrado na execução final.
- Identificação de 33 cidadãos com divergências.
- Identificação de 27 divergências de nomes.
- Investigação de 6 registros com datas de nascimento nulas.
- Preservação dos identificadores mestres durante as atualizações.

### 6.2 Evolução da V1 para a V2

A V2 aprimorou o processamento da tabela mestre ao incorporar as regras de padronização, comparação e tratamento de divergências verificadas durante o desenvolvimento.

A estratégia de atualização por CPF permite preservar o identificador `ID_GOLD_CIDADAO` dos cidadãos existentes.

A separação entre o script principal e o histórico de validações também contribuiu para melhorar a organização e a manutenção dos arquivos do projeto.

### 6.3 Limitações identificadas

**Persistência dos dados**

Durante os testes, foi utilizado `ROLLBACK` para evitar alterações permanentes na tabela mestre.

Após a criação dos backups da V1 e a conclusão das validações, a V2 foi executada definitivamente em 18/10/2026, com `COMMIT` ativo.

A execução apresentou 100 atualizações e zero erros. Uma consulta posterior confirmou a disponibilidade dos dados tratados na tabela `T_MDM_CIDADAO`.

Portanto, a persistência dos dados deixou de ser uma limitação da V2.

**Representação numérica do CPF**

O armazenamento do CPF como NUMBER não preserva zeros à esquerda na representação numérica. Quando necessário, a apresentação com 11 dígitos pode ser reconstruída utilizando `LPAD`.

**Datas de nascimento ausentes ou inválidas**

Seis registros permaneceram com data de nascimento nula devido a problemas identificados nas fontes. Consequentemente, também não receberam idade e faixa etária.

**Validações separadas**

O arquivo de validações preserva trechos PL/SQL utilizados durante o desenvolvimento, mas não constitui um script independente executável sem adaptação.

**Escopo dos testes**

Os resultados documentados correspondem ao conjunto de 100 registros utilizado durante o desenvolvimento. Não representam uma validação de desempenho ou de comportamento com volumes maiores de dados.

### 6.4 Considerações finais

O projeto Cidade Alfa — Master Data Management V2 concluiu as etapas de implementação, validação funcional e persistência dos dados no Oracle Database.

As 12 regras de negócio foram implementadas e verificadas, permitindo consolidar informações provenientes da Prefeitura e da Receita Federal, padronizar dados cadastrais e identificar divergências entre as fontes.

Antes da execução definitiva, a versão V1 foi preservada em uma tabela de backup no Oracle e em um arquivo CSV.

Em 18/10/2026, às 16:04:29, a V2 foi executada com `COMMIT` ativo, processando 100 registros, realizando 100 atualizações e apresentando zero erros.

A validação posterior confirmou 100 cidadãos na tabela mestre, sendo 94 com idade preenchida, 94 com faixa etária preenchida e 100 com escolaridade preenchida.

O projeto mantém os scripts SQL, o histórico dos testes e **22 evidências principais** organizadas, permitindo acompanhar o desenvolvimento, a execução definitiva e os resultados obtidos.

**Situação atual:** a versão MDM V2 está implementada, validada e persistida no Oracle Database. As duas views analíticas previstas na atividade da FIAP também foram criadas e validadas, contemplando as análises por faixa etária e escolaridade e por estado civil.
/* =========================================================
   MODELAGEM FÍSICA — ODS (Objetivos de Desenvolvimento Sustentável)
   ========================================================= */
BEGIN;

-- 1.  Schema padrão
CREATE SCHEMA IF NOT EXISTS ods;
SET search_path TO ods, public;

/* ---------------------------------------------------------
   TABELAS DE DIMENSÃO DEMOGRÁFICA
   --------------------------------------------------------- */

-- Regiões do país
CREATE TABLE regiao (
    id_regiao   SERIAL PRIMARY KEY,
    nome_regiao VARCHAR(100) NOT NULL
);

-- Famílias (uma região → muitas famílias)
CREATE TABLE familia (
    id_familia      SERIAL PRIMARY KEY,
    id_regiao       INT NOT NULL REFERENCES regiao(id_regiao),
    situacao        VARCHAR(100),
    renda_familiar  DECIMAL(10,2),
    tipo_moradia    VARCHAR(100),
    acesso_internet BOOLEAN
);

-- Pessoas (uma família → muitas pessoas)
CREATE TABLE pessoa (
    id_pessoa  SERIAL PRIMARY KEY,
    id_familia INT NOT NULL REFERENCES familia(id_familia),
    sexo       CHAR(1)  NOT NULL CHECK (sexo IN ('M','F','O')),
    idade      INT CHECK (idade >= 0)
);

/* ---------------------------------------------------------
   TABELAS DE SAÚDE E EDUCAÇÃO (1 : 1 com Pessoa)
   --------------------------------------------------------- */

CREATE TABLE acesso_saude (
    id_pessoa            INT PRIMARY KEY REFERENCES pessoa(id_pessoa),
    local_mais_frequente VARCHAR(100)
);

CREATE TABLE escolaridade (
    id_pessoa                INT PRIMARY KEY REFERENCES pessoa(id_pessoa),
    frequenta_escola_creche  BOOLEAN,
    matriculado              BOOLEAN
);

/* ---------------------------------------------------------
   SEGURANÇA ALIMENTAR (1 : 1 com Família)
   --------------------------------------------------------- */

CREATE TABLE seguranca_alimentar (
    id_familia                 INT PRIMARY KEY REFERENCES familia(id_familia),
    menor_18_sentiu_fome                  BOOLEAN,
    menor_18_sem_comer         BOOLEAN,
    morador_alim_acabassem     BOOLEAN,
    morador_alim_acabaram      BOOLEAN,
    morador_saudavel           BOOLEAN,
    morador_insuficiente       BOOLEAN,
    adulto_saltou_refeicao     BOOLEAN,
    adulto_comeu_menos         BOOLEAN,
    adulto_sentiu_fome         BOOLEAN,
    adulto_sem_comer           BOOLEAN,
    menor18_saudavel           BOOLEAN,
    menor18_insuficiente       BOOLEAN
);

/* ---------------------------------------------------------
   HÁBITOS ALIMENTARES (1 : 1 com Pessoa)
   --------------------------------------------------------- */

CREATE TABLE alimentacao (
    id_pessoa                           INT PRIMARY KEY REFERENCES pessoa(id_pessoa),
    consome_frutas_frequentemente       BOOLEAN,
    consome_alimentos_ultraprocessados  BOOLEAN,
    refeicao_escola_creche              VARCHAR(100),
    dificuldade_acesso_alimento_saudavel BOOLEAN
);

/* ---------------------------------------------------------
   INDICADORES ECONÔMICOS E AGREGAÇÕES
   --------------------------------------------------------- */

-- Indicador econômico por região/ano
CREATE TABLE indicador_economico (
    id_indicador SERIAL PRIMARY KEY,
    id_regiao    INT NOT NULL REFERENCES regiao(id_regiao),
);

-- Impostos (tabela SEPARADA)
CREATE TABLE impostos (
    id_regiao                   INT NOT NULL REFERENCES regiao(id_regiao),
    id_indicador                INT NOT NULL REFERENCES indicador_economico(id_indicador),
    impostos_total              DECIMAL(15,2),
    participacao_regiao_impostos DECIMAL(5,2),
    PRIMARY KEY (id_regiao, id_indicador)
);

-- Valor Adicionado Bruto por setor
CREATE TABLE valor_adicionado_bruto (
    id_indicador           INT PRIMARY KEY REFERENCES indicador_economico(id_indicador),
    total_vab              DECIMAL(15,2),
    participacao_agro      DECIMAL(5,2),
    participacao_industria DECIMAL(5,2),
    participacao_servicos  DECIMAL(5,2)
);

-- Produto Interno Bruto regional
CREATE TABLE pib (
    id_regiao                  INT NOT NULL REFERENCES regiao(id_regiao),
    id_indicador               INT NOT NULL REFERENCES indicador_economico(id_indicador),
    pib_total                  DECIMAL(15,2),
    participacao_regiao_brasil DECIMAL(5,2),
    PRIMARY KEY (id_regiao, id_indicador)
);

COMMIT;
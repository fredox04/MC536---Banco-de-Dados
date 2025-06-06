BEGIN;

CREATE SCHEMA IF NOT EXISTS ods;
SET search_path TO ods, public;

CREATE TABLE regiao (
    id_regiao   SERIAL PRIMARY KEY,
    nome_regiao VARCHAR(100) NOT NULL
);

CREATE TABLE familia (
    id_familia      SERIAL PRIMARY KEY,
    id_regiao       INT NOT NULL REFERENCES regiao(id_regiao),
    situacao        VARCHAR(100),
    renda_familiar  DECIMAL(10,2),
    tipo_moradia    VARCHAR(100),
    acesso_internet BOOLEAN
);

CREATE TABLE pessoa (
    id_pessoa  SERIAL PRIMARY KEY,
    id_familia INT NOT NULL REFERENCES familia(id_familia),
    sexo       CHAR(1)  NOT NULL CHECK (sexo IN ('M','F','O')),
    idade      INT CHECK (idade >= 0)
);

CREATE TABLE acesso_saude (
    id_acesso_saude  SERIAL PRIMARY KEY,
    id_pessoa        INT NOT NULL REFERENCES pessoa(id_pessoa),
    local_mais_frequente VARCHAR(100)
);

CREATE TABLE escolaridade (
    id_escolaridade  SERIAL PRIMARY KEY,
    id_pessoa        INT NOT NULL REFERENCES pessoa(id_pessoa),
    frequenta_escola_creche BOOLEAN,
    matriculado              BOOLEAN
);

CREATE TABLE seguranca_alimentar (
    id_seguranca_alimentar SERIAL PRIMARY KEY,
    id_familia             INT NOT NULL REFERENCES familia(id_familia),
    menor_18_sentiu_fome          BOOLEAN,
    menor_18_sem_comer            BOOLEAN,
    morador_alim_acabassem        BOOLEAN,
    morador_alim_acabaram         BOOLEAN,
    morador_saudavel              BOOLEAN,
    morador_insuficiente          BOOLEAN,
    adulto_saltou_refeicao        BOOLEAN,
    adulto_comeu_menos            BOOLEAN,
    adulto_sentiu_fome            BOOLEAN,
    adulto_sem_comer              BOOLEAN,
    menor18_saudavel              BOOLEAN,
    menor18_insuficiente          BOOLEAN
);

CREATE TABLE alimentacao (
    id_alimentacao  SERIAL PRIMARY KEY,
    id_pessoa       INT NOT NULL REFERENCES pessoa(id_pessoa),
    consome_frutas_frequentemente       BOOLEAN,
    consome_alimentos_ultraprocessados  BOOLEAN,
    refeicao_escola_creche              VARCHAR(100),
    dificuldade_acesso_alimento_saudavel BOOLEAN
);

CREATE TABLE indicador_economico (
    id_indicador SERIAL PRIMARY KEY,
    id_regiao    INT NOT NULL REFERENCES regiao(id_regiao)
);

CREATE TABLE impostos (
    id_impostos   SERIAL PRIMARY KEY,
    id_regiao     INT NOT NULL REFERENCES regiao(id_regiao),
    id_indicador  INT NOT NULL REFERENCES indicador_economico(id_indicador),
    impostos_total               DECIMAL(15,2),
    participacao_regiao_impostos DECIMAL(5,2)
);

CREATE TABLE valor_adicionado_bruto (
    id_vab                SERIAL PRIMARY KEY,
    id_indicador          INT NOT NULL REFERENCES indicador_economico(id_indicador),
    total_vab             DECIMAL(15,2),
    participacao_agro     DECIMAL(5,2),
    participacao_industria DECIMAL(5,2),
    participacao_servicos DECIMAL(5,2)
);

CREATE TABLE pib (
    id_pib                     SERIAL PRIMARY KEY,
    id_regiao                  INT NOT NULL REFERENCES regiao(id_regiao),
    id_indicador               INT NOT NULL REFERENCES indicador_economico(id_indicador),
    pib_total                  DECIMAL(15,2),
    participacao_regiao_brasil DECIMAL(5,2)
);

COMMIT;

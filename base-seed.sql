--- INICIO DDL ---

CREATE TABLE Pessoa
(
    CPF            VARCHAR(11) UNIQUE NOT NULL,
    Titulo_Eleitor VARCHAR(12) UNIQUE NOT NULL,
    Nome           VARCHAR(255)       NOT NULL,
    Endereco       VARCHAR(255)       NOT NULL,
    Escolaridade   VARCHAR(255),

    CONSTRAINT PK_CPF PRIMARY KEY (CPF),
    CONSTRAINT CK_ESCOLARIDADE CHECK (Escolaridade IN
                                      ('analfabeto', '1 grau completo', '2 grau incompleto',
                                       '2 grau completo', 'superior incompleto', 'superior completo', 'pos-graduação',
                                       'mestrado', 'doutorado'))

);

CREATE TABLE Programa_Partido
(
    ID              VARCHAR(255) NOT NULL,
    Conteudo        VARCHAR(255) NOT NULL,
    Data_Publicacao DATE         NOT NULL,

    CONSTRAINT PK_PROGRAMA_PARTIDO PRIMARY KEY (ID)
);

CREATE TABLE Partido
(
    Sigla          VARCHAR(8) UNIQUE  NOT NULL,
    Nome           VARCHAR(255)       NOT NULL,
    CPF_Presidente VARCHAR(11) UNIQUE NOT NULL,
    Data_Fundacao  DATE               NOT NULL,
    ID_Programa    VARCHAR            NOT NULL,

    CONSTRAINT PK_SIGLA PRIMARY KEY (Sigla),
    CONSTRAINT FK_PRESIDENTE FOREIGN KEY (CPF_Presidente) REFERENCES Pessoa (CPF) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT FK_PROGRAMA FOREIGN KEY (ID_Programa) REFERENCES Programa_Partido (ID) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE Candidato
(
    CPF_Candidato VARCHAR(11) NOT NULL,
    Sigla_Partido VARCHAR(8)  NOT NULL,

    CONSTRAINT PK_CANDIDATO PRIMARY KEY (CPF_Candidato, Sigla_Partido),
    CONSTRAINT FK_SIGLA_PARTIDO FOREIGN KEY (Sigla_Partido) REFERENCES Partido (Sigla) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT FK_CPF_CANDIDATO FOREIGN KEY (CPF_Candidato) REFERENCES Pessoa (CPF) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE Cargo
(
    ID                 VARCHAR(255) UNIQUE NOT NULL,
    Nome               VARCHAR(255)        NOT NULL,
    Cidade             VARCHAR(255) DEFAULT NULL,
    Estado             VARCHAR(255) DEFAULT NULL,
    Federacao          VARCHAR(255) DEFAULT NULL,
    Quantidade_Eleitos INT,

    CONSTRAINT PK_CARGO PRIMARY KEY (ID)
);

CREATE TABLE Pleito
(
    Ano         INT,
    Total_Votos INT,

    CONSTRAINT PK_PLEITO PRIMARY KEY (Ano)
);

CREATE TABLE Candidatura
(
    ID              VARCHAR(255) UNIQUE NOT NULL,
    CPF_Candidato   VARCHAR(11)         NOT NULL,
    CPF_Vice        VARCHAR(11)                  DEFAULT NULL,
    ano_pleito      INT                 NOT NULL,
    ID_Cargo        VARCHAR(255)        NOT NULL,
    Votos_Recebidos INT                 NOT NULL DEFAULT 0,

    CONSTRAINT PK_CANDIDATURA PRIMARY KEY (ID),
    CONSTRAINT FK_CPF_CANDIDATO FOREIGN KEY (CPF_Candidato) REFERENCES Pessoa (CPF) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT FK_CPF_VICE FOREIGN KEY (CPF_Vice) REFERENCES Pessoa (CPF) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT FK_PLEITO FOREIGN KEY (Ano_Pleito) REFERENCES Pleito (Ano) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT FK_CARGO FOREIGN KEY (ID_Cargo) REFERENCES Cargo (ID) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE Equipe_Apoio
(
    ID             VARCHAR(255) NOT NULL,
    ID_Candidatura VARCHAR(255) NOT NULL,
    Ano_Pleito     INT          NOT NULL,
    Objetivo       VARCHAR(255) NOT NULL,

    CONSTRAINT PK_EQUIPE_APOIO PRIMARY KEY (ID),
    CONSTRAINT FK_CANDIDATURA FOREIGN KEY (ID_Candidatura) REFERENCES Candidatura (ID) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE Apoiador_Campanha
(
    ID_Equipe_Apoio VARCHAR(255) NOT NULL,
    CPF_Apoiador    VARCHAR(11)  NOT NULL,
    ID_Candidatura  VARCHAR(255) NOT NULL,
    CONSTRAINT PK_APOIADOR_CAMPANHA PRIMARY KEY (CPF_Apoiador, ID_Equipe_Apoio),
    CONSTRAINT FK_EQUIPE_APOIO FOREIGN KEY (ID_Equipe_Apoio) REFERENCES Equipe_Apoio (ID) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT FK_CPF_APOIADOR FOREIGN KEY (CPF_Apoiador) REFERENCES Pessoa(CPF) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT FK_CANDIDATURA FOREIGN KEY (ID_Candidatura) REFERENCES Candidatura(ID) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE Doador_Campanha
(
    ID   VARCHAR(255) UNIQUE NOT NULL,
    CPF  VARCHAR(11),
    CNPJ VARCHAR(14),

    CONSTRAINT PK_DOADOR_CAMPANHA PRIMARY KEY (ID),
    CONSTRAINT FK_CPF_DOADOR FOREIGN KEY (CPF) REFERENCES Pessoa(CPF) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE Doacao_Candidatura
(
    ID_Doador      VARCHAR(255) NOT NULL,
    ID_Candidatura VARCHAR(255) NOT NULL,
    Valor          INT          NOT NULL,

    CONSTRAINT PK_DOACAO_CANDIDATURA PRIMARY KEY (ID_Candidatura, ID_Doador),
    CONSTRAINT FK_CANDIDATURA FOREIGN KEY (ID_Candidatura) REFERENCES Candidatura (ID) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT FK_DOADOR_CAMPANHA FOREIGN KEY (ID_Doador) REFERENCES Doador_Campanha (ID) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE Processo_Judicial
(
    ID          VARCHAR(255) NOT NULL,
    Data_Inicio DATE         NOT NULL,
    Data_Fim    DATE,
    Procedente  BOOLEAN,
    CPF_Reu     VARCHAR(11)  NOT NULL,

    CONSTRAINT PK_PROCESS_JUDICIAL PRIMARY KEY (ID),
    CONSTRAINT FK_CPF_REU FOREIGN KEY (CPF_Reu) REFERENCES Pessoa (CPF) ON DELETE CASCADE ON UPDATE CASCADE
);

--- FIM DDL ---
--- INICIO TRIGGERS ---

-- Valida se o candidato já existe com partido diferente

CREATE
    OR REPLACE FUNCTION valida_candidato() RETURNS trigger AS
$valida_candidato$
DECLARE
    candidatos_partido INTEGER;
BEGIN
    SELECT COUNT(*)
    INTO candidatos_partido
    FROM Candidato
    WHERE CPF_Candidato = NEW.CPF_Candidato;

    IF
        (candidatos_partido > 0) THEN
        RAISE EXCEPTION 'O Candidato já está cadastrado';
    END IF;

    RETURN NEW;
END;
$valida_candidato$
    LANGUAGE plpgsql;
CREATE TRIGGER VALIDA_CANDIDATo
    BEFORE INSERT OR
        UPDATE
    ON Candidato
    FOR EACH ROW
EXECUTE PROCEDURE valida_candidato();


--- VALIDA SE O CANDIDATO JÁ ESTÁ CADASTRADO NO PLEITO DO ANO
CREATE
    OR REPLACE FUNCTION valida_candidatura() RETURNS trigger AS
$valida_candidatura$
DECLARE
    candidaturas_ano INTEGER;
BEGIN
    SELECT COUNT(*)
    INTO candidaturas_ano
    FROM Candidatura
    WHERE CPF_Candidato = NEW.CPF_Candidato
      AND Ano_Pleito = NEW.Ano_Pleito;
    IF
        (candidaturas_ano > 0) THEN
        RAISE EXCEPTION 'O Candidato já está cadastrado no pleito desse ano';
    END IF;

    RETURN NEW;
END;
$valida_candidatura$
    LANGUAGE plpgsql;
CREATE TRIGGER VALIDA_CANDIDATURA
    BEFORE INSERT OR
        UPDATE
    ON Candidatura
    FOR EACH ROW
EXECUTE PROCEDURE valida_candidatura();


--- Valida se a pessoa é um candidato
CREATE
    OR REPLACE FUNCTION valida_candidatura_candidato() RETURNS trigger AS
$valida_candidatura_candidato$
DECLARE
    candidato INTEGER;
BEGIN
    SELECT COUNT(*)
    INTO candidato
    FROM Pessoa
    WHERE CPF = NEW.CPF_Candidato;
    IF
        (candidato = 0) THEN
        RAISE EXCEPTION 'A Pessoa precisa ser um candidato';
    END IF;

    RETURN NEW;
END;
$valida_candidatura_candidato$
    LANGUAGE plpgsql;
CREATE TRIGGER VALIDA_CANDIDATURA_CANDIDATO
    BEFORE INSERT OR
        UPDATE
    ON Candidatura
    FOR EACH ROW
EXECUTE PROCEDURE valida_candidatura_candidato();

-- Valida se o candidato é ficha limpa
CREATE
    OR REPLACE FUNCTION valida_candidatura_ficha_limpa() RETURNS trigger AS
$valida_candidatura_ficha_limpa$
DECLARE
    nro_processos_culpado_candidato INTEGER;
    nro_processos_culpado_vice
                                    INTEGER;
BEGIN
    SELECT COUNT(*)
    INTO nro_processos_culpado_candidato
    FROM Processo_Judicial
    WHERE CPF_Reu = NEW.CPF_Candidato
      AND Procedente = TRUE
      AND Data_Fim BETWEEN CURRENT_DATE - INTERVAL '5 YEARS'
        AND CURRENT_DATE;

    SELECT COUNT(*)
    INTO nro_processos_culpado_vice
    FROM Processo_Judicial
    WHERE CPF_Reu = NEW.CPF_Vice
      AND Procedente = TRUE
      AND Data_Fim BETWEEN CURRENT_DATE - INTERVAL '5 YEARS'
        AND CURRENT_DATE;

    IF
        (nro_processos_culpado_candidato > 0) THEN
        RAISE EXCEPTION 'Candidato não é ficha limpa';
    END IF;

    IF
        (NEW.CPF_VICE IS NOT NULL AND nro_processos_culpado_candidato > 0) THEN
        RAISE EXCEPTION 'Vice-Candidato não é ficha limpa';
    END IF;

    RETURN NEW;
END;
$valida_candidatura_ficha_limpa$
    LANGUAGE plpgsql;
CREATE TRIGGER VALIDA_CANDIDATURA_FICHA_LIMPA
    BEFORE INSERT OR
        UPDATE
    ON Candidatura
    FOR EACH ROW
EXECUTE PROCEDURE valida_candidatura_ficha_limpa();

-- Valida se o cargo tem uma cidade, estado ou federação
CREATE
    OR REPLACE FUNCTION valida_cargo() RETURNS trigger AS
$valida_cargo$
BEGIN
    IF
        (NEW.Cidade IS NOT NULL) THEN
        RETURN NEW;
    ELSEIF
        (NEW.Estado IS NOT NULL) THEN
        RETURN NEW;
    ELSEIF
        (NEW.Federacao IS NOT NULL) THEN
        RETURN NEW;
    END IF;
    RAISE
        EXCEPTION 'Um cargo deve estar associado a uma cidade, estado ou federeção';
END;
$valida_cargo$
    LANGUAGE plpgsql;
CREATE TRIGGER VALIDA_CARGO
    BEFORE INSERT OR
        UPDATE
    ON Cargo
    FOR EACH ROW
EXECUTE PROCEDURE valida_cargo();

-- Valida se o indivíduo já está apoiando alguma campanha no memsmo ano

CREATE
    OR REPLACE FUNCTION valida_apoiador_campanha() RETURNS trigger AS
$valida_apoiador_campanha$
DECLARE
    nro_campanhas_ano  INTEGER;
    ano_campanha_atual
                       INTEGER;
BEGIN
    SELECT Ano_Pleito
    INTO ano_campanha_atual
    FROM Equipe_Apoio
    WHERE ID = NEW.ID_Equipe_Apoio;

    SELECT COUNT(*)
    INTO nro_campanhas_ano
    FROM Apoiador_Campanha
             NATURAL JOIN Equipe_Apoio
    WHERE CPF_Apoiador = NEW.CPF_Apoiador
      AND Ano_Pleito = ano_campanha_atual;


    IF
        (nro_campanhas_ano > 0) THEN
        RAISE EXCEPTION 'Indivíduo só pode apoiar uma campanha por ano';
    END IF;

    RETURN NEW;
END;
$valida_apoiador_campanha$
    LANGUAGE plpgsql;
CREATE TRIGGER VALIDA_APOIADOR_CAMPANHA
    BEFORE INSERT OR
        UPDATE
    ON Apoiador_Campanha
    FOR EACH ROW
EXECUTE PROCEDURE valida_apoiador_campanha();

-- Valida documento do doador

CREATE
    OR REPLACE FUNCTION valida_doador_documento() RETURNS trigger AS
$valida_doador_documento$
BEGIN
    IF
        (NEW.CPF IS NOT NULL AND NEW.CNPJ IS NOT NULL) THEN
        RAISE EXCEPTION 'Um doador deve ser uma empresa ou um indivíduo';
    END IF;

    IF
        (NEW.CPF IS NOT NULL AND NEW.CNPJ IS NOT NULL) THEN
        RAISE EXCEPTION 'Um doador não pode ter cpf e cnpj ao mesmo tempo';
    END IF;

    RETURN NEW;
END;
$valida_doador_documento$
    LANGUAGE plpgsql;
CREATE TRIGGER VALIDA_DOACAO_DOCUMENTO
    BEFORE INSERT OR
        UPDATE
    ON Doador_Campanha
    FOR EACH ROW
EXECUTE PROCEDURE valida_doador_documento();

-- Valida numero de doação de empresas

CREATE
    OR REPLACE FUNCTION valida_doacao_empresa() RETURNS trigger AS
$valida_doacao_empresa$
DECLARE
    nro_doacao_candidatura INTEGER;
BEGIN
    SELECT COUNT(*)
    INTO nro_doacao_candidatura
    FROM Doacao_Candidatura
    WHERE ID_Candidatura = NEW.ID_Candidatura
      AND ID_Doador = NEW.ID_Doador;

    IF
        (nro_doacao_candidatura > 0) THEN
        RAISE EXCEPTION 'Uma empresa pode doar apenas uma vez por candidatura';
    END IF;
    RETURN NEW;
END;
$valida_doacao_empresa$
    LANGUAGE plpgsql;
CREATE TRIGGER VALIDA_DOADOR_EMPRESA
    BEFORE INSERT OR
        UPDATE
    ON Doacao_Candidatura
    FOR EACH ROW
EXECUTE PROCEDURE valida_doacao_empresa();

-- Atualiza total de votos do pleito

CREATE
    OR REPLACE FUNCTION atualiza_votos_pleito() RETURNS trigger AS
$atualiza_votos_pleito$
DECLARE
    nro_votos_pleito INTEGER;
BEGIN
    SELECT SUM(Votos_Recebidos)
    INTO nro_votos_pleito
    FROM Candidatura
    WHERE Ano_Pleito = NEW.Ano_Pleito;
    UPDATE Pleito
    SET Total_Votos = nro_votos_pleito
    WHERE Ano = NEW.Ano_Pleito;
    RETURN NEW;
END;
$atualiza_votos_pleito$
    LANGUAGE plpgsql;
CREATE TRIGGER VALIDA_DOADOR_EMPRESA
    AFTER INSERT OR
        UPDATE OR
        DELETE
    ON Candidatura
    FOR EACH ROW
EXECUTE PROCEDURE atualiza_votos_pleito();

-- FIM TRIGGERS

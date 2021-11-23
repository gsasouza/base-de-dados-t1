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
    CONSTRAINT FK_CPF_APOIADOR FOREIGN KEY (ID_Candidatura) REFERENCES Candidatura(ID) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE Doador_Campanha
(
    ID   VARCHAR(255) UNIQUE NOT NULL,
    CPF  VARCHAR(11),
    CNPJ VARCHAR(14),

    CONSTRAINT PK_DOADOR_CAMPANHA PRIMARY KEY (ID),
    CONSTRAINT FK_CPF_DOADOR FOREIGN KEY (CPF) REFERENCES Pessoa(CPF) ON DELETE CASCADE ON UPDATE CASCADE,
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


--- Insere pessoas

INSERT INTO Pessoa
VALUES ('75199425951', '243114962102', 'Pablo Santos', 'Santos Travessa, 36416, Moraes do Norte, AC',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('23576477523', '616330792987', 'Aline Nogueira', 'Hélio Rua, 83652, undefined Cauã, DF',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('45628193288', '283556670718', 'Marcelo Silva', 'Costa Travessa, 92630, undefined Isabelly do Norte, AP',
        'superior completo');
INSERT INTO Pessoa
VALUES ('69293496576', '175834169238', 'João Lucas Braga', 'Pereira Rodovia, 23837, Yago de Nossa Senhora, BA',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('28127971645', '211370177916', 'Ladislau Pereira', 'Pietro Alameda, 23610, undefined Norberto, CE',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('52914412149', '582753546652', 'Samuel Oliveira', 'Moraes Rodovia, 70645, Danilo do Norte, RJ',
        'mestrado');
INSERT INTO Pessoa
VALUES ('25902807421', '288500413182', 'Maitê Melo', 'Macedo Travessa, 87464, Macedo do Sul, SP',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('64084488817', '674179774499', 'Yago Barros', 'Martins Avenida, 33271, Guilherme do Descoberto, SP',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('32671805294', '876531244534', 'Gael Batista', 'Martins Rua, 11307, Gresham, AP',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('68540927693', '885215771291', 'Ana Clara Batista', 'Alice Travessa, 56398, undefined Víctor do Sul, RS',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('13836945446', '992493603168', 'Fabiano Xavier', 'Enzo Travessa, 61500, undefined Karla, MS',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('91207586100', '275397017062', 'Rafaela Reis', 'Marcos Alameda, 38248, Franco do Norte, AM',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('68651396587', '556004149187', 'Cecília Martins', 'Barros Travessa, 329, Saraiva do Norte, RN',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('83855298899', '597208340675', 'Salvador Barros', 'Macedo Alameda, 3116, undefined Mércia, RO',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('51026479906', '756869432772', 'Sirineu Martins', 'Roberta Marginal, 7363, undefined Bruna, RO',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('90985128022', '644131967797', 'Fábio Silva', 'Silas Rua, 89644, Xavier do Norte, GO',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('79479726215', '556808376661', 'Yango Souza', 'Gael Rodovia, 33251, undefined Danilo do Norte, SP',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('31219225791', '233573607448', 'Alessandra Braga', 'Xavier Marginal, 44374, undefined Eduarda, PR',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('58437837020', '341855683526', 'Bruna Martins', 'Alice Alameda, 72031, Saraiva do Norte, CE',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('55340310402', '874365838314', 'Anthony Souza', 'Isaac Travessa, 89, undefined Karla, MS',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('29969115727', '103895982145', 'Carlos Xavier', 'Macedo Alameda, 76128, Franklin, PB',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('89533223744', '815322195249', 'Antônio Moreira', 'Kléber Travessa, 76453, Austin, MS',
        'doutorado');
INSERT INTO Pessoa
VALUES ('61290123986', '429625294171', 'Anthony Xavier', 'Daniel Rua, 35497, undefined Elisa do Sul, RO',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('71656160976', '816310151736', 'Maria Luiza Franco', 'Carvalho Avenida, 8959, Marli do Descoberto, RO',
        'doutorado');
INSERT INTO Pessoa
VALUES ('45456711661', '636454921495', 'Ricardo Santos', 'Silva Rua, 83203, Lehigh Acres, RO',
        'doutorado');
INSERT INTO Pessoa
VALUES ('96782912428', '364003900415', 'Maria Luiza Saraiva', 'Oliveira Marginal, 19562, Rochester Hills, MS',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('98907837094', '714531698473', 'Salvador Reis', 'Fábio Rua, 16287, Moraes do Norte, SE',
        'superior completo');
INSERT INTO Pessoa
VALUES ('79309724329', '252857461688', 'Davi Saraiva', 'Joana Marginal, 12529, undefined Bernardo do Norte, PR',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('20158254010', '305558052798', 'Suélen Pereira', 'Batista Marginal, 91136, Hialeah, MS',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('93640094532', '941283495910', 'Manuela Albuquerque', 'Pedro Alameda, 90453, Márcia do Descoberto, PA',
        'mestrado');
INSERT INTO Pessoa
VALUES ('85598969515', '697355115460', 'Alícia Silva', 'Lorenzo Alameda, 98556, undefined Yasmin de Nossa Senhora, PB',
        'doutorado');
INSERT INTO Pessoa
VALUES ('84774450208', '362527867802', 'Gael Barros', 'Sophia Rodovia, 97941, Gulfport, SP',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('32125016890', '796349882730', 'Bruna Xavier', 'Samuel Alameda, 99008, undefined Sirineu, SP',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('43540165110', '831957060471', 'Matheus Martins', 'Mércia Rua, 45, undefined Núbia de Nossa Senhora, PE',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('57704504102', '727415131870', 'Ana Laura Silva', 'Nogueira Rua, 63624, Flint, RO',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('30543582160', '991152529674', 'Ana Júlia Braga', 'Murilo Alameda, 65791, Petaluma, MT',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('93402923154', '355419201287', 'Lorenzo Santos', 'Alexandre Rodovia, 27123, Rockville, PR',
        'superior completo');
INSERT INTO Pessoa
VALUES ('19081247556', '140771647775', 'Pablo Souza', 'Moreira Travessa, 86215, undefined Ana Clara, CE',
        'superior completo');
INSERT INTO Pessoa
VALUES ('64293432543', '740402489132', 'Gael Carvalho', 'Moraes Marginal, 99307, Pietro de Nossa Senhora, AM',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('55752608675', '890763629786', 'Fabrícia Batista', 'Oliveira Alameda, 17481, undefined Mariana, AP',
        'mestrado');
INSERT INTO Pessoa
VALUES ('86252562392', '609731758758', 'Elisa Carvalho', 'Carvalho Alameda, 59739, Eduarda do Norte, RN',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('69626756855', '238829423673', 'Felícia Macedo', 'Pablo Avenida, 3130, undefined Lara, RN',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('22932819214', '160356454877', 'Ana Clara Reis', 'Costa Alameda, 96032, Melo do Norte, RN',
        'doutorado');
INSERT INTO Pessoa
VALUES ('91896277903', '745111415931', 'Matheus Souza', 'Davi Lucca Alameda, 8798, undefined Ricardo, RJ',
        'superior completo');
INSERT INTO Pessoa
VALUES ('26279341266', '740973525354', 'Rafael Barros', 'Costa Marginal, 16877, Martins do Norte, SP',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('95690040225', '792570506059', 'Valentina Carvalho', 'Costa Rua, 37964, undefined Gabriel, PB',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('81192786749', '753771763411', 'Dalila Silva',
        'Barros Rodovia, 8961, undefined Alessandra de Nossa Senhora, MG',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('86534657040', '673884126963', 'Célia Albuquerque', 'Isabel Rodovia, 71693, Appleton, TO',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('78782798836', '407709100726', 'Heitor Oliveira', 'Ofélia Rodovia, 80300, undefined Isabelly, CE',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('29455049331', '702889422932', 'Salvador Albuquerque',
        'Saraiva Avenida, 59622, undefined Isabela de Nossa Senhora, PI',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('91382141099', '708261422184', 'Carlos Oliveira', 'Moraes Avenida, 90811, undefined Pablo do Norte, PB',
        'superior completo');
INSERT INTO Pessoa
VALUES ('89202787035', '684117819275', 'Silas Carvalho', 'Moreira Rua, 59054, Carvalho do Norte, MA',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('80014259815', '640090758912', 'Lorenzo Martins', 'Albuquerque Marginal, 26736, Karla do Norte, MS',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('61128608295', '278482510242', 'Felícia Martins', 'Caio Rua, 87520, Carvalho de Nossa Senhora, ES',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('36136912815', '776831409591', 'Maria Franco', 'Santos Alameda, 75865, Raul de Nossa Senhora, PA',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('13641347680', '989356579934', 'Maria Eduarda Oliveira', 'Souza Rodovia, 55979, Sunrise, PR',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('72597053705', '521928737428', 'Caio Moreira', 'Enzo Gabriel Avenida, 42371, undefined Maria Eduarda, ES',
        'mestrado');
INSERT INTO Pessoa
VALUES ('86885927871', '161064352071', 'Vitória Martins', 'Breno Avenida, 83784, Homestead, RS',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('39112057778', '577801035880', 'Lucca Santos', 'Braga Avenida, 44204, Barros de Nossa Senhora, SP',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('73767229476', '148744492279', 'Meire Batista', 'Rafaela Alameda, 36051, undefined Sara, MA',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('76882689699', '674323825887', 'Vitória Nogueira', 'Silva Rodovia, 99198, undefined Alice do Norte, RR',
        'superior completo');
INSERT INTO Pessoa
VALUES ('12062577367', '165657184692', 'Fabrícia Melo', 'Fabrício Marginal, 12350, Silva do Norte, PE',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('55804576182', '698222760832', 'Fabrício Macedo', 'Deneval Rua, 37011, undefined Salvador do Sul, DF',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('67022069275', '288523443718', 'Joana Martins', 'Carvalho Marginal, 66096, undefined Samuel do Descoberto, SP',
        'superior completo');
INSERT INTO Pessoa
VALUES ('51165132678', '293714380660', 'Bruna Silva', 'Hélio Alameda, 71734, undefined Hugo do Descoberto, AL',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('28253888052', '425674385624', 'Dalila Reis', 'Carvalho Alameda, 48110, undefined Mariana do Sul, GO',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('16891570298', '953417432308', 'César Albuquerque', 'Moraes Rodovia, 18428, Macedo do Sul, RO',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('22478564004', '737625859444', 'Laura Oliveira', 'Silva Rodovia, 865, undefined Arthur, RO',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('55515005839', '611468490562', 'Vitória Nogueira', 'Júlio César Rodovia, 73740, undefined Núbia, MA',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('57299066584', '737693471019', 'Suélen Carvalho', 'Washington Travessa, 59289, undefined Vitória do Sul, SP',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('61831559098', '365997886029', 'Gustavo Albuquerque', 'Lorena Rodovia, 6960, César do Norte, SP',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('66159643984', '365778319560', 'Alessandro Batista',
        'Pereira Travessa, 92107, undefined Vitória do Descoberto, RS',
        'superior completo');
INSERT INTO Pessoa
VALUES ('29222821181', '921150226308', 'Valentina Batista',
        'Marcela Travessa, 50678, undefined Marcelo do Descoberto, SC',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('53198584232', '725511316466', 'Roberta Melo', 'Heloísa Marginal, 78057, Albuquerque do Descoberto, TO',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('18246261053', '667599566862', 'Isabelly Pereira', 'Martins Marginal, 2937, undefined Esther, RJ',
        'doutorado');
INSERT INTO Pessoa
VALUES ('90560006066', '427225323743', 'Benjamin Reis', 'Júlio César Rodovia, 78473, Maricopa, RR',
        'doutorado');
INSERT INTO Pessoa
VALUES ('11846629010', '611108296085', 'Carlos Reis', 'Moraes Alameda, 72632, undefined João, AM',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('32739312681', '424811554607', 'Maria Luiza Macedo', 'Víctor Avenida, 51930, Santa Clarita, AP',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('89709084350', '816688167606', 'Felícia Saraiva', 'Martins Marginal, 86922, Santos do Descoberto, CE',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('86980507716', '844706240086', 'Liz Souza', 'Alice Marginal, 697, Rebeca do Sul, RO',
        'mestrado');
INSERT INTO Pessoa
VALUES ('62823072990', '804626310127', 'Lorraine Santos', 'Souza Avenida, 96979, Malden, PI',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('18505114549', '398261081916', 'Roberto Carvalho', 'Júlio Rua, 16670, Santos do Descoberto, AC',
        'mestrado');
INSERT INTO Pessoa
VALUES ('15123706744', '242950081056', 'Antônio Moreira', 'Reis Rua, 32682, Davie, MA',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('83156164272', '332107413420', 'Silas Batista', 'Lorena Marginal, 30773, Xavier de Nossa Senhora, MS',
        'doutorado');
INSERT INTO Pessoa
VALUES ('65929289441', '884670849097', 'Ricardo Nogueira', 'Melissa Travessa, 85439, undefined Alessandro, SE',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('43164160812', '710467999894', 'Isaac Souza', 'Alessandro Marginal, 44211, Félix do Sul, MS',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('28003311182', '119866520352', 'Maria Eduarda Reis', 'Gustavo Rua, 23719, Waukesha, TO',
        'doutorado');
INSERT INTO Pessoa
VALUES ('42961240594', '715447416156', 'Elisa Reis', 'Pedro Henrique Marginal, 61772, Murilo do Descoberto, DF',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('13525109647', '838778806477', 'Guilherme Barros', 'Lucca Rua, 22494, undefined Heloísa do Descoberto, AC',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('26038876282', '766333193215', 'Margarida Santos', 'Santos Rodovia, 61494, undefined Théo, AP',
        'doutorado');
INSERT INTO Pessoa
VALUES ('69618394083', '414769013482', 'Roberta Costa', 'Carvalho Marginal, 21731, Costa do Norte, RR',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('31128941818', '311272571189', 'Meire Carvalho', 'Batista Avenida, 51591, Moraes de Nossa Senhora, RS',
        'mestrado');
INSERT INTO Pessoa
VALUES ('60751450103', '643841706681', 'Vicente Franco', 'Silva Avenida, 21788, Paulo do Descoberto, CE',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('23625731619', '249910435243', 'Márcia Reis', 'Silva Rodovia, 7907, Calebe do Norte, PI',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('29139758762', '888697949564', 'Danilo Saraiva', 'Márcia Rua, 3954, Yago do Norte, DF',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('17060826153', '326290251500', 'João Melo', 'Sílvia Alameda, 71441, Madison, PI',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('44884157183', '153894656710', 'João Pedro Albuquerque',
        'Franco Avenida, 54023, undefined Marina do Descoberto, PI',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('21502376149', '717101258481', 'Margarida Pereira', 'Melo Marginal, 66200, undefined Enzo Gabriel, RJ',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('21211647114', '168739269580', 'Lorraine Braga', 'Xavier Marginal, 9910, Albany, TO',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('21425575076', '176952716195', 'Nataniel Macedo', 'Barros Rodovia, 72993, Schaumburg, AM',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('36079567898', '306459872657', 'Suélen Batista', 'Talita Alameda, 60394, undefined Joaquim do Sul, RN',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('93725932575', '607824709825', 'Cauã Melo', 'Isabella Avenida, 80909, Isabella do Norte, PE',
        'superior completo');
INSERT INTO Pessoa
VALUES ('93557888891', '201237980602', 'Davi Moraes', 'Alexandre Avenida, 59307, undefined Felipe do Descoberto, MT',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('88701410233', '467678892961', 'Melissa Costa', 'Franco Avenida, 95594, João do Sul, CE',
        'doutorado');
INSERT INTO Pessoa
VALUES ('85647496753', '536111154383', 'Yago Reis', 'Braga Rua, 69682, McAllen, BA',
        'mestrado');
INSERT INTO Pessoa
VALUES ('48673702988', '857499040383', 'Maria Eduarda Souza', 'Pietro Avenida, 33802, Murrieta, PA',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('14975074331', '807499389746', 'Júlio César Martins',
        'Silva Marginal, 72538, undefined Washington de Nossa Senhora, SE',
        'mestrado');
INSERT INTO Pessoa
VALUES ('18462353327', '346099924948', 'Lucas Oliveira', 'Benjamin Alameda, 50301, undefined Norberto do Norte, GO',
        'mestrado');
INSERT INTO Pessoa
VALUES ('40210098912', '533040334773', 'Lucas Franco', 'Matheus Avenida, 46844, Miguel do Norte, DF',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('54687466805', '567506145196', 'Antônio Batista',
        'Maria Eduarda Marginal, 90169, undefined Júlio César de Nossa Senhora, DF',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('74122189518', '762674024351', 'Paulo Souza', 'Moreira Avenida, 36017, undefined Rafaela, BA',
        'superior completo');
INSERT INTO Pessoa
VALUES ('89611346540', '638507423899', 'Beatriz Silva', 'Franco Travessa, 59190, Macedo do Sul, PB',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('18165175339', '262519370741', 'Benício Franco', 'Nogueira Marginal, 31979, Enzo Gabriel do Descoberto, RJ',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('72920575889', '566284221294', 'João Lucas Pereira', 'Feliciano Rodovia, 47255, Largo, ES',
        'superior completo');
INSERT INTO Pessoa
VALUES ('48237188747', '427347945119', 'Calebe Braga', 'Martins Avenida, 50363, Pittsfield, CE',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('52203854476', '259775326959', 'Carlos Saraiva', 'Yango Avenida, 96888, undefined Célia, AC',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('38185161759', '150771244009', 'Ana Júlia Xavier', 'Eduarda Avenida, 28080, undefined Anthony, AM',
        'doutorado');
INSERT INTO Pessoa
VALUES ('85739130568', '766574914101', 'Sarah Oliveira', 'Aline Travessa, 83922, Orland Park, GO',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('12991024018', '236217363853', 'Isadora Pereira', 'Maria Helena Rua, 17359, undefined Maitê, AM',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('36892929635', '579309152951', 'Carla Reis', 'Pietro Avenida, 17189, undefined Cauã do Sul, PR',
        'superior completo');
INSERT INTO Pessoa
VALUES ('98618554964', '488647384638', 'Valentina Macedo', 'Carvalho Rodovia, 80277, Macedo do Descoberto, PE',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('93351446241', '643362853373', 'Ígor Reis', 'Franco Rua, 46923, Raul do Descoberto, RS',
        'doutorado');
INSERT INTO Pessoa
VALUES ('25336353376', '307199931843', 'Janaína Souza', 'Silva Avenida, 36735, Feliciano do Norte, SE',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('61147306519', '612366822711', 'Tertuliano Moraes', 'Isis Marginal, 7776, undefined Isabel, SP',
        'superior completo');
INSERT INTO Pessoa
VALUES ('88576750692', '910618542879', 'Bernardo Saraiva', 'Batista Alameda, 77498, Macedo de Nossa Senhora, SE',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('25603374827', '692864302126', 'João Lucas Santos', 'Maria Cecília Alameda, 65176, undefined Samuel, AM',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('16081999130', '856358487997', 'Ofélia Martins', 'Albuquerque Rodovia, 6097, Roberta do Sul, GO',
        'superior completo');
INSERT INTO Pessoa
VALUES ('98036637124', '593625185615', 'Nicolas Carvalho', 'Maria Eduarda Alameda, 64167, Braga do Sul, PI',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('75318471796', '648488632962', 'Valentina Nogueira', 'Margarida Marginal, 11456, Reis de Nossa Senhora, MA',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('47530116646', '980665801535', 'Deneval Albuquerque', 'Silva Travessa, 64573, Nogueira do Norte, BA',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('44538643399', '443568723159', 'Enzo Gabriel Melo', 'Júlia Travessa, 24557, Wyoming, PE',
        'doutorado');
INSERT INTO Pessoa
VALUES ('22994280902', '268896007724', 'Norberto Moreira', 'Sara Marginal, 36208, Batista do Descoberto, SE',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('82171370822', '222748021595', 'Margarida Macedo', 'Reis Travessa, 75985, St. Louis, AC',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('42455865163', '940978830703', 'Isabel Moraes', 'Fabrícia Travessa, 69696, Santos do Descoberto, TO',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('80809978295', '660033864085', 'Vitória Pereira', 'Lorraine Alameda, 31672, Henderson, MT',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('36943202530', '584506323724', 'João Miguel Macedo', 'Oliveira Alameda, 28016, undefined Joaquim do Norte, MG',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('17909814855', '226523426920', 'Ricardo Saraiva', 'Ana Luiza Rua, 21349, undefined Davi, CE',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('99514881155', '539504077332', 'Júlia Saraiva', 'Núbia Marginal, 71317, undefined Marcelo, GO',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('53584502036', '404318242450', 'Felipe Moreira', 'Carlos Avenida, 28376, Raul do Descoberto, RS',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('25196086270', '769825185858', 'Fabrícia Martins', 'Lucca Rua, 60377, undefined Lavínia do Norte, SE',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('45746368169', '582324743364', 'Rafael Albuquerque', 'Janaína Avenida, 38470, undefined Isabel do Sul, MA',
        'superior completo');
INSERT INTO Pessoa
VALUES ('51697040249', '871105447714', 'Célia Oliveira', 'Souza Travessa, 91591, Emanuelly do Descoberto, MT',
        'mestrado');
INSERT INTO Pessoa
VALUES ('79293712463', '465915319998', 'Aline Souza',
        'Nogueira Rodovia, 70961, undefined Norberto de Nossa Senhora, RS',
        'mestrado');
INSERT INTO Pessoa
VALUES ('47333944300', '249825586914', 'Célia Souza', 'Moraes Alameda, 98421, Gulfport, AP',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('63795995046', '344650916638', 'Danilo Braga', 'Ofélia Rua, 75932, Pereira de Nossa Senhora, MS',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('63260848645', '976633368502', 'Lara Costa', 'Maria Cecília Avenida, 52163, Joaquim do Norte, GO',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('85319130541', '839412012114', 'Ígor Moreira', 'Lucas Marginal, 26081, undefined Kléber do Sul, MT',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('38939672771', '928251676843', 'Clara Moraes', 'Eduardo Rua, 98196, Heloísa de Nossa Senhora, AL',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('68038586615', '643084160960', 'João Xavier', 'Lucas Rodovia, 13914, undefined Pedro Henrique, PE',
        'mestrado');
INSERT INTO Pessoa
VALUES ('17353439859', '711347255879', 'Vitória Silva', 'Albuquerque Alameda, 54873, Melo do Descoberto, MT',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('76612723141', '457619980303', 'Silas Macedo', 'Carvalho Marginal, 49975, Towson, AL',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('90434170963', '846072864555', 'Isabelly Reis', 'Yango Rodovia, 12080, Ricardo de Nossa Senhora, PA',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('33932909250', '465765840490', 'Isis Braga', 'Melissa Marginal, 62003, undefined Gael, AP',
        'mestrado');
INSERT INTO Pessoa
VALUES ('16469240479', '312730140145', 'Suélen Moreira', 'Reis Marginal, 8614, undefined Benjamin, PI',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('74316856097', '321662148041', 'Morgana Xavier',
        'Albuquerque Travessa, 47832, undefined Maria Alice do Norte, RR',
        'doutorado');
INSERT INTO Pessoa
VALUES ('98239704843', '603511976520', 'Lucca Macedo', 'Lívia Marginal, 86384, undefined Isis, PA',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('83461462480', '462133768433', 'Mércia Costa', 'Saraiva Travessa, 57582, undefined Marcela, DF',
        'superior completo');
INSERT INTO Pessoa
VALUES ('90432507826', '687546789017', 'Beatriz Reis', 'Silva Travessa, 2606, undefined Salvador de Nossa Senhora, PR',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('76793153581', '673208221606', 'Maria Júlia Costa', 'Moreira Marginal, 4041, undefined Fabiano, PB',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('26868924126', '885428140219', 'Ladislau Pereira', 'Santos Rua, 77180, undefined Alícia, AM',
        'doutorado');
INSERT INTO Pessoa
VALUES ('72516597094', '688217693101', 'Heloísa Xavier', 'Isis Rua, 59775, undefined Ricardo do Descoberto, BA',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('56046937885', '279479536996', 'Lorraine Moraes', 'Melo Marginal, 91058, undefined Liz do Descoberto, AC',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('79646575415', '885273235733', 'Carla Albuquerque', 'Reis Rodovia, 27186, Pietro de Nossa Senhora, PB',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('62156000735', '880628972174', 'Tertuliano Nogueira', 'Liz Travessa, 26202, undefined Lorena do Descoberto, BA',
        'mestrado');
INSERT INTO Pessoa
VALUES ('97079823934', '281848207302', 'Yuri Souza', 'Moreira Alameda, 55778, Clarksville, AP',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('48873054108', '554125804710', 'Cecília Carvalho', 'João Pedro Avenida, 71538, Albuquerque do Norte, SC',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('48840457284', '117453833320', 'Enzo Saraiva', 'Rebeca Rodovia, 14607, undefined Rebeca, AC',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('91464355248', '855876787775', 'Sophia Oliveira', 'Márcia Avenida, 7940, undefined Rafael de Nossa Senhora, CE',
        'mestrado');
INSERT INTO Pessoa
VALUES ('29875680117', '318704083678', 'Lucca Pereira', 'Reis Rodovia, 86780, undefined Pietro, PI',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('27592656244', '473453486338', 'Cauã Macedo', 'Macedo Alameda, 58667, Silva de Nossa Senhora, AM',
        'doutorado');
INSERT INTO Pessoa
VALUES ('87764965905', '847646187595', 'Fabiano Moreira', 'Karla Rodovia, 59530, Gary, MS',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('79711277945', '707118433178', 'Suélen Carvalho', 'Melo Alameda, 64018, undefined Janaína, MG',
        'superior completo');
INSERT INTO Pessoa
VALUES ('29345624800', '671657872945', 'Silas Xavier', 'Reis Avenida, 57697, Sammamish, TO',
        'mestrado');
INSERT INTO Pessoa
VALUES ('94022594343', '508888148376', 'Fabrícia Silva', 'Norberto Rodovia, 29901, Southfield, RN',
        'superior completo');
INSERT INTO Pessoa
VALUES ('93598506252', '500919193495', 'Alice Moraes', 'Barros Rua, 41343, Clearwater, PR',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('29509833429', '612318872567', 'Carla Albuquerque', 'Théo Alameda, 61397, Morgana do Sul, GO',
        'mestrado');
INSERT INTO Pessoa
VALUES ('35275697032', '233933884487', 'Enzo Xavier', 'Melo Rodovia, 99671, Paula de Nossa Senhora, SE',
        'superior completo');
INSERT INTO Pessoa
VALUES ('16127951364', '367181377857', 'Benício Moraes', 'Silva Avenida, 75548, Barros de Nossa Senhora, RJ',
        'doutorado');
INSERT INTO Pessoa
VALUES ('68652663973', '267479572538', 'Gabriel Batista', 'Silva Avenida, 79117, Enzo de Nossa Senhora, SP',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('93407944291', '823392913141', 'Heitor Pereira', 'Lorenzo Rua, 30618, undefined Maria do Descoberto, GO',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('54873438458', '328516988945', 'Marcelo Santos', 'Silva Rodovia, 49281, Bristol, CE',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('91593408309', '830092559964', 'Marli Saraiva', 'João Lucas Rodovia, 23477, Batista do Descoberto, PR',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('33855974653', '739124146429', 'Esther Carvalho', 'Albuquerque Alameda, 31272, Alessandra de Nossa Senhora, RN',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('98786025829', '354944166354', 'Tertuliano Melo', 'Isabella Alameda, 69504, Macedo do Descoberto, MA',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('40780232739', '723999264091', 'Elisa Braga', 'Xavier Marginal, 20347, undefined João Lucas, SC',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('67661317153', '231537491246', 'Júlio César Barros', 'Braga Travessa, 25305, Rafaela de Nossa Senhora, PB',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('55587859393', '764514791080', 'Karla Barros',
        'Emanuelly Marginal, 40606, undefined Mariana de Nossa Senhora, MS',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('58593827674', '494247421319', 'Salvador Saraiva', 'Pablo Rua, 42570, Ana Luiza do Descoberto, AM',
        'mestrado');
INSERT INTO Pessoa
VALUES ('75875466403', '322864863346', 'Manuela Carvalho', 'Braga Rua, 12006, undefined Matheus, MA',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('16195919734', '600317901652', 'Marcela Nogueira', 'Barros Marginal, 46178, Martins de Nossa Senhora, ES',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('37135223362', '175004883226', 'Lorraine Macedo', 'Sara Rua, 32595, Isabelly do Norte, PB',
        'doutorado');
INSERT INTO Pessoa
VALUES ('52122835628', '183246634271', 'Larissa Nogueira', 'Calebe Travessa, 75393, Eloá de Nossa Senhora, RO',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('84286792359', '624996170448', 'Aline Silva', 'Silva Alameda, 73115, Eloá do Sul, RR',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('72560434259', '517125834617', 'Emanuelly Melo', 'Janaína Travessa, 44504, Yuma, MG',
        'mestrado');
INSERT INTO Pessoa
VALUES ('82760668424', '391259418777', 'Gúbio Batista', 'Xavier Travessa, 47911, Santos do Sul, MA',
        'mestrado');
INSERT INTO Pessoa
VALUES ('49390348521', '170939429267', 'Paulo Oliveira', 'Oliveira Rua, 55579, Albuquerque do Norte, GO',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('48582057354', '615991481393', 'Ladislau Barros', 'Moraes Rodovia, 83184, undefined Natália do Sul, MT',
        'mestrado');
INSERT INTO Pessoa
VALUES ('98071054182', '414956717612', 'Leonardo Reis', 'Alice Travessa, 37964, undefined Enzo Gabriel, TO',
        'mestrado');
INSERT INTO Pessoa
VALUES ('67891697345', '424533480149', 'Deneval Albuquerque', 'Daniel Avenida, 15599, Portage, RO',
        'mestrado');
INSERT INTO Pessoa
VALUES ('24276426893', '858976644813', 'Raul Santos', 'Meire Rua, 15811, undefined Laura, GO',
        'doutorado');
INSERT INTO Pessoa
VALUES ('25962785638', '952956214104', 'Alícia Carvalho', 'Cauã Rodovia, 32213, Normal, DF',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('95630513457', '758991739246', 'Giovanna Nogueira', 'Franco Rodovia, 34891, Carvalho de Nossa Senhora, RR',
        'superior completo');
INSERT INTO Pessoa
VALUES ('78031077992', '623213757481', 'Anthony Saraiva', 'Márcia Avenida, 55346, Marcos do Descoberto, BA',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('94947150240', '783456589700', 'Alice Xavier', 'Souza Rodovia, 15305, Souza do Norte, PA',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('48866858016', '833409941429', 'Roberto Reis', 'Franco Rua, 31504, undefined Ana Luiza, AP',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('76737339326', '782639195094', 'Davi Lucca Saraiva', 'Larissa Rodovia, 62017, Barros do Sul, ES',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('64671861850', '174926470313', 'Maria Alice Souza',
        'Pereira Marginal, 67574, undefined Hélio de Nossa Senhora, MT',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('18379429504', '540743623767', 'Hugo Nogueira', 'Albuquerque Marginal, 62044, Huntersville, BA',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('79031850325', '634219832532', 'Elísio Melo', 'Braga Alameda, 80002, Moreira do Sul, PB',
        'mestrado');
INSERT INTO Pessoa
VALUES ('79279382049', '565376669261', 'Ana Laura Saraiva', 'Warley Travessa, 43259, Marina de Nossa Senhora, RO',
        'doutorado');
INSERT INTO Pessoa
VALUES ('21775420166', '359997726208', 'Daniel Reis', 'Helena Travessa, 10245, Emanuel do Norte, RO',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('28842566022', '692851965012', 'Maria Helena Martins', 'Xavier Marginal, 23286, Danilo do Descoberto, TO',
        'doutorado');
INSERT INTO Pessoa
VALUES ('21313558840', '378674770891', 'Alexandre Oliveira', 'Souza Travessa, 83575, undefined João Miguel do Sul, SC',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('21282850208', '939667268842', 'Esther Silva', 'Silva Marginal, 82736, undefined Raul, PB',
        'mestrado');
INSERT INTO Pessoa
VALUES ('37938732800', '292236364050', 'Paulo Souza', 'Emanuel Avenida, 29806, undefined Davi, SC',
        'doutorado');
INSERT INTO Pessoa
VALUES ('17419773926', '739419436687', 'João Pedro Moreira', 'Noah Rodovia, 66458, Utica, PE',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('71320640726', '384390496276', 'Roberta Costa', 'Warley Marginal, 40839, Beatriz de Nossa Senhora, RO',
        'superior completo');
INSERT INTO Pessoa
VALUES ('55854224269', '537791293673', 'Rafaela Albuquerque', 'Melo Travessa, 59250, Chapel Hill, MT',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('17994645352', '426755854603', 'Nicolas Oliveira', 'Laura Avenida, 44824, undefined Fabiano, MA',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('60893714134', '700924551021', 'Ricardo Franco', 'Arthur Travessa, 37328, undefined Maria Helena, MS',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('95344005359', '730698387883', 'Emanuelly Macedo', 'Macedo Alameda, 22538, undefined Davi do Descoberto, AC',
        'superior completo');
INSERT INTO Pessoa
VALUES ('79691960571', '131954428367', 'Leonardo Costa', 'Miguel Rodovia, 46760, undefined Antônio, RR',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('79079376994', '417017611139', 'Matheus Batista', 'Albuquerque Rodovia, 64619, Leonardo do Descoberto, GO',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('28833782835', '249789526918', 'Raul Batista', 'Breno Marginal, 29677, Carlos de Nossa Senhora, PA',
        'superior completo');
INSERT INTO Pessoa
VALUES ('54644412510', '745345177361', 'Bruna Santos', 'Moreira Avenida, 13933, Macedo de Nossa Senhora, PB',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('76646342640', '515861228387', 'Morgana Franco', 'Souza Travessa, 89795, Germantown, SC',
        'doutorado');
INSERT INTO Pessoa
VALUES ('83073222993', '702566431951', 'Sílvia Moraes', 'Emanuelly Rodovia, 69013, Carvalho de Nossa Senhora, PI',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('98128233787', '834660920780', 'Natália Moraes', 'Franco Marginal, 90225, Sílvia do Descoberto, RR',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('56140621851', '206260287063', 'Suélen Albuquerque', 'Saraiva Marginal, 48384, Lorenzo do Norte, PI',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('66106046072', '587891162117', 'Lucas Silva', 'Moreira Marginal, 26065, undefined Bruna, TO',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('11703440623', '653955433634', 'Yasmin Macedo', 'Carvalho Alameda, 25731, DeSoto, AM',
        'superior completo');
INSERT INTO Pessoa
VALUES ('15441784567', '462285979604', 'Deneval Carvalho', 'Melo Travessa, 20071, undefined Larissa, RJ',
        'mestrado');
INSERT INTO Pessoa
VALUES ('89308487717', '514462813455', 'Suélen Santos', 'Morgana Alameda, 83351, Oliveira do Descoberto, PI',
        'superior completo');
INSERT INTO Pessoa
VALUES ('41465124920', '151660155947', 'Maria Silva', 'Isabella Travessa, 13485, undefined Pedro Henrique do Norte, BA',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('64847709590', '142138726124', 'Ricardo Reis', 'Santos Rua, 69422, undefined Fabiano do Descoberto, AP',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('11475470627', '813525843597', 'João Lucas Nogueira', 'Esther Avenida, 8712, undefined Liz do Sul, RN',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('42174338325', '364566463162', 'Lara Carvalho', 'Isabelly Rodovia, 38030, Moreira de Nossa Senhora, PA',
        'doutorado');
INSERT INTO Pessoa
VALUES ('98657625005', '275888313725', 'Manuela Pereira', 'Pereira Rodovia, 67939, undefined Paulo, RO',
        'superior completo');
INSERT INTO Pessoa
VALUES ('69571564621', '315039765811', 'Clara Xavier', 'Maria Júlia Rua, 39881, undefined Yasmin, GO',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('34139046359', '441549849580', 'Lara Nogueira', 'Gabriel Avenida, 53186, undefined Alessandra do Sul, MG',
        'doutorado');
INSERT INTO Pessoa
VALUES ('13690152484', '983058007177', 'Fabrício Silva',
        'Franco Travessa, 80565, undefined Pietro de Nossa Senhora, SE',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('47292644651', '204921054863', 'João Lucas Barros', 'Felícia Avenida, 46920, Júlio do Descoberto, DF',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('50634076290', '836047385842', 'Esther Franco', 'Fabrício Rodovia, 50201, undefined Miguel do Norte, CE',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('22331698350', '744697733595', 'Marina Souza', 'Franco Rua, 87579, Oliveira do Norte, AL',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('93231366153', '103492280561', 'Luiza Silva', 'Márcia Travessa, 97047, undefined Benício do Sul, MT',
        'mestrado');
INSERT INTO Pessoa
VALUES ('74947254906', '245336351473', 'Clara Santos',
        'Manuela Rodovia, 17478, undefined Emanuelly de Nossa Senhora, RJ',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('71402272270', '323118908354', 'Feliciano Albuquerque', 'Yago Rua, 98083, Moraes do Sul, RR',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('67951579191', '945014437334', 'Alessandro Nogueira', 'Barros Marginal, 95898, Wyoming, MS',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('55317056111', '973625683691', 'Guilherme Carvalho', 'Alessandro Alameda, 41749, Westminster, CE',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('27861878091', '108551923790', 'Matheus Pereira', 'Xavier Travessa, 9469, Honolulu, SE',
        'superior completo');
INSERT INTO Pessoa
VALUES ('77608265816', '775529610132', 'Benício Costa', 'Henrique Alameda, 49013, Santos do Descoberto, RS',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('48273120142', '695127770118', 'Sirineu Saraiva', 'Marcela Avenida, 92136, undefined Bryan do Norte, RR',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('17242466500', '906218864303', 'Félix Carvalho', 'Reis Rodovia, 58127, Hackensack, DF',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('23647714878', '499157637218', 'Raul Franco', 'Alice Rua, 58993, Saraiva do Norte, MT',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('59162837509', '279136657435', 'Benício Nogueira', 'Souza Marginal, 38604, Austin, PI',
        'superior completo');
INSERT INTO Pessoa
VALUES ('48550814816', '135223792423', 'Joana Franco', 'Hélio Marginal, 15364, Isabella do Sul, SC',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('96349825211', '624131092242', 'Feliciano Barros',
        'Marcos Alameda, 44065, undefined Fábio de Nossa Senhora, MT',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('73774401368', '837083511869', 'Pedro Henrique Costa',
        'Oliveira Rodovia, 40917, undefined Lorraine de Nossa Senhora, RO',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('52510659939', '840007317089', 'Aline Reis', 'Batista Rua, 39606, Norwalk, RR',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('55711421784', '701802229112', 'Maria Helena Souza', 'Isabela Rua, 1349, Janaína do Descoberto, PE',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('69286284870', '869648811244', 'Pedro Santos', 'Rafaela Rodovia, 84028, Barros do Sul, AC',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('49412925681', '761809118604', 'Mércia Moraes',
        'Carvalho Alameda, 40265, undefined Deneval de Nossa Senhora, MS',
        'doutorado');
INSERT INTO Pessoa
VALUES ('92413099054', '201477297139', 'Arthur Melo', 'Liz Rodovia, 15826, undefined Júlio César do Norte, PE',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('94240620594', '778463120339', 'Alexandre Reis', 'Gustavo Alameda, 22954, Benjamin de Nossa Senhora, AC',
        'doutorado');
INSERT INTO Pessoa
VALUES ('36344503618', '271075132186', 'Júlia Batista', 'Maria Helena Rua, 20874, Kokomo, GO',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('15051145425', '212316184025', 'Karla Moreira', 'Barros Travessa, 75331, Souza do Norte, AP',
        'superior completo');
INSERT INTO Pessoa
VALUES ('54014710634', '624509661528', 'Marcela Albuquerque', 'Ígor Rua, 84867, undefined Gael, BA',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('39911369015', '940770008158', 'João Miguel Pereira', 'Guilherme Alameda, 9407, undefined Alícia, AP',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('88489867446', '996226725773', 'Yuri Barros', 'Macedo Travessa, 11151, undefined Enzo, MT',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('86768067248', '622057955269', 'Lucca Pereira', 'Daniel Travessa, 93702, Silva do Norte, AL',
        'mestrado');
INSERT INTO Pessoa
VALUES ('99709735615', '167467256472', 'Ofélia Melo', 'Carvalho Travessa, 32964, Xavier do Sul, GO',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('58932911595', '591045595821', 'Gustavo Saraiva', 'Lorraine Rodovia, 48875, Sheboygan, MA',
        'mestrado');
INSERT INTO Pessoa
VALUES ('45083095934', '770733576500', 'Heitor Macedo', 'Martins Travessa, 23475, undefined Margarida, PA',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('72249765472', '467412577057', 'Maria Luiza Santos', 'Carvalho Rua, 8513, Daniel do Sul, GO',
        'doutorado');
INSERT INTO Pessoa
VALUES ('78893276196', '276702556735', 'Washington Martins', 'Macedo Rodovia, 45816, Oliveira do Descoberto, GO',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('15334344431', '243936799117', 'Ofélia Albuquerque', 'Sirineu Rodovia, 2445, Hartford, RN',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('77137697788', '974561614962', 'Tertuliano Reis', 'Vitória Rodovia, 20907, undefined Gustavo do Sul, AP',
        'doutorado');
INSERT INTO Pessoa
VALUES ('82639195390', '229604254313', 'Núbia Albuquerque', 'Souza Marginal, 61577, Rafael do Sul, AL',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('28168813411', '429562086239', 'Rafaela Melo', 'Barros Rua, 42810, undefined Paula, MG',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('41829273644', '863207873329', 'Hélio Martins', 'Macedo Marginal, 37550, undefined Paulo do Descoberto, AP',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('83423076674', '178847387991', 'Samuel Macedo', 'Maria Rodovia, 17413, Enzo do Norte, AC',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('53501761734', '287559422804', 'Calebe Melo', 'Braga Alameda, 28754, Vitor de Nossa Senhora, PR',
        'superior completo');
INSERT INTO Pessoa
VALUES ('50428395869', '459840632486', 'Rebeca Carvalho', 'Noah Rua, 95957, Moreira do Norte, MA',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('17823370946', '517832137155', 'Júlio Martins', 'Moreira Marginal, 42323, undefined Helena, CE',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('80154288623', '903896038397', 'Maria Xavier', 'Giovanna Rodovia, 86258, Taunton, RS',
        'mestrado');
INSERT INTO Pessoa
VALUES ('73645120004', '531778418924', 'Lara Nogueira', 'Warley Avenida, 22548, Danville, AP',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('82459476657', '415857045282', 'Alessandro Barros', 'Oliveira Rua, 84352, Antonella do Descoberto, SP',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('75642030232', '885422781459', 'Rafaela Franco', 'Luiza Rodovia, 70188, Macedo do Norte, MA',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('53509038442', '861815412272', 'Ofélia Moraes', 'Oliveira Marginal, 22909, Meire do Norte, AP',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('19436460018', '651820829021', 'João Pedro Barros', 'Saraiva Rua, 28161, Maria Helena do Descoberto, MT',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('97070763893', '697042964794', 'Tertuliano Melo', 'Manuela Alameda, 80192, undefined Lucca, AM',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('14897848735', '136046063830', 'Raul Carvalho', 'Barros Travessa, 52642, undefined Fabiano do Descoberto, RR',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('11253295710', '874906756053', 'Meire Albuquerque', 'Franco Marginal, 98839, Germantown, PI',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('88037559373', '137604702822', 'Davi Lucca Batista', 'Eduardo Alameda, 52695, Costa do Sul, RR',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('50291192873', '313478802936', 'Davi Xavier', 'Barros Rua, 55794, Nogueira de Nossa Senhora, SC',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('20972804070', '420122554525', 'Nataniel Souza', 'Lucas Rodovia, 67257, Portsmouth, RS',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('78880145065', '642533118510', 'Daniel Carvalho', 'Moraes Rodovia, 95327, Pedro Henrique do Sul, RS',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('26168256616', '666560211288', 'Benjamin Reis', 'Xavier Alameda, 76255, Luiza do Descoberto, AL',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('91148870261', '368126123538', 'Marcela Barros', 'Barros Rodovia, 88224, undefined Leonardo, AP',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('77054765247', '839570018323', 'Vitor Carvalho', 'Souza Avenida, 23802, undefined Carla do Norte, GO',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('18635187500', '588200640841', 'Lorraine Souza', 'Alícia Marginal, 5074, Kendale Lakes, PA',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('44631216491', '604576983442', 'Yago Nogueira', 'Felipe Rodovia, 27612, Macedo de Nossa Senhora, PE',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('60675624620', '520937312301', 'Vitória Macedo', 'Batista Avenida, 68017, Evanston, GO',
        'superior completo');
INSERT INTO Pessoa
VALUES ('83541382439', '472209071065', 'Manuela Saraiva',
        'Albuquerque Avenida, 97201, undefined Valentina do Descoberto, AM',
        'superior completo');
INSERT INTO Pessoa
VALUES ('57094455254', '515762439696', 'Víctor Braga', 'Moraes Rua, 38612, undefined João, MG',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('50921300621', '210909189586', 'Vicente Moraes', 'Ofélia Avenida, 39872, Rio Rancho, ES',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('75659786309', '361717456998', 'Roberta Moraes', 'João Rua, 75833, Macedo do Sul, MA',
        'superior completo');
INSERT INTO Pessoa
VALUES ('99605108487', '502701172279', 'Alícia Martins', 'Benício Rodovia, 92796, undefined Antônio do Sul, AC',
        'superior completo');
INSERT INTO Pessoa
VALUES ('38589444733', '429926765454', 'Maria Luiza Costa', 'Rafael Alameda, 16804, Idaho Falls, RS',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('10204609066', '608830009726', 'Murilo Pereira', 'Gustavo Alameda, 67685, undefined Clara do Sul, RS',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('12995957187', '226073220442', 'Alexandre Moraes', 'Melo Rua, 91996, undefined João, MT',
        'mestrado');
INSERT INTO Pessoa
VALUES ('32154909335', '989687907346', 'Noah Pereira', 'Paulo Marginal, 55670, Carvalho do Norte, PA',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('99903466564', '933959536440', 'Maria Cecília Barros', 'Nogueira Avenida, 24131, undefined Emanuelly, RS',
        'mestrado');
INSERT INTO Pessoa
VALUES ('27934283968', '735437070648', 'Rafaela Silva', 'Costa Travessa, 94704, Tamarac, PA',
        'mestrado');
INSERT INTO Pessoa
VALUES ('12347521192', '649751771101', 'Giovanna Saraiva', 'Albuquerque Alameda, 44610, undefined Maria Alice, RR',
        'doutorado');
INSERT INTO Pessoa
VALUES ('51003184649', '243727635010', 'Deneval Moreira', 'Fabiano Travessa, 47880, Santos do Descoberto, MT',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('79606743648', '733663155045', 'Maria Cecília Pereira', 'Bryan Alameda, 4223, Nogueira do Descoberto, TO',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('56224074342', '388479606481', 'Margarida Franco', 'Giovanna Alameda, 23210, undefined Eduarda, SE',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('77704517054', '350680487090', 'Raul Barros', 'Oliveira Avenida, 32469, Souza de Nossa Senhora, RS',
        'doutorado');
INSERT INTO Pessoa
VALUES ('14747534578', '332745527080', 'Sarah Oliveira', 'Macedo Avenida, 11171, Hélio de Nossa Senhora, PB',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('58487967234', '176460363622', 'Meire Souza', 'Kléber Rua, 87633, Anchorage, CE',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('19471678114', '335984035255', 'Benjamin Braga', 'Pereira Rodovia, 89446, Santos de Nossa Senhora, RS',
        'superior completo');
INSERT INTO Pessoa
VALUES ('44331545557', '286227933596', 'Washington Pereira', 'Albuquerque Marginal, 34521, Silva de Nossa Senhora, TO',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('67302381722', '848908197530', 'Kléber Silva', 'Melo Travessa, 77032, undefined Lara, SP',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('18723213032', '513744093338', 'Lorenzo Batista', 'Batista Travessa, 70718, Iowa City, RS',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('44931717652', '191055320249', 'Liz Souza', 'Alessandro Marginal, 28011, Clovis, CE',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('46028779612', '318641488673', 'Antonella Santos', 'Marcelo Rodovia, 29243, Moore, AP',
        'superior completo');
INSERT INTO Pessoa
VALUES ('69959773283', '271899154782', 'Roberto Moreira', 'Souza Avenida, 26281, Barros do Sul, DF',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('90615046252', '290211268374', 'Lavínia Pereira', 'Moraes Rodovia, 41482, undefined Eduardo, CE',
        'mestrado');
INSERT INTO Pessoa
VALUES ('24930473859', '238336716964', 'Fábio Barros', 'Saraiva Rodovia, 29310, Euclid, AL',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('43863967857', '888390352157', 'Mariana Pereira', 'Silva Alameda, 62574, Washington de Nossa Senhora, AC',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('59355980886', '286810823506', 'Isabelly Braga',
        'Albuquerque Rodovia, 21166, undefined Alícia de Nossa Senhora, AL',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('52959466576', '154382234113', 'Salvador Saraiva', 'Xavier Avenida, 4428, undefined Dalila do Sul, ES',
        'superior completo');
INSERT INTO Pessoa
VALUES ('96356041608', '847747890464', 'Sophia Moreira', 'Macedo Rodovia, 73234, Reis do Norte, SC',
        'superior completo');
INSERT INTO Pessoa
VALUES ('34047008347', '840590543742', 'Joaquim Silva', 'Xavier Marginal, 74513, undefined João, PA',
        'superior completo');
INSERT INTO Pessoa
VALUES ('42164321993', '695575841725', 'Rebeca Macedo', 'Pereira Rodovia, 61968, undefined Vitor, AP',
        'mestrado');
INSERT INTO Pessoa
VALUES ('33265460920', '573368181730', 'Lucas Albuquerque', 'Carvalho Rua, 51211, undefined Benício, MT',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('50650208310', '651519027911', 'Beatriz Braga', 'Tertuliano Rua, 93151, Santos do Norte, RJ',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('49220664729', '351734261214', 'Núbia Pereira', 'Gúbio Rodovia, 1180, undefined Márcia do Descoberto, CE',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('81137500617', '358354949252', 'Benício Reis', 'Sara Travessa, 25239, Surprise, MG',
        'superior completo');
INSERT INTO Pessoa
VALUES ('25756717512', '139555949741', 'Manuela Moraes', 'Santos Marginal, 73026, Dalila do Descoberto, SE',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('71762013956', '319490490178', 'João Moreira', 'Moraes Marginal, 87179, undefined Sirineu do Sul, SC',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('57039934452', '789809762174', 'João Pedro Oliveira', 'Nogueira Rua, 3066, undefined Lorraine, ES',
        'mestrado');
INSERT INTO Pessoa
VALUES ('66493321389', '724089176557', 'Bernardo Braga', 'Dalila Rua, 62498, Martins do Norte, RS',
        'mestrado');
INSERT INTO Pessoa
VALUES ('15705511113', '695946883852', 'Maria Júlia Oliveira', 'Lara Marginal, 48114, Ana Júlia de Nossa Senhora, DF',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('13162715234', '237688674102', 'Maria Luiza Reis', 'Melo Rua, 73641, undefined Luiza do Norte, TO',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('81479468415', '319994820281', 'Lorenzo Batista', 'Batista Travessa, 60670, Revere, AP',
        'superior completo');
INSERT INTO Pessoa
VALUES ('67031022950', '544684004434', 'Washington Pereira',
        'Calebe Rua, 83777, undefined João Miguel de Nossa Senhora, MS',
        'mestrado');
INSERT INTO Pessoa
VALUES ('40069712323', '769550354988', 'Lívia Silva', 'Silva Rodovia, 28237, Pietro do Sul, RS',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('99008050856', '604066471476', 'Alícia Nogueira', 'Albuquerque Alameda, 37447, undefined Breno, RS',
        'mestrado');
INSERT INTO Pessoa
VALUES ('83153095280', '845469993446', 'João Martins',
        'Albuquerque Avenida, 15394, undefined João Lucas do Descoberto, DF',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('16912034694', '838103586551', 'Noah Franco', 'Braga Travessa, 96581, Batista do Descoberto, GO',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('25737077812', '510410592425', 'Morgana Braga', 'Santos Rodovia, 79752, undefined Célia, MT',
        'doutorado');
INSERT INTO Pessoa
VALUES ('81435520064', '791314122686', 'Carlos Moreira', 'Lívia Travessa, 11750, Camarillo, TO',
        'superior completo');
INSERT INTO Pessoa
VALUES ('54967094177', '251305430987', 'Laura Batista', 'Silva Alameda, 22212, Pereira do Sul, RN',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('57793636212', '719065051432', 'Washington Carvalho', 'Joaquim Rua, 54422, Barros do Norte, AP',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('78188553669', '862235261173', 'Rebeca Reis', 'Macedo Rodovia, 20681, Peabody, RR',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('51977524964', '130849944148', 'César Oliveira', 'Esther Rua, 43664, Reis de Nossa Senhora, AC',
        'superior completo');
INSERT INTO Pessoa
VALUES ('37415883594', '483780211280', 'Gustavo Braga', 'Saraiva Alameda, 61374, Martins do Norte, PA',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('85275710606', '654616501135', 'Morgana Martins', 'Batista Rua, 44159, Brandon, BA',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('19264541170', '490819507068', 'Noah Carvalho', 'Souza Alameda, 96905, undefined Lucca, MA',
        'doutorado');
INSERT INTO Pessoa
VALUES ('29592667378', '955586051312', 'Eloá Santos', 'João Avenida, 79353, undefined Salvador, TO',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('25264475266', '341295420564', 'Maria Clara Barros', 'Luiza Avenida, 28254, Carla do Norte, MT',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('31276211123', '652056089346', 'Noah Costa', 'Liz Avenida, 29750, Moreira do Norte, PA',
        'doutorado');
INSERT INTO Pessoa
VALUES ('41136322179', '357550259097', 'Salvador Xavier', 'Macedo Alameda, 73360, undefined Vitor, RR',
        'doutorado');
INSERT INTO Pessoa
VALUES ('62782628233', '941891555627', 'Kléber Albuquerque', 'Braga Marginal, 67998, undefined Pietro do Norte, RJ',
        'superior completo');
INSERT INTO Pessoa
VALUES ('16521542130', '408525163447', 'Karla Martins', 'Martins Alameda, 6652, undefined Eloá, PB',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('92418782110', '869667285587', 'Emanuel Silva', 'Emanuelly Avenida, 87149, Reis do Norte, PE',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('31510259404', '460115873650', 'Larissa Moraes', 'Vitor Rodovia, 67677, undefined Alice de Nossa Senhora, AP',
        'mestrado');
INSERT INTO Pessoa
VALUES ('17366820771', '129682347550', 'Ana Laura Martins', 'Batista Rodovia, 1424, Carvalho do Norte, BA',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('11133646557', '484430828643', 'Lavínia Silva', 'Fabrícia Rua, 95433, Oliveira do Norte, ES',
        'doutorado');
INSERT INTO Pessoa
VALUES ('45510409004', '923053367179', 'Lucca Costa', 'Felícia Rodovia, 35023, Pereira do Descoberto, MS',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('70319649500', '399628653749', 'Maria Júlia Oliveira', 'Pedro Travessa, 24278, undefined Karla, MA',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('94981895470', '621240456099', 'Ana Júlia Moraes', 'Braga Rodovia, 81320, Vicente de Nossa Senhora, DF',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('58980360710', '612717755185', 'Alessandro Franco', 'Pereira Rodovia, 34934, Ígor de Nossa Senhora, RJ',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('98198924474', '906237357715', 'Júlia Braga', 'Reis Marginal, 71156, Waipahu, BA',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('10292860679', '777192685334', 'Sara Moreira', 'Sílvia Rodovia, 30556, Melo do Sul, RR',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('68093798568', '450424363487', 'Pietro Franco', 'Melo Rodovia, 48234, Franco do Descoberto, PA',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('86604477623', '176870474009', 'Kléber Albuquerque', 'Macedo Rua, 38703, Alice do Sul, MA',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('55582106600', '916080855042', 'Bruna Costa', 'Moraes Travessa, 78136, Isabela do Sul, RJ',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('56009768713', '156715638190', 'Isabela Xavier', 'Fabiano Travessa, 13088, Cecília do Sul, MG',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('82203919910', '295035305107', 'Raul Albuquerque', 'Carvalho Rodovia, 69713, Pereira do Sul, RS',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('46597759188', '726436051609', 'João Miguel Moraes', 'Joana Marginal, 59903, undefined Sara, SC',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('13129826323', '683472942258', 'Lucca Moreira', 'Joaquim Avenida, 77758, Santos do Descoberto, AM',
        'doutorado');
INSERT INTO Pessoa
VALUES ('51777044697', '396457611094', 'Vicente Pereira', 'Saraiva Rua, 82406, undefined Samuel, PA',
        'mestrado');
INSERT INTO Pessoa
VALUES ('40710145486', '981739233527', 'Yago Franco', 'Saraiva Rodovia, 33940, Taylor, RS',
        'mestrado');
INSERT INTO Pessoa
VALUES ('55121575377', '875146395503', 'Leonardo Albuquerque', 'Pereira Avenida, 50484, undefined Ricardo, TO',
        'superior completo');
INSERT INTO Pessoa
VALUES ('62031259345', '470524024590', 'Fabrício Xavier', 'Albuquerque Avenida, 1756, undefined Marli, PB',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('65379982653', '360401629167', 'Liz Moreira', 'Xavier Rua, 60808, Oliveira do Norte, RN',
        'mestrado');
INSERT INTO Pessoa
VALUES ('92312295855', '494723911350', 'Isadora Franco', 'Barros Alameda, 14981, undefined Maria Júlia, AL',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('84474516983', '193299718154', 'Janaína Barros', 'Alícia Marginal, 93188, Costa do Norte, SE',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('35410163693', '303659688984', 'Elisa Oliveira', 'Albuquerque Marginal, 20687, Silva do Norte, PA',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('52474887128', '711255017435', 'Esther Albuquerque', 'Albuquerque Rodovia, 73508, undefined Enzo, RO',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('37988147598', '497827086574', 'Luiza Xavier', 'Pereira Avenida, 18968, Inglewood, RO',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('10065442044', '497622452257', 'Giovanna Costa',
        'Alexandre Avenida, 51215, undefined Daniel de Nossa Senhora, AC',
        'doutorado');
INSERT INTO Pessoa
VALUES ('65208211410', '480380201223', 'Maria Clara Nogueira', 'Barros Marginal, 84796, Pereira do Norte, RN',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('53378136730', '804614367592', 'Roberta Moreira', 'Matheus Rua, 587, undefined Karla do Sul, AC',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('50331124449', '166612825589', 'Luiza Carvalho', 'Reis Alameda, 78113, Fábio do Descoberto, TO',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('50385235187', '745322862220', 'Salvador Oliveira', 'Nogueira Rua, 96714, Manuela de Nossa Senhora, PA',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('12213830926', '752061433764', 'Suélen Saraiva', 'Santos Rua, 35408, undefined Guilherme, MS',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('75511465452', '575377446715', 'Joaquim Oliveira',
        'Lorraine Alameda, 34005, undefined Carlos do Descoberto, BA',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('12044297421', '211017734394', 'Lorenzo Batista', 'Nogueira Marginal, 56792, Macedo do Descoberto, ES',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('69932859244', '155375282606', 'Joaquim Moreira', 'Braga Marginal, 92540, Pereira do Norte, AM',
        'mestrado');
INSERT INTO Pessoa
VALUES ('49999960965', '185099517670', 'Roberta Melo', 'Silva Marginal, 55073, Leonardo do Norte, PA',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('68321365918', '130386316985', 'Heloísa Souza', 'Carvalho Alameda, 61054, Carvalho de Nossa Senhora, GO',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('41139387378', '368675567139', 'Pablo Batista', 'Célia Alameda, 51285, Saraiva do Norte, BA',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('43344490984', '238533252058', 'Morgana Souza', 'Enzo Gabriel Travessa, 32135, undefined Davi, RS',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('83882872217', '255626036575', 'Ana Júlia Xavier', 'Pedro Henrique Alameda, 63457, undefined Yago do Sul, PA',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('94322587393', '546447021677', 'Yasmin Nogueira', 'Suélen Rua, 58081, Moreira de Nossa Senhora, SP',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('49697081230', '829808032070', 'Warley Saraiva', 'Carvalho Alameda, 33076, undefined Isis, PR',
        'mestrado');
INSERT INTO Pessoa
VALUES ('25392862658', '894060816103', 'Davi Lucca Braga', 'Carvalho Avenida, 7479, Souza do Sul, AL',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('26766975226', '325419477163', 'Paulo Franco', 'Paula Marginal, 14911, Pereira do Norte, ES',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('90733551590', '794214391941', 'Célia Saraiva', 'João Rodovia, 65138, Costa do Norte, GO',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('68099082331', '301256858231', 'Isabela Nogueira', 'Pereira Avenida, 76753, undefined Murilo, RR',
        'mestrado');
INSERT INTO Pessoa
VALUES ('84332452986', '491744096996', 'Nicolas Carvalho', 'Sirineu Alameda, 24335, Somerville, PI',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('34980392986', '248870784626', 'Pietro Souza', 'Noah Marginal, 67913, undefined Matheus, GO',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('97264050580', '300770022626', 'Guilherme Moreira', 'Pedro Henrique Avenida, 68978, Honolulu, PE',
        'doutorado');
INSERT INTO Pessoa
VALUES ('16470102223', '662219551787', 'Ígor Nogueira', 'Eduarda Marginal, 7109, Grapevine, PR',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('80229327632', '358370209764', 'Raul Reis', 'Reis Rua, 96890, Draper, SP',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('38465311408', '520722509478', 'Joana Barros', 'Giovanna Alameda, 83156, undefined Miguel, RS',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('48246632281', '572673402214', 'Esther Santos', 'Deneval Rua, 9432, Pereira do Descoberto, PB',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('84767766646', '762216453533', 'Sarah Melo', 'Martins Marginal, 32305, Calebe do Sul, AC',
        'doutorado');
INSERT INTO Pessoa
VALUES ('80291202422', '282153552910', 'César Braga', 'João Pedro Alameda, 40169, undefined Matheus do Norte, PE',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('45014148892', '914672320010', 'Lorraine Costa', 'Melo Rua, 60190, Franco do Descoberto, MG',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('25738695184', '353353100712', 'Hugo Oliveira', 'Maria Eduarda Alameda, 10294, Xavier do Sul, MT',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('54206616906', '833870471687', 'Júlio César Moraes', 'Santos Avenida, 59903, Maria Júlia de Nossa Senhora, PR',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('55212981896', '192901378893', 'Mércia Macedo', 'Moraes Rodovia, 85920, Maria Júlia do Sul, MS',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('93141531136', '589236676553', 'Pablo Braga', 'Cauã Avenida, 68626, Saraiva do Norte, RJ',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('49487133498', '314997251122', 'Maitê Franco', 'Pablo Rua, 56319, Caguas, BA',
        'superior completo');
INSERT INTO Pessoa
VALUES ('94417993945', '718641352513', 'Isis Moreira', 'Saraiva Marginal, 84675, Pereira do Sul, MA',
        'mestrado');
INSERT INTO Pessoa
VALUES ('62509119817', '290134122595', 'Felícia Pereira', 'Liz Rodovia, 2974, undefined Víctor, PA',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('84460796038', '158752977312', 'Maitê Macedo', 'Santos Alameda, 76737, undefined Ricardo do Norte, SC',
        'mestrado');
INSERT INTO Pessoa
VALUES ('29694294098', '208097290736', 'Carlos Martins', 'Melo Alameda, 9077, Beatriz do Descoberto, PB',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('42181111930', '735461484198', 'Janaína Carvalho', 'Costa Avenida, 80211, Felícia do Norte, DF',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('80518763633', '835836731013', 'Alessandro Moraes', 'Franco Rodovia, 77324, Paula do Sul, PE',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('65012076930', '350393035588', 'Calebe Oliveira', 'Reis Travessa, 1109, Garden Grove, PR',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('86836338876', '911261386238', 'Théo Reis', 'Saraiva Marginal, 67960, undefined Pablo do Norte, DF',
        'mestrado');
INSERT INTO Pessoa
VALUES ('67029859730', '905333403404', 'Tertuliano Pereira', 'Franco Avenida, 46742, Carlos de Nossa Senhora, MA',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('47411972254', '544862909032', 'João Pedro Carvalho', 'Pedro Henrique Rua, 29067, undefined Lucas do Norte, MT',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('28683887836', '172863343008', 'Maria Helena Pereira', 'Melo Travessa, 12427, undefined Clara, CE',
        'mestrado');
INSERT INTO Pessoa
VALUES ('85872988284', '863486227742', 'Murilo Reis', 'Melo Alameda, 91443, Lincoln, SC',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('74909855965', '845977561897', 'Cecília Melo', 'Carvalho Travessa, 85250, Lewisville, AM',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('79832300976', '377077810466', 'Ana Clara Pereira', 'Xavier Avenida, 2261, Esther do Descoberto, AL',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('73055091793', '504845053981', 'Laura Nogueira', 'Caio Rua, 88103, Eloá do Norte, AC',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('82543692174', '570699189719', 'Danilo Xavier', 'Costa Alameda, 37485, Boulder, MT',
        'mestrado');
INSERT INTO Pessoa
VALUES ('44661063903', '569343286124', 'Margarida Macedo', 'Xavier Alameda, 3294, undefined Eloá, AM',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('80214095890', '636893614800', 'Miguel Moreira', 'Xavier Marginal, 95658, undefined Maria, CE',
        'superior completo');
INSERT INTO Pessoa
VALUES ('45330556328', '953092132532', 'Emanuel Carvalho', 'Oliveira Rua, 70831, Porterville, CE',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('51308676458', '428660830692', 'Maria Cecília Martins', 'Lara Avenida, 35229, undefined Lorenzo do Norte, RR',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('78522324447', '754882570309', 'Eduarda Moreira', 'Martins Travessa, 28125, undefined Júlio, AL',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('95874667589', '351059005456', 'João Miguel Melo', 'Isabela Rua, 78184, undefined Ricardo, GO',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('60620319524', '388414652599', 'Manuela Melo', 'Marina Avenida, 94348, undefined Paulo do Descoberto, PE',
        'mestrado');
INSERT INTO Pessoa
VALUES ('53791592104', '191662072180', 'Gustavo Barros', 'Pablo Rodovia, 2528, undefined Carlos, PI',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('47100549493', '341757499380', 'Gustavo Braga', 'Santos Rua, 15845, Gabriel do Descoberto, TO',
        'mestrado');
INSERT INTO Pessoa
VALUES ('60686908485', '207649612659', 'Fabrício Pereira', 'Macedo Rua, 10060, Boulder, PA',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('61835304866', '828315174882', 'Meire Braga', 'Nogueira Rodovia, 44207, Moreira de Nossa Senhora, RJ',
        'superior completo');
INSERT INTO Pessoa
VALUES ('63358456494', '518193297646', 'Frederico Franco', 'Pereira Alameda, 33797, Moraes do Sul, RN',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('48008790058', '776367903966', 'Joana Carvalho', 'Ricardo Rua, 72238, undefined Lívia, AC',
        'superior completo');
INSERT INTO Pessoa
VALUES ('11120354053', '826979888672', 'Marcelo Santos', 'Nataniel Alameda, 73378, undefined Alessandra, PA',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('29078152088', '496783245634', 'Felícia Moreira',
        'Fabrício Avenida, 36328, undefined Célia de Nossa Senhora, GO',
        'mestrado');
INSERT INTO Pessoa
VALUES ('17360159694', '699471617676', 'Marcela Batista', 'João Miguel Marginal, 30139, Costa do Sul, MS',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('88044670873', '856285231630', 'Norberto Oliveira', 'Nogueira Rua, 63908, Eloá do Sul, MA',
        'doutorado');
INSERT INTO Pessoa
VALUES ('23858233627', '127606774377', 'Silas Melo', 'Ana Clara Rua, 20688, undefined Heitor de Nossa Senhora, AP',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('54304455467', '721641202759', 'Núbia Carvalho',
        'Santos Alameda, 23324, undefined Lorenzo de Nossa Senhora, PI',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('21448547421', '623217347450', 'Maria Luiza Martins',
        'Carvalho Travessa, 27643, Davi Lucca de Nossa Senhora, TO',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('90814044619', '752750996593', 'Marina Pereira', 'Lucca Rua, 43722, undefined Roberta, RR',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('32228380509', '722269322257', 'Elísio Reis', 'Reis Rua, 78248, Oliveira de Nossa Senhora, AC',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('35883675508', '781551540270', 'Maria Helena Albuquerque', 'Moraes Marginal, 91042, Catalina Foothills, MG',
        'mestrado');
INSERT INTO Pessoa
VALUES ('31626318043', '643644073978', 'César Macedo', 'Isadora Avenida, 26125, undefined Murilo, DF',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('38956106749', '388026811880', 'Sirineu Batista', 'Vicente Alameda, 2821, Helena do Descoberto, BA',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('85752784269', '368665224290', 'João Souza', 'Melo Travessa, 81280, Natália do Descoberto, PE',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('18092176485', '263460464007', 'Cecília Souza', 'Samuel Marginal, 50276, Silva de Nossa Senhora, PE',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('99693323471', '920956259849', 'Vitor Moraes', 'Carvalho Marginal, 65782, undefined Matheus, RJ',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('56206870884', '275378509401', 'Alessandro Carvalho', 'Pablo Travessa, 15185, Bayonne, BA',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('21124107418', '790404581837', 'Sarah Batista', 'Tertuliano Rodovia, 42211, undefined Frederico, PR',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('92776450554', '833538182033', 'Alessandra Reis', 'Souza Rua, 24616, Eugene, SP',
        'superior completo');
INSERT INTO Pessoa
VALUES ('42811426627', '108253900823', 'Enzo Nogueira', 'Célia Rodovia, 69404, undefined Bryan, MS',
        'mestrado');
INSERT INTO Pessoa
VALUES ('15702510098', '569354621600', 'Davi Nogueira', 'Lara Rua, 52305, undefined Meire, RS',
        'superior completo');
INSERT INTO Pessoa
VALUES ('29663832166', '276626514014', 'João Pedro Santos', 'Rafael Travessa, 48393, undefined Hélio do Norte, MT',
        'mestrado');
INSERT INTO Pessoa
VALUES ('86638707953', '267408174648', 'Heitor Oliveira', 'Moreira Rua, 57008, undefined Meire, CE',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('67214462850', '406089162570', 'Fábio Braga', 'João Rodovia, 78920, Fabrício do Descoberto, AP',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('39589262660', '615958208590', 'Maria Luiza Franco', 'Martins Rua, 65676, undefined Rafael do Sul, ES',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('22431804153', '911635970138', 'Yango Batista', 'Xavier Alameda, 48298, Albuquerque do Norte, MG',
        'doutorado');
INSERT INTO Pessoa
VALUES ('98747927837', '651187807577', 'Margarida Oliveira', 'Reis Rodovia, 11028, Bend, PR',
        'doutorado');
INSERT INTO Pessoa
VALUES ('57039100097', '153596998774', 'Maria Eduarda Batista', 'Isabelly Alameda, 9345, Santos do Descoberto, PB',
        'superior completo');
INSERT INTO Pessoa
VALUES ('84068701420', '785262479959', 'Gabriel Albuquerque', 'Santos Rodovia, 77635, Isabelly do Sul, AP',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('53343223149', '880741925025', 'Silas Moreira', 'Costa Rodovia, 34824, Lawrence, PB',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('42162135574', '500135387480', 'Marcelo Carvalho', 'Carvalho Travessa, 29617, undefined Margarida, DF',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('21487003488', '497206684504', 'Maria Silva', 'Costa Marginal, 99919, undefined Cauã, DF',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('20934364222', '163617045804', 'Gabriel Santos', 'Moraes Travessa, 53304, Lodi, CE',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('70565871405', '126381650473', 'Víctor Costa', 'Arthur Travessa, 34550, Víctor de Nossa Senhora, RO',
        'doutorado');
INSERT INTO Pessoa
VALUES ('54183079097', '853505813283', 'Fábio Martins', 'Yasmin Marginal, 27088, Martins do Norte, SE',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('30621758850', '911497609014', 'Isabella Moreira', 'Meire Alameda, 5354, Broken Arrow, SE',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('16082053717', '220035137748', 'Antônio Nogueira', 'Morgana Travessa, 2416, Nataniel de Nossa Senhora, RO',
        'superior completo');
INSERT INTO Pessoa
VALUES ('41769931132', '396053647156', 'Breno Macedo', 'Moraes Alameda, 34043, Esther de Nossa Senhora, SC',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('50671691924', '753717271401', 'Frederico Pereira', 'Moraes Alameda, 80769, Núbia do Sul, PR',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('20370718555', '167591730249', 'João Pedro Batista', 'Silva Travessa, 61522, Costa de Nossa Senhora, PA',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('71272484597', '969362682104', 'Mércia Braga', 'Ana Júlia Marginal, 57416, Arthur do Norte, PA',
        'doutorado');
INSERT INTO Pessoa
VALUES ('30869886612', '466847695456', 'Maria Barros', 'Esther Alameda, 92061, João Lucas do Sul, MG',
        'superior completo');
INSERT INTO Pessoa
VALUES ('83675283405', '352862746175', 'Leonardo Barros', 'Gabriel Marginal, 21412, Larissa do Sul, AC',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('83687715737', '927888443088', 'Feliciano Reis', 'Barros Alameda, 78789, Saraiva do Sul, RR',
        'superior completo');
INSERT INTO Pessoa
VALUES ('28302243251', '626157754077', 'Yango Costa', 'Moreira Rua, 11755, undefined João Lucas, PA',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('83880074904', '718165473733', 'Murilo Silva', 'Karla Avenida, 66401, undefined Mariana, AP',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('48100007649', '547232662490', 'Washington Xavier', 'Yuri Avenida, 98562, Nampa, RO',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('11269307890', '579256237787', 'Lavínia Costa', 'Morgana Travessa, 4121, Concord, RO',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('76628472611', '708304541418', 'Marina Barros', 'Davi Lucca Marginal, 36711, West Allis, SP',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('97614736857', '901070685754', 'Salvador Silva', 'Sara Rodovia, 44887, Alexandria, ES',
        'superior completo');
INSERT INTO Pessoa
VALUES ('44202141419', '865198708185', 'Frederico Pereira', 'João Alameda, 78580, Hollywood, SC',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('54358800731', '248243596986', 'Elísio Santos', 'Yuri Rodovia, 64164, undefined Warley do Descoberto, RO',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('43359677735', '290137074701', 'Pablo Braga', 'Sirineu Marginal, 66396, Ofélia do Norte, AC',
        'superior completo');
INSERT INTO Pessoa
VALUES ('67123855608', '776479593664', 'Ana Luiza Souza', 'Albuquerque Avenida, 56789, undefined Heitor do Sul, MG',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('61577998858', '279290752857', 'Elísio Martins', 'Santos Avenida, 47406, Santos do Sul, AP',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('76957148555', '106995480437', 'Alexandre Xavier', 'Frederico Rua, 95517, Carvalho de Nossa Senhora, PB',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('35126160527', '989245392521', 'Roberta Costa', 'Pablo Alameda, 8390, Las Vegas, RO',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('20277851468', '829277757671', 'Mariana Costa', 'Daniel Rodovia, 2208, undefined Sílvia, RO',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('55183109673', '207433929108', 'Maria Clara Batista', 'Reis Rodovia, 9242, Lorraine do Norte, PB',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('34528599961', '127011743071', 'Larissa Albuquerque', 'Raul Travessa, 37843, Larissa de Nossa Senhora, TO',
        'superior completo');
INSERT INTO Pessoa
VALUES ('33952316290', '844739153096', 'Davi Albuquerque', 'Liz Alameda, 31132, undefined Marcela do Descoberto, PE',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('58012603018', '743794496776', 'Marli Souza', 'Núbia Avenida, 57655, Luiza do Descoberto, SP',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('66035738396', '397999277571', 'Suélen Santos', 'Martins Avenida, 39543, Davenport, MS',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('22103242517', '705887000425', 'Salvador Nogueira', 'Deneval Avenida, 72537, Víctor do Sul, SP',
        'superior completo');
INSERT INTO Pessoa
VALUES ('56002168338', '208384595974', 'Elisa Reis', 'Barros Rua, 3079, undefined Enzo Gabriel do Descoberto, SC',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('93630574638', '340479336888', 'Eduardo Silva', 'Sarah Rodovia, 51411, Lavínia do Norte, SE',
        'superior completo');
INSERT INTO Pessoa
VALUES ('30010755995', '234906207467', 'Aline Martins',
        'Eduardo Rodovia, 85796, undefined Henrique de Nossa Senhora, RO',
        'superior completo');
INSERT INTO Pessoa
VALUES ('11529379235', '834036870906', 'Felipe Souza', 'Ricardo Rua, 24011, Phoenix, TO',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('99220432315', '943633088585', 'Víctor Braga', 'Lorraine Rua, 878, Reis do Sul, RO',
        'superior completo');
INSERT INTO Pessoa
VALUES ('40851067951', '925259346212', 'Rebeca Martins', 'Gabriel Travessa, 36386, Yasmin de Nossa Senhora, BA',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('46683265664', '890162249398', 'Maria Eduarda Macedo', 'Lucca Marginal, 57646, Carlos do Sul, RJ',
        'superior completo');
INSERT INTO Pessoa
VALUES ('63931753861', '517949781147', 'Rebeca Nogueira', 'Yuri Travessa, 49329, undefined Sophia de Nossa Senhora, PE',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('49829237502', '575392054487', 'Ana Clara Franco', 'Reis Rodovia, 72570, undefined Rebeca do Sul, MA',
        'mestrado');
INSERT INTO Pessoa
VALUES ('60173086568', '516159216151', 'Giovanna Saraiva', 'Santos Rodovia, 5068, Xavier do Norte, RR',
        'mestrado');
INSERT INTO Pessoa
VALUES ('22237183297', '568284185719', 'Sophia Nogueira', 'Larissa Alameda, 9853, Murrieta, MA',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('74132363493', '433553255372', 'Bernardo Martins', 'Santos Travessa, 71359, undefined Júlio do Descoberto, RO',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('22161167713', '409948054794', 'Guilherme Reis', 'Benício Rua, 57438, César do Norte, RS',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('99356726461', '718945289123', 'Isabel Barros', 'Braga Rodovia, 94412, undefined Sílvia, RJ',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('72124885278', '339667981234', 'Ladislau Martins', 'Saraiva Rodovia, 60698, undefined Aline do Norte, RS',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('12673338970', '937255639815', 'Ígor Oliveira', 'Maria Luiza Avenida, 50343, Barros do Descoberto, CE',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('83129861042', '246057743532', 'Lívia Costa', 'Ricardo Alameda, 75607, Palm Beach Gardens, MT',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('84785704296', '483675170945', 'Marina Martins', 'Mércia Avenida, 76146, undefined Antônio do Sul, MS',
        'superior completo');
INSERT INTO Pessoa
VALUES ('15691747337', '492169188358', 'Yasmin Franco',
        'Carvalho Avenida, 92057, undefined Cecília de Nossa Senhora, SC',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('95204672040', '323997421702', 'Aline Oliveira', 'Aline Alameda, 29056, Vitor do Sul, CE',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('75192492567', '963654924766', 'Ricardo Macedo', 'Marcela Alameda, 6177, Castle Rock, ES',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('64779439785', '195363105088', 'Pedro Reis', 'Melo Avenida, 42617, San Ramon, RR',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('98543534772', '108942875661', 'Marcos Moreira', 'Nogueira Avenida, 18104, undefined Warley, MA',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('80266070396', '360520742717', 'João Pedro Santos', 'Braga Alameda, 91956, Deltona, PR',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('72299882841', '707096961466', 'Fabrícia Albuquerque', 'Pereira Alameda, 65826, Torrance, MA',
        'superior completo');
INSERT INTO Pessoa
VALUES ('65327025726', '484338518325', 'Talita Souza', 'Nogueira Alameda, 14882, Laura do Sul, CE',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('48776552942', '358553229249', 'Gúbio Carvalho', 'Franco Marginal, 98122, Franco do Norte, RS',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('95605694998', '376735100848', 'Fabrícia Reis', 'Breno Avenida, 40534, Jersey City, AC',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('14908314673', '548533605947', 'Hélio Pereira', 'Reis Rua, 59547, Moreira do Sul, RO',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('78310490557', '285754414531', 'Sara Oliveira', 'Reis Alameda, 89595, Oak Park, RS',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('19397940060', '622995635634', 'Benício Oliveira', 'Gabriel Rua, 52769, Durham, AC',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('60623790931', '797334964433', 'Sophia Silva', 'Márcia Rua, 15300, Fort Smith, MG',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('74355497739', '254750704579', 'Maria Clara Oliveira',
        'Kléber Travessa, 29081, Enzo Gabriel de Nossa Senhora, BA',
        'superior completo');
INSERT INTO Pessoa
VALUES ('45168306697', '387460939749', 'Calebe Nogueira', 'João Lucas Travessa, 37919, undefined Isaac, PE',
        'mestrado');
INSERT INTO Pessoa
VALUES ('34864473633', '379397132317', 'Salvador Saraiva', 'Martins Rua, 78299, undefined Felipe do Descoberto, GO',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('90606078894', '260261762747', 'Dalila Moraes', 'Joaquim Rua, 52399, Reis do Sul, TO',
        'mestrado');
INSERT INTO Pessoa
VALUES ('12061152968', '151085510058', 'Janaína Moreira',
        'Albuquerque Marginal, 53005, undefined Ana Júlia do Norte, CE',
        'mestrado');
INSERT INTO Pessoa
VALUES ('98850444883', '760890439804', 'Maria Eduarda Nogueira', 'Giovanna Rodovia, 90137, Pereira do Sul, MT',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('83759686551', '682409421447', 'Ígor Martins', 'Carvalho Avenida, 78889, Sarah de Nossa Senhora, MS',
        'doutorado');
INSERT INTO Pessoa
VALUES ('24106467796', '231022426020', 'Bruna Moraes', 'Saraiva Avenida, 71152, Wheaton, AP',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('42516188630', '951866581360', 'Calebe Santos', 'Arthur Avenida, 30860, Salvador de Nossa Senhora, MG',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('55833025514', '987031770241', 'Bernardo Braga', 'Gael Marginal, 48565, undefined Gabriel do Sul, MT',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('27500320235', '718603983474', 'Guilherme Saraiva', 'Isabella Marginal, 82029, undefined Marcos, PR',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('63795820032', '155438176007', 'Karla Albuquerque', 'Pereira Rua, 27953, undefined Pedro Henrique do Norte, PI',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('58254329771', '826124701322', 'Yango Batista', 'Emanuelly Travessa, 85654, Reis do Sul, RN',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('64375204483', '718016040115', 'Hugo Martins', 'Barros Rua, 53697, undefined João Lucas do Descoberto, AC',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('96180057683', '247142194374', 'Ana Júlia Costa', 'Emanuel Rua, 85319, Margate, DF',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('69487778153', '933394578984', 'Ana Clara Carvalho', 'Fábio Rua, 94508, Emanuel do Descoberto, MT',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('56133283516', '571257988992', 'Yago Pereira', 'Beatriz Alameda, 33580, Maria Alice do Descoberto, SE',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('61363971529', '232105346955', 'Ana Laura Albuquerque', 'Carvalho Travessa, 23484, Costa de Nossa Senhora, AL',
        'superior completo');
INSERT INTO Pessoa
VALUES ('73590556099', '889956435747', 'Fabiano Oliveira', 'Alexandre Rua, 8940, Fabiano de Nossa Senhora, RO',
        'mestrado');
INSERT INTO Pessoa
VALUES ('14159918951', '124139968724', 'Alícia Barros', 'Margarida Rua, 85024, Maria Helena de Nossa Senhora, AP',
        'doutorado');
INSERT INTO Pessoa
VALUES ('26263470866', '426359815127', 'Bernardo Melo', 'Maria Cecília Rua, 79208, Union City, PA',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('97759025976', '327247839304', 'Sílvia Silva', 'Xavier Rodovia, 53416, Costa do Sul, SE',
        'mestrado');
INSERT INTO Pessoa
VALUES ('17152655287', '112303497898', 'Eduarda Costa', 'Frederico Alameda, 32903, Keller, SC',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('34757250568', '112390993023', 'Alícia Martins', 'Saraiva Rodovia, 68936, Lucca do Norte, MA',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('47442891250', '591566623933', 'Maria Braga', 'Martins Travessa, 83697, La Crosse, AP',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('44674791889', '831416267831', 'Lucca Macedo', 'Reis Travessa, 40168, Bernardo do Descoberto, PB',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('41525154309', '160704359179', 'Talita Albuquerque', 'Souza Travessa, 29950, Bloomington, RO',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('41830698924', '572503378870', 'Marcos Macedo', 'Marli Avenida, 64007, Silva do Sul, PI',
        'doutorado');
INSERT INTO Pessoa
VALUES ('30848156486', '831693002651', 'Maria Alice Xavier',
        'Albuquerque Alameda, 64879, undefined Salvador do Descoberto, MS',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('56085495813', '392704756651', 'Leonardo Martins', 'Lara Rua, 12282, Compton, AP',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('15118655033', '332886684406', 'Lorenzo Batista', 'Albuquerque Avenida, 7128, Barros do Norte, AC',
        'doutorado');
INSERT INTO Pessoa
VALUES ('64280859939', '936935267131', 'Miguel Martins', 'Maria Alice Alameda, 81546, Norberto do Norte, RJ',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('34828906285', '979526302334', 'Heitor Melo', 'Pereira Marginal, 7509, Martins de Nossa Senhora, RN',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('98227631277', '699275897722', 'Rafaela Costa', 'Bryan Rodovia, 41202, Charlottesville, TO',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('61699634627', '743917873362', 'Isadora Carvalho', 'Nogueira Marginal, 32556, Perth Amboy, SC',
        'superior completo');
INSERT INTO Pessoa
VALUES ('76445934206', '863493780465', 'Yasmin Melo', 'Santos Marginal, 54943, undefined Washington, GO',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('39602867474', '140630804141', 'Mariana Moreira', 'Braga Travessa, 87044, undefined Sophia, RO',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('52176460425', '649132075207', 'Yago Silva', 'Emanuel Avenida, 34877, Spokane Valley, PR',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('40100553724', '840726930089', 'Júlia Oliveira',
        'Isabelly Alameda, 74125, undefined Vitória de Nossa Senhora, CE',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('43260389566', '137894949899', 'Raul Souza', 'Oliveira Travessa, 47800, undefined Deneval, DF',
        'doutorado');
INSERT INTO Pessoa
VALUES ('63891801896', '590843299846', 'Marcos Braga', 'Kléber Avenida, 55493, undefined Ladislau, SC',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('75959301025', '242942856275', 'Bruna Barros', 'Moreira Marginal, 35801, undefined Joana, PR',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('92624975838', '607001786096', 'Célia Saraiva', 'Xavier Marginal, 60079, undefined Fabrício, AL',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('68038124940', '331463169236', 'Cecília Melo', 'Manuela Rodovia, 66294, Reis de Nossa Senhora, PA',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('92302586049', '874044035887', 'Warley Carvalho', 'Eduarda Marginal, 67427, undefined Eloá do Descoberto, BA',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('38865358545', '762639182666', 'Marcela Pereira', 'Alessandra Rodovia, 77963, undefined Margarida, PA',
        'doutorado');
INSERT INTO Pessoa
VALUES ('48741819467', '916880772542', 'Júlio César Souza', 'Costa Alameda, 33239, undefined Samuel do Sul, RR',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('73991621742', '937659930647', 'Miguel Reis', 'Enzo Gabriel Rua, 84555, Tyler, SE',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('68666926997', '563741336273', 'Gabriel Moreira', 'Moreira Marginal, 19989, Batista de Nossa Senhora, PE',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('95093021779', '460522345034', 'Júlio Braga', 'Xavier Travessa, 47427, Indio, SE',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('32508439864', '961618011025', 'Gabriel Oliveira', 'Souza Rodovia, 78479, undefined Pedro do Norte, PB',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('28238024273', '568057846464', 'Larissa Moraes', 'Esther Rodovia, 55201, Souza do Descoberto, AM',
        'mestrado');
INSERT INTO Pessoa
VALUES ('28123944120', '700915335537', 'Félix Moreira', 'Nogueira Rua, 87678, João Miguel de Nossa Senhora, MT',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('14330129588', '644873014581', 'Gael Oliveira', 'Macedo Alameda, 46227, undefined Maria Cecília do Sul, SE',
        'mestrado');
INSERT INTO Pessoa
VALUES ('39573748449', '580480368644', 'Ladislau Oliveira', 'Silas Avenida, 92527, undefined Tertuliano do Norte, RO',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('65680290067', '557535057701', 'Joana Souza', 'Nogueira Avenida, 41368, Paula do Norte, RJ',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('44038899224', '862873222283', 'Heloísa Costa', 'Heitor Rodovia, 49787, Lívia de Nossa Senhora, MT',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('44387366895', '432336252904', 'Daniel Xavier', 'Saraiva Marginal, 67875, Savannah, SP',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('58588938803', '983127719257', 'Fabrício Carvalho',
        'Barros Rodovia, 35726, undefined Eloá de Nossa Senhora, PI',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('31959316115', '592998679424', 'Antônio Franco', 'Xavier Rua, 17135, San Bruno, MA',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('61657774816', '235755721526', 'Rebeca Xavier', 'Moreira Rua, 34551, undefined Alícia, PB',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('27744644728', '356106606824', 'Mércia Franco', 'Marina Alameda, 47067, Tertuliano do Descoberto, RJ',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('28760097629', '327841930370', 'Lavínia Pereira',
        'Saraiva Rodovia, 65401, undefined Sirineu de Nossa Senhora, ES',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('99712320971', '713346170471', 'Fábio Moraes', 'Laura Rua, 83522, Roberto do Norte, CE',
        'mestrado');
INSERT INTO Pessoa
VALUES ('96588067063', '386077960091', 'Anthony Albuquerque', 'Xavier Avenida, 44206, Samuel do Norte, PR',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('81603123238', '998257416160', 'Raul Albuquerque', 'Lucca Rua, 17345, Nampa, ES',
        'mestrado');
INSERT INTO Pessoa
VALUES ('17597543469', '806826684181', 'Antônio Carvalho', 'Hélio Marginal, 9483, undefined Margarida, PB',
        'doutorado');
INSERT INTO Pessoa
VALUES ('45288225223', '502596448361', 'Pablo Pereira', 'Leonardo Rua, 26224, Springfield, PI',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('96358525417', '710552023653', 'Antônio Batista', 'Yasmin Alameda, 41101, Oliveira do Descoberto, SP',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('82078275873', '260598889389', 'Lorenzo Santos', 'Clara Rodovia, 21731, undefined Liz, MS',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('91867517477', '939774867543', 'Helena Xavier', 'Martins Marginal, 68660, Wichita Falls, PR',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('53392276959', '337520635500', 'Silas Martins', 'Melo Rodovia, 39778, Costa do Descoberto, RN',
        'doutorado');
INSERT INTO Pessoa
VALUES ('68482680276', '845251213409', 'Emanuel Batista', 'Maria Eduarda Rua, 36738, Bruna do Sul, PR',
        'mestrado');
INSERT INTO Pessoa
VALUES ('30518274260', '779776897327', 'Noah Pereira', 'Feliciano Travessa, 50394, undefined Lara, AC',
        'doutorado');
INSERT INTO Pessoa
VALUES ('45923760337', '965386870084', 'Meire Carvalho', 'Melo Rodovia, 42204, Spring, AC',
        'superior completo');
INSERT INTO Pessoa
VALUES ('80954469083', '224468119512', 'Bernardo Reis', 'Albuquerque Rodovia, 80378, undefined Víctor, MA',
        'mestrado');
INSERT INTO Pessoa
VALUES ('33005915498', '854542887932', 'Sarah Braga', 'Braga Rua, 23367, Helena do Norte, MA',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('75071605008', '570977751165', 'Heitor Braga', 'Reis Travessa, 7755, undefined Ana Luiza, MG',
        'mestrado');
INSERT INTO Pessoa
VALUES ('60858012235', '992128829448', 'Heitor Nogueira', 'Marli Rua, 85746, Albuquerque do Sul, MA',
        'superior completo');
INSERT INTO Pessoa
VALUES ('97555941788', '528223174135', 'Isaac Pereira', 'Santos Rodovia, 82302, Silva de Nossa Senhora, RO',
        'mestrado');
INSERT INTO Pessoa
VALUES ('36720092277', '835687928344', 'Liz Carvalho', 'Beatriz Alameda, 70070, undefined Lorenzo do Norte, MG',
        'doutorado');
INSERT INTO Pessoa
VALUES ('41320017329', '968361740792', 'Fabrícia Xavier', 'Margarida Alameda, 2289, Maria Helena do Sul, RN',
        'superior completo');
INSERT INTO Pessoa
VALUES ('41583542709', '613408697675', 'Eloá Carvalho', 'Luiza Marginal, 41330, Lorraine do Descoberto, ES',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('20656491559', '784632498421', 'Gael Moreira', 'Santos Rua, 88441, undefined Felipe, RO',
        'mestrado');
INSERT INTO Pessoa
VALUES ('57979449972', '616778123634', 'Bernardo Barros', 'Gúbio Travessa, 19641, Nogueira do Sul, SE',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('58745565121', '711572271212', 'Arthur Albuquerque', 'Ana Laura Rodovia, 48792, Paterson, SC',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('23680543084', '942272307560', 'Deneval Santos', 'Beatriz Rodovia, 52208, La Crosse, PA',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('80575645365', '890282862889', 'Isabelly Albuquerque', 'Souza Avenida, 1205, Oliveira de Nossa Senhora, PR',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('77363675071', '382093797810', 'Norberto Carvalho', 'Yago Alameda, 26333, undefined Enzo do Sul, RO',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('54518664223', '234487103088', 'Suélen Pereira', 'Cecília Alameda, 19867, undefined Beatriz, DF',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('58401128831', '445881471713', 'Joaquim Moreira', 'Moreira Rua, 95131, undefined Maria de Nossa Senhora, AP',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('80617708123', '725403194106', 'Heitor Carvalho', 'Isaac Travessa, 4486, Chandler, RJ',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('97844891136', '829935559374', 'Emanuel Santos', 'Reis Alameda, 64462, undefined Samuel de Nossa Senhora, RS',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('91139727742', '852250771434', 'Ígor Souza', 'Lívia Rodovia, 83942, Springdale, AP',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('74363441457', '257421285589', 'Ladislau Oliveira', 'Yago Rua, 40703, undefined Lorraine, TO',
        'mestrado');
INSERT INTO Pessoa
VALUES ('50602269105', '692741602798', 'Isis Batista', 'Antonella Avenida, 98364, Portsmouth, SE',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('46841982156', '994439262081', 'Isabelly Pereira', 'Santos Avenida, 34414, undefined Paulo, CE',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('83235424910', '688228141982', 'Liz Souza', 'Albuquerque Avenida, 27411, Tempe, AM',
        'mestrado');
INSERT INTO Pessoa
VALUES ('17049775347', '790451967041', 'Pedro Henrique Saraiva', 'Santos Alameda, 51667, Toledo, GO',
        'doutorado');
INSERT INTO Pessoa
VALUES ('21481214086', '205976614332', 'Miguel Barros', 'Bernardo Alameda, 56701, Jersey City, MG',
        'mestrado');
INSERT INTO Pessoa
VALUES ('65408776691', '771483047725', 'Leonardo Barros', 'Reis Rodovia, 26262, Reis do Norte, PA',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('47388927007', '208572486182', 'Fabrício Oliveira', 'Silva Rua, 8835, Melo do Norte, SC',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('49970481498', '639537108014', 'Paula Barros', 'Barros Rua, 58821, undefined Liz, MS',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('22430202225', '221030145720', 'Felícia Carvalho', 'Mércia Rodovia, 45774, Braga do Sul, AC',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('31459604231', '447271739644', 'Maria Cecília Franco', 'Emanuel Rodovia, 62106, Canton, PI',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('66894887096', '643447174481', 'Alícia Carvalho', 'Heloísa Avenida, 20795, East Los Angeles, BA',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('13566240610', '135906692058', 'Natália Batista', 'Fabiano Avenida, 31943, Kendale Lakes, PA',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('26260169129', '936740169534', 'Joaquim Xavier', 'Gabriel Rua, 66112, Maria Alice do Sul, RS',
        'doutorado');
INSERT INTO Pessoa
VALUES ('88668754065', '936660986742', 'João Martins', 'Nataniel Rodovia, 82875, Costa de Nossa Senhora, CE',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('87588114035', '629355462919', 'Roberta Martins', 'Carvalho Rodovia, 18764, Reis do Norte, RN',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('69817507220', '406832439359', 'Kléber Santos', 'Maria Cecília Marginal, 96537, Souza do Norte, SE',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('59028294656', '178071089228', 'Miguel Costa', 'Souza Marginal, 36065, undefined Alessandro do Descoberto, AM',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('24663187770', '907626083167', 'Karla Xavier', 'Reis Travessa, 61541, Columbia, AC',
        'superior completo');
INSERT INTO Pessoa
VALUES ('42799690433', '684204598166', 'Henrique Moreira', 'Joaquim Alameda, 83546, Braga do Descoberto, MS',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('98234464791', '825752452830', 'Joaquim Melo', 'Martins Rua, 49373, undefined Maria Helena, GO',
        'superior completo');
INSERT INTO Pessoa
VALUES ('67008212334', '864497147081', 'Roberta Souza', 'Ofélia Travessa, 13210, Breno do Sul, RR',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('76707281675', '654493542807', 'Pietro Reis', 'Martins Alameda, 69401, Nogueira do Descoberto, AM',
        'superior completo');
INSERT INTO Pessoa
VALUES ('72402479264', '713128662598', 'César Melo', 'Deneval Marginal, 26608, Franco do Descoberto, SC',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('96130006720', '408362716925', 'Lucas Martins', 'Karla Rodovia, 78427, Portland, SP',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('49887565386', '670874220528', 'Carla Souza', 'Carvalho Marginal, 27138, undefined Lavínia do Norte, MA',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('70189726690', '486094800080', 'Isis Costa', 'Carvalho Rua, 71978, undefined Núbia do Sul, PR',
        'superior completo');
INSERT INTO Pessoa
VALUES ('89710775923', '784004123276', 'Alexandre Costa', 'Paula Rodovia, 60967, Moreira do Descoberto, BA',
        'mestrado');
INSERT INTO Pessoa
VALUES ('73315387605', '223490159073', 'Marcela Moraes', 'Silas Rua, 16020, undefined Benjamin do Sul, MT',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('33644861271', '891685303440', 'Leonardo Moreira', 'Costa Rua, 53772, Tuckahoe, SE',
        'doutorado');
INSERT INTO Pessoa
VALUES ('21849655245', '883678032993', 'Cecília Silva', 'Nogueira Avenida, 95049, undefined Morgana, GO',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('83682897023', '171943860384', 'Paula Santos', 'Santos Travessa, 33991, undefined César, CE',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('36212424982', '216324581531', 'Morgana Carvalho', 'Pereira Alameda, 63201, undefined Júlio César, PA',
        'superior completo');
INSERT INTO Pessoa
VALUES ('31508015673', '296670560771', 'Beatriz Moreira', 'Nogueira Travessa, 75312, undefined Natália, BA',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('43586174864', '336799229611', 'Marli Santos', 'Barros Avenida, 75814, undefined Feliciano, GO',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('56437012213', '544635836570', 'Vitória Xavier', 'Fabiano Rodovia, 60098, undefined Lavínia do Sul, SP',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('38390440184', '450961551279', 'Arthur Nogueira', 'Carvalho Rua, 84802, Arcadia, PI',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('86945780506', '874205048684', 'Warley Albuquerque', 'Moraes Rua, 94657, undefined Fabrícia do Sul, TO',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('39486719819', '958089252840', 'Norberto Moreira', 'Roberto Rua, 9367, undefined Eloá do Norte, ES',
        'doutorado');
INSERT INTO Pessoa
VALUES ('74744968109', '903939247736', 'Isabela Oliveira', 'Batista Rua, 78624, Madison, PI',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('21879325024', '213406542222', 'Pietro Costa', 'Joana Alameda, 49568, Carvalho do Norte, AL',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('45670560686', '761211436940', 'Leonardo Batista', 'João Pedro Travessa, 33864, Findlay, MT',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('86681896694', '129331189393', 'Isabella Oliveira', 'Alice Avenida, 11327, undefined Miguel do Norte, AC',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('69452778594', '372765271412', 'Pablo Nogueira', 'Franco Avenida, 35935, Eduarda do Descoberto, RJ',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('42713638902', '928518732031', 'João Pedro Costa',
        'Elísio Alameda, 67570, undefined Danilo de Nossa Senhora, AC',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('59156701033', '340970802865', 'Pedro Henrique Pereira', 'Nogueira Alameda, 63834, undefined Isabelly, GO',
        'mestrado');
INSERT INTO Pessoa
VALUES ('69930587140', '300142331654', 'Feliciano Carvalho', 'Margarida Alameda, 91426, undefined Sirineu, GO',
        'superior completo');
INSERT INTO Pessoa
VALUES ('68331766016', '172708120220', 'Tertuliano Carvalho', 'Rebeca Rodovia, 10182, Leonardo do Descoberto, MA',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('27397945995', '403272035508', 'Heitor Macedo', 'Davi Lucca Rodovia, 88369, undefined Gael do Norte, TO',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('87614392244', '188933415687', 'Hélio Santos', 'Deneval Travessa, 61807, undefined Felipe do Sul, ES',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('13391795351', '365250889561', 'Lucas Silva', 'Santos Avenida, 17591, Newport News, RJ',
        'doutorado');
INSERT INTO Pessoa
VALUES ('28145866652', '667043724306', 'Tertuliano Santos', 'Nogueira Marginal, 51551, Omaha, RS',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('45491204094', '169842277537', 'Beatriz Barros', 'Gael Rua, 29032, undefined Pedro Henrique do Norte, MA',
        'doutorado');
INSERT INTO Pessoa
VALUES ('34218765089', '473255445645', 'Norberto Melo', 'Víctor Rodovia, 96575, undefined Rafael, AC',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('34232794048', '773822867521', 'Karla Pereira', 'Reis Marginal, 71415, undefined Ígor do Sul, PB',
        'superior completo');
INSERT INTO Pessoa
VALUES ('41397188589', '529727194341', 'Vicente Saraiva', 'Carvalho Alameda, 84059, Santa Ana, SP',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('71877414532', '102407180750', 'Lucca Batista', 'Moreira Travessa, 4171, Nogueira do Sul, RS',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('81651619777', '973409908986', 'Carlos Silva', 'Guilherme Rodovia, 18856, Carvalho do Descoberto, RR',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('68837744630', '877574323141', 'Elísio Silva', 'Barros Rua, 72063, Fresno, RN',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('28893999643', '563313240837', 'Roberta Souza', 'Júlia Rua, 99324, undefined Isadora do Norte, PI',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('54783345928', '792423373064', 'Mariana Silva', 'Félix Marginal, 41650, Oliveira do Descoberto, RR',
        'superior completo');
INSERT INTO Pessoa
VALUES ('45065363431', '618059074785', 'Daniel Albuquerque', 'Marli Avenida, 27041, João do Sul, BA',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('35895102075', '245678212004', 'Talita Melo', 'Moraes Travessa, 69334, undefined Roberto, ES',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('68820670107', '391170502919', 'Melissa Santos', 'Isabelly Alameda, 18009, undefined Benjamin do Norte, RS',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('25862227568', '242420784616', 'Yasmin Nogueira', 'Barros Alameda, 41396, Nogueira do Sul, AP',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('85584778869', '826168133830', 'Marina Silva', 'Macedo Travessa, 85973, undefined João Lucas, MS',
        'superior completo');
INSERT INTO Pessoa
VALUES ('51051183596', '193877110583', 'Murilo Moreira', 'Lorenzo Rodovia, 65409, undefined Lucca de Nossa Senhora, RN',
        'mestrado');
INSERT INTO Pessoa
VALUES ('46389898404', '337774605280', 'Alexandre Moraes', 'Rebeca Alameda, 64586, undefined Gustavo do Sul, RR',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('33032022989', '156291946815', 'Paulo Franco', 'Murilo Rua, 39278, Joana do Sul, SE',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('92511644628', '976541921938', 'Kléber Oliveira', 'Pereira Marginal, 99246, Braga do Descoberto, PR',
        'superior completo');
INSERT INTO Pessoa
VALUES ('67562512347', '424389107944', 'Célia Melo', 'Talita Avenida, 51258, Hilo, ES',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('74194578086', '855164031591', 'Meire Saraiva', 'Emanuel Travessa, 81640, New York, AP',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('39834057504', '915909883077', 'Cauã Moreira', 'Valentina Travessa, 67650, Batista do Sul, DF',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('27661639580', '906780151743', 'Bryan Braga', 'Silva Avenida, 53170, undefined Alice, MG',
        'superior completo');
INSERT INTO Pessoa
VALUES ('31590171044', '715269427280', 'João Pedro Santos', 'Márcia Marginal, 63343, undefined Gabriel do Norte, AM',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('27573815234', '539754210505', 'Luiza Martins', 'Ladislau Travessa, 17703, undefined Maria do Descoberto, RS',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('15132983059', '151305004651', 'Valentina Reis',
        'Vicente Marginal, 73558, undefined Feliciano do Descoberto, RO',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('34702133666', '163371751084', 'Marcos Albuquerque', 'Pietro Avenida, 34590, Murfreesboro, RS',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('39709400143', '523875486617', 'Víctor Carvalho', 'Tertuliano Marginal, 37024, Santos do Norte, SC',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('99311338330', '499124032910', 'Beatriz Franco', 'Luiza Rua, 95450, Isabel do Sul, SE',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('22195894273', '195419659884', 'Paulo Souza', 'Nicolas Marginal, 33109, undefined Suélen do Norte, RS',
        'doutorado');
INSERT INTO Pessoa
VALUES ('44503644322', '618331571295', 'Elísio Costa', 'Pereira Travessa, 10513, undefined Roberta, RJ',
        'superior completo');
INSERT INTO Pessoa
VALUES ('63500243364', '854520674631', 'João Xavier', 'Macedo Avenida, 87068, undefined Gael, PB',
        'superior completo');
INSERT INTO Pessoa
VALUES ('56639970568', '833416781062', 'Karla Pereira', 'Dalila Marginal, 86653, Castro Valley, PR',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('20311489617', '210038467636', 'Valentina Reis', 'Marli Avenida, 60406, undefined Joaquim, AM',
        'doutorado');
INSERT INTO Pessoa
VALUES ('20593875704', '980151566746', 'Lara Xavier', 'Melo Travessa, 83438, Pereira do Descoberto, MS',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('56544090188', '493659915705', 'Kléber Melo', 'Maria Luiza Marginal, 85395, Elizabeth, SP',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('73725674431', '672347883577', 'Hélio Saraiva',
        'Oliveira Rodovia, 1345, undefined Maria Eduarda de Nossa Senhora, PA',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('93420833500', '737479318631', 'Ana Laura Moreira', 'Núbia Alameda, 53973, Hesperia, PR',
        'doutorado');
INSERT INTO Pessoa
VALUES ('91388181308', '503344880649', 'Ricardo Oliveira', 'Eduardo Travessa, 62575, undefined Vitória do Norte, GO',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('73635011366', '739233087701', 'Silas Silva', 'Talita Rua, 43732, undefined Lorenzo, DF',
        'superior completo');
INSERT INTO Pessoa
VALUES ('53108889381', '496534054586', 'Karla Carvalho', 'Pedro Henrique Alameda, 70981, undefined Danilo, TO',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('96985040598', '101209764485', 'Júlio César Franco', 'Saraiva Travessa, 21365, Hoboken, AL',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('33042951838', '317089103837', 'Ricardo Batista', 'Eloá Avenida, 43949, Pereira do Norte, RS',
        'doutorado');
INSERT INTO Pessoa
VALUES ('37735666024', '576910926797', 'Ana Júlia Franco', 'Norberto Travessa, 51069, Xavier de Nossa Senhora, PE',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('56364648623', '884535245620', 'Anthony Carvalho', 'Moreira Travessa, 92043, Springfield, SP',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('61669403030', '268696134327', 'Salvador Oliveira', 'Enzo Rodovia, 47141, undefined Sirineu do Norte, RS',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('73145247376', '659088983875', 'Alícia Xavier', 'Martins Avenida, 775, undefined Frederico, BA',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('21125739731', '112943504401', 'Tertuliano Santos', 'Franco Rua, 78458, undefined Deneval do Sul, PI',
        'doutorado');
INSERT INTO Pessoa
VALUES ('21487723933', '501311996509', 'Fabiano Carvalho', 'Emanuelly Travessa, 4155, Mariana de Nossa Senhora, ES',
        'doutorado');
INSERT INTO Pessoa
VALUES ('34738838900', '408056084485', 'Vicente Oliveira', 'Alessandra Alameda, 6188, Sanford, RO',
        'superior completo');
INSERT INTO Pessoa
VALUES ('11848133248', '304211370972', 'Maria Alice Saraiva', 'Alessandra Alameda, 67309, Melo do Descoberto, MA',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('82960038760', '328337554191', 'Maitê Silva', 'Marina Travessa, 42548, Macedo do Descoberto, CE',
        'superior completo');
INSERT INTO Pessoa
VALUES ('58362277850', '274518988607', 'Heitor Santos', 'Márcia Rua, 55005, Alexandre do Sul, AC',
        'doutorado');
INSERT INTO Pessoa
VALUES ('32128272987', '679167185630', 'Gustavo Nogueira', 'Saraiva Avenida, 10905, undefined Cauã do Sul, RJ',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('86282287575', '754799769679', 'Joaquim Braga', 'Carvalho Avenida, 5668, undefined Isabel do Sul, AL',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('94048417352', '280688597401', 'Kléber Oliveira', 'Moraes Avenida, 50617, Macedo do Sul, PB',
        'mestrado');
INSERT INTO Pessoa
VALUES ('68767157313', '708482025493', 'Bernardo Batista',
        'Emanuelly Avenida, 57949, undefined Joaquim de Nossa Senhora, CE',
        'doutorado');
INSERT INTO Pessoa
VALUES ('15402143090', '178582744696', 'Murilo Carvalho', 'Kléber Rua, 13743, Moreira do Norte, TO',
        'mestrado');
INSERT INTO Pessoa
VALUES ('89264845682', '212409904808', 'Joana Souza', 'Moraes Alameda, 44152, Frederico do Descoberto, AC',
        'mestrado');
INSERT INTO Pessoa
VALUES ('10209552922', '165079011488', 'Deneval Nogueira', 'Xavier Avenida, 85154, Plainfield, PE',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('18004457291', '487918487214', 'Ígor Moreira', 'Marcelo Avenida, 76247, undefined João Miguel, MG',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('25330412890', '688400396378', 'Célia Oliveira', 'Franco Avenida, 91060, Manuela do Sul, RJ',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('51327180704', '397525306092', 'Enzo Gabriel Oliveira', 'Barros Travessa, 32396, Carvalho do Descoberto, CE',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('73157967103', '300001222733', 'Eduardo Moraes', 'Carlos Rodovia, 13478, undefined Rebeca, TO',
        'doutorado');
INSERT INTO Pessoa
VALUES ('31890189512', '468399953097', 'Anthony Carvalho', 'Albuquerque Marginal, 51539, Port Orange, SE',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('85526398515', '871433940576', 'Samuel Santos', 'Eduardo Alameda, 44131, Pittsfield, MA',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('37780293980', '117049469146', 'Marina Reis', 'Moreira Alameda, 91746, Coeur dAlene, MT',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('85617420598', '140732535929', 'Antônio Franco', 'Karla Marginal, 25321, Martins do Sul, AL',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('37581900996', '539154592202', 'Gúbio Reis', 'Maria Clara Alameda, 4834, Moreira do Norte, DF',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('52024004105', '239809529669', 'Ana Laura Barros', 'Barros Avenida, 31320, undefined Eduardo do Norte, PB',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('89025817608', '643142839521', 'Eloá Oliveira', 'Barros Avenida, 21707, Albuquerque do Norte, RS',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('65458204417', '484636974218', 'Yuri Melo', 'Gabriel Marginal, 49249, undefined Rafael do Descoberto, MT',
        'doutorado');
INSERT INTO Pessoa
VALUES ('37841710573', '923894471465', 'Warley Oliveira', 'Karla Travessa, 94617, undefined Calebe do Norte, CE',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('54133691079', '319351176242', 'Marcela Santos', 'Costa Travessa, 96745, Melo de Nossa Senhora, CE',
        'superior completo');
INSERT INTO Pessoa
VALUES ('91857076140', '958043364644', 'Clara Costa', 'Maria Alice Travessa, 21055, Moraes do Descoberto, SP',
        'mestrado');
INSERT INTO Pessoa
VALUES ('87642632594', '668132701376', 'João Miguel Reis', 'Oliveira Rua, 9984, Morgana de Nossa Senhora, MA',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('13211265460', '353862047567', 'Félix Reis', 'Reis Rua, 73076, undefined Meire, AC',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('45448827098', '601309841428', 'Gustavo Moreira', 'Joana Marginal, 96097, undefined Rebeca, RJ',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('34047240966', '866331485100', 'Emanuelly Batista', 'Braga Rodovia, 85240, Albuquerque do Sul, AL',
        'doutorado');
INSERT INTO Pessoa
VALUES ('45056562642', '697659471584', 'Felícia Carvalho', 'Santos Travessa, 41634, undefined Janaína do Sul, TO',
        'mestrado');
INSERT INTO Pessoa
VALUES ('62780075336', '259468681318', 'Ladislau Batista', 'Oliveira Alameda, 14492, Troy, AC',
        'superior completo');
INSERT INTO Pessoa
VALUES ('49404086042', '420317927887', 'Emanuelly Carvalho', 'Souza Avenida, 45698, undefined Alice do Norte, RJ',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('37254095533', '931237058457', 'Nicolas Moraes', 'Víctor Marginal, 816, undefined Lara do Descoberto, PR',
        'mestrado');
INSERT INTO Pessoa
VALUES ('56399587204', '544297932717', 'Antonella Costa', 'Carlos Avenida, 65879, undefined Maria Júlia, SP',
        'mestrado');
INSERT INTO Pessoa
VALUES ('65963803855', '913774356874', 'Isabella Costa', 'Melo Alameda, 87162, Asheville, AP',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('29613642755', '492520858231', 'Aline Nogueira', 'Júlio Avenida, 73620, undefined Elísio do Sul, AP',
        'mestrado');
INSERT INTO Pessoa
VALUES ('39251236913', '358913403190', 'Clara Costa', 'Moraes Marginal, 37783, Richardson, TO',
        'superior completo');
INSERT INTO Pessoa
VALUES ('74808992438', '910363589064', 'Hugo Silva', 'Xavier Travessa, 24268, undefined Isabella do Norte, ES',
        'superior completo');
INSERT INTO Pessoa
VALUES ('88463596005', '545557863102', 'Félix Costa', 'Costa Travessa, 74297, undefined Feliciano do Sul, CE',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('74359773746', '565696867182', 'Larissa Nogueira', 'Batista Avenida, 85202, undefined Rebeca do Sul, SE',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('31701090801', '500990207702', 'João Miguel Costa', 'Carvalho Travessa, 37676, undefined Rafaela do Norte, BA',
        'superior completo');
INSERT INTO Pessoa
VALUES ('26318127936', '378977408097', 'Sarah Pereira', 'Macedo Avenida, 89900, Fábio do Norte, PI',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('96993440124', '182985941786', 'Ana Laura Xavier', 'Feliciano Rodovia, 45330, Sirineu do Descoberto, SE',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('12932691567', '123725729412', 'Roberto Saraiva', 'Costa Travessa, 86231, Carvalho do Norte, DF',
        'mestrado');
INSERT INTO Pessoa
VALUES ('12698386129', '493451259750', 'Isis Carvalho', 'Costa Rodovia, 36559, undefined Fabiano, AL',
        'superior completo');
INSERT INTO Pessoa
VALUES ('92465915710', '900018899608', 'Paulo Silva', 'Suélen Alameda, 44264, Carvalho do Descoberto, CE',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('76850075086', '597219243436', 'Cecília Franco', 'Carlos Travessa, 16493, undefined Théo, RR',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('49141727066', '850058700493', 'Silas Xavier', 'Melo Avenida, 98080, undefined Karla, SC',
        'mestrado');
INSERT INTO Pessoa
VALUES ('56845003822', '723124653566', 'Benjamin Carvalho', 'Vicente Rodovia, 21066, Janaína do Descoberto, TO',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('91929024783', '833248878340', 'Nataniel Braga', 'Maitê Rua, 97522, undefined Marina, AL',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('18369440392', '107249914575', 'Lorena Santos',
        'Melo Avenida, 90434, undefined Enzo Gabriel de Nossa Senhora, RN',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('37706179977', '121909469901', 'Ana Laura Souza', 'João Lucas Marginal, 38869, Martins do Descoberto, AC',
        'superior completo');
INSERT INTO Pessoa
VALUES ('35165164980', '678019302012', 'Pedro Henrique Batista', 'Luiza Rua, 94285, undefined Paulo do Descoberto, RR',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('30228957973', '592185232695', 'Sara Franco', 'Nogueira Rodovia, 69795, undefined Sophia do Descoberto, AL',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('16524949248', '529349032626', 'Isabella Souza', 'Melissa Rua, 81617, Saraiva do Descoberto, AP',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('65546228860', '856783420941', 'César Costa', 'Eduardo Avenida, 96535, Costa do Descoberto, PR',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('96382571714', '894306454062', 'Raul Reis', 'Moreira Alameda, 18756, Macedo de Nossa Senhora, PI',
        'doutorado');
INSERT INTO Pessoa
VALUES ('22529268462', '660572451446', 'Miguel Silva', 'Batista Marginal, 83919, Elísio do Sul, RS',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('32622446236', '273103160690', 'Bryan Moreira', 'Macedo Avenida, 81867, undefined Pedro Henrique, AP',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('35623852645', '300646125315', 'Ofélia Nogueira', 'Batista Rua, 85466, undefined Pietro, SP',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('26070068068', '429704786464', 'Vitor Moraes', 'Eloá Rodovia, 13969, San Bruno, PB',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('28038902608', '903307495731', 'Giovanna Braga', 'Isabela Alameda, 24134, League City, SP',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('29294251089', '230750275263', 'Ana Júlia Souza', 'Maria Helena Marginal, 96096, undefined Fabrícia, TO',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('49723011339', '155103898374', 'Talita Souza', 'Franco Travessa, 43974, undefined Antônio de Nossa Senhora, MA',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('68863812936', '372208811319', 'Feliciano Souza', 'Bernardo Travessa, 54981, Danilo do Descoberto, RJ',
        'mestrado');
INSERT INTO Pessoa
VALUES ('82870189829', '898828203743', 'Larissa Batista', 'Carvalho Travessa, 46623, Santos do Sul, DF',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('31800616828', '124225607258', 'Maria Cecília Franco', 'Meire Travessa, 28813, undefined Lucca do Norte, PR',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('25677760089', '140340394247', 'Leonardo Xavier', 'Moreira Marginal, 42387, Flagstaff, SP',
        'mestrado');
INSERT INTO Pessoa
VALUES ('20882765164', '110228113946', 'Júlio César Pereira', 'Melo Rodovia, 53299, undefined Breno do Sul, CE',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('77571850281', '168192973802', 'Maria Santos', 'Antônio Alameda, 9859, Fort Worth, AP',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('59097811668', '183254835125', 'Leonardo Souza', 'Xavier Marginal, 78212, Isabelly de Nossa Senhora, AC',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('56643636750', '484030397678', 'Sara Batista', 'Lucas Alameda, 82264, undefined Anthony do Sul, PR',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('36824277385', '906923147640', 'Lívia Barros', 'Isabella Marginal, 80245, undefined Júlia do Descoberto, AP',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('66040890542', '471627448289', 'Giovanna Macedo', 'Macedo Avenida, 49483, Marcos do Descoberto, PB',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('60141710506', '322602814459', 'Lorraine Souza', 'Barros Avenida, 64575, undefined Isadora, RJ',
        'superior completo');
INSERT INTO Pessoa
VALUES ('50441387610', '776944145560', 'Cecília Reis', 'Moraes Rua, 51854, Carvalho do Norte, RJ',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('25783153302', '326377199706', 'Dalila Moraes', 'Barros Alameda, 38466, undefined Alícia do Norte, DF',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('83906174097', '572625693259', 'Liz Xavier', 'Ígor Rodovia, 30129, undefined Raul, RO',
        'mestrado');
INSERT INTO Pessoa
VALUES ('70315878796', '542179466201', 'Murilo Reis', 'Carla Avenida, 28643, Moreira de Nossa Senhora, PB',
        'superior completo');
INSERT INTO Pessoa
VALUES ('91566400225', '829161213384', 'Leonardo Moraes', 'Norberto Rodovia, 55301, undefined Isadora, MA',
        'mestrado');
INSERT INTO Pessoa
VALUES ('94763610071', '331171521754', 'Théo Barros', 'Carvalho Travessa, 29172, Carvalho do Descoberto, PB',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('65620046039', '604197531542', 'Vitória Oliveira', 'Júlio César Marginal, 13908, undefined Elisa, SC',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('20822501375', '531667840038', 'João Pedro Nogueira',
        'Moraes Alameda, 28877, undefined Henrique de Nossa Senhora, MT',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('63900773341', '224455259158', 'Célia Melo', 'Karla Rodovia, 82993, Beavercreek, CE',
        'superior completo');
INSERT INTO Pessoa
VALUES ('82049451954', '152526476769', 'Alícia Carvalho', 'Saraiva Rua, 45339, undefined Marina do Norte, MG',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('31935233147', '656058381893', 'Noah Albuquerque', 'Carvalho Alameda, 47620, Danilo do Sul, PI',
        'mestrado');
INSERT INTO Pessoa
VALUES ('98076882518', '866092943889', 'Davi Lucca Costa', 'Batista Rodovia, 38843, undefined Elisa, MA',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('28094365221', '437955280463', 'Daniel Albuquerque', 'Warley Alameda, 63097, undefined Gúbio, ES',
        'superior completo');
INSERT INTO Pessoa
VALUES ('26070915332', '778190018027', 'Mariana Saraiva', 'Enzo Travessa, 18440, Macedo do Descoberto, MT',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('86052406441', '781250824616', 'Mariana Pereira', 'Miguel Alameda, 13634, Mariana do Descoberto, AC',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('61486375667', '685869012377', 'Elisa Saraiva', 'Nogueira Travessa, 93045, undefined Isadora, SC',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('87222931571', '423164021130', 'Júlio Reis', 'Barros Marginal, 13457, undefined João Pedro, MA',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('60125770117', '989550624345', 'Isabela Carvalho', 'Reis Alameda, 69964, undefined Alice, CE',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('95140033254', '392562150722', 'Enzo Gabriel Moraes',
        'Bruna Rua, 84280, undefined Maria Eduarda de Nossa Senhora, MS',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('12399218089', '335922847362', 'Elisa Albuquerque', 'Macedo Travessa, 48898, undefined Pedro do Sul, SE',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('89382796012', '518721484951', 'Liz Xavier', 'Théo Marginal, 65074, Souza do Norte, AP',
        'mestrado');
INSERT INTO Pessoa
VALUES ('15201660203', '678130365791', 'Mariana Franco', 'Aline Marginal, 80687, Grand Island, PE',
        'mestrado');
INSERT INTO Pessoa
VALUES ('35331775275', '688199752685', 'Isis Pereira', 'Bruna Travessa, 84530, undefined Suélen, MT',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('68435227326', '336258524563', 'Fabiano Batista', 'Moraes Travessa, 21216, undefined Cecília do Sul, PI',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('14574779509', '189203368709', 'Pedro Albuquerque', 'Emanuelly Avenida, 32080, OFallon, PA',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('63763126712', '300533699477', 'Vitor Xavier', 'Matheus Rodovia, 28424, undefined Lucca de Nossa Senhora, PR',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('50193922165', '385185520001', 'Marli Costa', 'Moraes Avenida, 86917, Aspen Hill, SE',
        'superior completo');
INSERT INTO Pessoa
VALUES ('40589486460', '287530794623', 'Warley Albuquerque', 'Enzo Alameda, 23308, undefined Guilherme, RO',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('85730072224', '770996055379', 'Sarah Melo', 'Albuquerque Marginal, 10323, Carla de Nossa Senhora, AC',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('74479391069', '631491640815', 'Caio Souza', 'Gael Travessa, 66612, Lubbock, PB',
        'superior completo');
INSERT INTO Pessoa
VALUES ('66703392334', '435885074222', 'João Lucas Reis', 'Oliveira Travessa, 33359, Albuquerque de Nossa Senhora, AC',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('74573730144', '707835298799', 'Karla Melo', 'João Pedro Marginal, 90299, Antonella do Sul, ES',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('43331410249', '765164287574', 'Karla Nogueira', 'Carvalho Rua, 38754, Moreira do Norte, CE',
        'doutorado');
INSERT INTO Pessoa
VALUES ('51594797081', '926678338507', 'Janaína Moreira', 'Alexandre Travessa, 80443, Macedo do Norte, RR',
        'doutorado');
INSERT INTO Pessoa
VALUES ('51012184110', '562704145326', 'Samuel Saraiva', 'Rafaela Avenida, 92267, Surprise, TO',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('73727615827', '693821230693', 'Helena Barros', 'Carvalho Marginal, 96520, Carvalho do Descoberto, MS',
        'superior completo');
INSERT INTO Pessoa
VALUES ('54936377038', '753959320439', 'Lavínia Braga', 'Rebeca Avenida, 22154, undefined Lorraine do Norte, AP',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('70281883578', '898109086742', 'Manuela Xavier', 'João Pedro Alameda, 99556, undefined Luiza, GO',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('94102552335', '688259951304', 'Marina Franco', 'Albuquerque Avenida, 519, Melo do Sul, MA',
        'superior completo');
INSERT INTO Pessoa
VALUES ('63745677894', '273010482615', 'Frederico Melo', 'Sara Alameda, 76947, North Richland Hills, AP',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('23072280755', '544973996910', 'Lorraine Braga', 'Silva Alameda, 50870, Novato, PR',
        'mestrado');
INSERT INTO Pessoa
VALUES ('13099049085', '776378326443', 'Larissa Reis', 'Hélio Rua, 24398, undefined Ígor do Norte, AP',
        'mestrado');
INSERT INTO Pessoa
VALUES ('83954206069', '227000461774', 'Marcelo Costa', 'Rebeca Avenida, 523, undefined Warley, SP',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('14908413034', '801661403616', 'Alessandra Franco', 'Alícia Rodovia, 20018, Batista do Descoberto, MG',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('72668227651', '565783705585', 'Lorraine Albuquerque', 'Reis Avenida, 12227, Paulo do Descoberto, CE',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('71666067317', '610068015148', 'Lorena Silva', 'Paula Rua, 52956, Fabiano do Norte, RJ',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('74589843200', '602891248604', 'Warley Souza', 'Carvalho Avenida, 42467, Oliveira de Nossa Senhora, PI',
        'mestrado');
INSERT INTO Pessoa
VALUES ('15407267932', '742412504926', 'Vitor Silva', 'Melissa Avenida, 58325, undefined Heloísa, SE',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('47024384837', '831826462456', 'Janaína Souza', 'Melo Alameda, 33412, undefined Marcelo do Norte, RJ',
        'superior completo');
INSERT INTO Pessoa
VALUES ('24989942414', '739734476804', 'Eduarda Carvalho', 'Melo Travessa, 32360, Moraes do Descoberto, TO',
        'mestrado');
INSERT INTO Pessoa
VALUES ('72241387865', '826761867618', 'Théo Reis', 'Aline Rodovia, 75543, Janesville, MT',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('92201869981', '440703870588', 'Heitor Santos', 'Enzo Travessa, 83429, Gresham, SC',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('59691281320', '727932687778', 'Heloísa Carvalho', 'Samuel Avenida, 6936, Suélen do Sul, PE',
        'superior completo');
INSERT INTO Pessoa
VALUES ('34625774528', '646079580113', 'Júlio César Reis', 'Alice Alameda, 17199, undefined Lucca de Nossa Senhora, CE',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('75930518365', '231520119123', 'Carla Santos', 'Xavier Travessa, 3110, Laura do Descoberto, RO',
        'mestrado');
INSERT INTO Pessoa
VALUES ('55435475325', '524822173127', 'Vitor Nogueira', 'Hélio Avenida, 15934, Gastonia, ES',
        'mestrado');
INSERT INTO Pessoa
VALUES ('16068811987', '135312483855', 'Guilherme Martins', 'Nogueira Rodovia, 6060, Saraiva de Nossa Senhora, RS',
        'superior completo');
INSERT INTO Pessoa
VALUES ('71027335911', '859572723438', 'Valentina Carvalho', 'Macedo Alameda, 53391, Santos do Norte, PR',
        'doutorado');
INSERT INTO Pessoa
VALUES ('95326417863', '828410172648', 'Márcia Batista', 'Yago Alameda, 7294, Kentwood, MS',
        'doutorado');
INSERT INTO Pessoa
VALUES ('74025096402', '965678882389', 'Caio Xavier', 'Melo Avenida, 80240, undefined Nicolas, RS',
        'superior completo');
INSERT INTO Pessoa
VALUES ('47849461960', '536531640519', 'Laura Moraes', 'Fabrício Rua, 39370, Vicente do Sul, CE',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('93301798028', '209432762186', 'Maitê Pereira', 'Calebe Avenida, 95197, Waterbury, ES',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('24302034655', '202454875782', 'Margarida Carvalho', 'Lucca Marginal, 85416, undefined Silas, AC',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('34657710711', '335124360653', 'Fábio Melo', 'Gabriel Marginal, 97196, Concord, BA',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('41765983633', '445331755490', 'Giovanna Carvalho', 'Ana Luiza Rodovia, 14921, Martins de Nossa Senhora, RS',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('56279783362', '499257095204', 'Paula Oliveira', 'Oliveira Travessa, 80486, Surprise, GO',
        'mestrado');
INSERT INTO Pessoa
VALUES ('18236701744', '144858884206', 'Salvador Santos',
        'Nogueira Marginal, 12476, undefined Júlio César do Descoberto, PI',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('42089914267', '240141560742', 'João Lucas Carvalho', 'Giovanna Marginal, 99246, Maria Clara do Norte, AM',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('96389911915', '473812624905', 'Lucas Martins', 'Santos Avenida, 2805, Macedo do Sul, AC',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('38918265034', '257363266055', 'Alessandro Carvalho', 'Nicolas Avenida, 62089, undefined Meire, PA',
        'doutorado');
INSERT INTO Pessoa
VALUES ('73907273937', '670708152395', 'Lorraine Saraiva', 'Dalila Avenida, 27722, Hélio do Sul, MT',
        'superior completo');
INSERT INTO Pessoa
VALUES ('57607271133', '100424872594', 'Washington Braga', 'Alessandro Rua, 42593, Roswell, RJ',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('10737233394', '491160033829', 'Heloísa Carvalho', 'Reis Rua, 8991, Titusville, MS',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('54063647601', '525374395120', 'Raul Moraes',
        'Albuquerque Rodovia, 17723, undefined Ana Clara do Descoberto, RJ',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('70077948186', '342812501452', 'Sara Melo', 'Saraiva Marginal, 86791, undefined Gustavo, AP',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('14724061477', '510170498257', 'Marina Reis', 'Yasmin Travessa, 36387, undefined Yango do Descoberto, AP',
        'doutorado');
INSERT INTO Pessoa
VALUES ('15176868964', '690561984642', 'Sophia Carvalho', 'Sílvia Rua, 72926, undefined Gabriel, RO',
        'superior completo');
INSERT INTO Pessoa
VALUES ('37930955484', '357192877377', 'Margarida Silva', 'Melo Travessa, 2266, undefined Maria Eduarda, TO',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('32466301082', '658730979589', 'Fábio Braga', 'Joaquim Alameda, 6813, Souza do Descoberto, CE',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('47314490594', '664710932318', 'Gael Barros', 'Yasmin Marginal, 58890, undefined Célia, AM',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('98803486214', '121342948591', 'Nataniel Silva', 'Anthony Marginal, 21741, Mount Pleasant, MA',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('44307413429', '861724638775', 'Isabel Xavier', 'Barros Rua, 630, Detroit, BA',
        'doutorado');
INSERT INTO Pessoa
VALUES ('87476298043', '488785170344', 'Vitor Melo', 'Silva Marginal, 39749, undefined Maria de Nossa Senhora, RN',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('69028166278', '275357453431', 'João Pedro Costa', 'Leonardo Travessa, 72087, Oliveira de Nossa Senhora, AL',
        'mestrado');
INSERT INTO Pessoa
VALUES ('44186261715', '229451706819', 'Nataniel Nogueira', 'Maria Clara Rua, 79801, undefined Alexandre, SE',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('12138843927', '356218531215', 'Ana Luiza Oliveira', 'Norberto Rua, 70894, undefined Sílvia do Descoberto, PB',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('64713757117', '339966469188', 'Arthur Moreira', 'Carvalho Marginal, 37034, undefined Marcos do Descoberto, MA',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('37495928150', '630168674956', 'Manuela Santos', 'Santos Rua, 84369, undefined Sílvia, BA',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('88271164062', '127451428165', 'Alice Albuquerque', 'Isadora Marginal, 91403, Arvada, RR',
        'doutorado');
INSERT INTO Pessoa
VALUES ('27603935101', '200095400633', 'Lorenzo Albuquerque', 'Melo Travessa, 65839, Manhattan, MG',
        'mestrado');
INSERT INTO Pessoa
VALUES ('98591816106', '390934976050', 'Frederico Melo', 'Santos Rua, 5224, Gael do Sul, AL',
        'superior completo');
INSERT INTO Pessoa
VALUES ('91448831355', '211827393970', 'Janaína Costa', 'Carvalho Avenida, 21672, Alícia do Norte, RS',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('33842867389', '110134515748', 'Maria Luiza Carvalho', 'Morgana Marginal, 8346, undefined Júlia do Norte, SP',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('82486186116', '900178389833', 'César Xavier', 'Barros Marginal, 82985, Sara de Nossa Senhora, MS',
        'doutorado');
INSERT INTO Pessoa
VALUES ('28576460210', '553344802442', 'Murilo Franco', 'Costa Rodovia, 93263, Saraiva do Sul, PB',
        'mestrado');
INSERT INTO Pessoa
VALUES ('12425285473', '419516317243', 'Deneval Carvalho', 'Pedro Alameda, 47851, undefined Felipe, RS',
        'doutorado');
INSERT INTO Pessoa
VALUES ('66539061414', '338101600925', 'Washington Santos', 'Isis Travessa, 80901, Norberto do Norte, RS',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('32995448785', '552298341738', 'Gael Costa', 'Meire Alameda, 7576, Moreira de Nossa Senhora, BA',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('36101309738', '765312961162', 'Marina Carvalho', 'Reis Rua, 62967, Springfield, ES',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('56626854483', '778075638576', 'Guilherme Silva', 'Morgana Rodovia, 88666, undefined Yuri do Descoberto, PE',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('68030750646', '241722585074', 'Bryan Saraiva', 'Morgana Marginal, 5741, Alice do Sul, RO',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('12911266039', '440952767641', 'Ricardo Reis', 'Martins Avenida, 38243, undefined Hugo do Norte, ES',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('63405921850', '759923303127', 'Emanuel Batista', 'Nogueira Rua, 69193, Lorraine do Norte, AL',
        'mestrado');
INSERT INTO Pessoa
VALUES ('60652495953', '283574904710', 'Fabrícia Silva', 'Franco Rua, 64225, undefined Bruna do Sul, SP',
        'doutorado');
INSERT INTO Pessoa
VALUES ('90257081068', '869513709843', 'Washington Nogueira',
        'Saraiva Avenida, 95704, undefined Arthur do Descoberto, RO',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('13407645802', '240213485434', 'Danilo Reis', 'Moreira Marginal, 73143, Springfield, PB',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('83114106606', '708741808123', 'Ana Júlia Moraes', 'Pereira Avenida, 31228, undefined Warley, MG',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('44529969659', '239022886380', 'Gúbio Moreira', 'Moreira Alameda, 16777, undefined Lorraine, AL',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('91296067000', '327143320115', 'Heloísa Oliveira', 'Barros Rodovia, 78079, undefined Frederico, PA',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('69270376081', '342266260366', 'Rafael Oliveira', 'Franco Marginal, 58702, undefined Núbia do Norte, CE',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('44718786508', '406304769846', 'Davi Lucca Nogueira', 'Franco Marginal, 40399, Emanuel do Norte, PI',
        'superior completo');
INSERT INTO Pessoa
VALUES ('79759667741', '529035558248', 'Bernardo Reis', 'Marina Rodovia, 73345, Carvalho do Norte, PE',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('96239826499', '711295422608', 'Arthur Nogueira', 'Caio Rua, 79534, Ricardo do Descoberto, SP',
        'doutorado');
INSERT INTO Pessoa
VALUES ('73579154384', '755526519240', 'Mariana Costa', 'Xavier Travessa, 77279, undefined Roberta do Descoberto, RS',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('75953406409', '256945531489', 'Norberto Silva', 'Braga Marginal, 65520, Alpharetta, DF',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('97468617402', '338767608930', 'Samuel Macedo',
        'Maria Clara Marginal, 34913, undefined Pietro de Nossa Senhora, RJ',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('13908656504', '819752949732', 'Isadora Moreira', 'Isadora Rua, 6220, Carvalho de Nossa Senhora, AC',
        'doutorado');
INSERT INTO Pessoa
VALUES ('34996525992', '334346908540', 'Lucca Braga', 'Marli Marginal, 92172, Denver, SP',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('73656000972', '368311827117', 'Marcos Silva', 'Beatriz Rodovia, 99576, Marina de Nossa Senhora, TO',
        'superior completo');
INSERT INTO Pessoa
VALUES ('90218525256', '594870082638', 'Yasmin Reis', 'Silas Avenida, 78491, San Marcos, MG',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('73469289678', '180727097461', 'Heloísa Franco', 'Moreira Avenida, 79780, undefined Alice do Descoberto, CE',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('41297736910', '868913404433', 'Rebeca Oliveira', 'Moreira Avenida, 98258, Maria Luiza do Descoberto, GO',
        'mestrado');
INSERT INTO Pessoa
VALUES ('41487482076', '730441680573', 'César Saraiva', 'Oliveira Alameda, 17239, undefined Luiza, PE',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('93519565530', '791965021053', 'Janaína Braga', 'Antonella Travessa, 41529, undefined Marcela do Sul, PE',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('48220131113', '453998287767', 'Talita Braga', 'Costa Avenida, 75103, Nogueira do Sul, MA',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('50661863996', '384967720857', 'Yango Costa', 'Melo Alameda, 14333, undefined Yuri do Sul, GO',
        'doutorado');
INSERT INTO Pessoa
VALUES ('69501396566', '728643871098', 'Breno Franco', 'Sara Alameda, 28871, Elyria, ES',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('32608546945', '387864065077', 'Norberto Xavier', 'Ana Clara Avenida, 82617, undefined Maitê, RO',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('59884439555', '240073122922', 'Luiza Carvalho', 'Xavier Marginal, 41632, undefined Alessandro, AC',
        'doutorado');
INSERT INTO Pessoa
VALUES ('83155709574', '828090489376', 'Fabiano Pereira', 'Raul Travessa, 66735, undefined Ladislau, RS',
        'superior completo');
INSERT INTO Pessoa
VALUES ('85119483100', '243371452740', 'Paulo Carvalho', 'Nogueira Alameda, 55616, undefined Guilherme do Norte, MS',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('47132167625', '872269110684', 'Maria Alice Santos', 'Silva Alameda, 7955, Xavier do Descoberto, AL',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('76377020021', '329181346972', 'Karla Moreira', 'Helena Rua, 20042, undefined Talita de Nossa Senhora, RO',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('25892141219', '568663259386', 'João Costa', 'Lorraine Rua, 33086, Silas do Sul, AC',
        'mestrado');
INSERT INTO Pessoa
VALUES ('50892221683', '983457029983', 'Carlos Barros', 'Costa Rua, 51750, Carla do Descoberto, RS',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('90003691567', '285984370158', 'Bernardo Braga', 'Ígor Marginal, 72272, undefined Cauã de Nossa Senhora, ES',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('16329974634', '210847099591', 'Marli Franco', 'Lucca Travessa, 2172, Shreveport, MS',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('59043336380', '966462650056', 'Heitor Silva', 'Frederico Alameda, 59927, undefined Eduarda, PB',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('20972278714', '217094629700', 'Ladislau Albuquerque',
        'Albuquerque Avenida, 63198, Oliveira de Nossa Senhora, AL',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('92095009516', '235747190634', 'Giovanna Nogueira', 'Barros Rodovia, 78969, Barros de Nossa Senhora, PE',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('55663887299', '852881499170', 'Murilo Reis', 'Souza Travessa, 80190, OFallon, AM',
        'superior completo');
INSERT INTO Pessoa
VALUES ('10547932805', '761554930056', 'Carlos Reis', 'Sílvia Marginal, 52787, Oliveira do Norte, RS',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('68522295455', '904929971299', 'Júlia Martins', 'Moraes Rodovia, 89534, Costa do Sul, RJ',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('87970591781', '257288397639', 'Maria Alice Reis', 'Macedo Rua, 71913, Lowell, AL',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('75000258060', '596975563908', 'Lorena Saraiva', 'Costa Avenida, 10527, undefined Manuela do Descoberto, BA',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('96234430314', '178494047815', 'Alessandro Oliveira', 'Margarida Marginal, 88035, Danbury, RR',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('40909250010', '889906445238', 'Ígor Moraes', 'Nicolas Rua, 40537, Carrollton, BA',
        'doutorado');
INSERT INTO Pessoa
VALUES ('61522070106', '907318059960', 'Margarida Saraiva', 'Souza Alameda, 68526, Melo do Sul, BA',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('49292941880', '783745419606', 'Daniel Braga', 'Moraes Travessa, 27042, Xavier de Nossa Senhora, PI',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('50501488286', '148620057478', 'Suélen Souza', 'Isis Avenida, 76233, Azusa, CE',
        'mestrado');
INSERT INTO Pessoa
VALUES ('57025125327', '434977939189', 'Gabriel Braga', 'Esther Travessa, 47433, Leonardo de Nossa Senhora, TO',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('54010952000', '713675339543', 'Eduardo Moraes',
        'Albuquerque Rodovia, 16508, undefined Sophia de Nossa Senhora, RS',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('61883076978', '326110777771', 'João Pedro Reis', 'Costa Travessa, 24507, Pereira do Sul, GO',
        'mestrado');
INSERT INTO Pessoa
VALUES ('25002746400', '274887534393', 'Sophia Nogueira', 'Franco Rua, 36701, undefined Danilo do Sul, MS',
        'superior completo');
INSERT INTO Pessoa
VALUES ('44718153213', '647403656574', 'Antônio Moreira', 'Melo Rua, 16165, Fabrícia do Descoberto, RN',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('49287718026', '932749317237', 'Benício Franco', 'Carvalho Alameda, 83226, undefined Eduarda, PI',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('15527605952', '648887395299', 'Valentina Martins',
        'Felícia Rua, 89726, undefined Júlio César do Descoberto, PA',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('99513478213', '354593788762', 'Benjamin Silva', 'Felipe Rua, 19235, undefined Ígor do Norte, AL',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('49351430758', '360025628935', 'Margarida Souza',
        'Antônio Avenida, 74816, undefined Maria Clara de Nossa Senhora, RS',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('41319743199', '438817669544', 'Márcia Moreira', 'Barros Marginal, 41771, Reis de Nossa Senhora, PE',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('36434444980', '622228306136', 'Marina Xavier', 'Júlia Alameda, 55359, undefined Henrique, RJ',
        'superior completo');
INSERT INTO Pessoa
VALUES ('71358629062', '561874597379', 'Emanuel Martins', 'Tertuliano Rua, 2992, Ana Júlia do Sul, RJ',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('46922632912', '852681564795', 'Roberta Moraes', 'Ígor Alameda, 64274, Maria Cecília do Sul, PR',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('12808932473', '125717217638', 'Valentina Pereira', 'Liz Rua, 29018, Macedo do Norte, PB',
        'mestrado');
INSERT INTO Pessoa
VALUES ('95593594631', '116366818454', 'Luiza Souza', 'Murilo Travessa, 43197, Lorraine do Descoberto, AM',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('52019781784', '614334425656', 'Maria Alice Melo', 'Santos Avenida, 12540, Carvalho do Descoberto, CE',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('72547784710', '396984147792', 'Sara Costa', 'Noah Marginal, 60363, Pablo de Nossa Senhora, BA',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('55037683360', '605318969418', 'Fabiano Braga', 'Clara Travessa, 94822, Clara do Descoberto, RR',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('76696378767', '124553367123', 'Sílvia Oliveira', 'João Miguel Rodovia, 77384, Louisville/Jefferson County, MS',
        'mestrado');
INSERT INTO Pessoa
VALUES ('57094097116', '335684161982', 'Yuri Batista', 'Maitê Rua, 70662, undefined Suélen do Norte, CE',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('70844363323', '103204017691', 'Isabela Silva', 'Antônio Avenida, 22132, Melo do Descoberto, SP',
        'mestrado');
INSERT INTO Pessoa
VALUES ('48704881865', '271887451969', 'Pedro Henrique Melo', 'Carvalho Avenida, 68795, undefined Calebe, MG',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('45475941675', '791323064500', 'Vitor Batista', 'Silva Travessa, 86733, Martins do Norte, SE',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('46417632382', '758629084262', 'Margarida Moraes', 'Silva Avenida, 36389, undefined Alexandre, MG',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('23186676069', '261207988881', 'Natália Melo', 'Ana Júlia Rua, 13596, Moraes do Norte, BA',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('39274698467', '384581267763', 'Cecília Souza', 'Pablo Travessa, 38244, Melo do Sul, SP',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('35423602398', '992095919162', 'Calebe Batista', 'Hélio Alameda, 98683, Pflugerville, PB',
        'analfabeto');


--- Insere programa partidos

INSERT INTO Programa_Partido
VALUES ('2f99a0c6-14b2-423c-a42d-4971f385492e',
        'Voluptas aliquid quisquam quia aut tempore iusto qui tempore aut blanditiis omnis odio dolor sint atque id consequatur est sapiente.',
        '2007-9-14');
INSERT INTO Programa_Partido
VALUES ('c52c8893-bc14-4506-9829-3401291ad1ef',
        'Rerum maxime facere perspiciatis doloremque ex qui non expedita nesciunt labore consequatur est quo aut veniam optio non aperiam natus.',
        '2009-2-26');
INSERT INTO Programa_Partido
VALUES ('2097d321-f086-4af6-8769-23012d6df5f4',
        'Quae sunt cupiditate quos commodi recusandae maiores vel aliquam facilis non ducimus sunt ullam dolorem harum architecto qui rerum est.',
        '2017-6-2');
INSERT INTO Programa_Partido
VALUES ('656d324a-7add-4d50-90b4-d223b81d33f7',
        'Repellat totam cupiditate aut veritatis ipsa quasi ipsam vero recusandae voluptas qui et corrupti accusantium aspernatur totam aut officia sit.',
        '2018-7-10');
INSERT INTO Programa_Partido
VALUES ('29a59514-bf06-4663-a580-fddc1ed66778',
        'Laudantium voluptate quae maxime sed soluta veritatis corrupti eligendi alias fugit velit nemo dignissimos molestiae et alias possimus quae nesciunt.',
        '2014-10-1');
INSERT INTO Programa_Partido
VALUES ('41a40280-ab3e-4f77-bf09-f26698aada94',
        'Consequuntur suscipit eligendi vel perspiciatis quod occaecati dicta distinctio et iste neque sed ab non aut autem omnis incidunt ullam.',
        '2019-3-26');
INSERT INTO Programa_Partido
VALUES ('e4f7abaa-fb6d-4ba1-935c-53944e355356',
        'Temporibus soluta ratione rem repellat consequatur cupiditate quae incidunt rem ea consequatur et repudiandae eveniet et sit sit totam omnis.',
        '2006-12-27');
INSERT INTO Programa_Partido
VALUES ('63bfbccd-78e7-415e-8c3c-a4982a085560',
        'Neque animi et quis earum rem voluptatem nostrum enim aspernatur harum error sed neque nesciunt quo autem ullam reprehenderit facilis.',
        '2007-6-9');
INSERT INTO Programa_Partido
VALUES ('ee20215b-009b-4593-99c1-c18831ed9631',
        'Molestiae vel similique aut laborum et corporis rerum quis velit perspiciatis a et reiciendis delectus et reprehenderit architecto illum nemo.',
        '2016-6-28');
INSERT INTO Programa_Partido
VALUES ('c2b4b108-48dd-41b5-989a-3aad25db6ca4',
        'Veniam voluptatibus velit architecto eligendi omnis qui a tenetur rerum rerum provident est eos saepe porro dolorem ut labore asperiores.',
        '2015-2-14');
INSERT INTO Programa_Partido
VALUES ('c7c56782-2a5f-4226-8278-7e186b48582b',
        'Velit perspiciatis optio libero ratione eum ullam eligendi ut dicta quia perspiciatis eum aut consequatur numquam ducimus quis non blanditiis.',
        '2017-5-1');
INSERT INTO Programa_Partido
VALUES ('f37ee4b1-aab2-44f0-9e77-f260e5996aa2',
        'Culpa quia ducimus dignissimos aliquid ut incidunt officiis minima dolorem hic ratione alias consequatur ex quia praesentium blanditiis libero facere.',
        '2021-4-26');
INSERT INTO Programa_Partido
VALUES ('bbdffa48-2fa8-4b79-b1b8-857fa9be3342',
        'Sit accusamus et cumque dolorum accusantium ullam quidem aperiam aut suscipit est animi enim placeat laboriosam officia nihil facilis corporis.',
        '2013-5-7');
INSERT INTO Programa_Partido
VALUES ('f02d00e3-ef58-425c-a453-ca3b5e649610',
        'Consequuntur quia eos maiores commodi ab aperiam et fuga commodi veritatis blanditiis consectetur id et est quae consectetur quae sint.',
        '2010-9-17');
INSERT INTO Programa_Partido
VALUES ('298d5e44-9307-4285-bcec-92bc565788fe',
        'Vitae exercitationem sit est blanditiis ducimus unde quo neque eveniet dolor ut eum facere aut id autem quis dolorum ab.',
        '2011-11-15');
INSERT INTO Programa_Partido
VALUES ('b4668fbe-7965-4a09-80b3-d5591d1867e8',
        'Ut quae sunt voluptatem blanditiis unde rerum sit quis fuga distinctio consequatur magni ex sunt dicta id nam et excepturi.',
        '2011-6-14');
INSERT INTO Programa_Partido
VALUES ('17b0dea6-53f0-4f2a-9110-81ad7304f0a7',
        'Eius in tenetur minima voluptatum non ut voluptatem commodi suscipit eveniet omnis minima repellat hic velit aut voluptatem qui ipsam.',
        '2007-1-15');
INSERT INTO Programa_Partido
VALUES ('beed2dc8-70ea-4a22-a094-c48495f004bf',
        'Nobis vel ut id quia explicabo reiciendis repellendus tenetur nulla nihil et sed doloremque ipsa libero repudiandae officiis enim sapiente.',
        '2007-3-25');
INSERT INTO Programa_Partido
VALUES ('f4760900-94f3-4328-9c51-44f121068372',
        'Quis quis fugiat impedit amet sint voluptatum id magnam est quas pariatur est voluptatem ut ex cumque eveniet illo facere.',
        '2008-8-23');
INSERT INTO Programa_Partido
VALUES ('f1b98028-0899-43b4-aac8-0f29f624b979',
        'Atque vitae quod eum similique cumque reprehenderit rerum minus nihil suscipit animi in aspernatur pariatur harum fugit quasi numquam laborum.',
        '2016-9-16');


--- Insere partidos
INSERT INTO Partido
VALUES ('MDB', 'Movimento Democrático Brasileiro', '83880074904', '2007-2-5',
        '2f99a0c6-14b2-423c-a42d-4971f385492e');
INSERT INTO Partido
VALUES ('PT', 'Partido dos Trabalhadores', '79759667741', '2002-9-29',
        'c7c56782-2a5f-4226-8278-7e186b48582b');
INSERT INTO Partido
VALUES ('PSDB', 'Partido da Social Democracia Brasileira', '21313558840', '2010-5-21',
        'f4760900-94f3-4328-9c51-44f121068372');
INSERT INTO Partido
VALUES ('PP', 'Progressistas', '69487778153', '2009-3-23',
        '17b0dea6-53f0-4f2a-9110-81ad7304f0a7');
INSERT INTO Partido
VALUES ('PDT', 'Partido Democrático Trabalhista', '92624975838', '2007-1-6',
        '29a59514-bf06-4663-a580-fddc1ed66778');
INSERT INTO Partido
VALUES ('PTB', 'Partido Trabalhista Brasileiro', '73157967103', '1997-6-6',
        'f02d00e3-ef58-425c-a453-ca3b5e649610');


-- Insere Candidato
INSERT INTO Candidato
VALUES ('23186676069', 'PP');
INSERT INTO Candidato
VALUES ('29294251089', 'PDT');
INSERT INTO Candidato
VALUES ('36434444980', 'MDB');
INSERT INTO Candidato
VALUES ('90814044619', 'PT');
INSERT INTO Candidato
VALUES ('21211647114', 'PT');
INSERT INTO Candidato
VALUES ('71402272270', 'MDB');
INSERT INTO Candidato
VALUES ('33842867389', 'MDB');
INSERT INTO Candidato
VALUES ('24106467796', 'PDT');
INSERT INTO Candidato
VALUES ('47333944300', 'PSDB');
INSERT INTO Candidato
VALUES ('89382796012', 'MDB');
INSERT INTO Candidato
VALUES ('65379982653', 'PDT');
INSERT INTO Candidato
VALUES ('30518274260', 'PTB');
INSERT INTO Candidato
VALUES ('19264541170', 'PSDB');
INSERT INTO Candidato
VALUES ('16127951364', 'MDB');
INSERT INTO Candidato
VALUES ('92201869981', 'PP');
INSERT INTO Candidato
VALUES ('54967094177', 'MDB');
INSERT INTO Candidato
VALUES ('60858012235', 'PSDB');
INSERT INTO Candidato
VALUES ('94102552335', 'PSDB');
INSERT INTO Candidato
VALUES ('39589262660', 'PP');
INSERT INTO Candidato
VALUES ('49390348521', 'PDT');
INSERT INTO Candidato
VALUES ('44186261715', 'PP');
INSERT INTO Candidato
VALUES ('55121575377', 'PT');
INSERT INTO Candidato
VALUES ('44718786508', 'PDT');
INSERT INTO Candidato
VALUES ('76957148555', 'PT');
INSERT INTO Candidato
VALUES ('57039100097', 'PP');
INSERT INTO Candidato
VALUES ('80954469083', 'PSDB');
INSERT INTO Candidato
VALUES ('36720092277', 'MDB');
INSERT INTO Candidato
VALUES ('66035738396', 'MDB');
INSERT INTO Candidato
VALUES ('68666926997', 'PT');
INSERT INTO Candidato
VALUES ('96782912428', 'PT');
INSERT INTO Candidato
VALUES ('57704504102', 'PDT');
INSERT INTO Candidato
VALUES ('81479468415', 'PP');
INSERT INTO Candidato
VALUES ('39573748449', 'PTB');
INSERT INTO Candidato
VALUES ('63900773341', 'PP');
INSERT INTO Candidato
VALUES ('11269307890', 'PT');
INSERT INTO Candidato
VALUES ('37841710573', 'PTB');
INSERT INTO Candidato
VALUES ('87642632594', 'PSDB');
INSERT INTO Candidato
VALUES ('34047008347', 'PDT');
INSERT INTO Candidato
VALUES ('97614736857', 'PTB');
INSERT INTO Candidato
VALUES ('12347521192', 'PSDB');
INSERT INTO Candidato
VALUES ('49351430758', 'PT');
INSERT INTO Candidato
VALUES ('38956106749', 'PDT');
INSERT INTO Candidato
VALUES ('98747927837', 'PSDB');
INSERT INTO Candidato
VALUES ('11703440623', 'PDT');
INSERT INTO Candidato
VALUES ('20656491559', 'PT');
INSERT INTO Candidato
VALUES ('89264845682', 'PT');
INSERT INTO Candidato
VALUES ('92312295855', 'PSDB');
INSERT INTO Candidato
VALUES ('38939672771', 'PP');
INSERT INTO Candidato
VALUES ('32608546945', 'PP');
INSERT INTO Candidato
VALUES ('22103242517', 'PSDB');
INSERT INTO Candidato
VALUES ('37415883594', 'PTB');
INSERT INTO Candidato
VALUES ('37581900996', 'PDT');
INSERT INTO Candidato
VALUES ('55752608675', 'PDT');
INSERT INTO Candidato
VALUES ('16469240479', 'PT');
INSERT INTO Candidato
VALUES ('67562512347', 'PTB');
INSERT INTO Candidato
VALUES ('97079823934', 'PTB');
INSERT INTO Candidato
VALUES ('78782798836', 'PT');
INSERT INTO Candidato
VALUES ('74122189518', 'PT');
INSERT INTO Candidato
VALUES ('77571850281', 'PSDB');
INSERT INTO Candidato
VALUES ('20593875704', 'PT');
INSERT INTO Candidato
VALUES ('56399587204', 'PSDB');
INSERT INTO Candidato
VALUES ('29509833429', 'PTB');
INSERT INTO Candidato
VALUES ('76696378767', 'PTB');
INSERT INTO Candidato
VALUES ('24302034655', 'PP');
INSERT INTO Candidato
VALUES ('48273120142', 'MDB');
INSERT INTO Candidato
VALUES ('88463596005', 'PP');
INSERT INTO Candidato
VALUES ('68038586615', 'PSDB');
INSERT INTO Candidato
VALUES ('81137500617', 'PDT');
INSERT INTO Candidato
VALUES ('79479726215', 'PTB');
INSERT INTO Candidato
VALUES ('11475470627', 'PDT');
INSERT INTO Candidato
VALUES ('16082053717', 'PT');
INSERT INTO Candidato
VALUES ('94763610071', 'PDT');
INSERT INTO Candidato
VALUES ('70077948186', 'PSDB');
INSERT INTO Candidato
VALUES ('45491204094', 'PT');
INSERT INTO Candidato
VALUES ('80229327632', 'PSDB');
INSERT INTO Candidato
VALUES ('17353439859', 'PDT');
INSERT INTO Candidato
VALUES ('78031077992', 'PDT');
INSERT INTO Candidato
VALUES ('79691960571', 'PTB');
INSERT INTO Candidato
VALUES ('72560434259', 'MDB');
INSERT INTO Candidato
VALUES ('72597053705', 'PT');
INSERT INTO Candidato
VALUES ('36892929635', 'PSDB');
INSERT INTO Candidato
VALUES ('19436460018', 'MDB');
INSERT INTO Candidato
VALUES ('41320017329', 'PT');
INSERT INTO Candidato
VALUES ('60652495953', 'MDB');
INSERT INTO Candidato
VALUES ('74808992438', 'PTB');
INSERT INTO Candidato
VALUES ('90560006066', 'PT');
INSERT INTO Candidato
VALUES ('66159643984', 'PSDB');
INSERT INTO Candidato
VALUES ('98907837094', 'PP');
INSERT INTO Candidato
VALUES ('33855974653', 'PP');
INSERT INTO Candidato
VALUES ('74363441457', 'MDB');
INSERT INTO Candidato
VALUES ('32739312681', 'PTB');
INSERT INTO Candidato
VALUES ('93519565530', 'MDB');
INSERT INTO Candidato
VALUES ('44038899224', 'PP');
INSERT INTO Candidato
VALUES ('98591816106', 'PDT');
INSERT INTO Candidato
VALUES ('98239704843', 'PSDB');
INSERT INTO Candidato
VALUES ('47442891250', 'MDB');
INSERT INTO Candidato
VALUES ('18092176485', 'PDT');
INSERT INTO Candidato
VALUES ('50602269105', 'PSDB');
INSERT INTO Candidato
VALUES ('73590556099', 'PSDB');
INSERT INTO Candidato
VALUES ('68837744630', 'MDB');
INSERT INTO Candidato
VALUES ('60751450103', 'PT');
INSERT INTO Candidato
VALUES ('15441784567', 'PTB');
INSERT INTO Candidato
VALUES ('35165164980', 'PSDB');
INSERT INTO Candidato
VALUES ('86604477623', 'PTB');
INSERT INTO Candidato
VALUES ('44529969659', 'PSDB');
INSERT INTO Candidato
VALUES ('22431804153', 'PDT');
INSERT INTO Candidato
VALUES ('40780232739', 'MDB');
INSERT INTO Candidato
VALUES ('55663887299', 'PDT');
INSERT INTO Candidato
VALUES ('82486186116', 'PP');
INSERT INTO Candidato
VALUES ('10292860679', 'PDT');
INSERT INTO Candidato
VALUES ('99513478213', 'PSDB');
INSERT INTO Candidato
VALUES ('41136322179', 'MDB');
INSERT INTO Candidato
VALUES ('25336353376', 'MDB');
INSERT INTO Candidato
VALUES ('61669403030', 'PTB');
INSERT INTO Candidato
VALUES ('40851067951', 'PT');
INSERT INTO Candidato
VALUES ('32622446236', 'PP');
INSERT INTO Candidato
VALUES ('34996525992', 'PP');
INSERT INTO Candidato
VALUES ('27500320235', 'PTB');
INSERT INTO Candidato
VALUES ('11253295710', 'PT');
INSERT INTO Candidato
VALUES ('56845003822', 'MDB');
INSERT INTO Candidato
VALUES ('16470102223', 'PDT');
INSERT INTO Candidato
VALUES ('73315387605', 'PSDB');
INSERT INTO Candidato
VALUES ('80291202422', 'PT');
INSERT INTO Candidato
VALUES ('50501488286', 'PDT');
INSERT INTO Candidato
VALUES ('67123855608', 'PDT');
INSERT INTO Candidato
VALUES ('45083095934', 'PSDB');
INSERT INTO Candidato
VALUES ('14724061477', 'PTB');
INSERT INTO Candidato
VALUES ('50428395869', 'PDT');
INSERT INTO Candidato
VALUES ('16521542130', 'MDB');
INSERT INTO Candidato
VALUES ('41319743199', 'PTB');
INSERT INTO Candidato
VALUES ('18004457291', 'PDT');
INSERT INTO Candidato
VALUES ('61657774816', 'PSDB');
INSERT INTO Candidato
VALUES ('10737233394', 'PP');
INSERT INTO Candidato
VALUES ('21487723933', 'PTB');
INSERT INTO Candidato
VALUES ('53108889381', 'PT');
INSERT INTO Candidato
VALUES ('38589444733', 'PT');
INSERT INTO Candidato
VALUES ('83880074904', 'MDB');
INSERT INTO Candidato
VALUES ('21879325024', 'MDB');
INSERT INTO Candidato
VALUES ('45065363431', 'PDT');
INSERT INTO Candidato
VALUES ('97468617402', 'PT');
INSERT INTO Candidato
VALUES ('12061152968', 'PDT');
INSERT INTO Candidato
VALUES ('76882689699', 'PDT');
INSERT INTO Candidato
VALUES ('65408776691', 'MDB');
INSERT INTO Candidato
VALUES ('44331545557', 'PP');
INSERT INTO Candidato
VALUES ('83129861042', 'PTB');
INSERT INTO Candidato
VALUES ('85275710606', 'PSDB');
INSERT INTO Candidato
VALUES ('98618554964', 'PDT');
INSERT INTO Candidato
VALUES ('58745565121', 'MDB');
INSERT INTO Candidato
VALUES ('68820670107', 'PDT');
INSERT INTO Candidato
VALUES ('23647714878', 'PT');
INSERT INTO Candidato
VALUES ('52510659939', 'PSDB');
INSERT INTO Candidato
VALUES ('94048417352', 'PP');
INSERT INTO Candidato
VALUES ('68540927693', 'PDT');
INSERT INTO Candidato
VALUES ('45014148892', 'PP');
INSERT INTO Candidato
VALUES ('54183079097', 'MDB');
INSERT INTO Candidato
VALUES ('76707281675', 'PSDB');
INSERT INTO Candidato
VALUES ('45456711661', 'PT');
INSERT INTO Candidato
VALUES ('45923760337', 'PTB');
INSERT INTO Candidato
VALUES ('41465124920', 'PT');
INSERT INTO Candidato
VALUES ('41139387378', 'PDT');
INSERT INTO Candidato
VALUES ('15691747337', 'PP');
INSERT INTO Candidato
VALUES ('56009768713', 'PP');
INSERT INTO Candidato
VALUES ('70844363323', 'PTB');
INSERT INTO Candidato
VALUES ('85526398515', 'PDT');
INSERT INTO Candidato
VALUES ('21481214086', 'PSDB');
INSERT INTO Candidato
VALUES ('43331410249', 'MDB');
INSERT INTO Candidato
VALUES ('92776450554', 'PP');
INSERT INTO Candidato
VALUES ('47314490594', 'PDT');
INSERT INTO Candidato
VALUES ('44503644322', 'PSDB');
INSERT INTO Candidato
VALUES ('22932819214', 'PT');
INSERT INTO Candidato
VALUES ('57039934452', 'PT');
INSERT INTO Candidato
VALUES ('79646575415', 'PDT');
INSERT INTO Candidato
VALUES ('21425575076', 'PDT');
INSERT INTO Candidato
VALUES ('32125016890', 'PP');
INSERT INTO Candidato
VALUES ('51697040249', 'PDT');
INSERT INTO Candidato
VALUES ('90985128022', 'PSDB');
INSERT INTO Candidato
VALUES ('34757250568', 'PP');
INSERT INTO Candidato
VALUES ('44718153213', 'PT');
INSERT INTO Candidato
VALUES ('73656000972', 'MDB');
INSERT INTO Candidato
VALUES ('84774450208', 'MDB');
INSERT INTO Candidato
VALUES ('28238024273', 'PSDB');
INSERT INTO Candidato
VALUES ('70319649500', 'PDT');
INSERT INTO Candidato
VALUES ('83759686551', 'MDB');
INSERT INTO Candidato
VALUES ('54206616906', 'PTB');
INSERT INTO Candidato
VALUES ('25756717512', 'PTB');
INSERT INTO Candidato
VALUES ('14975074331', 'PP');
INSERT INTO Candidato
VALUES ('79293712463', 'PDT');
INSERT INTO Candidato
VALUES ('89025817608', 'PDT');
INSERT INTO Candidato
VALUES ('36824277385', 'PTB');
INSERT INTO Candidato
VALUES ('98036637124', 'PDT');
INSERT INTO Candidato
VALUES ('57979449972', 'PSDB');
INSERT INTO Candidato
VALUES ('30010755995', 'PDT');
INSERT INTO Candidato
VALUES ('15201660203', 'PDT');
INSERT INTO Candidato
VALUES ('94022594343', 'PP');
INSERT INTO Candidato
VALUES ('46597759188', 'PSDB');
INSERT INTO Candidato
VALUES ('26279341266', 'MDB');
INSERT INTO Candidato
VALUES ('26168256616', 'MDB');
INSERT INTO Candidato
VALUES ('10547932805', 'MDB');
INSERT INTO Candidato
VALUES ('81651619777', 'PSDB');
INSERT INTO Candidato
VALUES ('22529268462', 'PSDB');
INSERT INTO Candidato
VALUES ('92302586049', 'PT');
INSERT INTO Candidato
VALUES ('23072280755', 'PSDB');
INSERT INTO Candidato
VALUES ('41830698924', 'PSDB');
INSERT INTO Candidato
VALUES ('33952316290', 'PDT');
INSERT INTO Candidato
VALUES ('25902807421', 'PSDB');
INSERT INTO Candidato
VALUES ('98786025829', 'PT');
INSERT INTO Candidato
VALUES ('92418782110', 'PSDB');
INSERT INTO Candidato
VALUES ('58593827674', 'PT');
INSERT INTO Candidato
VALUES ('96993440124', 'MDB');
INSERT INTO Candidato
VALUES ('75875466403', 'MDB');
INSERT INTO Candidato
VALUES ('79832300976', 'PP');
INSERT INTO Candidato
VALUES ('45628193288', 'PT');
INSERT INTO Candidato
VALUES ('94322587393', 'MDB');
INSERT INTO Candidato
VALUES ('59162837509', 'PTB');
INSERT INTO Candidato
VALUES ('26070068068', 'PP');
INSERT INTO Candidato
VALUES ('20934364222', 'PT');
INSERT INTO Candidato
VALUES ('74744968109', 'PT');
INSERT INTO Candidato
VALUES ('92465915710', 'PP');
INSERT INTO Candidato
VALUES ('26868924126', 'PT');
INSERT INTO Candidato
VALUES ('83155709574', 'PP');
INSERT INTO Candidato
VALUES ('61147306519', 'PTB');
INSERT INTO Candidato
VALUES ('12995957187', 'PT');
INSERT INTO Candidato
VALUES ('85730072224', 'MDB');
INSERT INTO Candidato
VALUES ('34218765089', 'MDB');
INSERT INTO Candidato
VALUES ('37930955484', 'PSDB');
INSERT INTO Candidato
VALUES ('51308676458', 'MDB');
INSERT INTO Candidato
VALUES ('29592667378', 'PP');
INSERT INTO Candidato
VALUES ('88576750692', 'PP');
INSERT INTO Candidato
VALUES ('28168813411', 'PP');
INSERT INTO Candidato
VALUES ('52203854476', 'PSDB');
INSERT INTO Candidato
VALUES ('23625731619', 'PTB');
INSERT INTO Candidato
VALUES ('93630574638', 'PSDB');
INSERT INTO Candidato
VALUES ('27592656244', 'MDB');
INSERT INTO Candidato
VALUES ('50671691924', 'MDB');
INSERT INTO Candidato
VALUES ('13525109647', 'PSDB');
INSERT INTO Candidato
VALUES ('31935233147', 'PDT');
INSERT INTO Candidato
VALUES ('60686908485', 'PTB');
INSERT INTO Candidato
VALUES ('45330556328', 'PDT');
INSERT INTO Candidato
VALUES ('52914412149', 'PP');
INSERT INTO Candidato
VALUES ('34047240966', 'PP');
INSERT INTO Candidato
VALUES ('97070763893', 'PT');
INSERT INTO Candidato
VALUES ('66703392334', 'PP');
INSERT INTO Candidato
VALUES ('58487967234', 'PDT');
INSERT INTO Candidato
VALUES ('66040890542', 'MDB');
INSERT INTO Candidato
VALUES ('41297736910', 'PT');
INSERT INTO Candidato
VALUES ('95344005359', 'PTB');
INSERT INTO Candidato
VALUES ('17823370946', 'MDB');
INSERT INTO Candidato
VALUES ('38465311408', 'PDT');
INSERT INTO Candidato
VALUES ('35331775275', 'PP');
INSERT INTO Candidato
VALUES ('13566240610', 'PT');
INSERT INTO Candidato
VALUES ('51165132678', 'PT');
INSERT INTO Candidato
VALUES ('49287718026', 'PSDB');
INSERT INTO Candidato
VALUES ('98128233787', 'PP');
INSERT INTO Candidato
VALUES ('15176868964', 'PTB');
INSERT INTO Candidato
VALUES ('20972804070', 'PTB');
INSERT INTO Candidato
VALUES ('22237183297', 'PT');
INSERT INTO Candidato
VALUES ('15118655033', 'PDT');
INSERT INTO Candidato
VALUES ('39486719819', 'PSDB');
INSERT INTO Candidato
VALUES ('98076882518', 'PT');
INSERT INTO Candidato
VALUES ('67661317153', 'PT');
INSERT INTO Candidato
VALUES ('74479391069', 'PT');
INSERT INTO Candidato
VALUES ('16068811987', 'PSDB');
INSERT INTO Candidato
VALUES ('63931753861', 'MDB');
INSERT INTO Candidato
VALUES ('65929289441', 'PDT');
INSERT INTO Candidato
VALUES ('55582106600', 'PTB');
INSERT INTO Candidato
VALUES ('73727615827', 'MDB');
INSERT INTO Candidato
VALUES ('62031259345', 'PP');
INSERT INTO Candidato
VALUES ('25783153302', 'PTB');
INSERT INTO Candidato
VALUES ('76850075086', 'PDT');
INSERT INTO Candidato
VALUES ('51977524964', 'MDB');
INSERT INTO Candidato
VALUES ('21313558840', 'PDT');
INSERT INTO Candidato
VALUES ('96349825211', 'PDT');
INSERT INTO Candidato
VALUES ('45510409004', 'PTB');
INSERT INTO Candidato
VALUES ('31219225791', 'MDB');
INSERT INTO Candidato
VALUES ('91139727742', 'PTB');
INSERT INTO Candidato
VALUES ('62509119817', 'PSDB');
INSERT INTO Candidato
VALUES ('73635011366', 'PSDB');
INSERT INTO Candidato
VALUES ('14747534578', 'MDB');
INSERT INTO Candidato
VALUES ('99220432315', 'PTB');
INSERT INTO Candidato
VALUES ('76737339326', 'PP');
INSERT INTO Candidato
VALUES ('12808932473', 'PP');
INSERT INTO Candidato
VALUES ('47388927007', 'PP');
INSERT INTO Candidato
VALUES ('64779439785', 'PSDB');
INSERT INTO Candidato
VALUES ('91857076140', 'PT');
INSERT INTO Candidato
VALUES ('49829237502', 'PSDB');
INSERT INTO Candidato
VALUES ('56085495813', 'PT');
INSERT INTO Candidato
VALUES ('74025096402', 'PSDB');
INSERT INTO Candidato
VALUES ('93640094532', 'PTB');
INSERT INTO Candidato
VALUES ('49999960965', 'PTB');
INSERT INTO Candidato
VALUES ('73055091793', 'MDB');
INSERT INTO Candidato
VALUES ('69626756855', 'PTB');
INSERT INTO Candidato
VALUES ('63260848645', 'MDB');
INSERT INTO Candidato
VALUES ('51777044697', 'MDB');
INSERT INTO Candidato
VALUES ('38865358545', 'PSDB');
INSERT INTO Candidato
VALUES ('61522070106', 'PSDB');
INSERT INTO Candidato
VALUES ('49970481498', 'PP');
INSERT INTO Candidato
VALUES ('97555941788', 'PDT');
INSERT INTO Candidato
VALUES ('80266070396', 'PT');
INSERT INTO Candidato
VALUES ('50634076290', 'MDB');
INSERT INTO Candidato
VALUES ('50441387610', 'PP');
INSERT INTO Candidato
VALUES ('61577998858', 'PDT');
INSERT INTO Candidato
VALUES ('52959466576', 'PTB');
INSERT INTO Candidato
VALUES ('28038902608', 'PT');
INSERT INTO Candidato
VALUES ('14908413034', 'MDB');
INSERT INTO Candidato
VALUES ('92511644628', 'PT');
INSERT INTO Candidato
VALUES ('62782628233', 'PDT');
INSERT INTO Candidato
VALUES ('18369440392', 'MDB');
INSERT INTO Candidato
VALUES ('18165175339', 'PSDB');
INSERT INTO Candidato
VALUES ('75959301025', 'PDT');
INSERT INTO Candidato
VALUES ('86252562392', 'MDB');
INSERT INTO Candidato
VALUES ('67951579191', 'PDT');
INSERT INTO Candidato
VALUES ('44202141419', 'PTB');
INSERT INTO Candidato
VALUES ('17060826153', 'MDB');
INSERT INTO Candidato
VALUES ('76793153581', 'PTB');
INSERT INTO Candidato
VALUES ('70315878796', 'PTB');
INSERT INTO Candidato
VALUES ('85119483100', 'PTB');
INSERT INTO Candidato
VALUES ('61486375667', 'PSDB');
INSERT INTO Candidato
VALUES ('40210098912', 'PSDB');
INSERT INTO Candidato
VALUES ('65327025726', 'PT');
INSERT INTO Candidato
VALUES ('25677760089', 'PP');
INSERT INTO Candidato
VALUES ('68435227326', 'MDB');
INSERT INTO Candidato
VALUES ('25196086270', 'MDB');
INSERT INTO Candidato
VALUES ('46683265664', 'PT');
INSERT INTO Candidato
VALUES ('28576460210', 'MDB');
INSERT INTO Candidato
VALUES ('67022069275', 'PDT');
INSERT INTO Candidato
VALUES ('74132363493', 'PP');
INSERT INTO Candidato
VALUES ('26318127936', 'PTB');
INSERT INTO Candidato
VALUES ('55435475325', 'PP');
INSERT INTO Candidato
VALUES ('72249765472', 'PDT');
INSERT INTO Candidato
VALUES ('35895102075', 'PP');
INSERT INTO Candidato
VALUES ('80575645365', 'PP');
INSERT INTO Candidato
VALUES ('20882765164', 'PSDB');
INSERT INTO Candidato
VALUES ('91388181308', 'PT');
INSERT INTO Candidato
VALUES ('49404086042', 'PDT');
INSERT INTO Candidato
VALUES ('41487482076', 'PDT');
INSERT INTO Candidato
VALUES ('82639195390', 'PTB');
INSERT INTO Candidato
VALUES ('94417993945', 'PP');
INSERT INTO Candidato
VALUES ('84474516983', 'PT');
INSERT INTO Candidato
VALUES ('31459604231', 'PSDB');
INSERT INTO Candidato
VALUES ('68331766016', 'PDT');
INSERT INTO Candidato
VALUES ('12399218089', 'PSDB');
INSERT INTO Candidato
VALUES ('74194578086', 'MDB');
INSERT INTO Candidato
VALUES ('44674791889', 'MDB');
INSERT INTO Candidato
VALUES ('31800616828', 'PP');
INSERT INTO Candidato
VALUES ('40710145486', 'PP');
INSERT INTO Candidato
VALUES ('91566400225', 'PP');
INSERT INTO Candidato
VALUES ('93598506252', 'MDB');
INSERT INTO Candidato
VALUES ('71272484597', 'PTB');
INSERT INTO Candidato
VALUES ('69930587140', 'PTB');
INSERT INTO Candidato
VALUES ('12062577367', 'PP');
INSERT INTO Candidato
VALUES ('87970591781', 'PTB');
INSERT INTO Candidato
VALUES ('95605694998', 'PSDB');
INSERT INTO Candidato
VALUES ('44884157183', 'PT');
INSERT INTO Candidato
VALUES ('83461462480', 'PSDB');
INSERT INTO Candidato
VALUES ('47530116646', 'PTB');
INSERT INTO Candidato
VALUES ('31276211123', 'PDT');
INSERT INTO Candidato
VALUES ('52019781784', 'PP');
INSERT INTO Candidato
VALUES ('49141727066', 'PDT');
INSERT INTO Candidato
VALUES ('29694294098', 'PTB');
INSERT INTO Candidato
VALUES ('48220131113', 'PSDB');
INSERT INTO Candidato
VALUES ('86534657040', 'PSDB');
INSERT INTO Candidato
VALUES ('87764965905', 'PP');
INSERT INTO Candidato
VALUES ('82870189829', 'PTB');
INSERT INTO Candidato
VALUES ('29875680117', 'PDT');
INSERT INTO Candidato
VALUES ('43586174864', 'PTB');
INSERT INTO Candidato
VALUES ('37254095533', 'PTB');
INSERT INTO Candidato
VALUES ('42174338325', 'PSDB');
INSERT INTO Candidato
VALUES ('76377020021', 'PTB');
INSERT INTO Candidato
VALUES ('59691281320', 'PTB');
INSERT INTO Candidato
VALUES ('60893714134', 'PP');
INSERT INTO Candidato
VALUES ('19081247556', 'PP');
INSERT INTO Candidato
VALUES ('75199425951', 'MDB');
INSERT INTO Candidato
VALUES ('42713638902', 'PTB');
INSERT INTO Candidato
VALUES ('12425285473', 'MDB');
INSERT INTO Candidato
VALUES ('28833782835', 'PP');
INSERT INTO Candidato
VALUES ('79711277945', 'PP');
INSERT INTO Candidato
VALUES ('98803486214', 'MDB');
INSERT INTO Candidato
VALUES ('34702133666', 'PP');
INSERT INTO Candidato
VALUES ('64671861850', 'MDB');
INSERT INTO Candidato
VALUES ('87222931571', 'PP');
INSERT INTO Candidato
VALUES ('61831559098', 'PDT');
INSERT INTO Candidato
VALUES ('56224074342', 'PSDB');
INSERT INTO Candidato
VALUES ('50291192873', 'PT');
INSERT INTO Candidato
VALUES ('91448831355', 'PSDB');
INSERT INTO Candidato
VALUES ('72920575889', 'PDT');
INSERT INTO Candidato
VALUES ('12044297421', 'PT');
INSERT INTO Candidato
VALUES ('33932909250', 'PP');
INSERT INTO Candidato
VALUES ('41583542709', 'PTB');
INSERT INTO Candidato
VALUES ('68038124940', 'PTB');
INSERT INTO Candidato
VALUES ('82078275873', 'PP');
INSERT INTO Candidato
VALUES ('30228957973', 'PP');
INSERT INTO Candidato
VALUES ('66894887096', 'PDT');
INSERT INTO Candidato
VALUES ('58254329771', 'PDT');
INSERT INTO Candidato
VALUES ('75930518365', 'MDB');
INSERT INTO Candidato
VALUES ('15051145425', 'PP');
INSERT INTO Candidato
VALUES ('99709735615', 'PTB');
INSERT INTO Candidato
VALUES ('34657710711', 'PP');
INSERT INTO Candidato
VALUES ('69293496576', 'PTB');
INSERT INTO Candidato
VALUES ('46841982156', 'PTB');
INSERT INTO Candidato
VALUES ('21124107418', 'PTB');
INSERT INTO Candidato
VALUES ('27397945995', 'PTB');
INSERT INTO Candidato
VALUES ('55711421784', 'PP');
INSERT INTO Candidato
VALUES ('38390440184', 'PT');
INSERT INTO Candidato
VALUES ('32128272987', 'PT');
INSERT INTO Candidato
VALUES ('77704517054', 'PSDB');
INSERT INTO Candidato
VALUES ('43344490984', 'PT');
INSERT INTO Candidato
VALUES ('56639970568', 'PT');
INSERT INTO Candidato
VALUES ('37706179977', 'PTB');
INSERT INTO Candidato
VALUES ('23680543084', 'PTB');
INSERT INTO Candidato
VALUES ('79031850325', 'PT');
INSERT INTO Candidato
VALUES ('48840457284', 'PSDB');
INSERT INTO Candidato
VALUES ('37135223362', 'PDT');
INSERT INTO Candidato
VALUES ('86282287575', 'PT');
INSERT INTO Candidato
VALUES ('82049451954', 'PP');
INSERT INTO Candidato
VALUES ('42961240594', 'PP');
INSERT INTO Candidato
VALUES ('13407645802', 'PT');
INSERT INTO Candidato
VALUES ('50650208310', 'PDT');
INSERT INTO Candidato
VALUES ('63405921850', 'PP');
INSERT INTO Candidato
VALUES ('49292941880', 'MDB');
INSERT INTO Candidato
VALUES ('98657625005', 'PT');
INSERT INTO Candidato
VALUES ('52024004105', 'PTB');
INSERT INTO Candidato
VALUES ('73579154384', 'PTB');
INSERT INTO Candidato
VALUES ('38918265034', 'PP');
INSERT INTO Candidato
VALUES ('13129826323', 'PSDB');
INSERT INTO Candidato
VALUES ('31590171044', 'PT');
INSERT INTO Candidato
VALUES ('56364648623', 'PP');
INSERT INTO Candidato
VALUES ('55317056111', 'PSDB');
INSERT INTO Candidato
VALUES ('86836338876', 'MDB');
INSERT INTO Candidato
VALUES ('54014710634', 'PDT');
INSERT INTO Candidato
VALUES ('34864473633', 'PDT');
INSERT INTO Candidato
VALUES ('60125770117', 'PP');
INSERT INTO Candidato
VALUES ('41397188589', 'PTB');
INSERT INTO Candidato
VALUES ('18723213032', 'PTB');
INSERT INTO Candidato
VALUES ('27661639580', 'PSDB');
INSERT INTO Candidato
VALUES ('80014259815', 'PTB');
INSERT INTO Candidato
VALUES ('69932859244', 'PT');
INSERT INTO Candidato
VALUES ('53198584232', 'PDT');
INSERT INTO Candidato
VALUES ('60173086568', 'PT');
INSERT INTO Candidato
VALUES ('48100007649', 'PP');
INSERT INTO Candidato
VALUES ('75000258060', 'PT');
INSERT INTO Candidato
VALUES ('54936377038', 'MDB');
INSERT INTO Candidato
VALUES ('31128941818', 'PTB');
INSERT INTO Candidato
VALUES ('15407267932', 'PSDB');
INSERT INTO Candidato
VALUES ('32508439864', 'PTB');
INSERT INTO Candidato
VALUES ('83954206069', 'PT');
INSERT INTO Candidato
VALUES ('31890189512', 'PSDB');
INSERT INTO Candidato
VALUES ('48704881865', 'PP');
INSERT INTO Candidato
VALUES ('22994280902', 'PT');
INSERT INTO Candidato
VALUES ('42799690433', 'PTB');
INSERT INTO Candidato
VALUES ('82171370822', 'PTB');
INSERT INTO Candidato
VALUES ('71656160976', 'PSDB');
INSERT INTO Candidato
VALUES ('66493321389', 'MDB');
INSERT INTO Candidato
VALUES ('94240620594', 'PSDB');
INSERT INTO Candidato
VALUES ('76646342640', 'PP');
INSERT INTO Candidato
VALUES ('16329974634', 'PSDB');
INSERT INTO Candidato
VALUES ('48246632281', 'PTB');
INSERT INTO Candidato
VALUES ('43540165110', 'PDT');
INSERT INTO Candidato
VALUES ('86768067248', 'PDT');
INSERT INTO Candidato
VALUES ('48550814816', 'MDB');
INSERT INTO Candidato
VALUES ('11529379235', 'PP');
INSERT INTO Candidato
VALUES ('83675283405', 'PTB');
INSERT INTO Candidato
VALUES ('44307413429', 'MDB');
INSERT INTO Candidato
VALUES ('25330412890', 'PT');
INSERT INTO Candidato
VALUES ('98071054182', 'PT');
INSERT INTO Candidato
VALUES ('79606743648', 'PT');
INSERT INTO Candidato
VALUES ('77363675071', 'PP');
INSERT INTO Candidato
VALUES ('84460796038', 'PTB');
INSERT INTO Candidato
VALUES ('83114106606', 'PSDB');
INSERT INTO Candidato
VALUES ('18236701744', 'PP');
INSERT INTO Candidato
VALUES ('90003691567', 'PTB');
INSERT INTO Candidato
VALUES ('71358629062', 'PSDB');
INSERT INTO Candidato
VALUES ('48776552942', 'PT');
INSERT INTO Candidato
VALUES ('64847709590', 'PDT');
INSERT INTO Candidato
VALUES ('34232794048', 'MDB');
INSERT INTO Candidato
VALUES ('65012076930', 'PT');
INSERT INTO Candidato
VALUES ('88489867446', 'PP');
INSERT INTO Candidato
VALUES ('90606078894', 'PP');
INSERT INTO Candidato
VALUES ('75071605008', 'PT');
INSERT INTO Candidato
VALUES ('77054765247', 'PDT');
INSERT INTO Candidato
VALUES ('26070915332', 'PT');
INSERT INTO Candidato
VALUES ('36079567898', 'PT');
INSERT INTO Candidato
VALUES ('49220664729', 'PT');
INSERT INTO Candidato
VALUES ('34828906285', 'PT');
INSERT INTO Candidato
VALUES ('78893276196', 'PT');
INSERT INTO Candidato
VALUES ('47024384837', 'PTB');
INSERT INTO Candidato
VALUES ('83906174097', 'PP');
INSERT INTO Candidato
VALUES ('48008790058', 'PP');
INSERT INTO Candidato
VALUES ('36101309738', 'MDB');
INSERT INTO Candidato
VALUES ('12213830926', 'PT');
INSERT INTO Candidato
VALUES ('12698386129', 'PT');
INSERT INTO Candidato
VALUES ('95204672040', 'PDT');
INSERT INTO Candidato
VALUES ('85872988284', 'PTB');
INSERT INTO Candidato
VALUES ('72124885278', 'PTB');
INSERT INTO Candidato
VALUES ('13162715234', 'MDB');
INSERT INTO Candidato
VALUES ('73767229476', 'PSDB');
INSERT INTO Candidato
VALUES ('80154288623', 'PP');
INSERT INTO Candidato
VALUES ('12673338970', 'PP');
INSERT INTO Candidato
VALUES ('79079376994', 'PDT');
INSERT INTO Candidato
VALUES ('77608265816', 'PP');
INSERT INTO Candidato
VALUES ('56206870884', 'MDB');
INSERT INTO Candidato
VALUES ('39911369015', 'PT');


-- Insere Cargo
INSERT INTO Cargo
VALUES ('c076db4b-b65c-414d-860d-3ed4773801f7', 'Vereador', 'São Paulo',
        NULL,
        NULL,
        '20');
INSERT INTO Cargo
VALUES ('efff1e60-4a0e-4cfb-9b4b-246c5042b636', 'Prefeito', 'São Paulo',
        NULL,
        NULL,
        '1');
INSERT INTO Cargo
VALUES ('abfea304-7db2-4c4c-a674-b27b912c73c3', 'Deputado Estadual', NULL,
        'SP',
        NULL,
        '10');
INSERT INTO Cargo
VALUES ('6aca1346-2974-4a38-a50e-8137b7583736', 'Deputado Federal', NULL,
        NULL,
        'BR',
        '5');
INSERT INTO Cargo
VALUES ('902d5917-2c07-40e1-9bff-4a4187ed0489', 'Governador', NULL,
        'SP',
        NULL,
        '1');
INSERT INTO Cargo
VALUES ('6fb4b70f-ca27-4ae6-b823-211eccdd650d', 'Presidente', NULL,
        NULL,
        'BR',
        '1');


-- Insere Pleitos
INSERT INTO Pleito
VALUES (2020, 0);
INSERT INTO Pleito
VALUES (2018, 0);
INSERT INTO Pleito
VALUES (2016, 0);
INSERT INTO Pleito
VALUES (2014, 0);
INSERT INTO Pleito
VALUES (2012, 0);
INSERT INTO Pleito
VALUES (2010, 0);


-- Insere Candidaturas
INSERT INTO Candidatura
VALUES ('c15f3b7f-6a3c-4a38-86fc-2b0da6a25303', '23186676069', NULL,
        2014,
        '6aca1346-2974-4a38-a50e-8137b7583736',
        195);
INSERT INTO Candidatura
VALUES ('834d7b66-f257-4121-a4cd-a8fcfbd823f9', '29294251089', '20882765164',
        2012,
        'efff1e60-4a0e-4cfb-9b4b-246c5042b636',
        745);
INSERT INTO Candidatura
VALUES ('7628d803-161f-4cef-95d4-e5c23b53d4b0', '36434444980', '91388181308',
        2016,
        'efff1e60-4a0e-4cfb-9b4b-246c5042b636',
        694);
INSERT INTO Candidatura
VALUES ('3e08ab28-65f8-4935-a018-80f6a20f193c', '90814044619', '49404086042',
        2012,
        '6fb4b70f-ca27-4ae6-b823-211eccdd650d',
        365);
INSERT INTO Candidatura
VALUES ('77be7a80-b283-4dc5-903a-e10ca5b7b63e', '21211647114', NULL,
        2020,
        '6aca1346-2974-4a38-a50e-8137b7583736',
        798);
INSERT INTO Candidatura
VALUES ('f668632d-82b6-4154-b9ee-88a2f41bd654', '71402272270', '41487482076',
        2012,
        'efff1e60-4a0e-4cfb-9b4b-246c5042b636',
        767);
INSERT INTO Candidatura
VALUES ('30096b55-bcab-4a2f-9706-69ce4e0da8c4', '33842867389', NULL,
        2014,
        'abfea304-7db2-4c4c-a674-b27b912c73c3',
        726);
INSERT INTO Candidatura
VALUES ('0d064bb2-e515-4e4f-8cda-0968b1c7dc9e', '24106467796', NULL,
        2010,
        'abfea304-7db2-4c4c-a674-b27b912c73c3',
        643);
INSERT INTO Candidatura
VALUES ('3ff0cbb4-0989-4415-af66-5b36b637c121', '47333944300', NULL,
        2020,
        '6aca1346-2974-4a38-a50e-8137b7583736',
        918);
INSERT INTO Candidatura
VALUES ('a6700843-18c8-4ac6-b877-5d833d457089', '89382796012', '82639195390',
        2020,
        '6fb4b70f-ca27-4ae6-b823-211eccdd650d',
        287);
INSERT INTO Candidatura
VALUES ('de02054f-4a21-4825-84ea-4b66a9a7a4d2', '65379982653', NULL,
        2020,
        '6aca1346-2974-4a38-a50e-8137b7583736',
        908);
INSERT INTO Candidatura
VALUES ('d6496092-b2c3-4ad8-9801-d51b4471c786', '30518274260', NULL,
        2020,
        'abfea304-7db2-4c4c-a674-b27b912c73c3',
        823);
INSERT INTO Candidatura
VALUES ('e708f69b-0e28-4241-b594-2e5a9a332319', '19264541170', NULL,
        2012,
        'abfea304-7db2-4c4c-a674-b27b912c73c3',
        624);
INSERT INTO Candidatura
VALUES ('c054a236-8b76-4db4-b93e-422895a365f3', '16127951364', '94417993945',
        2014,
        'efff1e60-4a0e-4cfb-9b4b-246c5042b636',
        431);
INSERT INTO Candidatura
VALUES ('06aee079-ee83-4406-afb4-c8d28f6453d2', '92201869981', NULL,
        2020,
        'abfea304-7db2-4c4c-a674-b27b912c73c3',
        400);
INSERT INTO Candidatura
VALUES ('baa6ffa1-fdff-4667-be8e-5cc17770310d', '54967094177', NULL,
        2014,
        'abfea304-7db2-4c4c-a674-b27b912c73c3',
        3);
INSERT INTO Candidatura
VALUES ('a52ac019-a156-430c-97f9-96771e0dd475', '60858012235', '84474516983',
        2018,
        '902d5917-2c07-40e1-9bff-4a4187ed0489',
        408);
INSERT INTO Candidatura
VALUES ('c5c2e08c-9d9f-4e72-9864-a8a2276d6078', '94102552335', NULL,
        2010,
        'abfea304-7db2-4c4c-a674-b27b912c73c3',
        484);
INSERT INTO Candidatura
VALUES ('00e2c96a-69db-44e4-b7c3-d80047dcb047', '39589262660', NULL,
        2014,
        '6aca1346-2974-4a38-a50e-8137b7583736',
        918);
INSERT INTO Candidatura
VALUES ('13087ccb-65e5-4173-b8f6-fb464d3da8c6', '49390348521', NULL,
        2016,
        '6aca1346-2974-4a38-a50e-8137b7583736',
        216);
INSERT INTO Candidatura
VALUES ('c99ccf7c-e434-404c-97c3-af88880cd048', '44186261715', NULL,
        2020,
        'abfea304-7db2-4c4c-a674-b27b912c73c3',
        51);
INSERT INTO Candidatura
VALUES ('1e83a57f-6955-463a-8f94-251ba5e36473', '55121575377', '31459604231',
        2014,
        'efff1e60-4a0e-4cfb-9b4b-246c5042b636',
        428);
INSERT INTO Candidatura
VALUES ('1cc23bc0-6127-4d31-bf48-8b2994059939', '44718786508', '68331766016',
        2014,
        '902d5917-2c07-40e1-9bff-4a4187ed0489',
        973);
INSERT INTO Candidatura
VALUES ('26d7cd0e-608f-4353-a16d-13f92ef78922', '76957148555', NULL,
        2016,
        'c076db4b-b65c-414d-860d-3ed4773801f7',
        893);
INSERT INTO Candidatura
VALUES ('b4e7134f-657a-4d9e-9cbf-6efaadf2065c', '57039100097', '12399218089',
        2018,
        '6fb4b70f-ca27-4ae6-b823-211eccdd650d',
        445);
INSERT INTO Candidatura
VALUES ('8f60eda0-d26f-4e9a-b654-4c26a884957f', '80954469083', '74194578086',
        2016,
        '6fb4b70f-ca27-4ae6-b823-211eccdd650d',
        741);
INSERT INTO Candidatura
VALUES ('b1639525-ccbb-4026-891d-1b63579b9852', '36720092277', NULL,
        2010,
        '6aca1346-2974-4a38-a50e-8137b7583736',
        757);
INSERT INTO Candidatura
VALUES ('da17e508-c960-4011-a1a1-b7998220c6c9', '66035738396', NULL,
        2016,
        'abfea304-7db2-4c4c-a674-b27b912c73c3',
        328);
INSERT INTO Candidatura
VALUES ('dc41b2a9-f13a-4a61-8409-9bdc2396b793', '68666926997', NULL,
        2016,
        '6aca1346-2974-4a38-a50e-8137b7583736',
        798);
INSERT INTO Candidatura
VALUES ('10fe9e1c-ecc0-4c9c-8de8-99b231a516bb', '96782912428', '44674791889',
        2016,
        '6fb4b70f-ca27-4ae6-b823-211eccdd650d',
        286);
INSERT INTO Candidatura
VALUES ('8925189d-a9f3-4955-965d-c9a4748abba3', '57704504102', '31800616828',
        2012,
        'efff1e60-4a0e-4cfb-9b4b-246c5042b636',
        661);
INSERT INTO Candidatura
VALUES ('e4d29b3d-9dd3-43a5-8762-c59921c65425', '81479468415', '40710145486',
        2012,
        'efff1e60-4a0e-4cfb-9b4b-246c5042b636',
        166);
INSERT INTO Candidatura
VALUES ('e58fc962-e25c-4032-9934-6e09c10fac93', '39573748449', NULL,
        2018,
        '6aca1346-2974-4a38-a50e-8137b7583736',
        764);
INSERT INTO Candidatura
VALUES ('3d838daf-b50f-434d-8a4d-733ac960fc56', '63900773341', NULL,
        2020,
        '6aca1346-2974-4a38-a50e-8137b7583736',
        688);
INSERT INTO Candidatura
VALUES ('97516f6f-4280-46f7-aad0-363a36766cb1', '11269307890', '91566400225',
        2018,
        '902d5917-2c07-40e1-9bff-4a4187ed0489',
        925);
INSERT INTO Candidatura
VALUES ('4104cee5-6e88-414a-8bd7-ec6cd7d6ae62', '37841710573', '93598506252',
        2010,
        '6fb4b70f-ca27-4ae6-b823-211eccdd650d',
        993);
INSERT INTO Candidatura
VALUES ('7dfcdf5d-e129-4c5f-b9bc-f9e7d6f0efc3', '87642632594', '71272484597',
        2014,
        'efff1e60-4a0e-4cfb-9b4b-246c5042b636',
        608);
INSERT INTO Candidatura
VALUES ('29ec0277-6754-445c-a254-3b7c631dbaf8', '34047008347', NULL,
        2012,
        '6aca1346-2974-4a38-a50e-8137b7583736',
        619);
INSERT INTO Candidatura
VALUES ('fbc0eb50-4019-4da5-b2d7-161c9293706e', '97614736857', NULL,
        2018,
        '6aca1346-2974-4a38-a50e-8137b7583736',
        748);
INSERT INTO Candidatura
VALUES ('2d1a7c81-9a9b-4b00-bc36-caca205252fb', '12347521192', '69930587140',
        2016,
        'efff1e60-4a0e-4cfb-9b4b-246c5042b636',
        675);
INSERT INTO Candidatura
VALUES ('00c6b060-9bac-4452-b127-39420d4a97f9', '49351430758', NULL,
        2012,
        'c076db4b-b65c-414d-860d-3ed4773801f7',
        213);
INSERT INTO Candidatura
VALUES ('e13f090b-a488-4212-b502-e490f8b5d601', '38956106749', NULL,
        2020,
        'abfea304-7db2-4c4c-a674-b27b912c73c3',
        672);
INSERT INTO Candidatura
VALUES ('c4066e8c-26ae-4312-abc7-7aed8b2cbe26', '98747927837', NULL,
        2010,
        '6aca1346-2974-4a38-a50e-8137b7583736',
        739);
INSERT INTO Candidatura
VALUES ('407a7b86-c86c-444b-8034-af7d0d3c8405', '11703440623', '12062577367',
        2010,
        '6fb4b70f-ca27-4ae6-b823-211eccdd650d',
        382);
INSERT INTO Candidatura
VALUES ('fe9d85af-1f99-40ca-a63c-66675ff798cf', '20656491559', '87970591781',
        2018,
        '6fb4b70f-ca27-4ae6-b823-211eccdd650d',
        920);
INSERT INTO Candidatura
VALUES ('b4f08c42-776a-4e29-b240-bb90c3b21997', '89264845682', NULL,
        2016,
        'c076db4b-b65c-414d-860d-3ed4773801f7',
        975);
INSERT INTO Candidatura
VALUES ('c2eebe34-da75-4300-993b-4e3e9b40f92e', '92312295855', '95605694998',
        2016,
        'efff1e60-4a0e-4cfb-9b4b-246c5042b636',
        976);
INSERT INTO Candidatura
VALUES ('bab4f237-a893-4768-9c9f-78e299c73395', '38939672771', NULL,
        2012,
        'abfea304-7db2-4c4c-a674-b27b912c73c3',
        66);
INSERT INTO Candidatura
VALUES ('c8232346-5632-4690-9368-619c8343fbab', '32608546945', NULL,
        2012,
        'c076db4b-b65c-414d-860d-3ed4773801f7',
        753);
INSERT INTO Candidatura
VALUES ('b227c169-b231-4158-914e-d558c2c7055e', '22103242517', NULL,
        2010,
        'abfea304-7db2-4c4c-a674-b27b912c73c3',
        630);
INSERT INTO Candidatura
VALUES ('2a1d97af-87de-4086-aee7-b53ba7cfdcaa', '37415883594', '44884157183',
        2010,
        '902d5917-2c07-40e1-9bff-4a4187ed0489',
        378);
INSERT INTO Candidatura
VALUES ('01e85bac-4bed-4b58-b51b-ae77e95cac0d', '37581900996', '83461462480',
        2014,
        'efff1e60-4a0e-4cfb-9b4b-246c5042b636',
        253);
INSERT INTO Candidatura
VALUES ('69384f39-1b94-4f0b-9404-cc6f99209734', '55752608675', '47530116646',
        2014,
        'efff1e60-4a0e-4cfb-9b4b-246c5042b636',
        991);
INSERT INTO Candidatura
VALUES ('0bcc2544-fadd-4149-b422-0fcdd4ca64a9', '16469240479', NULL,
        2012,
        '6aca1346-2974-4a38-a50e-8137b7583736',
        703);
INSERT INTO Candidatura
VALUES ('ed043e6c-79ea-478d-942c-29a98b61e12a', '67562512347', NULL,
        2020,
        'abfea304-7db2-4c4c-a674-b27b912c73c3',
        99);
INSERT INTO Candidatura
VALUES ('e121dbca-5d41-4a89-ae81-3c4391f14eb0', '97079823934', NULL,
        2012,
        '6aca1346-2974-4a38-a50e-8137b7583736',
        622);
INSERT INTO Candidatura
VALUES ('4cc55a67-f714-47dd-8810-6f6ef7f0736f', '78782798836', '31276211123',
        2010,
        'efff1e60-4a0e-4cfb-9b4b-246c5042b636',
        374);
INSERT INTO Candidatura
VALUES ('9be2caf7-7ea8-43b8-bec1-91a4887531dd', '74122189518', '52019781784',
        2016,
        'efff1e60-4a0e-4cfb-9b4b-246c5042b636',
        545);
INSERT INTO Candidatura
VALUES ('0b5f8599-e968-421d-ae9d-11d271b8e9b8', '77571850281', NULL,
        2010,
        '6aca1346-2974-4a38-a50e-8137b7583736',
        921);
INSERT INTO Candidatura
VALUES ('825894a0-06af-4457-9668-c90521babf6f', '20593875704', '49141727066',
        2020,
        '902d5917-2c07-40e1-9bff-4a4187ed0489',
        713);
INSERT INTO Candidatura
VALUES ('6152b778-ea38-457f-9c17-d6e05506e4e8', '56399587204', '29694294098',
        2018,
        '6fb4b70f-ca27-4ae6-b823-211eccdd650d',
        151);
INSERT INTO Candidatura
VALUES ('4f6ea709-15e1-4e8f-ad4e-040c31a5d1ab', '29509833429', '48220131113',
        2010,
        '902d5917-2c07-40e1-9bff-4a4187ed0489',
        638);
INSERT INTO Candidatura
VALUES ('8658829e-b5e0-4fe1-b3b2-73a5100a152f', '76696378767', NULL,
        2018,
        '6aca1346-2974-4a38-a50e-8137b7583736',
        92);
INSERT INTO Candidatura
VALUES ('717cc3cd-9cf7-49b5-add8-f5561d3fe52c', '24302034655', '86534657040',
        2010,
        '902d5917-2c07-40e1-9bff-4a4187ed0489',
        453);
INSERT INTO Candidatura
VALUES ('37dd2db7-4c7e-43e7-a839-dd1c2f97f223', '48273120142', '87764965905',
        2016,
        'efff1e60-4a0e-4cfb-9b4b-246c5042b636',
        124);
INSERT INTO Candidatura
VALUES ('cc469a97-299b-4533-8b63-876818910bcb', '88463596005', NULL,
        2016,
        '6aca1346-2974-4a38-a50e-8137b7583736',
        527);
INSERT INTO Candidatura
VALUES ('9cf8572c-85f7-4df4-b60e-2a8c42cf1282', '68038586615', '82870189829',
        2018,
        '6fb4b70f-ca27-4ae6-b823-211eccdd650d',
        715);
INSERT INTO Candidatura
VALUES ('60b45d54-2935-40dd-a13b-56e12e07ef0c', '81137500617', NULL,
        2018,
        'abfea304-7db2-4c4c-a674-b27b912c73c3',
        569);
INSERT INTO Candidatura
VALUES ('4e120075-6bfd-4248-83ce-aa87193daf7e', '79479726215', '29875680117',
        2010,
        '902d5917-2c07-40e1-9bff-4a4187ed0489',
        897);
INSERT INTO Candidatura
VALUES ('272669e7-7493-418f-a622-00d75748f6f2', '11475470627', '43586174864',
        2014,
        'efff1e60-4a0e-4cfb-9b4b-246c5042b636',
        336);
INSERT INTO Candidatura
VALUES ('4c9d10ff-4f48-4dce-bc4b-98143d89d622', '16082053717', '37254095533',
        2010,
        '6fb4b70f-ca27-4ae6-b823-211eccdd650d',
        12);
INSERT INTO Candidatura
VALUES ('140c00c6-9c63-4078-8235-49de5c138138', '94763610071', NULL,
        2014,
        'c076db4b-b65c-414d-860d-3ed4773801f7',
        708);
INSERT INTO Candidatura
VALUES ('02bd4093-3e1a-497b-b21e-59192ffc29b0', '70077948186', '42174338325',
        2010,
        '902d5917-2c07-40e1-9bff-4a4187ed0489',
        271);
INSERT INTO Candidatura
VALUES ('6d4218ee-218f-4db6-bb5e-d485e731c55d', '45491204094', NULL,
        2010,
        '6aca1346-2974-4a38-a50e-8137b7583736',
        729);
INSERT INTO Candidatura
VALUES ('bccd20c5-9887-43d0-ab8f-9a99678f6bf5', '80229327632', NULL,
        2018,
        'abfea304-7db2-4c4c-a674-b27b912c73c3',
        13);
INSERT INTO Candidatura
VALUES ('91a9896d-0635-438b-a21e-16b0a19d97cf', '17353439859', '76377020021',
        2020,
        '902d5917-2c07-40e1-9bff-4a4187ed0489',
        294);
INSERT INTO Candidatura
VALUES ('3b3d1e33-a62b-431c-a761-c24e8cf602e3', '78031077992', '59691281320',
        2016,
        '6fb4b70f-ca27-4ae6-b823-211eccdd650d',
        882);
INSERT INTO Candidatura
VALUES ('65283eea-6dc8-4a2d-91fb-d5973c83c8fa', '79691960571', NULL,
        2012,
        '6aca1346-2974-4a38-a50e-8137b7583736',
        847);
INSERT INTO Candidatura
VALUES ('86c5373f-a37b-4d09-97c7-0a0da4c6ae82', '72560434259', '60893714134',
        2014,
        '902d5917-2c07-40e1-9bff-4a4187ed0489',
        149);
INSERT INTO Candidatura
VALUES ('b5ab827d-3c64-49f5-bcaf-987f4d7dfba4', '72597053705', '19081247556',
        2010,
        '6fb4b70f-ca27-4ae6-b823-211eccdd650d',
        636);
INSERT INTO Candidatura
VALUES ('a82a1bf7-56ef-4b0c-bf03-c9d87ed0cf1f', '36892929635', NULL,
        2016,
        'c076db4b-b65c-414d-860d-3ed4773801f7',
        871);
INSERT INTO Candidatura
VALUES ('ac8340e0-f62e-47cf-a3cd-7194a6afa5bf', '19436460018', '75199425951',
        2020,
        '902d5917-2c07-40e1-9bff-4a4187ed0489',
        830);
INSERT INTO Candidatura
VALUES ('f33f011e-3f4c-4920-a003-4987a4c22e7d', '41320017329', NULL,
        2018,
        'c076db4b-b65c-414d-860d-3ed4773801f7',
        652);
INSERT INTO Candidatura
VALUES ('05970f02-d4cc-44ff-98d1-cc80ebb383ea', '60652495953', '42713638902',
        2016,
        '6fb4b70f-ca27-4ae6-b823-211eccdd650d',
        264);
INSERT INTO Candidatura
VALUES ('ba120830-08ca-4719-b56a-ab77a191bb5b', '74808992438', '12425285473',
        2010,
        'efff1e60-4a0e-4cfb-9b4b-246c5042b636',
        398);
INSERT INTO Candidatura
VALUES ('6df4504e-b88d-4f7f-b79e-b9e663c15cbf', '90560006066', '28833782835',
        2012,
        '902d5917-2c07-40e1-9bff-4a4187ed0489',
        235);
INSERT INTO Candidatura
VALUES ('2c8a7bda-c9e1-4ba1-a140-1fef4af0900b', '66159643984', NULL,
        2018,
        'abfea304-7db2-4c4c-a674-b27b912c73c3',
        999);
INSERT INTO Candidatura
VALUES ('d1b0dede-99f8-4c51-b9de-ef7de6c0f223', '98907837094', NULL,
        2020,
        'abfea304-7db2-4c4c-a674-b27b912c73c3',
        593);
INSERT INTO Candidatura
VALUES ('4a48f41b-eae3-43c0-aa7c-7f996afea59f', '33855974653', NULL,
        2014,
        'c076db4b-b65c-414d-860d-3ed4773801f7',
        525);
INSERT INTO Candidatura
VALUES ('7929ba27-8368-4c77-97b3-face01bbe78b', '74363441457', '79711277945',
        2018,
        '902d5917-2c07-40e1-9bff-4a4187ed0489',
        414);
INSERT INTO Candidatura
VALUES ('ee818b31-872c-4349-84bd-096dc91dbf06', '32739312681', NULL,
        2016,
        'abfea304-7db2-4c4c-a674-b27b912c73c3',
        443);
INSERT INTO Candidatura
VALUES ('951773bf-8527-4ca8-9f02-167dddd5df64', '93519565530', '98803486214',
        2018,
        'efff1e60-4a0e-4cfb-9b4b-246c5042b636',
        617);
INSERT INTO Candidatura
VALUES ('c9976831-44c2-4c3e-916b-499f7c29bc4f', '44038899224', NULL,
        2012,
        '6aca1346-2974-4a38-a50e-8137b7583736',
        401);
INSERT INTO Candidatura
VALUES ('bef7c04c-bc0b-4136-8c5f-fdf8d2652ac6', '98591816106', NULL,
        2012,
        '6aca1346-2974-4a38-a50e-8137b7583736',
        432);
INSERT INTO Candidatura
VALUES ('cb951489-cf01-4402-98d4-c2020f79e862', '98239704843', NULL,
        2014,
        'abfea304-7db2-4c4c-a674-b27b912c73c3',
        547);
INSERT INTO Candidatura
VALUES ('b410004b-bf75-428e-9353-ba2a9a05691d', '47442891250', '34702133666',
        2018,
        '902d5917-2c07-40e1-9bff-4a4187ed0489',
        385);
INSERT INTO Candidatura
VALUES ('f5f7d4d0-5075-4714-85ca-97452ffd18b4', '18092176485', NULL,
        2012,
        'abfea304-7db2-4c4c-a674-b27b912c73c3',
        702);
INSERT INTO Candidatura
VALUES ('a2e4696e-5819-49da-b959-cf16d97794c5', '50602269105', NULL,
        2012,
        'c076db4b-b65c-414d-860d-3ed4773801f7',
        767);
INSERT INTO Candidatura
VALUES ('a155b5a9-8c5e-47dd-8e8b-04515039d10a', '73590556099', NULL,
        2012,
        'c076db4b-b65c-414d-860d-3ed4773801f7',
        622);
INSERT INTO Candidatura
VALUES ('0a6cf2bd-3b84-4f47-befc-df22efaee320', '68837744630', NULL,
        2012,
        'c076db4b-b65c-414d-860d-3ed4773801f7',
        379);
INSERT INTO Candidatura
VALUES ('fddbbf6c-f47a-477b-aac3-90d75a86c800', '60751450103', '64671861850',
        2018,
        '6fb4b70f-ca27-4ae6-b823-211eccdd650d',
        258);
INSERT INTO Candidatura
VALUES ('827d9967-cc68-4272-9daf-14e8089f9e76', '15441784567', NULL,
        2012,
        'c076db4b-b65c-414d-860d-3ed4773801f7',
        923);
INSERT INTO Candidatura
VALUES ('849a12e4-0864-437b-aa52-39cf2d851546', '35165164980', NULL,
        2016,
        '6aca1346-2974-4a38-a50e-8137b7583736',
        184);
INSERT INTO Candidatura
VALUES ('ff0760e5-3062-4770-a12a-b1c53a68c7de', '86604477623', '87222931571',
        2016,
        'efff1e60-4a0e-4cfb-9b4b-246c5042b636',
        103);
INSERT INTO Candidatura
VALUES ('6afe4c75-3af4-4eeb-b19b-6cdb1ae9e8dd', '44529969659', '61831559098',
        2016,
        '6fb4b70f-ca27-4ae6-b823-211eccdd650d',
        206);
INSERT INTO Candidatura
VALUES ('5e762276-5826-4899-becd-700a93e88cdd', '22431804153', '56224074342',
        2010,
        '6fb4b70f-ca27-4ae6-b823-211eccdd650d',
        269);
INSERT INTO Candidatura
VALUES ('3145c110-c210-41fc-b3bc-c938e38cbe8d', '40780232739', NULL,
        2020,
        'c076db4b-b65c-414d-860d-3ed4773801f7',
        881);
INSERT INTO Candidatura
VALUES ('cf214043-fccd-4982-ac53-ce54507a5e18', '55663887299', NULL,
        2016,
        'abfea304-7db2-4c4c-a674-b27b912c73c3',
        718);
INSERT INTO Candidatura
VALUES ('aad45ed3-cecf-412a-895b-17594e59bba3', '82486186116', NULL,
        2010,
        'abfea304-7db2-4c4c-a674-b27b912c73c3',
        117);
INSERT INTO Candidatura
VALUES ('acf39c8a-56ca-4eba-a415-d0a4e4ad929a', '10292860679', '50291192873',
        2012,
        '6fb4b70f-ca27-4ae6-b823-211eccdd650d',
        82);
INSERT INTO Candidatura
VALUES ('4d1e882e-9262-4038-a0ed-61c7d8b2b650', '99513478213', '91448831355',
        2010,
        'efff1e60-4a0e-4cfb-9b4b-246c5042b636',
        934);
INSERT INTO Candidatura
VALUES ('bc1b7865-785d-4ff7-bf9c-316005f2a822', '41136322179', '72920575889',
        2014,
        '6fb4b70f-ca27-4ae6-b823-211eccdd650d',
        708);
INSERT INTO Candidatura
VALUES ('61679c1f-09c1-4aa1-8521-0f83b10c8a55', '25336353376', '12044297421',
        2018,
        '6fb4b70f-ca27-4ae6-b823-211eccdd650d',
        951);
INSERT INTO Candidatura
VALUES ('b9d90922-bc31-49f7-86c0-0e98c4660856', '61669403030', '33932909250',
        2018,
        '6fb4b70f-ca27-4ae6-b823-211eccdd650d',
        204);
INSERT INTO Candidatura
VALUES ('294c5d0e-6eac-4fdf-97ac-afb6002d9a7a', '40851067951', '41583542709',
        2020,
        '6fb4b70f-ca27-4ae6-b823-211eccdd650d',
        329);
INSERT INTO Candidatura
VALUES ('f348d10b-3674-4cb0-b490-3c2123b0ee03', '32622446236', '68038124940',
        2014,
        '6fb4b70f-ca27-4ae6-b823-211eccdd650d',
        612);
INSERT INTO Candidatura
VALUES ('334ed8ed-7f23-4507-a7c0-5f4e0ad81cf9', '34996525992', NULL,
        2018,
        'c076db4b-b65c-414d-860d-3ed4773801f7',
        11);
INSERT INTO Candidatura
VALUES ('40181dc0-82fc-4ba0-8811-13410312a1f8', '27500320235', NULL,
        2020,
        'abfea304-7db2-4c4c-a674-b27b912c73c3',
        471);
INSERT INTO Candidatura
VALUES ('9ebb0892-f116-47c9-8c3c-79621186e93e', '11253295710', NULL,
        2020,
        'c076db4b-b65c-414d-860d-3ed4773801f7',
        593);
INSERT INTO Candidatura
VALUES ('2a9a4267-8f54-4481-b5af-30db4871670e', '56845003822', '82078275873',
        2010,
        'efff1e60-4a0e-4cfb-9b4b-246c5042b636',
        178);
INSERT INTO Candidatura
VALUES ('c0a3ee4d-fc71-47b3-b5dd-d536932c691a', '16470102223', NULL,
        2012,
        'abfea304-7db2-4c4c-a674-b27b912c73c3',
        369);
INSERT INTO Candidatura
VALUES ('58b95725-63d5-4d4a-96da-cf738741720e', '73315387605', NULL,
        2016,
        'c076db4b-b65c-414d-860d-3ed4773801f7',
        511);
INSERT INTO Candidatura
VALUES ('41611392-62a0-424e-b60a-a7ac2594f571', '80291202422', '30228957973',
        2018,
        '902d5917-2c07-40e1-9bff-4a4187ed0489',
        650);
INSERT INTO Candidatura
VALUES ('7f5afcff-fe6f-4e18-bab8-94c924ccdbef', '50501488286', '66894887096',
        2018,
        '902d5917-2c07-40e1-9bff-4a4187ed0489',
        877);
INSERT INTO Candidatura
VALUES ('3498d08b-67bf-46be-afcf-fa9f85759174', '67123855608', NULL,
        2010,
        'abfea304-7db2-4c4c-a674-b27b912c73c3',
        491);
INSERT INTO Candidatura
VALUES ('c6f8606f-b17c-4444-abf9-158564552e8d', '45083095934', NULL,
        2012,
        'abfea304-7db2-4c4c-a674-b27b912c73c3',
        192);
INSERT INTO Candidatura
VALUES ('a1a4ffab-a551-40fc-811f-02470eaf8aa8', '14724061477', '58254329771',
        2010,
        'efff1e60-4a0e-4cfb-9b4b-246c5042b636',
        243);
INSERT INTO Candidatura
VALUES ('a122384e-8cce-4619-8f76-d1441f1d0cea', '50428395869', '75930518365',
        2010,
        '6fb4b70f-ca27-4ae6-b823-211eccdd650d',
        761);
INSERT INTO Candidatura
VALUES ('4096297d-83d9-4f40-afae-5dd326709dfd', '16521542130', NULL,
        2016,
        'c076db4b-b65c-414d-860d-3ed4773801f7',
        859);
INSERT INTO Candidatura
VALUES ('87a3c68c-40e5-432d-9a37-42cfe2a6a110', '41319743199', '15051145425',
        2016,
        '6fb4b70f-ca27-4ae6-b823-211eccdd650d',
        494);
INSERT INTO Candidatura
VALUES ('f6f918f9-2f4d-4cfd-bd7a-a0205a7fcad4', '18004457291', '99709735615',
        2012,
        '6fb4b70f-ca27-4ae6-b823-211eccdd650d',
        94);
INSERT INTO Candidatura
VALUES ('bbb569b0-2bbc-40c4-ac37-50f7794f4d21', '61657774816', NULL,
        2012,
        'c076db4b-b65c-414d-860d-3ed4773801f7',
        813);
INSERT INTO Candidatura
VALUES ('be66fcc2-9a7a-4994-97db-d31b136abbf4', '10737233394', '34657710711',
        2020,
        '902d5917-2c07-40e1-9bff-4a4187ed0489',
        858);
INSERT INTO Candidatura
VALUES ('1c2dc5b3-6710-4e04-8150-4d4c27c30e79', '21487723933', NULL,
        2020,
        'abfea304-7db2-4c4c-a674-b27b912c73c3',
        81);
INSERT INTO Candidatura
VALUES ('f7dc20dd-2169-4673-a3a5-14a98b75c022', '53108889381', NULL,
        2018,
        '6aca1346-2974-4a38-a50e-8137b7583736',
        874);
INSERT INTO Candidatura
VALUES ('e92b3d56-bd71-40cb-9cd7-e8e7296b6ae7', '38589444733', '69293496576',
        2018,
        'efff1e60-4a0e-4cfb-9b4b-246c5042b636',
        59);
INSERT INTO Candidatura
VALUES ('dec0783c-9b85-46d6-854a-23789fbc5fac', '83880074904', '46841982156',
        2018,
        '6fb4b70f-ca27-4ae6-b823-211eccdd650d',
        727);
INSERT INTO Candidatura
VALUES ('14e004da-446a-46a4-8887-806ac81ebcad', '21879325024', '21124107418',
        2020,
        '6fb4b70f-ca27-4ae6-b823-211eccdd650d',
        974);
INSERT INTO Candidatura
VALUES ('71f474f3-cf89-4e8a-8751-430c3c8f627c', '45065363431', NULL,
        2010,
        'c076db4b-b65c-414d-860d-3ed4773801f7',
        861);
INSERT INTO Candidatura
VALUES ('04cae94e-ec38-4f04-83c6-90db81370973', '97468617402', '27397945995',
        2014,
        '902d5917-2c07-40e1-9bff-4a4187ed0489',
        179);
INSERT INTO Candidatura
VALUES ('3171cb48-4c1a-4fa0-87d9-c1469131ae2c', '12061152968', NULL,
        2012,
        'c076db4b-b65c-414d-860d-3ed4773801f7',
        937);
INSERT INTO Candidatura
VALUES ('4f1c68f4-1098-4154-a183-3bf32fb46b02', '76882689699', '55711421784',
        2020,
        'efff1e60-4a0e-4cfb-9b4b-246c5042b636',
        668);
INSERT INTO Candidatura
VALUES ('1ddf162a-5faa-45be-bb45-17555b4df092', '65408776691', NULL,
        2018,
        '6aca1346-2974-4a38-a50e-8137b7583736',
        98);
INSERT INTO Candidatura
VALUES ('4b497262-94b2-4cdd-910e-4b989095199b', '44331545557', '38390440184',
        2010,
        '6fb4b70f-ca27-4ae6-b823-211eccdd650d',
        955);
INSERT INTO Candidatura
VALUES ('917d9d62-6b92-4eb6-bcb4-e184642379df', '83129861042', '32128272987',
        2016,
        'efff1e60-4a0e-4cfb-9b4b-246c5042b636',
        866);
INSERT INTO Candidatura
VALUES ('f0968330-20b4-4cca-939a-c514fe8ba825', '85275710606', '77704517054',
        2014,
        '6fb4b70f-ca27-4ae6-b823-211eccdd650d',
        330);
INSERT INTO Candidatura
VALUES ('7e2799df-9577-46f6-b63a-dfccd5c89565', '98618554964', '43344490984',
        2012,
        '6fb4b70f-ca27-4ae6-b823-211eccdd650d',
        375);
INSERT INTO Candidatura
VALUES ('463d455d-d0de-4ba0-99ba-5f03b5f91e41', '58745565121', '56639970568',
        2018,
        'efff1e60-4a0e-4cfb-9b4b-246c5042b636',
        286);
INSERT INTO Candidatura
VALUES ('0ac6d652-946d-45fd-bc4f-b1e83551cac3', '68820670107', NULL,
        2014,
        'abfea304-7db2-4c4c-a674-b27b912c73c3',
        15);
INSERT INTO Candidatura
VALUES ('0b9629e2-bc23-4389-b2da-21e3ff418a56', '23647714878', NULL,
        2010,
        'c076db4b-b65c-414d-860d-3ed4773801f7',
        596);
INSERT INTO Candidatura
VALUES ('2ba7d78d-cec0-46d2-98cd-da240cd18f4a', '52510659939', NULL,
        2012,
        'abfea304-7db2-4c4c-a674-b27b912c73c3',
        195);
INSERT INTO Candidatura
VALUES ('27ef99af-4a54-433e-91ed-96b6ee7b2b06', '94048417352', '37706179977',
        2012,
        '902d5917-2c07-40e1-9bff-4a4187ed0489',
        972);
INSERT INTO Candidatura
VALUES ('42e009cf-1cee-44e3-b3a4-e48e6d9d4aea', '68540927693', '23680543084',
        2012,
        'efff1e60-4a0e-4cfb-9b4b-246c5042b636',
        281);
INSERT INTO Candidatura
VALUES ('ca3511e9-bebf-4d9b-a092-9d54323026c8', '45014148892', '79031850325',
        2020,
        'efff1e60-4a0e-4cfb-9b4b-246c5042b636',
        149);
INSERT INTO Candidatura
VALUES ('37cad15d-6a34-4dbb-aa0a-71e82adca8b8', '54183079097', NULL,
        2014,
        'c076db4b-b65c-414d-860d-3ed4773801f7',
        30);
INSERT INTO Candidatura
VALUES ('d057beff-cfa3-42fb-960c-0bd71b5f670e', '76707281675', NULL,
        2020,
        'c076db4b-b65c-414d-860d-3ed4773801f7',
        586);
INSERT INTO Candidatura
VALUES ('eae7a913-2b84-472d-bc97-3616b1fdb232', '45456711661', NULL,
        2014,
        'c076db4b-b65c-414d-860d-3ed4773801f7',
        637);
INSERT INTO Candidatura
VALUES ('4a83cbd8-872c-4aaf-89ab-c4082e9a86d3', '45923760337', NULL,
        2010,
        'c076db4b-b65c-414d-860d-3ed4773801f7',
        596);
INSERT INTO Candidatura
VALUES ('b0d7d877-19ff-4f8e-8d81-be232c6145f7', '41465124920', '48840457284',
        2012,
        'efff1e60-4a0e-4cfb-9b4b-246c5042b636',
        220);
INSERT INTO Candidatura
VALUES ('de9b4ed4-bee0-4223-b27f-9d7ff9b22d34', '41139387378', '37135223362',
        2010,
        '6fb4b70f-ca27-4ae6-b823-211eccdd650d',
        504);
INSERT INTO Candidatura
VALUES ('52baf9c0-a84a-465a-a289-b0ba450d1d21', '15691747337', '86282287575',
        2020,
        'efff1e60-4a0e-4cfb-9b4b-246c5042b636',
        233);
INSERT INTO Candidatura
VALUES ('0e679ddc-8e10-4c15-bfb5-a187d79c171d', '56009768713', '82049451954',
        2010,
        '902d5917-2c07-40e1-9bff-4a4187ed0489',
        227);
INSERT INTO Candidatura
VALUES ('ecba16c3-3457-4f06-be22-4af156f4cefe', '70844363323', '42961240594',
        2020,
        'efff1e60-4a0e-4cfb-9b4b-246c5042b636',
        604);
INSERT INTO Candidatura
VALUES ('fadd0750-3074-44c8-8dc6-5142a6fbcd9a', '85526398515', '13407645802',
        2010,
        'efff1e60-4a0e-4cfb-9b4b-246c5042b636',
        301);
INSERT INTO Candidatura
VALUES ('6ee18e5b-3789-4200-a321-6b7739d4dc4d', '21481214086', NULL,
        2014,
        'abfea304-7db2-4c4c-a674-b27b912c73c3',
        393);
INSERT INTO Candidatura
VALUES ('8dcc3d94-22e4-449b-b282-526679f164e1', '43331410249', NULL,
        2010,
        '6aca1346-2974-4a38-a50e-8137b7583736',
        33);
INSERT INTO Candidatura
VALUES ('39c80670-e490-4bfe-b325-baa2f10e1b6d', '92776450554', NULL,
        2018,
        'c076db4b-b65c-414d-860d-3ed4773801f7',
        993);
INSERT INTO Candidatura
VALUES ('39d1f0f1-5459-4a78-932a-867cc5b5878c', '47314490594', NULL,
        2010,
        '6aca1346-2974-4a38-a50e-8137b7583736',
        491);
INSERT INTO Candidatura
VALUES ('b7fbde9e-0ee7-4dde-8f11-d504a4ccb100', '44503644322', '50650208310',
        2020,
        '902d5917-2c07-40e1-9bff-4a4187ed0489',
        320);
INSERT INTO Candidatura
VALUES ('de9f0e95-beac-4fd8-aa8c-ed28b4acdd75', '22932819214', '63405921850',
        2012,
        '902d5917-2c07-40e1-9bff-4a4187ed0489',
        122);
INSERT INTO Candidatura
VALUES ('6c09c4e0-f482-4559-9193-395ec5fe628f', '57039934452', '49292941880',
        2012,
        'efff1e60-4a0e-4cfb-9b4b-246c5042b636',
        950);
INSERT INTO Candidatura
VALUES ('48cad3af-4499-43ce-bc98-c632486bdc3b', '79646575415', NULL,
        2018,
        '6aca1346-2974-4a38-a50e-8137b7583736',
        724);
INSERT INTO Candidatura
VALUES ('ed676738-4ee2-4a94-b49e-3ea0d057cc15', '21425575076', '98657625005',
        2020,
        'efff1e60-4a0e-4cfb-9b4b-246c5042b636',
        300);
INSERT INTO Candidatura
VALUES ('d0db5686-16b8-46c9-84ba-3503ade39d5c', '32125016890', NULL,
        2010,
        '6aca1346-2974-4a38-a50e-8137b7583736',
        340);
INSERT INTO Candidatura
VALUES ('5194f3ac-0f30-41d1-889c-fea9da91f253', '51697040249', '52024004105',
        2018,
        '6fb4b70f-ca27-4ae6-b823-211eccdd650d',
        793);
INSERT INTO Candidatura
VALUES ('5da46041-3847-40fa-a3bd-e29a48c3b61e', '90985128022', '73579154384',
        2014,
        'efff1e60-4a0e-4cfb-9b4b-246c5042b636',
        149);
INSERT INTO Candidatura
VALUES ('1858d9d7-d178-4a46-acc1-89e0757c6afd', '34757250568', NULL,
        2012,
        '6aca1346-2974-4a38-a50e-8137b7583736',
        378);
INSERT INTO Candidatura
VALUES ('0a95979e-c07d-4277-bc04-7bacaede0ad3', '44718153213', NULL,
        2016,
        '6aca1346-2974-4a38-a50e-8137b7583736',
        868);
INSERT INTO Candidatura
VALUES ('9cc9ac5b-b66a-4b29-858e-005244337c95', '73656000972', '38918265034',
        2010,
        '902d5917-2c07-40e1-9bff-4a4187ed0489',
        164);
INSERT INTO Candidatura
VALUES ('eee3cebd-00a3-474d-8d5f-d64a5121f2e5', '84774450208', '13129826323',
        2016,
        'efff1e60-4a0e-4cfb-9b4b-246c5042b636',
        1000);
INSERT INTO Candidatura
VALUES ('e6d53dbc-42d5-4631-a0c3-cddf2e8be77b', '28238024273', '31590171044',
        2018,
        '6fb4b70f-ca27-4ae6-b823-211eccdd650d',
        201);
INSERT INTO Candidatura
VALUES ('a3add6b7-5a06-4639-bccf-bf7cad622250', '70319649500', NULL,
        2010,
        '6aca1346-2974-4a38-a50e-8137b7583736',
        492);
INSERT INTO Candidatura
VALUES ('ee0bb945-c8ad-41a2-9c03-fa375b7a5583', '83759686551', '56364648623',
        2012,
        '902d5917-2c07-40e1-9bff-4a4187ed0489',
        799);
INSERT INTO Candidatura
VALUES ('cd786f62-8f1e-45c8-b034-399b1905bdc8', '54206616906', NULL,
        2018,
        '6aca1346-2974-4a38-a50e-8137b7583736',
        640);
INSERT INTO Candidatura
VALUES ('bcc39841-b25f-401b-848e-edd57d826604', '25756717512', NULL,
        2012,
        'abfea304-7db2-4c4c-a674-b27b912c73c3',
        182);
INSERT INTO Candidatura
VALUES ('ff86fb74-6d23-4863-b1a6-493fd936edc6', '14975074331', '55317056111',
        2018,
        'efff1e60-4a0e-4cfb-9b4b-246c5042b636',
        443);
INSERT INTO Candidatura
VALUES ('57cf0583-995e-452c-b883-44d4d2bcce6b', '79293712463', NULL,
        2020,
        'abfea304-7db2-4c4c-a674-b27b912c73c3',
        33);
INSERT INTO Candidatura
VALUES ('6d9e081a-565f-4eee-8992-3bdaa2ed2cf4', '89025817608', NULL,
        2014,
        'abfea304-7db2-4c4c-a674-b27b912c73c3',
        514);
INSERT INTO Candidatura
VALUES ('3642790a-3bc3-4fc1-89f6-3a2de7de616d', '36824277385', '86836338876',
        2014,
        '902d5917-2c07-40e1-9bff-4a4187ed0489',
        814);
INSERT INTO Candidatura
VALUES ('84591eb8-0dd9-4b71-a766-efa0e7f151e8', '98036637124', NULL,
        2018,
        'c076db4b-b65c-414d-860d-3ed4773801f7',
        176);
INSERT INTO Candidatura
VALUES ('8d5d2b88-33da-4a7f-9b4a-1894c54c1fbc', '57979449972', NULL,
        2012,
        'abfea304-7db2-4c4c-a674-b27b912c73c3',
        102);
INSERT INTO Candidatura
VALUES ('8a0fb414-58c3-487c-88ab-bc3787cad8bf', '30010755995', NULL,
        2012,
        '6aca1346-2974-4a38-a50e-8137b7583736',
        253);
INSERT INTO Candidatura
VALUES ('4bfaa9b4-2435-4027-a485-947e207fe1f8', '15201660203', '54014710634',
        2014,
        'efff1e60-4a0e-4cfb-9b4b-246c5042b636',
        768);
INSERT INTO Candidatura
VALUES ('b0b8bce8-d1d2-4261-a9d5-c376e731977d', '94022594343', NULL,
        2014,
        'abfea304-7db2-4c4c-a674-b27b912c73c3',
        981);
INSERT INTO Candidatura
VALUES ('abe02cd7-6f96-44da-8d97-058c8b364be6', '46597759188', '34864473633',
        2016,
        '902d5917-2c07-40e1-9bff-4a4187ed0489',
        150);
INSERT INTO Candidatura
VALUES ('cd73e0d8-a5a0-4965-b67f-fcb96082944b', '26279341266', NULL,
        2012,
        'abfea304-7db2-4c4c-a674-b27b912c73c3',
        61);
INSERT INTO Candidatura
VALUES ('7ddaa8fe-29f9-4c43-ac75-c3dcd030a9ca', '26168256616', '60125770117',
        2016,
        '902d5917-2c07-40e1-9bff-4a4187ed0489',
        137);
INSERT INTO Candidatura
VALUES ('9ad04dcb-64ce-4ebe-82f5-2a10a3a40843', '10547932805', NULL,
        2018,
        'c076db4b-b65c-414d-860d-3ed4773801f7',
        149);
INSERT INTO Candidatura
VALUES ('695f7e6f-f799-4d98-ac9d-86e79bb49b26', '81651619777', NULL,
        2016,
        'c076db4b-b65c-414d-860d-3ed4773801f7',
        474);
INSERT INTO Candidatura
VALUES ('5606cf84-e6df-441a-bf4b-8cf2fedd217b', '22529268462', NULL,
        2016,
        '6aca1346-2974-4a38-a50e-8137b7583736',
        616);
INSERT INTO Candidatura
VALUES ('8d7f4656-f8f2-4c46-b159-454dba770dcc', '92302586049', '41397188589',
        2018,
        '902d5917-2c07-40e1-9bff-4a4187ed0489',
        106);
INSERT INTO Candidatura
VALUES ('3e558b39-afa7-4172-84a2-ebb8fae35bc5', '23072280755', '18723213032',
        2014,
        '6fb4b70f-ca27-4ae6-b823-211eccdd650d',
        458);
INSERT INTO Candidatura
VALUES ('66ce5be3-cf2b-47b8-b202-9e03b049dfdb', '41830698924', NULL,
        2012,
        'c076db4b-b65c-414d-860d-3ed4773801f7',
        567);
INSERT INTO Candidatura
VALUES ('7a4ad448-53d3-4c66-826d-8a97a901a75b', '33952316290', NULL,
        2014,
        'c076db4b-b65c-414d-860d-3ed4773801f7',
        351);
INSERT INTO Candidatura
VALUES ('1907b7e9-b1c4-4513-85b4-eb22b7393ec1', '25902807421', NULL,
        2012,
        'c076db4b-b65c-414d-860d-3ed4773801f7',
        849);
INSERT INTO Candidatura
VALUES ('18cb490d-c661-46ed-bfc3-9c5ac3a2988d', '98786025829', '27661639580',
        2014,
        '902d5917-2c07-40e1-9bff-4a4187ed0489',
        693);
INSERT INTO Candidatura
VALUES ('74cca90c-43ab-4571-8e7d-6ed3378f3f15', '92418782110', '80014259815',
        2020,
        '6fb4b70f-ca27-4ae6-b823-211eccdd650d',
        314);
INSERT INTO Candidatura
VALUES ('13a9fa1e-1f6b-4342-9d4e-755eea4746ae', '58593827674', '69932859244',
        2012,
        'efff1e60-4a0e-4cfb-9b4b-246c5042b636',
        880);
INSERT INTO Candidatura
VALUES ('90b78a93-b0e6-4dd0-878b-26109cc8b6ab', '96993440124', '53198584232',
        2020,
        '902d5917-2c07-40e1-9bff-4a4187ed0489',
        219);
INSERT INTO Candidatura
VALUES ('dd690188-35f0-4f8f-a988-bda55a7f31e0', '75875466403', '60173086568',
        2014,
        'efff1e60-4a0e-4cfb-9b4b-246c5042b636',
        760);
INSERT INTO Candidatura
VALUES ('b0c47a27-be24-44bc-9ce5-ba1d604b3d7a', '79832300976', '48100007649',
        2018,
        '6fb4b70f-ca27-4ae6-b823-211eccdd650d',
        468);
INSERT INTO Candidatura
VALUES ('640eb4c6-6d24-4a37-abad-9b9b644e3955', '45628193288', NULL,
        2014,
        'c076db4b-b65c-414d-860d-3ed4773801f7',
        396);
INSERT INTO Candidatura
VALUES ('42c45f89-5f27-47be-bced-02ead36c250c', '94322587393', '75000258060',
        2012,
        'efff1e60-4a0e-4cfb-9b4b-246c5042b636',
        693);
INSERT INTO Candidatura
VALUES ('5b11b35e-1923-4b75-a947-4db0de6b945e', '59162837509', NULL,
        2020,
        'abfea304-7db2-4c4c-a674-b27b912c73c3',
        836);
INSERT INTO Candidatura
VALUES ('283ed392-8e7a-4feb-8873-528dfde48e17', '26070068068', '54936377038',
        2012,
        '902d5917-2c07-40e1-9bff-4a4187ed0489',
        679);
INSERT INTO Candidatura
VALUES ('6743edf2-b86d-4fd5-acb3-deb787d31e25', '20934364222', NULL,
        2014,
        'c076db4b-b65c-414d-860d-3ed4773801f7',
        564);
INSERT INTO Candidatura
VALUES ('55897dfb-60be-4a72-9090-b5e285526d40', '74744968109', '31128941818',
        2014,
        'efff1e60-4a0e-4cfb-9b4b-246c5042b636',
        219);
INSERT INTO Candidatura
VALUES ('22238844-c804-4e8e-aee3-43d6778442b1', '92465915710', NULL,
        2012,
        '6aca1346-2974-4a38-a50e-8137b7583736',
        100);
INSERT INTO Candidatura
VALUES ('93cf78cd-82c8-45a9-a62c-53f2779ee849', '26868924126', '15407267932',
        2016,
        '902d5917-2c07-40e1-9bff-4a4187ed0489',
        394);
INSERT INTO Candidatura
VALUES ('28dfc23e-0015-4499-ae3c-4043c2380c07', '83155709574', NULL,
        2020,
        '6aca1346-2974-4a38-a50e-8137b7583736',
        431);
INSERT INTO Candidatura
VALUES ('4d494652-5545-4dda-9bed-aab79da8ea43', '61147306519', '32508439864',
        2016,
        '902d5917-2c07-40e1-9bff-4a4187ed0489',
        603);
INSERT INTO Candidatura
VALUES ('119fba9c-16a0-4082-a48b-fe5c200309e7', '12995957187', '83954206069',
        2010,
        'efff1e60-4a0e-4cfb-9b4b-246c5042b636',
        851);
INSERT INTO Candidatura
VALUES ('f308e8be-8067-44a4-911f-12f1f0d5ec8d', '85730072224', NULL,
        2016,
        'c076db4b-b65c-414d-860d-3ed4773801f7',
        912);
INSERT INTO Candidatura
VALUES ('7aa95821-a090-4632-944e-23ca486f0381', '34218765089', '31890189512',
        2012,
        'efff1e60-4a0e-4cfb-9b4b-246c5042b636',
        119);
INSERT INTO Candidatura
VALUES ('b6c487a0-35bb-4285-a98d-2cf4b8b0277d', '37930955484', '48704881865',
        2020,
        '6fb4b70f-ca27-4ae6-b823-211eccdd650d',
        362);
INSERT INTO Candidatura
VALUES ('e2616eeb-7005-4ecc-8664-30f74a522398', '51308676458', NULL,
        2016,
        'abfea304-7db2-4c4c-a674-b27b912c73c3',
        946);
INSERT INTO Candidatura
VALUES ('d141ab14-4b8f-403b-a2ef-7df00c4d5eae', '29592667378', '22994280902',
        2010,
        '902d5917-2c07-40e1-9bff-4a4187ed0489',
        91);
INSERT INTO Candidatura
VALUES ('71daf188-eb09-4891-9ac3-e382052e38ee', '88576750692', '42799690433',
        2020,
        '6fb4b70f-ca27-4ae6-b823-211eccdd650d',
        618);
INSERT INTO Candidatura
VALUES ('e3ccd2df-cf31-4dc2-a1e9-34dafe4b26d5', '28168813411', NULL,
        2016,
        '6aca1346-2974-4a38-a50e-8137b7583736',
        224);
INSERT INTO Candidatura
VALUES ('8a706504-ea92-4641-9be4-170346048ca8', '52203854476', '82171370822',
        2016,
        '902d5917-2c07-40e1-9bff-4a4187ed0489',
        466);
INSERT INTO Candidatura
VALUES ('b04d785b-ed4b-4251-9a16-89b585dbc84e', '23625731619', NULL,
        2012,
        'abfea304-7db2-4c4c-a674-b27b912c73c3',
        938);
INSERT INTO Candidatura
VALUES ('f40618ab-e9e6-40f8-80b6-5eed21db0f9f', '93630574638', NULL,
        2012,
        '6aca1346-2974-4a38-a50e-8137b7583736',
        957);
INSERT INTO Candidatura
VALUES ('e021e534-59b1-4a3a-a241-5ccb38a8c368', '27592656244', NULL,
        2012,
        '6aca1346-2974-4a38-a50e-8137b7583736',
        813);
INSERT INTO Candidatura
VALUES ('786b63c3-7d37-448f-bbf1-5bde135f008e', '50671691924', NULL,
        2016,
        'c076db4b-b65c-414d-860d-3ed4773801f7',
        59);
INSERT INTO Candidatura
VALUES ('f94735ea-6c94-4bc9-b853-498fbe3fb8ed', '13525109647', '71656160976',
        2010,
        '902d5917-2c07-40e1-9bff-4a4187ed0489',
        741);
INSERT INTO Candidatura
VALUES ('82a92bc8-dadb-4652-b07b-c553ff495625', '31935233147', '66493321389',
        2016,
        'efff1e60-4a0e-4cfb-9b4b-246c5042b636',
        425);
INSERT INTO Candidatura
VALUES ('5499ba12-93eb-4f28-9030-e422e1ca641b', '60686908485', '94240620594',
        2014,
        '6fb4b70f-ca27-4ae6-b823-211eccdd650d',
        228);
INSERT INTO Candidatura
VALUES ('9a1b188a-1ae7-481b-910e-2a8cf616b278', '45330556328', NULL,
        2020,
        'c076db4b-b65c-414d-860d-3ed4773801f7',
        386);
INSERT INTO Candidatura
VALUES ('dec824a8-13f8-4268-b20d-7625c2cb8e4f', '52914412149', '76646342640',
        2018,
        'efff1e60-4a0e-4cfb-9b4b-246c5042b636',
        559);
INSERT INTO Candidatura
VALUES ('406023d1-1277-460d-bb2d-a2d6f85252fe', '34047240966', NULL,
        2012,
        'c076db4b-b65c-414d-860d-3ed4773801f7',
        493);
INSERT INTO Candidatura
VALUES ('52de8a78-08c2-49d5-ba43-c390fee8f254', '97070763893', NULL,
        2016,
        'abfea304-7db2-4c4c-a674-b27b912c73c3',
        299);
INSERT INTO Candidatura
VALUES ('ebb36ef1-07a5-4104-83bd-68ce97ba041f', '66703392334', NULL,
        2016,
        '6aca1346-2974-4a38-a50e-8137b7583736',
        128);
INSERT INTO Candidatura
VALUES ('24ad90d3-c085-4344-a95a-cc1f0e5b6384', '58487967234', NULL,
        2020,
        '6aca1346-2974-4a38-a50e-8137b7583736',
        4);
INSERT INTO Candidatura
VALUES ('dfed5950-b082-402f-9c77-8920121f9e05', '66040890542', '16329974634',
        2014,
        '902d5917-2c07-40e1-9bff-4a4187ed0489',
        831);
INSERT INTO Candidatura
VALUES ('0654d45e-ca64-4527-af60-904e467d6b1e', '41297736910', NULL,
        2014,
        '6aca1346-2974-4a38-a50e-8137b7583736',
        902);
INSERT INTO Candidatura
VALUES ('d64f2c38-fb8f-4dfd-b538-1d602b8be339', '95344005359', NULL,
        2010,
        'c076db4b-b65c-414d-860d-3ed4773801f7',
        757);
INSERT INTO Candidatura
VALUES ('3a28fd22-f3ee-4a81-8885-1a7db6aed624', '17823370946', '48246632281',
        2018,
        '6fb4b70f-ca27-4ae6-b823-211eccdd650d',
        610);
INSERT INTO Candidatura
VALUES ('0b82da72-d140-4882-b30e-3ac4e3904ff4', '38465311408', NULL,
        2012,
        'c076db4b-b65c-414d-860d-3ed4773801f7',
        534);
INSERT INTO Candidatura
VALUES ('04203daf-737a-4560-b0c6-243bbd1ea019', '35331775275', '43540165110',
        2016,
        'efff1e60-4a0e-4cfb-9b4b-246c5042b636',
        256);
INSERT INTO Candidatura
VALUES ('736b1b58-c06b-4827-9136-3ad9c479d8c6', '13566240610', '86768067248',
        2012,
        '902d5917-2c07-40e1-9bff-4a4187ed0489',
        608);
INSERT INTO Candidatura
VALUES ('813c52ec-5ee8-4b5f-9eba-99a79a785e11', '51165132678', NULL,
        2018,
        'c076db4b-b65c-414d-860d-3ed4773801f7',
        993);
INSERT INTO Candidatura
VALUES ('07e539d9-369d-46f6-b249-f73bc79da5f5', '49287718026', '48550814816',
        2020,
        '902d5917-2c07-40e1-9bff-4a4187ed0489',
        163);
INSERT INTO Candidatura
VALUES ('239e4d8b-6ce7-4398-9361-2d3d31a9e36f', '98128233787', '11529379235',
        2014,
        '6fb4b70f-ca27-4ae6-b823-211eccdd650d',
        976);
INSERT INTO Candidatura
VALUES ('ed5e8e53-720d-428f-ac5a-6b4e966cd3a7', '15176868964', '83675283405',
        2018,
        '6fb4b70f-ca27-4ae6-b823-211eccdd650d',
        994);
INSERT INTO Candidatura
VALUES ('4459792d-86d7-45b8-bd53-d78640095044', '20972804070', '44307413429',
        2016,
        '6fb4b70f-ca27-4ae6-b823-211eccdd650d',
        198);
INSERT INTO Candidatura
VALUES ('dd8113c3-7fa4-429d-a732-f19b85af7eb7', '22237183297', NULL,
        2012,
        'c076db4b-b65c-414d-860d-3ed4773801f7',
        977);
INSERT INTO Candidatura
VALUES ('3fce514b-d035-473e-89b9-90bc8bcbc5eb', '15118655033', '25330412890',
        2012,
        'efff1e60-4a0e-4cfb-9b4b-246c5042b636',
        578);
INSERT INTO Candidatura
VALUES ('5842fb88-5e24-4dfb-92da-70dbbf28ae85', '39486719819', '98071054182',
        2016,
        'efff1e60-4a0e-4cfb-9b4b-246c5042b636',
        909);
INSERT INTO Candidatura
VALUES ('440a79f2-ff61-48ab-a617-df3942665d6f', '98076882518', '79606743648',
        2018,
        '902d5917-2c07-40e1-9bff-4a4187ed0489',
        133);
INSERT INTO Candidatura
VALUES ('7773ce18-d4d2-4ef7-b7df-72ed88749e4d', '67661317153', NULL,
        2014,
        '6aca1346-2974-4a38-a50e-8137b7583736',
        741);
INSERT INTO Candidatura
VALUES ('57cca424-6f6c-4d4d-82c9-6b5ff1e74fa1', '74479391069', '77363675071',
        2012,
        '902d5917-2c07-40e1-9bff-4a4187ed0489',
        371);
INSERT INTO Candidatura
VALUES ('fcf65244-2aaa-4f3e-b7a9-b72e87cdf61a', '16068811987', '84460796038',
        2012,
        'efff1e60-4a0e-4cfb-9b4b-246c5042b636',
        120);
INSERT INTO Candidatura
VALUES ('a3b55b65-efc7-48f0-9c6b-92859cb10dab', '63931753861', '83114106606',
        2010,
        '6fb4b70f-ca27-4ae6-b823-211eccdd650d',
        552);
INSERT INTO Candidatura
VALUES ('78e76551-55dc-49a8-b8c3-fe845acbfecd', '65929289441', NULL,
        2018,
        'c076db4b-b65c-414d-860d-3ed4773801f7',
        53);
INSERT INTO Candidatura
VALUES ('abdb4c55-b853-43db-8eaf-ff857af66912', '55582106600', NULL,
        2016,
        'abfea304-7db2-4c4c-a674-b27b912c73c3',
        490);
INSERT INTO Candidatura
VALUES ('c29c2f54-6c07-4d53-84b1-3834535e35c6', '73727615827', '18236701744',
        2018,
        'efff1e60-4a0e-4cfb-9b4b-246c5042b636',
        591);
INSERT INTO Candidatura
VALUES ('71458e28-7240-43be-a63e-a3ea1f4f1085', '62031259345', NULL,
        2020,
        '6aca1346-2974-4a38-a50e-8137b7583736',
        803);
INSERT INTO Candidatura
VALUES ('4aab384f-7e7e-4bf1-ac35-58ddb6ca8dfa', '25783153302', '90003691567',
        2010,
        '902d5917-2c07-40e1-9bff-4a4187ed0489',
        700);
INSERT INTO Candidatura
VALUES ('d590c3bc-a0e7-4e14-9603-734290d855d6', '76850075086', '71358629062',
        2012,
        'efff1e60-4a0e-4cfb-9b4b-246c5042b636',
        211);
INSERT INTO Candidatura
VALUES ('dcf903a2-d27b-4a1a-b62d-0db8a24241ae', '51977524964', NULL,
        2010,
        'abfea304-7db2-4c4c-a674-b27b912c73c3',
        792);
INSERT INTO Candidatura
VALUES ('0ef44006-8f96-4047-90fa-baa19f9f0627', '21313558840', NULL,
        2014,
        'c076db4b-b65c-414d-860d-3ed4773801f7',
        347);
INSERT INTO Candidatura
VALUES ('65a1d9a6-7c81-48d2-af36-bbfce45f9e8c', '96349825211', NULL,
        2014,
        '6aca1346-2974-4a38-a50e-8137b7583736',
        440);
INSERT INTO Candidatura
VALUES ('2e606f99-258b-4f47-bcad-b2d1ee0079d4', '45510409004', '48776552942',
        2014,
        'efff1e60-4a0e-4cfb-9b4b-246c5042b636',
        256);
INSERT INTO Candidatura
VALUES ('b437122a-32c9-4dde-a516-11d1a76d338a', '31219225791', NULL,
        2014,
        '6aca1346-2974-4a38-a50e-8137b7583736',
        360);
INSERT INTO Candidatura
VALUES ('8a9fab03-d9bd-4daa-9e68-efeebed74226', '91139727742', NULL,
        2020,
        'c076db4b-b65c-414d-860d-3ed4773801f7',
        976);
INSERT INTO Candidatura
VALUES ('dcd75be4-49aa-45ae-8cb4-897f2afb7d41', '62509119817', NULL,
        2014,
        'abfea304-7db2-4c4c-a674-b27b912c73c3',
        236);
INSERT INTO Candidatura
VALUES ('88f1117b-9324-4424-9c76-c7223602197d', '73635011366', '64847709590',
        2020,
        '6fb4b70f-ca27-4ae6-b823-211eccdd650d',
        527);
INSERT INTO Candidatura
VALUES ('42145819-f5cf-4193-bd0d-156bbe3c82c7', '14747534578', '34232794048',
        2010,
        '902d5917-2c07-40e1-9bff-4a4187ed0489',
        396);
INSERT INTO Candidatura
VALUES ('d5929beb-48cc-421e-8fe1-8adcacc67c26', '99220432315', '65012076930',
        2018,
        '902d5917-2c07-40e1-9bff-4a4187ed0489',
        327);
INSERT INTO Candidatura
VALUES ('639f2b7f-3768-4aa4-b3a6-555204d9ea55', '76737339326', NULL,
        2010,
        'c076db4b-b65c-414d-860d-3ed4773801f7',
        953);
INSERT INTO Candidatura
VALUES ('7f4c1600-7514-4812-9de6-1d4ad7700a02', '12808932473', '88489867446',
        2020,
        '6fb4b70f-ca27-4ae6-b823-211eccdd650d',
        878);
INSERT INTO Candidatura
VALUES ('aa89363c-cc69-4198-9997-7ffba904e406', '47388927007', '90606078894',
        2010,
        '902d5917-2c07-40e1-9bff-4a4187ed0489',
        768);
INSERT INTO Candidatura
VALUES ('3159ba5d-da6b-4506-8a4b-5b1227d0b17c', '64779439785', '75071605008',
        2018,
        'efff1e60-4a0e-4cfb-9b4b-246c5042b636',
        564);
INSERT INTO Candidatura
VALUES ('85bbbbe9-8850-4bea-96e1-c7bc69998342', '91857076140', '77054765247',
        2020,
        'efff1e60-4a0e-4cfb-9b4b-246c5042b636',
        99);
INSERT INTO Candidatura
VALUES ('a0361ceb-8a60-4dc1-adf5-2d302c2871f2', '49829237502', '26070915332',
        2010,
        'efff1e60-4a0e-4cfb-9b4b-246c5042b636',
        447);
INSERT INTO Candidatura
VALUES ('c3811de8-8a01-4ec2-8999-428a570ef493', '56085495813', '36079567898',
        2016,
        '902d5917-2c07-40e1-9bff-4a4187ed0489',
        507);
INSERT INTO Candidatura
VALUES ('154a8bdc-f43f-432d-bbb1-8603be3e2bcc', '74025096402', '49220664729',
        2010,
        'efff1e60-4a0e-4cfb-9b4b-246c5042b636',
        385);
INSERT INTO Candidatura
VALUES ('c6b44329-108b-493e-aa4f-1411a4692f71', '93640094532', '34828906285',
        2018,
        'efff1e60-4a0e-4cfb-9b4b-246c5042b636',
        364);
INSERT INTO Candidatura
VALUES ('6adcce89-1210-4786-a4d5-19d8aa029e96', '49999960965', NULL,
        2014,
        'abfea304-7db2-4c4c-a674-b27b912c73c3',
        321);
INSERT INTO Candidatura
VALUES ('62aa82c3-9f78-43f0-a14e-8459d16e8977', '73055091793', '78893276196',
        2018,
        '6fb4b70f-ca27-4ae6-b823-211eccdd650d',
        748);
INSERT INTO Candidatura
VALUES ('afed7395-37f4-4d04-af9e-34a63982727b', '69626756855', '47024384837',
        2010,
        '902d5917-2c07-40e1-9bff-4a4187ed0489',
        555);
INSERT INTO Candidatura
VALUES ('e6d2d42a-1a5a-47f6-9993-ccdb98d51eb3', '63260848645', '83906174097',
        2018,
        '902d5917-2c07-40e1-9bff-4a4187ed0489',
        596);
INSERT INTO Candidatura
VALUES ('afb7ec26-4f46-4450-ad0d-7e0fb4721d9f', '51777044697', '48008790058',
        2012,
        '6fb4b70f-ca27-4ae6-b823-211eccdd650d',
        38);
INSERT INTO Candidatura
VALUES ('7791637f-e466-451e-9163-8ae171ba4a00', '38865358545', NULL,
        2014,
        'abfea304-7db2-4c4c-a674-b27b912c73c3',
        49);
INSERT INTO Candidatura
VALUES ('9ee749ba-698b-4b79-bf82-6a2f9fe5a6cc', '61522070106', NULL,
        2016,
        '6aca1346-2974-4a38-a50e-8137b7583736',
        217);
INSERT INTO Candidatura
VALUES ('3b4adc40-133e-4268-b397-0d58f9796cbe', '49970481498', NULL,
        2020,
        '6aca1346-2974-4a38-a50e-8137b7583736',
        658);
INSERT INTO Candidatura
VALUES ('7789487f-7d38-4e16-a7f5-0b57473abcae', '97555941788', NULL,
        2010,
        '6aca1346-2974-4a38-a50e-8137b7583736',
        900);
INSERT INTO Candidatura
VALUES ('5220a514-eaed-4d37-bfaa-83b7173e67fb', '80266070396', NULL,
        2018,
        'c076db4b-b65c-414d-860d-3ed4773801f7',
        614);
INSERT INTO Candidatura
VALUES ('2902a6c6-7c05-41fb-8e06-2926ec5ec375', '50634076290', '36101309738',
        2012,
        '6fb4b70f-ca27-4ae6-b823-211eccdd650d',
        73);
INSERT INTO Candidatura
VALUES ('4b44945c-c3f8-41eb-b673-f44cd25840ff', '50441387610', '12213830926',
        2010,
        'efff1e60-4a0e-4cfb-9b4b-246c5042b636',
        561);
INSERT INTO Candidatura
VALUES ('2552431d-c420-4d02-bad1-19bc739900df', '61577998858', '12698386129',
        2020,
        'efff1e60-4a0e-4cfb-9b4b-246c5042b636',
        246);
INSERT INTO Candidatura
VALUES ('782ef36f-236a-4dd3-aa19-f9f0bd61eb10', '52959466576', '95204672040',
        2014,
        '902d5917-2c07-40e1-9bff-4a4187ed0489',
        50);
INSERT INTO Candidatura
VALUES ('30d3e491-cf0c-4b40-863d-0487d785dea4', '28038902608', NULL,
        2018,
        'abfea304-7db2-4c4c-a674-b27b912c73c3',
        537);
INSERT INTO Candidatura
VALUES ('c70ff7c3-1273-475b-aa99-effa288fd7cd', '14908413034', NULL,
        2014,
        'abfea304-7db2-4c4c-a674-b27b912c73c3',
        438);
INSERT INTO Candidatura
VALUES ('050bb7aa-3853-470e-95d9-f5c11c566425', '92511644628', NULL,
        2010,
        'abfea304-7db2-4c4c-a674-b27b912c73c3',
        29);
INSERT INTO Candidatura
VALUES ('907cbc21-fe24-4711-8a85-ba401e870971', '62782628233', NULL,
        2018,
        'abfea304-7db2-4c4c-a674-b27b912c73c3',
        296);
INSERT INTO Candidatura
VALUES ('09851534-f0f1-4902-b7bc-7818876c0940', '18369440392', '85872988284',
        2014,
        '6fb4b70f-ca27-4ae6-b823-211eccdd650d',
        342);
INSERT INTO Candidatura
VALUES ('c5659edf-a245-4445-868b-41a316da92a0', '18165175339', '72124885278',
        2016,
        'efff1e60-4a0e-4cfb-9b4b-246c5042b636',
        42);
INSERT INTO Candidatura
VALUES ('e2dac658-9a73-4a91-81d4-625dbbcb9d7e', '75959301025', NULL,
        2016,
        'c076db4b-b65c-414d-860d-3ed4773801f7',
        270);
INSERT INTO Candidatura
VALUES ('3a9cb203-bfbc-41fc-b7c3-1f7a01541d00', '86252562392', NULL,
        2018,
        'c076db4b-b65c-414d-860d-3ed4773801f7',
        597);
INSERT INTO Candidatura
VALUES ('d8974770-6d0b-4e73-a175-5be80285fa4d', '67951579191', NULL,
        2018,
        '6aca1346-2974-4a38-a50e-8137b7583736',
        604);
INSERT INTO Candidatura
VALUES ('b9df20ea-f757-462e-9920-988b3d89e03d', '44202141419', NULL,
        2012,
        '6aca1346-2974-4a38-a50e-8137b7583736',
        143);
INSERT INTO Candidatura
VALUES ('616a8426-048b-4dd0-8875-a53c517be974', '17060826153', '13162715234',
        2018,
        '902d5917-2c07-40e1-9bff-4a4187ed0489',
        21);
INSERT INTO Candidatura
VALUES ('f6864c44-7706-41e2-8e35-f5dd0b914dcc', '76793153581', '73767229476',
        2018,
        'efff1e60-4a0e-4cfb-9b4b-246c5042b636',
        670);
INSERT INTO Candidatura
VALUES ('86a09a87-0cf3-4621-b641-31f3e2f54616', '70315878796', NULL,
        2014,
        'abfea304-7db2-4c4c-a674-b27b912c73c3',
        15);
INSERT INTO Candidatura
VALUES ('1ca4e324-d621-42ae-8e53-d084fe1e58df', '85119483100', NULL,
        2016,
        'abfea304-7db2-4c4c-a674-b27b912c73c3',
        533);
INSERT INTO Candidatura
VALUES ('43b2526b-02e2-4f55-8f81-46ea3f552053', '61486375667', '80154288623',
        2016,
        '902d5917-2c07-40e1-9bff-4a4187ed0489',
        523);
INSERT INTO Candidatura
VALUES ('e298afbd-dfe4-4bb3-af93-e80d852d305b', '40210098912', NULL,
        2018,
        '6aca1346-2974-4a38-a50e-8137b7583736',
        731);
INSERT INTO Candidatura
VALUES ('f91f6201-a115-4e1b-803a-667c579e4f5b', '65327025726', '12673338970',
        2010,
        'efff1e60-4a0e-4cfb-9b4b-246c5042b636',
        364);
INSERT INTO Candidatura
VALUES ('6c5e83c6-2fc6-44f5-8f04-188a62645bf0', '25677760089', '79079376994',
        2018,
        'efff1e60-4a0e-4cfb-9b4b-246c5042b636',
        616);
INSERT INTO Candidatura
VALUES ('8eef8298-c53a-4709-a3de-a111ce009e2a', '68435227326', NULL,
        2020,
        'c076db4b-b65c-414d-860d-3ed4773801f7',
        524);
INSERT INTO Candidatura
VALUES ('df8062eb-aa44-4306-91d5-42380c0ed1dd', '25196086270', NULL,
        2018,
        '6aca1346-2974-4a38-a50e-8137b7583736',
        258);
INSERT INTO Candidatura
VALUES ('26d90d3e-2c05-4422-ab2e-015903f2c540', '46683265664', NULL,
        2014,
        'c076db4b-b65c-414d-860d-3ed4773801f7',
        688);
INSERT INTO Candidatura
VALUES ('7b5dc685-ae94-452c-ab8b-134509c6ef54', '28576460210', NULL,
        2016,
        'c076db4b-b65c-414d-860d-3ed4773801f7',
        576);
INSERT INTO Candidatura
VALUES ('3fd668e5-19a7-4c7a-8d04-94ec82e21881', '67022069275', NULL,
        2012,
        'c076db4b-b65c-414d-860d-3ed4773801f7',
        696);
INSERT INTO Candidatura
VALUES ('2ae7d657-c108-4134-8a5c-475019279bfe', '74132363493', '77608265816',
        2014,
        'efff1e60-4a0e-4cfb-9b4b-246c5042b636',
        364);
INSERT INTO Candidatura
VALUES ('d02242e7-fe79-4ff1-a13a-6d791330a265', '26318127936', NULL,
        2018,
        'abfea304-7db2-4c4c-a674-b27b912c73c3',
        750);
INSERT INTO Candidatura
VALUES ('e7d9f52a-ff86-48ec-99ba-c777dd6f778d', '55435475325', NULL,
        2010,
        '6aca1346-2974-4a38-a50e-8137b7583736',
        50);
INSERT INTO Candidatura
VALUES ('6a915a3a-868e-43fe-947c-10d8064a6d38', '72249765472', '56206870884',
        2012,
        '6fb4b70f-ca27-4ae6-b823-211eccdd650d',
        884);
INSERT INTO Candidatura
VALUES ('e4e3f156-654c-4a28-b169-d5611004848e', '35895102075', NULL,
        2012,
        'abfea304-7db2-4c4c-a674-b27b912c73c3',
        844);
INSERT INTO Candidatura
VALUES ('b9957418-f6d0-4c83-9178-6b0975af3315', '80575645365', '39911369015',
        2018,
        'efff1e60-4a0e-4cfb-9b4b-246c5042b636',
        987);


-- Insere Equipes de Apoio
INSERT INTO Equipe_Apoio
VALUES ('883dde1f-5898-4a09-af78-a327c3421c72', '917d9d62-6b92-4eb6-bcb4-e184642379df', 2016,
        'Comunicação com o Eleitor');
INSERT INTO Equipe_Apoio
VALUES ('d4b47ae3-e1e0-4e2e-8bbb-c6c5cfa74f80', '39d1f0f1-5459-4a78-932a-867cc5b5878c', 2014, 'Arrecador Fundos');
INSERT INTO Equipe_Apoio
VALUES ('e4190452-7b83-4953-a7a2-a0410b0a94b4', 'cd73e0d8-a5a0-4965-b67f-fcb96082944b', 2010, 'Apoiar Movimentos');
INSERT INTO Equipe_Apoio
VALUES ('e38a8b10-d849-449c-8ec2-02d36d230d23', 'cb951489-cf01-4402-98d4-c2020f79e862', 2010, 'Apoiar Movimentos');
INSERT INTO Equipe_Apoio
VALUES ('cb80f973-7257-4411-8d2d-2ba42095bdd3', '14e004da-446a-46a4-8887-806ac81ebcad', 2014,
        'Comunicação com o Eleitor');
INSERT INTO Equipe_Apoio
VALUES ('ad3b0c42-0627-4314-85c4-7b8d29bdb75a', '0a95979e-c07d-4277-bc04-7bacaede0ad3', 2010, 'Apoiar Movimentos');
INSERT INTO Equipe_Apoio
VALUES ('c5553153-7d3e-4cc7-84e4-43591d84d199', '4b44945c-c3f8-41eb-b673-f44cd25840ff', 2018, 'Marketing');
INSERT INTO Equipe_Apoio
VALUES ('980ee312-f850-43d6-93ff-8b5bf963f636', '140c00c6-9c63-4078-8235-49de5c138138', 2016,
        'Comunicação com o Eleitor');
INSERT INTO Equipe_Apoio
VALUES ('f67ca040-4764-4759-97d1-60246e2bcfb5', '9cc9ac5b-b66a-4b29-858e-005244337c95', 2010, 'Arrecador Fundos');
INSERT INTO Equipe_Apoio
VALUES ('c420a55b-837f-480e-9208-b527b95a30f5', 'fadd0750-3074-44c8-8dc6-5142a6fbcd9a', 2020,
        'Comunicação com o Eleitor');
INSERT INTO Equipe_Apoio
VALUES ('66f88b54-82f1-4b7d-8428-bc27357704b9', '0b5f8599-e968-421d-ae9d-11d271b8e9b8', 2012, 'Apoiar Movimentos');
INSERT INTO Equipe_Apoio
VALUES ('eed2ed8e-35bf-4120-bcf7-7b46a0f4d579', '30d3e491-cf0c-4b40-863d-0487d785dea4', 2014, 'Apoiar Movimentos');
INSERT INTO Equipe_Apoio
VALUES ('1ea42961-8416-4334-b882-62feafc574b1', '6c5e83c6-2fc6-44f5-8f04-188a62645bf0', 2014,
        'Comunicação com o Eleitor');
INSERT INTO Equipe_Apoio
VALUES ('813e7fa6-ce75-492f-a975-36a8c7110394', '283ed392-8e7a-4feb-8873-528dfde48e17', 2018, 'Apoiar Movimentos');
INSERT INTO Equipe_Apoio
VALUES ('5992d3ca-7897-4472-be0b-b953af3af579', '6c09c4e0-f482-4559-9193-395ec5fe628f', 2012, 'Apoiar Movimentos');
INSERT INTO Equipe_Apoio
VALUES ('ef8b0d83-2585-4867-a2c3-b50fd19b35f8', '3e08ab28-65f8-4935-a018-80f6a20f193c', 2016, 'Arrecador Fundos');
INSERT INTO Equipe_Apoio
VALUES ('addaee00-4e9e-4ca3-a134-f882588e3d7c', '951773bf-8527-4ca8-9f02-167dddd5df64', 2012, 'Marketing');
INSERT INTO Equipe_Apoio
VALUES ('efbf228b-2a3f-4ea9-ae84-b344cf9fbf85', '849a12e4-0864-437b-aa52-39cf2d851546', 2012, 'Arrecador Fundos');
INSERT INTO Equipe_Apoio
VALUES ('95096071-49b8-41ab-97bb-9eccbe5bac34', '58b95725-63d5-4d4a-96da-cf738741720e', 2020, 'Arrecador Fundos');
INSERT INTO Equipe_Apoio
VALUES ('088223cb-8981-4991-8dbe-476b081bd471', 'abdb4c55-b853-43db-8eaf-ff857af66912', 2016, 'Marketing');
INSERT INTO Equipe_Apoio
VALUES ('abd68967-ba77-40d4-83a7-d6d2ae397be1', '1ddf162a-5faa-45be-bb45-17555b4df092', 2014,
        'Comunicação com o Eleitor');
INSERT INTO Equipe_Apoio
VALUES ('e49c4f8d-1b75-4b8b-a8b2-9e98cfe839e6', '294c5d0e-6eac-4fdf-97ac-afb6002d9a7a', 2010,
        'Comunicação com o Eleitor');
INSERT INTO Equipe_Apoio
VALUES ('73c9d17a-506a-4bca-bdaf-3f9e938117e6', 'f33f011e-3f4c-4920-a003-4987a4c22e7d', 2014, 'Marketing');
INSERT INTO Equipe_Apoio
VALUES ('777754cc-b140-4168-86e8-180476720db6', 'dcf903a2-d27b-4a1a-b62d-0db8a24241ae', 2016, 'Apoiar Movimentos');
INSERT INTO Equipe_Apoio
VALUES ('975706f4-c4b9-4211-96e0-85e54a59f3d0', '65a1d9a6-7c81-48d2-af36-bbfce45f9e8c', 2020, 'Arrecador Fundos');
INSERT INTO Equipe_Apoio
VALUES ('7e4c6f05-7054-4db2-9641-c0c695cdbe12', '6df4504e-b88d-4f7f-b79e-b9e663c15cbf', 2016, 'Apoiar Movimentos');
INSERT INTO Equipe_Apoio
VALUES ('233e7579-f95f-4f51-9551-3c47117e4e10', '7773ce18-d4d2-4ef7-b7df-72ed88749e4d', 2016, 'Apoiar Movimentos');
INSERT INTO Equipe_Apoio
VALUES ('b0bd8f57-5ed8-47d2-8b1d-d5f12c79e4dc', 'f348d10b-3674-4cb0-b490-3c2123b0ee03', 2012, 'Marketing');
INSERT INTO Equipe_Apoio
VALUES ('019662fc-6911-4ffd-9027-e1c65381c212', 'f6864c44-7706-41e2-8e35-f5dd0b914dcc', 2020, 'Marketing');
INSERT INTO Equipe_Apoio
VALUES ('2738a0b5-57f2-416f-92fc-a6590c8e0156', '2ae7d657-c108-4134-8a5c-475019279bfe', 2010,
        'Comunicação com o Eleitor');
INSERT INTO Equipe_Apoio
VALUES ('6f0fef58-d623-4cb9-b26e-eb7b80e8c217', '71f474f3-cf89-4e8a-8751-430c3c8f627c', 2010, 'Arrecador Fundos');
INSERT INTO Equipe_Apoio
VALUES ('ac80df4a-01ff-4aed-a73c-f63631b44536', '90b78a93-b0e6-4dd0-878b-26109cc8b6ab', 2016, 'Apoiar Movimentos');
INSERT INTO Equipe_Apoio
VALUES ('ea1ec8d1-7eba-4d92-8fbe-48efe28431f6', 'f0968330-20b4-4cca-939a-c514fe8ba825', 2010,
        'Comunicação com o Eleitor');
INSERT INTO Equipe_Apoio
VALUES ('85f24004-f7fd-4000-acd1-0ade019d947b', '0e679ddc-8e10-4c15-bfb5-a187d79c171d', 2014, 'Arrecador Fundos');
INSERT INTO Equipe_Apoio
VALUES ('b365bfe4-9c7f-47f6-a5d9-aff1ca47cbc1', '3159ba5d-da6b-4506-8a4b-5b1227d0b17c', 2018, 'Apoiar Movimentos');
INSERT INTO Equipe_Apoio
VALUES ('2a24189e-829f-470d-ada6-d91e339827e3', 'f91f6201-a115-4e1b-803a-667c579e4f5b', 2014, 'Arrecador Fundos');
INSERT INTO Equipe_Apoio
VALUES ('172aa6cb-deac-41a9-bf1f-da2b3e37d7ac', 'a3add6b7-5a06-4639-bccf-bf7cad622250', 2012, 'Apoiar Movimentos');
INSERT INTO Equipe_Apoio
VALUES ('213baa8e-4d1b-432f-aded-3b6832553337', '8925189d-a9f3-4955-965d-c9a4748abba3', 2018, 'Apoiar Movimentos');
INSERT INTO Equipe_Apoio
VALUES ('5b10b370-9be5-401b-84a5-2c66d84329af', '827d9967-cc68-4272-9daf-14e8089f9e76', 2012, 'Apoiar Movimentos');
INSERT INTO Equipe_Apoio
VALUES ('85dab8c6-fb66-4405-943f-234943494bd0', '52de8a78-08c2-49d5-ba43-c390fee8f254', 2010,
        'Comunicação com o Eleitor');
INSERT INTO Equipe_Apoio
VALUES ('61638f40-1999-4dde-80ea-f02f5c256e60', '88f1117b-9324-4424-9c76-c7223602197d', 2016, 'Apoiar Movimentos');
INSERT INTO Equipe_Apoio
VALUES ('cb7e7f05-6cc9-4802-af54-e228ab26fad4', 'cd73e0d8-a5a0-4965-b67f-fcb96082944b', 2010, 'Arrecador Fundos');
INSERT INTO Equipe_Apoio
VALUES ('22850f31-5bb8-48c6-826f-68cba23b6ba5', '154a8bdc-f43f-432d-bbb1-8603be3e2bcc', 2016,
        'Comunicação com o Eleitor');
INSERT INTO Equipe_Apoio
VALUES ('4896abea-0e4b-4c24-bd81-e15efe9b5202', 'e2616eeb-7005-4ecc-8664-30f74a522398', 2012,
        'Comunicação com o Eleitor');
INSERT INTO Equipe_Apoio
VALUES ('89f5b4d0-bc3e-4190-8f0d-f5417e0e21cd', 'fbc0eb50-4019-4da5-b2d7-161c9293706e', 2012, 'Arrecador Fundos');
INSERT INTO Equipe_Apoio
VALUES ('f0dc16c0-faa9-49e6-be7e-d013aecec2f7', '55897dfb-60be-4a72-9090-b5e285526d40', 2010, 'Apoiar Movimentos');
INSERT INTO Equipe_Apoio
VALUES ('e154942d-3c0e-4cb3-acd1-b6987451c71b', '050bb7aa-3853-470e-95d9-f5c11c566425', 2016, 'Apoiar Movimentos');
INSERT INTO Equipe_Apoio
VALUES ('e8c11ad3-094f-4366-8ee2-8f43ca6a7a96', '0654d45e-ca64-4527-af60-904e467d6b1e', 2018, 'Marketing');
INSERT INTO Equipe_Apoio
VALUES ('3e3e71bf-f0fe-4d02-af1a-d29c9636cfa1', '84591eb8-0dd9-4b71-a766-efa0e7f151e8', 2020, 'Marketing');
INSERT INTO Equipe_Apoio
VALUES ('8623fb61-0275-44e3-8c22-c88b4a497700', '907cbc21-fe24-4711-8a85-ba401e870971', 2018, 'Apoiar Movimentos');
INSERT INTO Equipe_Apoio
VALUES ('a8c9c6cb-4139-4d10-ae9b-df554da911fe', '9ad04dcb-64ce-4ebe-82f5-2a10a3a40843', 2018, 'Apoiar Movimentos');
INSERT INTO Equipe_Apoio
VALUES ('ae4d6ec0-814d-41e1-a1f0-b08aaead4aea', '00c6b060-9bac-4452-b127-39420d4a97f9', 2016, 'Apoiar Movimentos');
INSERT INTO Equipe_Apoio
VALUES ('454c88bd-7003-4f2c-907e-6322f1c49a0c', 'e58fc962-e25c-4032-9934-6e09c10fac93', 2010, 'Marketing');
INSERT INTO Equipe_Apoio
VALUES ('3a8f538d-e05c-404f-b441-e0c69203dd68', '6df4504e-b88d-4f7f-b79e-b9e663c15cbf', 2010,
        'Comunicação com o Eleitor');
INSERT INTO Equipe_Apoio
VALUES ('b796b41a-ec6c-4e9d-a861-b421e109d9df', '7929ba27-8368-4c77-97b3-face01bbe78b', 2020,
        'Comunicação com o Eleitor');
INSERT INTO Equipe_Apoio
VALUES ('f42992db-4c57-4ad4-bf42-37396f0d77ba', '13a9fa1e-1f6b-4342-9d4e-755eea4746ae', 2016, 'Arrecador Fundos');
INSERT INTO Equipe_Apoio
VALUES ('06921e43-c8a1-40bc-a537-5ed9c915f1d4', '01e85bac-4bed-4b58-b51b-ae77e95cac0d', 2010, 'Marketing');
INSERT INTO Equipe_Apoio
VALUES ('fc5c02ef-3f61-4567-a6d3-6e2910a527a4', '69384f39-1b94-4f0b-9404-cc6f99209734', 2018,
        'Comunicação com o Eleitor');
INSERT INTO Equipe_Apoio
VALUES ('5863fe9d-2717-488e-9e23-bacc564b88ce', 'de9f0e95-beac-4fd8-aa8c-ed28b4acdd75', 2018,
        'Comunicação com o Eleitor');
INSERT INTO Equipe_Apoio
VALUES ('49e83525-834a-4bc7-b08a-c9061456b1a2', 'd8974770-6d0b-4e73-a175-5be80285fa4d', 2010, 'Apoiar Movimentos');
INSERT INTO Equipe_Apoio
VALUES ('cf4c46a0-d533-4934-a077-39713f20ec46', '14e004da-446a-46a4-8887-806ac81ebcad', 2016, 'Apoiar Movimentos');
INSERT INTO Equipe_Apoio
VALUES ('87a81832-3d34-4864-8e94-d19f4d7d7cae', '4d494652-5545-4dda-9bed-aab79da8ea43', 2018,
        'Comunicação com o Eleitor');
INSERT INTO Equipe_Apoio
VALUES ('862c16e5-851b-4083-8e0a-c3f67188339d', 'b04d785b-ed4b-4251-9a16-89b585dbc84e', 2016, 'Marketing');
INSERT INTO Equipe_Apoio
VALUES ('b2cd7158-830a-49e6-81a6-6213785d7fdd', '00c6b060-9bac-4452-b127-39420d4a97f9', 2010,
        'Comunicação com o Eleitor');
INSERT INTO Equipe_Apoio
VALUES ('9918b566-6aae-4840-b207-ef4bba5f97b8', '7a4ad448-53d3-4c66-826d-8a97a901a75b', 2016, 'Apoiar Movimentos');
INSERT INTO Equipe_Apoio
VALUES ('90c7027a-8c35-4abd-b7bb-879aa21458d3', '8658829e-b5e0-4fe1-b3b2-73a5100a152f', 2012,
        'Comunicação com o Eleitor');
INSERT INTO Equipe_Apoio
VALUES ('b7e02c87-11f8-4687-babb-19fd32049f51', '8dcc3d94-22e4-449b-b282-526679f164e1', 2018,
        'Comunicação com o Eleitor');
INSERT INTO Equipe_Apoio
VALUES ('b9fd5755-c40f-480c-bff4-e96e5dbefb31', 'd1b0dede-99f8-4c51-b9de-ef7de6c0f223', 2016, 'Arrecador Fundos');
INSERT INTO Equipe_Apoio
VALUES ('72a10e43-4ca1-40ae-a08f-67e8d5b463d7', '26d90d3e-2c05-4422-ab2e-015903f2c540', 2010, 'Apoiar Movimentos');
INSERT INTO Equipe_Apoio
VALUES ('64a950b3-44e1-4c1a-a4f3-d73cdf6f52d7', 'c3811de8-8a01-4ec2-8999-428a570ef493', 2020, 'Apoiar Movimentos');
INSERT INTO Equipe_Apoio
VALUES ('c1a79efe-6456-4d31-a4e5-d11ad51a78cb', '5da46041-3847-40fa-a3bd-e29a48c3b61e', 2018, 'Apoiar Movimentos');
INSERT INTO Equipe_Apoio
VALUES ('ed2d6d75-a514-40dd-8bb3-a41b2a8ae291', '3e08ab28-65f8-4935-a018-80f6a20f193c', 2012, 'Arrecador Fundos');
INSERT INTO Equipe_Apoio
VALUES ('75c3d2b6-0862-4fd8-9703-e8cb672c84c9', '85bbbbe9-8850-4bea-96e1-c7bc69998342', 2014, 'Apoiar Movimentos');
INSERT INTO Equipe_Apoio
VALUES ('4e9663f6-82d8-45e8-94bd-bac5938198e4', '04cae94e-ec38-4f04-83c6-90db81370973', 2020,
        'Comunicação com o Eleitor');
INSERT INTO Equipe_Apoio
VALUES ('65c20bb9-98b6-43b7-9557-6dc29e5cb58f', 'bccd20c5-9887-43d0-ab8f-9a99678f6bf5', 2012,
        'Comunicação com o Eleitor');
INSERT INTO Equipe_Apoio
VALUES ('29eada49-e5a9-4c52-8e4a-39b710ba4ac6', 'd590c3bc-a0e7-4e14-9603-734290d855d6', 2020, 'Arrecador Fundos');
INSERT INTO Equipe_Apoio
VALUES ('8703a49a-0644-40fd-a423-c59c5f515f77', '42e009cf-1cee-44e3-b3a4-e48e6d9d4aea', 2012, 'Apoiar Movimentos');
INSERT INTO Equipe_Apoio
VALUES ('a585e09f-bad4-40ee-9c6f-9fc8b60e5afc', 'de9f0e95-beac-4fd8-aa8c-ed28b4acdd75', 2018,
        'Comunicação com o Eleitor');
INSERT INTO Equipe_Apoio
VALUES ('b52bb575-a975-4e4c-a26b-e3295fc3905f', 'df8062eb-aa44-4306-91d5-42380c0ed1dd', 2014, 'Arrecador Fundos');
INSERT INTO Equipe_Apoio
VALUES ('4fcef15f-52db-4fd1-bceb-0e57287722e4', '6152b778-ea38-457f-9c17-d6e05506e4e8', 2018, 'Arrecador Fundos');
INSERT INTO Equipe_Apoio
VALUES ('e8f613fb-78ab-45dd-827b-fa8816d73802', '4104cee5-6e88-414a-8bd7-ec6cd7d6ae62', 2014, 'Marketing');
INSERT INTO Equipe_Apoio
VALUES ('7f456833-68b4-42be-9638-8d31c1dcb284', 'dec0783c-9b85-46d6-854a-23789fbc5fac', 2014, 'Arrecador Fundos');
INSERT INTO Equipe_Apoio
VALUES ('5014c0a3-c1e2-4c31-b201-3691d1da8216', 'be66fcc2-9a7a-4994-97db-d31b136abbf4', 2014, 'Arrecador Fundos');
INSERT INTO Equipe_Apoio
VALUES ('911012ce-07b3-4793-8443-b9307d490f85', 'ebb36ef1-07a5-4104-83bd-68ce97ba041f', 2020, 'Marketing');
INSERT INTO Equipe_Apoio
VALUES ('6fbb0c02-df96-4dff-8ef4-3865781bed0c', '3b3d1e33-a62b-431c-a761-c24e8cf602e3', 2012,
        'Comunicação com o Eleitor');
INSERT INTO Equipe_Apoio
VALUES ('e2c22394-e0b8-4d70-a25d-31f106cdd084', '3d838daf-b50f-434d-8a4d-733ac960fc56', 2018, 'Marketing');
INSERT INTO Equipe_Apoio
VALUES ('c3c49906-a4e1-4007-83fb-1fcf86eb98d3', 'b04d785b-ed4b-4251-9a16-89b585dbc84e', 2010,
        'Comunicação com o Eleitor');
INSERT INTO Equipe_Apoio
VALUES ('e3f842a5-e5c0-4e23-b907-6227186a52ab', 'f0968330-20b4-4cca-939a-c514fe8ba825', 2014, 'Marketing');
INSERT INTO Equipe_Apoio
VALUES ('c9b9cdb5-24ce-47c2-8084-94179c0ad109', 'f33f011e-3f4c-4920-a003-4987a4c22e7d', 2014,
        'Comunicação com o Eleitor');
INSERT INTO Equipe_Apoio
VALUES ('52bb2f46-2d2d-4b15-8730-dd4c9b3e56c5', '3b4adc40-133e-4268-b397-0d58f9796cbe', 2014,
        'Comunicação com o Eleitor');
INSERT INTO Equipe_Apoio
VALUES ('a6fa3e73-3b3d-47b6-8fa4-a6409c01240a', '55897dfb-60be-4a72-9090-b5e285526d40', 2012, 'Marketing');
INSERT INTO Equipe_Apoio
VALUES ('c8d025ec-a1ef-42f1-9045-ab9124df1a03', 'b227c169-b231-4158-914e-d558c2c7055e', 2012, 'Arrecador Fundos');
INSERT INTO Equipe_Apoio
VALUES ('cc81a461-a46e-47f5-b2a2-8cf054331939', '3fce514b-d035-473e-89b9-90bc8bcbc5eb', 2018, 'Marketing');
INSERT INTO Equipe_Apoio
VALUES ('94d18442-8291-44e9-b4e5-0bd6fcc936ce', '3159ba5d-da6b-4506-8a4b-5b1227d0b17c', 2010, 'Arrecador Fundos');
INSERT INTO Equipe_Apoio
VALUES ('ce888567-2731-4664-a243-015d44780b1d', '7791637f-e466-451e-9163-8ae171ba4a00', 2010, 'Apoiar Movimentos');
INSERT INTO Equipe_Apoio
VALUES ('e45c94b7-9e11-4b85-a5d5-8d4190260f5c', 'be66fcc2-9a7a-4994-97db-d31b136abbf4', 2010, 'Arrecador Fundos');
INSERT INTO Equipe_Apoio
VALUES ('e1120b8e-4944-47fd-837b-eaed572739bf', '5499ba12-93eb-4f28-9030-e422e1ca641b', 2014, 'Arrecador Fundos');
INSERT INTO Equipe_Apoio
VALUES ('f7048642-3a98-43d1-a4c9-43d0db8bddf4', '9ad04dcb-64ce-4ebe-82f5-2a10a3a40843', 2014, 'Apoiar Movimentos');
INSERT INTO Equipe_Apoio
VALUES ('7a133504-c609-4089-b2f4-e3d2080fdd00', '3fd668e5-19a7-4c7a-8d04-94ec82e21881', 2010, 'Apoiar Movimentos');
INSERT INTO Equipe_Apoio
VALUES ('3f33ff66-bb0c-48b0-a7e9-95b393126ac9', '0bcc2544-fadd-4149-b422-0fcdd4ca64a9', 2012, 'Arrecador Fundos');


-- Insere Apoiadores de Campanha
INSERT INTO Apoiador_Campanha
VALUES ('4fcef15f-52db-4fd1-bceb-0e57287722e4', '15407267932', 'ca3511e9-bebf-4d9b-a092-9d54323026c8');
INSERT INTO Apoiador_Campanha
VALUES ('e2c22394-e0b8-4d70-a25d-31f106cdd084', '48673702988', 'cd73e0d8-a5a0-4965-b67f-fcb96082944b');
INSERT INTO Apoiador_Campanha
VALUES ('ac80df4a-01ff-4aed-a73c-f63631b44536', '44538643399', 'f33f011e-3f4c-4920-a003-4987a4c22e7d');
INSERT INTO Apoiador_Campanha
VALUES ('61638f40-1999-4dde-80ea-f02f5c256e60', '27603935101', '1858d9d7-d178-4a46-acc1-89e0757c6afd');
INSERT INTO Apoiador_Campanha
VALUES ('75c3d2b6-0862-4fd8-9703-e8cb672c84c9', '95630513457', '3b3d1e33-a62b-431c-a761-c24e8cf602e3');
INSERT INTO Apoiador_Campanha
VALUES ('72a10e43-4ca1-40ae-a08f-67e8d5b463d7', '44931717652', 'fbc0eb50-4019-4da5-b2d7-161c9293706e');
INSERT INTO Apoiador_Campanha
VALUES ('cb80f973-7257-4411-8d2d-2ba42095bdd3', '44931717652', 'bccd20c5-9887-43d0-ab8f-9a99678f6bf5');
INSERT INTO Apoiador_Campanha
VALUES ('ef8b0d83-2585-4867-a2c3-b50fd19b35f8', '74359773746', 'e92b3d56-bd71-40cb-9cd7-e8e7296b6ae7');
INSERT INTO Apoiador_Campanha
VALUES ('4fcef15f-52db-4fd1-bceb-0e57287722e4', '63405921850', '22238844-c804-4e8e-aee3-43d6778442b1');
INSERT INTO Apoiador_Campanha
VALUES ('e38a8b10-d849-449c-8ec2-02d36d230d23', '71027335911', '2c8a7bda-c9e1-4ba1-a140-1fef4af0900b');
INSERT INTO Apoiador_Campanha
VALUES ('95096071-49b8-41ab-97bb-9eccbe5bac34', '50921300621', '97516f6f-4280-46f7-aad0-363a36766cb1');
INSERT INTO Apoiador_Campanha
VALUES ('49e83525-834a-4bc7-b08a-c9061456b1a2', '39709400143', '74cca90c-43ab-4571-8e7d-6ed3378f3f15');
INSERT INTO Apoiador_Campanha
VALUES ('29eada49-e5a9-4c52-8e4a-39b710ba4ac6', '33042951838', 'ac8340e0-f62e-47cf-a3cd-7194a6afa5bf');
INSERT INTO Apoiador_Campanha
VALUES ('4fcef15f-52db-4fd1-bceb-0e57287722e4', '64847709590', '813c52ec-5ee8-4b5f-9eba-99a79a785e11');
INSERT INTO Apoiador_Campanha
VALUES ('5992d3ca-7897-4472-be0b-b953af3af579', '32128272987', 'e7d9f52a-ff86-48ec-99ba-c777dd6f778d');
INSERT INTO Apoiador_Campanha
VALUES ('a8c9c6cb-4139-4d10-ae9b-df554da911fe', '64713757117', 'f668632d-82b6-4154-b9ee-88a2f41bd654');
INSERT INTO Apoiador_Campanha
VALUES ('c1a79efe-6456-4d31-a4e5-d11ad51a78cb', '17597543469', 'e3ccd2df-cf31-4dc2-a1e9-34dafe4b26d5');
INSERT INTO Apoiador_Campanha
VALUES ('4e9663f6-82d8-45e8-94bd-bac5938198e4', '14908314673', 'a155b5a9-8c5e-47dd-8e8b-04515039d10a');
INSERT INTO Apoiador_Campanha
VALUES ('9918b566-6aae-4840-b207-ef4bba5f97b8', '39709400143', '4d1e882e-9262-4038-a0ed-61c7d8b2b650');
INSERT INTO Apoiador_Campanha
VALUES ('eed2ed8e-35bf-4120-bcf7-7b46a0f4d579', '83682897023', 'ff0760e5-3062-4770-a12a-b1c53a68c7de');
INSERT INTO Apoiador_Campanha
VALUES ('ed2d6d75-a514-40dd-8bb3-a41b2a8ae291', '99693323471', '3e558b39-afa7-4172-84a2-ebb8fae35bc5');
INSERT INTO Apoiador_Campanha
VALUES ('4fcef15f-52db-4fd1-bceb-0e57287722e4', '49887565386', '42c45f89-5f27-47be-bced-02ead36c250c');
INSERT INTO Apoiador_Campanha
VALUES ('5992d3ca-7897-4472-be0b-b953af3af579', '49723011339', '52de8a78-08c2-49d5-ba43-c390fee8f254');
INSERT INTO Apoiador_Campanha
VALUES ('6fbb0c02-df96-4dff-8ef4-3865781bed0c', '36212424982', 'a2e4696e-5819-49da-b959-cf16d97794c5');
INSERT INTO Apoiador_Campanha
VALUES ('9918b566-6aae-4840-b207-ef4bba5f97b8', '44661063903', 'b437122a-32c9-4dde-a516-11d1a76d338a');
INSERT INTO Apoiador_Campanha
VALUES ('6f0fef58-d623-4cb9-b26e-eb7b80e8c217', '25392862658', '0654d45e-ca64-4527-af60-904e467d6b1e');
INSERT INTO Apoiador_Campanha
VALUES ('e3f842a5-e5c0-4e23-b907-6227186a52ab', '45448827098', '26d7cd0e-608f-4353-a16d-13f92ef78922');
INSERT INTO Apoiador_Campanha
VALUES ('e4190452-7b83-4953-a7a2-a0410b0a94b4', '26038876282', '9cf8572c-85f7-4df4-b60e-2a8c42cf1282');
INSERT INTO Apoiador_Campanha
VALUES ('29eada49-e5a9-4c52-8e4a-39b710ba4ac6', '16524949248', '639f2b7f-3768-4aa4-b3a6-555204d9ea55');
INSERT INTO Apoiador_Campanha
VALUES ('980ee312-f850-43d6-93ff-8b5bf963f636', '44538643399', '4c9d10ff-4f48-4dce-bc4b-98143d89d622');
INSERT INTO Apoiador_Campanha
VALUES ('7f456833-68b4-42be-9638-8d31c1dcb284', '48008790058', '782ef36f-236a-4dd3-aa19-f9f0bd61eb10');
INSERT INTO Apoiador_Campanha
VALUES ('7e4c6f05-7054-4db2-9641-c0c695cdbe12', '74589843200', '5499ba12-93eb-4f28-9030-e422e1ca641b');
INSERT INTO Apoiador_Campanha
VALUES ('6fbb0c02-df96-4dff-8ef4-3865781bed0c', '99514881155', '294c5d0e-6eac-4fdf-97ac-afb6002d9a7a');
INSERT INTO Apoiador_Campanha
VALUES ('f7048642-3a98-43d1-a4c9-43d0db8bddf4', '32466301082', '782ef36f-236a-4dd3-aa19-f9f0bd61eb10');
INSERT INTO Apoiador_Campanha
VALUES ('3e3e71bf-f0fe-4d02-af1a-d29c9636cfa1', '17049775347', '0a6cf2bd-3b84-4f47-befc-df22efaee320');
INSERT INTO Apoiador_Campanha
VALUES ('5863fe9d-2717-488e-9e23-bacc564b88ce', '55804576182', 'c5c2e08c-9d9f-4e72-9864-a8a2276d6078');
INSERT INTO Apoiador_Campanha
VALUES ('cb7e7f05-6cc9-4802-af54-e228ab26fad4', '48776552942', '39d1f0f1-5459-4a78-932a-867cc5b5878c');
INSERT INTO Apoiador_Campanha
VALUES ('233e7579-f95f-4f51-9551-3c47117e4e10', '50661863996', 'fcf65244-2aaa-4f3e-b7a9-b72e87cdf61a');
INSERT INTO Apoiador_Campanha
VALUES ('95096071-49b8-41ab-97bb-9eccbe5bac34', '93231366153', 'd5929beb-48cc-421e-8fe1-8adcacc67c26');
INSERT INTO Apoiador_Campanha
VALUES ('abd68967-ba77-40d4-83a7-d6d2ae397be1', '64280859939', '57cf0583-995e-452c-b883-44d4d2bcce6b');
INSERT INTO Apoiador_Campanha
VALUES ('5863fe9d-2717-488e-9e23-bacc564b88ce', '57607271133', '834d7b66-f257-4121-a4cd-a8fcfbd823f9');
INSERT INTO Apoiador_Campanha
VALUES ('777754cc-b140-4168-86e8-180476720db6', '32128272987', 'd590c3bc-a0e7-4e14-9603-734290d855d6');
INSERT INTO Apoiador_Campanha
VALUES ('e4190452-7b83-4953-a7a2-a0410b0a94b4', '61699634627', '57cca424-6f6c-4d4d-82c9-6b5ff1e74fa1');
INSERT INTO Apoiador_Campanha
VALUES ('019662fc-6911-4ffd-9027-e1c65381c212', '15407267932', 'de9f0e95-beac-4fd8-aa8c-ed28b4acdd75');
INSERT INTO Apoiador_Campanha
VALUES ('49e83525-834a-4bc7-b08a-c9061456b1a2', '48741819467', '3d838daf-b50f-434d-8a4d-733ac960fc56');
INSERT INTO Apoiador_Campanha
VALUES ('85f24004-f7fd-4000-acd1-0ade019d947b', '50921300621', 'abe02cd7-6f96-44da-8d97-058c8b364be6');
INSERT INTO Apoiador_Campanha
VALUES ('f7048642-3a98-43d1-a4c9-43d0db8bddf4', '82459476657', 'ebb36ef1-07a5-4104-83bd-68ce97ba041f');
INSERT INTO Apoiador_Campanha
VALUES ('233e7579-f95f-4f51-9551-3c47117e4e10', '54687466805', '1cc23bc0-6127-4d31-bf48-8b2994059939');
INSERT INTO Apoiador_Campanha
VALUES ('e4190452-7b83-4953-a7a2-a0410b0a94b4', '68331766016', '52baf9c0-a84a-465a-a289-b0ba450d1d21');
INSERT INTO Apoiador_Campanha
VALUES ('eed2ed8e-35bf-4120-bcf7-7b46a0f4d579', '91148870261', '406023d1-1277-460d-bb2d-a2d6f85252fe');
INSERT INTO Apoiador_Campanha
VALUES ('8703a49a-0644-40fd-a423-c59c5f515f77', '26766975226', 'cf214043-fccd-4982-ac53-ce54507a5e18');
INSERT INTO Apoiador_Campanha
VALUES ('7a133504-c609-4089-b2f4-e3d2080fdd00', '45746368169', '4c9d10ff-4f48-4dce-bc4b-98143d89d622');
INSERT INTO Apoiador_Campanha
VALUES ('87a81832-3d34-4864-8e94-d19f4d7d7cae', '44307413429', '3b4adc40-133e-4268-b397-0d58f9796cbe');
INSERT INTO Apoiador_Campanha
VALUES ('172aa6cb-deac-41a9-bf1f-da2b3e37d7ac', '98657625005', '907cbc21-fe24-4711-8a85-ba401e870971');
INSERT INTO Apoiador_Campanha
VALUES ('a6fa3e73-3b3d-47b6-8fa4-a6409c01240a', '54644412510', '0b9629e2-bc23-4389-b2da-21e3ff418a56');
INSERT INTO Apoiador_Campanha
VALUES ('4e9663f6-82d8-45e8-94bd-bac5938198e4', '58437837020', 'f0968330-20b4-4cca-939a-c514fe8ba825');
INSERT INTO Apoiador_Campanha
VALUES ('f0dc16c0-faa9-49e6-be7e-d013aecec2f7', '15702510098', '3a9cb203-bfbc-41fc-b7c3-1f7a01541d00');
INSERT INTO Apoiador_Campanha
VALUES ('3f33ff66-bb0c-48b0-a7e9-95b393126ac9', '93141531136', 'ebb36ef1-07a5-4104-83bd-68ce97ba041f');
INSERT INTO Apoiador_Campanha
VALUES ('1ea42961-8416-4334-b882-62feafc574b1', '85752784269', '1c2dc5b3-6710-4e04-8150-4d4c27c30e79');
INSERT INTO Apoiador_Campanha
VALUES ('e45c94b7-9e11-4b85-a5d5-8d4190260f5c', '53501761734', 'ebb36ef1-07a5-4104-83bd-68ce97ba041f');
INSERT INTO Apoiador_Campanha
VALUES ('e2c22394-e0b8-4d70-a25d-31f106cdd084', '58362277850', '37cad15d-6a34-4dbb-aa0a-71e82adca8b8');
INSERT INTO Apoiador_Campanha
VALUES ('a8c9c6cb-4139-4d10-ae9b-df554da911fe', '53378136730', 'a3b55b65-efc7-48f0-9c6b-92859cb10dab');
INSERT INTO Apoiador_Campanha
VALUES ('5014c0a3-c1e2-4c31-b201-3691d1da8216', '28842566022', '97516f6f-4280-46f7-aad0-363a36766cb1');
INSERT INTO Apoiador_Campanha
VALUES ('90c7027a-8c35-4abd-b7bb-879aa21458d3', '73767229476', 'fcf65244-2aaa-4f3e-b7a9-b72e87cdf61a');
INSERT INTO Apoiador_Campanha
VALUES ('64a950b3-44e1-4c1a-a4f3-d73cdf6f52d7', '54063647601', '5499ba12-93eb-4f28-9030-e422e1ca641b');
INSERT INTO Apoiador_Campanha
VALUES ('6fbb0c02-df96-4dff-8ef4-3865781bed0c', '37135223362', '272669e7-7493-418f-a622-00d75748f6f2');
INSERT INTO Apoiador_Campanha
VALUES ('b52bb575-a975-4e4c-a26b-e3295fc3905f', '21282850208', '7ddaa8fe-29f9-4c43-ac75-c3dcd030a9ca');
INSERT INTO Apoiador_Campanha
VALUES ('777754cc-b140-4168-86e8-180476720db6', '84767766646', 'a3add6b7-5a06-4639-bccf-bf7cad622250');
INSERT INTO Apoiador_Campanha
VALUES ('e4190452-7b83-4953-a7a2-a0410b0a94b4', '93420833500', 'a52ac019-a156-430c-97f9-96771e0dd475');
INSERT INTO Apoiador_Campanha
VALUES ('e154942d-3c0e-4cb3-acd1-b6987451c71b', '20370718555', 'afed7395-37f4-4d04-af9e-34a63982727b');
INSERT INTO Apoiador_Campanha
VALUES ('75c3d2b6-0862-4fd8-9703-e8cb672c84c9', '60620319524', '9ad04dcb-64ce-4ebe-82f5-2a10a3a40843');
INSERT INTO Apoiador_Campanha
VALUES ('b52bb575-a975-4e4c-a26b-e3295fc3905f', '20311489617', '07e539d9-369d-46f6-b249-f73bc79da5f5');
INSERT INTO Apoiador_Campanha
VALUES ('ef8b0d83-2585-4867-a2c3-b50fd19b35f8', '27861878091', '6c5e83c6-2fc6-44f5-8f04-188a62645bf0');
INSERT INTO Apoiador_Campanha
VALUES ('233e7579-f95f-4f51-9551-3c47117e4e10', '73725674431', 'a3add6b7-5a06-4639-bccf-bf7cad622250');
INSERT INTO Apoiador_Campanha
VALUES ('ef8b0d83-2585-4867-a2c3-b50fd19b35f8', '52024004105', 'fadd0750-3074-44c8-8dc6-5142a6fbcd9a');
INSERT INTO Apoiador_Campanha
VALUES ('f7048642-3a98-43d1-a4c9-43d0db8bddf4', '69452778594', '6d9e081a-565f-4eee-8992-3bdaa2ed2cf4');
INSERT INTO Apoiador_Campanha
VALUES ('975706f4-c4b9-4211-96e0-85e54a59f3d0', '43344490984', '0b9629e2-bc23-4389-b2da-21e3ff418a56');
INSERT INTO Apoiador_Campanha
VALUES ('c9b9cdb5-24ce-47c2-8084-94179c0ad109', '44661063903', '7ddaa8fe-29f9-4c43-ac75-c3dcd030a9ca');
INSERT INTO Apoiador_Campanha
VALUES ('911012ce-07b3-4793-8443-b9307d490f85', '91593408309', 'df8062eb-aa44-4306-91d5-42380c0ed1dd');
INSERT INTO Apoiador_Campanha
VALUES ('8703a49a-0644-40fd-a423-c59c5f515f77', '74909855965', '2a9a4267-8f54-4481-b5af-30db4871670e');
INSERT INTO Apoiador_Campanha
VALUES ('72a10e43-4ca1-40ae-a08f-67e8d5b463d7', '68522295455', 'b9957418-f6d0-4c83-9178-6b0975af3315');
INSERT INTO Apoiador_Campanha
VALUES ('4fcef15f-52db-4fd1-bceb-0e57287722e4', '35423602398', '4f1c68f4-1098-4154-a183-3bf32fb46b02');
INSERT INTO Apoiador_Campanha
VALUES ('8623fb61-0275-44e3-8c22-c88b4a497700', '83906174097', 'f348d10b-3674-4cb0-b490-3c2123b0ee03');
INSERT INTO Apoiador_Campanha
VALUES ('f0dc16c0-faa9-49e6-be7e-d013aecec2f7', '30228957973', 'd057beff-cfa3-42fb-960c-0bd71b5f670e');
INSERT INTO Apoiador_Campanha
VALUES ('e154942d-3c0e-4cb3-acd1-b6987451c71b', '96180057683', 'f94735ea-6c94-4bc9-b853-498fbe3fb8ed');
INSERT INTO Apoiador_Campanha
VALUES ('ea1ec8d1-7eba-4d92-8fbe-48efe28431f6', '78310490557', 'cf214043-fccd-4982-ac53-ce54507a5e18');
INSERT INTO Apoiador_Campanha
VALUES ('c5553153-7d3e-4cc7-84e4-43591d84d199', '15334344431', 'b4e7134f-657a-4d9e-9cbf-6efaadf2065c');
INSERT INTO Apoiador_Campanha
VALUES ('f7048642-3a98-43d1-a4c9-43d0db8bddf4', '37780293980', '18cb490d-c661-46ed-bfc3-9c5ac3a2988d');
INSERT INTO Apoiador_Campanha
VALUES ('c420a55b-837f-480e-9208-b527b95a30f5', '68321365918', '9ebb0892-f116-47c9-8c3c-79621186e93e');
INSERT INTO Apoiador_Campanha
VALUES ('c3c49906-a4e1-4007-83fb-1fcf86eb98d3', '94981895470', '440a79f2-ff61-48ab-a617-df3942665d6f');
INSERT INTO Apoiador_Campanha
VALUES ('e8c11ad3-094f-4366-8ee2-8f43ca6a7a96', '70565871405', '6df4504e-b88d-4f7f-b79e-b9e663c15cbf');
INSERT INTO Apoiador_Campanha
VALUES ('65c20bb9-98b6-43b7-9557-6dc29e5cb58f', '67214462850', '3145c110-c210-41fc-b3bc-c938e38cbe8d');
INSERT INTO Apoiador_Campanha
VALUES ('2a24189e-829f-470d-ada6-d91e339827e3', '90003691567', '907cbc21-fe24-4711-8a85-ba401e870971');
INSERT INTO Apoiador_Campanha
VALUES ('61638f40-1999-4dde-80ea-f02f5c256e60', '22994280902', 'dc41b2a9-f13a-4a61-8409-9bdc2396b793');
INSERT INTO Apoiador_Campanha
VALUES ('87a81832-3d34-4864-8e94-d19f4d7d7cae', '15051145425', 'e4e3f156-654c-4a28-b169-d5611004848e');
INSERT INTO Apoiador_Campanha
VALUES ('2a24189e-829f-470d-ada6-d91e339827e3', '78522324447', '1ca4e324-d621-42ae-8e53-d084fe1e58df');
INSERT INTO Apoiador_Campanha
VALUES ('777754cc-b140-4168-86e8-180476720db6', '65458204417', '4459792d-86d7-45b8-bd53-d78640095044');
INSERT INTO Apoiador_Campanha
VALUES ('cb7e7f05-6cc9-4802-af54-e228ab26fad4', '96130006720', '3171cb48-4c1a-4fa0-87d9-c1469131ae2c');


-- Insere Doadores de Campanha
INSERT INTO Doador_Campanha
VALUES ('8f433bfa-0f56-43e4-af7d-7717b669a123', '32995448785',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('83d5df3b-ffa9-4e24-8416-a585c0b4d5e2', NULL,
        '77712847450748');
INSERT INTO Doador_Campanha
VALUES ('1f2a3787-0d4d-4891-9763-f6052ee55b95', '72241387865',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('2fcd760e-9246-405c-82b1-82980a0c3225', NULL,
        '28033196062315');
INSERT INTO Doador_Campanha
VALUES ('9685c156-0f8c-4e57-93eb-b6ec38cfa35e', '27603935101',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('588bc67f-e59b-47dc-86b9-5e288fb01f76', '55183109673',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('11f335dd-0d29-4d1d-9328-0dfd0d4f17d3', NULL,
        '96948214077856');
INSERT INTO Doador_Campanha
VALUES ('11827962-55bd-4536-8dee-81624564b3ab', '61831559098',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('72778511-c6cc-4d53-b827-5befb16ba72f', NULL,
        '90903553622774');
INSERT INTO Doador_Campanha
VALUES ('61c6438a-f71f-410d-b018-dd1c0a60e9bf', '35126160527',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('e3b16cbd-aee5-4b57-a015-7a0bad968a3e', NULL,
        '79241707741748');
INSERT INTO Doador_Campanha
VALUES ('0423b0fe-8ba4-4813-b046-4884d3eccbfa', NULL,
        '73082725859712');
INSERT INTO Doador_Campanha
VALUES ('31e78a32-61e5-4497-87c9-061ca2f06259', '93725932575',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('9beebb8d-60f7-4aaf-b845-7d36623c7766', NULL,
        '30255417316220');
INSERT INTO Doador_Campanha
VALUES ('46da5b42-c0bb-4edc-907a-326188dba6c6', NULL,
        '42318984807934');
INSERT INTO Doador_Campanha
VALUES ('a51e4f71-d090-42b0-b37b-e730616f6c90', '48008790058',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('3828ce25-2cfc-4336-8214-30c175eae781', '48008790058',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('6e0a6ce9-f39a-4274-8982-8f842a81e046', NULL,
        '81057815854437');
INSERT INTO Doador_Campanha
VALUES ('8ef0f9c0-f164-4977-a9b8-a8a7cc2f59e5', NULL,
        '46660345706623');
INSERT INTO Doador_Campanha
VALUES ('b9527116-986b-450a-ab31-0ab943f303e5', NULL,
        '10244308065157');
INSERT INTO Doador_Campanha
VALUES ('cb01f0a2-89ea-4c25-9341-5228f929eb19', NULL,
        '39349931811448');
INSERT INTO Doador_Campanha
VALUES ('0abac055-163f-42e2-8712-e47751db6267', '43359677735',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('e53d183f-d345-450e-a1e8-6d5c951e6883', '69028166278',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('86d5ea9f-90c2-466a-97fa-be9aa59ca9be', NULL,
        '76653378766495');
INSERT INTO Doador_Campanha
VALUES ('1d545a7e-1180-40ef-a2b4-feb4a38daefc', '27934283968',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('bb773f6d-3e92-4151-a6ee-59437bd2e55c', NULL,
        '19849239769391');
INSERT INTO Doador_Campanha
VALUES ('aa1572cc-1cde-434f-83d3-f1cd287d8856', NULL,
        '97632482373155');
INSERT INTO Doador_Campanha
VALUES ('e1a8e9ac-3a9c-4024-a208-4daf52df25f5', '59028294656',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('ae119550-5fe1-48ea-9383-928c40f25d46', NULL,
        '46829371876083');
INSERT INTO Doador_Campanha
VALUES ('7d2942f3-52da-445d-8caa-3f92bad84c0f', '32128272987',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('86c8e2b8-7f17-4066-9dcc-4775eb677a31', NULL,
        '12075403900817');
INSERT INTO Doador_Campanha
VALUES ('0b6c8d73-65e5-4684-963a-7b95306c1545', NULL,
        '24420424113050');
INSERT INTO Doador_Campanha
VALUES ('147a2b1b-12f9-417e-8e3f-88dcd70efa28', NULL,
        '74114042476285');
INSERT INTO Doador_Campanha
VALUES ('44fab8db-495a-4ce8-802f-3ea865cbafea', NULL,
        '87041515104938');
INSERT INTO Doador_Campanha
VALUES ('a8e61822-7bf5-40f9-b344-b47eadc97a27', '77054765247',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('1c8e036d-36ef-4c71-9c9b-2b0946e962b6', NULL,
        '70780901336111');
INSERT INTO Doador_Campanha
VALUES ('d1924713-dc4d-477f-812e-1c08bb343190', '73767229476',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('1474d130-72cd-4dd6-b419-04987bfbc870', NULL,
        '71470310441218');
INSERT INTO Doador_Campanha
VALUES ('0434d89c-b653-4008-a8fc-365a06993f91', '21487003488',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('a90fd8d8-50ed-425d-aea0-42052731a813', NULL,
        '79311056989245');
INSERT INTO Doador_Campanha
VALUES ('66c0603f-5f3d-474a-9598-1e3000500751', NULL,
        '84487225960474');
INSERT INTO Doador_Campanha
VALUES ('4a85b76b-999d-48aa-8be1-87354afc02cf', NULL,
        '54408071066718');
INSERT INTO Doador_Campanha
VALUES ('fe4b2b7c-0be3-4971-b21e-6ed97bf8d26e', NULL,
        '24339883034117');
INSERT INTO Doador_Campanha
VALUES ('cf1444fb-1f90-423a-b424-648549a3c426', '46389898404',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('bfdc1000-4f79-4a15-b2de-67263894907a', NULL,
        '43052528447005');
INSERT INTO Doador_Campanha
VALUES ('b4f6b4eb-a424-47d1-871f-88527aa58ff0', NULL,
        '36363636129535');
INSERT INTO Doador_Campanha
VALUES ('0f345e89-a7c3-4d8a-bde7-3f4a492e98e3', NULL,
        '59545718193985');
INSERT INTO Doador_Campanha
VALUES ('a0591bc5-b676-4806-931d-9095022f7bf3', '16524949248',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('a03526ba-7c32-4b0d-889f-33e2f9b0f60b', NULL,
        '44568887359928');
INSERT INTO Doador_Campanha
VALUES ('48894464-4500-4fcd-bfe0-5b531c709a33', '25962785638',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('7ebfb333-df42-4c80-964d-25d3c8abb381', NULL,
        '89859514324925');
INSERT INTO Doador_Campanha
VALUES ('785570ba-fee1-4034-bc19-0142877bdb01', NULL,
        '78626642555464');
INSERT INTO Doador_Campanha
VALUES ('b555da04-7eac-4207-bf43-ade727eac012', NULL,
        '39895351093728');
INSERT INTO Doador_Campanha
VALUES ('4234ec2b-017b-46a0-8913-0bc68a91b6ce', NULL,
        '10197527972050');
INSERT INTO Doador_Campanha
VALUES ('4ef22a20-992c-4966-9733-6ec1c61f3f4c', NULL,
        '94509106553159');
INSERT INTO Doador_Campanha
VALUES ('16631993-ff29-4121-95ab-ce4cfe799649', '49723011339',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('558a29e7-0844-4777-87bd-b561c5d8cfba', '24663187770',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('b9b8b533-e43a-45cc-9684-8d83ef8df837', NULL,
        '65680871729273');
INSERT INTO Doador_Campanha
VALUES ('80717ab9-35cd-452c-bd31-c72fb8def0c7', NULL,
        '61906987405382');
INSERT INTO Doador_Campanha
VALUES ('940cae35-7f04-4c5d-97b2-34edb5dc7753', '23680543084',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('de62e4cf-f6a7-449f-beeb-3707876c8d08', '42713638902',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('d12ba51d-426f-4a26-8d59-b417e2e6574d', NULL,
        '22824832892511');
INSERT INTO Doador_Campanha
VALUES ('1ea8b95b-f371-4a29-8350-a9e32b3d5b19', '55317056111',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('2134cafe-39c9-4ef4-9bda-2e67d69296a7', '40069712323',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('10cdf2ab-21cc-4b42-8fd3-911f3029cc56', NULL,
        '90511627963278');
INSERT INTO Doador_Campanha
VALUES ('af6962e3-72e4-403d-822e-936805b93d17', NULL,
        '11631811079569');
INSERT INTO Doador_Campanha
VALUES ('56761ff6-0d55-42a1-96c8-e7435fc0e5bc', '25330412890',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('741b84ee-6c6b-47c2-b50c-d418d86371a5', '35410163693',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('8c1fcbd2-55b6-4083-8175-b104c83770a9', '99514881155',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('b6cb6744-4009-40a0-bb7a-9187fcd9ea5e', NULL,
        '26304426772985');
INSERT INTO Doador_Campanha
VALUES ('12740ffb-966c-40b1-abbd-130e39d8d79c', NULL,
        '97840535354334');
INSERT INTO Doador_Campanha
VALUES ('813bb9da-8d0d-49f1-ab98-f152983dd6c7', NULL,
        '76843197084963');
INSERT INTO Doador_Campanha
VALUES ('4608f34e-4e9d-4c50-a77a-c9d0d0e4500c', NULL,
        '38353442547377');
INSERT INTO Doador_Campanha
VALUES ('b3466716-3bbe-4cf2-a2b9-8d658251fcbf', NULL,
        '77042108217719');
INSERT INTO Doador_Campanha
VALUES ('46eef9f4-16ed-43c1-bd79-8654c049a371', '70565871405',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('bd32d695-0b48-4700-a9b3-df25dd1a09be', '59156701033',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('f1946f45-5f93-4586-9d4a-ef6c5b618acf', '27861878091',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('da043168-f934-4951-8b3a-3eb5e94a8361', '59043336380',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('8be373d0-dbff-424d-a911-ce292da7a3c7', NULL,
        '89140356630086');
INSERT INTO Doador_Campanha
VALUES ('d1332ce7-ff3a-4daf-910b-dfdbd6710321', NULL,
        '80342628562357');
INSERT INTO Doador_Campanha
VALUES ('7fb92c16-8725-4b11-87ba-9523795aca44', '62156000735',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('dba029a4-9bb9-4237-8fe0-522e437b5c3d', NULL,
        '49390384585130');
INSERT INTO Doador_Campanha
VALUES ('4a7847ab-f1e9-43dd-a603-1d123367459c', NULL,
        '80429028926882');
INSERT INTO Doador_Campanha
VALUES ('e35d38d7-b9ab-4c9d-9d93-e6332f198d44', '38390440184',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('bc531d6a-677d-4053-b430-ec1f6fb2219e', '87764965905',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('45707ef0-e555-4482-9633-ca1e5252d2d3', '65680290067',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('5f46b047-bbe5-4366-a00f-1db6e4959886', NULL,
        '42600139887072');
INSERT INTO Doador_Campanha
VALUES ('bcbfb096-34d4-46cd-a9bd-b415de0d0639', '44674791889',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('c112235a-f955-4fbd-85dc-7d0ee7ccd3ae', '51026479906',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('1580c3fa-2a15-42d4-929c-4ef025a2d083', '99311338330',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('a5faae26-8140-493d-a9c2-e7fa1bd5ccfb', '22994280902',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('d8cb4455-e06f-43dc-ae75-7cd8c2db9a1b', NULL,
        '68322291637305');
INSERT INTO Doador_Campanha
VALUES ('9e1110ee-9a7e-42e8-921a-33dcd1adb68f', NULL,
        '47066753786057');
INSERT INTO Doador_Campanha
VALUES ('972dfb1a-22f4-4943-abbb-ffe57bbdd950', NULL,
        '89215457581449');
INSERT INTO Doador_Campanha
VALUES ('d274d0fb-2a03-4cdf-93c7-bc6a8517d624', '84332452986',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('3cc53c33-7938-4126-a5b4-9d34e6a4bbbf', NULL,
        '72979406665544');
INSERT INTO Doador_Campanha
VALUES ('5814beca-6685-4dc8-be53-3f54c9c80244', NULL,
        '98281319881789');
INSERT INTO Doador_Campanha
VALUES ('3ce2e7f0-6b66-4ffa-b9ad-eef23b2fbd4c', NULL,
        '77853996960911');
INSERT INTO Doador_Campanha
VALUES ('9a145b03-ffdb-4a27-96bf-d6b8236d4732', NULL,
        '33881479087285');
INSERT INTO Doador_Campanha
VALUES ('cf2e76a6-3896-4a9b-b9be-6e3418414d19', NULL,
        '24966481467708');
INSERT INTO Doador_Campanha
VALUES ('7a671348-62bc-4cfd-8842-15770e069655', NULL,
        '30756905619055');
INSERT INTO Doador_Campanha
VALUES ('05896118-ffb3-4a62-9588-26af8fb254bb', '99514881155',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('40c4b4db-adb2-4898-99be-f2c1460168f4', '14897848735',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('f5b296ee-dd81-4c95-afc6-a4917b86122b', '47530116646',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('8f3b0288-74eb-4b5f-87e8-e47ac48de27f', NULL,
        '56652924884110');
INSERT INTO Doador_Campanha
VALUES ('79ede16f-7dd3-48fb-a3e5-2dea4542ea96', NULL,
        '66330596022307');
INSERT INTO Doador_Campanha
VALUES ('a2c3e829-a702-4b38-9c77-72c1ae2291b4', '27397945995',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('d1eed142-7371-4a5e-952b-ad518198fc86', NULL,
        '15494311356451');
INSERT INTO Doador_Campanha
VALUES ('c29c8f1c-8a47-4f3e-8e20-8d619c8a6cff', '58362277850',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('75f0e3d1-7254-4fe4-913e-a598e89364a8', '64713757117',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('5d7e7d61-73b7-4622-bbe3-056127a9d2a7', '86638707953',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('34a36766-ab86-4dd4-bcc9-38e2c8f1156f', '23576477523',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('4afa1504-62d4-41ae-a3f8-4c87d265d67b', NULL,
        '62535189234185');
INSERT INTO Doador_Campanha
VALUES ('6a04619c-b013-4c1d-ab8b-880ded2088e0', '73645120004',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('5297f8ca-5191-4c0c-b7fd-2cde5606ed47', '51051183596',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('6d3e5baa-9be4-49c1-9007-8558b0ed2277', NULL,
        '65026521359104');
INSERT INTO Doador_Campanha
VALUES ('3d07c4aa-d7ab-43ff-944e-b405bd6d83df', NULL,
        '65324003128334');
INSERT INTO Doador_Campanha
VALUES ('59581d97-0844-409a-a8ca-783e274f858d', NULL,
        '84313352662138');
INSERT INTO Doador_Campanha
VALUES ('fbf3c673-942a-46af-a9f6-bd50d435456b', '15407267932',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('9c32eb10-f3be-41db-9b1d-f658a4ef2351', '48741819467',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('2a97996c-3004-43b0-8d76-9ea6233823a3', '34528599961',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('e7c71688-1138-4892-a572-a1b78c0f6de1', '68767157313',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('f92763d8-0a6c-4c6a-9eb9-b3341a3a80d1', NULL,
        '22726485466118');
INSERT INTO Doador_Campanha
VALUES ('e12f895f-2477-4aad-81eb-e51011694736', '53378136730',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('b0de3765-e5d9-4f94-84e7-284a568e6035', '60893714134',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('12df605e-ee95-4cb0-8fdb-a4480b5c7f72', '61699634627',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('5abb68ea-dfd3-4e7e-b7ff-76faea265245', NULL,
        '74669056166894');
INSERT INTO Doador_Campanha
VALUES ('673af975-8411-4ceb-820b-2a5203bdbca3', NULL,
        '83448990711476');
INSERT INTO Doador_Campanha
VALUES ('9e1cf7d0-3585-4fb3-811c-9c678453168c', '41829273644',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('62162693-c78d-412b-85f2-7ce9b87cb016', NULL,
        '36997400943655');
INSERT INTO Doador_Campanha
VALUES ('c968d9b2-6a0d-48bd-865e-8b9c21beeca1', '56133283516',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('db739a87-c99d-43d2-bdc1-90de24cb1905', NULL,
        '61446458885911');
INSERT INTO Doador_Campanha
VALUES ('0bc1ab04-616d-4bd9-9f37-18ca61aae5bf', NULL,
        '39960084552876');
INSERT INTO Doador_Campanha
VALUES ('ca4fc7cf-29a9-455e-80b0-92cfc0e6659b', '64713757117',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('5795dabc-a0fe-44da-bd4b-9a4303b3fbb7', NULL,
        '41020243822131');
INSERT INTO Doador_Campanha
VALUES ('b09b425c-6788-4c29-95f0-0bd608ce4d59', NULL,
        '91969747883267');
INSERT INTO Doador_Campanha
VALUES ('01de9f04-1c61-421c-a97e-858d115e8dcf', NULL,
        '64337659634184');
INSERT INTO Doador_Campanha
VALUES ('17b381cd-3ad4-46a2-8cb2-ee2484797a6b', NULL,
        '40155156920664');
INSERT INTO Doador_Campanha
VALUES ('fe91ae22-1349-4612-8478-7ab33e94f753', '21487003488',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('6b2996e3-d506-416c-928f-9456cac18c1c', NULL,
        '71597856436856');
INSERT INTO Doador_Campanha
VALUES ('6914072e-06b1-46c8-a4c9-d62fe1ae5839', NULL,
        '68697035526856');
INSERT INTO Doador_Campanha
VALUES ('3d7f3e00-d68b-455f-9295-895c43092e21', NULL,
        '80343982554040');
INSERT INTO Doador_Campanha
VALUES ('2d2a5f60-dc74-42ca-aeee-e7af7d12c595', '76646342640',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('5ae1e1cf-503a-4299-8c54-7b207b3175b6', '90003691567',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('3b6c0488-0ba2-4557-981a-2983c2f823bd', '43359677735',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('a01c9207-ac01-4502-879d-36e2904b07da', '13407645802',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('e7969682-0ca1-4d9d-aa56-04424f3c316c', '50661863996',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('ea8b08f6-a5c3-4d93-9ca6-e301b65007e2', '25392862658',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('44c77c51-2199-4e8b-a9de-93b531a5b0ad', NULL,
        '36442271855194');
INSERT INTO Doador_Campanha
VALUES ('ea9c1a9e-c07a-4b66-88f9-ac10455ab6a1', NULL,
        '27169103547930');
INSERT INTO Doador_Campanha
VALUES ('a646407e-e49a-4dc3-9664-aa5c1ae9634e', NULL,
        '59907523756846');
INSERT INTO Doador_Campanha
VALUES ('1d41dbd8-d3b4-4177-a077-ed264e895486', '22430202225',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('3c1493ce-1a7e-46cc-8795-e9800e502281', NULL,
        '29371914535295');
INSERT INTO Doador_Campanha
VALUES ('5bb803e2-0ebe-4439-bd6b-28e1c517b74d', NULL,
        '92596961087547');
INSERT INTO Doador_Campanha
VALUES ('000d96d7-7195-46ce-8ecf-ecd0c61f0497', '82049451954',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('f2f03fd1-c3d2-408c-99ff-86e006142122', '80154288623',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('5a8b7b94-922b-4e48-bcee-f0af2f22bf70', '48246632281',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('3171f4da-9671-4b9b-9f52-33b737a0b1e6', NULL,
        '18841846864670');
INSERT INTO Doador_Campanha
VALUES ('c3a7c3d0-bc86-4168-9346-a6e5818cc9b4', NULL,
        '81903787846677');
INSERT INTO Doador_Campanha
VALUES ('7be8fe52-e173-4ab2-b316-c68679d5c351', '40909250010',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('faa8129b-72c3-4f87-a183-74d3dab322b4', '30848156486',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('b41c4424-4dda-44d1-8fcd-12ab3c68b3fe', NULL,
        '28473056841176');
INSERT INTO Doador_Campanha
VALUES ('07695413-d750-4a98-99dd-169d90b1ea2a', NULL,
        '51484434909652');
INSERT INTO Doador_Campanha
VALUES ('1bc134b8-f077-42f8-a3bf-ab779cd12a1e', NULL,
        '55462824134156');
INSERT INTO Doador_Campanha
VALUES ('6db06b25-d9b7-4723-8497-16464a6152c5', NULL,
        '33252758816815');
INSERT INTO Doador_Campanha
VALUES ('70ef348e-8ca8-4314-bb3e-4e505c2b1c53', NULL,
        '62019063823390');
INSERT INTO Doador_Campanha
VALUES ('e348bb2a-ebb8-4a52-b7d0-932c7c7e8857', NULL,
        '16033794952090');
INSERT INTO Doador_Campanha
VALUES ('92cce294-5940-42ba-a735-d8d6840da114', '31959316115',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('f2eaa20a-dfa3-401d-bdc8-dbafbb9459ec', NULL,
        '38310905939433');
INSERT INTO Doador_Campanha
VALUES ('382e4669-fbfb-44ad-a70f-df893b34f8e2', NULL,
        '87099012006074');
INSERT INTO Doador_Campanha
VALUES ('4111d6d3-66e3-45b0-a8b0-3e4f1dae37b3', NULL,
        '46096739978529');
INSERT INTO Doador_Campanha
VALUES ('2ac4b7c0-ef80-4db1-b540-db12daa52821', NULL,
        '36340875804889');
INSERT INTO Doador_Campanha
VALUES ('390156a2-9266-4b2d-8ca4-9c3b7b106c52', '37254095533',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('bde9f447-4361-4088-8bfd-13729183fba8', NULL,
        '16080173908267');
INSERT INTO Doador_Campanha
VALUES ('2048ff1a-9f0e-4249-be44-31536650af1c', '20972278714',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('4098127e-455b-404b-bb7d-848509daf857', NULL,
        '32828536783345');
INSERT INTO Doador_Campanha
VALUES ('4266de86-b231-4da5-a0bc-506fa1d5765c', NULL,
        '23807422572281');
INSERT INTO Doador_Campanha
VALUES ('3661d524-a551-42bc-ae9d-0e96c5070158', '56626854483',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('04aed91e-396a-4d50-a676-c0801c4aae7e', '25962785638',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('c429f430-5c05-4e30-a7e2-2d65651d7b94', '33932909250',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('ff28af53-2076-4911-aef3-f829aca38d79', '48673702988',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('279fe8e1-cc5e-43e4-a389-2badc0f058b3', '82171370822',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('be06bd19-f384-462c-a657-0ab400f50511', '49141727066',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('6e2b636f-6a66-45f3-adec-9d2174dab697', NULL,
        '13584328631404');
INSERT INTO Doador_Campanha
VALUES ('f11770ad-caa9-47d6-9a45-51ae0690c52f', NULL,
        '80570955229923');
INSERT INTO Doador_Campanha
VALUES ('77d61626-d300-4daf-b104-a7d0a306825e', NULL,
        '14748276355676');
INSERT INTO Doador_Campanha
VALUES ('396f34d8-b3f5-4ee6-b579-36abf42bc707', NULL,
        '42550319132860');
INSERT INTO Doador_Campanha
VALUES ('116c3cba-a218-4ee9-b3d1-4f2bea422d10', '77137697788',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('41586493-0615-4147-bfd8-dd33488dd5af', NULL,
        '82117493562400');
INSERT INTO Doador_Campanha
VALUES ('7f2d407d-c239-48ed-8305-e48cb31b1db8', NULL,
        '47981626216787');
INSERT INTO Doador_Campanha
VALUES ('5991106a-1dac-4f35-a552-2b054a669a67', '21849655245',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('54055335-0047-4043-bcaa-04cedfcf0a4e', NULL,
        '48667714558541');
INSERT INTO Doador_Campanha
VALUES ('992a1e28-d929-475a-a05f-7e1fdb0ed36e', '35883675508',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('7732c810-ea7a-4193-8968-c79a0f446cdb', NULL,
        '50633510889019');
INSERT INTO Doador_Campanha
VALUES ('dc47c8de-dac5-45a6-978c-f74210f97960', '97264050580',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('1d3772ad-f947-44af-b1f2-01f4f3f8a505', NULL,
        '95581423626281');
INSERT INTO Doador_Campanha
VALUES ('499b830a-8e7b-4c3e-9194-2954fd57774e', NULL,
        '25694177241530');
INSERT INTO Doador_Campanha
VALUES ('2fe2e1a6-a853-4d93-8e00-2ceaa9484020', '12399218089',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('89c55803-ee6f-4d64-a56a-e2b33c351fe2', '74573730144',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('c7af32c5-2268-4e28-a764-16bf5d354e72', '69571564621',
        NULL);


-- Insere Doacao Candidatura
INSERT INTO Doacao_Candidatura
VALUES ('8f433bfa-0f56-43e4-af7d-7717b669a123', '3a28fd22-f3ee-4a81-8885-1a7db6aed624', 35715);
INSERT INTO Doacao_Candidatura
VALUES ('83d5df3b-ffa9-4e24-8416-a585c0b4d5e2', 'ba120830-08ca-4719-b56a-ab77a191bb5b', 80993);
INSERT INTO Doacao_Candidatura
VALUES ('1f2a3787-0d4d-4891-9763-f6052ee55b95', 'fbc0eb50-4019-4da5-b2d7-161c9293706e', 55202);
INSERT INTO Doacao_Candidatura
VALUES ('2fcd760e-9246-405c-82b1-82980a0c3225', '4104cee5-6e88-414a-8bd7-ec6cd7d6ae62', 48682);
INSERT INTO Doacao_Candidatura
VALUES ('9685c156-0f8c-4e57-93eb-b6ec38cfa35e', 'bbb569b0-2bbc-40c4-ac37-50f7794f4d21', 86374);
INSERT INTO Doacao_Candidatura
VALUES ('588bc67f-e59b-47dc-86b9-5e288fb01f76', 'dc41b2a9-f13a-4a61-8409-9bdc2396b793', 26888);
INSERT INTO Doacao_Candidatura
VALUES ('11f335dd-0d29-4d1d-9328-0dfd0d4f17d3', '9cc9ac5b-b66a-4b29-858e-005244337c95', 86709);
INSERT INTO Doacao_Candidatura
VALUES ('11827962-55bd-4536-8dee-81624564b3ab', '42c45f89-5f27-47be-bced-02ead36c250c', 33585);
INSERT INTO Doacao_Candidatura
VALUES ('72778511-c6cc-4d53-b827-5befb16ba72f', '3b3d1e33-a62b-431c-a761-c24e8cf602e3', 67868);
INSERT INTO Doacao_Candidatura
VALUES ('61c6438a-f71f-410d-b018-dd1c0a60e9bf', 'ecba16c3-3457-4f06-be22-4af156f4cefe', 88250);
INSERT INTO Doacao_Candidatura
VALUES ('e3b16cbd-aee5-4b57-a015-7a0bad968a3e', '827d9967-cc68-4272-9daf-14e8089f9e76', 63939);
INSERT INTO Doacao_Candidatura
VALUES ('0423b0fe-8ba4-4813-b046-4884d3eccbfa', '37dd2db7-4c7e-43e7-a839-dd1c2f97f223', 13165);
INSERT INTO Doacao_Candidatura
VALUES ('31e78a32-61e5-4497-87c9-061ca2f06259', '786b63c3-7d37-448f-bbf1-5bde135f008e', 47884);
INSERT INTO Doacao_Candidatura
VALUES ('9beebb8d-60f7-4aaf-b845-7d36623c7766', '74cca90c-43ab-4571-8e7d-6ed3378f3f15', 98843);
INSERT INTO Doacao_Candidatura
VALUES ('46da5b42-c0bb-4edc-907a-326188dba6c6', 'e2dac658-9a73-4a91-81d4-625dbbcb9d7e', 85669);
INSERT INTO Doacao_Candidatura
VALUES ('a51e4f71-d090-42b0-b37b-e730616f6c90', '29ec0277-6754-445c-a254-3b7c631dbaf8', 19570);
INSERT INTO Doacao_Candidatura
VALUES ('3828ce25-2cfc-4336-8214-30c175eae781', 'bc1b7865-785d-4ff7-bf9c-316005f2a822', 87639);
INSERT INTO Doacao_Candidatura
VALUES ('6e0a6ce9-f39a-4274-8982-8f842a81e046', 'cd73e0d8-a5a0-4965-b67f-fcb96082944b', 86736);
INSERT INTO Doacao_Candidatura
VALUES ('8ef0f9c0-f164-4977-a9b8-a8a7cc2f59e5', '77be7a80-b283-4dc5-903a-e10ca5b7b63e', 71467);
INSERT INTO Doacao_Candidatura
VALUES ('b9527116-986b-450a-ab31-0ab943f303e5', 'd5929beb-48cc-421e-8fe1-8adcacc67c26', 9255);
INSERT INTO Doacao_Candidatura
VALUES ('cb01f0a2-89ea-4c25-9341-5228f929eb19', '616a8426-048b-4dd0-8875-a53c517be974', 12796);
INSERT INTO Doacao_Candidatura
VALUES ('0abac055-163f-42e2-8712-e47751db6267', 'a1a4ffab-a551-40fc-811f-02470eaf8aa8', 18624);
INSERT INTO Doacao_Candidatura
VALUES ('e53d183f-d345-450e-a1e8-6d5c951e6883', '616a8426-048b-4dd0-8875-a53c517be974', 2481);
INSERT INTO Doacao_Candidatura
VALUES ('86d5ea9f-90c2-466a-97fa-be9aa59ca9be', '9cc9ac5b-b66a-4b29-858e-005244337c95', 72726);
INSERT INTO Doacao_Candidatura
VALUES ('1d545a7e-1180-40ef-a2b4-feb4a38daefc', '40181dc0-82fc-4ba0-8811-13410312a1f8', 53353);
INSERT INTO Doacao_Candidatura
VALUES ('bb773f6d-3e92-4151-a6ee-59437bd2e55c', 'e6d2d42a-1a5a-47f6-9993-ccdb98d51eb3', 29747);
INSERT INTO Doacao_Candidatura
VALUES ('aa1572cc-1cde-434f-83d3-f1cd287d8856', 'bcc39841-b25f-401b-848e-edd57d826604', 83999);
INSERT INTO Doacao_Candidatura
VALUES ('e1a8e9ac-3a9c-4024-a208-4daf52df25f5', '04cae94e-ec38-4f04-83c6-90db81370973', 95687);
INSERT INTO Doacao_Candidatura
VALUES ('ae119550-5fe1-48ea-9383-928c40f25d46', '5842fb88-5e24-4dfb-92da-70dbbf28ae85', 40937);
INSERT INTO Doacao_Candidatura
VALUES ('7d2942f3-52da-445d-8caa-3f92bad84c0f', '9cf8572c-85f7-4df4-b60e-2a8c42cf1282', 55921);
INSERT INTO Doacao_Candidatura
VALUES ('86c8e2b8-7f17-4066-9dcc-4775eb677a31', 'a122384e-8cce-4619-8f76-d1441f1d0cea', 77713);
INSERT INTO Doacao_Candidatura
VALUES ('0b6c8d73-65e5-4684-963a-7b95306c1545', 'ed676738-4ee2-4a94-b49e-3ea0d057cc15', 54245);
INSERT INTO Doacao_Candidatura
VALUES ('147a2b1b-12f9-417e-8e3f-88dcd70efa28', 'bef7c04c-bc0b-4136-8c5f-fdf8d2652ac6', 31213);
INSERT INTO Doacao_Candidatura
VALUES ('44fab8db-495a-4ce8-802f-3ea865cbafea', '3a28fd22-f3ee-4a81-8885-1a7db6aed624', 94331);
INSERT INTO Doacao_Candidatura
VALUES ('a8e61822-7bf5-40f9-b344-b47eadc97a27', '86c5373f-a37b-4d09-97c7-0a0da4c6ae82', 37156);
INSERT INTO Doacao_Candidatura
VALUES ('1c8e036d-36ef-4c71-9c9b-2b0946e962b6', '30d3e491-cf0c-4b40-863d-0487d785dea4', 73043);
INSERT INTO Doacao_Candidatura
VALUES ('d1924713-dc4d-477f-812e-1c08bb343190', '26d7cd0e-608f-4353-a16d-13f92ef78922', 54015);
INSERT INTO Doacao_Candidatura
VALUES ('1474d130-72cd-4dd6-b419-04987bfbc870', '616a8426-048b-4dd0-8875-a53c517be974', 85260);
INSERT INTO Doacao_Candidatura
VALUES ('0434d89c-b653-4008-a8fc-365a06993f91', '8658829e-b5e0-4fe1-b3b2-73a5100a152f', 28358);
INSERT INTO Doacao_Candidatura
VALUES ('a90fd8d8-50ed-425d-aea0-42052731a813', 'bab4f237-a893-4768-9c9f-78e299c73395', 34173);
INSERT INTO Doacao_Candidatura
VALUES ('66c0603f-5f3d-474a-9598-1e3000500751', '640eb4c6-6d24-4a37-abad-9b9b644e3955', 17688);
INSERT INTO Doacao_Candidatura
VALUES ('4a85b76b-999d-48aa-8be1-87354afc02cf', '813c52ec-5ee8-4b5f-9eba-99a79a785e11', 69545);
INSERT INTO Doacao_Candidatura
VALUES ('fe4b2b7c-0be3-4971-b21e-6ed97bf8d26e', 'e6d53dbc-42d5-4631-a0c3-cddf2e8be77b', 33264);
INSERT INTO Doacao_Candidatura
VALUES ('cf1444fb-1f90-423a-b424-648549a3c426', '2ba7d78d-cec0-46d2-98cd-da240cd18f4a', 57121);
INSERT INTO Doacao_Candidatura
VALUES ('bfdc1000-4f79-4a15-b2de-67263894907a', '41611392-62a0-424e-b60a-a7ac2594f571', 91311);
INSERT INTO Doacao_Candidatura
VALUES ('b4f6b4eb-a424-47d1-871f-88527aa58ff0', '5499ba12-93eb-4f28-9030-e422e1ca641b', 52115);
INSERT INTO Doacao_Candidatura
VALUES ('0f345e89-a7c3-4d8a-bde7-3f4a492e98e3', '52de8a78-08c2-49d5-ba43-c390fee8f254', 28456);
INSERT INTO Doacao_Candidatura
VALUES ('a0591bc5-b676-4806-931d-9095022f7bf3', 'fcf65244-2aaa-4f3e-b7a9-b72e87cdf61a', 40301);
INSERT INTO Doacao_Candidatura
VALUES ('a03526ba-7c32-4b0d-889f-33e2f9b0f60b', 'ecba16c3-3457-4f06-be22-4af156f4cefe', 67593);
INSERT INTO Doacao_Candidatura
VALUES ('48894464-4500-4fcd-bfe0-5b531c709a33', 'e4e3f156-654c-4a28-b169-d5611004848e', 9801);
INSERT INTO Doacao_Candidatura
VALUES ('7ebfb333-df42-4c80-964d-25d3c8abb381', '8a0fb414-58c3-487c-88ab-bc3787cad8bf', 23789);
INSERT INTO Doacao_Candidatura
VALUES ('785570ba-fee1-4034-bc19-0142877bdb01', '9ee749ba-698b-4b79-bf82-6a2f9fe5a6cc', 25117);
INSERT INTO Doacao_Candidatura
VALUES ('b555da04-7eac-4207-bf43-ade727eac012', '9ebb0892-f116-47c9-8c3c-79621186e93e', 48501);
INSERT INTO Doacao_Candidatura
VALUES ('4234ec2b-017b-46a0-8913-0bc68a91b6ce', '3fce514b-d035-473e-89b9-90bc8bcbc5eb', 54028);
INSERT INTO Doacao_Candidatura
VALUES ('4ef22a20-992c-4966-9733-6ec1c61f3f4c', 'e298afbd-dfe4-4bb3-af93-e80d852d305b', 89696);
INSERT INTO Doacao_Candidatura
VALUES ('16631993-ff29-4121-95ab-ce4cfe799649', '616a8426-048b-4dd0-8875-a53c517be974', 8500);
INSERT INTO Doacao_Candidatura
VALUES ('558a29e7-0844-4777-87bd-b561c5d8cfba', 'dfed5950-b082-402f-9c77-8920121f9e05', 92746);
INSERT INTO Doacao_Candidatura
VALUES ('b9b8b533-e43a-45cc-9684-8d83ef8df837', '8dcc3d94-22e4-449b-b282-526679f164e1', 35413);
INSERT INTO Doacao_Candidatura
VALUES ('80717ab9-35cd-452c-bd31-c72fb8def0c7', 'bbb569b0-2bbc-40c4-ac37-50f7794f4d21', 55863);
INSERT INTO Doacao_Candidatura
VALUES ('940cae35-7f04-4c5d-97b2-34edb5dc7753', '7791637f-e466-451e-9163-8ae171ba4a00', 32919);
INSERT INTO Doacao_Candidatura
VALUES ('de62e4cf-f6a7-449f-beeb-3707876c8d08', 'c8232346-5632-4690-9368-619c8343fbab', 77279);
INSERT INTO Doacao_Candidatura
VALUES ('d12ba51d-426f-4a26-8d59-b417e2e6574d', '717cc3cd-9cf7-49b5-add8-f5561d3fe52c', 70216);
INSERT INTO Doacao_Candidatura
VALUES ('1ea8b95b-f371-4a29-8350-a9e32b3d5b19', '91a9896d-0635-438b-a21e-16b0a19d97cf', 81466);
INSERT INTO Doacao_Candidatura
VALUES ('2134cafe-39c9-4ef4-9bda-2e67d69296a7', 'a3b55b65-efc7-48f0-9c6b-92859cb10dab', 414);
INSERT INTO Doacao_Candidatura
VALUES ('10cdf2ab-21cc-4b42-8fd3-911f3029cc56', '91a9896d-0635-438b-a21e-16b0a19d97cf', 32493);
INSERT INTO Doacao_Candidatura
VALUES ('af6962e3-72e4-403d-822e-936805b93d17', 'ff0760e5-3062-4770-a12a-b1c53a68c7de', 29027);
INSERT INTO Doacao_Candidatura
VALUES ('56761ff6-0d55-42a1-96c8-e7435fc0e5bc', 'acf39c8a-56ca-4eba-a415-d0a4e4ad929a', 98281);
INSERT INTO Doacao_Candidatura
VALUES ('741b84ee-6c6b-47c2-b50c-d418d86371a5', '2ae7d657-c108-4134-8a5c-475019279bfe', 584);
INSERT INTO Doacao_Candidatura
VALUES ('8c1fcbd2-55b6-4083-8175-b104c83770a9', '834d7b66-f257-4121-a4cd-a8fcfbd823f9', 27998);
INSERT INTO Doacao_Candidatura
VALUES ('b6cb6744-4009-40a0-bb7a-9187fcd9ea5e', 'c9976831-44c2-4c3e-916b-499f7c29bc4f', 26064);
INSERT INTO Doacao_Candidatura
VALUES ('12740ffb-966c-40b1-abbd-130e39d8d79c', 'd02242e7-fe79-4ff1-a13a-6d791330a265', 78097);
INSERT INTO Doacao_Candidatura
VALUES ('813bb9da-8d0d-49f1-ab98-f152983dd6c7', 'b4e7134f-657a-4d9e-9cbf-6efaadf2065c', 48006);
INSERT INTO Doacao_Candidatura
VALUES ('4608f34e-4e9d-4c50-a77a-c9d0d0e4500c', 'cd73e0d8-a5a0-4965-b67f-fcb96082944b', 2239);
INSERT INTO Doacao_Candidatura
VALUES ('b3466716-3bbe-4cf2-a2b9-8d658251fcbf', 'abdb4c55-b853-43db-8eaf-ff857af66912', 55987);
INSERT INTO Doacao_Candidatura
VALUES ('46eef9f4-16ed-43c1-bd79-8654c049a371', '5b11b35e-1923-4b75-a947-4db0de6b945e', 81536);
INSERT INTO Doacao_Candidatura
VALUES ('bd32d695-0b48-4700-a9b3-df25dd1a09be', 'a3b55b65-efc7-48f0-9c6b-92859cb10dab', 40623);
INSERT INTO Doacao_Candidatura
VALUES ('f1946f45-5f93-4586-9d4a-ef6c5b618acf', '7ddaa8fe-29f9-4c43-ac75-c3dcd030a9ca', 5327);
INSERT INTO Doacao_Candidatura
VALUES ('da043168-f934-4951-8b3a-3eb5e94a8361', '8a0fb414-58c3-487c-88ab-bc3787cad8bf', 48020);
INSERT INTO Doacao_Candidatura
VALUES ('8be373d0-dbff-424d-a911-ce292da7a3c7', '4d494652-5545-4dda-9bed-aab79da8ea43', 76140);
INSERT INTO Doacao_Candidatura
VALUES ('d1332ce7-ff3a-4daf-910b-dfdbd6710321', '3fd668e5-19a7-4c7a-8d04-94ec82e21881', 77718);
INSERT INTO Doacao_Candidatura
VALUES ('7fb92c16-8725-4b11-87ba-9523795aca44', '239e4d8b-6ce7-4398-9361-2d3d31a9e36f', 43462);
INSERT INTO Doacao_Candidatura
VALUES ('dba029a4-9bb9-4237-8fe0-522e437b5c3d', '3d838daf-b50f-434d-8a4d-733ac960fc56', 55649);
INSERT INTO Doacao_Candidatura
VALUES ('4a7847ab-f1e9-43dd-a603-1d123367459c', '4c9d10ff-4f48-4dce-bc4b-98143d89d622', 74300);
INSERT INTO Doacao_Candidatura
VALUES ('e35d38d7-b9ab-4c9d-9d93-e6332f198d44', 'c5c2e08c-9d9f-4e72-9864-a8a2276d6078', 23474);
INSERT INTO Doacao_Candidatura
VALUES ('bc531d6a-677d-4053-b430-ec1f6fb2219e', '7aa95821-a090-4632-944e-23ca486f0381', 37687);
INSERT INTO Doacao_Candidatura
VALUES ('45707ef0-e555-4482-9633-ca1e5252d2d3', '61679c1f-09c1-4aa1-8521-0f83b10c8a55', 8102);
INSERT INTO Doacao_Candidatura
VALUES ('5f46b047-bbe5-4366-a00f-1db6e4959886', '2902a6c6-7c05-41fb-8e06-2926ec5ec375', 31373);
INSERT INTO Doacao_Candidatura
VALUES ('bcbfb096-34d4-46cd-a9bd-b415de0d0639', 'ebb36ef1-07a5-4104-83bd-68ce97ba041f', 95656);
INSERT INTO Doacao_Candidatura
VALUES ('c112235a-f955-4fbd-85dc-7d0ee7ccd3ae', 'b437122a-32c9-4dde-a516-11d1a76d338a', 18074);
INSERT INTO Doacao_Candidatura
VALUES ('1580c3fa-2a15-42d4-929c-4ef025a2d083', '140c00c6-9c63-4078-8235-49de5c138138', 74966);
INSERT INTO Doacao_Candidatura
VALUES ('a5faae26-8140-493d-a9c2-e7fa1bd5ccfb', '3159ba5d-da6b-4506-8a4b-5b1227d0b17c', 35761);
INSERT INTO Doacao_Candidatura
VALUES ('d8cb4455-e06f-43dc-ae75-7cd8c2db9a1b', '5b11b35e-1923-4b75-a947-4db0de6b945e', 99858);
INSERT INTO Doacao_Candidatura
VALUES ('9e1110ee-9a7e-42e8-921a-33dcd1adb68f', '48cad3af-4499-43ce-bc98-c632486bdc3b', 2715);
INSERT INTO Doacao_Candidatura
VALUES ('972dfb1a-22f4-4943-abbb-ffe57bbdd950', '41611392-62a0-424e-b60a-a7ac2594f571', 4301);
INSERT INTO Doacao_Candidatura
VALUES ('d274d0fb-2a03-4cdf-93c7-bc6a8517d624', '37dd2db7-4c7e-43e7-a839-dd1c2f97f223', 32639);
INSERT INTO Doacao_Candidatura
VALUES ('3cc53c33-7938-4126-a5b4-9d34e6a4bbbf', '7929ba27-8368-4c77-97b3-face01bbe78b', 96437);
INSERT INTO Doacao_Candidatura
VALUES ('5814beca-6685-4dc8-be53-3f54c9c80244', 'c70ff7c3-1273-475b-aa99-effa288fd7cd', 1950);
INSERT INTO Doacao_Candidatura
VALUES ('3ce2e7f0-6b66-4ffa-b9ad-eef23b2fbd4c', '3e08ab28-65f8-4935-a018-80f6a20f193c', 40876);
INSERT INTO Doacao_Candidatura
VALUES ('9a145b03-ffdb-4a27-96bf-d6b8236d4732', '4cc55a67-f714-47dd-8810-6f6ef7f0736f', 19068);
INSERT INTO Doacao_Candidatura
VALUES ('cf2e76a6-3896-4a9b-b9be-6e3418414d19', 'afb7ec26-4f46-4450-ad0d-7e0fb4721d9f', 26863);
INSERT INTO Doacao_Candidatura
VALUES ('7a671348-62bc-4cfd-8842-15770e069655', 'c29c2f54-6c07-4d53-84b1-3834535e35c6', 12317);
INSERT INTO Doacao_Candidatura
VALUES ('05896118-ffb3-4a62-9588-26af8fb254bb', 'c99ccf7c-e434-404c-97c3-af88880cd048', 28279);
INSERT INTO Doacao_Candidatura
VALUES ('40c4b4db-adb2-4898-99be-f2c1460168f4', 'ba120830-08ca-4719-b56a-ab77a191bb5b', 25192);
INSERT INTO Doacao_Candidatura
VALUES ('f5b296ee-dd81-4c95-afc6-a4917b86122b', '1858d9d7-d178-4a46-acc1-89e0757c6afd', 74709);
INSERT INTO Doacao_Candidatura
VALUES ('8f3b0288-74eb-4b5f-87e8-e47ac48de27f', 'cb951489-cf01-4402-98d4-c2020f79e862', 56263);
INSERT INTO Doacao_Candidatura
VALUES ('79ede16f-7dd3-48fb-a3e5-2dea4542ea96', '1e83a57f-6955-463a-8f94-251ba5e36473', 5456);
INSERT INTO Doacao_Candidatura
VALUES ('a2c3e829-a702-4b38-9c77-72c1ae2291b4', 'afed7395-37f4-4d04-af9e-34a63982727b', 55860);
INSERT INTO Doacao_Candidatura
VALUES ('d1eed142-7371-4a5e-952b-ad518198fc86', 'e298afbd-dfe4-4bb3-af93-e80d852d305b', 31773);
INSERT INTO Doacao_Candidatura
VALUES ('c29c8f1c-8a47-4f3e-8e20-8d619c8a6cff', '82a92bc8-dadb-4652-b07b-c553ff495625', 73995);
INSERT INTO Doacao_Candidatura
VALUES ('75f0e3d1-7254-4fe4-913e-a598e89364a8', '24ad90d3-c085-4344-a95a-cc1f0e5b6384', 83165);
INSERT INTO Doacao_Candidatura
VALUES ('5d7e7d61-73b7-4622-bbe3-056127a9d2a7', '951773bf-8527-4ca8-9f02-167dddd5df64', 72695);
INSERT INTO Doacao_Candidatura
VALUES ('34a36766-ab86-4dd4-bcc9-38e2c8f1156f', '85bbbbe9-8850-4bea-96e1-c7bc69998342', 50668);
INSERT INTO Doacao_Candidatura
VALUES ('4afa1504-62d4-41ae-a3f8-4c87d265d67b', 'c29c2f54-6c07-4d53-84b1-3834535e35c6', 39534);
INSERT INTO Doacao_Candidatura
VALUES ('6a04619c-b013-4c1d-ab8b-880ded2088e0', '00c6b060-9bac-4452-b127-39420d4a97f9', 92741);
INSERT INTO Doacao_Candidatura
VALUES ('5297f8ca-5191-4c0c-b7fd-2cde5606ed47', '8f60eda0-d26f-4e9a-b654-4c26a884957f', 58972);
INSERT INTO Doacao_Candidatura
VALUES ('6d3e5baa-9be4-49c1-9007-8558b0ed2277', '66ce5be3-cf2b-47b8-b202-9e03b049dfdb', 16335);
INSERT INTO Doacao_Candidatura
VALUES ('3d07c4aa-d7ab-43ff-944e-b405bd6d83df', 'c15f3b7f-6a3c-4a38-86fc-2b0da6a25303', 52095);
INSERT INTO Doacao_Candidatura
VALUES ('59581d97-0844-409a-a8ca-783e274f858d', 'f5f7d4d0-5075-4714-85ca-97452ffd18b4', 43004);
INSERT INTO Doacao_Candidatura
VALUES ('fbf3c673-942a-46af-a9f6-bd50d435456b', 'b9957418-f6d0-4c83-9178-6b0975af3315', 51209);
INSERT INTO Doacao_Candidatura
VALUES ('9c32eb10-f3be-41db-9b1d-f658a4ef2351', '7789487f-7d38-4e16-a7f5-0b57473abcae', 21290);
INSERT INTO Doacao_Candidatura
VALUES ('2a97996c-3004-43b0-8d76-9ea6233823a3', '6743edf2-b86d-4fd5-acb3-deb787d31e25', 96170);
INSERT INTO Doacao_Candidatura
VALUES ('e7c71688-1138-4892-a572-a1b78c0f6de1', '09851534-f0f1-4902-b7bc-7818876c0940', 62391);
INSERT INTO Doacao_Candidatura
VALUES ('f92763d8-0a6c-4c6a-9eb9-b3341a3a80d1', '639f2b7f-3768-4aa4-b3a6-555204d9ea55', 26448);
INSERT INTO Doacao_Candidatura
VALUES ('e12f895f-2477-4aad-81eb-e51011694736', '8dcc3d94-22e4-449b-b282-526679f164e1', 15144);
INSERT INTO Doacao_Candidatura
VALUES ('b0de3765-e5d9-4f94-84e7-284a568e6035', '640eb4c6-6d24-4a37-abad-9b9b644e3955', 67578);
INSERT INTO Doacao_Candidatura
VALUES ('12df605e-ee95-4cb0-8fdb-a4480b5c7f72', '5b11b35e-1923-4b75-a947-4db0de6b945e', 27372);
INSERT INTO Doacao_Candidatura
VALUES ('5abb68ea-dfd3-4e7e-b7ff-76faea265245', 'a0361ceb-8a60-4dc1-adf5-2d302c2871f2', 84375);
INSERT INTO Doacao_Candidatura
VALUES ('673af975-8411-4ceb-820b-2a5203bdbca3', '85bbbbe9-8850-4bea-96e1-c7bc69998342', 27602);
INSERT INTO Doacao_Candidatura
VALUES ('9e1cf7d0-3585-4fb3-811c-9c678453168c', '13087ccb-65e5-4173-b8f6-fb464d3da8c6', 57871);
INSERT INTO Doacao_Candidatura
VALUES ('62162693-c78d-412b-85f2-7ce9b87cb016', '4b497262-94b2-4cdd-910e-4b989095199b', 81882);
INSERT INTO Doacao_Candidatura
VALUES ('c968d9b2-6a0d-48bd-865e-8b9c21beeca1', '2a1d97af-87de-4086-aee7-b53ba7cfdcaa', 6832);
INSERT INTO Doacao_Candidatura
VALUES ('db739a87-c99d-43d2-bdc1-90de24cb1905', 'ed043e6c-79ea-478d-942c-29a98b61e12a', 73781);
INSERT INTO Doacao_Candidatura
VALUES ('0bc1ab04-616d-4bd9-9f37-18ca61aae5bf', '07e539d9-369d-46f6-b249-f73bc79da5f5', 66462);
INSERT INTO Doacao_Candidatura
VALUES ('ca4fc7cf-29a9-455e-80b0-92cfc0e6659b', '30d3e491-cf0c-4b40-863d-0487d785dea4', 50466);
INSERT INTO Doacao_Candidatura
VALUES ('5795dabc-a0fe-44da-bd4b-9a4303b3fbb7', '43b2526b-02e2-4f55-8f81-46ea3f552053', 37749);
INSERT INTO Doacao_Candidatura
VALUES ('b09b425c-6788-4c29-95f0-0bd608ce4d59', '29ec0277-6754-445c-a254-3b7c631dbaf8', 86123);
INSERT INTO Doacao_Candidatura
VALUES ('01de9f04-1c61-421c-a97e-858d115e8dcf', 'cf214043-fccd-4982-ac53-ce54507a5e18', 82739);
INSERT INTO Doacao_Candidatura
VALUES ('17b381cd-3ad4-46a2-8cb2-ee2484797a6b', '02bd4093-3e1a-497b-b21e-59192ffc29b0', 53780);
INSERT INTO Doacao_Candidatura
VALUES ('fe91ae22-1349-4612-8478-7ab33e94f753', '30096b55-bcab-4a2f-9706-69ce4e0da8c4', 33383);
INSERT INTO Doacao_Candidatura
VALUES ('6b2996e3-d506-416c-928f-9456cac18c1c', 'c5659edf-a245-4445-868b-41a316da92a0', 37356);
INSERT INTO Doacao_Candidatura
VALUES ('6914072e-06b1-46c8-a4c9-d62fe1ae5839', 'f6f918f9-2f4d-4cfd-bd7a-a0205a7fcad4', 5217);
INSERT INTO Doacao_Candidatura
VALUES ('3d7f3e00-d68b-455f-9295-895c43092e21', 'c054a236-8b76-4db4-b93e-422895a365f3', 36535);
INSERT INTO Doacao_Candidatura
VALUES ('2d2a5f60-dc74-42ca-aeee-e7af7d12c595', 'dcd75be4-49aa-45ae-8cb4-897f2afb7d41', 55686);
INSERT INTO Doacao_Candidatura
VALUES ('5ae1e1cf-503a-4299-8c54-7b207b3175b6', '85bbbbe9-8850-4bea-96e1-c7bc69998342', 298);
INSERT INTO Doacao_Candidatura
VALUES ('3b6c0488-0ba2-4557-981a-2983c2f823bd', 'c6b44329-108b-493e-aa4f-1411a4692f71', 51637);
INSERT INTO Doacao_Candidatura
VALUES ('a01c9207-ac01-4502-879d-36e2904b07da', 'eee3cebd-00a3-474d-8d5f-d64a5121f2e5', 42521);
INSERT INTO Doacao_Candidatura
VALUES ('e7969682-0ca1-4d9d-aa56-04424f3c316c', '334ed8ed-7f23-4507-a7c0-5f4e0ad81cf9', 41061);
INSERT INTO Doacao_Candidatura
VALUES ('ea8b08f6-a5c3-4d93-9ca6-e301b65007e2', 'd1b0dede-99f8-4c51-b9de-ef7de6c0f223', 57343);
INSERT INTO Doacao_Candidatura
VALUES ('44c77c51-2199-4e8b-a9de-93b531a5b0ad', 'b0c47a27-be24-44bc-9ce5-ba1d604b3d7a', 18192);
INSERT INTO Doacao_Candidatura
VALUES ('ea9c1a9e-c07a-4b66-88f9-ac10455ab6a1', '0a6cf2bd-3b84-4f47-befc-df22efaee320', 23482);
INSERT INTO Doacao_Candidatura
VALUES ('a646407e-e49a-4dc3-9664-aa5c1ae9634e', '2d1a7c81-9a9b-4b00-bc36-caca205252fb', 79961);
INSERT INTO Doacao_Candidatura
VALUES ('1d41dbd8-d3b4-4177-a077-ed264e895486', 'b6c487a0-35bb-4285-a98d-2cf4b8b0277d', 96961);
INSERT INTO Doacao_Candidatura
VALUES ('3c1493ce-1a7e-46cc-8795-e9800e502281', 'f348d10b-3674-4cb0-b490-3c2123b0ee03', 33425);
INSERT INTO Doacao_Candidatura
VALUES ('5bb803e2-0ebe-4439-bd6b-28e1c517b74d', '0d064bb2-e515-4e4f-8cda-0968b1c7dc9e', 61383);
INSERT INTO Doacao_Candidatura
VALUES ('000d96d7-7195-46ce-8ecf-ecd0c61f0497', '1ddf162a-5faa-45be-bb45-17555b4df092', 35365);
INSERT INTO Doacao_Candidatura
VALUES ('f2f03fd1-c3d2-408c-99ff-86e006142122', '834d7b66-f257-4121-a4cd-a8fcfbd823f9', 69991);
INSERT INTO Doacao_Candidatura
VALUES ('5a8b7b94-922b-4e48-bcee-f0af2f22bf70', 'e3ccd2df-cf31-4dc2-a1e9-34dafe4b26d5', 97102);
INSERT INTO Doacao_Candidatura
VALUES ('3171f4da-9671-4b9b-9f52-33b737a0b1e6', '8f60eda0-d26f-4e9a-b654-4c26a884957f', 22861);
INSERT INTO Doacao_Candidatura
VALUES ('c3a7c3d0-bc86-4168-9346-a6e5818cc9b4', 'a0361ceb-8a60-4dc1-adf5-2d302c2871f2', 7057);
INSERT INTO Doacao_Candidatura
VALUES ('7be8fe52-e173-4ab2-b316-c68679d5c351', 'f0968330-20b4-4cca-939a-c514fe8ba825', 46135);
INSERT INTO Doacao_Candidatura
VALUES ('faa8129b-72c3-4f87-a183-74d3dab322b4', '6df4504e-b88d-4f7f-b79e-b9e663c15cbf', 82713);
INSERT INTO Doacao_Candidatura
VALUES ('b41c4424-4dda-44d1-8fcd-12ab3c68b3fe', 'e298afbd-dfe4-4bb3-af93-e80d852d305b', 10072);
INSERT INTO Doacao_Candidatura
VALUES ('07695413-d750-4a98-99dd-169d90b1ea2a', '37dd2db7-4c7e-43e7-a839-dd1c2f97f223', 3487);
INSERT INTO Doacao_Candidatura
VALUES ('1bc134b8-f077-42f8-a3bf-ab779cd12a1e', '3159ba5d-da6b-4506-8a4b-5b1227d0b17c', 4424);
INSERT INTO Doacao_Candidatura
VALUES ('6db06b25-d9b7-4723-8497-16464a6152c5', 'd1b0dede-99f8-4c51-b9de-ef7de6c0f223', 88199);
INSERT INTO Doacao_Candidatura
VALUES ('70ef348e-8ca8-4314-bb3e-4e505c2b1c53', '06aee079-ee83-4406-afb4-c8d28f6453d2', 49533);
INSERT INTO Doacao_Candidatura
VALUES ('e348bb2a-ebb8-4a52-b7d0-932c7c7e8857', 'd0db5686-16b8-46c9-84ba-3503ade39d5c', 16996);
INSERT INTO Doacao_Candidatura
VALUES ('92cce294-5940-42ba-a735-d8d6840da114', 'e121dbca-5d41-4a89-ae81-3c4391f14eb0', 28203);
INSERT INTO Doacao_Candidatura
VALUES ('f2eaa20a-dfa3-401d-bdc8-dbafbb9459ec', '9cc9ac5b-b66a-4b29-858e-005244337c95', 45012);
INSERT INTO Doacao_Candidatura
VALUES ('382e4669-fbfb-44ad-a70f-df893b34f8e2', '65a1d9a6-7c81-48d2-af36-bbfce45f9e8c', 49479);
INSERT INTO Doacao_Candidatura
VALUES ('4111d6d3-66e3-45b0-a8b0-3e4f1dae37b3', '6a915a3a-868e-43fe-947c-10d8064a6d38', 64913);
INSERT INTO Doacao_Candidatura
VALUES ('2ac4b7c0-ef80-4db1-b540-db12daa52821', '5194f3ac-0f30-41d1-889c-fea9da91f253', 89711);
INSERT INTO Doacao_Candidatura
VALUES ('390156a2-9266-4b2d-8ca4-9c3b7b106c52', '01e85bac-4bed-4b58-b51b-ae77e95cac0d', 24414);
INSERT INTO Doacao_Candidatura
VALUES ('bde9f447-4361-4088-8bfd-13729183fba8', 'b0b8bce8-d1d2-4261-a9d5-c376e731977d', 33960);
INSERT INTO Doacao_Candidatura
VALUES ('2048ff1a-9f0e-4249-be44-31536650af1c', '0b5f8599-e968-421d-ae9d-11d271b8e9b8', 99397);
INSERT INTO Doacao_Candidatura
VALUES ('4098127e-455b-404b-bb7d-848509daf857', '71f474f3-cf89-4e8a-8751-430c3c8f627c', 15271);
INSERT INTO Doacao_Candidatura
VALUES ('4266de86-b231-4da5-a0bc-506fa1d5765c', '951773bf-8527-4ca8-9f02-167dddd5df64', 49838);
INSERT INTO Doacao_Candidatura
VALUES ('3661d524-a551-42bc-ae9d-0e96c5070158', 'b227c169-b231-4158-914e-d558c2c7055e', 2837);
INSERT INTO Doacao_Candidatura
VALUES ('04aed91e-396a-4d50-a676-c0801c4aae7e', '55897dfb-60be-4a72-9090-b5e285526d40', 44451);
INSERT INTO Doacao_Candidatura
VALUES ('c429f430-5c05-4e30-a7e2-2d65651d7b94', 'd1b0dede-99f8-4c51-b9de-ef7de6c0f223', 30744);
INSERT INTO Doacao_Candidatura
VALUES ('ff28af53-2076-4911-aef3-f829aca38d79', 'd8974770-6d0b-4e73-a175-5be80285fa4d', 64152);
INSERT INTO Doacao_Candidatura
VALUES ('279fe8e1-cc5e-43e4-a389-2badc0f058b3', '8925189d-a9f3-4955-965d-c9a4748abba3', 72419);
INSERT INTO Doacao_Candidatura
VALUES ('be06bd19-f384-462c-a657-0ab400f50511', '4c9d10ff-4f48-4dce-bc4b-98143d89d622', 39460);
INSERT INTO Doacao_Candidatura
VALUES ('6e2b636f-6a66-45f3-adec-9d2174dab697', '6c5e83c6-2fc6-44f5-8f04-188a62645bf0', 67411);
INSERT INTO Doacao_Candidatura
VALUES ('f11770ad-caa9-47d6-9a45-51ae0690c52f', 'a0361ceb-8a60-4dc1-adf5-2d302c2871f2', 9305);
INSERT INTO Doacao_Candidatura
VALUES ('77d61626-d300-4daf-b104-a7d0a306825e', '88f1117b-9324-4424-9c76-c7223602197d', 21154);
INSERT INTO Doacao_Candidatura
VALUES ('396f34d8-b3f5-4ee6-b579-36abf42bc707', 'cd786f62-8f1e-45c8-b034-399b1905bdc8', 22408);
INSERT INTO Doacao_Candidatura
VALUES ('116c3cba-a218-4ee9-b3d1-4f2bea422d10', '6a915a3a-868e-43fe-947c-10d8064a6d38', 96918);
INSERT INTO Doacao_Candidatura
VALUES ('41586493-0615-4147-bfd8-dd33488dd5af', 'd02242e7-fe79-4ff1-a13a-6d791330a265', 33764);
INSERT INTO Doacao_Candidatura
VALUES ('7f2d407d-c239-48ed-8305-e48cb31b1db8', 'c5c2e08c-9d9f-4e72-9864-a8a2276d6078', 25336);
INSERT INTO Doacao_Candidatura
VALUES ('5991106a-1dac-4f35-a552-2b054a669a67', 'c5659edf-a245-4445-868b-41a316da92a0', 49101);
INSERT INTO Doacao_Candidatura
VALUES ('54055335-0047-4043-bcaa-04cedfcf0a4e', '4096297d-83d9-4f40-afae-5dd326709dfd', 5377);
INSERT INTO Doacao_Candidatura
VALUES ('992a1e28-d929-475a-a05f-7e1fdb0ed36e', 'dc41b2a9-f13a-4a61-8409-9bdc2396b793', 97343);
INSERT INTO Doacao_Candidatura
VALUES ('7732c810-ea7a-4193-8968-c79a0f446cdb', '8658829e-b5e0-4fe1-b3b2-73a5100a152f', 64858);
INSERT INTO Doacao_Candidatura
VALUES ('dc47c8de-dac5-45a6-978c-f74210f97960', 'f7dc20dd-2169-4673-a3a5-14a98b75c022', 84875);
INSERT INTO Doacao_Candidatura
VALUES ('1d3772ad-f947-44af-b1f2-01f4f3f8a505', '272669e7-7493-418f-a622-00d75748f6f2', 95275);
INSERT INTO Doacao_Candidatura
VALUES ('499b830a-8e7b-4c3e-9194-2954fd57774e', 'a6700843-18c8-4ac6-b877-5d833d457089', 87717);
INSERT INTO Doacao_Candidatura
VALUES ('2fe2e1a6-a853-4d93-8e00-2ceaa9484020', '4b497262-94b2-4cdd-910e-4b989095199b', 43460);
INSERT INTO Doacao_Candidatura
VALUES ('89c55803-ee6f-4d64-a56a-e2b33c351fe2', '97516f6f-4280-46f7-aad0-363a36766cb1', 35455);
INSERT INTO Doacao_Candidatura
VALUES ('c7af32c5-2268-4e28-a764-16bf5d354e72', '22238844-c804-4e8e-aee3-43d6778442b1', 34429);


-- Insere Processos Judiciais
INSERT INTO Processo_Judicial
VALUES ('beea430c-b53b-4711-b6d5-7e88fb1ef1cc', '2001-12-27',
        '2019-9-17', true, '16524949248');
INSERT INTO Processo_Judicial
VALUES ('f8c273dc-3db5-4980-b1fb-38013db0a555', '2017-8-12',
        NULL, false, '48673702988');
INSERT INTO Processo_Judicial
VALUES ('8eba261b-f3ec-478a-b941-98b4afff533f', '2004-10-1',
        NULL, false, '73055091793');
INSERT INTO Processo_Judicial
VALUES ('86dd7ad4-fb09-4714-aa24-511fe9bc6026', '2006-6-23',
        NULL, false, '74132363493');
INSERT INTO Processo_Judicial
VALUES ('98c4e028-07f3-4762-8cf5-4728d1fb203f', '2020-11-19',
        '2021-3-23', true, '79759667741');
INSERT INTO Processo_Judicial
VALUES ('5d30fa8b-726a-4133-b037-588fcb90875d', '2013-8-17',
        NULL, true, '95605694998');
INSERT INTO Processo_Judicial
VALUES ('67667fe6-8570-47b8-8a5a-6ef75639b5f6', '2009-2-22',
        '2020-6-14', true, '25756717512');
INSERT INTO Processo_Judicial
VALUES ('bbf66e3f-8e76-4b08-b1e7-661f03136b3b', '2003-4-17',
        NULL, true, '51026479906');
INSERT INTO Processo_Judicial
VALUES ('8ea51205-c92f-4252-b62f-41820b4b9d67', '2018-11-2',
        NULL, true, '28127971645');
INSERT INTO Processo_Judicial
VALUES ('5ca7d174-781c-446f-8558-64992065b71c', '2002-9-23',
        '2019-1-5', false, '32128272987');
INSERT INTO Processo_Judicial
VALUES ('3b8f5e78-aec8-442d-9dc1-2ac360263e70', '2019-2-12',
        NULL, true, '36136912815');
INSERT INTO Processo_Judicial
VALUES ('7ab63a10-d657-46fa-b4de-b28f287bd76f', '2010-3-30',
        '2019-1-23', true, '17909814855');
INSERT INTO Processo_Judicial
VALUES ('604c87b4-fbf6-443e-a835-829e6d4c88e9', '2014-7-6',
        NULL, false, '81603123238');
INSERT INTO Processo_Judicial
VALUES ('a2f67aa7-efd5-42d7-830a-021270b139f8', '2007-11-27',
        NULL, false, '82203919910');
INSERT INTO Processo_Judicial
VALUES ('18acd6e9-fef0-40ba-a886-92b752e8c798', '2005-11-2',
        '2020-8-25', false, '41136322179');
INSERT INTO Processo_Judicial
VALUES ('1c9daf22-08bc-427b-8760-ff37f871e3ab', '2003-7-19',
        '2019-2-4', false, '73635011366');
INSERT INTO Processo_Judicial
VALUES ('a832afa5-302e-4f46-bbb6-769a565de0b2', '2007-1-4',
        '2020-10-16', false, '55804576182');
INSERT INTO Processo_Judicial
VALUES ('61ebf900-84d3-4b46-93d9-b2207b32a5bd', '2006-4-2',
        '2021-3-11', true, '56626854483');
INSERT INTO Processo_Judicial
VALUES ('a515c3d1-9638-4fb7-9632-bc7409b36ec2', '2006-9-27',
        '2021-1-21', false, '29875680117');
INSERT INTO Processo_Judicial
VALUES ('0c42988b-2337-4cd1-87bd-41456f8d4417', '2016-6-20',
        NULL, false, '84286792359');
INSERT INTO Processo_Judicial
VALUES ('df342160-9082-4cc9-8106-a5d4f4152bba', '2020-1-11',
        '2021-7-17', false, '83954206069');
INSERT INTO Processo_Judicial
VALUES ('786e1622-c58a-4aca-b80b-bb52869183a5', '2005-2-26',
        '2018-12-12', true, '85647496753');
INSERT INTO Processo_Judicial
VALUES ('848053e2-7ec3-44e9-bedc-23da61eed11d', '2006-2-5',
        '2021-7-18', true, '89611346540');
INSERT INTO Processo_Judicial
VALUES ('8331cfd3-fe05-4ea2-8ea3-305a3a7ff881', '2014-5-7',
        NULL, true, '55854224269');
INSERT INTO Processo_Judicial
VALUES ('ce96b8fe-ca24-44f7-9b69-9baaf4155072', '2013-4-27',
        NULL, false, '66894887096');
INSERT INTO Processo_Judicial
VALUES ('7e26198b-755d-4a0f-ae05-bffbc264ba4f', '2002-2-3',
        NULL, false, '29078152088');
INSERT INTO Processo_Judicial
VALUES ('6331b8b3-a3fd-4ed0-809d-9a29b313695e', '2002-3-16',
        '2020-1-2', true, '86885927871');
INSERT INTO Processo_Judicial
VALUES ('75d79065-91c5-4946-ae91-5c37d37ad2bf', '2011-10-24',
        '2019-7-4', true, '39274698467');
INSERT INTO Processo_Judicial
VALUES ('c856d945-3949-4c23-ba48-6215be06671f', '2011-1-31',
        '2017-2-16', true, '30228957973');
INSERT INTO Processo_Judicial
VALUES ('be3a2687-79d0-4bce-a0ab-6690d2788245', '2013-7-9',
        '2020-9-22', true, '15702510098');
INSERT INTO Processo_Judicial
VALUES ('5c10a1bd-8438-43c8-bed5-7d8801431837', '2003-2-21',
        NULL, true, '60141710506');
INSERT INTO Processo_Judicial
VALUES ('89a0ea54-0dc1-4f2a-9719-001f393e1a4d', '2015-3-10',
        '2017-12-30', false, '53392276959');
INSERT INTO Processo_Judicial
VALUES ('6942ac95-edf2-4e6f-9439-62e0c35127c4', '2009-12-9',
        '2020-10-17', true, '86885927871');
INSERT INTO Processo_Judicial
VALUES ('e23b24f6-1c1d-499b-8254-a9bff2994063', '2017-7-11',
        NULL, false, '77137697788');
INSERT INTO Processo_Judicial
VALUES ('2068121d-a49c-463d-b924-b539c3e40ece', '2005-3-7',
        '2018-3-24', true, '44931717652');
INSERT INTO Processo_Judicial
VALUES ('29189747-ab0e-4d2e-8f02-170d5016f6ec', '2004-7-28',
        '2019-7-20', false, '20934364222');
INSERT INTO Processo_Judicial
VALUES ('6728e9e4-2894-4196-b186-24175641f539', '2009-1-21',
        '2018-8-4', false, '49292941880');
INSERT INTO Processo_Judicial
VALUES ('4e75d15a-b6a2-4855-86d4-209fbcad1a25', '2009-9-12',
        '2021-5-17', false, '82870189829');
INSERT INTO Processo_Judicial
VALUES ('63b00945-d02d-4bf9-a541-5e0399833394', '2005-12-20',
        NULL, true, '63745677894');
INSERT INTO Processo_Judicial
VALUES ('411e9e52-6d5a-432f-bb56-d75a538b1201', '2021-11-17',
        '2021-5-3', false, '68482680276');
INSERT INTO Processo_Judicial
VALUES ('874fce50-74a3-4097-9c53-3109d710e24c', '2016-2-5',
        NULL, false, '58362277850');
INSERT INTO Processo_Judicial
VALUES ('4d9841dc-8c41-440d-9afe-01b428dbf9ae', '2005-1-6',
        NULL, false, '22478564004');
INSERT INTO Processo_Judicial
VALUES ('b4cda243-d42e-456e-9581-91f0147b42d9', '2020-6-7',
        '2020-8-19', false, '33952316290');
INSERT INTO Processo_Judicial
VALUES ('0639dc12-1142-4693-bd48-f18928629625', '2002-11-10',
        '2020-6-2', false, '20158254010');
INSERT INTO Processo_Judicial
VALUES ('bca3782b-67e9-4eae-a18a-98ffd78428bc', '2019-4-11',
        NULL, false, '26766975226');
INSERT INTO Processo_Judicial
VALUES ('73fb6745-edb5-4233-9790-62a4594d9988', '2017-6-5',
        '2018-5-11', false, '83687715737');
INSERT INTO Processo_Judicial
VALUES ('0bff818a-425e-4b5b-b79f-dbf290e1605a', '2005-12-4',
        '2019-9-5', false, '57704504102');
INSERT INTO Processo_Judicial
VALUES ('fc81a49d-20cc-4bcd-b7f0-92e482d7f7e3', '2007-7-10',
        NULL, true, '98071054182');
INSERT INTO Processo_Judicial
VALUES ('811df669-cba2-41a7-94ba-170543d3f5a9', '2003-9-18',
        NULL, false, '52024004105');
INSERT INTO Processo_Judicial
VALUES ('a2b10e6c-b218-4d54-8f01-143a4eec4dcf', '2004-9-13',
        '2019-11-15', true, '44718153213');
INSERT INTO Processo_Judicial
VALUES ('05933d6b-a898-4733-aae5-15b5499ef5cc', '2019-5-6',
        NULL, true, '78188553669');
INSERT INTO Processo_Judicial
VALUES ('5eccc8af-a55a-4174-a6c1-8cf2c6d5c199', '2012-5-3',
        NULL, true, '60858012235');
INSERT INTO Processo_Judicial
VALUES ('fbc06b63-7f45-46e4-9e2c-f4c43de039b1', '2002-9-4',
        '2020-2-3', false, '12213830926');
INSERT INTO Processo_Judicial
VALUES ('b31d83ee-7e89-4323-beca-9cea6c320f18', '2017-5-1',
        '2020-6-2', true, '31701090801');
INSERT INTO Processo_Judicial
VALUES ('928899a2-243f-418f-aec4-35d2567e8ba7', '2014-7-3',
        '2021-4-3', true, '30848156486');
INSERT INTO Processo_Judicial
VALUES ('b61914a2-7e1f-4316-bc53-d3da019def2d', '2009-5-25',
        '2017-4-28', false, '94102552335');
INSERT INTO Processo_Judicial
VALUES ('771db524-deec-4b55-83ef-a76a6255c9d0', '2005-6-25',
        '2021-4-7', false, '32128272987');
INSERT INTO Processo_Judicial
VALUES ('bbe4df79-c37a-478d-a6d5-4f57281699a1', '2018-3-20',
        '2020-3-10', true, '51697040249');
INSERT INTO Processo_Judicial
VALUES ('57de5b40-6355-4f60-ac4c-f34e953b89a2', '2018-12-3',
        NULL, true, '61522070106');
INSERT INTO Processo_Judicial
VALUES ('cb5a4d34-fd37-49c5-aabe-d4e16985f0d8', '2010-12-31',
        NULL, false, '54687466805');
INSERT INTO Processo_Judicial
VALUES ('168c4260-a1cd-427d-a06e-0574a06d582b', '2018-8-24',
        NULL, false, '82078275873');
INSERT INTO Processo_Judicial
VALUES ('b2c3eff5-1093-460e-b470-4c30a232b243', '2013-4-5',
        '2020-11-18', false, '50921300621');
INSERT INTO Processo_Judicial
VALUES ('9b6c103e-fc6d-4644-9c1b-4d074b75d489', '2019-1-21',
        NULL, false, '25336353376');
INSERT INTO Processo_Judicial
VALUES ('a833950a-aed5-41dc-9ce8-817f5f57405d', '2018-4-12',
        NULL, false, '47100549493');
INSERT INTO Processo_Judicial
VALUES ('773cf203-0b9b-4035-a9ae-a21f5d4b124e', '2009-5-14',
        NULL, false, '95593594631');
INSERT INTO Processo_Judicial
VALUES ('29bbe2a6-3597-4968-89c6-0b046609a2c3', '2003-5-28',
        NULL, true, '86681896694');
INSERT INTO Processo_Judicial
VALUES ('0cbed245-9226-4c3d-9112-285972e7be36', '2020-3-28',
        NULL, false, '42811426627');
INSERT INTO Processo_Judicial
VALUES ('5791ade9-9dbe-4ef0-85d5-525bf3994e5b', '2007-10-28',
        '2018-1-27', false, '42181111930');
INSERT INTO Processo_Judicial
VALUES ('6671a361-c8f0-4913-bcfc-1a92e8eef690', '2018-1-19',
        NULL, false, '17366820771');
INSERT INTO Processo_Judicial
VALUES ('a3828256-b803-4970-a172-b0e875811ee0', '2014-11-12',
        '2020-6-3', true, '30621758850');
INSERT INTO Processo_Judicial
VALUES ('022e9ba5-2d38-4a5a-a8f6-166d6a30dcb4', '2005-4-10',
        '2019-8-6', true, '52959466576');
INSERT INTO Processo_Judicial
VALUES ('0ae317f2-3146-4b6d-b025-45d384db6be0', '2006-9-15',
        NULL, false, '33952316290');
INSERT INTO Processo_Judicial
VALUES ('e999d513-e15b-4471-84ea-ea166fe1d8a6', '2002-7-14',
        '2021-9-15', true, '52122835628');
INSERT INTO Processo_Judicial
VALUES ('854ffd2a-2dc8-499d-86db-5383399ea491', '2020-2-2',
        '2018-10-7', true, '60858012235');
INSERT INTO Processo_Judicial
VALUES ('fbed8c9e-a098-44f2-8fc9-1a99d49d76c5', '2013-11-21',
        NULL, false, '35895102075');
INSERT INTO Processo_Judicial
VALUES ('319502d6-6b31-4412-8e6c-5fa319227071', '2017-10-12',
        '2017-2-11', true, '83675283405');
INSERT INTO Processo_Judicial
VALUES ('249dd5af-fc14-4380-90f6-706be2716f2a', '2008-10-3',
        NULL, true, '90434170963');
INSERT INTO Processo_Judicial
VALUES ('9b8966eb-cb67-48a5-8301-d5dc786b99ea', '2010-9-16',
        '2018-11-25', true, '71402272270');
INSERT INTO Processo_Judicial
VALUES ('78affb22-817f-48cd-94c0-dc96fd300fd6', '2015-12-28',
        '2019-12-18', true, '32125016890');
INSERT INTO Processo_Judicial
VALUES ('86d5cc40-afed-43c8-8ec5-9b9c24701ae2', '2006-7-25',
        '2018-7-9', false, '54358800731');
INSERT INTO Processo_Judicial
VALUES ('38b8b8f3-225d-4d50-a1e9-36c3c2e0304a', '2019-2-5',
        NULL, false, '20934364222');
INSERT INTO Processo_Judicial
VALUES ('7a05ae5c-8cde-4614-a0b0-e7de8292defa', '2009-8-3',
        '2017-3-31', false, '13211265460');
INSERT INTO Processo_Judicial
VALUES ('4691df76-e74c-447d-82c8-31c598cb8b3c', '2006-6-18',
        '2017-12-27', true, '68767157313');
INSERT INTO Processo_Judicial
VALUES ('e3563277-88c0-4f5c-a588-7fb416707541', '2014-3-31',
        '2018-3-17', false, '45014148892');
INSERT INTO Processo_Judicial
VALUES ('14423698-93fc-4eef-90fb-09c4e0a03f65', '2004-3-5',
        NULL, false, '25336353376');
INSERT INTO Processo_Judicial
VALUES ('5959d062-42d1-4727-b256-faa019af6662', '2017-1-5',
        NULL, true, '41139387378');
INSERT INTO Processo_Judicial
VALUES ('69d8496e-1f46-48cb-ba5e-c46796057fac', '2019-1-20',
        '2020-12-21', true, '79606743648');
INSERT INTO Processo_Judicial
VALUES ('62c86c04-1236-4517-8fcf-39f76fe2aa25', '2005-8-19',
        NULL, true, '28238024273');
INSERT INTO Processo_Judicial
VALUES ('f3fb5670-bd09-4b90-bf43-d66bc4337be9', '2013-7-16',
        '2018-5-10', true, '54183079097');
INSERT INTO Processo_Judicial
VALUES ('af890c3b-0a6a-4e4b-92fb-1fd631216ff8', '2018-10-20',
        NULL, false, '27744644728');
INSERT INTO Processo_Judicial
VALUES ('c340c2e5-2c96-464e-8c1a-ad523b2269cd', '2003-11-9',
        '2019-4-30', true, '22431804153');
INSERT INTO Processo_Judicial
VALUES ('3d919968-3ffd-424b-be41-404d9af94778', '2010-7-14',
        NULL, false, '19264541170');
INSERT INTO Processo_Judicial
VALUES ('49b7384a-4761-4938-b5d1-65834026ba4d', '2009-10-10',
        NULL, true, '90003691567');
INSERT INTO Processo_Judicial
VALUES ('3a4ea650-df82-4d38-9f90-534a9eee51e8', '2005-12-11',
        '2021-3-25', false, '91139727742');
INSERT INTO Processo_Judicial
VALUES ('51a24686-7e94-485d-a1be-f77151395ed1', '2018-8-3',
        NULL, true, '58254329771');
INSERT INTO Processo_Judicial
VALUES ('bc8c4aa4-a5ff-48f6-9268-41b3c1ecaffc', '2009-11-2',
        '2021-5-9', true, '93557888891');
INSERT INTO Processo_Judicial
VALUES ('746f7f79-2716-4306-a290-bd8c81dac167', '2006-7-16',
        NULL, false, '98543534772');
INSERT INTO Processo_Judicial
VALUES ('53eb3322-05b0-4751-8e4c-25953f9dee02', '2020-7-1',
        NULL, false, '80014259815');
INSERT INTO Processo_Judicial
VALUES ('8448b21f-c471-40ea-939b-c66e33cdeb39', '2011-1-26',
        '2018-1-26', false, '21125739731');
INSERT INTO Processo_Judicial
VALUES ('633d932f-5428-4f21-9b69-3891d55132d1', '2020-3-21',
        '2021-3-11', false, '72560434259');
INSERT INTO Processo_Judicial
VALUES ('b02b29c2-91f4-45d2-a50b-a165596e371c', '2011-9-25',
        NULL, true, '78782798836');
INSERT INTO Processo_Judicial
VALUES ('ffdab896-6339-4291-bdbf-194bd1dbcfd3', '2013-5-19',
        NULL, false, '45065363431');
INSERT INTO Processo_Judicial
VALUES ('63814d3c-f8fa-496d-b1d3-fe84c1b5c6d8', '2009-5-23',
        '2020-10-20', true, '28842566022');
INSERT INTO Processo_Judicial
VALUES ('9219fe61-39f6-4d36-aa00-72fa0d043ee9', '2010-6-18',
        NULL, true, '88037559373');
INSERT INTO Processo_Judicial
VALUES ('45d684ac-0753-4d5c-988c-dbc3a8f6c236', '2018-11-24',
        NULL, false, '91566400225');
INSERT INTO Processo_Judicial
VALUES ('7c39d2ae-d97a-4ba4-8df7-f4fe53079cac', '2012-11-13',
        NULL, true, '58980360710');
INSERT INTO Processo_Judicial
VALUES ('059924ee-340f-4ec8-9d49-629d60971767', '2021-2-16',
        '2021-7-14', false, '69626756855');
INSERT INTO Processo_Judicial
VALUES ('cac6f35e-dd7e-49f1-80f8-84562dfb373e', '2016-6-15',
        NULL, false, '87614392244');
INSERT INTO Processo_Judicial
VALUES ('0e1c73f8-6aa9-433d-9048-cf4db39e8d54', '2021-3-7',
        NULL, false, '96993440124');
INSERT INTO Processo_Judicial
VALUES ('3647bab1-e802-4045-9748-64d52a7650ed', '2006-11-21',
        NULL, true, '63500243364');
INSERT INTO Processo_Judicial
VALUES ('52b0979c-48b6-4c43-89b2-d0d170d4f3d6', '2003-6-1',
        NULL, true, '73767229476');
INSERT INTO Processo_Judicial
VALUES ('7c900fd9-c47a-4b8e-823a-5204eb00794a', '2007-7-26',
        NULL, false, '49970481498');
INSERT INTO Processo_Judicial
VALUES ('887aa8fa-31b1-4d3b-95f1-fa18161c02a6', '2007-5-28',
        NULL, true, '85739130568');
INSERT INTO Processo_Judicial
VALUES ('357b62a8-99a1-4e7f-8efe-07e2322f6f61', '2004-3-22',
        '2018-1-20', false, '44718153213');
INSERT INTO Processo_Judicial
VALUES ('32dd83e4-5baf-4173-b12e-4b9fc8f2ae5f', '2005-6-17',
        '2019-6-2', false, '74479391069');
INSERT INTO Processo_Judicial
VALUES ('2bb1b203-9364-48c0-adbd-932baccfab17', '2004-3-11',
        '2020-7-4', false, '41319743199');
INSERT INTO Processo_Judicial
VALUES ('30356767-2969-4552-9311-1c4a45a951b8', '2008-5-18',
        NULL, false, '27603935101');
INSERT INTO Processo_Judicial
VALUES ('28f3a425-e3f8-4142-b6bd-e274c565e245', '2020-3-18',
        '2019-11-27', false, '43863967857');
INSERT INTO Processo_Judicial
VALUES ('2d1942b0-55d5-44d2-be4a-ca51ff91ba15', '2009-12-5',
        NULL, true, '66703392334');
INSERT INTO Processo_Judicial
VALUES ('fbdc56a7-5280-4951-8345-a63f71e2ad23', '2003-3-28',
        NULL, true, '23680543084');
INSERT INTO Processo_Judicial
VALUES ('021a32e9-1ef5-46c4-9ca7-9b510d5d6eeb', '2020-10-8',
        NULL, true, '39911369015');
INSERT INTO Processo_Judicial
VALUES ('256145b9-266a-48c3-9d63-d945e60c6e3c', '2009-2-6',
        NULL, true, '15132983059');
INSERT INTO Processo_Judicial
VALUES ('aa9921de-548b-439f-9123-17f227e1f981', '2011-8-14',
        NULL, false, '20370718555');
INSERT INTO Processo_Judicial
VALUES ('8d4ea226-5dea-4d00-a696-2f9717ef39a1', '2005-9-9',
        '2021-4-12', false, '58593827674');
INSERT INTO Processo_Judicial
VALUES ('bdc3ceb5-aa66-4ce8-9e6e-8a5b2437c0b9', '2020-8-23',
        '2018-11-26', false, '38865358545');
INSERT INTO Processo_Judicial
VALUES ('857b9b39-5c6f-43af-8838-750d7691568d', '2003-11-26',
        NULL, false, '25892141219');
INSERT INTO Processo_Judicial
VALUES ('944b113e-687f-4d0b-a5d9-01a2ea07adfa', '2016-2-26',
        NULL, false, '31626318043');
INSERT INTO Processo_Judicial
VALUES ('d0284928-4ad8-436a-93f0-eab4345c05cb', '2006-12-29',
        NULL, true, '55582106600');
INSERT INTO Processo_Judicial
VALUES ('d30a4021-5196-45c6-a9fe-d3d9fdf46958', '2004-2-13',
        '2018-10-24', true, '65327025726');
INSERT INTO Processo_Judicial
VALUES ('12a99f4f-2012-4a2b-85b9-33afccecd8d2', '2006-4-24',
        NULL, false, '54014710634');
INSERT INTO Processo_Judicial
VALUES ('d5ed490d-8b5a-4739-9feb-8025ac91f8ce', '2005-10-29',
        NULL, true, '67008212334');
INSERT INTO Processo_Judicial
VALUES ('a190598f-70d3-4b95-a24d-d9e6880f60c4', '2012-3-22',
        '2016-12-4', false, '40851067951');
INSERT INTO Processo_Judicial
VALUES ('80720522-5539-4db3-80ec-518db0d8e444', '2021-6-1',
        '2020-6-5', true, '57793636212');
INSERT INTO Processo_Judicial
VALUES ('d68a9b9c-2ba4-41e9-baf4-7387b9a1118a', '2007-2-5',
        '2017-11-7', false, '39274698467');
INSERT INTO Processo_Judicial
VALUES ('635ffa3f-5f32-4fbe-a7f4-bcf7f4896319', '2015-5-18',
        '2021-1-7', true, '32508439864');
INSERT INTO Processo_Judicial
VALUES ('a0c691fd-aa0d-4271-a891-667e77da1abd', '2005-3-1',
        '2020-10-23', false, '56437012213');
INSERT INTO Processo_Judicial
VALUES ('82da9ca9-8fec-45bc-b043-2863b58c7225', '2003-11-23',
        '2018-10-29', true, '41830698924');
INSERT INTO Processo_Judicial
VALUES ('2e35ce97-24e6-4bb3-94a1-0bc82ccd50e4', '2009-11-7',
        NULL, true, '35410163693');
INSERT INTO Processo_Judicial
VALUES ('b4fd1633-a776-4574-867c-a724d36d42c2', '2013-10-15',
        NULL, true, '44202141419');
INSERT INTO Processo_Judicial
VALUES ('407004c5-6f70-49c2-bc1b-b2044052bc6f', '2007-11-25',
        NULL, false, '46683265664');
INSERT INTO Processo_Judicial
VALUES ('a1782b77-d47f-4231-bae0-ab0d42bee288', '2017-8-15',
        '2021-5-1', true, '92776450554');
INSERT INTO Processo_Judicial
VALUES ('7841236f-f811-4101-a586-6b55f0e10c32', '2016-3-14',
        '2017-7-28', false, '32228380509');
INSERT INTO Processo_Judicial
VALUES ('8f29cf84-ead0-478c-82c9-b5c00264d54d', '2008-6-28',
        '2019-5-28', true, '81435520064');
INSERT INTO Processo_Judicial
VALUES ('d9ed587b-7e05-401a-8e1e-216666d4bfa6', '2011-2-8',
        NULL, true, '53198584232');
INSERT INTO Processo_Judicial
VALUES ('3dd8c2e6-1bda-43ce-8705-4a8b556dc837', '2009-5-1',
        '2018-5-23', true, '13641347680');
INSERT INTO Processo_Judicial
VALUES ('fdb19d53-110d-445a-a014-e6660ce85965', '2019-5-19',
        '2019-8-25', false, '59097811668');
INSERT INTO Processo_Judicial
VALUES ('8289894c-debe-4374-be79-bddf0cfe2e39', '2008-9-10',
        NULL, false, '43359677735');
INSERT INTO Processo_Judicial
VALUES ('58908be4-aaec-4094-aaae-f2d30445f71f', '2009-3-21',
        '2018-8-14', true, '25862227568');
INSERT INTO Processo_Judicial
VALUES ('f9b128ac-075e-40d6-bf5e-9305f7e745c4', '2004-9-27',
        '2017-12-26', true, '27573815234');
INSERT INTO Processo_Judicial
VALUES ('f97dcebe-c30c-49d9-8e3d-d1e194ae54d8', '2002-5-23',
        '2020-2-2', false, '98850444883');
INSERT INTO Processo_Judicial
VALUES ('56aa5cd1-95b9-4a35-a560-7362cbd7cd4f', '2012-9-10',
        '2019-5-19', true, '83906174097');
INSERT INTO Processo_Judicial
VALUES ('54c01a25-5d08-45a3-95c5-a2a54d7fdaa8', '2012-5-1',
        '2020-4-16', true, '86836338876');
INSERT INTO Processo_Judicial
VALUES ('f8d91ffd-89ae-43f9-80f5-25aa724b2bd9', '2021-10-29',
        NULL, true, '38390440184');
INSERT INTO Processo_Judicial
VALUES ('4d3e4cab-3315-4b7e-9cc9-f28d3744ee2a', '2011-6-19',
        NULL, true, '55854224269');
INSERT INTO Processo_Judicial
VALUES ('b534fb66-fe91-41fe-b708-ce00f9db8ff9', '2021-8-23',
        '2021-1-18', false, '33005915498');
INSERT INTO Processo_Judicial
VALUES ('7f026e69-729c-4087-b2a2-f2c928a20f62', '2009-3-17',
        NULL, true, '52510659939');
INSERT INTO Processo_Judicial
VALUES ('5f104861-880d-45f5-9e85-2f71f4c65304', '2018-12-6',
        NULL, false, '77137697788');
INSERT INTO Processo_Judicial
VALUES ('266d1376-8fb2-4d0d-a999-1d90afed2c1c', '2019-6-1',
        NULL, true, '79646575415');
INSERT INTO Processo_Judicial
VALUES ('ae4dd4e2-e47b-4d7d-a257-de6f2aaa5866', '2013-2-18',
        '2017-12-16', true, '10209552922');
INSERT INTO Processo_Judicial
VALUES ('d5eb8464-8eee-4e71-939b-07a8de78626b', '2019-2-2',
        NULL, true, '44331545557');
INSERT INTO Processo_Judicial
VALUES ('0736e29b-7603-4192-b98b-dfa6c7c95f3a', '2020-10-22',
        '2017-8-15', true, '73635011366');
INSERT INTO Processo_Judicial
VALUES ('5019bbd3-7f85-40f9-ab0d-99a88e78f3fc', '2020-4-6',
        NULL, true, '26260169129');
INSERT INTO Processo_Judicial
VALUES ('5da3989c-75e2-4d60-8102-7bb66ce6d5f1', '2007-2-12',
        '2018-8-14', true, '57704504102');
INSERT INTO Processo_Judicial
VALUES ('333bd19a-da94-497e-a766-3cd067a084df', '2008-8-21',
        '2017-7-31', false, '54358800731');
INSERT INTO Processo_Judicial
VALUES ('768981b1-c502-4661-9969-76a2510cfc1b', '2009-10-1',
        NULL, false, '31128941818');
INSERT INTO Processo_Judicial
VALUES ('381b21fb-0628-4f2c-ba1f-408818e29d0c', '2010-4-18',
        '2021-11-5', false, '51977524964');
INSERT INTO Processo_Judicial
VALUES ('71eebec7-9437-4016-b7de-03356a881ed8', '2021-6-22',
        '2021-2-14', false, '84774450208');
INSERT INTO Processo_Judicial
VALUES ('d5cbce45-77ec-4e33-a805-1aacdafce760', '2018-3-17',
        '2019-10-6', false, '82049451954');
INSERT INTO Processo_Judicial
VALUES ('9a7d693b-689e-4998-8e32-7adcaa399326', '2007-1-27',
        NULL, true, '56279783362');
INSERT INTO Processo_Judicial
VALUES ('e5f5bb41-d8ef-4bb2-a2f3-e44c4624a5e7', '2008-4-20',
        '2021-4-17', true, '75511465452');
INSERT INTO Processo_Judicial
VALUES ('a3a3ba69-7b0e-41b5-b09a-6d877a651157', '2016-4-2',
        '2021-7-25', true, '62782628233');
INSERT INTO Processo_Judicial
VALUES ('63003963-61d1-439f-b360-630a6d0897d6', '2014-5-22',
        '2020-7-23', false, '67951579191');
INSERT INTO Processo_Judicial
VALUES ('3b9a6e84-7021-4f68-a7ed-020df85bdf77', '2004-7-23',
        '2017-3-29', false, '47292644651');
INSERT INTO Processo_Judicial
VALUES ('deb7fcb9-eabc-439b-a5bc-51baa027ee1d', '2018-3-20',
        NULL, false, '54873438458');
INSERT INTO Processo_Judicial
VALUES ('d6c3d264-c5bb-4d13-a40d-2f8b5fce0d89', '2020-4-22',
        '2018-1-16', true, '14975074331');
INSERT INTO Processo_Judicial
VALUES ('8ccef45a-ed89-429c-b115-3da1b63e6862', '2015-5-14',
        '2021-10-1', true, '53509038442');
INSERT INTO Processo_Judicial
VALUES ('6ddfdcf4-5448-4764-afb8-836ff7378da0', '2002-4-14',
        '2019-2-16', true, '29694294098');
INSERT INTO Processo_Judicial
VALUES ('34f0d61e-696f-4840-a6ab-c7dcd019e4ff', '2006-6-15',
        '2018-9-9', false, '33265460920');
INSERT INTO Processo_Judicial
VALUES ('f1154218-876b-4d0e-a149-dcdf3e30aa42', '2004-5-19',
        NULL, true, '45168306697');
INSERT INTO Processo_Judicial
VALUES ('945249f3-f690-4297-9b33-cfd1ee203db0', '2015-5-16',
        '2018-6-22', false, '40909250010');
INSERT INTO Processo_Judicial
VALUES ('951d00fa-a765-4d0b-b5cf-226f7aa4c935', '2006-11-7',
        NULL, true, '56643636750');
INSERT INTO Processo_Judicial
VALUES ('ee6cdd56-362d-451b-a3f2-7ecabe50c207', '2007-8-9',
        NULL, true, '59156701033');
INSERT INTO Processo_Judicial
VALUES ('e7bf0467-3792-497f-a52c-e585f4182aab', '2020-1-22',
        NULL, true, '34702133666');
INSERT INTO Processo_Judicial
VALUES ('7bf09804-afe9-4ec8-972a-11f39b5117e8', '2016-9-5',
        '2019-5-15', true, '27500320235');
INSERT INTO Processo_Judicial
VALUES ('a9b182e9-3d19-472b-8bca-89b668c6b1da', '2011-2-13',
        NULL, true, '30869886612');
INSERT INTO Processo_Judicial
VALUES ('7e782e9b-941e-4ba2-8b5c-4fd10c1a82a4', '2013-11-22',
        NULL, true, '40210098912');
INSERT INTO Processo_Judicial
VALUES ('1d8f180c-ddf6-4f61-a375-22eef1609cf2', '2002-8-4',
        '2019-12-2', false, '99709735615');
INSERT INTO Processo_Judicial
VALUES ('2e9b4e2d-5c51-4984-b084-a1b5acc456be', '2020-6-24',
        NULL, true, '42162135574');
INSERT INTO Processo_Judicial
VALUES ('e0f0daee-3af0-4ede-9c31-400cdba88372', '2003-9-10',
        '2019-10-20', true, '56845003822');
INSERT INTO Processo_Judicial
VALUES ('c5161483-c6e5-45e0-b42e-9162f0fe20a0', '2007-11-28',
        NULL, false, '83129861042');
INSERT INTO Processo_Judicial
VALUES ('43ff7171-78e8-4cb9-8ed7-48c7a3ea0b42', '2002-10-12',
        NULL, true, '20158254010');
INSERT INTO Processo_Judicial
VALUES ('ad5b43b1-f727-4eb9-8ace-b9fea9a0365c', '2012-7-2',
        NULL, true, '82203919910');
INSERT INTO Processo_Judicial
VALUES ('1c518765-7305-4eff-b878-95aafa7402a6', '2006-2-4',
        NULL, false, '50650208310');
INSERT INTO Processo_Judicial
VALUES ('4075afbe-b699-486d-8029-990b15d68575', '2007-4-21',
        '2019-6-9', true, '14724061477');
INSERT INTO Processo_Judicial
VALUES ('75839f8e-da8a-4af1-b3ff-cbe2f7a1afc8', '2015-2-24',
        NULL, false, '32125016890');
INSERT INTO Processo_Judicial
VALUES ('9302ada4-b7a7-4bf6-96ae-28d8b18d0ab3', '2019-5-25',
        NULL, true, '83759686551');
INSERT INTO Processo_Judicial
VALUES ('3015864b-1712-4060-9b6c-0f70666d0f7b', '2021-1-23',
        NULL, false, '79031850325');
INSERT INTO Processo_Judicial
VALUES ('8166b61d-5cbd-4baf-9831-14e63ae29ca9', '2018-11-8',
        '2021-8-21', true, '28893999643');
INSERT INTO Processo_Judicial
VALUES ('1782ae2b-3896-49f3-8ead-9be00a56d5de', '2009-4-14',
        NULL, false, '43540165110');
INSERT INTO Processo_Judicial
VALUES ('817f2bde-0fe8-44c9-8e8c-5704034d013e', '2008-12-11',
        NULL, false, '84774450208');
INSERT INTO Processo_Judicial
VALUES ('4e407fa2-4ada-434e-bcb7-431bf8a2dba8', '2010-6-6',
        NULL, false, '68651396587');
INSERT INTO Processo_Judicial
VALUES ('b8b909f4-ce6b-4ca0-93eb-237045031d55', '2010-5-12',
        NULL, true, '50661863996');
INSERT INTO Processo_Judicial
VALUES ('c75241ce-65d4-445d-83e3-f18e41dd7533', '2007-2-23',
        '2020-4-25', true, '46417632382');
INSERT INTO Processo_Judicial
VALUES ('c793b1c1-dc70-43b3-8924-94d6a1a47d07', '2003-7-24',
        '2020-8-8', true, '24989942414');
INSERT INTO Processo_Judicial
VALUES ('90a3d3c5-29d5-4c80-8b16-6b2b97d7d414', '2021-3-1',
        NULL, false, '51051183596');
INSERT INTO Processo_Judicial
VALUES ('89b5f0a5-5a1c-439d-a6ce-247753734207', '2008-1-27',
        '2018-3-7', true, '42961240594');
INSERT INTO Processo_Judicial
VALUES ('df4e0dff-5a97-48e5-bd5b-1c2abea1a6a2', '2002-12-10',
        NULL, true, '58588938803');
INSERT INTO Processo_Judicial
VALUES ('68006c1e-ff5b-4a59-b37b-6524ff83d0c1', '2009-3-8',
        '2017-6-27', true, '88271164062');
INSERT INTO Processo_Judicial
VALUES ('b6a3daa6-d798-4a8c-aacc-c4b8f213a163', '2015-10-10',
        '2020-6-18', false, '98803486214');
INSERT INTO Processo_Judicial
VALUES ('6217d10d-9ee0-421e-9bb5-8938aee7d878', '2006-5-11',
        '2017-10-31', false, '74808992438');
INSERT INTO Processo_Judicial
VALUES ('42fc45b4-dab0-4db0-9f03-e16a42a1e45d', '2018-2-6',
        NULL, false, '13525109647');
INSERT INTO Processo_Judicial
VALUES ('44b48d01-e8ea-40ab-bc9f-9e4c37ccd846', '2003-9-27',
        '2021-8-16', false, '27861878091');
INSERT INTO Processo_Judicial
VALUES ('938da1cd-a121-4864-973e-403585c0dbf3', '2011-1-11',
        NULL, false, '90985128022');
INSERT INTO Processo_Judicial
VALUES ('21307632-71e1-481d-9a19-79eeb3877243', '2010-3-24',
        '2020-12-27', false, '45628193288');
INSERT INTO Processo_Judicial
VALUES ('341915e4-0847-444d-9235-63d3fcdf53df', '2021-7-22',
        NULL, false, '68331766016');
INSERT INTO Processo_Judicial
VALUES ('9c093946-075c-4a75-b6ea-a85afd443e48', '2017-9-13',
        '2020-7-26', true, '45448827098');
INSERT INTO Processo_Judicial
VALUES ('6267b9a3-7e85-4ce2-b366-a6927d02e1cd', '2018-11-14',
        NULL, true, '97079823934');
INSERT INTO Processo_Judicial
VALUES ('7dc95e63-db00-4a2e-bfd9-98c2e6433f52', '2018-11-12',
        '2019-12-20', true, '28842566022');
INSERT INTO Processo_Judicial
VALUES ('9c05cbb2-9fe2-48a0-97a2-ec2721c39426', '2012-8-21',
        NULL, true, '38865358545');
INSERT INTO Processo_Judicial
VALUES ('3bf5b307-a2f3-4a89-9287-014450b93da7', '2011-12-12',
        '2017-1-17', false, '99693323471');
INSERT INTO Processo_Judicial
VALUES ('ab449cb6-2b83-4d9f-9262-dac79ff8b7b0', '2011-9-3',
        NULL, false, '90733551590');
INSERT INTO Processo_Judicial
VALUES ('d316d2b8-70e6-4599-9036-91c162cc1a3f', '2011-4-20',
        NULL, false, '72241387865');
INSERT INTO Processo_Judicial
VALUES ('38b8d7f4-3dc7-40ef-b879-45089dac3b63', '2007-1-9',
        NULL, true, '40100553724');
INSERT INTO Processo_Judicial
VALUES ('474100a5-2133-43a7-a309-1382e2383557', '2008-3-3',
        '2021-11-9', false, '53584502036');
INSERT INTO Processo_Judicial
VALUES ('ef102193-80b9-41e4-b2c0-23295f2dd8d6', '2003-1-8',
        NULL, false, '35410163693');
INSERT INTO Processo_Judicial
VALUES ('c669d0f8-b1e8-46a4-8f94-89e8ccb7f6ab', '2002-6-9',
        '2017-7-4', false, '71402272270');
INSERT INTO Processo_Judicial
VALUES ('f2914d9b-1904-4e7a-8dc9-c018df377220', '2014-1-9',
        NULL, false, '93640094532');
INSERT INTO Processo_Judicial
VALUES ('a936eacd-5664-44bf-b510-a6da54bfd5d1', '2002-5-22',
        '2017-2-3', true, '12995957187');
INSERT INTO Processo_Judicial
VALUES ('65c33780-95c7-4cc5-9857-4d560e8aa58c', '2005-6-7',
        NULL, true, '13391795351');
INSERT INTO Processo_Judicial
VALUES ('0e593387-2448-4392-9cfd-ffd486518b5f', '2015-10-22',
        '2017-7-6', false, '61290123986');
INSERT INTO Processo_Judicial
VALUES ('888feec7-2cdc-4fd5-ba44-ba6cd72e06e9', '2018-7-28',
        NULL, false, '76628472611');
INSERT INTO Processo_Judicial
VALUES ('7f1ca430-7abe-4d9e-bd27-28423b789b2f', '2013-11-19',
        NULL, true, '75511465452');
INSERT INTO Processo_Judicial
VALUES ('80f19c29-e896-4a7c-810d-21f3d5bca6ac', '2005-7-27',
        '2017-3-21', false, '41525154309');
INSERT INTO Processo_Judicial
VALUES ('850c316f-db98-4999-bdb9-db1ac6331ae9', '2003-5-4',
        NULL, false, '10547932805');
INSERT INTO Processo_Judicial
VALUES ('66f925cf-0148-4715-acf1-48ebb4645720', '2016-8-31',
        '2021-6-10', true, '88668754065');
INSERT INTO Processo_Judicial
VALUES ('cf2a2ce9-644c-4e68-a57d-b33339de188f', '2004-12-20',
        '2017-4-17', true, '53509038442');
INSERT INTO Processo_Judicial
VALUES ('9f2dbde5-ee3f-4a5f-99b0-3eae5847096c', '2021-8-31',
        NULL, true, '28038902608');
INSERT INTO Processo_Judicial
VALUES ('6be03713-9543-4a77-98e7-4a03ecb23698', '2009-8-5',
        NULL, false, '13099049085');
INSERT INTO Processo_Judicial
VALUES ('2dd19d82-a534-4139-babf-2bfd2a67406e', '2009-5-2',
        NULL, false, '70565871405');
INSERT INTO Processo_Judicial
VALUES ('59cbf13b-fba0-4ca9-8702-7a897b0ee139', '2011-10-24',
        NULL, true, '18635187500');
INSERT INTO Processo_Judicial
VALUES ('65361049-b540-4c55-a75e-984604923c8f', '2014-4-27',
        '2017-9-8', true, '17360159694');
INSERT INTO Processo_Judicial
VALUES ('90f031fe-d45b-4310-a369-cc9a0e82f921', '2007-6-26',
        '2019-9-14', true, '70565871405');
INSERT INTO Processo_Judicial
VALUES ('ec231cda-e207-4c36-b23f-51b1105c40f7', '2018-8-8',
        NULL, false, '36101309738');
INSERT INTO Processo_Judicial
VALUES ('bb0e2bf3-0207-4314-8055-bd838a2eb2ff', '2007-2-8',
        NULL, true, '67302381722');
INSERT INTO Processo_Judicial
VALUES ('ae3f95e8-eb58-46ec-936f-ca33647f4151', '2016-5-23',
        '2019-9-18', true, '65929289441');
INSERT INTO Processo_Judicial
VALUES ('62f404ac-7b34-4836-a09f-ee5516e88e32', '2012-1-22',
        '2018-2-3', true, '89533223744');
INSERT INTO Processo_Judicial
VALUES ('01edbcfb-3b53-4669-920c-07e96879fad8', '2010-3-23',
        '2019-11-12', true, '16521542130');
INSERT INTO Processo_Judicial
VALUES ('77c6b42e-d234-49b0-abdf-d8a889059f85', '2019-1-28',
        '2017-8-11', true, '99220432315');
INSERT INTO Processo_Judicial
VALUES ('934af254-c1ee-4d69-8454-fb674b232d75', '2010-7-31',
        '2019-8-3', false, '27861878091');
INSERT INTO Processo_Judicial
VALUES ('5ee5c4d9-e517-49a0-ad51-624810bb1546', '2004-8-20',
        NULL, true, '55587859393');
INSERT INTO Processo_Judicial
VALUES ('aa142117-09a2-4ee8-8fbf-d2ab60df3bca', '2005-5-8',
        '2018-6-17', false, '68038586615');
INSERT INTO Processo_Judicial
VALUES ('2da4c0e1-b206-4609-82fb-9b0090a1ae97', '2020-11-2',
        NULL, true, '99903466564');
INSERT INTO Processo_Judicial
VALUES ('db669bf4-dd8a-47d9-97b1-cf31ededf2b6', '2002-5-12',
        '2017-12-14', false, '92418782110');
INSERT INTO Processo_Judicial
VALUES ('420d1caf-2a6f-47ba-877b-5a6f3d32642a', '2006-5-19',
        NULL, false, '90257081068');
INSERT INTO Processo_Judicial
VALUES ('207cbc56-6710-4e04-83ed-29e041bb3e5f', '2008-6-13',
        NULL, false, '48776552942');
INSERT INTO Processo_Judicial
VALUES ('6c5cd8a5-9242-4201-b228-ae108a0bd5e7', '2019-8-6',
        NULL, false, '44718153213');
INSERT INTO Processo_Judicial
VALUES ('c00f6846-f4eb-42bb-a4c0-9af562356ba2', '2002-4-13',
        '2019-10-24', false, '55183109673');
INSERT INTO Processo_Judicial
VALUES ('38b8eb85-b3a8-4d36-8d6a-47d23263ed48', '2008-10-22',
        NULL, false, '13099049085');
INSERT INTO Processo_Judicial
VALUES ('15181e12-b6b0-4d0f-9a83-cb5c8184ba80', '2014-7-12',
        '2017-1-5', true, '17366820771');
INSERT INTO Processo_Judicial
VALUES ('2e673eae-f7c3-4373-8e3e-40bfb84bf323', '2011-10-8',
        '2018-11-16', false, '29294251089');
INSERT INTO Processo_Judicial
VALUES ('8420545a-09b7-4d96-9d6c-bca4ba13f74b', '2009-12-2',
        '2021-8-23', true, '26279341266');
INSERT INTO Processo_Judicial
VALUES ('8778e656-96e6-408c-9b72-f9b7d98796fb', '2015-1-11',
        '2017-12-2', true, '86980507716');
INSERT INTO Processo_Judicial
VALUES ('94f49a55-aa32-41d1-af2a-aa6156b814a9', '2002-6-25',
        '2019-5-11', false, '91207586100');
INSERT INTO Processo_Judicial
VALUES ('f1f0321d-4db4-415f-9316-4da5bf64f6ef', '2015-12-8',
        '2017-10-7', false, '81479468415');
INSERT INTO Processo_Judicial
VALUES ('5d61cd32-754a-4542-b442-fdfc90e5520d', '2003-4-2',
        '2021-1-26', true, '25783153302');
INSERT INTO Processo_Judicial
VALUES ('9e18468d-a934-47b7-a11d-a3acb89c1ee9', '2021-4-9',
        NULL, true, '44331545557');
INSERT INTO Processo_Judicial
VALUES ('6336c89c-d2f3-48e3-8a68-2c763f338bc9', '2005-10-25',
        '2021-11-7', true, '46389898404');
INSERT INTO Processo_Judicial
VALUES ('b33c1d12-8862-428e-99b7-00cf9c996b2f', '2009-2-26',
        '2018-1-1', false, '49829237502');
INSERT INTO Processo_Judicial
VALUES ('a21823e2-b788-4dcf-a693-c93bdd920681', '2004-12-5',
        NULL, false, '18165175339');
INSERT INTO Processo_Judicial
VALUES ('d51b8025-2d93-42e1-b434-659c497c639c', '2002-12-1',
        NULL, true, '34232794048');
INSERT INTO Processo_Judicial
VALUES ('87623056-d898-43f6-8aae-58bb18e3b01a', '2006-3-9',
        NULL, false, '94981895470');
INSERT INTO Processo_Judicial
VALUES ('64da8efa-cafc-4fb1-933c-4e47d8c3535f', '2016-7-22',
        NULL, true, '48741819467');
INSERT INTO Processo_Judicial
VALUES ('18cf7b48-bc48-471b-bcf7-1580c51dc0bd', '2014-9-29',
        '2020-7-1', true, '49970481498');
INSERT INTO Processo_Judicial
VALUES ('87af4d52-ef22-4007-994f-fcc6d1ee6f8f', '2006-4-26',
        '2021-11-14', true, '76445934206');
INSERT INTO Processo_Judicial
VALUES ('d68d7f61-0fd9-4b13-b89d-79ae0e8e0187', '2005-2-10',
        NULL, false, '66894887096');
INSERT INTO Processo_Judicial
VALUES ('bad9a0a3-9689-4206-b6e0-c84025aa5594', '2010-10-25',
        '2021-6-23', true, '79646575415');
INSERT INTO Processo_Judicial
VALUES ('a605886a-1c34-43f6-ba9e-e279d0431390', '2008-8-22',
        '2019-8-3', false, '85584778869');
INSERT INTO Processo_Judicial
VALUES ('0494de4d-4255-454a-9837-cce5480f2d24', '2014-10-26',
        NULL, true, '61699634627');
INSERT INTO Processo_Judicial
VALUES ('e5165cc4-72ce-4e37-ba32-6e34e1729759', '2004-5-16',
        NULL, true, '39251236913');
INSERT INTO Processo_Judicial
VALUES ('a92efde0-1fe4-4ba9-9eac-30fd402a1f61', '2011-3-1',
        NULL, false, '71402272270');
INSERT INTO Processo_Judicial
VALUES ('88272bd2-3403-4f60-8d8f-63006fabe319', '2003-12-19',
        '2018-10-2', false, '25783153302');
INSERT INTO Processo_Judicial
VALUES ('a37576f7-e3d4-47af-8de7-fbc8c1de03a7', '2003-3-9',
        '2021-6-28', true, '89710775923');
INSERT INTO Processo_Judicial
VALUES ('d62fbd49-0b6b-4e44-862b-b8b0240285e1', '2008-7-27',
        '2021-11-16', true, '73656000972');
INSERT INTO Processo_Judicial
VALUES ('55afac85-a915-473c-a53a-2ca611c57625', '2007-11-9',
        NULL, true, '69028166278');
INSERT INTO Processo_Judicial
VALUES ('fc22b660-fee2-4c96-ab7c-adb1ed788a85', '2004-8-8',
        '2017-4-26', false, '96239826499');
INSERT INTO Processo_Judicial
VALUES ('744ce7ab-8dec-4d37-8aa6-1678aa304c30', '2004-1-2',
        '2020-11-28', true, '29078152088');
INSERT INTO Processo_Judicial
VALUES ('cc8c8ce6-1b9c-4c10-a0e6-14386f750208', '2017-4-8',
        NULL, false, '92776450554');
INSERT INTO Processo_Judicial
VALUES ('062ce7fe-9bac-4aa2-921c-bf8e0bd157b5', '2002-1-18',
        NULL, false, '72241387865');
INSERT INTO Processo_Judicial
VALUES ('75a84dbf-e247-430f-b9d4-ebab1dca503f', '2011-4-3',
        '2021-3-24', true, '68331766016');
INSERT INTO Processo_Judicial
VALUES ('280db7dd-dceb-46bb-acc2-4340c5b12ad5', '2014-11-16',
        NULL, false, '76957148555');
INSERT INTO Processo_Judicial
VALUES ('8c1ff33d-07c4-41fe-ae60-d1e7ac171e69', '2006-6-17',
        '2018-12-14', true, '92465915710');
INSERT INTO Processo_Judicial
VALUES ('19b1e4e1-be87-488b-98b1-521c3e014d5b', '2004-9-16',
        NULL, true, '27934283968');
INSERT INTO Processo_Judicial
VALUES ('1cb30f1e-ce3d-47a8-a82e-8bd99a525ec7', '2015-8-10',
        '2017-7-15', false, '67661317153');
INSERT INTO Processo_Judicial
VALUES ('ea188149-ae1e-4668-a9e2-aaf316eec311', '2003-6-29',
        NULL, true, '53108889381');
INSERT INTO Processo_Judicial
VALUES ('f5898244-2baf-4a84-a6fe-8f6e5462fed0', '2009-5-28',
        '2020-8-7', true, '69932859244');
INSERT INTO Processo_Judicial
VALUES ('c9e39e87-0bbb-466d-a827-97fb75741b9f', '2017-5-23',
        NULL, false, '21879325024');
INSERT INTO Processo_Judicial
VALUES ('c5a807c4-8df3-43e0-9431-c49059ac7148', '2017-6-9',
        '2019-5-18', true, '55340310402');
INSERT INTO Processo_Judicial
VALUES ('3a1ac3b8-9931-4dcc-80bd-c28dfb8e089c', '2013-1-28',
        '2018-4-12', false, '83073222993');
INSERT INTO Processo_Judicial
VALUES ('8827dbd0-244e-4786-8f27-f9e5de02a444', '2019-8-22',
        NULL, true, '56009768713');
INSERT INTO Processo_Judicial
VALUES ('880d8707-d676-44d5-830f-d01f87f35141', '2012-10-10',
        NULL, true, '35275697032');
INSERT INTO Processo_Judicial
VALUES ('e52ea5a2-52b3-4f02-bc04-ffbf79f9713e', '2019-11-1',
        '2017-8-28', true, '88463596005');
INSERT INTO Processo_Judicial
VALUES ('406f5fd3-85de-4e9b-b941-f2cee4aca45b', '2020-7-18',
        NULL, false, '71358629062');
INSERT INTO Processo_Judicial
VALUES ('98896659-a669-47ad-83bf-f22105316e06', '2003-11-2',
        '2019-6-3', true, '31219225791');
INSERT INTO Processo_Judicial
VALUES ('7e8bde0f-adac-498d-8be6-4dad5e827310', '2017-5-2',
        NULL, false, '81137500617');
INSERT INTO Processo_Judicial
VALUES ('7879d7cf-9335-4a00-b27c-d411d6505de0', '2010-3-2',
        '2019-9-24', true, '54644412510');
INSERT INTO Processo_Judicial
VALUES ('46de4176-8a9c-432d-8cc0-4f36b0eb93cd', '2009-6-22',
        '2019-2-26', false, '88044670873');
INSERT INTO Processo_Judicial
VALUES ('bc655d9d-215c-4b64-9ce3-f3129a1e01ae', '2011-2-9',
        '2020-12-24', true, '96588067063');
INSERT INTO Processo_Judicial
VALUES ('ead4f57a-ac8d-471f-ad13-d06fd11175b7', '2018-9-24',
        '2021-9-2', true, '63900773341');
INSERT INTO Processo_Judicial
VALUES ('5fb13d59-44a0-4fba-aa0f-3e7259422248', '2020-6-24',
        '2020-12-10', false, '44884157183');
INSERT INTO Processo_Judicial
VALUES ('5e0a3a1f-8140-406a-baf3-be53f83f27a0', '2002-2-20',
        NULL, false, '54063647601');
INSERT INTO Processo_Judicial
VALUES ('b01a5d94-e867-4234-9624-21e3a75cc045', '2018-1-11',
        '2021-5-30', true, '50661863996');
INSERT INTO Processo_Judicial
VALUES ('fd0eaf2b-d34f-4432-99cd-c9217b5413d8', '2006-12-27',
        NULL, false, '71402272270');
INSERT INTO Processo_Judicial
VALUES ('7038b6e8-7fa5-41e6-85d4-f47a61c126e3', '2018-2-10',
        '2018-10-26', true, '53791592104');
INSERT INTO Processo_Judicial
VALUES ('b695edee-2c00-471e-9267-8c6ecaa5133b', '2011-8-3',
        '2018-10-21', false, '56206870884');
INSERT INTO Processo_Judicial
VALUES ('1f38108a-15f9-4614-925c-67c89193a5b6', '2005-8-13',
        NULL, true, '70077948186');
INSERT INTO Processo_Judicial
VALUES ('dfba3e09-8a2e-4310-900c-bc82f50f9e8c', '2011-8-5',
        NULL, true, '26318127936');
INSERT INTO Processo_Judicial
VALUES ('333c9deb-14f9-425e-8779-d7e6d34252d4', '2021-9-10',
        '2019-3-13', false, '29509833429');
INSERT INTO Processo_Judicial
VALUES ('c394c703-c54a-423f-acb2-0aa1383ae510', '2017-11-22',
        NULL, false, '46417632382');
INSERT INTO Processo_Judicial
VALUES ('7fa50cc5-d6bd-4d98-a00b-1c9fa95d4a45', '2008-1-21',
        NULL, true, '20934364222');
INSERT INTO Processo_Judicial
VALUES ('5e32746b-88fd-44bc-b562-cce2aff7e3a4', '2013-3-18',
        NULL, true, '38185161759');
INSERT INTO Processo_Judicial
VALUES ('b7881389-bce4-47d9-a044-8b827842376f', '2019-10-6',
        '2020-9-10', false, '76793153581');
INSERT INTO Processo_Judicial
VALUES ('95113a8c-1458-4988-8ddb-f0c98dd65a53', '2007-9-27',
        '2020-12-21', true, '93301798028');
INSERT INTO Processo_Judicial
VALUES ('96d6ed37-baad-411a-b65a-721be7a32785', '2008-11-9',
        '2019-4-25', true, '40210098912');
INSERT INTO Processo_Judicial
VALUES ('2bd82783-8a56-4038-a38b-8a100ea98966', '2010-8-4',
        '2017-6-29', true, '60893714134');
INSERT INTO Processo_Judicial
VALUES ('d04b1a49-0b31-48a8-bc19-e07b22ac4882', '2008-9-6',
        NULL, false, '15407267932');
INSERT INTO Processo_Judicial
VALUES ('8812c7a0-f862-406e-b271-f5642a54b57e', '2020-11-24',
        '2021-4-17', true, '63900773341');
INSERT INTO Processo_Judicial
VALUES ('d7fc9823-5ef4-4df4-94b3-c88372805ddc', '2003-7-20',
        '2017-5-15', false, '91382141099');
INSERT INTO Processo_Judicial
VALUES ('d2691991-7fa4-4e60-ae57-64f6ec5a89b1', '2004-10-5',
        NULL, false, '72516597094');
INSERT INTO Processo_Judicial
VALUES ('8870c433-b7c8-47df-a2dc-0442e58b931e', '2004-10-7',
        NULL, false, '32466301082');
INSERT INTO Processo_Judicial
VALUES ('423e2c6b-9832-4462-9f45-f2cb7cbe2847', '2014-9-26',
        NULL, false, '85119483100');
INSERT INTO Processo_Judicial
VALUES ('33b1743a-ce62-4480-a498-3f2f76974466', '2021-5-17',
        '2019-2-12', true, '73315387605');
INSERT INTO Processo_Judicial
VALUES ('bc5ed792-7194-4022-9ad3-4b515f019e3f', '2017-11-12',
        '2017-7-24', false, '24302034655');
INSERT INTO Processo_Judicial
VALUES ('235cf787-e505-4266-a8f8-82988408cdeb', '2018-11-21',
        '2020-4-28', true, '31959316115');
INSERT INTO Processo_Judicial
VALUES ('297b93a6-6ffd-47e5-b086-ed75e90f6b82', '2014-6-27',
        NULL, false, '79646575415');
INSERT INTO Processo_Judicial
VALUES ('7bd6569d-4fbd-4f25-acd8-eb2c21a1b043', '2010-6-4',
        NULL, true, '50602269105');
INSERT INTO Processo_Judicial
VALUES ('6e8f0a5f-e804-435e-ac8a-ab8df76f2575', '2001-12-22',
        '2018-10-3', true, '19081247556');
INSERT INTO Processo_Judicial
VALUES ('ec90a4ac-c033-4a17-be1b-9e53407a9e79', '2002-8-8',
        '2019-10-31', true, '85739130568');
INSERT INTO Processo_Judicial
VALUES ('6805ecb2-36fd-4839-bde6-1303d1328589', '2017-1-6',
        '2017-6-12', false, '27934283968');
INSERT INTO Processo_Judicial
VALUES ('9b0ec2b8-ce3b-442d-b382-42713284eeef', '2007-8-29',
        NULL, true, '88271164062');
INSERT INTO Processo_Judicial
VALUES ('83a09a75-8702-4d15-8f40-05289d40da71', '2007-4-20',
        NULL, true, '41397188589');
INSERT INTO Processo_Judicial
VALUES ('4c33e4a6-c445-45f4-acd0-6ce947677151', '2006-1-30',
        NULL, true, '94763610071');
INSERT INTO Processo_Judicial
VALUES ('a2897aff-64ca-4a6f-9394-d7c0059ebdbd', '2003-2-26',
        NULL, false, '68666926997');
INSERT INTO Processo_Judicial
VALUES ('9e9c9208-3d2c-4e6b-9662-f9668dae9b20', '2001-12-9',
        '2021-10-30', false, '74355497739');
INSERT INTO Processo_Judicial
VALUES ('cd121632-5db6-4bce-93b1-0d07944b03c8', '2020-4-17',
        NULL, false, '10204609066');
INSERT INTO Processo_Judicial
VALUES ('b9d2aac8-e724-49b2-ac01-362ca8bf25ad', '2009-10-11',
        '2017-8-22', true, '53509038442');
INSERT INTO Processo_Judicial
VALUES ('0826ecd8-543d-45f4-bf17-1faa9511ea91', '2011-3-10',
        NULL, false, '43260389566');
INSERT INTO Processo_Judicial
VALUES ('aab6cc87-ddfc-426b-8285-dee3cc4dbc39', '2015-8-9',
        '2021-5-22', true, '11133646557');
INSERT INTO Processo_Judicial
VALUES ('0428318d-51ab-44bd-8c83-4eddb67c56e5', '2007-2-24',
        '2018-9-29', false, '13908656504');
INSERT INTO Processo_Judicial
VALUES ('fce19992-3953-4576-8e37-208a447a090f', '2008-4-2',
        '2020-9-7', false, '58487967234');
INSERT INTO Processo_Judicial
VALUES ('c695a2e2-01db-4403-8d07-39fb7442f8f3', '2013-2-22',
        NULL, true, '80266070396');
INSERT INTO Processo_Judicial
VALUES ('6972e3b0-15ae-4553-b33c-f04cd1332598', '2019-3-23',
        '2016-12-5', false, '83073222993');
INSERT INTO Processo_Judicial
VALUES ('3d8137e9-4fc7-4f73-afaf-96d591a8e956', '2002-6-14',
        '2021-8-16', true, '39112057778');
INSERT INTO Processo_Judicial
VALUES ('bfa55edc-6ec6-4232-9ac1-87c077df261a', '2008-4-16',
        NULL, true, '55711421784');
INSERT INTO Processo_Judicial
VALUES ('e0df6cea-80ba-4a37-9424-aac18e5a0759', '2009-4-1',
        NULL, true, '84785704296');
INSERT INTO Processo_Judicial
VALUES ('6d78a35e-4ce4-4740-b5d2-3a6c86a3c7bf', '2004-10-18',
        '2017-10-12', true, '16469240479');
INSERT INTO Processo_Judicial
VALUES ('725ec101-961a-4265-b67b-c7408c84850b', '2021-8-11',
        NULL, false, '75959301025');
INSERT INTO Processo_Judicial
VALUES ('bc5fdf0a-f7f9-48d7-bd7a-6f222b1796a2', '2014-8-12',
        '2017-7-17', true, '78880145065');
INSERT INTO Processo_Judicial
VALUES ('f34e0985-88eb-43b5-b60e-479556657323', '2015-7-27',
        '2018-12-13', true, '25737077812');
INSERT INTO Processo_Judicial
VALUES ('915dd96a-f35d-44f2-a3ee-85886c79aba4', '2015-2-10',
        NULL, true, '91896277903');
INSERT INTO Processo_Judicial
VALUES ('e598b027-d62d-4872-b36f-74b7f78f8e9b', '2004-5-9',
        NULL, false, '34864473633');
INSERT INTO Processo_Judicial
VALUES ('ea301534-37fc-4512-90df-7321a24993fc', '2019-6-29',
        NULL, false, '50661863996');
INSERT INTO Processo_Judicial
VALUES ('f2d9d6e0-35b2-4d19-86e7-a343eed564c1', '2002-6-9',
        '2017-2-13', true, '37735666024');
INSERT INTO Processo_Judicial
VALUES ('a6ba1c5b-b47b-4bb5-8466-536fe31ed7ae', '2008-11-1',
        NULL, true, '34047008347');
INSERT INTO Processo_Judicial
VALUES ('528700f5-560e-4a7d-815a-1ed9cc4e66b8', '2008-3-29',
        '2018-2-27', true, '46389898404');
INSERT INTO Processo_Judicial
VALUES ('05900e75-4159-426d-813b-e47de00d605a', '2002-3-28',
        '2021-1-2', true, '29139758762');
INSERT INTO Processo_Judicial
VALUES ('98441fca-0d6a-42eb-ade2-a4a8baeaa923', '2019-4-9',
        NULL, true, '21487003488');
INSERT INTO Processo_Judicial
VALUES ('64ae91b4-7967-459e-87ae-3175d19432e9', '2018-6-19',
        '2017-12-12', true, '77363675071');
INSERT INTO Processo_Judicial
VALUES ('67f98a5f-4971-44c7-bcb9-79ac084fa708', '2021-3-10',
        '2020-1-6', true, '33932909250');
INSERT INTO Processo_Judicial
VALUES ('a9eba840-0cf5-4bdc-84af-57074f265b9f', '2019-1-5',
        '2021-4-28', false, '15334344431');
INSERT INTO Processo_Judicial
VALUES ('9121982f-aa40-4027-9f00-1d4a6ed6babf', '2021-9-26',
        '2021-5-9', true, '69487778153');
INSERT INTO Processo_Judicial
VALUES ('2419880b-afeb-4425-93d3-f160a3c086bb', '2015-2-16',
        '2018-12-26', true, '23072280755');
INSERT INTO Processo_Judicial
VALUES ('f17b6dd1-8a93-449a-a977-f307371520a9', '2003-6-17',
        NULL, false, '74122189518');
INSERT INTO Processo_Judicial
VALUES ('559c3021-e614-48ca-8dd3-bf3452f64487', '2018-9-2',
        NULL, true, '54644412510');
INSERT INTO Processo_Judicial
VALUES ('179e2739-bcce-4795-8aba-8479d3afa910', '2008-4-16',
        '2020-6-18', true, '88576750692');
INSERT INTO Processo_Judicial
VALUES ('8ec0bc7f-612e-4af3-a417-3b1b47fd2c0d', '2020-4-23',
        '2021-2-8', true, '55663887299');
INSERT INTO Processo_Judicial
VALUES ('76fa413e-eb13-4653-a3ff-6e95265152b1', '2008-11-14',
        NULL, false, '52019781784');
INSERT INTO Processo_Judicial
VALUES ('af1ceb37-cc01-4b41-a05c-35bf4d5c0dd6', '2010-11-28',
        '2017-8-25', false, '28842566022');
INSERT INTO Processo_Judicial
VALUES ('a3d77d3a-cd67-4fd4-ad61-89056b67137e', '2011-9-24',
        '2020-3-6', true, '37988147598');
INSERT INTO Processo_Judicial
VALUES ('c71c699d-3cf5-4894-9a15-2bed0b505f10', '2006-2-21',
        NULL, true, '83880074904');
INSERT INTO Processo_Judicial
VALUES ('98b53ce8-b797-41d5-9cd8-3c7921f438eb', '2019-2-2',
        '2019-9-29', true, '37254095533');
INSERT INTO Processo_Judicial
VALUES ('ae89e527-4810-4965-bb48-4f3d7c7e18fb', '2016-9-3',
        '2020-3-14', true, '90733551590');
INSERT INTO Processo_Judicial
VALUES ('811c79db-3620-4d7c-bcb3-eaaef8a0120b', '2021-3-12',
        NULL, true, '80518763633');
INSERT INTO Processo_Judicial
VALUES ('1d160579-5d0e-4064-8c1a-c566ec2e4b01', '2021-1-27',
        '2018-11-4', true, '73645120004');
INSERT INTO Processo_Judicial
VALUES ('05857ae1-4301-4fbd-8f4d-c16c86f702b8', '2015-8-6',
        NULL, false, '69930587140');
INSERT INTO Processo_Judicial
VALUES ('39d4359e-e769-442f-bdff-ecbb4bc4b357', '2017-4-26',
        NULL, true, '49970481498');
INSERT INTO Processo_Judicial
VALUES ('a8b40a7d-ad24-4461-acc4-4aaa643cf425', '2020-5-15',
        '2021-6-10', true, '37706179977');
INSERT INTO Processo_Judicial
VALUES ('0fddaea1-5d3e-4c45-a46f-0a37669e35d4', '2008-2-16',
        NULL, true, '36943202530');
INSERT INTO Processo_Judicial
VALUES ('8a54c8d4-23dc-44fe-b25d-96aff67bd68f', '2017-9-13',
        '2017-3-31', false, '86252562392');
INSERT INTO Processo_Judicial
VALUES ('17afcc61-9c06-4eb3-b0fb-e2e98d7c7d78', '2019-10-27',
        '2017-4-20', true, '46683265664');
INSERT INTO Processo_Judicial
VALUES ('0131f7be-f292-4126-a5eb-8e663eea7219', '2012-1-28',
        NULL, true, '68837744630');
INSERT INTO Processo_Judicial
VALUES ('d1ce62ef-b14e-45f1-869b-b4136c637edd', '2004-2-16',
        '2017-2-7', false, '66159643984');
INSERT INTO Processo_Judicial
VALUES ('2b3b4309-09c6-4f53-8af6-3682cde4ac04', '2013-8-8',
        NULL, false, '35895102075');
INSERT INTO Processo_Judicial
VALUES ('50918760-cfc2-4c68-91ad-08f8c60f6fc1', '2006-12-10',
        '2018-1-4', true, '23625731619');
INSERT INTO Processo_Judicial
VALUES ('9ae48458-a13a-478a-8794-1badaf0caf4f', '2020-5-25',
        '2021-3-17', true, '61522070106');
INSERT INTO Processo_Judicial
VALUES ('1fd562eb-49ac-46ae-b40e-a24671eb7156', '2010-4-19',
        NULL, true, '33855974653');
INSERT INTO Processo_Judicial
VALUES ('5978c814-af88-42d5-a125-4b4c6492da2d', '2013-9-18',
        NULL, true, '25196086270');
INSERT INTO Processo_Judicial
VALUES ('3d0b0927-4353-434a-a4cd-7e0805e663c6', '2014-12-16',
        '2018-4-27', false, '32128272987');
INSERT INTO Processo_Judicial
VALUES ('0c42c446-e961-46ed-b109-101a141a3018', '2008-4-14',
        '2021-8-7', true, '46597759188');
INSERT INTO Processo_Judicial
VALUES ('c773a140-f22c-4c20-89dc-f18702c39e17', '2012-8-6',
        NULL, true, '13211265460');
INSERT INTO Processo_Judicial
VALUES ('e7eda7bb-375d-4aba-8ad7-317517682e17', '2017-3-29',
        '2017-9-9', true, '92201869981');
INSERT INTO Processo_Judicial
VALUES ('62a675db-3994-4340-90b3-d32e10aca49a', '2009-12-13',
        NULL, false, '48246632281');
INSERT INTO Processo_Judicial
VALUES ('3737a00e-c5fd-49d5-828b-c27524fcc80a', '2015-10-24',
        '2021-8-30', false, '54010952000');
INSERT INTO Processo_Judicial
VALUES ('20decf16-b3bb-4157-959f-cf42060ad7f9', '2010-6-10',
        '2019-8-18', true, '25677760089');
INSERT INTO Processo_Judicial
VALUES ('38072aa3-ea27-4c47-a6c5-969973d258da', '2002-1-24',
        NULL, false, '25264475266');
INSERT INTO Processo_Judicial
VALUES ('4d947c14-257c-4aba-8ef3-9beb31aea5e8', '2010-2-7',
        '2020-9-29', true, '19264541170');
INSERT INTO Processo_Judicial
VALUES ('ac3e0291-adaf-48a2-9df5-ea27340a2134', '2002-12-5',
        '2020-10-25', true, '66539061414');
INSERT INTO Processo_Judicial
VALUES ('025deb61-1881-4540-b291-bcc179c8d192', '2004-10-29',
        NULL, true, '87642632594');
INSERT INTO Processo_Judicial
VALUES ('2df56a6f-b38c-4629-a405-00cc6f1332b9', '2010-8-26',
        '2020-12-5', true, '43344490984');
INSERT INTO Processo_Judicial
VALUES ('ad34bfce-e73f-44b9-8913-0ca239b46039', '2005-12-18',
        NULL, true, '29613642755');
INSERT INTO Processo_Judicial
VALUES ('79037942-1e99-49a7-8bdd-a02cd1ebbb97', '2005-4-7',
        NULL, true, '36434444980');
INSERT INTO Processo_Judicial
VALUES ('ebc44588-c297-44e4-85c3-4e2fd39da085', '2013-7-4',
        '2018-6-28', false, '49723011339');
INSERT INTO Processo_Judicial
VALUES ('7653adab-7a1a-4dbf-b064-65ca5262540a', '2019-5-20',
        '2016-11-29', true, '48246632281');
INSERT INTO Processo_Judicial
VALUES ('2c77c4ec-7803-4b62-a749-9c51039572b7', '2017-1-1',
        '2018-1-11', true, '14975074331');
INSERT INTO Processo_Judicial
VALUES ('488bc324-bbc8-4865-913a-ddac78a49317', '2010-11-9',
        '2020-8-13', false, '37135223362');
INSERT INTO Processo_Judicial
VALUES ('ca58230c-24e2-46c7-8d18-0a12e846ee51', '2020-8-3',
        '2021-9-24', false, '41583542709');
INSERT INTO Processo_Judicial
VALUES ('95ee1689-0242-4004-9e7b-e3c3989c6e5b', '2012-12-7',
        NULL, true, '26038876282');
INSERT INTO Processo_Judicial
VALUES ('8f81501a-ba3e-4e58-82fb-f336dc41ee56', '2006-12-17',
        NULL, true, '16127951364');
INSERT INTO Processo_Judicial
VALUES ('2be39f99-d8aa-41bb-ac9f-127fb0a9ba30', '2002-2-20',
        NULL, true, '60652495953');
INSERT INTO Processo_Judicial
VALUES ('9d83c4f5-514b-4941-aa30-2f4d82b74e7f', '2014-7-31',
        NULL, false, '20158254010');
INSERT INTO Processo_Judicial
VALUES ('0db177b5-d43c-45ab-8874-221e879c6605', '2019-6-10',
        NULL, false, '44718153213');
INSERT INTO Processo_Judicial
VALUES ('275ae29b-52c8-4608-b2a4-088ac4226482', '2002-6-7',
        '2018-10-12', false, '68767157313');
INSERT INTO Processo_Judicial
VALUES ('f808d16e-385c-4e08-8796-f1d90693e6e0', '2018-5-6',
        '2019-6-15', true, '15201660203');
INSERT INTO Processo_Judicial
VALUES ('223e7b71-2b07-462d-8232-5a457bd3ef7d', '2002-2-22',
        NULL, false, '29694294098');
INSERT INTO Processo_Judicial
VALUES ('a626a741-78e1-4f62-bc5e-a37b70aa9bb3', '2014-6-19',
        '2017-11-17', false, '93519565530');
INSERT INTO Processo_Judicial
VALUES ('85bb6a0f-3027-44ce-a63e-df20f1cda94f', '2010-12-31',
        NULL, true, '31128941818');
INSERT INTO Processo_Judicial
VALUES ('d8d0a25a-d88e-477c-a9ab-e88d0a6a2e7b', '2016-7-18',
        NULL, false, '91296067000');
INSERT INTO Processo_Judicial
VALUES ('4082e5d8-36a1-4c24-8558-18006421ca52', '2005-9-18',
        NULL, false, '69571564621');
INSERT INTO Processo_Judicial
VALUES ('3ed64da3-d1b8-4df9-a0e6-8c16cc3e2386', '2016-3-20',
        '2019-12-23', true, '56085495813');
INSERT INTO Processo_Judicial
VALUES ('5eed3e50-b82e-488c-b98b-37bb585b62ce', '2012-5-20',
        '2018-7-29', false, '67214462850');
INSERT INTO Processo_Judicial
VALUES ('78c2255c-e64c-48b9-b02b-1450e26b35ed', '2002-3-22',
        NULL, false, '77054765247');
INSERT INTO Processo_Judicial
VALUES ('728fac2f-2ede-46ca-a946-792130d54df0', '2007-12-14',
        '2017-5-24', false, '87476298043');
INSERT INTO Processo_Judicial
VALUES ('e0e8b24e-2fad-4234-abef-ca44f972f7bb', '2006-9-21',
        '2020-6-22', false, '48273120142');
INSERT INTO Processo_Judicial
VALUES ('8479dbaa-65a9-481b-a9a7-6044dd119bf2', '2018-7-21',
        '2018-6-14', true, '65680290067');
INSERT INTO Processo_Judicial
VALUES ('6582d6b4-abad-4355-9678-a8be87998ecd', '2013-9-20',
        '2018-5-2', false, '97468617402');
INSERT INTO Processo_Judicial
VALUES ('1a6a8ef5-3001-4c7a-9271-a2b9d8ba420b', '2021-2-14',
        NULL, true, '67008212334');
INSERT INTO Processo_Judicial
VALUES ('b8620109-c284-4109-9b57-9828a4933985', '2011-4-16',
        '2019-9-20', false, '98543534772');
INSERT INTO Processo_Judicial
VALUES ('c97be663-b477-4afd-b961-80afed6084bf', '2011-5-10',
        '2021-5-18', false, '91857076140');
INSERT INTO Processo_Judicial
VALUES ('63c788b8-c0e6-4460-a3e2-b5bbb49e8313', '2013-9-17',
        NULL, false, '65458204417');
INSERT INTO Processo_Judicial
VALUES ('83b40f79-64e4-4264-bef3-8ec658d9977b', '2021-5-28',
        '2017-2-25', false, '18505114549');
INSERT INTO Processo_Judicial
VALUES ('c2139e87-cf66-4d2e-8b14-64cfc1676da0', '2017-6-5',
        NULL, true, '20934364222');
INSERT INTO Processo_Judicial
VALUES ('418b3145-2e70-4ef8-ad0d-5b8fa44bf1a4', '2015-7-19',
        NULL, false, '15123706744');
INSERT INTO Processo_Judicial
VALUES ('5cdda2fd-67f0-4794-8e20-e00ea54cfa68', '2002-3-20',
        '2020-11-24', true, '96349825211');
INSERT INTO Processo_Judicial
VALUES ('3cf04bc3-a6bf-4650-afdb-a0ecd30f3f91', '2003-5-31',
        NULL, false, '26168256616');
INSERT INTO Processo_Judicial
VALUES ('3e45e7ef-c32f-4e76-bc78-df237a0b4310', '2017-5-14',
        NULL, false, '62031259345');
INSERT INTO Processo_Judicial
VALUES ('82a509d8-2308-4ba9-bdec-0962cab4958a', '2019-10-27',
        NULL, true, '58254329771');
INSERT INTO Processo_Judicial
VALUES ('1c2e8830-5c8e-4463-bdd8-2cc18d6a45f8', '2004-8-10',
        NULL, false, '87476298043');
INSERT INTO Processo_Judicial
VALUES ('810e2da2-0d7e-4ba4-bc4a-2baf668768ab', '2016-8-20',
        NULL, true, '67123855608');
INSERT INTO Processo_Judicial
VALUES ('4c345764-3fd7-4c93-9617-0d335e2fc0aa', '2019-6-22',
        NULL, false, '42455865163');
INSERT INTO Processo_Judicial
VALUES ('49a9329e-ca1f-4d60-be4c-8f2978598a38', '2002-3-28',
        '2020-3-18', true, '92095009516');
INSERT INTO Processo_Judicial
VALUES ('8560e94f-2c4f-4464-82ff-da55fda37a2b', '2016-12-11',
        '2017-4-5', true, '79606743648');
INSERT INTO Processo_Judicial
VALUES ('e42ba160-f017-4bd7-b81d-1b9064b04fa3', '2007-2-17',
        '2020-11-16', true, '76377020021');
INSERT INTO Processo_Judicial
VALUES ('75283e35-1814-46e3-a9dd-71d8e60242f5', '2002-2-17',
        '2020-9-8', false, '88271164062');
INSERT INTO Processo_Judicial
VALUES ('ecd45e42-1fbf-4c47-a369-f41a4a346d82', '2005-5-3',
        NULL, true, '76737339326');
INSERT INTO Processo_Judicial
VALUES ('3df7ff42-80c6-43e2-9b50-5f7dd7e331b9', '2009-11-22',
        NULL, true, '94322587393');
INSERT INTO Processo_Judicial
VALUES ('3b7075a5-7805-4ea4-9a17-09c64c1f823b', '2011-5-4',
        '2018-4-12', false, '85872988284');
INSERT INTO Processo_Judicial
VALUES ('42c27639-c14a-43f1-aca8-cdf90b1bd731', '2013-6-11',
        '2020-6-12', false, '96239826499');
INSERT INTO Processo_Judicial
VALUES ('74020d8f-6401-4eea-aaa2-a31e36d3fc2b', '2004-6-12',
        '2017-8-18', true, '60623790931');
INSERT INTO Processo_Judicial
VALUES ('f00ce783-cf87-4f74-97dd-c07623a7040d', '2019-12-16',
        NULL, true, '13641347680');
INSERT INTO Processo_Judicial
VALUES ('17b3b0ce-c809-43f5-8518-f449d5516412', '2019-4-15',
        NULL, false, '68540927693');
INSERT INTO Processo_Judicial
VALUES ('91e7776b-0e44-42b7-a34e-033df7abf7c4', '2005-11-15',
        NULL, true, '76737339326');
INSERT INTO Processo_Judicial
VALUES ('b8364ed6-4249-4954-b561-914437ab99c9', '2011-2-15',
        NULL, true, '79646575415');
INSERT INTO Processo_Judicial
VALUES ('f11e494c-eca9-4500-8235-1baf5501b794', '2017-7-29',
        '2017-4-23', false, '72597053705');
INSERT INTO Processo_Judicial
VALUES ('0267b4d4-adf2-4f03-921a-1041de3057e0', '2005-10-20',
        '2021-1-22', false, '25196086270');
INSERT INTO Processo_Judicial
VALUES ('dbb79021-850f-468c-82e1-7bf999f6ac6f', '2020-3-19',
        NULL, false, '46683265664');
INSERT INTO Processo_Judicial
VALUES ('f57c9349-09fd-466d-be34-0b1315537404', '2005-10-15',
        NULL, false, '52019781784');
INSERT INTO Processo_Judicial
VALUES ('e1eee187-f55f-4934-9a0c-b437cebaceb5', '2005-2-23',
        NULL, true, '26766975226');
INSERT INTO Processo_Judicial
VALUES ('bf77acc1-8afc-4c2b-8579-c54c5f0d5e8d', '2013-2-27',
        '2017-8-3', false, '25738695184');
INSERT INTO Processo_Judicial
VALUES ('7529f6b2-563d-4028-915b-2fcffecd1db0', '2010-3-14',
        NULL, true, '22431804153');
INSERT INTO Processo_Judicial
VALUES ('b3448daa-8962-4eeb-a3d0-7dd8bfed7cc6', '2014-8-10',
        '2019-7-2', false, '34528599961');
INSERT INTO Processo_Judicial
VALUES ('497fe7ac-e54b-46a1-b945-0f9f5a3f937d', '2019-9-10',
        NULL, true, '59884439555');
INSERT INTO Processo_Judicial
VALUES ('4b464833-5883-4d5a-91bd-e6774302575e', '2015-1-18',
        '2020-8-4', false, '74122189518');
INSERT INTO Processo_Judicial
VALUES ('e179c4c2-0624-4176-b9fb-e8c96497592b', '2010-12-31',
        NULL, true, '55587859393');
INSERT INTO Processo_Judicial
VALUES ('a8df3a8d-0c39-48a1-9a6d-d202f85bfce0', '2019-7-23',
        '2021-4-2', false, '16195919734');
INSERT INTO Processo_Judicial
VALUES ('ff6a6bec-a59d-4c0f-85da-bc38ea48e91a', '2005-2-5',
        NULL, false, '30621758850');
INSERT INTO Processo_Judicial
VALUES ('8637aa66-9694-4476-be59-354c625d1b72', '2006-10-26',
        '2017-8-20', true, '56364648623');
INSERT INTO Processo_Judicial
VALUES ('02c61364-c93e-4f7d-8f18-55e820a648ac', '2002-1-29',
        NULL, false, '74025096402');
INSERT INTO Processo_Judicial
VALUES ('039b16f3-50c4-4bd6-b275-3baa39238fbf', '2020-10-26',
        '2017-12-4', false, '34864473633');
INSERT INTO Processo_Judicial
VALUES ('687e5327-8dda-4001-9974-eb81ccead85d', '2018-1-17',
        '2020-12-18', true, '34657710711');
INSERT INTO Processo_Judicial
VALUES ('3463c845-1f31-4bf5-b00b-654029c4afae', '2017-11-6',
        '2017-10-15', true, '59028294656');
INSERT INTO Processo_Judicial
VALUES ('b690f83a-860e-4184-84ce-88fe22ce9377', '2007-6-3',
        NULL, false, '69270376081');
INSERT INTO Processo_Judicial
VALUES ('bd97e62a-2fbe-48ce-aa84-67dde7d511e5', '2002-8-6',
        '2017-5-8', true, '63763126712');
INSERT INTO Processo_Judicial
VALUES ('36449ff3-03f7-4cc3-b407-6aafdd921da6', '2016-6-20',
        '2018-2-21', false, '52203854476');
INSERT INTO Processo_Judicial
VALUES ('b1a67e0c-f485-4979-90f5-82dac8b58030', '2014-1-26',
        NULL, false, '95630513457');
INSERT INTO Processo_Judicial
VALUES ('edb4af12-e50e-4d6c-8628-30ef587614d5', '2013-1-15',
        NULL, true, '39274698467');
INSERT INTO Processo_Judicial
VALUES ('6b7d5132-6f3e-43f9-b160-2d4283af4a75', '2011-9-23',
        NULL, false, '20158254010');
INSERT INTO Processo_Judicial
VALUES ('2fead518-da04-482f-85bf-5cf87767d312', '2010-12-19',
        NULL, false, '56437012213');
INSERT INTO Processo_Judicial
VALUES ('a1c967c0-37be-40f5-afcd-21b27f60814a', '2004-6-17',
        '2017-10-17', true, '65680290067');
INSERT INTO Processo_Judicial
VALUES ('947b15a6-20dc-4210-9623-7bf951b6ca95', '2002-2-14',
        NULL, false, '41139387378');
INSERT INTO Processo_Judicial
VALUES ('9c7d35e1-5274-4940-b0cd-f9cd39712c05', '2013-9-21',
        '2019-1-29', true, '41765983633');
INSERT INTO Processo_Judicial
VALUES ('39a84bb8-811e-4631-803c-3c70fd9202e9', '2003-4-16',
        '2019-6-9', false, '51777044697');
INSERT INTO Processo_Judicial
VALUES ('035c6b52-9347-46b0-b199-a639d91aee4b', '2014-11-10',
        NULL, false, '67031022950');
INSERT INTO Processo_Judicial
VALUES ('1c93291d-5bd7-47e6-a944-8fcdc0a2672b', '2020-5-29',
        '2021-9-7', true, '52510659939');
INSERT INTO Processo_Judicial
VALUES ('fcc5f947-2a0a-4d5f-b4c6-0aaa2b1e54d4', '2004-2-17',
        '2018-11-30', false, '28038902608');
INSERT INTO Processo_Judicial
VALUES ('7000d18d-789e-4638-b205-f5451aeb1798', '2011-2-9',
        NULL, false, '10292860679');
INSERT INTO Processo_Judicial
VALUES ('94c447c9-7ce1-4778-96cd-01fa3f716adc', '2011-9-7',
        NULL, false, '91382141099');
INSERT INTO Processo_Judicial
VALUES ('055957de-951a-4c9e-b0a6-59830074c763', '2016-5-24',
        NULL, false, '62156000735');
INSERT INTO Processo_Judicial
VALUES ('289aaf63-ad53-4d07-b9e1-9898618e8dfe', '2021-6-29',
        NULL, false, '42516188630');
INSERT INTO Processo_Judicial
VALUES ('29f6976f-13ac-405d-b46f-ffd009364ba5', '2004-5-20',
        NULL, false, '23186676069');
INSERT INTO Processo_Judicial
VALUES ('847230bd-6629-4699-9616-1a44526615a8', '2019-10-26',
        NULL, false, '34047240966');
INSERT INTO Processo_Judicial
VALUES ('d050e6d0-9871-4efe-8b87-7f76b010fcaf', '2005-6-12',
        NULL, false, '57299066584');
INSERT INTO Processo_Judicial
VALUES ('c3dd52f6-4a5a-469d-86a9-f7e08949dd60', '2014-10-1',
        NULL, true, '51308676458');
INSERT INTO Processo_Judicial
VALUES ('b26254b0-ac56-4c7e-99d4-939058c9912f', '2005-5-19',
        NULL, false, '64375204483');
INSERT INTO Processo_Judicial
VALUES ('24fcdd80-a9a4-4422-acbd-b4bd95deb06a', '2011-1-24',
        '2021-4-1', false, '11848133248');
INSERT INTO Processo_Judicial
VALUES ('6d78eedf-e9b4-4279-88a6-e44e18d97af0', '2015-2-10',
        NULL, true, '89264845682');
INSERT INTO Processo_Judicial
VALUES ('9d6a7712-a26a-4891-b271-dd4934d39a26', '2006-5-19',
        NULL, false, '32508439864');
INSERT INTO Processo_Judicial
VALUES ('96c64609-79df-482a-81ff-51e0ba290d71', '2018-4-7',
        NULL, false, '52019781784');
INSERT INTO Processo_Judicial
VALUES ('5c890e16-0f3f-4c9a-a7e7-bb5d410edc2e', '2015-6-27',
        '2018-3-30', true, '98071054182');
INSERT INTO Processo_Judicial
VALUES ('e54c884f-112c-4195-900f-10443b9115a2', '2017-11-16',
        '2021-10-1', true, '80229327632');
INSERT INTO Processo_Judicial
VALUES ('a2a30269-f4cc-40d1-aeea-fa69a740c480', '2011-4-8',
        NULL, false, '93407944291');
INSERT INTO Processo_Judicial
VALUES ('8ab23ca5-c089-483e-bc73-3530b9a5f739', '2015-5-8',
        NULL, true, '59156701033');
INSERT INTO Processo_Judicial
VALUES ('e2971e63-3766-4a79-a5af-26b5c2760a76', '2011-9-24',
        NULL, true, '18505114549');
INSERT INTO Processo_Judicial
VALUES ('e8e8ca2b-3556-45f8-abf2-c1452d0b7514', '2004-3-28',
        '2017-8-4', true, '17360159694');
INSERT INTO Processo_Judicial
VALUES ('9554877e-d362-4156-96a6-e62b4cfc6771', '2006-1-10',
        NULL, false, '24663187770');
INSERT INTO Processo_Judicial
VALUES ('cc09dbcf-30ed-452d-a9cc-7c9e4790f71a', '2016-10-29',
        '2019-12-13', false, '85319130541');
INSERT INTO Processo_Judicial
VALUES ('45f52102-77ae-4e72-a55f-c178da19d49b', '2015-9-20',
        NULL, true, '67008212334');
INSERT INTO Processo_Judicial
VALUES ('4fd58cec-1f18-40c2-9897-e70c3c29c73f', '2004-3-27',
        '2020-12-29', false, '37581900996');
INSERT INTO Processo_Judicial
VALUES ('fd5069de-a440-4de6-9e19-b131b130e5b6', '2012-1-19',
        '2020-11-11', false, '85319130541');
INSERT INTO Processo_Judicial
VALUES ('3a654a5a-eedc-4328-bd79-9f0519ff622c', '2019-10-12',
        '2017-8-18', false, '99311338330');
INSERT INTO Processo_Judicial
VALUES ('d51c83db-22f5-42c9-bb38-74c55864a398', '2019-6-20',
        '2021-8-6', true, '55037683360');
INSERT INTO Processo_Judicial
VALUES ('ee1d69ee-afec-4dd7-be99-50654f44d46f', '2014-5-23',
        '2020-6-28', false, '64779439785');
INSERT INTO Processo_Judicial
VALUES ('03a9cf7b-2536-4f7b-bc3e-ad813602d965', '2021-7-19',
        NULL, true, '74947254906');
INSERT INTO Processo_Judicial
VALUES ('389885c7-6616-4027-9334-3552b5931205', '2003-9-1',
        NULL, false, '30621758850');
INSERT INTO Processo_Judicial
VALUES ('6b542875-dd0f-46c4-9edc-43155e502c3f', '2018-11-14',
        NULL, false, '86980507716');
INSERT INTO Processo_Judicial
VALUES ('a3e21165-99a7-4ee7-9226-9615d1bfd06f', '2002-10-22',
        '2018-7-18', false, '27397945995');
INSERT INTO Processo_Judicial
VALUES ('b50bf1b8-48b3-4fb6-b08c-d4b6f5df2aa4', '2009-9-17',
        NULL, false, '73469289678');
INSERT INTO Processo_Judicial
VALUES ('797b6ae8-2679-4204-a705-e77b5b570ec4', '2006-7-11',
        NULL, false, '94947150240');
INSERT INTO Processo_Judicial
VALUES ('6384d03d-c4d0-44bc-b3d9-5958c66396db', '2013-9-1',
        NULL, true, '85752784269');
INSERT INTO Processo_Judicial
VALUES ('4707cec9-abf9-44b4-8e67-d66de7bd0f5d', '2005-6-30',
        NULL, true, '64084488817');
INSERT INTO Processo_Judicial
VALUES ('c750f366-63d3-4c7f-96f8-51c4a4597c7f', '2016-6-26',
        '2020-9-10', false, '72668227651');
INSERT INTO Processo_Judicial
VALUES ('e17d9d8e-c255-4ad2-84b3-6729716b4c7d', '2013-10-15',
        NULL, false, '73590556099');
INSERT INTO Processo_Judicial
VALUES ('3d1f0314-1d0e-4d87-8f1e-f673c70403ec', '2009-2-20',
        '2021-2-28', false, '95630513457');
INSERT INTO Processo_Judicial
VALUES ('095c7cf2-404c-4de8-a5ff-557992929e37', '2011-3-7',
        '2018-9-10', true, '31935233147');
INSERT INTO Processo_Judicial
VALUES ('bebbadc3-6030-4a50-8ac5-997a1d7a9803', '2004-3-9',
        NULL, false, '82960038760');
INSERT INTO Processo_Judicial
VALUES ('b41b1d08-9ef0-4fda-b829-88a7dba2b769', '2019-10-8',
        NULL, false, '80214095890');
INSERT INTO Processo_Judicial
VALUES ('538f04c2-f5a4-4709-8b29-dcc79016e865', '2009-10-9',
        '2018-6-23', false, '49697081230');
INSERT INTO Processo_Judicial
VALUES ('2317320c-7737-4de2-adaa-f03bccf69a45', '2010-10-5',
        NULL, false, '88668754065');
INSERT INTO Processo_Judicial
VALUES ('2abeb761-ea8f-4610-93e7-ad2176ec6839', '2020-9-5',
        NULL, true, '56009768713');
INSERT INTO Processo_Judicial
VALUES ('565999b0-3842-463b-aae9-dd2ae896db5a', '2018-8-7',
        NULL, false, '40589486460');
INSERT INTO Processo_Judicial
VALUES ('de63c834-4f73-4a51-bb9f-0363fd3bf3dc', '2014-3-2',
        NULL, true, '94947150240');
INSERT INTO Processo_Judicial
VALUES ('4fb5eb59-057b-4978-8b55-700f3eb50641', '2002-12-7',
        NULL, false, '86282287575');
INSERT INTO Processo_Judicial
VALUES ('11178922-1dfc-42e2-932b-93a92c48e980', '2017-10-15',
        NULL, true, '67123855608');
INSERT INTO Processo_Judicial
VALUES ('6db0f634-44e3-46fc-9871-e943c49dc039', '2007-1-30',
        '2018-2-17', false, '48840457284');
INSERT INTO Processo_Judicial
VALUES ('7d62372e-904c-4763-830b-2b159ccf0a7e', '2011-1-27',
        '2021-2-6', true, '37581900996');
INSERT INTO Processo_Judicial
VALUES ('78d22ba7-fee7-4db7-b75c-013fe07d4d16', '2018-1-1',
        NULL, false, '40589486460');
INSERT INTO Processo_Judicial
VALUES ('d7984ed6-5ee4-40b7-894c-33e12446ec8f', '2019-5-23',
        '2018-10-28', true, '79646575415');
INSERT INTO Processo_Judicial
VALUES ('93c58d1b-b2b7-4801-9be9-9121720173d9', '2019-7-23',
        '2018-11-20', false, '62031259345');
INSERT INTO Processo_Judicial
VALUES ('85355ae1-93b0-4bee-a70c-f7d7e9501d65', '2004-1-6',
        '2020-3-31', true, '63795995046');
INSERT INTO Processo_Judicial
VALUES ('95e8a10b-beae-43ac-928a-3e686ab4b14f', '2008-9-29',
        NULL, false, '75318471796');
INSERT INTO Processo_Judicial
VALUES ('905c1cbd-7be7-4295-92d6-b02487251a01', '2003-4-25',
        NULL, false, '85730072224');
INSERT INTO Processo_Judicial
VALUES ('88639c1c-c7ea-4343-b006-62a508f433c4', '2002-1-17',
        '2016-12-3', false, '46922632912');
INSERT INTO Processo_Judicial
VALUES ('556b7486-65c0-437f-a965-c42511bffcf3', '2017-5-13',
        '2018-5-22', true, '83156164272');
INSERT INTO Processo_Judicial
VALUES ('7b98f20c-8886-40c7-b1f7-41eee0fa2722', '2021-5-2',
        '2019-12-17', true, '23072280755');
INSERT INTO Processo_Judicial
VALUES ('fe752d49-1894-48db-be04-aea46f8a1f3e', '2005-7-18',
        '2018-5-12', false, '74808992438');
INSERT INTO Processo_Judicial
VALUES ('3a9310c5-fd59-47a6-bc7d-2ca87a44915d', '2009-2-14',
        NULL, true, '66703392334');
INSERT INTO Processo_Judicial
VALUES ('ba4a99e9-b7a7-425e-9f7f-da6fa0176f43', '2006-4-24',
        '2017-1-31', false, '10209552922');
INSERT INTO Processo_Judicial
VALUES ('11d0477e-585e-482f-bcba-17d2423f7280', '2002-5-27',
        NULL, true, '58980360710');
INSERT INTO Processo_Judicial
VALUES ('e24b7f21-6091-4122-961a-889e93e70bc1', '2008-2-1',
        NULL, true, '40851067951');
INSERT INTO Processo_Judicial
VALUES ('15148478-df1c-42b4-8d86-d6ff86b8d8c7', '2007-2-28',
        '2019-4-2', false, '25862227568');
INSERT INTO Processo_Judicial
VALUES ('6d50f465-a72f-4955-9da3-46ea66fa1ef3', '2007-5-25',
        NULL, false, '79293712463');
INSERT INTO Processo_Judicial
VALUES ('d0342bde-8376-4e28-bc67-cf998d3f4073', '2018-5-6',
        NULL, false, '61669403030');
INSERT INTO Processo_Judicial
VALUES ('cf0010bf-76be-4260-961a-b5a6e8999af3', '2005-11-4',
        '2021-2-14', false, '87764965905');
INSERT INTO Processo_Judicial
VALUES ('80b4a330-7231-4bc6-83de-830b2acf0841', '2010-1-7',
        NULL, false, '76646342640');
INSERT INTO Processo_Judicial
VALUES ('74e87bc9-9abe-4c12-b36e-7d4b6afdf8c3', '2004-10-18',
        NULL, true, '38185161759');
INSERT INTO Processo_Judicial
VALUES ('73853be5-07bb-4170-b4dd-e6054b236ef7', '2006-6-25',
        NULL, true, '36136912815');
INSERT INTO Processo_Judicial
VALUES ('975ba258-74dc-477c-b04c-df896a50e485', '2008-10-11',
        NULL, true, '17419773926');
INSERT INTO Processo_Judicial
VALUES ('344fdc03-ecff-49dd-8537-c3f7865c9d9c', '2011-11-25',
        NULL, false, '29969115727');
INSERT INTO Processo_Judicial
VALUES ('306f8b9e-311c-4320-b274-65283ee813f6', '2021-9-4',
        NULL, true, '51977524964');
INSERT INTO Processo_Judicial
VALUES ('49abef20-4b7f-461f-ac63-02aee635257f', '2013-5-10',
        '2021-4-10', false, '10065442044');
INSERT INTO Processo_Judicial
VALUES ('dbbfd319-e466-4a7a-b109-7f192c3cd3a1', '2018-9-25',
        '2020-11-30', false, '11848133248');
INSERT INTO Processo_Judicial
VALUES ('cf414199-71a7-4359-a550-e9727f3fdd2d', '2007-7-8',
        NULL, true, '14908413034');
INSERT INTO Processo_Judicial
VALUES ('f6f952f1-dd2f-4b71-8003-15f2f92b3af2', '2009-1-19',
        NULL, true, '45065363431');
INSERT INTO Processo_Judicial
VALUES ('2ae902ab-af20-4ce5-bb8d-0a24a666bb90', '2020-1-18',
        '2017-6-8', false, '10204609066');
INSERT INTO Processo_Judicial
VALUES ('a58193bf-52b5-4fe1-b9e2-afa9d2a0e1ae', '2021-4-3',
        '2018-12-4', true, '50650208310');
INSERT INTO Processo_Judicial
VALUES ('54a4a37f-a0f9-4b13-8422-7ceb86914240', '2019-2-3',
        NULL, true, '37415883594');
INSERT INTO Processo_Judicial
VALUES ('5f3539bf-9299-4863-87c7-b3d03077456b', '2008-5-8',
        '2019-3-27', true, '55317056111');
INSERT INTO Processo_Judicial
VALUES ('5af3e9ee-c43c-4dd1-8700-688e1b0900ea', '2006-5-15',
        '2019-5-17', false, '45065363431');
INSERT INTO Processo_Judicial
VALUES ('33e3d0ab-b95c-46c9-9da0-e76e0d0d05e2', '2016-9-6',
        '2019-1-30', true, '57793636212');
INSERT INTO Processo_Judicial
VALUES ('ba3c529d-f47a-4eef-a583-d42c2e378768', '2007-7-19',
        '2019-10-27', true, '35275697032');
INSERT INTO Processo_Judicial
VALUES ('5e028265-f30e-4b7f-ad4b-f7895c72c206', '2006-4-13',
        NULL, false, '32995448785');
INSERT INTO Processo_Judicial
VALUES ('98c07013-187c-4b29-900b-1ea3ffb07995', '2005-12-4',
        '2017-7-14', true, '33032022989');
INSERT INTO Processo_Judicial
VALUES ('a015a1f9-7c90-43e2-b8d8-cb14ac76eba3', '2011-8-26',
        NULL, true, '76377020021');
INSERT INTO Processo_Judicial
VALUES ('73f978e3-ca4b-486f-a615-9a1ad2a5452d', '2013-5-13',
        NULL, false, '66040890542');
INSERT INTO Processo_Judicial
VALUES ('be0544ad-7e4b-4e11-a4af-05f4e3b8c774', '2014-3-11',
        '2017-9-2', true, '87642632594');
INSERT INTO Processo_Judicial
VALUES ('ddfaa574-0c2e-4eea-8f4b-5a12ea6ea080', '2004-11-2',
        NULL, false, '22161167713');
INSERT INTO Processo_Judicial
VALUES ('78703977-bb93-46c8-a4d9-aa94b582f8cd', '2014-3-5',
        '2018-10-30', true, '86768067248');
INSERT INTO Processo_Judicial
VALUES ('48025cd8-d0e4-424c-aba8-a949707d28ed', '2010-11-8',
        '2021-2-19', true, '55317056111');
INSERT INTO Processo_Judicial
VALUES ('ef6886b1-9def-4e91-9ee2-382d7de39611', '2013-12-19',
        '2021-8-23', true, '50331124449');
INSERT INTO Processo_Judicial
VALUES ('c2e575c1-55a5-4e3d-bbe0-20159600fa75', '2012-2-3',
        NULL, true, '62156000735');
INSERT INTO Processo_Judicial
VALUES ('449a5a23-3636-49aa-9894-0e0272da8e7a', '2004-1-19',
        '2019-4-6', false, '53108889381');
INSERT INTO Processo_Judicial
VALUES ('6c99920c-8396-41ae-9747-3f3ece0d1c5b', '2007-2-25',
        NULL, false, '65929289441');
INSERT INTO Processo_Judicial
VALUES ('d3790961-1881-43a4-bdc4-6e1f479218cd', '2006-11-29',
        '2018-5-10', true, '48840457284');
INSERT INTO Processo_Judicial
VALUES ('26b03b10-90ae-417c-8379-5c94411ac549', '2016-7-2',
        '2017-2-17', true, '93402923154');
INSERT INTO Processo_Judicial
VALUES ('d5ad15f2-bdd9-4e55-9d76-aae466a68abd', '2008-12-31',
        NULL, false, '43863967857');
INSERT INTO Processo_Judicial
VALUES ('b78df500-8c9e-4585-b94a-feb6c024fd69', '2016-4-3',
        '2020-11-9', false, '85119483100');
INSERT INTO Processo_Judicial
VALUES ('31ae09d0-f947-4341-9bfd-a41783221f8e', '2010-9-15',
        NULL, true, '44718786508');
INSERT INTO Processo_Judicial
VALUES ('1b4a042c-a0ad-4b2f-9c4e-5d1a778d5e6b', '2014-5-27',
        '2021-9-21', true, '45083095934');
INSERT INTO Processo_Judicial
VALUES ('603bfc5e-68a1-4b6f-a2bf-cc0ce016551b', '2005-4-15',
        NULL, true, '66493321389');
INSERT INTO Processo_Judicial
VALUES ('27c0008e-992a-41f2-973f-3da4eb6fba28', '2004-6-26',
        NULL, true, '37841710573');
INSERT INTO Processo_Judicial
VALUES ('678a7c5b-e1e1-4346-bf77-2cc856b40ee8', '2009-6-29',
        '2018-3-21', false, '55515005839');
INSERT INTO Processo_Judicial
VALUES ('72f0cdc7-8828-47fc-8830-db2405e113ae', '2014-1-2',
        NULL, true, '95344005359');
INSERT INTO Processo_Judicial
VALUES ('a8ede8b4-a71e-49aa-a1db-b92b5c199081', '2019-8-4',
        NULL, true, '44718153213');
INSERT INTO Processo_Judicial
VALUES ('3b9b3c17-1f84-4131-a452-65df9e060ba0', '2012-6-28',
        NULL, true, '49292941880');
INSERT INTO Processo_Judicial
VALUES ('98cb1443-d509-4df1-aa11-53cf4d2c6f45', '2009-2-4',
        '2017-9-20', true, '72516597094');
INSERT INTO Processo_Judicial
VALUES ('b51dfbe3-a030-4a30-a747-84795439f038', '2014-12-8',
        '2020-12-11', false, '33644861271');
INSERT INTO Processo_Judicial
VALUES ('3bdedee7-4876-4e96-b68a-480c049b43ce', '2008-4-13',
        '2018-8-18', true, '84785704296');
INSERT INTO Processo_Judicial
VALUES ('3dab75ab-f968-4e52-ba2e-92367da7ebe9', '2002-9-29',
        '2020-1-2', false, '69930587140');
INSERT INTO Processo_Judicial
VALUES ('4201cfd7-a65a-4219-8edb-f3a76d91167c', '2003-4-13',
        NULL, false, '95593594631');
INSERT INTO Processo_Judicial
VALUES ('76280bcd-42c0-40f7-9cec-919b18cddb1d', '2003-6-30',
        '2019-4-28', true, '45065363431');
INSERT INTO Processo_Judicial
VALUES ('56a290b8-42fb-4434-916a-970e959a06be', '2018-9-19',
        '2019-4-23', true, '47849461960');
INSERT INTO Processo_Judicial
VALUES ('bf19e819-2b91-4e95-860f-6a43db709001', '2012-3-24',
        NULL, true, '25392862658');
INSERT INTO Processo_Judicial
VALUES ('4d0b030e-5729-4d17-892d-7f6f0c9605ec', '2004-10-28',
        NULL, false, '26038876282');
INSERT INTO Processo_Judicial
VALUES ('e1f07e3b-68a1-4fcb-a37d-325af9927e6a', '2006-12-10',
        NULL, false, '33042951838');
INSERT INTO Processo_Judicial
VALUES ('4ec5a984-1510-4106-9322-3166678bfe67', '2009-8-23',
        NULL, false, '26260169129');
INSERT INTO Processo_Judicial
VALUES ('15544816-7423-4b9c-8b9c-274df3b56f23', '2010-5-23',
        NULL, true, '22103242517');
INSERT INTO Processo_Judicial
VALUES ('09e49865-bafa-42a7-bfc8-f087ff36acf4', '2009-7-22',
        NULL, false, '43344490984');
INSERT INTO Processo_Judicial
VALUES ('8ec15a37-fcde-47ff-b315-04b3dfbc3ed9', '2008-1-25',
        NULL, false, '16524949248');
INSERT INTO Processo_Judicial
VALUES ('d9801023-e36b-4c04-867b-a7fb398093ae', '2012-11-25',
        NULL, false, '12673338970');
INSERT INTO Processo_Judicial
VALUES ('f194750e-b08a-45c8-9b7f-84aef4594e68', '2009-11-30',
        NULL, true, '90560006066');
INSERT INTO Processo_Judicial
VALUES ('a874ec1d-4161-40b1-9a34-f4a87c5c1afc', '2020-9-16',
        '2021-8-6', true, '88463596005');
INSERT INTO Processo_Judicial
VALUES ('63c4168c-98f6-4ce2-a9cd-7bb0ed7859d3', '2020-9-29',
        '2019-1-6', true, '16470102223');
INSERT INTO Processo_Judicial
VALUES ('7c7220c7-b944-4e97-ba71-22cc0082ef4d', '2014-5-13',
        '2018-10-30', false, '12911266039');
INSERT INTO Processo_Judicial
VALUES ('314f8993-15cd-4049-9513-fc56658ee7ef', '2004-10-28',
        '2021-3-20', false, '55340310402');
INSERT INTO Processo_Judicial
VALUES ('9ef96449-8683-4040-a60d-a76a161f0e18', '2009-7-1',
        '2021-10-5', false, '65620046039');
INSERT INTO Processo_Judicial
VALUES ('368d7557-4506-4d16-b497-813afe166797', '2020-2-22',
        '2017-1-22', false, '46841982156');
INSERT INTO Processo_Judicial
VALUES ('bab5cbf0-fb15-440b-bfa3-2ea3b242d4ce', '2016-12-11',
        NULL, false, '27661639580');
INSERT INTO Processo_Judicial
VALUES ('209d2175-92cc-4ab5-bd0e-b92a15b949e4', '2007-12-18',
        '2020-9-28', false, '65012076930');
INSERT INTO Processo_Judicial
VALUES ('3026d563-4924-47be-a4cc-032c606ebf49', '2005-11-20',
        NULL, true, '61290123986');
INSERT INTO Processo_Judicial
VALUES ('b236a9e5-96b0-4b6c-bb4a-258833e6fd05', '2015-12-22',
        NULL, true, '86282287575');
INSERT INTO Processo_Judicial
VALUES ('9947abdb-dc9a-457b-bfd5-1438b4e4e0d6', '2010-9-16',
        '2018-6-6', true, '54783345928');
INSERT INTO Processo_Judicial
VALUES ('f7cc4c85-5f10-4b88-baf2-a0beaa2ca728', '2011-10-28',
        '2018-5-2', false, '58487967234');
INSERT INTO Processo_Judicial
VALUES ('72af91ff-8f91-4a4e-85a1-c4ce80a11b74', '2009-1-15',
        '2019-11-13', true, '96782912428');
INSERT INTO Processo_Judicial
VALUES ('4d71d9df-65c5-4283-b5ec-b28a676a9c9a', '2019-5-14',
        NULL, false, '82459476657');
INSERT INTO Processo_Judicial
VALUES ('51571a4e-f1cd-45a7-aca2-7392b7109d17', '2014-5-16',
        '2021-2-15', true, '51165132678');
INSERT INTO Processo_Judicial
VALUES ('24d13d08-c1ec-425a-a99a-1124997b619e', '2007-1-27',
        NULL, false, '47442891250');
INSERT INTO Processo_Judicial
VALUES ('e9c8663c-97de-47ae-b150-52163f05c3d9', '2007-10-27',
        NULL, true, '93231366153');
INSERT INTO Processo_Judicial
VALUES ('c57da0ca-e0f5-4664-ba87-d678052f903d', '2020-10-17',
        NULL, true, '87642632594');
INSERT INTO Processo_Judicial
VALUES ('8b47a22d-26bb-4a9d-9c64-b2f58a8f526a', '2016-11-25',
        '2017-12-4', false, '99709735615');
INSERT INTO Processo_Judicial
VALUES ('00b7038f-99e9-4843-8be8-34acf164d5df', '2018-3-11',
        '2017-9-19', false, '34139046359');
INSERT INTO Processo_Judicial
VALUES ('766572c2-61c9-4698-9285-185b4f7931b3', '2011-10-25',
        '2020-1-18', false, '96993440124');
INSERT INTO Processo_Judicial
VALUES ('5006b2bb-fd74-4221-86c6-b77077b19394', '2003-11-1',
        NULL, true, '22237183297');
INSERT INTO Processo_Judicial
VALUES ('31f7798e-cfeb-489e-82c2-027f1893dc6e', '2009-3-12',
        NULL, true, '34528599961');
INSERT INTO Processo_Judicial
VALUES ('00259040-6295-46d3-a86b-c1fd57bab4de', '2016-10-19',
        '2019-7-12', true, '54206616906');
INSERT INTO Processo_Judicial
VALUES ('94897c1b-281a-4fb3-b5a6-f86ecbcc2f68', '2009-5-14',
        '2018-9-16', true, '77704517054');
INSERT INTO Processo_Judicial
VALUES ('ec9c644b-837b-44dd-a21f-4e42e197e41d', '2002-8-14',
        NULL, false, '49412925681');
INSERT INTO Processo_Judicial
VALUES ('0fafb52b-3ab7-4194-b8a0-2cada01576ba', '2018-8-8',
        '2020-4-1', true, '96993440124');
INSERT INTO Processo_Judicial
VALUES ('822d6917-b021-443e-b164-328e29eeffe1', '2012-10-26',
        NULL, false, '21125739731');
INSERT INTO Processo_Judicial
VALUES ('3e2e9388-d63d-4a8d-b6cb-cc65cc2e1695', '2020-10-26',
        NULL, true, '48873054108');
INSERT INTO Processo_Judicial
VALUES ('eab20cbb-ac11-4f00-929b-a2433f95c409', '2018-11-8',
        NULL, false, '61883076978');
INSERT INTO Processo_Judicial
VALUES ('ada98b1f-21c6-4685-9c68-c95aaf7ec7f0', '2002-4-25',
        '2018-4-15', false, '98803486214');
INSERT INTO Processo_Judicial
VALUES ('d9fec964-d0d2-4320-9603-6bc3fba10c14', '2020-2-10',
        NULL, false, '60686908485');
INSERT INTO Processo_Judicial
VALUES ('59088e21-2b0f-485b-b54d-9e4cc7bbd524', '2002-11-26',
        '2018-3-12', false, '62509119817');
INSERT INTO Processo_Judicial
VALUES ('dd4feeeb-6386-4c23-af69-c07b5f0a39db', '2015-3-14',
        '2018-8-3', true, '66894887096');
INSERT INTO Processo_Judicial
VALUES ('c57e33be-e0c5-461c-af97-18bc986c02ac', '2018-8-10',
        NULL, true, '27573815234');
INSERT INTO Processo_Judicial
VALUES ('463c7374-68e5-4e2f-88fb-c244b0c4d9e1', '2003-9-22',
        NULL, false, '13129826323');
INSERT INTO Processo_Judicial
VALUES ('ad58bfa2-9bee-4714-a62b-f2502e6a153e', '2009-4-12',
        NULL, true, '42713638902');
INSERT INTO Processo_Judicial
VALUES ('1b56338c-b993-4927-80ce-5313c6aa0a48', '2019-1-4',
        '2021-3-18', false, '16891570298');
INSERT INTO Processo_Judicial
VALUES ('c8391989-7cea-4850-b54f-a64c5454fbd7', '2011-5-10',
        '2021-9-8', false, '32508439864');
INSERT INTO Processo_Judicial
VALUES ('d3a43cb1-4866-4f40-8478-650ad1b4eab3', '2005-5-22',
        '2017-10-17', false, '75659786309');
INSERT INTO Processo_Judicial
VALUES ('2d0a6ebe-ed41-4ee8-9fe8-374b2e745e16', '2008-3-2',
        '2019-12-23', true, '49351430758');
INSERT INTO Processo_Judicial
VALUES ('e2e2845b-0cec-4316-8b77-eade34989ad6', '2011-7-28',
        '2018-9-4', true, '87588114035');
INSERT INTO Processo_Judicial
VALUES ('660e51ae-09d7-4167-80f2-fa39bcb4b831', '2015-5-22',
        '2017-10-29', true, '18379429504');
INSERT INTO Processo_Judicial
VALUES ('b4c31037-0683-4c7b-b93d-2a41cd00d505', '2019-6-21',
        '2017-10-5', true, '67661317153');
INSERT INTO Processo_Judicial
VALUES ('099cbe15-8966-42de-844d-ea212488e865', '2013-6-12',
        NULL, false, '57299066584');
INSERT INTO Processo_Judicial
VALUES ('83707cf2-aed9-4161-beb0-0d10191b902f', '2007-10-31',
        '2020-5-15', false, '15123706744');
INSERT INTO Processo_Judicial
VALUES ('aa01b1e6-5557-48a3-9ca3-b3c8d97e44b1', '2013-12-21',
        '2020-5-5', true, '36079567898');
INSERT INTO Processo_Judicial
VALUES ('77761f22-d383-4f48-ab51-58c8e43dbccb', '2020-10-4',
        '2019-10-2', false, '38918265034');
INSERT INTO Processo_Judicial
VALUES ('e8989272-3769-4e3a-894d-8da4c116ffc0', '2011-7-17',
        '2017-2-3', true, '91382141099');
INSERT INTO Processo_Judicial
VALUES ('fef47e7f-c03f-4a71-8933-e8f89ec75eed', '2008-9-2',
        '2017-3-21', true, '37581900996');
INSERT INTO Processo_Judicial
VALUES ('d08f2bd9-01e1-4910-8ede-e2933b6034a3', '2003-10-22',
        NULL, false, '83156164272');
INSERT INTO Processo_Judicial
VALUES ('11774814-97da-4ae7-8972-53d646c6258a', '2012-7-17',
        '2021-8-21', false, '54967094177');
INSERT INTO Processo_Judicial
VALUES ('f5d6d568-91c3-46a7-b105-32fd5de9fae2', '2010-5-9',
        NULL, true, '49220664729');
INSERT INTO Processo_Judicial
VALUES ('9e9acc1b-c05c-4b71-aec8-9451732881dc', '2013-3-3',
        '2017-6-13', true, '82486186116');
INSERT INTO Processo_Judicial
VALUES ('471242e9-a6a2-48c3-929f-58dca4d1260f', '2020-12-23',
        '2019-3-11', true, '37706179977');
INSERT INTO Processo_Judicial
VALUES ('07303f5a-d954-462a-9387-e4641d7b0fbf', '2002-12-22',
        NULL, true, '47132167625');
INSERT INTO Processo_Judicial
VALUES ('efb08f9f-5500-4eb1-ae72-ebb30786da74', '2011-2-4',
        '2019-6-6', false, '79606743648');
INSERT INTO Processo_Judicial
VALUES ('534de771-ec17-4bd0-a200-3218a5844374', '2009-3-15',
        '2019-6-25', false, '31590171044');
INSERT INTO Processo_Judicial
VALUES ('e109c6c9-386f-4e21-bd7d-3df7e6c2adc8', '2018-11-21',
        NULL, true, '41297736910');
INSERT INTO Processo_Judicial
VALUES ('daf5dcf5-fb1d-4818-8dcc-12bcc05c4955', '2012-3-16',
        NULL, false, '94102552335');
INSERT INTO Processo_Judicial
VALUES ('5db41543-5f83-45e3-83ae-89d88f600f95', '2013-2-24',
        '2020-3-16', false, '73907273937');
INSERT INTO Processo_Judicial
VALUES ('37cd74bb-f403-400c-8362-93df7c126b52', '2013-1-10',
        NULL, true, '72560434259');
INSERT INTO Processo_Judicial
VALUES ('34c75937-f065-40e3-84e6-e8b4a5ee230a', '2019-9-25',
        '2019-10-28', true, '55752608675');
INSERT INTO Processo_Judicial
VALUES ('6884f4dc-25a6-47df-b72c-1820657fb999', '2008-8-18',
        NULL, true, '50602269105');
INSERT INTO Processo_Judicial
VALUES ('685a013f-6ea4-482c-af8c-24c9cf48e2ae', '2010-8-29',
        NULL, true, '58437837020');
INSERT INTO Processo_Judicial
VALUES ('8f221023-aa10-4d90-bbb6-636e722f1d1a', '2004-10-26',
        '2021-8-2', true, '60686908485');
INSERT INTO Processo_Judicial
VALUES ('03c612e7-150d-44a1-a694-13bdcc1a0b40', '2009-1-27',
        '2019-11-25', false, '47333944300');
INSERT INTO Processo_Judicial
VALUES ('be530f28-dcf6-46ba-a3f9-9288545d1799', '2011-11-23',
        '2019-10-13', false, '52510659939');
INSERT INTO Processo_Judicial
VALUES ('c43cbe8d-1ed1-4477-bdf4-ac695fcf6909', '2012-8-16',
        NULL, false, '98543534772');
INSERT INTO Processo_Judicial
VALUES ('f42f4f77-2375-45cd-a26d-44ec626f4289', '2016-6-23',
        NULL, false, '65963803855');
INSERT INTO Processo_Judicial
VALUES ('e8739b61-860a-4dfd-9710-304e30b1b431', '2010-12-27',
        NULL, true, '39709400143');
INSERT INTO Processo_Judicial
VALUES ('208d0b9e-a217-4bb6-889f-fa4484e4b747', '2015-4-21',
        NULL, true, '64293432543');
INSERT INTO Processo_Judicial
VALUES ('53b125ee-9158-4fc4-9a63-902a19af9b2b', '2009-8-25',
        '2021-4-2', true, '10204609066');
INSERT INTO Processo_Judicial
VALUES ('11e11125-148a-40b8-8051-47a94055521c', '2016-11-23',
        NULL, true, '50921300621');
INSERT INTO Processo_Judicial
VALUES ('c5260031-496b-41f4-8a83-a35deb6921c8', '2011-11-17',
        NULL, false, '68540927693');
INSERT INTO Processo_Judicial
VALUES ('ef42088c-7d5b-47a7-90c0-0b75faff2b5f', '2006-1-29',
        '2018-11-29', false, '92201869981');
INSERT INTO Processo_Judicial
VALUES ('70df2004-dbbf-469a-9a40-8ad08ceadd48', '2010-7-23',
        NULL, true, '26038876282');
INSERT INTO Processo_Judicial
VALUES ('1882ebce-750e-470c-98d3-c0b368314473', '2018-7-14',
        NULL, true, '54358800731');
INSERT INTO Processo_Judicial
VALUES ('60c48277-2fdd-4034-9589-53fd38832136', '2006-7-2',
        NULL, false, '42516188630');
INSERT INTO Processo_Judicial
VALUES ('0fedbbb3-f9f2-438e-806c-8290c240a0aa', '2015-11-21',
        NULL, false, '52176460425');
INSERT INTO Processo_Judicial
VALUES ('f86eb7cd-3858-44d0-9fb3-9084fe61fd9b', '2002-4-1',
        '2019-12-21', true, '34625774528');
INSERT INTO Processo_Judicial
VALUES ('4bfd3d37-6887-4123-a55f-9552f5f3eca9', '2007-7-21',
        '2020-4-19', true, '84774450208');
INSERT INTO Processo_Judicial
VALUES ('5c967097-b6b9-4bac-a692-17910124c982', '2021-10-13',
        NULL, true, '31800616828');
INSERT INTO Processo_Judicial
VALUES ('c54ba3e5-75bb-47a3-99d9-ee2ecdc8fb0b', '2010-11-26',
        '2021-8-18', true, '74122189518');
INSERT INTO Processo_Judicial
VALUES ('ed27799a-17ad-4a10-b1ae-418d9e08c9cc', '2012-9-6',
        '2020-3-12', false, '29078152088');
INSERT INTO Processo_Judicial
VALUES ('b2a9e51b-b35b-4f97-97e1-bd9205bcf75c', '2004-12-9',
        '2018-3-3', true, '55804576182');
INSERT INTO Processo_Judicial
VALUES ('c7578312-8dcd-4e32-914c-e79307cbee44', '2013-12-16',
        '2021-8-29', false, '88037559373');
INSERT INTO Processo_Judicial
VALUES ('dcd9b440-22f5-4c6c-be20-a30cabce5bf3', '2013-9-13',
        NULL, false, '48873054108');
INSERT INTO Processo_Judicial
VALUES ('f40e35ee-a39b-49c2-b4f0-addfc1aa20d8', '2013-2-24',
        '2018-7-31', true, '40069712323');
INSERT INTO Processo_Judicial
VALUES ('e85dffc2-7bae-4692-add6-275e0e55f080', '2004-2-20',
        '2017-11-2', true, '68652663973');
INSERT INTO Processo_Judicial
VALUES ('1c58d5cf-8f99-4bdd-94e2-d59d7656af55', '2012-5-14',
        NULL, false, '94048417352');
INSERT INTO Processo_Judicial
VALUES ('0eeeb8f0-1f7c-40ff-865e-46773ac0b925', '2008-3-10',
        '2017-8-22', true, '28760097629');
INSERT INTO Processo_Judicial
VALUES ('f97da1b4-5f6a-4c96-9ae7-dd24eebbc8c8', '2020-10-29',
        NULL, true, '64084488817');
INSERT INTO Processo_Judicial
VALUES ('33395d1a-1d86-4c02-b1d4-2abe5ec0f45e', '2014-5-24',
        NULL, true, '45475941675');
INSERT INTO Processo_Judicial
VALUES ('6164a8d1-c0d7-4c8d-8744-65b2cade85e3', '2005-6-8',
        '2019-3-22', false, '11120354053');
INSERT INTO Processo_Judicial
VALUES ('81e4f586-3119-478d-ae1f-46d9b8bbfe50', '2002-7-24',
        '2017-6-21', true, '87764965905');
INSERT INTO Processo_Judicial
VALUES ('46089489-ce6b-4aff-90b3-25d2d21eff15', '2019-4-12',
        NULL, false, '34218765089');
INSERT INTO Processo_Judicial
VALUES ('d258ca03-bd14-45bb-9af0-3faa1ff4b668', '2009-11-23',
        NULL, false, '55340310402');
INSERT INTO Processo_Judicial
VALUES ('b90faa0d-51f2-401f-a5aa-dec4241349b6', '2019-5-30',
        NULL, false, '21879325024');
INSERT INTO Processo_Judicial
VALUES ('f35709ce-2d21-445d-a137-522c754de6e0', '2009-3-15',
        NULL, false, '98907837094');
INSERT INTO Processo_Judicial
VALUES ('83647f5b-4f28-4ea6-98bb-2690393228f0', '2016-12-12',
        '2017-1-10', false, '65379982653');
INSERT INTO Processo_Judicial
VALUES ('9e48e66a-2828-4312-b12d-0155c79b08ea', '2011-4-20',
        NULL, true, '77363675071');
INSERT INTO Processo_Judicial
VALUES ('8e15fd86-44fa-40d6-bb41-4db72f135f95', '2014-3-19',
        '2018-6-15', false, '10204609066');
INSERT INTO Processo_Judicial
VALUES ('f471f7ba-5492-49bd-a88c-1dec4412b74f', '2015-10-17',
        '2020-4-17', true, '60686908485');
INSERT INTO Processo_Judicial
VALUES ('eed70772-a9dd-4b41-bdac-f084f90f9d97', '2009-9-29',
        NULL, false, '32128272987');
INSERT INTO Processo_Judicial
VALUES ('833257a8-dfaf-4617-aae8-51939709cd73', '2005-9-29',
        '2020-1-21', false, '17419773926');
INSERT INTO Processo_Judicial
VALUES ('19153432-23a3-4fd6-83e4-e082d8b25b32', '2017-12-21',
        NULL, true, '45746368169');
INSERT INTO Processo_Judicial
VALUES ('cc33550d-8530-4b93-9921-293b31658f80', '2013-9-14',
        NULL, false, '83759686551');
INSERT INTO Processo_Judicial
VALUES ('263f921e-762c-4753-a6b1-ef0d21f4f71c', '2007-10-26',
        NULL, false, '29613642755');
INSERT INTO Processo_Judicial
VALUES ('7da29da1-1365-45f7-aa83-aaf451310011', '2011-11-2',
        '2017-12-8', false, '23647714878');
INSERT INTO Processo_Judicial
VALUES ('9ec2e130-269f-4045-8a3c-25e9e462d080', '2002-6-30',
        NULL, true, '32995448785');
INSERT INTO Processo_Judicial
VALUES ('d7570a59-873c-4406-b9cd-a4f3694a1783', '2011-6-5',
        NULL, true, '52176460425');
INSERT INTO Processo_Judicial
VALUES ('d765847d-df67-40d8-94cd-878356ca569e', '2014-11-26',
        '2021-6-12', false, '70189726690');
INSERT INTO Processo_Judicial
VALUES ('72087bdd-f50b-4f6d-a38d-7e91b21bbcbb', '2010-1-4',
        '2021-4-26', true, '37581900996');
INSERT INTO Processo_Judicial
VALUES ('52d94f1a-c2d6-486d-840f-398c4b8fee36', '2015-4-23',
        NULL, true, '91857076140');
INSERT INTO Processo_Judicial
VALUES ('4943074c-7b71-4c7c-b672-62f1592f2544', '2021-2-10',
        NULL, false, '61522070106');
INSERT INTO Processo_Judicial
VALUES ('586a5115-9715-45b1-998f-ec6994320aae', '2016-4-12',
        NULL, false, '22103242517');
INSERT INTO Processo_Judicial
VALUES ('8a37276a-95b5-4e58-8ff6-9a17ff0f7c1f', '2004-1-4',
        '2021-2-15', true, '96358525417');
INSERT INTO Processo_Judicial
VALUES ('fde6f2f2-0e98-4ba1-a450-23dd3b60d5f2', '2014-12-30',
        NULL, true, '65546228860');
INSERT INTO Processo_Judicial
VALUES ('e907ccee-f28a-4d93-b41d-bb0496231793', '2005-10-30',
        NULL, true, '79293712463');
INSERT INTO Processo_Judicial
VALUES ('b3c3857d-e775-4dca-a5c5-95c7f2267420', '2007-5-28',
        '2020-1-21', true, '84460796038');
INSERT INTO Processo_Judicial
VALUES ('d289db72-41e5-46e0-9c70-4ee73c07f4c7', '2014-5-29',
        '2019-5-7', false, '86836338876');
INSERT INTO Processo_Judicial
VALUES ('63c66e3e-95ea-4d5f-9123-594ec963dbab', '2002-8-3',
        '2021-5-23', false, '54014710634');
INSERT INTO Processo_Judicial
VALUES ('1a61ed5e-bb16-4c5c-9246-232aee2b21ae', '2020-1-14',
        '2016-11-23', false, '35165164980');
INSERT INTO Processo_Judicial
VALUES ('dc1f8c18-b107-4022-81e4-83794e3029a9', '2013-6-16',
        '2020-2-22', true, '41320017329');
INSERT INTO Processo_Judicial
VALUES ('b0b772b4-b3fb-44b5-a530-3a5404dd4474', '2006-3-31',
        NULL, true, '95593594631');
INSERT INTO Processo_Judicial
VALUES ('15bbd52c-f31b-4781-836e-45f8698e790c', '2010-9-14',
        NULL, true, '48246632281');
INSERT INTO Processo_Judicial
VALUES ('375a45d6-b07e-42c6-8cd2-ff8901fe53c7', '2006-7-2',
        '2021-3-22', true, '45288225223');
INSERT INTO Processo_Judicial
VALUES ('2a554d1d-7d94-4696-8d63-13592031972b', '2004-12-19',
        '2018-5-15', false, '28168813411');
INSERT INTO Processo_Judicial
VALUES ('13630a27-eb1f-405c-93c5-7eee986631ee', '2016-12-30',
        NULL, false, '29455049331');
INSERT INTO Processo_Judicial
VALUES ('d8c8d093-c0aa-4637-ae7f-0a7f969a2408', '2020-4-30',
        NULL, true, '21211647114');
INSERT INTO Processo_Judicial
VALUES ('1d5e3015-9030-44eb-b2be-4e74d634b7b9', '2012-5-23',
        '2017-4-26', false, '11846629010');
INSERT INTO Processo_Judicial
VALUES ('562e5271-b9cd-4d5a-8125-e39574686988', '2011-6-27',
        '2021-3-30', true, '71656160976');
INSERT INTO Processo_Judicial
VALUES ('79c64c44-686f-428e-b9a0-a5907b9c5f27', '2020-11-5',
        '2019-2-23', false, '61657774816');
INSERT INTO Processo_Judicial
VALUES ('c1add444-2fbe-49a0-ac9b-44e3ff67e71a', '2011-7-13',
        '2018-12-17', false, '42516188630');
INSERT INTO Processo_Judicial
VALUES ('b4842d05-602a-46c3-8cf8-bd0a58354be8', '2019-8-4',
        NULL, true, '61699634627');
INSERT INTO Processo_Judicial
VALUES ('2f786ea3-838d-4938-b349-84537724b648', '2010-3-12',
        NULL, false, '56279783362');
INSERT INTO Processo_Judicial
VALUES ('0b40f20d-0b74-4813-87b4-ad6424a93e5c', '2021-2-2',
        NULL, true, '32466301082');
INSERT INTO Processo_Judicial
VALUES ('3dbd9794-ce78-4353-8ddf-fa05582d6762', '2017-11-7',
        '2018-3-22', true, '14724061477');
INSERT INTO Processo_Judicial
VALUES ('315c6b8e-3feb-428e-b235-5e6c565f0514', '2018-12-28',
        '2018-9-20', false, '75953406409');
INSERT INTO Processo_Judicial
VALUES ('b39f53d0-6733-466a-b7c8-10ba54ea64e0', '2002-10-9',
        '2020-7-23', false, '99008050856');
INSERT INTO Processo_Judicial
VALUES ('404fb566-f47b-4bed-9c2f-3b332a4f3c56', '2017-6-15',
        NULL, false, '64671861850');
INSERT INTO Processo_Judicial
VALUES ('95d31982-ce5c-4cff-9076-00cd5f853c55', '2006-3-4',
        '2018-3-16', true, '54358800731');
INSERT INTO Processo_Judicial
VALUES ('71c6d3d3-e60e-446d-b95b-a834c5dcd362', '2012-12-30',
        NULL, false, '51327180704');
INSERT INTO Processo_Judicial
VALUES ('be59932e-43d5-4ab8-a9a6-1af249f084da', '2007-6-24',
        NULL, true, '37706179977');
INSERT INTO Processo_Judicial
VALUES ('e5ef9b1f-72ed-49a2-8373-a82ddb8de053', '2002-4-24',
        NULL, true, '42799690433');
INSERT INTO Processo_Judicial
VALUES ('da37f350-e6c1-4409-8561-1bfd0ac53d2c', '2012-6-3',
        NULL, false, '74947254906');
INSERT INTO Processo_Judicial
VALUES ('7aee45b3-b577-4797-992e-f8646c98284e', '2009-10-22',
        '2021-9-8', true, '54206616906');
INSERT INTO Processo_Judicial
VALUES ('c6d04b88-e5bd-4fed-b171-b2d58dbe5787', '2005-9-2',
        '2019-11-15', false, '72668227651');
INSERT INTO Processo_Judicial
VALUES ('54a94519-1839-400d-bf53-2d8249b05a46', '2008-1-8',
        NULL, true, '73645120004');
INSERT INTO Processo_Judicial
VALUES ('1a282ec2-b2ea-4bc6-bd78-989375cdd84b', '2021-5-5',
        NULL, false, '87476298043');
INSERT INTO Processo_Judicial
VALUES ('5409fc18-7807-42c9-9977-804dc1c69a5a', '2016-6-30',
        NULL, false, '87476298043');
INSERT INTO Processo_Judicial
VALUES ('247feccd-3229-4927-b0da-5c7ade66d96b', '2011-3-28',
        NULL, false, '56009768713');
INSERT INTO Processo_Judicial
VALUES ('09877c67-8db3-4b3b-9f4a-5f1cbf55dfee', '2006-12-6',
        '2018-4-15', false, '94322587393');
INSERT INTO Processo_Judicial
VALUES ('e9cf9122-7ce8-450f-aaca-79c0cceaf7ee', '2004-12-17',
        '2021-10-6', false, '55833025514');
INSERT INTO Processo_Judicial
VALUES ('b2340105-e1e0-40e9-a8bc-51e5dc7f2e57', '2019-3-19',
        '2017-11-9', true, '91896277903');
INSERT INTO Processo_Judicial
VALUES ('059e8113-0bff-4978-8232-594f4916161a', '2019-2-24',
        '2020-5-9', true, '44718153213');
INSERT INTO Processo_Judicial
VALUES ('28288b14-c197-45ed-ba40-84c8ffb7d9b0', '2004-2-15',
        NULL, true, '21502376149');
INSERT INTO Processo_Judicial
VALUES ('c2b4d80b-77ed-492d-9549-ad4441d6d743', '2021-1-17',
        '2018-12-30', false, '63891801896');
INSERT INTO Processo_Judicial
VALUES ('91802e69-83ad-4805-8c60-e3a64ba0f397', '2006-12-10',
        NULL, true, '49999960965');
INSERT INTO Processo_Judicial
VALUES ('5c3287c5-c68d-4d13-b5ea-a5f52c133e64', '2014-3-21',
        '2017-12-9', true, '60675624620');
INSERT INTO Processo_Judicial
VALUES ('e0ef96ed-7803-414f-b680-a2554f06a0fd', '2003-12-25',
        NULL, false, '18505114549');
INSERT INTO Processo_Judicial
VALUES ('216cc27d-fcf8-443d-b05c-bc0edaaff1e6', '2021-7-6',
        '2018-8-3', false, '75000258060');
INSERT INTO Processo_Judicial
VALUES ('882b94bd-7a25-4bf3-8746-51d964e28d96', '2004-8-15',
        '2018-7-12', true, '82870189829');
INSERT INTO Processo_Judicial
VALUES ('0b6195fe-aacb-4b24-b9d1-dcaf7d716c98', '2015-8-23',
        '2017-4-15', false, '23680543084');
INSERT INTO Processo_Judicial
VALUES ('24ccee35-0f10-4643-aea8-a98d70e5241e', '2012-11-30',
        NULL, false, '96358525417');
INSERT INTO Processo_Judicial
VALUES ('e904da4d-c7eb-4acd-9a5a-2cfbb8895fb6', '2019-3-24',
        '2017-12-12', false, '13162715234');
INSERT INTO Processo_Judicial
VALUES ('d82b0d9f-b6fe-4401-81ab-cb12de24b657', '2016-10-3',
        '2019-10-12', false, '95690040225');
INSERT INTO Processo_Judicial
VALUES ('48fc7e08-18e0-4f48-a1b2-272d38d937c2', '2021-3-25',
        NULL, false, '42713638902');
INSERT INTO Processo_Judicial
VALUES ('7bd542e6-7b19-4c7d-93b8-aef3c8a5edb9', '2014-8-16',
        '2019-12-25', false, '54206616906');
INSERT INTO Processo_Judicial
VALUES ('4390855c-8996-4514-ad69-f6e07c56341e', '2014-2-24',
        NULL, false, '39274698467');
INSERT INTO Processo_Judicial
VALUES ('96782786-cc32-4e6f-8039-0f2cd5919025', '2013-8-5',
        '2021-10-17', true, '57094097116');
INSERT INTO Processo_Judicial
VALUES ('a5727f06-8c97-4e5a-9cc4-a9a8aab3110a', '2007-4-10',
        NULL, true, '95344005359');
INSERT INTO Processo_Judicial
VALUES ('9ec4a064-40ee-4fb7-b63d-e63d1f4f7e09', '2015-12-23',
        '2018-1-26', true, '74363441457');
INSERT INTO Processo_Judicial
VALUES ('a0c4c670-0c65-4b79-986f-5788dc9cd95a', '2010-6-14',
        NULL, false, '80214095890');
INSERT INTO Processo_Judicial
VALUES ('3af867b6-c6fa-4ee6-bf63-ae4c345cd473', '2008-10-28',
        '2020-2-20', false, '94022594343');
INSERT INTO Processo_Judicial
VALUES ('8b3fe009-e1bc-421a-bf82-92404fe77b41', '2014-10-9',
        NULL, false, '97759025976');
INSERT INTO Processo_Judicial
VALUES ('a55ba038-876b-48f5-b9e9-39a0445486f7', '2013-1-25',
        NULL, true, '97070763893');
INSERT INTO Processo_Judicial
VALUES ('c87ccadb-ad38-41b4-b30c-c6a3572eb54d', '2007-3-24',
        NULL, true, '20593875704');
INSERT INTO Processo_Judicial
VALUES ('6dc4d075-1573-425f-b4a0-0c263e84a9fc', '2017-5-19',
        NULL, false, '42089914267');
INSERT INTO Processo_Judicial
VALUES ('2cbd2210-e97d-47eb-948e-029d36f8f1c3', '2007-6-3',
        '2017-6-28', true, '48273120142');
INSERT INTO Processo_Judicial
VALUES ('dd075183-17ce-43c0-8e38-e8690289a28d', '2020-5-23',
        NULL, false, '16082053717');
INSERT INTO Processo_Judicial
VALUES ('212023af-ecfc-4931-9abd-08e20aa6bd12', '2019-10-4',
        '2020-9-15', false, '94947150240');
INSERT INTO Processo_Judicial
VALUES ('1319f28c-1065-419f-bcde-e1b848dfa33c', '2008-12-7',
        '2018-5-27', false, '42799690433');
INSERT INTO Processo_Judicial
VALUES ('7fa1fdf1-1930-4226-b202-7fa2117d88b0', '2021-3-20',
        '2021-2-6', false, '66894887096');
INSERT INTO Processo_Judicial
VALUES ('1702a421-fd10-4502-9b9c-efb284d79a2f', '2019-7-16',
        '2020-12-9', false, '93598506252');
INSERT INTO Processo_Judicial
VALUES ('8e2fd689-6574-41db-923e-41b9618deefa', '2015-1-16',
        NULL, true, '60858012235');
INSERT INTO Processo_Judicial
VALUES ('0c611029-5bde-45a0-9d8c-96281225e3bc', '2006-6-14',
        '2017-11-24', false, '21313558840');
INSERT INTO Processo_Judicial
VALUES ('b4d10b38-bf95-419a-bb02-7f0e4fe88873', '2006-11-22',
        '2020-7-3', false, '54967094177');
INSERT INTO Processo_Judicial
VALUES ('cc17d168-f98c-4d3a-8c13-96f37215ddb1', '2012-1-14',
        NULL, false, '87588114035');
INSERT INTO Processo_Judicial
VALUES ('32932cd5-5539-49ba-b852-b0405b913d4a', '2004-1-1',
        NULL, false, '25783153302');
INSERT INTO Processo_Judicial
VALUES ('45396f43-dee4-40a5-865b-33c20f2734c9', '2003-8-3',
        NULL, false, '73656000972');
INSERT INTO Processo_Judicial
VALUES ('5d5d5bd7-6a5a-4b4e-b934-fd0556eb96c1', '2007-9-16',
        '2016-12-25', true, '32508439864');
INSERT INTO Processo_Judicial
VALUES ('608c54b0-34f4-4f4e-949a-461a3b9115b3', '2020-2-12',
        '2020-4-6', false, '67123855608');
INSERT INTO Processo_Judicial
VALUES ('008ab9db-37dd-41d3-928c-bbdfa8a5a7c1', '2021-5-1',
        NULL, true, '67562512347');
INSERT INTO Processo_Judicial
VALUES ('ed72e64c-6506-4c77-b105-a3579cf596b2', '2007-9-9',
        NULL, true, '14897848735');
INSERT INTO Processo_Judicial
VALUES ('13debda3-3fd7-4c7d-b9f3-360a646448d1', '2011-2-20',
        NULL, true, '89264845682');
INSERT INTO Processo_Judicial
VALUES ('c382a8a6-314e-4859-989f-931cb6e7aaf2', '2012-4-30',
        '2018-3-29', true, '16068811987');
INSERT INTO Processo_Judicial
VALUES ('db0dfb2c-4a1a-4368-a84e-658d4a90ac64', '2021-4-5',
        NULL, true, '80617708123');
INSERT INTO Processo_Judicial
VALUES ('d23cf8df-acc5-4674-a86f-40992802aa5e', '2011-9-11',
        '2018-4-9', true, '36943202530');
INSERT INTO Processo_Judicial
VALUES ('ec4a09df-6eaf-413a-ad89-992bdc3add5b', '2015-4-24',
        NULL, false, '48776552942');
INSERT INTO Processo_Judicial
VALUES ('02c96211-2d3d-49e6-ba0a-746444af8fba', '2003-3-29',
        NULL, false, '12911266039');
INSERT INTO Processo_Judicial
VALUES ('891f66d0-87e1-45fc-92a9-a7ee73e16d35', '2021-10-18',
        NULL, true, '47024384837');
INSERT INTO Processo_Judicial
VALUES ('24fe7966-7dae-4649-a890-95e1dec702f7', '2009-9-5',
        NULL, false, '16470102223');
INSERT INTO Processo_Judicial
VALUES ('7512ad76-0246-4a61-b173-af473358c373', '2016-12-11',
        '2020-5-22', false, '59156701033');
INSERT INTO Processo_Judicial
VALUES ('d93b2b38-f8ee-40b4-b237-10d372887215', '2005-7-30',
        '2017-3-12', true, '65327025726');
INSERT INTO Processo_Judicial
VALUES ('c4effc65-0ccc-4f19-8f32-4171fc1bf176', '2005-7-7',
        '2021-1-22', true, '67008212334');
INSERT INTO Processo_Judicial
VALUES ('3f172e3c-9247-421a-b1f2-1a9f6370c038', '2016-2-19',
        '2021-6-16', false, '81651619777');
INSERT INTO Processo_Judicial
VALUES ('7a765841-f525-4194-941b-5bff75aa60d3', '2018-6-27',
        '2017-10-8', true, '97614736857');
INSERT INTO Processo_Judicial
VALUES ('f1a99d91-61a9-4afb-89dd-f95113f3185d', '2010-8-6',
        '2017-9-4', true, '69817507220');
INSERT INTO Processo_Judicial
VALUES ('7aa4f547-85d8-424d-acd2-72c944829101', '2015-6-15',
        NULL, false, '37254095533');
INSERT INTO Processo_Judicial
VALUES ('df25ab3b-ccae-4749-b822-583db2ae2236', '2005-7-26',
        NULL, false, '23858233627');
INSERT INTO Processo_Judicial
VALUES ('83bec141-7163-41b1-b79d-556840c4b4b4', '2008-8-15',
        '2018-8-5', false, '93141531136');
INSERT INTO Processo_Judicial
VALUES ('af8178aa-5893-4ec7-bbe1-245744512227', '2006-10-5',
        '2020-4-12', true, '11253295710');
INSERT INTO Processo_Judicial
VALUES ('c7ecb73f-7360-48e1-8902-e62eba353891', '2006-11-1',
        '2019-11-10', true, '98591816106');
INSERT INTO Processo_Judicial
VALUES ('160e5154-270f-483b-8579-a73030a0bec5', '2004-1-10',
        NULL, false, '45923760337');
INSERT INTO Processo_Judicial
VALUES ('2d031a83-192a-4ac3-b8ea-89da9eefdff3', '2008-6-17',
        '2017-1-13', false, '94981895470');
INSERT INTO Processo_Judicial
VALUES ('c0764862-b15f-4d8c-b5e2-c46c7e6a52d6', '2002-5-12',
        NULL, false, '41397188589');
INSERT INTO Processo_Judicial
VALUES ('0f15b99c-27a1-4fb7-9016-d4e0e9a597c2', '2014-12-14',
        NULL, false, '88701410233');
INSERT INTO Processo_Judicial
VALUES ('1059af08-bea1-4b8f-b30b-fe6fd2ef3fc4', '2003-12-10',
        NULL, true, '44038899224');
INSERT INTO Processo_Judicial
VALUES ('b6be7231-8d7f-45f7-8e51-23ff6707cb98', '2012-9-17',
        NULL, false, '64779439785');
INSERT INTO Processo_Judicial
VALUES ('ca4d7409-f804-4b9f-bc40-9611681c6d1c', '2007-9-4',
        '2021-4-4', false, '64671861850');
INSERT INTO Processo_Judicial
VALUES ('9f1365ff-f827-4b6e-87ce-eec862288969', '2010-5-25',
        NULL, false, '49697081230');
INSERT INTO Processo_Judicial
VALUES ('7c3d3a82-7e0f-4421-bf69-37482ce056cf', '2019-4-30',
        '2020-8-13', false, '71656160976');
INSERT INTO Processo_Judicial
VALUES ('6faf718a-f04e-4842-bc31-acc77b0cb59e', '2011-1-3',
        NULL, false, '57094455254');
INSERT INTO Processo_Judicial
VALUES ('13bffd08-e269-47b2-8e5e-1ea0608f0ec9', '2017-8-3',
        '2018-6-16', true, '71877414532');
INSERT INTO Processo_Judicial
VALUES ('3218d262-5a3d-4f30-9ef2-3827638e4339', '2017-6-10',
        NULL, false, '25756717512');
INSERT INTO Processo_Judicial
VALUES ('60ef3810-52b4-431a-9559-11de78954b33', '2004-5-17',
        NULL, false, '47388927007');
INSERT INTO Processo_Judicial
VALUES ('b079c924-14d7-48dc-82ff-55f2e1516a04', '2012-6-13',
        NULL, true, '50634076290');
INSERT INTO Processo_Judicial
VALUES ('3afc0ece-eb6a-4fe9-a73a-19b5241fdc46', '2009-5-18',
        NULL, false, '80518763633');
INSERT INTO Processo_Judicial
VALUES ('ae0a51b1-c2c4-4f3d-bad2-1cd83212c404', '2007-4-14',
        NULL, false, '58980360710');
INSERT INTO Processo_Judicial
VALUES ('187388ab-4ea3-456d-b73b-8a4584a47b38', '2001-12-14',
        '2019-3-21', true, '41139387378');
INSERT INTO Processo_Judicial
VALUES ('281b1440-3a78-454c-a430-898e442ce24b', '2006-7-11',
        '2018-10-5', true, '56206870884');
INSERT INTO Processo_Judicial
VALUES ('6bc4bbc6-ed41-44ef-bb8c-b1ed7eee0d15', '2007-3-21',
        NULL, true, '63795995046');
INSERT INTO Processo_Judicial
VALUES ('a597e24a-03d8-479e-ba1d-1ed05eb70f9a', '2003-11-13',
        NULL, true, '60751450103');
INSERT INTO Processo_Judicial
VALUES ('7a5a3257-1d22-4462-8f26-277e3d35871f', '2015-9-25',
        '2020-6-26', false, '70189726690');
INSERT INTO Processo_Judicial
VALUES ('d809f65b-45d0-4f47-968f-ae0400996ff6', '2005-2-4',
        '2017-5-1', true, '54183079097');
INSERT INTO Processo_Judicial
VALUES ('bee28b95-1fd0-4d7b-b7bb-4cfa5cc9b8f9', '2010-4-13',
        '2021-7-29', false, '88668754065');
INSERT INTO Processo_Judicial
VALUES ('675fc4c4-b73d-4c96-8835-50499f74cef2', '2005-10-25',
        '2020-1-28', true, '23072280755');
INSERT INTO Processo_Judicial
VALUES ('71c00f2d-170b-4ea4-b302-e96bc08679a4', '2013-10-3',
        '2017-2-1', true, '48873054108');
INSERT INTO Processo_Judicial
VALUES ('d5806314-8d7f-4f83-b099-12501d0eb9bb', '2013-11-4',
        NULL, true, '69501396566');
INSERT INTO Processo_Judicial
VALUES ('67fb55ca-e46f-4af2-acb7-df8044f7d5f0', '2012-2-17',
        NULL, true, '42162135574');
INSERT INTO Processo_Judicial
VALUES ('de228cc1-40a9-41b7-bc7b-477280f020cd', '2011-5-11',
        NULL, true, '96389911915');
INSERT INTO Processo_Judicial
VALUES ('25899b50-3131-4986-b085-ec6b468eb806', '2021-6-8',
        '2017-6-24', true, '40210098912');
INSERT INTO Processo_Judicial
VALUES ('de5e60ff-ea98-4ad5-abd0-f323dcf3baf2', '2003-2-13',
        '2017-12-26', true, '51308676458');
INSERT INTO Processo_Judicial
VALUES ('090a3fd4-f380-4d8a-86c7-e60c302df151', '2002-12-6',
        '2018-5-31', true, '61363971529');
INSERT INTO Processo_Judicial
VALUES ('e8fde333-8f4f-40a3-b762-4d9e43238a33', '2009-7-2',
        '2020-3-2', true, '80214095890');
INSERT INTO Processo_Judicial
VALUES ('e1fc0ee9-63a0-4db1-9d80-aa736a29c864', '2017-10-31',
        '2017-3-3', true, '38865358545');
INSERT INTO Processo_Judicial
VALUES ('f6ca6b32-03ee-4248-949f-ee73bc39c17a', '2013-3-25',
        '2018-1-15', false, '45628193288');
INSERT INTO Processo_Judicial
VALUES ('650adfb1-fcdc-44cc-b4e1-d89825c726f0', '2021-10-30',
        NULL, false, '60620319524');
INSERT INTO Processo_Judicial
VALUES ('18b27def-60b2-4790-873e-59c26afa59be', '2009-6-11',
        '2017-12-28', false, '89025817608');
INSERT INTO Processo_Judicial
VALUES ('fb66ae8b-f0c4-4086-bacb-78240f49c001', '2021-11-2',
        NULL, false, '15407267932');
INSERT INTO Processo_Judicial
VALUES ('dd5e66eb-1fae-4b98-a855-08d8c4744e97', '2009-9-20',
        NULL, true, '16524949248');
INSERT INTO Processo_Judicial
VALUES ('a4318737-39b4-4e23-92ff-2cd9c75b3a90', '2020-3-28',
        NULL, true, '71358629062');
INSERT INTO Processo_Judicial
VALUES ('b0d6a988-6f44-4c42-bd26-14907ff2afe5', '2021-6-10',
        NULL, false, '43586174864');
INSERT INTO Processo_Judicial
VALUES ('3758f50e-6ad0-4d26-996d-1046f0612e5e', '2016-5-15',
        '2019-12-9', true, '98850444883');
INSERT INTO Processo_Judicial
VALUES ('c4750527-539c-4d3f-97a3-0808262c9010', '2012-10-14',
        '2021-9-4', false, '69501396566');
INSERT INTO Processo_Judicial
VALUES ('006fa57d-1a87-449e-8114-6e8832fd8fa1', '2010-2-14',
        NULL, false, '25862227568');
INSERT INTO Processo_Judicial
VALUES ('ee860c81-e269-40ce-8fe9-3ebe12f6891b', '2018-8-30',
        '2020-11-11', true, '68482680276');
INSERT INTO Processo_Judicial
VALUES ('07bc9acf-69fb-4ef7-9aa1-dcf8221e62a9', '2018-2-28',
        NULL, false, '85647496753');
INSERT INTO Processo_Judicial
VALUES ('a685629d-f61c-44e0-b68c-7ac98dcac80f', '2020-3-26',
        '2018-1-2', true, '46683265664');
INSERT INTO Processo_Judicial
VALUES ('e86e8a3f-019f-4d83-87ef-fe93750aef14', '2014-10-17',
        '2021-5-16', true, '69452778594');
INSERT INTO Processo_Judicial
VALUES ('d3567aca-a96a-4e5f-a068-65dca366cf6c', '2021-9-18',
        NULL, true, '70189726690');
INSERT INTO Processo_Judicial
VALUES ('3e7341f0-a2ae-49c2-a8f1-28f968f138a7', '2012-6-23',
        NULL, true, '39251236913');
INSERT INTO Processo_Judicial
VALUES ('4e54696c-c523-4e2e-bf02-d0515b807411', '2013-7-9',
        NULL, false, '72249765472');
INSERT INTO Processo_Judicial
VALUES ('1807ea3a-1ebb-47f7-ac71-7c2e82c999e4', '2008-7-12',
        NULL, true, '84767766646');
INSERT INTO Processo_Judicial
VALUES ('fca24fe9-43e8-44c7-9a9c-20fae239662e', '2003-8-4',
        NULL, true, '89308487717');
INSERT INTO Processo_Judicial
VALUES ('55b3640f-67d5-4c5a-a7d0-b4b6c08ae887', '2020-11-12',
        '2017-9-4', false, '50428395869');
INSERT INTO Processo_Judicial
VALUES ('b68a0590-f80b-40e4-a615-6947427eb8ff', '2002-4-18',
        NULL, false, '76707281675');
INSERT INTO Processo_Judicial
VALUES ('44efe576-37d8-48f7-ab4b-88e5dfe86998', '2012-12-30',
        NULL, false, '18379429504');
INSERT INTO Processo_Judicial
VALUES ('b8dc8b5b-4fe5-4c14-b16e-4c09f0487f33', '2004-1-12',
        NULL, false, '56399587204');
INSERT INTO Processo_Judicial
VALUES ('ccfe54da-350b-47ea-a111-bfd65c643a45', '2003-6-18',
        NULL, true, '32125016890');
INSERT INTO Processo_Judicial
VALUES ('6dc3e4ad-a973-4cf5-abdf-83437fbe22a8', '2016-12-29',
        NULL, false, '96993440124');
INSERT INTO Processo_Judicial
VALUES ('2b39d6e1-02cc-4e52-a71e-a45db4d5c28f', '2016-8-9',
        '2016-12-4', true, '86282287575');
INSERT INTO Processo_Judicial
VALUES ('16180604-eea4-431a-90fd-db19d2508479', '2004-8-25',
        '2020-2-7', true, '20934364222');
INSERT INTO Processo_Judicial
VALUES ('bdafcdb5-479a-4c3c-92a0-7cb79ad61f4b', '2017-11-18',
        NULL, false, '90432507826');
INSERT INTO Processo_Judicial
VALUES ('f2eaf32d-4f87-4b8f-8dca-3173bff33e38', '2018-4-13',
        '2020-5-31', true, '93630574638');
INSERT INTO Processo_Judicial
VALUES ('464dda3a-5a7b-4f92-84dc-f58deb38478b', '2003-6-16',
        NULL, false, '57979449972');
INSERT INTO Processo_Judicial
VALUES ('8fb6187d-63cf-4ed3-b55e-56d4c3fc3b7e', '2005-11-22',
        NULL, true, '87588114035');
INSERT INTO Processo_Judicial
VALUES ('912eabfd-1fd3-4dc6-837d-036ef6b0d78c', '2017-5-16',
        NULL, true, '86282287575');
INSERT INTO Processo_Judicial
VALUES ('1872ecd0-270a-4b40-a8da-c3fea27d81d0', '2006-1-9',
        '2019-12-30', false, '13525109647');
INSERT INTO Processo_Judicial
VALUES ('8c2bd0a2-ea4d-4776-a7c1-e8cd957568f8', '2021-3-23',
        '2018-1-6', true, '15334344431');
INSERT INTO Processo_Judicial
VALUES ('28c21bdf-1006-4643-9304-17047efbead9', '2006-1-9',
        '2018-4-9', false, '34657710711');
INSERT INTO Processo_Judicial
VALUES ('04d9b326-8e94-4658-ba9a-40b3f25a0d0f', '2018-8-1',
        NULL, false, '56046937885');
INSERT INTO Processo_Judicial
VALUES ('c42ab45c-201a-435b-ba4d-ec70bd74cf23', '2004-5-13',
        NULL, true, '94981895470');
INSERT INTO Processo_Judicial
VALUES ('d10b2afc-a881-44da-955f-6752413d0d2f', '2005-4-18',
        NULL, false, '61486375667');
INSERT INTO Processo_Judicial
VALUES ('24d56cd3-59a5-41d7-b83a-02edfc841889', '2008-1-13',
        NULL, false, '86534657040');
INSERT INTO Processo_Judicial
VALUES ('c07748db-8c40-4946-8ee6-651dce76ff66', '2008-5-24',
        '2018-1-5', false, '18379429504');
INSERT INTO Processo_Judicial
VALUES ('4f7bbae5-2d57-4dc8-89f2-5250326fbcb1', '2006-11-11',
        NULL, false, '40210098912');
INSERT INTO Processo_Judicial
VALUES ('dae16d1c-edb8-49eb-8ad3-c2e71d82c077', '2018-2-6',
        NULL, false, '14574779509');
INSERT INTO Processo_Judicial
VALUES ('4fc58fad-ff73-4fb2-84d2-aca089d6f68c', '2019-2-28',
        NULL, true, '22994280902');
INSERT INTO Processo_Judicial
VALUES ('ae0a89b2-015a-4f79-a95e-4eaebd20ec6f', '2009-8-9',
        '2020-7-25', false, '22431804153');
INSERT INTO Processo_Judicial
VALUES ('63433bf7-dd56-45db-8526-1bb8782fcaa9', '2014-1-15',
        '2020-12-21', false, '58932911595');
INSERT INTO Processo_Judicial
VALUES ('1ef7ff44-bc5b-4e42-b268-8b4d4f6f3e37', '2003-6-7',
        '2018-5-1', true, '93402923154');
INSERT INTO Processo_Judicial
VALUES ('e932d58a-2b17-485d-8240-4917e26f6f00', '2020-2-12',
        '2019-9-6', false, '31800616828');
INSERT INTO Processo_Judicial
VALUES ('9c34622e-b1c1-4ff1-80c2-e59a0159878c', '2009-6-11',
        NULL, true, '97468617402');
INSERT INTO Processo_Judicial
VALUES ('033fb7ff-d82a-48e5-8f38-753c8f240bbb', '2019-2-6',
        '2017-7-9', false, '92776450554');
INSERT INTO Processo_Judicial
VALUES ('e0bf66f6-6977-4e1a-8fdc-63311cd4656b', '2015-4-17',
        NULL, true, '32228380509');
INSERT INTO Processo_Judicial
VALUES ('74397493-9c15-456c-82df-80c1188efbbf', '2014-11-21',
        '2020-5-7', true, '41319743199');
INSERT INTO Processo_Judicial
VALUES ('9df24e6e-3efd-4766-8df5-528d464c7d81', '2007-1-5',
        '2018-4-21', true, '76646342640');
INSERT INTO Processo_Judicial
VALUES ('cf605790-4573-401f-a783-0b63a13b486a', '2016-10-6',
        NULL, false, '46683265664');
INSERT INTO Processo_Judicial
VALUES ('d0225372-d627-4750-bd37-a928b62fb518', '2012-8-11',
        NULL, true, '51977524964');
INSERT INTO Processo_Judicial
VALUES ('a3ee108c-6b27-42ca-8f1c-c61a91859dae', '2007-9-4',
        NULL, true, '68093798568');
INSERT INTO Processo_Judicial
VALUES ('f2b4a5c5-e69d-442a-accd-da15925d169b', '2019-11-22',
        NULL, true, '88463596005');
INSERT INTO Processo_Judicial
VALUES ('f3e3754a-9793-4af5-9e68-683e0f56db26', '2012-9-12',
        NULL, false, '57299066584');
INSERT INTO Processo_Judicial
VALUES ('d78d0758-d5ad-4111-8875-48ec4abb0474', '2004-7-31',
        '2021-6-25', true, '13836945446');
INSERT INTO Processo_Judicial
VALUES ('115fa5bd-ec85-4cde-9f35-4d74ea18ccb3', '2012-8-16',
        '2017-9-9', false, '43331410249');
INSERT INTO Processo_Judicial
VALUES ('316f10a4-edc0-472e-a6af-4ceeab9a0931', '2011-2-1',
        '2018-5-24', true, '13641347680');
INSERT INTO Processo_Judicial
VALUES ('717d9f31-48fb-4f80-8ecc-1b0e83914cc6', '2014-8-20',
        NULL, false, '37938732800');
INSERT INTO Processo_Judicial
VALUES ('650bd1b6-4077-4261-a006-565d693a0744', '2014-7-30',
        '2016-12-11', true, '89382796012');
INSERT INTO Processo_Judicial
VALUES ('86a6f9e4-d810-4c0b-98ba-c39d31757c39', '2019-12-22',
        '2020-11-23', false, '69286284870');
INSERT INTO Processo_Judicial
VALUES ('85845c52-c571-4fc6-b582-6f41a596ccc3', '2018-5-27',
        NULL, true, '88668754065');
INSERT INTO Processo_Judicial
VALUES ('05655962-60c8-4823-9cc8-698bd18449f2', '2014-3-20',
        '2021-9-6', false, '26070915332');
INSERT INTO Processo_Judicial
VALUES ('b8d18abf-bdb1-4a64-8490-98721c5cb437', '2008-5-8',
        NULL, true, '40100553724');
INSERT INTO Processo_Judicial
VALUES ('b8f9897e-d069-42cb-90f0-a1480671b5d2', '2016-1-7',
        NULL, false, '51165132678');
INSERT INTO Processo_Judicial
VALUES ('21be5e9a-c38c-4af9-9408-6848503dd61f', '2009-1-25',
        NULL, true, '49404086042');
INSERT INTO Processo_Judicial
VALUES ('c8f9fac7-a405-4b84-9a19-091e539f7063', '2010-9-27',
        '2019-5-2', false, '74194578086');
INSERT INTO Processo_Judicial
VALUES ('4d03df88-d010-4fef-83a1-0a23f2ab1467', '2019-8-29',
        '2020-1-25', false, '69618394083');
INSERT INTO Processo_Judicial
VALUES ('1ab3ace4-2299-4365-bb09-e4e92b35e711', '2008-12-25',
        NULL, true, '76445934206');
INSERT INTO Processo_Judicial
VALUES ('526ac752-8d2a-491e-b9af-1e5ece4d8f25', '2006-8-6',
        '2020-5-24', false, '55587859393');
INSERT INTO Processo_Judicial
VALUES ('274b66a1-f769-4579-be35-14031c732ed8', '2009-2-5',
        '2018-7-9', false, '73645120004');
INSERT INTO Processo_Judicial
VALUES ('17a1ba2a-36e4-4505-9363-a25bb8e9a6f4', '2011-9-20',
        NULL, false, '99514881155');
INSERT INTO Processo_Judicial
VALUES ('15c3d844-3654-4ba7-bcb8-cc47365a446e', '2018-9-25',
        '2019-2-25', false, '43359677735');
INSERT INTO Processo_Judicial
VALUES ('93475d35-51e3-491c-bdc9-7ba4e25dfaa9', '2012-3-4',
        NULL, true, '25002746400');
INSERT INTO Processo_Judicial
VALUES ('7689a455-9aad-43a7-802b-60ea888a7618', '2020-10-1',
        '2019-3-29', false, '97614736857');
INSERT INTO Processo_Judicial
VALUES ('de2968f4-9c1e-4bf3-b1fc-6772ea0bb98c', '2009-5-20',
        '2020-10-25', false, '83235424910');
INSERT INTO Processo_Judicial
VALUES ('0b48916a-2c95-4c74-aaef-c53d64d8854e', '2004-7-14',
        '2019-7-6', false, '98227631277');
INSERT INTO Processo_Judicial
VALUES ('ec0aa3b6-baed-466b-83d1-b29601833362', '2018-6-27',
        NULL, false, '19264541170');
INSERT INTO Processo_Judicial
VALUES ('9c50e0dc-d889-41bf-b36f-ed8a1f7c45fa', '2018-5-12',
        '2021-7-15', true, '93557888891');
INSERT INTO Processo_Judicial
VALUES ('39ebd01c-49a8-4465-9dde-cba0ea55971d', '2014-4-11',
        NULL, true, '52914412149');
INSERT INTO Processo_Judicial
VALUES ('06ce385a-d7ae-4e9a-bd9f-4defb6ada7a6', '2019-11-25',
        NULL, true, '76850075086');
INSERT INTO Processo_Judicial
VALUES ('76d8a847-65bc-4b12-83ae-be2beae0dc3f', '2011-4-28',
        NULL, true, '28683887836');
INSERT INTO Processo_Judicial
VALUES ('d5fa0d22-4b4f-4d15-af45-6634fcee7a8e', '2011-9-6',
        NULL, true, '70844363323');
INSERT INTO Processo_Judicial
VALUES ('8bfa630b-f5db-40eb-9cfc-9865785d91f7', '2016-4-22',
        NULL, true, '49723011339');
INSERT INTO Processo_Judicial
VALUES ('b5a6df04-a97c-4f79-9cdd-a4296f2a1168', '2021-2-19',
        '2021-8-8', true, '50892221683');
INSERT INTO Processo_Judicial
VALUES ('19be6835-5bb3-4e4b-b950-0ee31b7e87f3', '2011-6-29',
        '2020-9-6', true, '11120354053');
INSERT INTO Processo_Judicial
VALUES ('8a21f8f4-ee27-487a-8a7c-b48528b73adb', '2015-7-20',
        '2018-2-21', true, '57299066584');
INSERT INTO Processo_Judicial
VALUES ('4a89cca2-6435-4ff5-838d-714ed37d0e0e', '2013-1-4',
        NULL, true, '51697040249');
INSERT INTO Processo_Judicial
VALUES ('459828df-60e2-48cd-9da4-a548654c863f', '2012-10-3',
        '2016-12-11', true, '23186676069');
INSERT INTO Processo_Judicial
VALUES ('011913c2-5bcc-42eb-826f-ffb4b1c69857', '2020-3-22',
        '2019-5-5', false, '83541382439');
INSERT INTO Processo_Judicial
VALUES ('86973d7d-f098-49ee-b583-e8ed5069ce0c', '2019-9-9',
        NULL, true, '75071605008');
INSERT INTO Processo_Judicial
VALUES ('e5d864a5-61f9-4f52-b99e-293f3844f759', '2004-9-28',
        '2019-10-3', true, '78522324447');
INSERT INTO Processo_Judicial
VALUES ('9cb3c757-328e-45cd-b7f9-5e609ff58198', '2020-5-9',
        '2020-7-5', false, '61577998858');
INSERT INTO Processo_Judicial
VALUES ('0a15e450-6e63-40f1-bdc0-7834e85f890b', '2006-1-22',
        NULL, false, '22529268462');
INSERT INTO Processo_Judicial
VALUES ('8740a428-564f-4213-9b3d-ae129487221c', '2002-7-17',
        '2021-3-11', false, '49292941880');
INSERT INTO Processo_Judicial
VALUES ('4f5c604c-8467-4386-81aa-9713fa15f0b1', '2020-7-13',
        NULL, true, '53392276959');
INSERT INTO Processo_Judicial
VALUES ('7fa3460b-d068-46c5-a25c-0d613aec180f', '2020-2-4',
        '2019-3-9', true, '67008212334');
INSERT INTO Processo_Judicial
VALUES ('4dfd45ea-2729-4e64-ace5-da56b4bdd125', '2015-4-11',
        '2020-1-3', false, '33644861271');
INSERT INTO Processo_Judicial
VALUES ('79f26dd5-400b-49c1-9695-7fd0e58ed29a', '2004-4-23',
        NULL, false, '45628193288');
INSERT INTO Processo_Judicial
VALUES ('fbc59f0b-a7dd-4277-b788-0d8bcca6b528', '2008-5-16',
        NULL, true, '84774450208');
INSERT INTO Processo_Judicial
VALUES ('d8dbf7d4-404b-4719-966e-dca97c22d8d3', '2009-9-2',
        '2020-8-20', false, '96358525417');
INSERT INTO Processo_Judicial
VALUES ('5987e40c-6b4c-467e-886d-b7a3586b3b6e', '2013-12-13',
        '2018-7-7', false, '53198584232');
INSERT INTO Processo_Judicial
VALUES ('09396001-9838-43c7-ad1f-ab4deed951e0', '2009-8-19',
        '2017-9-13', true, '88044670873');
INSERT INTO Processo_Judicial
VALUES ('840c2139-97a6-4504-9993-d33fa10eae06', '2015-1-8',
        NULL, false, '53378136730');
INSERT INTO Processo_Judicial
VALUES ('c6916f2f-21b2-4336-8a8b-bb13c4cf264a', '2006-12-18',
        NULL, false, '41139387378');
INSERT INTO Processo_Judicial
VALUES ('e2e2d062-4c4e-4e0c-a13c-a5eeb4e006eb', '2010-11-4',
        '2019-9-17', true, '29509833429');
INSERT INTO Processo_Judicial
VALUES ('66444e4d-c606-439b-89df-1974e79e7e77', '2015-2-8',
        '2020-2-3', false, '39251236913');
INSERT INTO Processo_Judicial
VALUES ('f346f14b-d166-40df-8e33-b83f1345f32f', '2006-7-20',
        '2018-1-31', false, '95630513457');
INSERT INTO Processo_Judicial
VALUES ('ffc68938-e611-4d8b-8659-a9ee78089aa5', '2006-9-25',
        '2018-2-25', false, '31701090801');
INSERT INTO Processo_Judicial
VALUES ('8fe055ce-9e3e-47ae-8a77-75906ff25752', '2018-12-16',
        '2021-2-3', true, '44331545557');
INSERT INTO Processo_Judicial
VALUES ('c1a09587-555d-40cd-9353-83c712d5e90d', '2013-1-9',
        '2019-2-3', true, '69932859244');
INSERT INTO Processo_Judicial
VALUES ('ee578467-1134-45ac-a142-15ca74519847', '2018-10-3',
        NULL, false, '74355497739');
INSERT INTO Processo_Judicial
VALUES ('04b01622-5dec-4094-bc64-b9b0aae97c93', '2003-8-25',
        '2020-1-13', true, '98198924474');
INSERT INTO Processo_Judicial
VALUES ('efd85115-bc73-471c-994c-9383249ecf00', '2008-2-22',
        '2017-4-8', true, '32128272987');
INSERT INTO Processo_Judicial
VALUES ('78f148c1-f123-4ac3-9882-c9075e8b0e4a', '2003-10-14',
        NULL, false, '49287718026');
INSERT INTO Processo_Judicial
VALUES ('729043e3-7f5b-44b1-9b80-8ceebb685e9e', '2019-8-3',
        '2020-7-15', false, '38185161759');
INSERT INTO Processo_Judicial
VALUES ('2360efb3-21c0-44ce-a0a9-5bdfe17774b9', '2021-4-23',
        NULL, false, '53509038442');
INSERT INTO Processo_Judicial
VALUES ('487078d5-ad2d-400e-a675-115bbb6c8e26', '2013-12-27',
        NULL, false, '34996525992');
INSERT INTO Processo_Judicial
VALUES ('59751e2a-5976-4198-86b2-1ef15a478cdc', '2006-5-5',
        '2021-8-30', false, '15123706744');
INSERT INTO Processo_Judicial
VALUES ('8f65ccd9-e423-4973-be3b-b3fa60cf116f', '2021-9-12',
        '2018-5-20', false, '61522070106');
INSERT INTO Processo_Judicial
VALUES ('791026a5-3317-4b3c-b086-8dcfe556d9fb', '2008-2-10',
        NULL, true, '56399587204');
INSERT INTO Processo_Judicial
VALUES ('454039df-e67b-4629-9db8-13a39b1e7e86', '2015-10-13',
        NULL, false, '23680543084');
INSERT INTO Processo_Judicial
VALUES ('10e5c984-e455-41c1-be1a-b9809b271f92', '2021-9-22',
        NULL, false, '63405921850');
INSERT INTO Processo_Judicial
VALUES ('441a1e77-ff11-438b-a653-fc220d284aa6', '2004-1-24',
        '2017-5-14', true, '95344005359');
INSERT INTO Processo_Judicial
VALUES ('f4121c7d-537b-4e69-b612-94a5d6d880f6', '2011-4-3',
        '2019-4-5', false, '34702133666');
INSERT INTO Processo_Judicial
VALUES ('ab1a657a-38bf-411a-bcd9-a7809dd81698', '2011-7-18',
        '2019-4-7', true, '62780075336');
INSERT INTO Processo_Judicial
VALUES ('6251cbad-ef67-437d-a3cb-d9f310c3bb4b', '2007-7-10',
        NULL, true, '54133691079');
INSERT INTO Processo_Judicial
VALUES ('3abdf7cc-8c73-46c3-873c-e98ab1cb9b4a', '2006-5-21',
        NULL, true, '56224074342');
INSERT INTO Processo_Judicial
VALUES ('a923430c-c7e5-47e5-a30e-20257e6827b2', '2017-2-4',
        NULL, false, '50671691924');
INSERT INTO Processo_Judicial
VALUES ('27c991bb-4f12-427a-8937-dd4b46d7607e', '2010-2-3',
        NULL, false, '45746368169');
INSERT INTO Processo_Judicial
VALUES ('d23e20e4-7246-454b-848b-e489d26630df', '2019-9-24',
        '2019-8-30', true, '92465915710');
INSERT INTO Processo_Judicial
VALUES ('db4fd1ce-9642-419b-8905-03b40c4fd54f', '2020-10-9',
        '2021-3-14', false, '41769931132');
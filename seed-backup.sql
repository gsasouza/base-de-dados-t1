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
    CONSTRAINT FK_PRESIDENTE FOREIGN KEY (CPF_Presidente) REFERENCES Pessoa (CPF),
    CONSTRAINT FK_PROGRAMA FOREIGN KEY (ID_Programa) REFERENCES Programa_Partido (ID)
);

CREATE TABLE Candidato
(
    CPF_Candidato VARCHAR(11) NOT NULL,
    Sigla_Partido VARCHAR(8)  NOT NULL,

    CONSTRAINT PK_CANDIDATO PRIMARY KEY (CPF_Candidato, Sigla_Partido),
    CONSTRAINT FK_SIGLA_PARTIDO FOREIGN KEY (Sigla_Partido) REFERENCES Partido (Sigla),
    CONSTRAINT FK_CPF_CANDIDATO FOREIGN KEY (CPF_Candidato) REFERENCES Pessoa (CPF)
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
    Ano_Pleito      INT                 NOT NULL,
    ID_Cargo        VARCHAR(255)        NOT NULL,
    Votos_Recebidos INT                 NOT NULL DEFAULT 0,

    CONSTRAINT PK_CANDIDATURA PRIMARY KEY (ID),
    CONSTRAINT FK_CPF_CANDIDATO FOREIGN KEY (CPF_Candidato) REFERENCES Pessoa (CPF),
    CONSTRAINT FK_CPF_VICE FOREIGN KEY (CPF_Vice) REFERENCES Pessoa (CPF),
    CONSTRAINT FK_PLEITO FOREIGN KEY (Ano_Pleito) REFERENCES Pleito (Ano),
    CONSTRAINT FK_CARGO FOREIGN KEY (ID_Cargo) REFERENCES Cargo (ID)
);

CREATE TABLE Equipe_Apoio
(
    ID             VARCHAR(255) NOT NULL,
    ID_Candidatura VARCHAR(255) NOT NULL,
    Ano_Pleito     INT          NOT NULL,
    Objetivo       VARCHAR(255) NOT NULL,

    CONSTRAINT PK_EQUIPE_APOIO PRIMARY KEY (ID),
    CONSTRAINT FK_CANDIDATURA FOREIGN KEY (ID_Candidatura) REFERENCES Candidatura (ID)
);

CREATE TABLE Apoiador_Campanha
(
    ID_Equipe_Apoio VARCHAR(255) NOT NULL,
    CPF_Apoiador    VARCHAR(11)   NOT NULL,
    ID_Candidatura  VARCHAR(255) NOT NULL,
    CONSTRAINT PK_APOIADOR_CAMPANHA PRIMARY KEY (CPF_Apoiador, ID_Equipe_Apoio),
    CONSTRAINT FK_EQUIPE_APOIO FOREIGN KEY (ID_Equipe_Apoio) REFERENCES Equipe_Apoio (ID)
);

CREATE TABLE Doador_Campanha
(
    ID   VARCHAR(255) UNIQUE NOT NULL,
    CPF  VARCHAR(11),
    CNPJ VARCHAR(14),

    CONSTRAINT PK_DOADOR_CAMPANHA PRIMARY KEY (ID)
);

CREATE TABLE Doacao_Candidatura
(
    ID_Doador      VARCHAR(255) NOT NULL,
    ID_Candidatura VARCHAR(255) NOT NULL,
    Valor          INT          NOT NULL,

    CONSTRAINT PK_DOACAO_CANDIDATURA PRIMARY KEY (ID_Candidatura, ID_Doador),
    CONSTRAINT FK_CANDIDATURA FOREIGN KEY (ID_Candidatura) REFERENCES Candidatura (ID),
    CONSTRAINT FK_DOADOR_CAMPANHA FOREIGN KEY (ID_Doador) REFERENCES Doador_Campanha (ID)

);

CREATE TABLE Processo_Judicial
(
    ID          VARCHAR(255) NOT NULL,
    Data_Inicio DATE         NOT NULL,
    Data_Fim    DATE,
    Procedente  BOOLEAN,
    CPF_Reu     VARCHAR(11)   NOT NULL,

    CONSTRAINT PK_PROCESS_JUDICIAL PRIMARY KEY (ID),
    CONSTRAINT FK_CPF_REU FOREIGN KEY (CPF_Reu) REFERENCES Pessoa (CPF)
);

--- FIM DDL ---
--- INICIO TRIGGERS ---

-- Valida se o candidato já existe com partido diferente

CREATE OR REPLACE FUNCTION valida_candidato() RETURNS trigger AS
$valida_candidato$
DECLARE
candidatos_partido INTEGER;
BEGIN
SELECT COUNT(*)
INTO candidatos_partido
FROM Candidato
WHERE CPF_Candidato = NEW.CPF_Candidato;

IF (candidatos_partido > 0) THEN
        RAISE EXCEPTION 'O Candidato já está cadastrado';
END IF;

RETURN NEW;
END;
$valida_candidato$ LANGUAGE plpgsql;
CREATE TRIGGER VALIDA_CANDIDATo
    BEFORE INSERT OR UPDATE
                         ON Candidato
                         FOR EACH ROW
                         EXECUTE PROCEDURE valida_candidato();


--- VALIDA SE O CANDIDATO JÁ ESTÁ CADASTRADO NO PLEITO DO ANO
CREATE OR REPLACE FUNCTION valida_candidatura() RETURNS trigger AS
$valida_candidatura$
DECLARE
candidaturas_ano INTEGER;
BEGIN
SELECT COUNT(*)
INTO candidaturas_ano
FROM Candidatura
WHERE CPF_Candidato = NEW.CPF_Candidato
  AND Ano_Pleito = NEW.Ano_Pleito;
IF (candidaturas_ano > 0) THEN
        RAISE EXCEPTION 'O Candidato já está cadastrado no pleito desse ano';
END IF;

RETURN NEW;
END;
$valida_candidatura$ LANGUAGE plpgsql;
CREATE TRIGGER VALIDA_CANDIDATURA
    BEFORE INSERT OR UPDATE
                         ON Candidatura
                         FOR EACH ROW
                         EXECUTE PROCEDURE valida_candidatura();

-- Valida se o candidato é ficha limpa
CREATE OR REPLACE FUNCTION valida_candidatura_ficha_limpa() RETURNS trigger AS
$valida_candidatura_ficha_limpa$
DECLARE
nro_processos_culpado_candidato INTEGER;
    nro_processos_culpado_vice      INTEGER;
BEGIN
SELECT COUNT(*)
INTO nro_processos_culpado_candidato
FROM Processo_Judicial
WHERE CPF_Reu = NEW.CPF_Candidato
  AND Procedente = TRUE
  AND Data_Fim BETWEEN CURRENT_DATE - INTERVAL '5 YEARS' AND CURRENT_DATE;

SELECT COUNT(*)
INTO nro_processos_culpado_vice
FROM Processo_Judicial
WHERE CPF_Reu = NEW.CPF_Vice
  AND Procedente = TRUE
  AND Data_Fim BETWEEN CURRENT_DATE - INTERVAL '5 YEARS' AND CURRENT_DATE;

IF (nro_processos_culpado_candidato > 0) THEN
        RAISE EXCEPTION 'Candidato não é ficha limpa';
END IF;

    IF (NEW.CPF_VICE <> NULL AND nro_processos_culpado_candidato > 0) THEN
        RAISE EXCEPTION 'Vice-Candidato não é ficha limpa';
END IF;

RETURN NEW;
END;
$valida_candidatura_ficha_limpa$ LANGUAGE plpgsql;
CREATE TRIGGER VALIDA_CANDIDATURA_FICHA_LIMPA
    BEFORE INSERT OR UPDATE
                         ON Candidatura
                         FOR EACH ROW
                         EXECUTE PROCEDURE valida_candidatura_ficha_limpa();

-- Valida se o cargo tem uma cidade, estado ou federação
CREATE OR REPLACE FUNCTION valida_cargo() RETURNS trigger AS
$valida_cargo$
BEGIN
    IF (NEW.Cidade IS NOT NULL) THEN
        RETURN NEW;
    ELSEIF (NEW.Estado IS NOT NULL) THEN
        RETURN NEW;
    ELSEIF (NEW.Federacao IS NOT NULL) THEN
        RETURN NEW;
END IF;
    RAISE EXCEPTION 'Um cargo deve estar associado a uma cidade, estado ou federeção';
END;
$valida_cargo$ LANGUAGE plpgsql;
CREATE TRIGGER VALIDA_CARGO
    BEFORE INSERT OR UPDATE
                         ON Cargo
                         FOR EACH ROW
                         EXECUTE PROCEDURE valida_cargo();

-- Valida se o indivíduo já está apoiando alguma campanha no memsmo ano

CREATE OR REPLACE FUNCTION valida_apoiador_campanha() RETURNS trigger AS
$valida_apoiador_campanha$
DECLARE
nro_campanhas_ano  INTEGER;
    ano_campanha_atual INTEGER;
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


IF (nro_campanhas_ano > 0) THEN
        RAISE EXCEPTION 'Indivíduo só pode apoiar uma campanha por ano';
END IF;

RETURN NEW;
END;
$valida_apoiador_campanha$ LANGUAGE plpgsql;
CREATE TRIGGER VALIDA_APOIADOR_CAMPANHA
    BEFORE INSERT OR UPDATE
                         ON Apoiador_Campanha
                         FOR EACH ROW
                         EXECUTE PROCEDURE valida_apoiador_campanha();

-- Valida documento do doador

CREATE OR REPLACE FUNCTION valida_doador_documento() RETURNS trigger AS
$valida_doador_documento$
BEGIN
    IF (NEW.CPF = NULL AND NEW.CNPJ = NULL) THEN
        RAISE EXCEPTION 'Um doador deve ser uma empresa ou um indivíduo';
END IF;

    IF (NEW.CPF <> NULL AND NEW.CNPJ <> NULL) THEN
        RAISE EXCEPTION 'Um doador não pode ter cpf e cnpj ao mesmo tempo';
END IF;

RETURN NEW;
END;
$valida_doador_documento$ LANGUAGE plpgsql;
CREATE TRIGGER VALIDA_DOACAO_DOCUMENTO
    BEFORE INSERT OR UPDATE
                         ON Doador_Campanha
                         FOR EACH ROW
                         EXECUTE PROCEDURE valida_doador_documento();

-- Valida numero de doação de empresas

CREATE OR REPLACE FUNCTION valida_doacao_empresa() RETURNS trigger AS
$valida_doacao_empresa$
DECLARE
nro_doacao_candidatura INTEGER;
BEGIN
SELECT COUNT(*)
INTO nro_doacao_candidatura
FROM Doacao_Candidatura
WHERE ID_Candidatura = NEW.ID_Candidatura
  AND ID_Doador = NEW.ID_Doador;

IF (nro_doacao_candidatura > 0) THEN
        RAISE EXCEPTION 'Uma empresa pode doar apenas uma vez por candidatura';
END IF;
RETURN NEW;
END;
$valida_doacao_empresa$ LANGUAGE plpgsql;
CREATE TRIGGER VALIDA_DOADOR_EMPRESA
    BEFORE INSERT OR UPDATE
                         ON Doacao_Candidatura
                         FOR EACH ROW
                         EXECUTE PROCEDURE valida_doacao_empresa();

-- Atualiza total de votos do pleito

CREATE OR REPLACE FUNCTION atualiza_votos_pleito() RETURNS trigger AS
$atualiza_votos_pleito$
DECLARE
nro_votos_pleito INTEGER;
BEGIN
SELECT SUM(Votos_Recebidos) INTO nro_votos_pleito FROM Candidatura WHERE Ano_Pleito = NEW.Ano_Pleito;
UPDATE Pleito
SET Total_Votos = nro_votos_pleito
WHERE Ano = NEW.Ano_Pleito;
RETURN NEW;
END;
$atualiza_votos_pleito$ LANGUAGE plpgsql;
CREATE TRIGGER VALIDA_DOADOR_EMPRESA
    AFTER INSERT OR UPDATE
                        ON Candidatura
                        FOR EACH ROW
                        EXECUTE PROCEDURE atualiza_votos_pleito();

-- FIM TRIGGERS



--- Insere pessoas

INSERT INTO Pessoa
VALUES ('46037782656', '535577217722', 'Vitória Moraes', 'Martins Travessa, 5302, undefined Gustavo do Descoberto, PR',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('25317057166', '516833634348', 'Yango Saraiva', 'Martins Rodovia, 71266, Azusa, PR',
        'superior completo');
INSERT INTO Pessoa
VALUES ('42580829826', '760407845443', 'Clara Carvalho', 'Carvalho Rua, 3659, Miramar, SE',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('83222212893', '773401726339', 'Sara Moraes', 'Santos Avenida, 45030, Lake Forest, MG',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('81480079204', '177527953428', 'Frederico Martins', 'Barros Rodovia, 92764, Schenectady, CE',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('13378266729', '675643332954', 'Célia Xavier', 'Roberta Alameda, 99312, undefined Beatriz, ES',
        'superior completo');
INSERT INTO Pessoa
VALUES ('44480531623', '843984759808', 'Vicente Oliveira', 'Laura Rua, 96498, undefined Carlos do Sul, GO',
        'superior completo');
INSERT INTO Pessoa
VALUES ('37496586486', '380908475373', 'Anthony Silva', 'Macedo Marginal, 79721, Franco do Descoberto, RR',
        'mestrado');
INSERT INTO Pessoa
VALUES ('30904407899', '164400630327', 'Fabiano Santos', 'Moraes Alameda, 60647, Alexandre do Descoberto, BA',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('88644450863', '929242511047', 'Maria Luiza Carvalho', 'Bryan Avenida, 93275, Yago do Sul, SE',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('54104066689', '378088067215', 'Pietro Oliveira', 'Silva Rua, 97877, Macedo do Norte, RJ',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('79990477925', '880208176956', 'Benício Barros', 'Nogueira Alameda, 66189, Marina do Descoberto, SE',
        'doutorado');
INSERT INTO Pessoa
VALUES ('60391245295', '803375486680', 'Ladislau Macedo', 'Hélio Alameda, 26699, Oliveira do Sul, CE',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('14448990675', '468541790824', 'Alessandra Braga', 'Franco Alameda, 36223, undefined Benício do Descoberto, BA',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('94811795873', '247571887192', 'Ana Clara Costa', 'Silva Rodovia, 50656, Suélen do Norte, AL',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('29039845638', '468980676284', 'Alícia Silva', 'Isabella Alameda, 7410, San Francisco, RR',
        'superior completo');
INSERT INTO Pessoa
VALUES ('21081520980', '375388275063', 'Yango Melo', 'Dalila Marginal, 78805, undefined Yango, PI',
        'mestrado');
INSERT INTO Pessoa
VALUES ('56604801905', '432443624874', 'Yango Moraes', 'Carvalho Alameda, 93254, Braga do Norte, PE',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('42220121475', '464791006711', 'Natália Braga', 'Vitória Marginal, 73272, undefined Eduardo, MT',
        'doutorado');
INSERT INTO Pessoa
VALUES ('81989843735', '699061163840', 'Gustavo Albuquerque', 'Alessandro Avenida, 52923, Rebeca de Nossa Senhora, BA',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('78830082472', '211194392223', 'Matheus Braga', 'Nogueira Alameda, 12799, Lodi, AL',
        'doutorado');
INSERT INTO Pessoa
VALUES ('54207576885', '798610570654', 'Giovanna Batista', 'Alexandre Marginal, 8277, undefined Beatriz, SP',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('85655194001', '568900867481', 'Murilo Carvalho', 'Pereira Rodovia, 18838, undefined Danilo, DF',
        'doutorado');
INSERT INTO Pessoa
VALUES ('49630068878', '136472428194', 'Ana Luiza Costa', 'Albuquerque Rua, 81256, Irvine, SP',
        'mestrado');
INSERT INTO Pessoa
VALUES ('68224937592', '920794915966', 'Pietro Moreira', 'Franco Rodovia, 73313, Eduardo do Descoberto, PE',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('47086909811', '568541328888', 'Ofélia Moreira', 'Silva Alameda, 54984, Washington do Norte, AC',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('74884315195', '327536032604', 'Roberta Costa', 'Janaína Alameda, 23066, undefined Margarida do Norte, PE',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('29093351392', '220708971936', 'Fábio Batista', 'Lara Marginal, 55410, Nampa, MG',
        'superior completo');
INSERT INTO Pessoa
VALUES ('23413005832', '111507763387', 'Salvador Souza', 'Oliveira Marginal, 31243, Fayetteville, RR',
        'superior completo');
INSERT INTO Pessoa
VALUES ('32085399280', '977181948767', 'Gustavo Nogueira', 'Macedo Travessa, 14284, undefined Antonella de Nossa Senhora, ES',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('10664018120', '306083822762', 'Júlio Reis', 'Moreira Rodovia, 55934, Mércia do Norte, PB',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('52857200317', '190229828096', 'Ana Laura Reis', 'Martins Rodovia, 16775, undefined Yango, RN',
        'doutorado');
INSERT INTO Pessoa
VALUES ('78677525506', '645063394843', 'Rafaela Nogueira', 'Júlia Rodovia, 84967, Pocatello, AM',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('15462815286', '506882930803', 'Nataniel Braga', 'Souza Rua, 81856, Idaho Falls, RJ',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('98036668179', '722913383087', 'João Reis', 'Braga Travessa, 60083, Santos do Sul, SC',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('63327833798', '758845261926', 'Isaac Costa', 'Carvalho Travessa, 96670, Rock Hill, BA',
        'superior completo');
INSERT INTO Pessoa
VALUES ('94223495926', '925178597681', 'Esther Santos', 'Saraiva Marginal, 51776, undefined Carlos, AC',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('60043165707', '105359510635', 'Fabiano Saraiva', 'Oliveira Marginal, 539, undefined Carla do Descoberto, SE',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('40370402915', '973210544162', 'Elisa Martins', 'Santos Alameda, 98440, Carvalho de Nossa Senhora, PR',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('90524761965', '487560508493', 'Márcia Franco', 'Franco Alameda, 91057, undefined Maria Helena do Norte, AM',
        'mestrado');
INSERT INTO Pessoa
VALUES ('17017262971', '898335546907', 'João Miguel Saraiva', 'Feliciano Avenida, 44278, Kenosha, PI',
        'doutorado');
INSERT INTO Pessoa
VALUES ('86249082582', '580723287514', 'Isabella Nogueira', 'Moraes Avenida, 14935, undefined Karla, PB',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('66609882188', '632656720117', 'Théo Carvalho', 'Franco Marginal, 10544, Mission, AP',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('85294869835', '332856849441', 'Núbia Moraes', 'Pablo Travessa, 85706, Moraes do Descoberto, PE',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('67193564104', '251017880160', 'Heloísa Carvalho', 'Carvalho Alameda, 56183, Gaithersburg, MT',
        'superior completo');
INSERT INTO Pessoa
VALUES ('82545323397', '328505115769', 'Silas Xavier', 'Moraes Alameda, 58162, undefined Maria do Descoberto, AC',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('51658055912', '635883447946', 'Célia Saraiva', 'Murilo Rua, 79813, Isabel do Norte, SP',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('83294698440', '657986815785', 'Alessandro Oliveira', 'Antônio Rua, 62175, Carla do Descoberto, PA',
        'doutorado');
INSERT INTO Pessoa
VALUES ('60372715506', '635436397674', 'Manuela Franco', 'Sophia Marginal, 40175, undefined Beatriz, RJ',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('40021847444', '330397395789', 'Mércia Carvalho', 'Macedo Rodovia, 1129, Silva do Descoberto, PA',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('45378367919', '796638155030', 'Gabriel Xavier', 'Albuquerque Rodovia, 31232, undefined Cecília do Norte, MS',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('71359896301', '416386977490', 'Ricardo Carvalho', 'Yasmin Avenida, 43931, Maria Alice do Descoberto, TO',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('89658641323', '717610051529', 'Enzo Souza', 'Macedo Alameda, 97366, Hugo do Descoberto, PE',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('76178380483', '798312551458', 'Karla Reis', 'Carvalho Rua, 32488, undefined Benjamin do Descoberto, AP',
        'superior completo');
INSERT INTO Pessoa
VALUES ('34952035478', '781129602598', 'Matheus Xavier', 'Silva Rua, 63366, Nogueira do Descoberto, RR',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('65191834932', '311254554917', 'Miguel Albuquerque', 'Batista Rua, 82972, Casa Grande, RN',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('55553544007', '250320735271', 'Théo Albuquerque', 'Moraes Avenida, 98656, Pereira do Descoberto, RJ',
        'mestrado');
INSERT INTO Pessoa
VALUES ('49993791026', '639149322197', 'Rebeca Saraiva', 'Oliveira Marginal, 53321, Carlos do Descoberto, AC',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('83635655883', '487381947552', 'Yuri Melo', 'Norberto Avenida, 62776, Strongsville, SC',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('61191493880', '429678236367', 'Bernardo Carvalho', 'Matheus Rodovia, 65264, Maria Cecília do Sul, PA',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('82742590734', '680602759844', 'Liz Silva', 'Batista Rodovia, 16293, Silva de Nossa Senhora, DF',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('19629932825', '330768083571', 'Rafael Oliveira', 'Elisa Travessa, 52514, Pereira do Norte, CE',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('35363002663', '681717395177', 'Félix Nogueira', 'João Lucas Marginal, 87971, undefined Dalila do Norte, SC',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('26209410189', '329793186509', 'Benjamin Silva', 'Melissa Alameda, 22323, Manuela de Nossa Senhora, PA',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('41108251772', '941292527201', 'Warley Carvalho', 'Costa Rodovia, 65609, Apopka, PA',
        'superior completo');
INSERT INTO Pessoa
VALUES ('63419523332', '630687513086', 'Dalila Oliveira', 'Célia Rodovia, 75383, undefined Marcos, RN',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('68443179363', '158731657522', 'Lucas Reis', 'Albuquerque Rua, 53112, Moraes do Sul, RN',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('73565084710', '371313276002', 'Maria Alice Braga', 'João Miguel Marginal, 74895, Carvalho do Sul, MS',
        'mestrado');
INSERT INTO Pessoa
VALUES ('66659215325', '198449039575', 'Raul Melo', 'Silva Marginal, 70023, undefined Maria Cecília, GO',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('74298426869', '386537090991', 'Joana Carvalho', 'Breno Alameda, 87459, undefined Isaac, BA',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('33666146213', '700130857294', 'Yuri Souza', 'Larissa Rua, 344, Fort Smith, CE',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('52057552337', '583357403683', 'Davi Lucca Carvalho', 'Ladislau Alameda, 54000, Milwaukee, RO',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('83335207737', '723461798648', 'Pablo Batista', 'Núbia Avenida, 6964, Batista de Nossa Senhora, MA',
        'superior completo');
INSERT INTO Pessoa
VALUES ('71078690302', '663019261416', 'Deneval Oliveira', 'Sophia Travessa, 22214, undefined Maria Eduarda de Nossa Senhora, PB',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('66041600762', '291094248648', 'Heloísa Batista', 'Gustavo Avenida, 66150, Félix do Norte, SP',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('27514509037', '483389301947', 'Nataniel Costa', 'Hélio Travessa, 5086, Silva de Nossa Senhora, AL',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('48407140278', '900434329151', 'Ladislau Macedo', 'Sophia Rua, 70134, Carla do Sul, DF',
        'mestrado');
INSERT INTO Pessoa
VALUES ('27104304458', '796552803786', 'Gael Oliveira', 'Carvalho Rodovia, 85926, undefined Yango do Norte, SP',
        'doutorado');
INSERT INTO Pessoa
VALUES ('40367657486', '565406741015', 'Raul Carvalho', 'Lucca Avenida, 43125, Isabella do Sul, AM',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('90374537745', '827113076276', 'Maria Júlia Moreira', 'Moraes Travessa, 96584, undefined Isis, PA',
        'superior completo');
INSERT INTO Pessoa
VALUES ('99031375555', '628921124013', 'Vitor Carvalho', 'Raul Alameda, 55584, Leonardo do Descoberto, RN',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('49451829111', '580273130070', 'Calebe Carvalho', 'Nogueira Avenida, 34287, Columbia, BA',
        'superior completo');
INSERT INTO Pessoa
VALUES ('51375660479', '901280755735', 'Maria Helena Xavier', 'Costa Rua, 76067, undefined Yango, SC',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('85722795790', '661194893252', 'Giovanna Xavier', 'Norberto Rua, 32174, undefined Ígor do Descoberto, PB',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('89286399788', '165592540102', 'Pedro Henrique Macedo', 'Pedro Alameda, 26245, Daniel do Norte, PA',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('81112522231', '215519677847', 'César Franco', 'Pereira Marginal, 33205, Trenton, GO',
        'doutorado');
INSERT INTO Pessoa
VALUES ('25947751102', '848186186258', 'Esther Carvalho', 'Pietro Rua, 67882, undefined Eduarda do Sul, MT',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('16519870674', '261832868983', 'Fabrícia Martins', 'Macedo Rodovia, 32477, Franco do Sul, SE',
        'superior completo');
INSERT INTO Pessoa
VALUES ('19179157342', '711170138092', 'Maria Luiza Carvalho', 'Deneval Avenida, 55386, Santos do Norte, RN',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('69290820988', '421290836972', 'Théo Macedo', 'Margarida Rodovia, 86070, Nogueira do Norte, RS',
        'superior completo');
INSERT INTO Pessoa
VALUES ('33110790541', '432181846513', 'Joana Moreira', 'Eduarda Alameda, 40174, Raul do Norte, PB',
        'doutorado');
INSERT INTO Pessoa
VALUES ('44484618890', '411453234637', 'Vitória Xavier', 'Silva Rodovia, 77922, Rochester, MT',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('11737644865', '537476279539', 'Sophia Xavier', 'Hélio Avenida, 73947, Sugar Land, PA',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('33670471631', '139535111072', 'Maria Clara Santos', 'Eduardo Rodovia, 5894, undefined Isabelly do Descoberto, TO',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('33855325537', '948006682679', 'Sarah Braga', 'Barros Rodovia, 22847, Silva do Descoberto, RR',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('69146417120', '690909739118', 'Gustavo Moreira', 'Nogueira Marginal, 22292, Santos do Sul, RR',
        'superior completo');
INSERT INTO Pessoa
VALUES ('55165247858', '490035330783', 'Davi Pereira', 'Maria Cecília Marginal, 52105, Davi Lucca do Descoberto, PR',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('43832994084', '772841843077', 'Isis Reis', 'Clara Rodovia, 64378, undefined Vitória do Sul, RN',
        'superior completo');
INSERT INTO Pessoa
VALUES ('16893356314', '219683719333', 'Ofélia Souza', 'Nataniel Marginal, 83988, undefined João Pedro de Nossa Senhora, BA',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('75745057673', '722220015921', 'Yango Macedo', 'Pedro Alameda, 90938, undefined Aline, RN',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('79857502803', '859558885334', 'Théo Xavier', 'Calebe Rua, 9520, Núbia de Nossa Senhora, SC',
        'superior completo');
INSERT INTO Pessoa
VALUES ('81840145753', '982039980613', 'Larissa Xavier', 'Souza Rodovia, 97809, undefined Alexandre, AC',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('68579267167', '977177686570', 'Arthur Braga', 'Martins Rua, 68970, undefined Maria Luiza do Descoberto, SE',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('89233355857', '359994424576', 'Enzo Gabriel Oliveira', 'Saraiva Marginal, 25759, undefined Daniel do Norte, RR',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('29005892204', '276560967951', 'Marina Moreira', 'Albuquerque Travessa, 55136, Milwaukee, PR',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('40928985222', '693064415664', 'Maria Eduarda Carvalho', 'Washington Travessa, 56600, Lucca do Descoberto, AC',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('10546498305', '147447817097', 'Pietro Nogueira', 'Pereira Travessa, 87084, Pereira de Nossa Senhora, BA',
        'doutorado');
INSERT INTO Pessoa
VALUES ('84247250689', '727050756709', 'Maitê Souza', 'Barros Travessa, 59564, Macedo do Sul, MT',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('24746668823', '628640108974', 'Eduardo Reis', 'Braga Rua, 99598, Nogueira de Nossa Senhora, ES',
        'doutorado');
INSERT INTO Pessoa
VALUES ('31080767794', '387358627305', 'Marli Silva', 'Oliveira Alameda, 37732, undefined Enzo, PE',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('96609805801', '233931412873', 'Lorena Macedo', 'Salvador Travessa, 66238, Saraiva do Descoberto, SP',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('48819631503', '628216629661', 'Anthony Moreira', 'Felipe Rodovia, 53755, Plainfield, SP',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('29895040113', '592087956517', 'Cauã Reis', 'Moreira Alameda, 89171, Santa Cruz, DF',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('31726471120', '697149460227', 'Guilherme Souza', 'Batista Travessa, 28929, undefined Víctor, RN',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('56392738602', '167447934928', 'Suélen Pereira', 'Carvalho Rodovia, 81191, undefined Alícia do Norte, PI',
        'mestrado');
INSERT INTO Pessoa
VALUES ('88774482219', '665373858506', 'Maria Xavier', 'Noah Marginal, 54685, Paula do Norte, MA',
        'doutorado');
INSERT INTO Pessoa
VALUES ('79239115805', '766483103344', 'Raul Melo', 'Isaac Alameda, 27381, undefined Anthony, RN',
        'superior completo');
INSERT INTO Pessoa
VALUES ('53324051348', '127092406945', 'Lucca Carvalho', 'Margarida Marginal, 31886, Waukegan, MG',
        'superior completo');
INSERT INTO Pessoa
VALUES ('20926508598', '315515260281', 'Cecília Moraes', 'Costa Rua, 89169, Reis do Norte, SE',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('67352445363', '831929856794', 'Marcela Xavier', 'Frederico Rodovia, 82944, undefined Vicente de Nossa Senhora, SP',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('18233533741', '323231924278', 'Talita Costa', 'Kléber Rodovia, 38380, Carvalho do Sul, GO',
        'superior completo');
INSERT INTO Pessoa
VALUES ('26254597574', '770249247085', 'Maitê Batista', 'Maria Cecília Marginal, 52522, Beaumont, PA',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('91040847708', '202507496112', 'Sophia Moraes', 'Roberto Avenida, 21010, undefined Samuel, MG',
        'superior completo');
INSERT INTO Pessoa
VALUES ('37769212496', '283952246047', 'Roberta Martins', 'Albuquerque Avenida, 95270, undefined Júlio César do Sul, TO',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('86949663003', '407179147982', 'Margarida Santos', 'Saraiva Rodovia, 64276, undefined Júlio César de Nossa Senhora, AM',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('32414304846', '226003312645', 'Silas Melo', 'Reis Travessa, 49455, Bradenton, RR',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('89778357343', '729734449111', 'Carlos Costa', 'Carvalho Travessa, 96623, Martins do Descoberto, TO',
        'superior completo');
INSERT INTO Pessoa
VALUES ('21310869527', '191178428614', 'Fabrício Barros', 'César Travessa, 71883, undefined Warley, PR',
        'superior completo');
INSERT INTO Pessoa
VALUES ('80856457897', '584128614421', 'Núbia Martins', 'Saraiva Rua, 35335, undefined Larissa de Nossa Senhora, GO',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('38336047478', '843229150306', 'Lucas Braga', 'Batista Alameda, 83038, Taylorsville, RR',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('56577562082', '411624023038', 'Suélen Franco', 'Xavier Alameda, 93329, undefined Maria Júlia, RR',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('93827489160', '366245687357', 'Hélio Franco', 'Costa Rua, 77237, Antonella do Norte, MA',
        'mestrado');
INSERT INTO Pessoa
VALUES ('27882795822', '839530465169', 'Arthur Xavier', 'Maria Travessa, 57366, Reis do Norte, AP',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('60364329223', '277860867651', 'Júlia Souza', 'Murilo Alameda, 741, undefined Larissa de Nossa Senhora, SP',
        'mestrado');
INSERT INTO Pessoa
VALUES ('48624392356', '772431478300', 'João Miguel Costa', 'Batista Avenida, 92677, Bryan do Sul, AC',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('73277497400', '834017219743', 'Paulo Xavier', 'Norberto Avenida, 3684, Reis do Descoberto, MA',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('89938825150', '208240242418', 'Isadora Franco', 'Eduardo Travessa, 21226, undefined Aline de Nossa Senhora, BA',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('34774391916', '391976398392', 'Salvador Santos', 'Carvalho Marginal, 7965, undefined Washington, PA',
        'doutorado');
INSERT INTO Pessoa
VALUES ('88995994818', '578821368305', 'Silas Nogueira', 'Carvalho Avenida, 75321, Rancho Cucamonga, ES',
        'superior completo');
INSERT INTO Pessoa
VALUES ('82117342813', '819286428717', 'Pablo Oliveira', 'Xavier Rua, 92644, Célia do Sul, ES',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('59180864153', '791574059543', 'Antônio Moreira', 'Márcia Travessa, 24808, undefined Miguel do Norte, AP',
        'doutorado');
INSERT INTO Pessoa
VALUES ('26629737697', '349652652861', 'Natália Melo', 'Pereira Rodovia, 29585, Batista do Sul, SC',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('67794386299', '261940290196', 'Isis Silva', 'Pereira Rua, 92120, undefined Miguel, MG',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('86363215206', '850224260683', 'Ana Luiza Costa', 'Carlos Avenida, 46844, Pereira do Descoberto, SE',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('53966798104', '611501176632', 'Isis Macedo', 'Silva Avenida, 86492, Ana Júlia do Norte, RR',
        'superior completo');
INSERT INTO Pessoa
VALUES ('37764165711', '504137871344', 'Heitor Melo', 'Franco Marginal, 12708, undefined Natália, GO',
        'mestrado');
INSERT INTO Pessoa
VALUES ('62152035068', '683210698701', 'Helena Martins', 'Souza Rodovia, 6394, undefined Isabelly, PE',
        'mestrado');
INSERT INTO Pessoa
VALUES ('85452085987', '677602189593', 'Bruna Carvalho', 'Xavier Marginal, 82650, Roberto de Nossa Senhora, AP',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('21959062153', '232500803051', 'Felícia Nogueira', 'Júlio César Travessa, 701, Pensacola, PR',
        'mestrado');
INSERT INTO Pessoa
VALUES ('27274558073', '324548367341', 'Lorenzo Nogueira', 'Nicolas Travessa, 50489, undefined Antônio do Sul, RN',
        'doutorado');
INSERT INTO Pessoa
VALUES ('43961375064', '261238077608', 'Melissa Nogueira', 'Santos Travessa, 67751, undefined Daniel, DF',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('60892811592', '575512644927', 'Hugo Oliveira', 'Santos Avenida, 9777, undefined Henrique, BA',
        'superior completo');
INSERT INTO Pessoa
VALUES ('34806180221', '524656667839', 'Isaac Reis', 'Maria Travessa, 88789, Roberta do Norte, DF',
        'superior completo');
INSERT INTO Pessoa
VALUES ('84743212782', '199144073063', 'Henrique Moraes', 'Martins Rodovia, 19062, Heitor do Sul, RS',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('30275409643', '467497997661', 'Beatriz Macedo', 'Martins Avenida, 77969, undefined Margarida, MA',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('57082543941', '978565692645', 'Talita Silva', 'Valentina Alameda, 4172, Newark, PB',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('47322499984', '825858046999', 'Ana Luiza Pereira', 'Santos Marginal, 44433, undefined Antonella do Sul, SP',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('83672753747', '701374655240', 'Maitê Moraes', 'Albuquerque Rua, 5690, Pereira do Descoberto, DF',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('71797774885', '731576293124', 'Valentina Costa', 'Pietro Travessa, 93496, Macedo de Nossa Senhora, RO',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('15426200556', '507426011702', 'Lavínia Nogueira', 'Moreira Rua, 85793, undefined Lavínia do Descoberto, PR',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('77959251704', '413134684436', 'Larissa Martins', 'Oliveira Avenida, 4305, undefined Ana Luiza, SE',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('97253314054', '798787398217', 'Laura Saraiva', 'Pereira Travessa, 68887, undefined Ladislau, RS',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('99047559711', '776472441805', 'Luiza Barros', 'Saraiva Rua, 79172, Palm Bay, MA',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('18723273822', '103989965072', 'Silas Nogueira', 'Nataniel Avenida, 16452, undefined Maitê do Sul, PR',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('30731319272', '793733645160', 'Meire Braga', 'Carla Avenida, 19649, Henrique de Nossa Senhora, MG',
        'mestrado');
INSERT INTO Pessoa
VALUES ('64004827691', '483809066819', 'Márcia Pereira', 'Barros Alameda, 54227, Saraiva do Norte, SE',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('69911227060', '520304542523', 'Maria Helena Souza', 'Ricardo Alameda, 29030, Felipe do Sul, PR',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('64312151931', '886260272306', 'Maria Eduarda Silva', 'Barros Rodovia, 90510, undefined Cauã de Nossa Senhora, RR',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('32206475872', '327179087162', 'Antônio Braga', 'Liz Rua, 34560, Lancaster, PI',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('78521770969', '323765499261', 'João Miguel Saraiva', 'Ana Luiza Avenida, 19645, undefined Heitor do Sul, PI',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('19451177760', '560795879759', 'Sophia Albuquerque', 'Reis Alameda, 42982, Washington do Descoberto, PA',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('79631428855', '455285778688', 'Anthony Costa', 'Franco Marginal, 79334, Carvalho do Sul, DF',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('14901188861', '257179567217', 'Aline Santos', 'Ana Laura Avenida, 69513, Xavier do Sul, SE',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('35566097435', '328700049081', 'Miguel Macedo', 'Silva Travessa, 31821, Maria Júlia do Norte, CE',
        'doutorado');
INSERT INTO Pessoa
VALUES ('44852999553', '914703350863', 'Cecília Carvalho', 'Ofélia Travessa, 22259, Valentina do Sul, SP',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('99875636277', '195001290598', 'Ana Júlia Costa', 'Eduardo Avenida, 74315, undefined Fabrícia do Norte, MA',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('50616122588', '620294854207', 'Marcos Barros', 'Braga Marginal, 97869, undefined Eduardo do Norte, ES',
        'doutorado');
INSERT INTO Pessoa
VALUES ('26146796492', '179002038715', 'Guilherme Franco', 'Deneval Rua, 94774, undefined Hugo do Sul, SP',
        'superior completo');
INSERT INTO Pessoa
VALUES ('12614989210', '644573237490', 'Leonardo Martins', 'Maria Avenida, 10673, Leesburg, SP',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('14428552011', '362313818302', 'Karla Albuquerque', 'Maria Júlia Avenida, 66212, Compton, PB',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('29731390641', '953325591585', 'Clara Xavier', 'Davi Lucca Alameda, 3274, Vallejo, ES',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('21995127492', '202840886311', 'Sílvia Barros', 'Nogueira Marginal, 69836, undefined Pedro Henrique, PA',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('89964209555', '753776895860', 'Bryan Souza', 'Arthur Travessa, 72705, Mércia do Norte, DF',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('12976033654', '772715508937', 'Danilo Carvalho', 'Maria Júlia Avenida, 37585, Paula do Sul, AP',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('48658048233', '139271742035', 'Antonella Macedo', 'Vitória Rua, 36389, undefined Pietro, SC',
        'doutorado');
INSERT INTO Pessoa
VALUES ('56632317912', '559495889535', 'Roberto Martins', 'Kléber Alameda, 12413, undefined Ana Júlia, MA',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('84994391954', '965169551642', 'Nicolas Oliveira', 'Júlio César Rodovia, 78419, undefined Natália de Nossa Senhora, PA',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('56392080958', '460457281349', 'Helena Carvalho', 'Moreira Marginal, 74465, undefined Margarida do Sul, RR',
        'superior completo');
INSERT INTO Pessoa
VALUES ('12408964524', '690097846603', 'Esther Batista', 'Rafael Alameda, 57608, Melo de Nossa Senhora, MG',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('52924657328', '701806949591', 'Alice Martins', 'Isaac Alameda, 34925, Chattanooga, AP',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('30491285622', '945884289452', 'João Miguel Martins', 'Pereira Marginal, 158, Brockton, AP',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('85759488451', '777813695720', 'Melissa Souza', 'Helena Alameda, 652, Albuquerque do Norte, BA',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('59100339210', '342984281852', 'Heloísa Barros', 'Maria Eduarda Rodovia, 91052, Lavínia do Norte, ES',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('78540902768', '830330282263', 'Fabiano Costa', 'Sara Travessa, 81184, Guilherme do Descoberto, PB',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('36323933107', '993116094218', 'Maria Melo', 'Nogueira Travessa, 25338, Lehi, RS',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('48617187398', '546399670839', 'Talita Barros', 'Costa Rua, 82230, undefined Esther, PR',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('39909716104', '327462154719', 'Enzo Gabriel Reis', 'Carvalho Rodovia, 54973, Pereira do Descoberto, SE',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('69257088878', '313949216506', 'Sílvia Silva', 'Isabelly Rodovia, 53856, Carvalho do Sul, GO',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('28251362228', '211225145217', 'Calebe Nogueira', 'Bryan Travessa, 37707, Danilo do Sul, BA',
        'superior completo');
INSERT INTO Pessoa
VALUES ('11214965519', '833026305702', 'Alícia Nogueira', 'Xavier Rua, 24432, Bismarck, PB',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('44080556528', '825881947786', 'Lorenzo Macedo', 'Marcos Avenida, 17417, undefined Yago do Sul, SE',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('76986037665', '530709020094', 'Rafaela Barros', 'Silas Marginal, 13339, undefined Alícia do Descoberto, CE',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('48564919442', '630648789741', 'Núbia Carvalho', 'Nicolas Travessa, 29171, Shoreline, SP',
        'superior completo');
INSERT INTO Pessoa
VALUES ('88126655463', '731242066621', 'Warley Martins', 'Felipe Marginal, 6830, Souza de Nossa Senhora, SC',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('82448269089', '830052503058', 'Sílvia Franco', 'Barros Alameda, 9938, Giovanna do Sul, RJ',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('68663108202', '854070117999', 'Rafael Pereira', 'Saraiva Rodovia, 4756, undefined Eduardo, PI',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('33251189284', '437281443341', 'Kléber Barros', 'Macedo Rodovia, 92728, New Orleans, RJ',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('70054730942', '239460215531', 'Roberto Carvalho', 'Braga Marginal, 59452, Braga de Nossa Senhora, RN',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('85698530410', '575016880710', 'Alessandro Braga', 'Reis Rua, 93358, Macedo do Sul, PB',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('75949794522', '104720394499', 'Alexandre Moreira', 'Xavier Alameda, 23432, undefined Isis de Nossa Senhora, AC',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('88159796837', '624593915999', 'Bryan Braga', 'Albuquerque Alameda, 89024, Cathedral City, AC',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('80639247749', '376945742894', 'Melissa Pereira', 'Alice Travessa, 5514, Melo de Nossa Senhora, AC',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('24439672860', '665107890870', 'Breno Carvalho', 'Barros Avenida, 64923, Macedo do Descoberto, PR',
        'mestrado');
INSERT INTO Pessoa
VALUES ('17678079477', '573726312164', 'Raul Saraiva', 'Maitê Alameda, 49501, Fayetteville, RS',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('42253852223', '295938808261', 'Célia Barros', 'Braga Marginal, 67829, undefined Calebe, MG',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('94970913690', '265125025529', 'Marcela Franco', 'Talita Rua, 39952, undefined Júlia do Sul, AM',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('44154843701', '357509144814', 'Bryan Pereira', 'Xavier Marginal, 57199, Macedo de Nossa Senhora, RS',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('62563421055', '783649988495', 'Enzo Oliveira', 'Barros Travessa, 50183, undefined César de Nossa Senhora, PB',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('54988852173', '293184019299', 'Vitor Santos', 'Silva Rua, 2277, undefined Eloá do Sul, MA',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('11802864642', '332221916085', 'Davi Lucca Nogueira', 'Felipe Avenida, 87285, undefined Hugo do Norte, PE',
        'doutorado');
INSERT INTO Pessoa
VALUES ('94071586923', '696264987136', 'Núbia Albuquerque', 'Moraes Marginal, 46470, Théo do Norte, RN',
        'mestrado');
INSERT INTO Pessoa
VALUES ('33861935359', '782067003636', 'Sarah Melo', 'Felipe Rua, 11562, undefined Joana, PA',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('71791716990', '904385082842', 'Lorena Nogueira', 'Barros Avenida, 11232, undefined Marcelo, RO',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('35354715120', '232858162769', 'Elisa Carvalho', 'Barros Marginal, 7062, Huntersville, CE',
        'doutorado');
INSERT INTO Pessoa
VALUES ('62330017092', '982704859785', 'Breno Santos', 'Pereira Travessa, 94406, Coral Gables, PR',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('54613564885', '589589171204', 'Ofélia Macedo', 'Fábio Avenida, 15264, Vitória do Norte, SC',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('51161424755', '404187487275', 'Bryan Saraiva', 'Fabrício Marginal, 79513, undefined Henrique, PB',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('78797397429', '237012825533', 'Heitor Carvalho', 'Franco Alameda, 81096, undefined Bruna, SE',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('13112014401', '327856493298', 'Maria Eduarda Nogueira', 'Antonella Rua, 46465, Murilo do Norte, TO',
        'superior completo');
INSERT INTO Pessoa
VALUES ('80311061413', '169972374942', 'Norberto Nogueira', 'Félix Rodovia, 11181, Martins de Nossa Senhora, RS',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('64878309026', '304046531836', 'Alice Carvalho', 'Sirineu Rua, 19426, Emanuel do Norte, AC',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('86797248676', '799957628827', 'Kléber Reis', 'Morgana Marginal, 12242, Marcelo do Sul, PA',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('59327314610', '794616850488', 'Enzo Gabriel Silva', 'Matheus Rodovia, 64194, Tucson, PI',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('60984027946', '489621326583', 'João Pedro Franco', 'Albuquerque Alameda, 76302, Guilherme de Nossa Senhora, RO',
        'mestrado');
INSERT INTO Pessoa
VALUES ('59381403052', '150351706286', 'Fabiano Moraes', 'Enzo Gabriel Marginal, 56260, undefined Eloá, SE',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('77009138378', '480289500439', 'Eduarda Melo', 'Washington Rodovia, 19269, Souza do Norte, PE',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('99410824584', '819499017042', 'Heitor Silva', 'Marcela Avenida, 56736, Titusville, TO',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('60122351620', '592445819359', 'Bruna Albuquerque', 'Silas Rodovia, 82380, Oliveira de Nossa Senhora, PB',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('49541541982', '156495970091', 'João Miguel Carvalho', 'Santos Alameda, 57165, Moreira do Sul, SE',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('50722760849', '370988990855', 'Núbia Batista', 'Melo Rodovia, 67437, Bentonville, PA',
        'doutorado');
INSERT INTO Pessoa
VALUES ('97856096168', '474490340123', 'Sophia Pereira', 'Talita Rua, 77090, Tuscaloosa, PB',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('31951113061', '602053334889', 'Calebe Barros', 'Deneval Rua, 11483, Fabiano do Sul, PB',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('22216452944', '622805434744', 'João Pedro Albuquerque', 'Santos Rua, 63398, Midland, SC',
        'mestrado');
INSERT INTO Pessoa
VALUES ('89395024664', '947881267196', 'Nataniel Oliveira', 'Maria Eduarda Avenida, 53033, Silva do Norte, PB',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('79310353223', '224228942114', 'Yago Souza', 'Xavier Travessa, 42229, undefined Isis, SP',
        'doutorado');
INSERT INTO Pessoa
VALUES ('32050464514', '679090681276', 'Eloá Braga', 'Barros Rodovia, 74558, undefined Isabella do Norte, BA',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('15456776062', '501590600702', 'Heloísa Carvalho', 'Martins Alameda, 1032, Célia do Norte, TO',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('36680386532', '848186174524', 'Lavínia Nogueira', 'Margarida Marginal, 58923, Deerfield Beach, DF',
        'superior completo');
INSERT INTO Pessoa
VALUES ('88249640718', '813155300612', 'Ricardo Carvalho', 'Ana Laura Rua, 9210, undefined Natália do Norte, PA',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('20534925025', '568112318357', 'Isabela Martins', 'Franco Travessa, 14356, Fontana, PR',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('62644287729', '458317964011', 'Lorenzo Braga', 'Saraiva Marginal, 75894, Oliveira de Nossa Senhora, PA',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('93245290170', '804248700360', 'Maria Clara Saraiva', 'Silva Marginal, 52436, Ana Clara de Nossa Senhora, PR',
        'superior completo');
INSERT INTO Pessoa
VALUES ('27684655510', '252767471061', 'Gustavo Saraiva', 'Carvalho Travessa, 22583, Maria Clara do Descoberto, MS',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('42586692003', '492416249355', 'César Reis', 'Ofélia Alameda, 35114, Carvalho do Norte, TO',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('11719256164', '728518400085', 'Elísio Reis', 'Carvalho Marginal, 78797, Burbank, ES',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('96970153856', '315203854558', 'Maria Clara Xavier', 'Saraiva Rodovia, 61731, Rockford, PI',
        'superior completo');
INSERT INTO Pessoa
VALUES ('18720562611', '888603799208', 'Clara Carvalho', 'Kléber Alameda, 47681, undefined Calebe do Descoberto, CE',
        'superior completo');
INSERT INTO Pessoa
VALUES ('18437136497', '949555593007', 'Janaína Martins', 'Enzo Travessa, 29974, undefined Dalila, PA',
        'mestrado');
INSERT INTO Pessoa
VALUES ('89653281683', '860269596753', 'Félix Moreira', 'Carvalho Travessa, 43135, undefined Júlio César, PI',
        'superior completo');
INSERT INTO Pessoa
VALUES ('53065562297', '557366025098', 'Felipe Melo', 'Carla Travessa, 94848, undefined Júlia do Norte, AL',
        'doutorado');
INSERT INTO Pessoa
VALUES ('61652706887', '237072154320', 'Eduardo Macedo', 'Isabel Rodovia, 95123, Bradenton, RS',
        'mestrado');
INSERT INTO Pessoa
VALUES ('71713129335', '953581660822', 'Nicolas Saraiva', 'Oliveira Travessa, 93361, Lewisville, MT',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('23369654125', '273972729919', 'Cauã Moreira', 'Feliciano Rua, 90482, Breno de Nossa Senhora, RO',
        'doutorado');
INSERT INTO Pessoa
VALUES ('14430595960', '546785172168', 'Elísio Carvalho', 'Saraiva Marginal, 99834, Beaverton, PA',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('74553356398', '186750088748', 'Enzo Gabriel Reis', 'Deneval Avenida, 14474, North Port, ES',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('92975085964', '252472741762', 'Lívia Melo', 'Costa Rodovia, 58609, undefined Norberto, RJ',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('20150466552', '888884837087', 'Marina Silva', 'Rafael Marginal, 38645, undefined Sílvia do Norte, RN',
        'mestrado');
INSERT INTO Pessoa
VALUES ('45290986180', '339810662390', 'Maria Reis', 'Pereira Alameda, 96266, Ponce, SC',
        'mestrado');
INSERT INTO Pessoa
VALUES ('44945997984', '100643211323', 'Núbia Silva', 'Nogueira Rua, 83684, undefined Salvador, MS',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('16535910640', '182070437422', 'Leonardo Macedo', 'Elísio Travessa, 65313, Felipe do Norte, MT',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('67729153551', '541442675539', 'Anthony Costa', 'Souza Rua, 16183, Odessa, AP',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('13249461750', '797936202539', 'Carlos Franco', 'João Pedro Alameda, 85510, undefined Salvador, RS',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('34295891087', '539615798462', 'Elísio Macedo', 'Cecília Marginal, 13043, Melo do Sul, RJ',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('44441414789', '989235347439', 'Pedro Henrique Barros', 'Bernardo Marginal, 70657, undefined Emanuelly, PA',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('28806930759', '944541216874', 'Alessandro Nogueira', 'Xavier Avenida, 35344, Carvalho do Sul, PE',
        'mestrado');
INSERT INTO Pessoa
VALUES ('98651677060', '233917805482', 'Isabel Barros', 'Moraes Travessa, 43535, undefined Lavínia do Norte, TO',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('84577393592', '855021117208', 'Célia Moraes', 'João Lucas Marginal, 18801, undefined Fábio do Norte, RJ',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('77440287217', '973605455853', 'Raul Martins', 'Costa Rodovia, 44931, Pedro do Norte, MA',
        'superior completo');
INSERT INTO Pessoa
VALUES ('54570902423', '666748452279', 'Pablo Santos', 'Costa Marginal, 22877, Paulo do Descoberto, BA',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('31258916617', '548528149537', 'Lara Moraes', 'Moreira Travessa, 87987, Yago de Nossa Senhora, RR',
        'doutorado');
INSERT INTO Pessoa
VALUES ('52020327886', '335783254727', 'Sophia Carvalho', 'Albuquerque Avenida, 96820, Ana Clara do Norte, SC',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('81856962239', '578752364288', 'Hugo Reis', 'Costa Alameda, 88690, Jacksonville, SE',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('56274953270', '904066237760', 'Karla Carvalho', 'Martins Rua, 89848, undefined Danilo do Sul, AL',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('86574679580', '241046079155', 'Marcela Moreira', 'Pereira Alameda, 9371, Hélio do Descoberto, RN',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('70917615771', '183979776292', 'Núbia Costa', 'Santos Travessa, 64885, undefined Maria Júlia de Nossa Senhora, RJ',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('11856616593', '497544858884', 'Roberto Saraiva', 'César Rodovia, 38326, undefined Sophia, MS',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('96993769449', '978459963528', 'Margarida Reis', 'Gabriel Rua, 25269, undefined Aline do Sul, MA',
        'mestrado');
INSERT INTO Pessoa
VALUES ('79759818490', '175821108766', 'Rebeca Batista', 'Silva Alameda, 98636, Xavier de Nossa Senhora, PI',
        'mestrado');
INSERT INTO Pessoa
VALUES ('82775994734', '366403666534', 'Manuela Pereira', 'Kléber Travessa, 72755, undefined Lorena de Nossa Senhora, PB',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('23029678915', '767198891472', 'Sophia Moraes', 'Roberto Avenida, 11318, Palm Coast, PE',
        'mestrado');
INSERT INTO Pessoa
VALUES ('96399192840', '333335146401', 'Eduarda Silva', 'Silva Alameda, 91715, Melo de Nossa Senhora, MS',
        'mestrado');
INSERT INTO Pessoa
VALUES ('10734215972', '888549443613', 'Hugo Barros', 'Nataniel Marginal, 25853, undefined Mariana, MS',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('77949062872', '714547114050', 'Ana Júlia Moraes', 'Enzo Rodovia, 51207, undefined Bernardo, MT',
        'superior completo');
INSERT INTO Pessoa
VALUES ('76328378601', '841905536316', 'Emanuelly Albuquerque', 'Carvalho Rodovia, 81445, undefined Daniel de Nossa Senhora, PR',
        'mestrado');
INSERT INTO Pessoa
VALUES ('41542903429', '155100469756', 'Natália Saraiva', 'Franco Rodovia, 80859, undefined Roberta do Descoberto, SP',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('74748832648', '426625560433', 'Roberto Pereira', 'Morgana Travessa, 73419, Moraes do Norte, PE',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('29951727385', '255345836258', 'Yago Nogueira', 'Pereira Alameda, 77751, Xavier do Descoberto, ES',
        'superior completo');
INSERT INTO Pessoa
VALUES ('61259361898', '691241393005', 'Roberta Saraiva', 'Reis Marginal, 90070, undefined Isabela, RJ',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('53600938739', '370442795660', 'Eduardo Martins', 'Oliveira Rua, 57375, Fremont, AM',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('28005878622', '811435124534', 'João Pedro Souza', 'Costa Avenida, 6298, Lodi, RJ',
        'doutorado');
INSERT INTO Pessoa
VALUES ('79075478885', '224639542424', 'Felipe Pereira', 'Antonella Rodovia, 14879, undefined Bernardo de Nossa Senhora, MS',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('99424410643', '297459127497', 'Valentina Souza', 'Reis Travessa, 4952, Santa Clara, SP',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('71670214808', '382369392691', 'Hélio Albuquerque', 'Carvalho Marginal, 94735, Berwyn, SP',
        'superior completo');
INSERT INTO Pessoa
VALUES ('30165319882', '963684373535', 'Ricardo Braga', 'Vitória Marginal, 182, Natália do Descoberto, ES',
        'mestrado');
INSERT INTO Pessoa
VALUES ('79710021100', '495936354272', 'Esther Pereira', 'Henrique Rua, 30031, Joaquim do Norte, TO',
        'superior completo');
INSERT INTO Pessoa
VALUES ('64631355758', '481345877982', 'Gustavo Souza', 'Sophia Avenida, 28477, Giovanna do Sul, PR',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('90085991316', '738836019975', 'João Pedro Reis', 'Barros Travessa, 47364, undefined Noah do Norte, AC',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('26968071500', '210158963990', 'Núbia Carvalho', 'Costa Alameda, 35567, Chapel Hill, SE',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('99474227605', '142204414471', 'Cauã Pereira', 'Emanuelly Avenida, 24449, undefined Luiza, RS',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('58512432794', '300460440595', 'João Miguel Carvalho', 'Maria Clara Rua, 67372, undefined Margarida, PR',
        'doutorado');
INSERT INTO Pessoa
VALUES ('75170857366', '681949197757', 'Yango Costa', 'Alessandro Avenida, 44309, Barros do Norte, AC',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('17245056382', '800110282353', 'Daniel Carvalho', 'Martins Alameda, 99840, Moraes do Descoberto, RN',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('20170554369', '646613358776', 'Lavínia Macedo', 'Alessandra Rua, 88010, undefined Samuel do Descoberto, PI',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('83848194922', '537627820367', 'Carlos Saraiva', 'Morgana Rua, 34296, Albuquerque de Nossa Senhora, SE',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('26316265854', '276349027757', 'Fabiano Moraes', 'Saraiva Alameda, 48937, Frederico do Sul, DF',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('37795407914', '593831171095', 'Joaquim Reis', 'Barros Rua, 56742, undefined Guilherme, PB',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('32980330095', '942397933010', 'Kléber Batista', 'Braga Rua, 43347, undefined Eloá, RS',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('41960043215', '135722119407', 'Júlio Macedo', 'Ana Laura Avenida, 72267, undefined Alexandre, AC',
        'superior completo');
INSERT INTO Pessoa
VALUES ('21443818414', '898533092648', 'Isabela Silva', 'Franco Rodovia, 75310, Alessandra do Descoberto, TO',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('49372404732', '764428972965', 'Enzo Costa', 'Santos Rodovia, 28838, Clearwater, AM',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('61741954395', '255802569934', 'Eloá Xavier', 'Breno Marginal, 84001, Las Cruces, AL',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('59442965532', '291518100746', 'Isabella Pereira', 'Liz Travessa, 66909, Xavier do Norte, TO',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('52791193877', '280263240961', 'Marcelo Melo', 'Oliveira Alameda, 83455, Vicente de Nossa Senhora, BA',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('81158944626', '980244604614', 'Gabriel Pereira', 'Xavier Marginal, 60320, undefined Víctor do Sul, MG',
        'mestrado');
INSERT INTO Pessoa
VALUES ('46631380887', '481303820107', 'Frederico Carvalho', 'Gabriel Rodovia, 65469, Germantown, MS',
        'doutorado');
INSERT INTO Pessoa
VALUES ('83634928187', '112775224074', 'Melissa Braga', 'Cauã Rua, 57591, Arlington, SE',
        'doutorado');
INSERT INTO Pessoa
VALUES ('97948715968', '634512993786', 'Vitória Moreira', 'Isabela Alameda, 94815, undefined Alexandre, PI',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('42488055673', '218261970439', 'Dalila Oliveira', 'Silva Marginal, 10001, undefined Bernardo do Sul, MS',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('34798725692', '430343559570', 'João Lucas Barros', 'Maria Eduarda Alameda, 87847, Carvalho do Sul, PB',
        'mestrado');
INSERT INTO Pessoa
VALUES ('30865337816', '199395612091', 'Maria Melo', 'Barros Alameda, 84381, Tertuliano do Descoberto, RS',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('88250035129', '807642953936', 'Feliciano Barros', 'Lorraine Travessa, 35035, Santos do Sul, RN',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('63353046625', '695141700841', 'Rafael Souza', 'Isabelly Rodovia, 49520, undefined Emanuel, PA',
        'doutorado');
INSERT INTO Pessoa
VALUES ('38368732249', '947646121284', 'Lucca Reis', 'Costa Rua, 39668, undefined Carlos, MS',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('42662608220', '502832522359', 'Sophia Pereira', 'Carvalho Rodovia, 44891, Carvalho do Norte, AM',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('78746910984', '465950304805', 'Margarida Xavier', 'Silva Marginal, 66173, undefined Célia, AL',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('31904155020', '171085689705', 'Margarida Carvalho', 'Maria Alice Alameda, 16839, Alice do Sul, SC',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('24799374230', '488890559785', 'Norberto Pereira', 'Braga Travessa, 22652, undefined Rebeca, PB',
        'superior completo');
INSERT INTO Pessoa
VALUES ('16716102720', '210388007666', 'Rebeca Franco', 'Pereira Rua, 89865, undefined Gustavo, SC',
        'superior completo');
INSERT INTO Pessoa
VALUES ('77598187436', '231421195692', 'Eduarda Carvalho', 'Melo Avenida, 55702, Melo do Descoberto, PI',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('95569495800', '842815088690', 'Maria Júlia Pereira', 'Nogueira Alameda, 74494, Henrique do Descoberto, AP',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('82694570559', '596141233667', 'Alexandre Batista', 'Murilo Rodovia, 28719, Martins do Descoberto, PI',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('73146977170', '146094655431', 'Núbia Santos', 'César Alameda, 38583, Oliveira do Descoberto, PE',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('63150459881', '178997146408', 'Vitória Carvalho', 'Maria Alameda, 54056, Elísio de Nossa Senhora, ES',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('48260050807', '732330386969', 'Fabrício Reis', 'Félix Travessa, 29424, Calebe do Descoberto, ES',
        'mestrado');
INSERT INTO Pessoa
VALUES ('31208277349', '609681259887', 'Murilo Moreira', 'Moreira Marginal, 11409, Moreira de Nossa Senhora, PE',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('13684269834', '295536897052', 'Pablo Santos', 'Barros Alameda, 46143, undefined Arthur, AM',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('25462423549', '243214708636', 'Alexandre Nogueira', 'Carvalho Marginal, 71401, Lakewood, MS',
        'mestrado');
INSERT INTO Pessoa
VALUES ('26610598333', '186531088687', 'Sophia Souza', 'Moreira Marginal, 97096, Braga de Nossa Senhora, PE',
        'doutorado');
INSERT INTO Pessoa
VALUES ('37324441201', '749786581681', 'Bruna Reis', 'Raul Marginal, 85064, undefined Nataniel, AC',
        'mestrado');
INSERT INTO Pessoa
VALUES ('26005033133', '909916679398', 'Alícia Xavier', 'Macedo Rodovia, 59673, Barros do Descoberto, SC',
        'mestrado');
INSERT INTO Pessoa
VALUES ('53326698206', '998924931022', 'Karla Franco', 'Víctor Travessa, 83863, Billings, RO',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('29644463055', '172870394075', 'Rafael Carvalho', 'Moraes Marginal, 64502, undefined Gúbio, RS',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('79579603821', '471176415984', 'Miguel Braga', 'Breno Travessa, 90583, undefined Manuela, RS',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('26153816252', '808994768210', 'Mariana Braga', 'Oliveira Avenida, 5405, Melo do Sul, AL',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('65671260850', '557826523296', 'Lara Souza', 'Melo Travessa, 30178, undefined Bernardo de Nossa Senhora, PE',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('27572791909', '199405508185', 'Vitor Oliveira', 'Saraiva Alameda, 31546, Franco do Descoberto, AP',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('83248722925', '231133663724', 'Hélio Moreira', 'Moreira Travessa, 13581, Port Charlotte, RR',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('81749686598', '519687454239', 'João Pedro Moraes', 'Melo Travessa, 33024, Costa do Sul, TO',
        'superior completo');
INSERT INTO Pessoa
VALUES ('67696900554', '101057325326', 'Rafael Martins', 'Silva Travessa, 49756, undefined Yago de Nossa Senhora, RJ',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('76730977462', '128617062140', 'Gúbio Carvalho', 'Víctor Alameda, 43193, undefined Davi, RJ',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('56926663320', '287246577488', 'Anthony Nogueira', 'Talita Travessa, 31228, João do Sul, MS',
        'doutorado');
INSERT INTO Pessoa
VALUES ('48280321999', '638768296595', 'Vicente Souza', 'Souza Rodovia, 86530, undefined Mariana do Sul, GO',
        'mestrado');
INSERT INTO Pessoa
VALUES ('16846755656', '396700415969', 'Deneval Costa', 'Maria Cecília Travessa, 95953, undefined Kléber do Sul, RJ',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('94493685548', '180042138393', 'Lorenzo Martins', 'Costa Avenida, 22238, undefined Mércia, MS',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('89211657708', '589297595177', 'Mércia Saraiva', 'Maria Alice Alameda, 59996, undefined Caio, GO',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('35014395120', '332031680410', 'Maria Eduarda Pereira', 'Moreira Rodovia, 89529, Saginaw, PA',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('31581937542', '492525992775', 'Emanuel Albuquerque', 'Ígor Marginal, 85890, undefined Alessandra do Descoberto, PE',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('89516800977', '289211741928', 'Suélen Pereira', 'Mércia Avenida, 17034, Chino, RR',
        'mestrado');
INSERT INTO Pessoa
VALUES ('94656017050', '369553589518', 'Noah Moreira', 'Matheus Rodovia, 65102, Waterbury, ES',
        'mestrado');
INSERT INTO Pessoa
VALUES ('24517586107', '445236353925', 'Ana Júlia Albuquerque', 'Moreira Rua, 17534, Overland Park, PB',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('86656567275', '916240742360', 'Víctor Santos', 'Elisa Travessa, 6645, undefined Mariana, SP',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('56330149946', '707078422792', 'João Saraiva', 'Maria Clara Travessa, 82806, undefined Eduardo, RO',
        'doutorado');
INSERT INTO Pessoa
VALUES ('68939089383', '597287080693', 'Isadora Pereira', 'Carvalho Rodovia, 36745, Antônio de Nossa Senhora, PR',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('65311654887', '498489474435', 'Heloísa Macedo', 'Cauã Travessa, 54629, Yuma, MT',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('79117540030', '532822912815', 'Lucas Nogueira', 'Pereira Alameda, 41690, undefined Guilherme, PI',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('72538530293', '230251896101', 'Calebe Franco', 'Margarida Rua, 22848, undefined Isaac, GO',
        'doutorado');
INSERT INTO Pessoa
VALUES ('98020184999', '920717935520', 'Mariana Carvalho', 'Santos Travessa, 31841, Santos do Descoberto, MG',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('80758689786', '826507948967', 'Rafaela Reis', 'Melo Rodovia, 24871, undefined Gael de Nossa Senhora, RJ',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('44860848870', '973017208650', 'Enzo Gabriel Moraes', 'Lucca Marginal, 59140, Springfield, RN',
        'superior completo');
INSERT INTO Pessoa
VALUES ('21185206798', '345474576507', 'Lorraine Martins', 'Carvalho Rodovia, 54136, undefined Calebe do Norte, CE',
        'superior completo');
INSERT INTO Pessoa
VALUES ('77664967630', '140728517225', 'Sirineu Souza', 'Morgana Marginal, 38987, Mountain View, PI',
        'mestrado');
INSERT INTO Pessoa
VALUES ('10814941977', '634428868396', 'Mércia Pereira', 'Isabel Avenida, 40225, Rancho Santa Margarita, RS',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('94529897822', '535098321037', 'João Lucas Barros', 'Marcos Rodovia, 34632, Gúbio do Descoberto, CE',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('97763730341', '570367905264', 'Marli Saraiva', 'Roberto Marginal, 2276, undefined Lucas do Sul, AL',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('84909864924', '873232656973', 'Lucas Xavier', 'Martins Alameda, 79427, Antonella de Nossa Senhora, ES',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('16176439919', '364208362065', 'Liz Macedo', 'Rebeca Travessa, 85583, undefined Heitor do Descoberto, AM',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('99122018190', '532591100386', 'João Miguel Macedo', 'Ofélia Alameda, 36666, Union City, BA',
        'doutorado');
INSERT INTO Pessoa
VALUES ('90056711882', '156954705575', 'Elísio Oliveira', 'Laura Rodovia, 4362, undefined Yango do Norte, TO',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('21700934006', '143141512293', 'Margarida Martins', 'Pereira Avenida, 99987, Plainfield, RO',
        'doutorado');
INSERT INTO Pessoa
VALUES ('97353540891', '406749212718', 'Isabela Nogueira', 'Yuri Alameda, 10098, Benício do Norte, MA',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('28029985185', '718633547076', 'Valentina Souza', 'Carlos Rua, 75701, Lorenzo do Descoberto, MT',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('36030380690', '760692448355', 'Lucas Pereira', 'Moreira Rua, 16439, South Jordan, TO',
        'doutorado');
INSERT INTO Pessoa
VALUES ('19092043468', '687665961030', 'Noah Braga', 'Félix Avenida, 26102, Alessandro de Nossa Senhora, SP',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('68556229528', '906141921784', 'Morgana Melo', 'Yuri Alameda, 87605, Niagara Falls, MA',
        'superior completo');
INSERT INTO Pessoa
VALUES ('76437914024', '888452566834', 'Eduardo Reis', 'Davi Travessa, 45650, undefined Rafaela, CE',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('24488041764', '849052817630', 'Maria Clara Xavier', 'Carvalho Alameda, 58230, Deneval do Descoberto, AP',
        'doutorado');
INSERT INTO Pessoa
VALUES ('70865662137', '456631190865', 'Isabela Saraiva', 'Sara Travessa, 18532, Rochester Hills, SC',
        'superior completo');
INSERT INTO Pessoa
VALUES ('74766249782', '181892166077', 'Aline Nogueira', 'Márcia Rua, 53635, Hoffman Estates, PR',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('85103842427', '251063350727', 'Laura Moreira', 'Barros Rua, 19290, undefined Lívia de Nossa Senhora, RN',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('51842986051', '806411725492', 'Sílvia Franco', 'Moreira Alameda, 91163, Gúbio do Sul, ES',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('49827746006', '617963328305', 'Célia Braga', 'Albuquerque Rua, 26465, Marcelo do Norte, AC',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('50569366908', '609198687737', 'Júlio Moreira', 'Emanuelly Avenida, 66640, Isadora do Descoberto, SP',
        'superior completo');
INSERT INTO Pessoa
VALUES ('48150026823', '648012287728', 'Isabella Souza', 'Carvalho Marginal, 46195, Beaumont, SC',
        'superior completo');
INSERT INTO Pessoa
VALUES ('25997139057', '884831889974', 'Maria Clara Silva', 'Braga Rodovia, 23421, undefined Mariana, MA',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('97341636095', '233962069265', 'Paulo Braga', 'Braga Alameda, 53547, Dalila do Descoberto, SP',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('80553411089', '370563908503', 'Roberto Carvalho', 'Frederico Rua, 10832, undefined Fabrícia de Nossa Senhora, PA',
        'superior completo');
INSERT INTO Pessoa
VALUES ('76136016375', '859437539684', 'Calebe Carvalho', 'Xavier Rodovia, 20156, undefined Tertuliano do Norte, MS',
        'doutorado');
INSERT INTO Pessoa
VALUES ('75247511798', '341862480412', 'Fábio Melo', 'Heitor Rua, 36675, undefined Bryan do Norte, RO',
        'mestrado');
INSERT INTO Pessoa
VALUES ('46842239857', '908951294957', 'Hélio Costa', 'Carvalho Avenida, 82503, Daly City, SE',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('56571923072', '368640364403', 'Rafaela Saraiva', 'João Travessa, 7309, undefined Washington, SE',
        'mestrado');
INSERT INTO Pessoa
VALUES ('42354971754', '598542764596', 'Ana Laura Martins', 'Reis Travessa, 37859, Braga do Norte, SE',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('89854734104', '932174016721', 'Matheus Oliveira', 'Xavier Avenida, 23955, Wilmington, RN',
        'mestrado');
INSERT INTO Pessoa
VALUES ('17417510917', '605852374876', 'Emanuelly Braga', 'Reis Rodovia, 79073, Souza do Norte, BA',
        'doutorado');
INSERT INTO Pessoa
VALUES ('36536230433', '934191825171', 'Frederico Saraiva', 'Souza Travessa, 60684, undefined César, RN',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('15051016972', '360977047029', 'João Lucas Santos', 'Norberto Alameda, 27036, Yakima, RR',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('36764807719', '544122741930', 'Beatriz Albuquerque', 'Carvalho Alameda, 82450, undefined Kléber do Sul, MA',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('16205148608', '176356383389', 'Breno Nogueira', 'Albuquerque Travessa, 50609, Larissa do Descoberto, RS',
        'superior completo');
INSERT INTO Pessoa
VALUES ('15945927712', '773628780781', 'Joana Franco', 'Sarah Avenida, 84803, undefined Célia de Nossa Senhora, MG',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('79860785743', '291118479054', 'Isadora Costa', 'Salvador Rua, 5767, undefined Alexandre do Descoberto, PR',
        'doutorado');
INSERT INTO Pessoa
VALUES ('42206480598', '273820772510', 'Talita Souza', 'Nogueira Avenida, 27403, undefined Vicente do Norte, GO',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('68110109437', '394456284609', 'Maria Alice Braga', 'Pereira Travessa, 13875, Maria Luiza de Nossa Senhora, RJ',
        'doutorado');
INSERT INTO Pessoa
VALUES ('61740416085', '540013796580', 'Núbia Pereira', 'Oliveira Marginal, 16365, undefined Valentina de Nossa Senhora, SC',
        'mestrado');
INSERT INTO Pessoa
VALUES ('45732964542', '733166511356', 'Benjamin Costa', 'Maria Alice Travessa, 65100, Elisa do Sul, BA',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('40505070846', '270141935930', 'Eloá Carvalho', 'Santos Rua, 52175, Mission, TO',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('97409812505', '992502025095', 'Maria Saraiva', 'Pedro Henrique Marginal, 67438, undefined Feliciano, GO',
        'mestrado');
INSERT INTO Pessoa
VALUES ('51445510021', '435100135183', 'Maria Helena Oliveira', 'Deneval Rodovia, 50884, Lawrence, BA',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('82502861178', '840877533610', 'Maria Eduarda Pereira', 'Batista Marginal, 59028, undefined Felipe do Sul, TO',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('64113110627', '830924209044', 'Alessandra Barros', 'Melo Rodovia, 49140, Santos de Nossa Senhora, ES',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('16381429000', '452377763087', 'Carla Barros', 'Júlio Travessa, 27114, undefined Kléber, CE',
        'doutorado');
INSERT INTO Pessoa
VALUES ('42256481919', '693176849465', 'Isabela Moreira', 'Martins Marginal, 97656, Maria Alice de Nossa Senhora, PB',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('91828825019', '760521335154', 'Yango Franco', 'Oliveira Rua, 41598, Nicolas do Descoberto, DF',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('32882520346', '286537044565', 'Anthony Souza', 'Santos Travessa, 98789, Matheus do Sul, PA',
        'mestrado');
INSERT INTO Pessoa
VALUES ('46218319148', '118309033871', 'Sara Albuquerque', 'Davi Lucca Rodovia, 50431, undefined Vitor do Norte, RN',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('16300685813', '213035555207', 'Paula Silva', 'Lara Rodovia, 27468, Carvalho de Nossa Senhora, PE',
        'doutorado');
INSERT INTO Pessoa
VALUES ('90832039350', '877580072917', 'Cecília Carvalho', 'Maria Eduarda Marginal, 64105, Silva do Sul, PR',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('66636465038', '638403341406', 'Maria Luiza Souza', 'João Lucas Rua, 59012, Souza de Nossa Senhora, SE',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('38607805878', '807078639161', 'Alessandro Moreira', 'Heitor Travessa, 66413, undefined Bruna, GO',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('71321501170', '751720974687', 'Mariana Martins', 'Pereira Avenida, 90914, undefined Daniel de Nossa Senhora, PB',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('38533823639', '656826394726', 'Maitê Batista', 'Benjamin Rua, 51507, Martins de Nossa Senhora, RN',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('37652357325', '769987406907', 'Fabrício Barros', 'Barros Rua, 14375, Albuquerque do Sul, ES',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('44197359627', '458638945012', 'Lucas Melo', 'Batista Travessa, 56102, undefined Fábio do Norte, SP',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('38676820667', '958473329036', 'Pablo Batista', 'Maria Clara Avenida, 19756, undefined Dalila do Descoberto, RS',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('15692404331', '949816935509', 'Joana Carvalho', 'Hugo Avenida, 81806, undefined Eloá, GO',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('98059176125', '200139328720', 'Ricardo Oliveira', 'Franco Travessa, 49301, St. Paul, RJ',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('27899335727', '171512815356', 'Benjamin Macedo', 'Ígor Alameda, 39085, undefined Breno, CE',
        'doutorado');
INSERT INTO Pessoa
VALUES ('68421083828', '111384066613', 'Davi Franco', 'Silva Avenida, 56858, Draper, AP',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('21359217371', '939425612916', 'Ladislau Reis', 'Albuquerque Rua, 84823, Ofélia do Sul, SP',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('67442927379', '579633897636', 'Fabrício Pereira', 'Carla Rua, 89573, Grand Island, PE',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('36481781632', '861680715926', 'Alícia Oliveira', 'Reis Rua, 55181, undefined Eloá, RR',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('14018435610', '894926720345', 'Isabella Saraiva', 'Emanuel Avenida, 11900, undefined Alexandre, DF',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('34531981556', '978619306231', 'Rafael Pereira', 'Carvalho Alameda, 57375, Manuela de Nossa Senhora, SC',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('93058234590', '788582367612', 'Joaquim Albuquerque', 'Carvalho Rodovia, 82424, undefined Sirineu, MT',
        'superior completo');
INSERT INTO Pessoa
VALUES ('53239999383', '157133946078', 'Breno Saraiva', 'Martins Rodovia, 96170, undefined Felícia, MS',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('96735474125', '710933626140', 'Margarida Franco', 'Ricardo Avenida, 41334, Moreira de Nossa Senhora, ES',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('40160910950', '883205365110', 'Lavínia Macedo', 'Albuquerque Travessa, 73848, Moreira do Sul, TO',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('23977915302', '950666373292', 'Fabrício Moreira', 'Ana Júlia Rua, 22663, undefined Washington, AC',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('62271722485', '207468408695', 'Joaquim Silva', 'Batista Alameda, 72577, Corona, PI',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('84267205318', '164531853632', 'Isabel Carvalho', 'Ana Laura Rodovia, 88878, undefined Rebeca, MG',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('78620078519', '781692721485', 'Caio Costa', 'Silva Marginal, 51775, Caguas, SC',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('27884188957', '516009224089', 'Vicente Oliveira', 'Albuquerque Rua, 63348, Nicolas do Sul, TO',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('77020872854', '384317283076', 'Clara Oliveira', 'Raul Rodovia, 3703, Redondo Beach, SC',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('66000308196', '582401329651', 'Guilherme Pereira', 'Yuri Rodovia, 55100, Fabrício do Sul, BA',
        'doutorado');
INSERT INTO Pessoa
VALUES ('11973855195', '237470648437', 'Enzo Gabriel Martins', 'Saraiva Marginal, 77083, undefined Noah de Nossa Senhora, RS',
        'superior completo');
INSERT INTO Pessoa
VALUES ('23578601770', '407054131058', 'Davi Lucca Braga', 'Melo Marginal, 62713, Joana do Norte, MT',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('62763315637', '189900063909', 'Lívia Nogueira', 'Silva Rua, 17340, Coconut Creek, CE',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('21158760678', '824782419786', 'Eloá Costa', 'Carvalho Rua, 64881, undefined Marcela, MA',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('85096177156', '819845930393', 'Elisa Xavier', 'Pereira Rodovia, 47844, Rebeca do Norte, AC',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('93732622361', '568992264382', 'Isis Saraiva', 'Maria Avenida, 70071, Victorville, PA',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('76603942574', '719467906653', 'Enzo Pereira', 'Bryan Avenida, 67573, João Pedro de Nossa Senhora, AC',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('93748753082', '942980419751', 'Maria Clara Oliveira', 'Oliveira Alameda, 17420, undefined Bryan, MT',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('54557767456', '788576313992', 'Marina Costa', 'Larissa Marginal, 5074, undefined Alessandro de Nossa Senhora, PA',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('72167665150', '248139258427', 'Aline Moraes', 'Sophia Marginal, 39232, Júlio César do Norte, RJ',
        'superior completo');
INSERT INTO Pessoa
VALUES ('60074036989', '931529960711', 'Ladislau Nogueira', 'Melo Avenida, 22238, undefined Paulo do Sul, SP',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('44287939586', '941245023184', 'Washington Reis', 'Júlio Travessa, 15373, Ígor do Descoberto, SC',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('38337135156', '767051153094', 'Kléber Xavier', 'Xavier Alameda, 89340, undefined Noah, AC',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('26635247771', '926983756199', 'Carlos Batista', 'Moreira Rua, 68114, undefined João Miguel do Descoberto, GO',
        'doutorado');
INSERT INTO Pessoa
VALUES ('50137497729', '675473386514', 'Carla Xavier', 'Anthony Alameda, 5766, undefined Lara do Sul, MT',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('34163422295', '233172901975', 'Lorena Carvalho', 'Santos Rodovia, 37158, Eduardo de Nossa Senhora, PR',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('90917762164', '877701370371', 'Lorraine Batista', 'Silva Alameda, 25127, undefined Antônio, RO',
        'doutorado');
INSERT INTO Pessoa
VALUES ('99547809399', '616673152241', 'Margarida Reis', 'Marli Marginal, 56968, Albuquerque do Norte, MS',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('98488777014', '429967909073', 'Samuel Oliveira', 'Roberto Travessa, 6447, undefined Bruna do Sul, AP',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('48501468393', '193839859100', 'Deneval Xavier', 'Braga Marginal, 61852, Morgana de Nossa Senhora, CE',
        'doutorado');
INSERT INTO Pessoa
VALUES ('89273748940', '942624198296', 'Lucas Carvalho', 'Yasmin Marginal, 17673, undefined Enzo, DF',
        'doutorado');
INSERT INTO Pessoa
VALUES ('27042364289', '498347830120', 'Vitória Silva', 'Souza Rodovia, 29170, undefined Cecília do Sul, RR',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('80710820276', '200170098687', 'Marli Barros', 'Saraiva Alameda, 96657, Silva do Sul, PR',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('19121663228', '371134435315', 'Matheus Albuquerque', 'Melo Rua, 25990, undefined Norberto do Norte, SP',
        'superior completo');
INSERT INTO Pessoa
VALUES ('97532397126', '188200478814', 'Benício Melo', 'Guilherme Alameda, 60006, undefined Yasmin, TO',
        'doutorado');
INSERT INTO Pessoa
VALUES ('46791838572', '518874319945', 'Paulo Carvalho', 'Morgana Marginal, 8454, Reis do Sul, MA',
        'superior completo');
INSERT INTO Pessoa
VALUES ('73877129219', '262002233508', 'Benjamin Costa', 'Kléber Travessa, 5666, Heloísa do Descoberto, SC',
        'mestrado');
INSERT INTO Pessoa
VALUES ('14925663892', '755977773666', 'Talita Moraes', 'Barros Avenida, 25778, Rafaela do Sul, PE',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('59657050718', '734239989658', 'Ricardo Martins', 'Carvalho Rua, 99460, Chesapeake, DF',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('18472580276', '641374699259', 'Cecília Braga', 'Lorenzo Rua, 76026, undefined Marcelo do Norte, RS',
        'doutorado');
INSERT INTO Pessoa
VALUES ('23965377714', '814307106961', 'Gúbio Martins', 'Marli Avenida, 91837, Yuma, AC',
        'superior completo');
INSERT INTO Pessoa
VALUES ('90229740976', '225375461787', 'Benício Oliveira', 'Emanuel Travessa, 63584, Maria do Norte, BA',
        'superior completo');
INSERT INTO Pessoa
VALUES ('65810908826', '136216959520', 'Helena Martins', 'Pereira Travessa, 99026, undefined Alessandra, RN',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('25301664806', '963710011681', 'Núbia Costa', 'Maria Clara Rua, 98470, undefined Emanuelly, MS',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('21988119990', '263503293436', 'Alessandra Martins', 'Saraiva Travessa, 63528, undefined Helena, BA',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('14911504909', '746462292270', 'Isabela Martins', 'Suélen Alameda, 54074, undefined Lorraine do Sul, AP',
        'mestrado');
INSERT INTO Pessoa
VALUES ('80310637017', '559433432412', 'Clara Barros', 'Pereira Rua, 75977, Aloha, RS',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('93053958227', '172545066848', 'Maria Alice Albuquerque', 'Costa Marginal, 66724, Macedo do Sul, PB',
        'mestrado');
INSERT INTO Pessoa
VALUES ('49035936468', '886323495954', 'Laura Macedo', 'Lavínia Alameda, 24941, undefined Aline do Descoberto, SE',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('24966657152', '997268947539', 'Paula Xavier', 'Isabella Marginal, 49005, undefined Bryan do Descoberto, RR',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('85147762342', '958838268928', 'Bruna Reis', 'Leonardo Avenida, 8868, undefined Felícia de Nossa Senhora, PE',
        'superior completo');
INSERT INTO Pessoa
VALUES ('20454070107', '332744057732', 'Luiza Carvalho', 'Moreira Rodovia, 99366, Carla do Norte, PB',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('70941680760', '745459899213', 'Aline Moreira', 'Braga Marginal, 29472, Beatriz do Descoberto, SE',
        'mestrado');
INSERT INTO Pessoa
VALUES ('24394065793', '405333874723', 'Murilo Braga', 'Maria Helena Travessa, 50679, Martins do Norte, AP',
        'superior completo');
INSERT INTO Pessoa
VALUES ('39643863362', '668799349968', 'Fábio Albuquerque', 'Silas Marginal, 55517, Medford, AP',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('90507961907', '699362232582', 'Ana Júlia Costa', 'Santos Avenida, 73339, Roberta do Norte, AM',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('58344170006', '626802515005', 'Fabrício Oliveira', 'Maria Alice Avenida, 58627, Macedo de Nossa Senhora, DF',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('14742387901', '778748822747', 'Giovanna Carvalho', 'Martins Marginal, 53335, Warner Robins, PA',
        'doutorado');
INSERT INTO Pessoa
VALUES ('42611886474', '274983524368', 'Leonardo Oliveira', 'Dalila Marginal, 82154, undefined Pietro, AM',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('87898668807', '487318979552', 'Daniel Macedo', 'Batista Travessa, 43821, West Babylon, PI',
        'superior completo');
INSERT INTO Pessoa
VALUES ('13751666853', '154886260582', 'Rafaela Pereira', 'Braga Marginal, 99707, Maria Clara de Nossa Senhora, PB',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('70566484834', '961872604629', 'Meire Melo', 'Marina Marginal, 4018, undefined Clara de Nossa Senhora, RS',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('34354209771', '308026070240', 'Nataniel Costa', 'Ana Luiza Marginal, 7986, Franco do Norte, RR',
        'superior completo');
INSERT INTO Pessoa
VALUES ('37445924126', '902265023766', 'Yuri Franco', 'Sarah Alameda, 70187, undefined Suélen, RO',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('50802746731', '800350706977', 'Benjamin Melo', 'Oliveira Travessa, 14741, Macedo do Descoberto, AL',
        'mestrado');
INSERT INTO Pessoa
VALUES ('23022611923', '546447919798', 'Marli Oliveira', 'Roberta Rodovia, 25931, undefined Júlio César, AP',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('59413086730', '546794107905', 'Henrique Moreira', 'Barros Alameda, 3481, Silva de Nossa Senhora, MS',
        'doutorado');
INSERT INTO Pessoa
VALUES ('35594983946', '286294853873', 'Melissa Braga', 'Melo Rua, 1808, undefined Mércia do Sul, SP',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('26316574874', '443565626884', 'Feliciano Barros', 'Nogueira Marginal, 80843, Battle Creek, RN',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('27614811982', '890882565849', 'Anthony Silva', 'Isabelly Alameda, 47507, Apopka, MS',
        'mestrado');
INSERT INTO Pessoa
VALUES ('76349967408', '567614530958', 'Cecília Melo', 'Nogueira Travessa, 5810, undefined Guilherme do Norte, AP',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('82877426827', '855564360506', 'Warley Moreira', 'Lucca Travessa, 95548, undefined Pedro, RJ',
        'superior completo');
INSERT INTO Pessoa
VALUES ('86912200003', '372666954202', 'César Braga', 'Joaquim Rodovia, 29224, Franco do Descoberto, DF',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('16140814840', '755998303042', 'Alexandre Moreira', 'Margarida Avenida, 29411, undefined Fabrício, RN',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('17716842761', '701880903751', 'Marina Moreira', 'Melo Alameda, 63747, undefined Júlio do Sul, CE',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('40696949039', '843898517778', 'Maria Moraes', 'Reis Rua, 26265, Braga do Descoberto, SP',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('91892894401', '513067650492', 'Roberto Carvalho', 'Batista Travessa, 75084, undefined Valentina, AL',
        'doutorado');
INSERT INTO Pessoa
VALUES ('26663710535', '892286734329', 'Yuri Reis', 'Oliveira Avenida, 82832, Brookline, AP',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('35807526966', '705032348888', 'Melissa Melo', 'Martins Marginal, 49008, undefined Esther de Nossa Senhora, MS',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('21716864630', '653268221090', 'Maria Cecília Batista', 'Martins Rodovia, 3588, Souza de Nossa Senhora, PA',
        'mestrado');
INSERT INTO Pessoa
VALUES ('44611691811', '677838804642', 'Laura Xavier', 'Isabela Alameda, 93, Brockton, RJ',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('86753180653', '656410925998', 'Bruna Costa', 'Carvalho Travessa, 25659, Boston, RR',
        'doutorado');
INSERT INTO Pessoa
VALUES ('20462237349', '434273118991', 'Breno Reis', 'Melo Alameda, 14933, Beatriz do Norte, PA',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('73957219352', '828806274989', 'Caio Reis', 'Antonella Avenida, 27383, Albuquerque do Descoberto, PB',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('67688139935', '521353026409', 'Carlos Reis', 'Paulo Alameda, 19698, Marcelo de Nossa Senhora, SP',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('19252804473', '171895507490', 'Isabella Franco', 'Carla Marginal, 46231, Braga do Descoberto, RJ',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('43096352221', '560187339549', 'Elísio Martins', 'Macedo Avenida, 88253, undefined João Lucas de Nossa Senhora, AL',
        'doutorado');
INSERT INTO Pessoa
VALUES ('13749101529', '589362645661', 'Roberta Moraes', 'Ana Clara Rua, 38721, undefined Calebe do Descoberto, RR',
        'superior completo');
INSERT INTO Pessoa
VALUES ('21656998395', '810187474894', 'Maria Luiza Costa', 'Janaína Marginal, 49887, Victorville, ES',
        'mestrado');
INSERT INTO Pessoa
VALUES ('17156520811', '498060992173', 'Meire Costa', 'Pablo Rua, 84516, Souza de Nossa Senhora, MA',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('66367407455', '814751885947', 'Felipe Oliveira', 'Batista Avenida, 78229, Malden, ES',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('38326898736', '875791621627', 'Anthony Nogueira', 'Martins Marginal, 56650, Anaheim, SE',
        'superior completo');
INSERT INTO Pessoa
VALUES ('41209149078', '529591519827', 'Fábio Saraiva', 'Célia Avenida, 68513, undefined Raul, CE',
        'doutorado');
INSERT INTO Pessoa
VALUES ('87576986304', '180629480979', 'Gael Barros', 'Mariana Rua, 76242, Braga do Sul, SC',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('69862666106', '480850360612', 'Isis Santos', 'Alícia Rodovia, 49584, undefined Manuela, ES',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('36747011074', '378642666945', 'Marli Albuquerque', 'Caio Avenida, 28903, Martins do Norte, RN',
        'mestrado');
INSERT INTO Pessoa
VALUES ('84538009271', '429688582359', 'Nicolas Reis', 'Reis Travessa, 66374, undefined Maria Júlia, MT',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('30055465318', '264354930841', 'Paulo Carvalho', 'Barros Avenida, 99648, Syracuse, AL',
        'doutorado');
INSERT INTO Pessoa
VALUES ('16016930101', '143024228303', 'Esther Costa', 'Daniel Alameda, 28671, Carvalho de Nossa Senhora, SC',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('91077021027', '857564127119', 'Suélen Braga', 'Paulo Avenida, 71757, undefined Vicente do Norte, MS',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('81787125857', '493906568922', 'Valentina Xavier', 'Alice Alameda, 34701, undefined Eloá, PI',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('47835368167', '185131417936', 'Ana Laura Batista', 'Nogueira Rodovia, 83209, undefined Joana do Sul, GO',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('57761234645', '137901313020', 'Isabella Franco', 'Reis Marginal, 31584, Bryan do Norte, PB',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('98291583606', '469924907945', 'Eloá Silva', 'Albuquerque Marginal, 68814, undefined Elísio, MS',
        'mestrado');
INSERT INTO Pessoa
VALUES ('81107487515', '589996546157', 'Ricardo Franco', 'Pereira Marginal, 43904, Moreira do Norte, SE',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('74082964621', '174041305924', 'Júlia Albuquerque', 'Silva Rodovia, 39776, undefined Rafaela, PI',
        'mestrado');
INSERT INTO Pessoa
VALUES ('68520916590', '312518827337', 'Leonardo Moraes', 'Batista Avenida, 94141, Fabiano do Descoberto, AP',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('83035852278', '146935218037', 'Laura Barros', 'Maitê Marginal, 2837, Felipe de Nossa Senhora, TO',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('79021790616', '540002852957', 'Caio Santos', 'Barros Rua, 36476, Júlia de Nossa Senhora, RO',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('34177497543', '943409630190', 'Clara Saraiva', 'Calebe Rodovia, 62830, undefined Eduarda do Sul, AM',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('91929960791', '511719882371', 'Yango Melo', 'Souza Avenida, 13626, undefined Daniel, RR',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('53485558112', '632808754220', 'Sophia Martins', 'Costa Alameda, 41178, Santos do Norte, MS',
        'mestrado');
INSERT INTO Pessoa
VALUES ('19822962293', '304937177360', 'Antônio Souza', 'Moraes Avenida, 20314, Wylie, GO',
        'superior completo');
INSERT INTO Pessoa
VALUES ('87706230955', '890073404787', 'Enzo Gabriel Saraiva', 'Macedo Alameda, 2435, undefined Henrique, AM',
        'mestrado');
INSERT INTO Pessoa
VALUES ('70796429398', '180698644253', 'Rafael Batista', 'Carvalho Rodovia, 52222, undefined Matheus do Norte, TO',
        'superior completo');
INSERT INTO Pessoa
VALUES ('97014694346', '604430307261', 'Lavínia Martins', 'Lucas Marginal, 67014, Marietta, SE',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('72265644003', '908719671959', 'Emanuel Oliveira', 'Pereira Marginal, 71744, DeSoto, SC',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('41520086317', '443951794155', 'Eduardo Albuquerque', 'Costa Avenida, 12410, undefined Mércia, DF',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('68425539585', '879283663723', 'Júlio Carvalho', 'Carvalho Rodovia, 83816, undefined Aline do Sul, ES',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('52929108014', '955325440969', 'Lívia Silva', 'Nataniel Alameda, 63326, Wichita Falls, BA',
        'superior completo');
INSERT INTO Pessoa
VALUES ('11848160342', '944551520748', 'Leonardo Martins', 'Elísio Rua, 18857, Overland Park, GO',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('85421043294', '477872752794', 'Norberto Moraes', 'Marcela Marginal, 25079, Oliveira do Sul, MT',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('57748351241', '237098920252', 'Marli Moreira', 'Souza Rodovia, 96112, Ana Luiza do Descoberto, GO',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('93404436695', '538485101726', 'Noah Macedo', 'Saraiva Travessa, 49885, Cauã do Sul, MA',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('87482139978', '306763866683', 'Morgana Batista', 'Warley Travessa, 66610, undefined Feliciano, MS',
        'mestrado');
INSERT INTO Pessoa
VALUES ('31766336101', '471493732207', 'Miguel Costa', 'Larissa Rua, 57805, Mariana do Norte, TO',
        'mestrado');
INSERT INTO Pessoa
VALUES ('26564529193', '921953621669', 'Matheus Silva', 'Albuquerque Rodovia, 87569, Bryan do Sul, AC',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('43850494597', '567108500795', 'Célia Xavier', 'Costa Travessa, 12906, João Pedro do Sul, PR',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('92712711545', '613459030585', 'Pietro Reis', 'Souza Marginal, 18119, Burnsville, MA',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('11940935752', '239983217162', 'Miguel Souza', 'Marcela Travessa, 63915, undefined Isadora, BA',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('48772362389', '743581197247', 'Bernardo Albuquerque', 'João Travessa, 84996, undefined Marli, MS',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('66001942080', '461026685615', 'Alessandra Franco', 'Elísio Travessa, 31738, undefined Carla, SP',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('94982653530', '502037395746', 'Miguel Reis', 'Batista Rodovia, 64159, undefined Hugo, RR',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('14423142687', '196441816631', 'Lucas Moreira', 'Franco Rodovia, 35340, Maria do Descoberto, MA',
        'doutorado');
INSERT INTO Pessoa
VALUES ('74113580884', '152008642582', 'Manuela Oliveira', 'Carvalho Rua, 40063, undefined Heloísa, PR',
        'mestrado');
INSERT INTO Pessoa
VALUES ('42681556036', '467682830779', 'Helena Batista', 'Tertuliano Alameda, 66065, Reis do Norte, DF',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('82239788295', '720496473670', 'Frederico Albuquerque', 'Vicente Rodovia, 31773, Buckeye, PA',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('41509310919', '493294136784', 'João Lucas Albuquerque', 'Albuquerque Alameda, 56963, undefined Gustavo do Norte, AM',
        'doutorado');
INSERT INTO Pessoa
VALUES ('66261561494', '465675971191', 'Rebeca Silva', 'Martins Avenida, 13115, undefined Clara do Sul, AP',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('24846970050', '401095564127', 'Yango Saraiva', 'Eloá Alameda, 24872, undefined Arthur, MG',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('31480855625', '993945960467', 'Isabella Melo', 'Anthony Rua, 50547, Novi, MS',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('86313275324', '686459872848', 'Felícia Melo', 'Hugo Marginal, 46284, undefined Núbia, SC',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('13439644786', '326208734977', 'Kléber Melo', 'Moraes Rodovia, 86210, undefined Leonardo, PR',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('89034917883', '175988082354', 'Víctor Franco', 'Gabriel Rodovia, 70632, Costa do Norte, SP',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('82966468287', '573008663882', 'Helena Saraiva', 'Isis Rodovia, 98215, Oliveira de Nossa Senhora, SP',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('62869147914', '461339709884', 'Joaquim Martins', 'João Miguel Rodovia, 8878, undefined Pablo do Norte, PI',
        'superior completo');
INSERT INTO Pessoa
VALUES ('91017248921', '701234934362', 'Sílvia Moraes', 'Eduardo Alameda, 50142, Warley de Nossa Senhora, BA',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('65095990132', '959560596616', 'Víctor Macedo', 'Manuela Rodovia, 98032, Oliveira do Norte, PA',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('21655415012', '732682769303', 'Aline Xavier', 'Víctor Marginal, 52400, Hélio do Descoberto, AL',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('23662008999', '262469458184', 'Manuela Xavier', 'Oliveira Alameda, 2622, undefined Maria Cecília, ES',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('76983075961', '476435266877', 'Davi Lucca Reis', 'Karla Rua, 57628, Lorena do Norte, DF',
        'mestrado');
INSERT INTO Pessoa
VALUES ('44515146410', '919830041984', 'Antônio Silva', 'Albuquerque Avenida, 62661, Ana Clara do Descoberto, SC',
        'mestrado');
INSERT INTO Pessoa
VALUES ('44242259408', '255702409753', 'Ana Júlia Albuquerque', 'Miguel Rodovia, 10400, undefined Alessandra, AL',
        'mestrado');
INSERT INTO Pessoa
VALUES ('64313026478', '237571995495', 'Luiza Nogueira', 'Reis Avenida, 88005, Santos do Descoberto, AP',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('36500291242', '208783440454', 'Carla Nogueira', 'Souza Rua, 84724, South San Francisco, RO',
        'superior completo');
INSERT INTO Pessoa
VALUES ('43212705317', '968445985205', 'João Pedro Reis', 'Saraiva Avenida, 64636, Pietro do Descoberto, RO',
        'mestrado');
INSERT INTO Pessoa
VALUES ('92874572738', '946100006112', 'Marcos Costa', 'Silva Alameda, 47717, Isadora do Norte, AP',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('95325006309', '792739742132', 'Maria Luiza Braga', 'Maitê Rodovia, 53026, Maria Cecília do Norte, SC',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('80744732806', '336196530540', 'Miguel Santos', 'Silva Rodovia, 38550, undefined Marcela, DF',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('96818589621', '408508826699', 'Alice Macedo', 'Norberto Rodovia, 33728, undefined Vitória de Nossa Senhora, RO',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('13070944417', '434380913618', 'Aline Moraes', 'Martins Avenida, 61368, Bernardo do Norte, TO',
        'doutorado');
INSERT INTO Pessoa
VALUES ('18922563376', '740756552666', 'Feliciano Franco', 'Washington Rua, 64508, undefined Benjamin de Nossa Senhora, SP',
        'superior completo');
INSERT INTO Pessoa
VALUES ('27443005263', '603397362586', 'Isabela Barros', 'Macedo Avenida, 46595, Júlio César de Nossa Senhora, PI',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('21991884345', '890228564501', 'Ana Luiza Batista', 'Santos Rodovia, 91166, undefined Fabrício de Nossa Senhora, AC',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('43381068897', '279709586710', 'Ana Júlia Braga', 'Xavier Marginal, 53939, undefined Marli, RJ',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('86269439584', '812517797574', 'Paulo Barros', 'Raul Avenida, 10205, Alessandra do Descoberto, PI',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('82961410374', '783107456401', 'Valentina Carvalho', 'Pedro Rua, 14550, undefined Melissa, RS',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('32235214128', '938527807150', 'Isadora Souza', 'Fábio Travessa, 8908, Valentina de Nossa Senhora, PB',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('90251854406', '780502560385', 'Meire Xavier', 'Fabrícia Rodovia, 65665, Cicero, SP',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('99175420803', '254503870732', 'Caio Santos', 'Núbia Alameda, 37149, undefined Esther, PA',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('89975072103', '918147209379', 'Rebeca Barros', 'Costa Rodovia, 93834, Xavier de Nossa Senhora, PB',
        'superior completo');
INSERT INTO Pessoa
VALUES ('49878119379', '237655633897', 'Célia Carvalho', 'Mariana Alameda, 43525, undefined Clara do Descoberto, PA',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('56800358914', '212117036920', 'Yago Saraiva', 'Paula Rua, 44169, undefined Pablo, DF',
        'doutorado');
INSERT INTO Pessoa
VALUES ('34482197472', '889706734032', 'Murilo Batista', 'Macedo Rua, 80878, Sammamish, GO',
        'mestrado');
INSERT INTO Pessoa
VALUES ('22420991435', '332256695744', 'Kléber Batista', 'Pereira Avenida, 33119, undefined Danilo de Nossa Senhora, BA',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('11792162314', '143218632717', 'Célia Martins', 'César Rua, 57794, Franco do Norte, AP',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('41238485593', '305416313349', 'Núbia Carvalho', 'Silva Marginal, 12622, Scranton, MG',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('33077115302', '970995404128', 'Matheus Xavier', 'Albuquerque Travessa, 61599, Sirineu de Nossa Senhora, MT',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('99021190118', '111253332812', 'Helena Franco', 'Lorena Marginal, 19560, undefined Suélen, MA',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('78064916469', '731625387608', 'Ígor Melo', 'Franco Travessa, 67688, Midland, PA',
        'mestrado');
INSERT INTO Pessoa
VALUES ('32021542380', '585718815680', 'Benício Reis', 'Martins Marginal, 37823, Núbia do Descoberto, RS',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('12626151097', '425450804224', 'Vicente Santos', 'Benício Avenida, 40985, Lehi, AM',
        'superior completo');
INSERT INTO Pessoa
VALUES ('77011687273', '724353998387', 'Antônio Martins', 'Macedo Rua, 80916, Silva de Nossa Senhora, MA',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('60306908786', '428182555316', 'Matheus Carvalho', 'Albuquerque Rua, 73050, undefined Salvador do Sul, PA',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('52794275211', '224338543042', 'Lívia Braga', 'Martins Avenida, 49124, undefined Yuri, TO',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('92310514114', '708570432779', 'Antonella Pereira', 'Gustavo Rua, 36222, undefined Lucca do Descoberto, SP',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('39886607385', '205575631419', 'Félix Pereira', 'Macedo Avenida, 68556, undefined Gustavo, PB',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('90039808077', '164056372572', 'Ofélia Albuquerque', 'Maria Alice Travessa, 46737, Smyrna, RR',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('86525803739', '449092198070', 'Elisa Carvalho', 'Fabrícia Rodovia, 51991, undefined Danilo do Sul, RO',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('90588345301', '490374247170', 'Arthur Martins', 'Eloá Alameda, 58419, Memphis, PE',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('10616772223', '330403973488', 'Pablo Pereira', 'Maria Eduarda Marginal, 86293, Alícia de Nossa Senhora, RO',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('42666099744', '214030749886', 'Matheus Santos', 'Maria Luiza Rua, 69246, undefined Helena do Norte, ES',
        'mestrado');
INSERT INTO Pessoa
VALUES ('26367881237', '607584592397', 'César Batista', 'Franco Travessa, 97850, Silva do Sul, RN',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('61664271336', '856073189596', 'Marcela Martins', 'Giovanna Marginal, 40419, Kenosha, PB',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('69868170775', '227046087407', 'Elísio Oliveira', 'Clara Rodovia, 43775, Clovis, AM',
        'doutorado');
INSERT INTO Pessoa
VALUES ('87386788851', '590612037060', 'Davi Lucca Macedo', 'Eloá Marginal, 32750, Shoreline, CE',
        'mestrado');
INSERT INTO Pessoa
VALUES ('22700045653', '804450035979', 'Benjamin Saraiva', 'Giovanna Rodovia, 20270, Napa, MA',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('39015131085', '788489172584', 'Sophia Pereira', 'Ana Laura Alameda, 59150, Carla do Descoberto, AL',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('43031963950', '321755251917', 'Fabrícia Moraes', 'Nogueira Travessa, 75130, undefined Heloísa, RO',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('62047257632', '587653972906', 'Norberto Santos', 'Macedo Avenida, 46424, Nicolas do Norte, AP',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('86761833312', '681656934204', 'Núbia Barros', 'Sara Avenida, 5130, Saraiva do Descoberto, RO',
        'superior completo');
INSERT INTO Pessoa
VALUES ('84441573002', '133807401452', 'Ofélia Franco', 'Clara Marginal, 53369, Columbus, MS',
        'mestrado');
INSERT INTO Pessoa
VALUES ('48909591054', '677824481017', 'João Lucas Martins', 'Helena Marginal, 46840, undefined Cecília de Nossa Senhora, DF',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('27577754918', '557511352421', 'Mariana Costa', 'Albuquerque Travessa, 38906, Danilo de Nossa Senhora, AM',
        'superior completo');
INSERT INTO Pessoa
VALUES ('31817754048', '303194353799', 'Lorena Souza', 'Emanuel Rodovia, 34412, Franco de Nossa Senhora, RO',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('63150170790', '472789073619', 'Vitor Nogueira', 'Maria Helena Rua, 55486, Mesquite, BA',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('11138060991', '689508943306', 'Eloá Santos', 'Silva Marginal, 59813, undefined Ana Luiza, SP',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('48903583744', '476155856344', 'Gael Reis', 'Washington Rodovia, 56093, Lauderhill, MG',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('34049041755', '232121922587', 'Emanuel Saraiva', 'Isabela Rua, 3133, undefined Marina do Sul, CE',
        'superior completo');
INSERT INTO Pessoa
VALUES ('24291245951', '855112180300', 'Tertuliano Saraiva', 'Deneval Rodovia, 76789, Eduardo do Norte, AP',
        'mestrado');
INSERT INTO Pessoa
VALUES ('61250933664', '956396791106', 'Fabrício Moraes', 'Maria Júlia Rodovia, 29590, undefined Ana Laura, SC',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('47783979305', '386959672812', 'Gael Moreira', 'Fábio Marginal, 17, Ann Arbor, MG',
        'superior completo');
INSERT INTO Pessoa
VALUES ('85471168039', '920306191919', 'Elisa Oliveira', 'Eduardo Rodovia, 76193, Ames, BA',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('36024964263', '761450139712', 'Lucas Xavier', 'Antonella Avenida, 33028, undefined Marina do Norte, MT',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('46974461216', '232246125419', 'Suélen Martins', 'Mércia Avenida, 73106, undefined Roberto, MS',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('74856146364', '787735436647', 'Heitor Costa', 'Beatriz Rua, 66055, Martins do Descoberto, CE',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('63185736755', '694229562859', 'Bryan Melo', 'Silva Rua, 98377, undefined Rafaela, RJ',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('72898224287', '392503231810', 'Breno Macedo', 'Carvalho Rodovia, 96180, undefined Guilherme do Descoberto, MG',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('23752783061', '873045951966', 'Liz Saraiva', 'Enzo Gabriel Avenida, 18023, undefined Breno do Descoberto, RR',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('44094416738', '196076844260', 'Noah Oliveira', 'Martins Rua, 1136, undefined Daniel de Nossa Senhora, CE',
        'mestrado');
INSERT INTO Pessoa
VALUES ('11271613019', '269217502535', 'Meire Carvalho', 'Melo Rua, 77011, Batista de Nossa Senhora, ES',
        'mestrado');
INSERT INTO Pessoa
VALUES ('90722480562', '194308247603', 'Suélen Nogueira', 'Silva Avenida, 63191, undefined Aline, PR',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('70247840185', '476983819901', 'Maria Júlia Batista', 'Franco Marginal, 66247, Karla do Sul, PI',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('33628560900', '869548947154', 'Lucca Costa', 'Caio Travessa, 96548, undefined Meire, MG',
        'doutorado');
INSERT INTO Pessoa
VALUES ('72423329877', '313898925296', 'João Reis', 'Carvalho Travessa, 64181, undefined Emanuelly de Nossa Senhora, MS',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('30057355521', '671449624141', 'Víctor Carvalho', 'Braga Alameda, 98698, Oliveira de Nossa Senhora, SC',
        'doutorado');
INSERT INTO Pessoa
VALUES ('54887827818', '478936792025', 'Júlio César Souza', 'Franco Rodovia, 45863, undefined Emanuelly, MG',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('56150399090', '189412274444', 'Célia Braga', 'Moreira Marginal, 54714, undefined Pedro Henrique do Sul, PI',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('32271739926', '531240539206', 'Miguel Macedo', 'Albuquerque Rua, 52840, Braga do Descoberto, MT',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('57456171549', '475443033524', 'Lara Barros', 'Lavínia Avenida, 28409, Phoenix, MA',
        'doutorado');
INSERT INTO Pessoa
VALUES ('73494647324', '879163909796', 'Talita Santos', 'Gustavo Travessa, 11249, undefined Célia do Sul, RS',
        'superior completo');
INSERT INTO Pessoa
VALUES ('79950719017', '764479363500', 'Cecília Pereira', 'Braga Travessa, 96530, Waco, AC',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('70177465768', '246802303800', 'Benjamin Martins', 'Mariana Rua, 96710, undefined Célia, RR',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('47524044020', '677548666321', 'Nicolas Santos', 'Júlio Rua, 34172, Rebeca do Sul, PB',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('14247396097', '798114385455', 'Théo Carvalho', 'Dalila Travessa, 43694, Franco do Sul, SE',
        'doutorado');
INSERT INTO Pessoa
VALUES ('61750890677', '250301181967', 'Norberto Melo', 'Xavier Avenida, 95198, Célia do Descoberto, SC',
        'mestrado');
INSERT INTO Pessoa
VALUES ('16635875334', '118094787606', 'Daniel Pereira', 'Liz Rua, 10209, Madison, PB',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('88091845146', '723933051247', 'Júlia Franco', 'Mércia Rua, 13282, undefined Maria Clara, PB',
        'doutorado');
INSERT INTO Pessoa
VALUES ('72847558700', '929291120008', 'Matheus Souza', 'Elísio Rodovia, 39373, Nogueira do Descoberto, BA',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('32780581086', '961876898049', 'João Miguel Braga', 'Yuri Travessa, 54341, undefined Lucas de Nossa Senhora, AM',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('58621376936', '467522363434', 'Maria Alice Nogueira', 'Felipe Marginal, 72448, Riverview, PI',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('92353644056', '842922813119', 'Joana Souza', 'Santos Rodovia, 97179, Xavier do Sul, SP',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('50740862700', '532503788615', 'Ana Luiza Silva', 'Felipe Alameda, 19193, undefined Lívia, AC',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('42022861305', '428173057781', 'Elisa Melo', 'Macedo Avenida, 40220, undefined Mércia de Nossa Senhora, PR',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('93524363834', '258470540400', 'Elísio Reis', 'Barros Rodovia, 91067, undefined Laura, MS',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('41833977757', '171480330033', 'Mariana Silva', 'Esther Avenida, 14691, undefined Felipe do Norte, SC',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('25185088501', '151413460611', 'Heitor Martins', 'Pereira Marginal, 86217, Marina de Nossa Senhora, GO',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('29075196001', '992835858277', 'Ana Clara Nogueira', 'Gabriel Marginal, 63955, undefined Ofélia, AL',
        'superior completo');
INSERT INTO Pessoa
VALUES ('84795078553', '491293530305', 'Pedro Santos', 'Daniel Alameda, 45758, Concord, PE',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('55661978677', '891756572457', 'Víctor Xavier', 'Moraes Alameda, 81676, Portland, PR',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('39470596222', '750766942277', 'João Miguel Nogueira', 'Nogueira Travessa, 98905, Dalila do Norte, MS',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('12390054175', '930385363637', 'Carla Nogueira', 'Lara Travessa, 79804, Amarillo, SE',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('90003637734', '291949845245', 'Gúbio Reis', 'Rafael Rodovia, 87102, undefined Fábio, SC',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('12367218623', '230063088284', 'Antônio Pereira', 'Valentina Avenida, 93239, undefined Yago, PA',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('34451081710', '567966253845', 'Liz Carvalho', 'Silva Avenida, 95713, Yasmin do Descoberto, CE',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('34965334206', '792266672756', 'Helena Nogueira', 'João Miguel Rua, 11131, undefined Isadora do Norte, AM',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('92995127346', '216327629401', 'Júlia Costa', 'Xavier Rodovia, 33337, Macedo do Descoberto, MG',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('98058124845', '244554414204', 'Maria Cecília Saraiva', 'Santos Marginal, 52664, undefined Nataniel de Nossa Senhora, RJ',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('42148925778', '785619288985', 'Alice Xavier', 'Júlio César Travessa, 90394, undefined Cecília, RS',
        'mestrado');
INSERT INTO Pessoa
VALUES ('52877239394', '200254704989', 'Deneval Reis', 'Souza Avenida, 88834, Moreira do Sul, PR',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('44242360976', '308059474010', 'Emanuelly Xavier', 'Isadora Alameda, 97140, undefined Isabel do Descoberto, PA',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('56193133238', '162152203032', 'Emanuel Braga', 'Lucca Rodovia, 2771, Alice do Norte, PB',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('69644132792', '267246448551', 'Sara Carvalho', 'Albuquerque Marginal, 112, Pietro do Sul, SC',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('62654740172', '894303970085', 'Eduardo Souza', 'Ladislau Rodovia, 84015, Davi do Sul, ES',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('34712144928', '424726628116', 'Alexandre Melo', 'Matheus Avenida, 29806, Macedo de Nossa Senhora, MT',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('40792622072', '744460829370', 'Lucca Moraes', 'Moraes Rodovia, 34045, undefined Sophia de Nossa Senhora, AP',
        'doutorado');
INSERT INTO Pessoa
VALUES ('77116765116', '979808108415', 'Melissa Carvalho', 'Santos Marginal, 73637, Newport Beach, AM',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('80145377612', '154621622315', 'Janaína Pereira', 'Natália Avenida, 25898, undefined João Lucas do Norte, PR',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('64278458273', '104599023284', 'Lorena Carvalho', 'Giovanna Rua, 81658, undefined Marli de Nossa Senhora, RS',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('96162843727', '428168675303', 'Morgana Moreira', 'Moraes Avenida, 67118, undefined Maria Clara, ES',
        'superior completo');
INSERT INTO Pessoa
VALUES ('21325235543', '320246480219', 'Emanuel Albuquerque', 'Roberta Rua, 35891, undefined Ana Júlia do Norte, AL',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('63629505806', '456647963053', 'Antonella Batista', 'Lorenzo Rodovia, 73091, Jefferson City, PE',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('44973071531', '837099539744', 'Aline Martins', 'Ígor Rodovia, 3558, Barros do Sul, AM',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('86179116971', '463378344848', 'Eduardo Costa', 'Souza Rodovia, 49718, Liz do Sul, DF',
        'doutorado');
INSERT INTO Pessoa
VALUES ('85431055435', '635154137923', 'Dalila Franco', 'Hugo Alameda, 70086, Franco do Norte, PR',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('83423976283', '934439979167', 'Luiza Martins', 'Pereira Marginal, 91365, Talita de Nossa Senhora, MG',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('69957945945', '904766103206', 'Dalila Carvalho', 'Santos Travessa, 7820, Davi de Nossa Senhora, PE',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('91491590670', '442655284726', 'Janaína Moraes', 'Gael Marginal, 4260, undefined Rafaela, SP',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('27857613652', '898682155576', 'Arthur Xavier', 'Felipe Travessa, 50195, West Babylon, PA',
        'doutorado');
INSERT INTO Pessoa
VALUES ('86186453672', '154734321823', 'Meire Santos', 'Júlio César Rodovia, 63903, Macedo de Nossa Senhora, PA',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('52453071193', '506687186122', 'Fabiano Braga', 'Franco Rua, 93433, undefined Alessandra de Nossa Senhora, RN',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('67893272326', '677898157108', 'Gúbio Moreira', 'Gabriel Travessa, 25665, undefined Warley, AP',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('10729401176', '385979368374', 'Talita Silva', 'Silva Alameda, 45088, Saraiva do Sul, BA',
        'mestrado');
INSERT INTO Pessoa
VALUES ('57006225958', '514346729544', 'Leonardo Albuquerque', 'Félix Rodovia, 55196, Núbia do Norte, PB',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('86344928094', '111334844306', 'Natália Saraiva', 'Ricardo Rua, 26216, undefined Joana do Sul, CE',
        'mestrado');
INSERT INTO Pessoa
VALUES ('29649122953', '649002958904', 'Maria Eduarda Moraes', 'Yago Rua, 1293, Harrisburg, AM',
        'mestrado');
INSERT INTO Pessoa
VALUES ('39244721408', '933327215304', 'Lorenzo Costa', 'Reis Rua, 99854, undefined Marcelo, PE',
        'superior completo');
INSERT INTO Pessoa
VALUES ('29555345340', '118981327465', 'Márcia Saraiva', 'Helena Alameda, 94477, undefined Fabrício do Norte, MS',
        'mestrado');
INSERT INTO Pessoa
VALUES ('14154119554', '777384151890', 'Vitor Pereira', 'Albuquerque Marginal, 85107, Albany, ES',
        'superior completo');
INSERT INTO Pessoa
VALUES ('56126027428', '942811181372', 'Salvador Santos', 'Albuquerque Marginal, 19018, undefined Rafael, GO',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('99258126760', '133511063246', 'Isabel Reis', 'Júlio Travessa, 13413, undefined Antonella, PA',
        'mestrado');
INSERT INTO Pessoa
VALUES ('30614520721', '715608099964', 'Laura Santos', 'Santos Rua, 73529, Suélen do Sul, AM',
        'doutorado');
INSERT INTO Pessoa
VALUES ('12587690399', '119504619948', 'Ana Luiza Franco', 'Reis Rodovia, 21685, Barnstable Town, MS',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('89067652127', '428175682784', 'Fabrícia Braga', 'Saraiva Avenida, 56865, Daniel do Norte, RN',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('68096587185', '359650552179', 'Davi Lucca Albuquerque', 'Kléber Travessa, 79196, undefined Gúbio, MS',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('15216369207', '497514930879', 'Suélen Barros', 'Maria Luiza Alameda, 24462, Hugo do Norte, CE',
        'superior completo');
INSERT INTO Pessoa
VALUES ('29665019169', '332205748022', 'Cecília Silva', 'Carvalho Alameda, 54937, undefined Noah, BA',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('28974858648', '812516823387', 'Helena Souza', 'Pedro Marginal, 61030, undefined Lívia, AC',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('38653304902', '522249863226', 'Manuela Moreira', 'Nogueira Travessa, 62405, undefined Fabiano do Descoberto, PR',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('41530032556', '680300913890', 'Feliciano Carvalho', 'Félix Alameda, 51076, Lompoc, DF',
        'doutorado');
INSERT INTO Pessoa
VALUES ('89955552096', '537187053798', 'Joaquim Martins', 'Alessandra Rodovia, 66417, undefined Elísio, PA',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('85689289949', '526677969656', 'Paula Saraiva', 'Murilo Travessa, 45380, undefined Alessandra do Sul, RS',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('42809196475', '505047868378', 'Joaquim Reis', 'Feliciano Rua, 66086, Nogueira do Norte, AL',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('50013432025', '466530359536', 'Henrique Costa', 'Maria Travessa, 47376, Heitor de Nossa Senhora, PA',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('35013815364', '143338418495', 'Natália Carvalho', 'Macedo Rodovia, 59715, Cauã de Nossa Senhora, AL',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('77360690359', '156512497947', 'Isis Santos', 'Maria Clara Avenida, 54836, undefined Elisa do Sul, AL',
        'superior completo');
INSERT INTO Pessoa
VALUES ('14297463551', '194136728090', 'Vicente Barros', 'Júlia Travessa, 32638, undefined Leonardo, PI',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('66122044045', '848123200028', 'João Pedro Silva', 'Melo Rodovia, 75201, undefined Bruna do Sul, ES',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('71934199538', '688957743905', 'Núbia Souza', 'Sarah Alameda, 26723, undefined Maitê do Descoberto, SP',
        'doutorado');
INSERT INTO Pessoa
VALUES ('74868324829', '389832879207', 'Bruna Souza', 'Leonardo Rodovia, 34937, Natália do Sul, PR',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('46404720542', '804020790755', 'Janaína Franco', 'Janaína Alameda, 39914, Braga de Nossa Senhora, MT',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('57755531829', '697372316173', 'Paula Melo', 'Paula Alameda, 39063, Antioch, RN',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('95659425617', '112735330197', 'Yago Melo', 'Carvalho Avenida, 56791, Kalamazoo, PE',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('87744765498', '460060678189', 'Rafaela Xavier', 'Nogueira Alameda, 23250, undefined João Miguel do Norte, SC',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('28691501056', '939208484953', 'Víctor Santos', 'Clara Travessa, 46114, Deneval do Norte, PA',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('98220638674', '865183057915', 'Enzo Xavier', 'Melo Marginal, 80251, Alexandre do Sul, RN',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('58115882335', '547426935518', 'Tertuliano Martins', 'Barros Marginal, 57111, undefined Calebe do Sul, MA',
        'mestrado');
INSERT INTO Pessoa
VALUES ('74929202487', '739852532767', 'Yago Pereira', 'Esther Travessa, 2119, undefined Margarida de Nossa Senhora, TO',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('99621701030', '944423917797', 'Yuri Santos', 'Luiza Rua, 121, Carvalho de Nossa Senhora, GO',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('73786580944', '686387197766', 'Elisa Carvalho', 'Heloísa Avenida, 72072, undefined Sophia de Nossa Senhora, DF',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('30063241985', '810372258140', 'Ana Clara Santos', 'Samuel Marginal, 18895, Saginaw, RS',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('45365409015', '448161508841', 'Hélio Reis', 'Pedro Avenida, 23673, undefined João Miguel, RR',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('38951155769', '581825942802', 'Norberto Barros', 'Feliciano Avenida, 79374, Santos do Sul, TO',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('78491106405', '778779076389', 'Benjamin Oliveira', 'Franco Marginal, 72962, Evanston, AC',
        'mestrado');
INSERT INTO Pessoa
VALUES ('19756374296', '431564388587', 'Alessandra Pereira', 'Carvalho Avenida, 63542, undefined Hélio do Descoberto, GO',
        'superior completo');
INSERT INTO Pessoa
VALUES ('56817372397', '777457891474', 'Roberta Santos', 'Reis Travessa, 5868, Barros do Descoberto, RN',
        'doutorado');
INSERT INTO Pessoa
VALUES ('98326434637', '722666174359', 'Márcia Carvalho', 'Nataniel Rua, 88886, Esther do Norte, RJ',
        'mestrado');
INSERT INTO Pessoa
VALUES ('73610341141', '825447643036', 'Cauã Pereira', 'Silva Rodovia, 99169, Enzo do Descoberto, AM',
        'doutorado');
INSERT INTO Pessoa
VALUES ('64592013116', '643584023299', 'Matheus Saraiva', 'Braga Alameda, 74913, undefined Liz, TO',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('52366501996', '434184607560', 'Marli Carvalho', 'Melo Rodovia, 97798, Víctor do Norte, RO',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('65505142740', '693118486064', 'Aline Saraiva', 'Albuquerque Rua, 84723, Anderson, RR',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('24567704398', '112520820531', 'Isaac Santos', 'Melo Travessa, 79794, Ofélia do Norte, RR',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('92796421276', '297022685152', 'Sirineu Santos', 'Enzo Rua, 10572, undefined Feliciano, CE',
        'doutorado');
INSERT INTO Pessoa
VALUES ('72196090049', '211651269230', 'Víctor Moreira', 'Moraes Rodovia, 757, Joaquim do Sul, MS',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('94086229731', '625663347519', 'Breno Carvalho', 'Costa Rodovia, 25404, undefined Heloísa, AL',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('46951443084', '626286006206', 'João Miguel Nogueira', 'Yago Alameda, 56369, Auburn, RS',
        'doutorado');
INSERT INTO Pessoa
VALUES ('23579627191', '925128574273', 'Cecília Nogueira', 'Souza Rodovia, 52384, Costa do Norte, DF',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('24722674724', '299795042793', 'Ofélia Moreira', 'Hélio Rua, 90478, Marli do Descoberto, MA',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('68928154059', '385983162443', 'Eduardo Batista', 'Davi Lucca Marginal, 20158, Fabrícia de Nossa Senhora, PB',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('87348033047', '912624335032', 'Ladislau Oliveira', 'Isis Rua, 85778, Maria do Sul, AL',
        'doutorado');
INSERT INTO Pessoa
VALUES ('69263624604', '443897538515', 'Breno Melo', 'Carvalho Alameda, 34567, Mount Vernon, PB',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('62333358894', '969133020262', 'Yasmin Xavier', 'Oliveira Rodovia, 27261, Palm Beach Gardens, MS',
        'superior completo');
INSERT INTO Pessoa
VALUES ('68440822518', '142954959627', 'Sarah Carvalho', 'Talita Marginal, 49311, Franco do Descoberto, SE',
        'doutorado');
INSERT INTO Pessoa
VALUES ('53815103929', '629813096811', 'Clara Batista', 'Ana Júlia Marginal, 40366, undefined Marina, AP',
        'superior completo');
INSERT INTO Pessoa
VALUES ('71007887653', '929152153711', 'Fabiano Martins', 'Saraiva Avenida, 53777, undefined Cecília de Nossa Senhora, AL',
        'doutorado');
INSERT INTO Pessoa
VALUES ('28437440353', '242190983425', 'Gustavo Oliveira', 'Rebeca Marginal, 58618, Breno do Sul, PI',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('41570859046', '729323670687', 'Bruna Moraes', 'Carvalho Rodovia, 61309, Nicolas do Sul, CE',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('44770700223', '619398196763', 'Márcia Silva', 'Paula Rodovia, 7879, undefined Clara do Norte, MG',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('57093701930', '768054638942', 'Alexandre Albuquerque', 'Lucas Alameda, 39784, Alícia de Nossa Senhora, DF',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('23646102703', '738454343308', 'Yasmin Souza', 'Saraiva Avenida, 7986, undefined Guilherme de Nossa Senhora, MG',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('28406533049', '258566624461', 'Lorena Oliveira', 'Sirineu Avenida, 73863, undefined Pedro, RR',
        'mestrado');
INSERT INTO Pessoa
VALUES ('35535540033', '943725387798', 'Calebe Melo', 'Carvalho Avenida, 39519, undefined Sarah, MS',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('61570064800', '466457101283', 'Fabiano Moraes', 'Vitor Alameda, 42972, undefined Maria, ES',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('64179538718', '170326859247', 'Ana Júlia Braga', 'Lorenzo Marginal, 46103, Raul do Sul, RR',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('57362485802', '772793528740', 'Roberta Melo', 'Batista Travessa, 30170, undefined Salvador, AM',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('41701333993', '885961797973', 'Natália Moreira', 'Xavier Alameda, 8571, Rowlett, RO',
        'superior completo');
INSERT INTO Pessoa
VALUES ('16630750785', '134820059197', 'Elísio Martins', 'Albuquerque Alameda, 27962, undefined Fabrícia do Norte, RJ',
        'doutorado');
INSERT INTO Pessoa
VALUES ('24563835521', '177193297562', 'Isadora Xavier', 'Braga Marginal, 77577, East Los Angeles, AC',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('47509506070', '342807775526', 'Isaac Souza', 'Moreira Travessa, 5144, undefined Isabel de Nossa Senhora, RN',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('45841697754', '500931441551', 'Enzo Martins', 'Reis Marginal, 76957, Sirineu do Sul, MA',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('52920149751', '648941167723', 'Eloá Saraiva', 'Costa Rodovia, 51282, Danville, PB',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('21012337736', '518503779475', 'Bryan Braga', 'Yasmin Rodovia, 14912, Albuquerque do Sul, AP',
        'superior completo');
INSERT INTO Pessoa
VALUES ('80703236414', '952838425734', 'Yuri Xavier', 'Barros Marginal, 30092, Chicago, PR',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('62067907205', '753782600164', 'Maria Eduarda Saraiva', 'Deneval Marginal, 2995, Maria Cecília do Descoberto, PA',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('95178695621', '490863100299', 'Fábio Franco', 'Batista Rodovia, 74268, undefined Feliciano de Nossa Senhora, PA',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('69472774860', '125724337436', 'Benício Costa', 'Macedo Rodovia, 44841, Bellflower, RJ',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('76313567715', '907852202816', 'Ígor Carvalho', 'Braga Travessa, 7817, Portland, BA',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('44911381667', '291675653913', 'Beatriz Barros', 'Ana Laura Rodovia, 58733, Maitê do Norte, TO',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('54743101750', '916719039110', 'Joaquim Braga', 'Samuel Avenida, 46329, Lynwood, RJ',
        'doutorado');
INSERT INTO Pessoa
VALUES ('80001908850', '264559706393', 'Sophia Reis', 'Carvalho Rodovia, 77040, undefined Yago, ES',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('72085512168', '616902515478', 'Sara Xavier', 'Márcia Rua, 93961, Melo do Norte, PB',
        'superior completo');
INSERT INTO Pessoa
VALUES ('18336009925', '520549830747', 'Maria Eduarda Oliveira', 'Martins Rodovia, 35883, Eloá do Descoberto, AC',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('75698780661', '317833915562', 'Isis Melo', 'Barros Rodovia, 74888, Cleveland, DF',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('96217219165', '465198233723', 'Sirineu Santos', 'Moreira Avenida, 79232, Moreira de Nossa Senhora, AM',
        'superior completo');
INSERT INTO Pessoa
VALUES ('31668141162', '123360452777', 'Beatriz Braga', 'Emanuelly Rodovia, 1238, Nogueira do Sul, PE',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('39781806061', '145557960285', 'Roberto Franco', 'Rafael Rodovia, 32359, Albuquerque do Descoberto, RO',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('42436610548', '443891591345', 'Elísio Carvalho', 'Bruna Avenida, 40579, Melo do Descoberto, PR',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('29479615306', '296623584185', 'Isabela Martins', 'Reis Rua, 24475, Costa do Norte, RJ',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('53773475124', '758937271754', 'Célia Saraiva', 'Caio Travessa, 15591, Marcela do Sul, RN',
        'superior completo');
INSERT INTO Pessoa
VALUES ('83016668260', '445122652151', 'Júlio César Reis', 'Costa Alameda, 17966, Vancouver, SC',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('61978392985', '714559050719', 'Bernardo Carvalho', 'Silva Travessa, 69898, Austin, TO',
        'mestrado');
INSERT INTO Pessoa
VALUES ('44453197566', '337315845699', 'Cecília Franco', 'Carvalho Marginal, 11678, undefined Gúbio do Norte, DF',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('97664171834', '524944653059', 'Ofélia Souza', 'Mariana Rodovia, 48002, Maria Eduarda de Nossa Senhora, RJ',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('91695537378', '433008863544', 'Eduarda Carvalho', 'Costa Rua, 86115, Stockton, SE',
        'superior completo');
INSERT INTO Pessoa
VALUES ('13218261646', '875160108297', 'Marcos Silva', 'Murilo Alameda, 42370, Cincinnati, SP',
        'superior completo');
INSERT INTO Pessoa
VALUES ('69042728620', '907335648755', 'Danilo Melo', 'Macedo Avenida, 7561, Nogueira do Norte, AL',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('13409115150', '956171114020', 'Fabrícia Carvalho', 'Oliveira Rodovia, 67404, undefined Antonella, PR',
        'doutorado');
INSERT INTO Pessoa
VALUES ('79418088067', '237570820352', 'Salvador Martins', 'Carla Travessa, 32525, Benjamin do Descoberto, MA',
        'doutorado');
INSERT INTO Pessoa
VALUES ('80777933001', '489661583397', 'Maria Luiza Carvalho', 'Núbia Travessa, 66029, Bellingham, TO',
        'doutorado');
INSERT INTO Pessoa
VALUES ('34317429289', '884986514714', 'Davi Lucca Santos', 'Martins Rodovia, 36269, undefined Pedro Henrique, GO',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('41203180619', '549566138023', 'Maria Costa', 'Melo Marginal, 86276, Felícia do Norte, RJ',
        'doutorado');
INSERT INTO Pessoa
VALUES ('58712847996', '741645507561', 'Sirineu Moreira', 'Fabrício Rodovia, 64385, undefined Lorenzo, RR',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('16354246530', '217916323174', 'Washington Barros', 'Felipe Alameda, 52939, Mount Pleasant, RJ',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('80961511202', '712307654554', 'Antonella Silva', 'Alícia Travessa, 42321, undefined Isabella, RO',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('38918710805', '898583353473', 'Cecília Saraiva', 'João Travessa, 86264, Greensboro, PA',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('13293680355', '691549182566', 'Paulo Carvalho', 'Oliveira Travessa, 73752, Braga de Nossa Senhora, MT',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('86202337315', '958872283948', 'Silas Silva', 'Roberto Alameda, 64046, Eduarda do Descoberto, GO',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('96834017981', '877007016446', 'Nataniel Saraiva', 'Hélio Marginal, 48643, Lowell, SP',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('87312114937', '791417820658', 'Cauã Batista', 'Moraes Travessa, 94575, Nogueira do Sul, RJ',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('84145448263', '701134019182', 'João Miguel Souza', 'Xavier Alameda, 84295, undefined Antônio, RS',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('27809734062', '366653963993', 'Liz Barros', 'Núbia Rua, 13513, Carvalho de Nossa Senhora, AP',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('10190151415', '366770569048', 'Frederico Batista', 'Pereira Travessa, 94712, undefined Fábio do Sul, MG',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('65601518931', '624550651130', 'Lívia Braga', 'Carvalho Alameda, 10005, Roberta do Norte, PI',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('71713188239', '907175098848', 'Emanuelly Nogueira', 'Moreira Alameda, 6676, undefined Suélen, SE',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('65745125890', '961640242976', 'Benício Pereira', 'Carvalho Marginal, 74098, Maria Helena do Descoberto, RS',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('10297100099', '256254894100', 'Eduardo Braga', 'Melo Avenida, 7860, McAllen, MA',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('28583832178', '549147855699', 'Guilherme Carvalho', 'Calebe Marginal, 73590, Vitor do Sul, RR',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('67668265667', '389816710934', 'Maria Alice Martins', 'Silva Travessa, 49832, Melo de Nossa Senhora, SE',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('31901904270', '412890531751', 'Warley Nogueira', 'Pereira Alameda, 84830, undefined João Pedro do Descoberto, MT',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('27553708830', '579575298493', 'Samuel Saraiva', 'Oliveira Rua, 24525, Felipe do Sul, GO',
        'superior completo');
INSERT INTO Pessoa
VALUES ('97844949536', '860502302483', 'Marcela Moreira', 'Antônio Rua, 2257, undefined Henrique, AL',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('27781179496', '953957336465', 'Lucca Santos', 'Samuel Avenida, 40890, Boston, MT',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('87366192734', '382714473339', 'Karla Carvalho', 'Santos Alameda, 70632, undefined Lavínia, MS',
        'doutorado');
INSERT INTO Pessoa
VALUES ('29610695552', '436964404769', 'Mariana Moreira', 'Braga Rua, 88199, Elisa do Norte, PI',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('58672425325', '225278090476', 'Larissa Barros', 'Fabiano Rodovia, 36286, undefined Lorraine do Sul, PA',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('12393648503', '288497183844', 'Ana Luiza Moreira', 'Melo Rodovia, 46860, undefined Calebe do Sul, DF',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('50989122078', '330187027412', 'Suélen Nogueira', 'Suélen Marginal, 15040, Silva do Descoberto, PE',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('39996799803', '105698265042', 'Ricardo Melo', 'Xavier Avenida, 68395, Florin, CE',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('31269832097', '846604736545', 'Ricardo Oliveira', 'Enzo Marginal, 70665, undefined Enzo, PI',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('64255168652', '304590237606', 'Benício Carvalho', 'Franco Marginal, 81223, undefined Júlio do Norte, DF',
        'superior completo');
INSERT INTO Pessoa
VALUES ('48286474652', '531324984366', 'Vicente Albuquerque', 'Oliveira Travessa, 76685, Bel Air South, AL',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('98107159230', '274971513310', 'Heitor Pereira', 'Davi Lucca Marginal, 64757, Palm Harbor, PB',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('15567308135', '749327697418', 'Yango Carvalho', 'Maria Luiza Rodovia, 73037, undefined Víctor do Sul, GO',
        'doutorado');
INSERT INTO Pessoa
VALUES ('12836654633', '169842698308', 'Félix Santos', 'Antonella Alameda, 63372, Moraes do Descoberto, ES',
        'superior completo');
INSERT INTO Pessoa
VALUES ('74306043400', '346517073619', 'Caio Santos', 'Gúbio Avenida, 96973, Salvador do Norte, BA',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('63777786765', '948393699456', 'Davi Braga', 'Reis Travessa, 62212, Braga do Norte, CE',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('37049869918', '208853512117', 'Fabrício Xavier', 'Oliveira Travessa, 69613, undefined Célia de Nossa Senhora, RO',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('12377018178', '196223395550', 'Salvador Martins', 'Isaac Marginal, 70565, undefined Morgana, BA',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('69556537419', '704051453946', 'Cauã Souza', 'Pablo Alameda, 99786, undefined Félix de Nossa Senhora, ES',
        'mestrado');
INSERT INTO Pessoa
VALUES ('30003875982', '137573740282', 'Núbia Barros', 'Roberta Marginal, 47330, undefined Hélio, PE',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('10555255529', '167704601795', 'Talita Souza', 'Macedo Avenida, 41573, Pedro Henrique do Norte, AL',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('32502407345', '936368690710', 'Mércia Nogueira', 'Marina Travessa, 42637, undefined Emanuelly do Descoberto, AL',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('77198284929', '123539201682', 'Júlio César Carvalho', 'Beatriz Marginal, 97381, Xavier do Descoberto, AL',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('75472573232', '661149735958', 'Valentina Souza', 'João Lucas Travessa, 46456, Rafael do Descoberto, DF',
        'doutorado');
INSERT INTO Pessoa
VALUES ('32333718526', '743270084890', 'Clara Xavier', 'Martins Rodovia, 51854, undefined Roberto, MT',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('76037732714', '151226059067', 'Valentina Batista', 'Xavier Rodovia, 93691, Nogueira do Descoberto, TO',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('73656134139', '475654201535', 'Ana Laura Carvalho', 'Costa Alameda, 25634, undefined César de Nossa Senhora, MS',
        'doutorado');
INSERT INTO Pessoa
VALUES ('37029771979', '844461554940', 'Pietro Barros', 'Ana Luiza Alameda, 87842, Melo de Nossa Senhora, SE',
        'mestrado');
INSERT INTO Pessoa
VALUES ('46141128463', '234634814225', 'Matheus Moreira', 'Carvalho Rodovia, 59098, undefined Natália, MT',
        'doutorado');
INSERT INTO Pessoa
VALUES ('45949940583', '417169500654', 'Rafael Franco', 'Santos Travessa, 78123, Lara do Norte, TO',
        'superior completo');
INSERT INTO Pessoa
VALUES ('51767491549', '844678569538', 'Mércia Nogueira', 'Costa Rodovia, 51395, Carla do Descoberto, CE',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('90751582509', '257378133037', 'Cauã Melo', 'Nicolas Alameda, 8672, Albuquerque do Norte, BA',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('19354682923', '923250926542', 'Maria Júlia Costa', 'Melo Avenida, 47492, Rock Hill, MG',
        'mestrado');
INSERT INTO Pessoa
VALUES ('69316593371', '632538307085', 'Alice Carvalho', 'Franco Rua, 58995, undefined Elísio do Sul, GO',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('20324891002', '981362826353', 'Emanuelly Carvalho', 'Costa Alameda, 39166, undefined Hélio de Nossa Senhora, SP',
        'superior completo');
INSERT INTO Pessoa
VALUES ('28458227536', '872744272393', 'Meire Martins', 'Xavier Rua, 83611, Clara de Nossa Senhora, RS',
        'mestrado');
INSERT INTO Pessoa
VALUES ('64118797685', '181517280219', 'Maria Cecília Costa', 'Franco Avenida, 14906, undefined Aline, GO',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('32866277098', '759345242241', 'Heloísa Macedo', 'Costa Travessa, 15363, Saraiva de Nossa Senhora, PE',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('11296014750', '610575183993', 'Félix Silva', 'Ricardo Travessa, 36112, Matheus do Sul, PE',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('89959186364', '747305068536', 'Rafael Barros', 'Cecília Travessa, 69293, Aline do Descoberto, MT',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('26499034971', '922948749712', 'Helena Saraiva', 'Costa Avenida, 35066, Alícia de Nossa Senhora, ES',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('92002684760', '981095189042', 'Emanuel Macedo', 'Franco Travessa, 81038, Spokane Valley, PB',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('40396111428', '889525691629', 'Larissa Macedo', 'Silva Marginal, 81448, undefined Alessandro do Norte, PA',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('52037642614', '196952164941', 'Suélen Xavier', 'Macedo Travessa, 95274, undefined Júlia, RN',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('98420247789', '114391068927', 'Ofélia Martins', 'Martins Travessa, 44674, undefined Carlos, DF',
        'doutorado');
INSERT INTO Pessoa
VALUES ('40150557057', '684975612768', 'Marli Silva', 'Braga Rodovia, 86778, undefined Sirineu do Norte, PE',
        'superior completo');
INSERT INTO Pessoa
VALUES ('74158802132', '581919863284', 'Marcelo Carvalho', 'Moreira Travessa, 11300, Utica, AL',
        'superior completo');
INSERT INTO Pessoa
VALUES ('41031348041', '358478528261', 'Benjamin Carvalho', 'Clara Rua, 94884, Souza do Norte, GO',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('38843407263', '847471861820', 'Kléber Carvalho', 'Moraes Alameda, 27875, Isaac do Sul, RR',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('37662852117', '371237137517', 'Manuela Moreira', 'Souza Alameda, 36247, undefined Théo, MS',
        'mestrado');
INSERT INTO Pessoa
VALUES ('23571120649', '304195885825', 'Lucas Macedo', 'Braga Alameda, 76050, Ceres, RR',
        'mestrado');
INSERT INTO Pessoa
VALUES ('86721126118', '782273619435', 'Pedro Xavier', 'Marli Rodovia, 45226, undefined Yuri, TO',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('87208565492', '986155237955', 'Nataniel Costa', 'Barros Marginal, 55525, Pereira de Nossa Senhora, TO',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('54175896581', '397669087164', 'Dalila Franco', 'Marcelo Marginal, 23757, Fountainebleau, SC',
        'doutorado');
INSERT INTO Pessoa
VALUES ('80985354657', '398315163212', 'Sophia Martins', 'Sílvia Rua, 52556, undefined Isabella do Descoberto, PI',
        'mestrado');
INSERT INTO Pessoa
VALUES ('56881690993', '577979606669', 'Salvador Souza', 'Franco Rua, 27495, undefined Alícia do Descoberto, MS',
        'mestrado');
INSERT INTO Pessoa
VALUES ('64449079392', '502279927162', 'Helena Xavier', 'Rafael Rodovia, 81657, Apple Valley, PE',
        'superior completo');
INSERT INTO Pessoa
VALUES ('15007094920', '552092216070', 'João Miguel Albuquerque', 'Lorena Rodovia, 2739, undefined César do Sul, PA',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('24966265256', '767026470485', 'Maria Souza', 'Feliciano Alameda, 44225, Kalamazoo, RR',
        'superior completo');
INSERT INTO Pessoa
VALUES ('27393568651', '226788864610', 'Eduarda Saraiva', 'Oliveira Rua, 1520, Silva de Nossa Senhora, MG',
        'mestrado');
INSERT INTO Pessoa
VALUES ('43068155143', '100568838277', 'Hélio Moreira', 'Braga Rua, 10600, Saginaw, ES',
        'superior completo');
INSERT INTO Pessoa
VALUES ('14172927623', '816287583881', 'Benjamin Santos', 'Barros Rua, 6567, Fountain Valley, PR',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('52849328536', '783904513157', 'Gael Batista', 'Miguel Rua, 5866, undefined Silas de Nossa Senhora, AC',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('15525305538', '681212806282', 'Suélen Batista', 'Saraiva Travessa, 28469, Kléber do Descoberto, MS',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('38096104059', '457587124919', 'Felícia Macedo', 'Eduardo Rua, 96979, St. Cloud, MT',
        'mestrado');
INSERT INTO Pessoa
VALUES ('93052325244', '443846513261', 'Ana Clara Martins', 'Martins Marginal, 80020, Moraes do Descoberto, PE',
        'mestrado');
INSERT INTO Pessoa
VALUES ('78014859156', '591949809971', 'Maria Alice Xavier', 'Ofélia Rua, 35203, Nogueira do Descoberto, RS',
        'superior completo');
INSERT INTO Pessoa
VALUES ('33585029381', '909991954755', 'Rebeca Moraes', 'Martins Rua, 16018, Santos do Descoberto, AL',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('47134191666', '298525359015', 'Joaquim Pereira', 'Albuquerque Alameda, 80869, undefined Rafael de Nossa Senhora, SE',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('55815897535', '909943281044', 'Joana Melo', 'Víctor Alameda, 64963, Moraes do Descoberto, BA',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('42855953916', '868102531367', 'Paula Batista', 'Reis Avenida, 48907, Emanuelly do Descoberto, PE',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('57690196863', '186150021385', 'Dalila Carvalho', 'Giovanna Rua, 27739, Saraiva do Norte, RN',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('86271196368', '764083004882', 'Júlia Batista', 'Valentina Marginal, 31140, Bryan do Norte, MA',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('83225498516', '982434464828', 'Maria Martins', 'Pablo Rua, 42577, Everett, AP',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('75320973584', '627159905945', 'Roberta Silva', 'Moreira Rodovia, 22753, Oliveira de Nossa Senhora, MA',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('83326663854', '392501030093', 'Miguel Macedo', 'Pereira Avenida, 73839, Júlia de Nossa Senhora, PR',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('71301379678', '457958557433', 'Ana Luiza Souza', 'Braga Rodovia, 45108, Carla do Sul, PI',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('71902848579', '556798260333', 'Emanuel Carvalho', 'Júlio Marginal, 86001, Souza do Norte, AC',
        'doutorado');
INSERT INTO Pessoa
VALUES ('54582723022', '629961991682', 'Feliciano Saraiva', 'Moreira Travessa, 80260, Macedo do Norte, AL',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('17000984330', '750245737307', 'Lavínia Reis', 'Xavier Avenida, 84047, Ana Júlia de Nossa Senhora, AM',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('19962675774', '562797577353', 'Felipe Braga', 'Carvalho Marginal, 8257, Fabiano do Norte, AL',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('17060522225', '979264816502', 'Gúbio Macedo', 'Costa Avenida, 34099, Silas de Nossa Senhora, RO',
        'mestrado');
INSERT INTO Pessoa
VALUES ('90046827753', '773096598032', 'Frederico Moraes', 'Costa Travessa, 54075, undefined Calebe, RS',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('64122301510', '972035138984', 'João Lucas Santos', 'Lucas Marginal, 52718, undefined Marcela, DF',
        'mestrado');
INSERT INTO Pessoa
VALUES ('72005313155', '298828581278', 'Washington Oliveira', 'Isis Rua, 60524, Sunnyvale, BA',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('15346407331', '597556032915', 'Feliciano Carvalho', 'Silva Marginal, 60728, Tucson, PA',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('21997365166', '518215671880', 'Liz Franco', 'Eduarda Rua, 94177, undefined Melissa, AM',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('40690805627', '726798355393', 'Liz Silva', 'Albuquerque Marginal, 45109, Heloísa do Descoberto, TO',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('49472601814', '531932009337', 'Lorena Martins', 'Martins Alameda, 20701, Guilherme de Nossa Senhora, PA',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('71410878263', '848143802117', 'João Miguel Oliveira', 'Batista Marginal, 99805, Asheville, SC',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('47806147113', '881218679505', 'Marina Souza', 'Washington Alameda, 22864, Tuckahoe, GO',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('94784048316', '710716453124', 'Miguel Moraes', 'Antonella Rua, 65592, Barros do Sul, MG',
        'superior completo');
INSERT INTO Pessoa
VALUES ('24243827324', '938209954486', 'Dalila Oliveira', 'Mariana Travessa, 47561, Dunwoody, RR',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('48470564924', '995291306218', 'Valentina Oliveira', 'Marcela Travessa, 92530, undefined Janaína, BA',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('97542159403', '467991617997', 'Gustavo Pereira', 'Barros Travessa, 76068, Martins do Sul, SE',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('57989361614', '273892747284', 'Lívia Carvalho', 'Vitória Avenida, 43733, Macedo do Descoberto, MT',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('93187630493', '422610549186', 'Maria Pereira', 'Warley Rua, 78076, Sioux City, RR',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('64684924166', '471212319866', 'Lavínia Reis', 'Moraes Alameda, 29466, undefined Rafaela do Descoberto, SP',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('65832432862', '255386496242', 'Isabelly Oliveira', 'Santos Travessa, 64470, Martins do Descoberto, PE',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('29543020694', '451255022245', 'Isis Reis', 'Souza Travessa, 92787, Roberta de Nossa Senhora, SC',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('24890993377', '652684769174', 'Guilherme Nogueira', 'Xavier Marginal, 34447, undefined Antônio, MA',
        'superior completo');
INSERT INTO Pessoa
VALUES ('59303166514', '929018916864', 'Natália Albuquerque', 'Felícia Rua, 54065, Mércia do Descoberto, MS',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('24653057004', '887143680686', 'Maitê Xavier', 'Santos Travessa, 99593, undefined Marina, PR',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('96953084403', '104911017837', 'Melissa Barros', 'Silva Alameda, 31116, Saraiva do Descoberto, RJ',
        'doutorado');
INSERT INTO Pessoa
VALUES ('65871269844', '125313598406', 'Norberto Carvalho', 'Nogueira Avenida, 64496, undefined Meire, RR',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('26077215422', '462892476934', 'Marli Reis', 'Sílvia Avenida, 58240, Appleton, RO',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('53850071197', '812663067271', 'Carla Carvalho', 'Macedo Marginal, 48026, Souza de Nossa Senhora, GO',
        'mestrado');
INSERT INTO Pessoa
VALUES ('89630639564', '775627036974', 'Karla Reis', 'Santos Marginal, 11496, Springfield, SC',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('24822467043', '832886845502', 'Warley Braga', 'Natália Marginal, 6066, Lucca do Norte, MS',
        'superior completo');
INSERT INTO Pessoa
VALUES ('24302018939', '877821774943', 'Suélen Batista', 'Reis Alameda, 19472, undefined Sirineu do Descoberto, SC',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('52205724709', '958562860544', 'Hugo Martins', 'Félix Marginal, 37635, Carvalho do Norte, DF',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('85063207736', '307673415285', 'Ana Luiza Costa', 'Joaquim Alameda, 90019, Raul do Descoberto, PB',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('44908207063', '900043968204', 'Carlos Franco', 'Pedro Henrique Alameda, 48293, undefined Gustavo, PI',
        'superior completo');
INSERT INTO Pessoa
VALUES ('30624507255', '515652909176', 'Cauã Oliveira', 'Melo Travessa, 9707, undefined Kléber, BA',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('58935807752', '337816211162', 'Yuri Nogueira', 'Vitor Rua, 49605, Franco de Nossa Senhora, PA',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('73679764212', '306346130860', 'Maria Cecília Pereira', 'Albuquerque Travessa, 11505, undefined Frederico de Nossa Senhora, AP',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('53190602837', '539968231925', 'Samuel Moraes', 'Batista Alameda, 5489, undefined Melissa, DF',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('89536202107', '954419398726', 'Maria Cecília Souza', 'Silva Alameda, 8339, Murfreesboro, AP',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('63614471920', '404859745036', 'Célia Albuquerque', 'Macedo Rodovia, 78610, East Los Angeles, RR',
        '2 grau completo');
INSERT INTO Pessoa
VALUES ('51938838479', '729468836449', 'Natália Oliveira', 'Martins Rodovia, 81056, Glendora, PI',
        'mestrado');
INSERT INTO Pessoa
VALUES ('43316695608', '932543696369', 'Danilo Nogueira', 'João Lucas Avenida, 3345, undefined João Miguel, PB',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('49645626486', '150711673614', 'Giovanna Reis', 'Benício Avenida, 21403, Alícia de Nossa Senhora, SP',
        'mestrado');
INSERT INTO Pessoa
VALUES ('39180499266', '650091061531', 'Yuri Melo', 'Noah Rua, 71414, undefined Roberto, CE',
        'doutorado');
INSERT INTO Pessoa
VALUES ('53504122414', '433865654352', 'Beatriz Albuquerque', 'Barros Rua, 48038, undefined Isabel do Sul, RN',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('20341535366', '743065347895', 'Yango Batista', 'Moreira Marginal, 25814, undefined Nicolas do Norte, PB',
        '2 grau incompleto');
INSERT INTO Pessoa
VALUES ('56464298493', '846443330007', 'Ricardo Franco', 'Gúbio Avenida, 28455, Carvalho do Descoberto, BA',
        'mestrado');
INSERT INTO Pessoa
VALUES ('83590763018', '388894560141', 'Yuri Albuquerque', 'Moreira Rua, 58221, undefined Pietro do Norte, MA',
        'superior incompleto');
INSERT INTO Pessoa
VALUES ('30618227072', '359070810931', 'Joaquim Moraes', 'Reis Alameda, 79621, Tyler, PB',
        'superior completo');
INSERT INTO Pessoa
VALUES ('39221640580', '307704230095', 'Heloísa Albuquerque', 'Silas Rodovia, 23778, undefined Marli, CE',
        'superior completo');
INSERT INTO Pessoa
VALUES ('33739217927', '608221979555', 'João Lucas Saraiva', 'Barros Alameda, 62369, Silva do Sul, ES',
        'mestrado');
INSERT INTO Pessoa
VALUES ('36970834878', '477780224964', 'Felícia Oliveira', 'Marcos Rodovia, 1464, undefined Alessandro do Norte, PB',
        '1 grau completo');
INSERT INTO Pessoa
VALUES ('10952521341', '966691177617', 'Warley Nogueira', 'Valentina Travessa, 71378, Saraiva de Nossa Senhora, RS',
        'analfabeto');
INSERT INTO Pessoa
VALUES ('93363777676', '429596063331', 'Yasmin Santos', 'Elísio Rua, 52103, Melo do Norte, MA',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('41160983415', '132513288408', 'Lívia Oliveira', 'Franco Rodovia, 96976, undefined João Lucas, PA',
        'pos-graduação');
INSERT INTO Pessoa
VALUES ('44259705774', '260159795638', 'Raul Reis', 'Sílvia Alameda, 76565, Vitor do Sul, ES',
        'doutorado');
INSERT INTO Pessoa
VALUES ('95268948602', '624529801984', 'Carlos Barros', 'Alexandre Marginal, 25851, Melo de Nossa Senhora, AM',
        'mestrado');
INSERT INTO Pessoa
VALUES ('15808746593', '786758220102', 'Pablo Saraiva', 'Rafael Marginal, 11888, Plantation, BA',
        'doutorado');
INSERT INTO Pessoa
VALUES ('54927417181', '574119920679', 'Ana Clara Oliveira', 'Franco Avenida, 15313, Davie, ES',
        '1 grau completo');


--- Insere programa partidos

INSERT INTO Programa_Partido
VALUES ('64a35cbd-4ef7-4fc0-b6f9-d57f0d1e2cdc', 'Dicta sed cupiditate a fugiat rerum voluptatum voluptatum ut ullam architecto qui nostrum voluptas tempore dolores quisquam asperiores qui nostrum.', '2007-12-4');
INSERT INTO Programa_Partido
VALUES ('c5d211e4-5fd0-46bb-a102-ac1400849a68', 'Odit repudiandae doloremque in omnis est ut corporis ex vel et nulla alias ratione occaecati saepe porro velit dolor et.', '2020-1-14');
INSERT INTO Programa_Partido
VALUES ('08d0554b-3a54-4463-b045-4984038444a0', 'Architecto aperiam quaerat omnis id necessitatibus assumenda tenetur ut cum aliquam voluptas reiciendis blanditiis ab molestiae aut quia deserunt recusandae.', '2011-4-28');
INSERT INTO Programa_Partido
VALUES ('d20c3699-b3c0-4bca-9c06-02fd39fa4e18', 'Ad illo voluptatum quis ut velit blanditiis earum maiores minus exercitationem ad laborum molestiae reiciendis perspiciatis blanditiis eum ea tempora.', '2020-4-19');
INSERT INTO Programa_Partido
VALUES ('01caaecc-d785-45a5-a847-28dbd7af5940', 'Aliquam voluptates tempora veniam eum est molestias fuga rerum commodi perferendis culpa et ea voluptates dolore nemo quia non suscipit.', '2014-7-25');
INSERT INTO Programa_Partido
VALUES ('b607c14d-b4e7-4acb-9baf-4a904bdf758b', 'Laudantium velit deserunt quis cupiditate perferendis ducimus non est dignissimos est esse deserunt est explicabo eaque dolorum nulla et iste.', '2016-5-6');
INSERT INTO Programa_Partido
VALUES ('3f332ee4-8f2d-4951-a5bc-2d41e761d352', 'Dolores beatae corrupti in quia animi beatae in ut qui ullam dolorem quis reprehenderit explicabo magnam earum cum dolorem illum.', '2020-3-1');
INSERT INTO Programa_Partido
VALUES ('51b4f051-b293-4419-afc7-b1a784afd944', 'Veniam aut ullam hic non quod exercitationem rerum quas iste sequi aspernatur autem minima non ut debitis optio sed animi.', '2011-5-29');
INSERT INTO Programa_Partido
VALUES ('5315377e-270f-4fcc-a091-85733f9a34e2', 'Est impedit facere in molestiae molestias vel ea voluptas debitis eum voluptatibus quidem facilis cupiditate enim quaerat provident quos eos.', '2016-10-3');
INSERT INTO Programa_Partido
VALUES ('1e9c0b77-e577-43bc-ab63-6dad02146517', 'Sunt a pariatur ut perspiciatis debitis necessitatibus qui voluptatem facilis velit beatae tenetur impedit dolores voluptas quisquam ducimus a culpa.', '2009-11-12');
INSERT INTO Programa_Partido
VALUES ('53beb1e1-0c98-48f6-8f9d-ecd175302ba8', 'Deserunt nemo rem aut ea pariatur perferendis molestiae et laborum accusamus deleniti corporis labore rerum distinctio reiciendis et magni laudantium.', '2009-10-4');
INSERT INTO Programa_Partido
VALUES ('1f032f35-ea28-4df3-80d7-f10d954df6f6', 'Iure eveniet a architecto ipsam repellat ducimus repellat enim repudiandae rerum alias ducimus labore iusto impedit molestias est optio eum.', '2016-2-9');
INSERT INTO Programa_Partido
VALUES ('f833b412-59f6-4a7b-8376-4104bd982203', 'Voluptas modi laborum illum porro tenetur dignissimos delectus dolorem consequatur tempore aut quia dolore veniam nobis in id consequatur architecto.', '2017-8-11');
INSERT INTO Programa_Partido
VALUES ('d8212199-b704-472e-87f5-172e8eadf290', 'Eos ducimus dolorum reiciendis dolore dolorem nostrum velit recusandae quia aut consequuntur tenetur odit accusantium et numquam in ab voluptatibus.', '2017-2-3');
INSERT INTO Programa_Partido
VALUES ('d0aaab62-127d-4e9e-ae48-a7d1ce3e2f3e', 'Ullam iusto qui illo esse corporis ut ut nulla suscipit quia quia repellendus molestias eaque consequatur qui quaerat cupiditate ipsum.', '2012-3-12');
INSERT INTO Programa_Partido
VALUES ('125653cc-f602-4b99-b693-9af6403b893c', 'Aliquam pariatur dolor molestiae odit repellendus accusantium sequi vel reprehenderit nesciunt quas quasi beatae non et minus nobis in qui.', '2016-7-30');
INSERT INTO Programa_Partido
VALUES ('879ea8cb-0cb3-41ba-b7c2-b295d4bea4ba', 'Voluptates labore et repellendus possimus maiores nobis vel amet impedit eaque non explicabo est quia architecto voluptatem aut quos quibusdam.', '2008-8-6');
INSERT INTO Programa_Partido
VALUES ('f378bfda-b262-491f-b3e5-4aacf135a713', 'Tempora rerum qui deleniti blanditiis quia dolorem dolore numquam ea ut vel ut minus in est ut quos rerum illo.', '2007-4-6');
INSERT INTO Programa_Partido
VALUES ('d4a242ed-1151-4b8e-ade9-c2fd57b04c39', 'Sed aut eum velit quia ipsam molestiae omnis tempore vitae libero nostrum ducimus quia maxime exercitationem odit voluptas nulla neque.', '2010-2-8');
INSERT INTO Programa_Partido
VALUES ('d1feedd4-8bc9-4abe-974c-30e42615a5a8', 'Delectus suscipit perferendis qui et architecto suscipit voluptatibus quis autem eum accusamus molestiae sint aliquam in error et id vitae.', '2013-2-26');


--- Insere partidos
INSERT INTO Partido
VALUES ('MDB', 'Movimento Democrático Brasileiro', '76328378601', '2006-12-3',
        'd1feedd4-8bc9-4abe-974c-30e42615a5a8');
INSERT INTO Partido
VALUES ('PT', 'Partido dos Trabalhadores', '99175420803', '2010-11-23',
        'd8212199-b704-472e-87f5-172e8eadf290');
INSERT INTO Partido
VALUES ('PSDB', 'Partido da Social Democracia Brasileira', '81107487515', '2021-1-17',
        '1f032f35-ea28-4df3-80d7-f10d954df6f6');
INSERT INTO Partido
VALUES ('PP', 'Progressistas', '64684924166', '2014-5-25',
        'd0aaab62-127d-4e9e-ae48-a7d1ce3e2f3e');
INSERT INTO Partido
VALUES ('PDT', 'Partido Democrático Trabalhista', '71007887653', '2013-10-19',
        'f833b412-59f6-4a7b-8376-4104bd982203');
INSERT INTO Partido
VALUES ('PTB', 'Partido Trabalhista Brasileiro', '94223495926', '1997-3-11',
        '01caaecc-d785-45a5-a847-28dbd7af5940');


-- Insere Candidato
INSERT INTO Candidato
VALUES ('43096352221', 'PSDB');
INSERT INTO Candidato
VALUES ('47783979305', 'PTB');
INSERT INTO Candidato
VALUES ('75247511798', 'MDB');
INSERT INTO Candidato
VALUES ('67352445363', 'PDT');
INSERT INTO Candidato
VALUES ('22700045653', 'PSDB');
INSERT INTO Candidato
VALUES ('60043165707', 'MDB');
INSERT INTO Candidato
VALUES ('34049041755', 'PP');
INSERT INTO Candidato
VALUES ('73679764212', 'PSDB');
INSERT INTO Candidato
VALUES ('42611886474', 'PP');
INSERT INTO Candidato
VALUES ('66000308196', 'MDB');
INSERT INTO Candidato
VALUES ('11856616593', 'PSDB');
INSERT INTO Candidato
VALUES ('15462815286', 'PTB');
INSERT INTO Candidato
VALUES ('74884315195', 'PT');
INSERT INTO Candidato
VALUES ('11792162314', 'PP');
INSERT INTO Candidato
VALUES ('74553356398', 'PP');
INSERT INTO Candidato
VALUES ('84577393592', 'PTB');
INSERT INTO Candidato
VALUES ('63150459881', 'MDB');
INSERT INTO Candidato
VALUES ('16176439919', 'PDT');
INSERT INTO Candidato
VALUES ('92002684760', 'PDT');
INSERT INTO Candidato
VALUES ('38607805878', 'PP');
INSERT INTO Candidato
VALUES ('78521770969', 'PP');
INSERT INTO Candidato
VALUES ('79418088067', 'PP');
INSERT INTO Candidato
VALUES ('71797774885', 'PSDB');
INSERT INTO Candidato
VALUES ('81107487515', 'MDB');
INSERT INTO Candidato
VALUES ('55165247858', 'MDB');
INSERT INTO Candidato
VALUES ('78014859156', 'PT');
INSERT INTO Candidato
VALUES ('33628560900', 'PTB');
INSERT INTO Candidato
VALUES ('85471168039', 'PP');
INSERT INTO Candidato
VALUES ('62563421055', 'PT');
INSERT INTO Candidato
VALUES ('59100339210', 'PT');
INSERT INTO Candidato
VALUES ('86269439584', 'PDT');
INSERT INTO Candidato
VALUES ('27899335727', 'PDT');
INSERT INTO Candidato
VALUES ('86179116971', 'PDT');
INSERT INTO Candidato
VALUES ('42666099744', 'MDB');
INSERT INTO Candidato
VALUES ('15808746593', 'PDT');
INSERT INTO Candidato
VALUES ('30063241985', 'PDT');
INSERT INTO Candidato
VALUES ('89273748940', 'PT');
INSERT INTO Candidato
VALUES ('97542159403', 'PSDB');
INSERT INTO Candidato
VALUES ('39886607385', 'PSDB');
INSERT INTO Candidato
VALUES ('84267205318', 'PTB');
INSERT INTO Candidato
VALUES ('70796429398', 'PDT');
INSERT INTO Candidato
VALUES ('99474227605', 'PTB');
INSERT INTO Candidato
VALUES ('59180864153', 'MDB');
INSERT INTO Candidato
VALUES ('85421043294', 'PSDB');
INSERT INTO Candidato
VALUES ('19092043468', 'PTB');
INSERT INTO Candidato
VALUES ('24822467043', 'PT');
INSERT INTO Candidato
VALUES ('44484618890', 'PTB');
INSERT INTO Candidato
VALUES ('70865662137', 'MDB');
INSERT INTO Candidato
VALUES ('71078690302', 'PSDB');
INSERT INTO Candidato
VALUES ('95268948602', 'PT');
INSERT INTO Candidato
VALUES ('74868324829', 'PDT');
INSERT INTO Candidato
VALUES ('38326898736', 'PDT');
INSERT INTO Candidato
VALUES ('52877239394', 'PSDB');
INSERT INTO Candidato
VALUES ('81840145753', 'MDB');
INSERT INTO Candidato
VALUES ('23029678915', 'PDT');
INSERT INTO Candidato
VALUES ('68440822518', 'PSDB');
INSERT INTO Candidato
VALUES ('29895040113', 'PP');
INSERT INTO Candidato
VALUES ('89975072103', 'PTB');
INSERT INTO Candidato
VALUES ('21700934006', 'PDT');
INSERT INTO Candidato
VALUES ('48470564924', 'PT');
INSERT INTO Candidato
VALUES ('10616772223', 'PT');
INSERT INTO Candidato
VALUES ('85698530410', 'MDB');
INSERT INTO Candidato
VALUES ('72538530293', 'PDT');
INSERT INTO Candidato
VALUES ('24966265256', 'MDB');
INSERT INTO Candidato
VALUES ('33110790541', 'PP');
INSERT INTO Candidato
VALUES ('91017248921', 'PP');
INSERT INTO Candidato
VALUES ('66609882188', 'PTB');
INSERT INTO Candidato
VALUES ('32414304846', 'PP');
INSERT INTO Candidato
VALUES ('12408964524', 'PT');
INSERT INTO Candidato
VALUES ('17716842761', 'PT');
INSERT INTO Candidato
VALUES ('88091845146', 'PTB');
INSERT INTO Candidato
VALUES ('27614811982', 'PTB');
INSERT INTO Candidato
VALUES ('47322499984', 'PP');
INSERT INTO Candidato
VALUES ('71713129335', 'PTB');
INSERT INTO Candidato
VALUES ('82877426827', 'PDT');
INSERT INTO Candidato
VALUES ('21997365166', 'PT');
INSERT INTO Candidato
VALUES ('61750890677', 'PT');
INSERT INTO Candidato
VALUES ('99621701030', 'PP');
INSERT INTO Candidato
VALUES ('53326698206', 'PTB');
INSERT INTO Candidato
VALUES ('27553708830', 'PSDB');
INSERT INTO Candidato
VALUES ('32085399280', 'PDT');
INSERT INTO Candidato
VALUES ('50722760849', 'PDT');
INSERT INTO Candidato
VALUES ('90507961907', 'PSDB');
INSERT INTO Candidato
VALUES ('24439672860', 'PP');
INSERT INTO Candidato
VALUES ('33666146213', 'PSDB');
INSERT INTO Candidato
VALUES ('16205148608', 'MDB');
INSERT INTO Candidato
VALUES ('93827489160', 'PTB');
INSERT INTO Candidato
VALUES ('46842239857', 'PP');
INSERT INTO Candidato
VALUES ('70917615771', 'PTB');
INSERT INTO Candidato
VALUES ('58344170006', 'PSDB');
INSERT INTO Candidato
VALUES ('95569495800', 'PTB');
INSERT INTO Candidato
VALUES ('75949794522', 'PDT');
INSERT INTO Candidato
VALUES ('35807526966', 'PSDB');
INSERT INTO Candidato
VALUES ('46037782656', 'PTB');
INSERT INTO Candidato
VALUES ('50740862700', 'MDB');
INSERT INTO Candidato
VALUES ('58672425325', 'PP');
INSERT INTO Candidato
VALUES ('35566097435', 'PT');
INSERT INTO Candidato
VALUES ('15567308135', 'PSDB');
INSERT INTO Candidato
VALUES ('26077215422', 'PDT');
INSERT INTO Candidato
VALUES ('34482197472', 'PDT');
INSERT INTO Candidato
VALUES ('81989843735', 'PSDB');
INSERT INTO Candidato
VALUES ('28806930759', 'PP');
INSERT INTO Candidato
VALUES ('13439644786', 'PDT');
INSERT INTO Candidato
VALUES ('53600938739', 'PTB');
INSERT INTO Candidato
VALUES ('15346407331', 'PP');
INSERT INTO Candidato
VALUES ('46951443084', 'PTB');
INSERT INTO Candidato
VALUES ('55553544007', 'PSDB');
INSERT INTO Candidato
VALUES ('25317057166', 'PSDB');
INSERT INTO Candidato
VALUES ('17678079477', 'PSDB');
INSERT INTO Candidato
VALUES ('96162843727', 'PSDB');
INSERT INTO Candidato
VALUES ('23646102703', 'PDT');
INSERT INTO Candidato
VALUES ('87348033047', 'PTB');
INSERT INTO Candidato
VALUES ('93524363834', 'PTB');
INSERT INTO Candidato
VALUES ('23977915302', 'MDB');
INSERT INTO Candidato
VALUES ('74748832648', 'MDB');
INSERT INTO Candidato
VALUES ('54927417181', 'PDT');
INSERT INTO Candidato
VALUES ('82239788295', 'PT');
INSERT INTO Candidato
VALUES ('73277497400', 'PSDB');
INSERT INTO Candidato
VALUES ('42148925778', 'PSDB');
INSERT INTO Candidato
VALUES ('56274953270', 'PTB');
INSERT INTO Candidato
VALUES ('48407140278', 'MDB');
INSERT INTO Candidato
VALUES ('62152035068', 'PT');
INSERT INTO Candidato
VALUES ('74856146364', 'PTB');
INSERT INTO Candidato
VALUES ('81856962239', 'PSDB');
INSERT INTO Candidato
VALUES ('44287939586', 'PT');
INSERT INTO Candidato
VALUES ('99031375555', 'PT');
INSERT INTO Candidato
VALUES ('53815103929', 'PT');
INSERT INTO Candidato
VALUES ('92874572738', 'PT');
INSERT INTO Candidato
VALUES ('11214965519', 'PDT');
INSERT INTO Candidato
VALUES ('16354246530', 'PTB');
INSERT INTO Candidato
VALUES ('45949940583', 'PP');
INSERT INTO Candidato
VALUES ('84743212782', 'PP');
INSERT INTO Candidato
VALUES ('13409115150', 'PDT');
INSERT INTO Candidato
VALUES ('98326434637', 'PTB');
INSERT INTO Candidato
VALUES ('38843407263', 'PT');
INSERT INTO Candidato
VALUES ('64449079392', 'PDT');
INSERT INTO Candidato
VALUES ('94982653530', 'PTB');
INSERT INTO Candidato
VALUES ('41530032556', 'PTB');
INSERT INTO Candidato
VALUES ('29644463055', 'PSDB');
INSERT INTO Candidato
VALUES ('89658641323', 'PSDB');
INSERT INTO Candidato
VALUES ('37795407914', 'PSDB');
INSERT INTO Candidato
VALUES ('12614989210', 'PP');
INSERT INTO Candidato
VALUES ('22216452944', 'PP');
INSERT INTO Candidato
VALUES ('24567704398', 'MDB');
INSERT INTO Candidato
VALUES ('63777786765', 'PT');
INSERT INTO Candidato
VALUES ('90085991316', 'PDT');
INSERT INTO Candidato
VALUES ('44480531623', 'PSDB');
INSERT INTO Candidato
VALUES ('17017262971', 'PT');
INSERT INTO Candidato
VALUES ('98058124845', 'MDB');
INSERT INTO Candidato
VALUES ('44611691811', 'MDB');
INSERT INTO Candidato
VALUES ('21012337736', 'PTB');
INSERT INTO Candidato
VALUES ('24722674724', 'PTB');
INSERT INTO Candidato
VALUES ('71670214808', 'PSDB');
INSERT INTO Candidato
VALUES ('48909591054', 'PTB');
INSERT INTO Candidato
VALUES ('51375660479', 'PSDB');
INSERT INTO Candidato
VALUES ('76136016375', 'PTB');
INSERT INTO Candidato
VALUES ('12393648503', 'PSDB');
INSERT INTO Candidato
VALUES ('28583832178', 'PDT');
INSERT INTO Candidato
VALUES ('64631355758', 'PDT');
INSERT INTO Candidato
VALUES ('76603942574', 'PP');
INSERT INTO Candidato
VALUES ('24846970050', 'PT');
INSERT INTO Candidato
VALUES ('62271722485', 'PDT');
INSERT INTO Candidato
VALUES ('16016930101', 'PTB');
INSERT INTO Candidato
VALUES ('23662008999', 'PSDB');
INSERT INTO Candidato
VALUES ('87366192734', 'PSDB');
INSERT INTO Candidato
VALUES ('65871269844', 'MDB');
INSERT INTO Candidato
VALUES ('10190151415', 'PT');
INSERT INTO Candidato
VALUES ('79579603821', 'MDB');
INSERT INTO Candidato
VALUES ('83423976283', 'PSDB');
INSERT INTO Candidato
VALUES ('18723273822', 'PTB');
INSERT INTO Candidato
VALUES ('72005313155', 'PTB');
INSERT INTO Candidato
VALUES ('77440287217', 'PSDB');
INSERT INTO Candidato
VALUES ('63629505806', 'PDT');
INSERT INTO Candidato
VALUES ('79950719017', 'PT');
INSERT INTO Candidato
VALUES ('42436610548', 'PP');
INSERT INTO Candidato
VALUES ('52920149751', 'PSDB');
INSERT INTO Candidato
VALUES ('11719256164', 'PSDB');
INSERT INTO Candidato
VALUES ('19822962293', 'PDT');
INSERT INTO Candidato
VALUES ('86761833312', 'MDB');
INSERT INTO Candidato
VALUES ('97532397126', 'PDT');
INSERT INTO Candidato
VALUES ('19756374296', 'PTB');
INSERT INTO Candidato
VALUES ('44259705774', 'PDT');
INSERT INTO Candidato
VALUES ('91077021027', 'PSDB');
INSERT INTO Candidato
VALUES ('65191834932', 'MDB');
INSERT INTO Candidato
VALUES ('24291245951', 'PP');
INSERT INTO Candidato
VALUES ('47835368167', 'PTB');
INSERT INTO Candidato
VALUES ('48617187398', 'MDB');
INSERT INTO Candidato
VALUES ('16635875334', 'PDT');
INSERT INTO Candidato
VALUES ('87706230955', 'MDB');
INSERT INTO Candidato
VALUES ('55815897535', 'PSDB');
INSERT INTO Candidato
VALUES ('29543020694', 'MDB');
INSERT INTO Candidato
VALUES ('71007887653', 'PT');
INSERT INTO Candidato
VALUES ('95178695621', 'PDT');
INSERT INTO Candidato
VALUES ('53485558112', 'MDB');
INSERT INTO Candidato
VALUES ('42206480598', 'PP');
INSERT INTO Candidato
VALUES ('34295891087', 'PDT');
INSERT INTO Candidato
VALUES ('75472573232', 'PSDB');
INSERT INTO Candidato
VALUES ('96399192840', 'PSDB');
INSERT INTO Candidato
VALUES ('33861935359', 'PT');
INSERT INTO Candidato
VALUES ('64684924166', 'PP');
INSERT INTO Candidato
VALUES ('36536230433', 'PTB');
INSERT INTO Candidato
VALUES ('32780581086', 'PTB');
INSERT INTO Candidato
VALUES ('68663108202', 'PTB');
INSERT INTO Candidato
VALUES ('76986037665', 'PSDB');
INSERT INTO Candidato
VALUES ('79631428855', 'PTB');
INSERT INTO Candidato
VALUES ('63150170790', 'PTB');
INSERT INTO Candidato
VALUES ('86271196368', 'PT');
INSERT INTO Candidato
VALUES ('90251854406', 'PTB');
INSERT INTO Candidato
VALUES ('57093701930', 'PP');
INSERT INTO Candidato
VALUES ('66261561494', 'PT');
INSERT INTO Candidato
VALUES ('40792622072', 'PT');
INSERT INTO Candidato
VALUES ('28458227536', 'PSDB');
INSERT INTO Candidato
VALUES ('30904407899', 'MDB');
INSERT INTO Candidato
VALUES ('36030380690', 'PSDB');
INSERT INTO Candidato
VALUES ('56126027428', 'PDT');
INSERT INTO Candidato
VALUES ('68520916590', 'PT');
INSERT INTO Candidato
VALUES ('77598187436', 'PT');
INSERT INTO Candidato
VALUES ('37764165711', 'PDT');
INSERT INTO Candidato
VALUES ('97948715968', 'PT');
INSERT INTO Candidato
VALUES ('68579267167', 'PTB');
INSERT INTO Candidato
VALUES ('16846755656', 'MDB');
INSERT INTO Candidato
VALUES ('15525305538', 'PTB');
INSERT INTO Candidato
VALUES ('96735474125', 'PSDB');
INSERT INTO Candidato
VALUES ('27274558073', 'MDB');
INSERT INTO Candidato
VALUES ('11138060991', 'PDT');
INSERT INTO Candidato
VALUES ('68928154059', 'PTB');
INSERT INTO Candidato
VALUES ('42809196475', 'PSDB');
INSERT INTO Candidato
VALUES ('24799374230', 'PSDB');
INSERT INTO Candidato
VALUES ('89233355857', 'PT');
INSERT INTO Candidato
VALUES ('99875636277', 'PP');
INSERT INTO Candidato
VALUES ('37324441201', 'PDT');
INSERT INTO Candidato
VALUES ('64004827691', 'PP');
INSERT INTO Candidato
VALUES ('35014395120', 'PDT');
INSERT INTO Candidato
VALUES ('96993769449', 'PTB');
INSERT INTO Candidato
VALUES ('44908207063', 'PP');
INSERT INTO Candidato
VALUES ('39996799803', 'PT');
INSERT INTO Candidato
VALUES ('68110109437', 'MDB');
INSERT INTO Candidato
VALUES ('79857502803', 'PSDB');
INSERT INTO Candidato
VALUES ('72898224287', 'PDT');
INSERT INTO Candidato
VALUES ('94086229731', 'PDT');
INSERT INTO Candidato
VALUES ('87208565492', 'MDB');
INSERT INTO Candidato
VALUES ('39180499266', 'PT');
INSERT INTO Candidato
VALUES ('30165319882', 'PTB');
INSERT INTO Candidato
VALUES ('40928985222', 'MDB');
INSERT INTO Candidato
VALUES ('44860848870', 'PSDB');
INSERT INTO Candidato
VALUES ('74766249782', 'PSDB');
INSERT INTO Candidato
VALUES ('15051016972', 'PDT');
INSERT INTO Candidato
VALUES ('77664967630', 'PSDB');
INSERT INTO Candidato
VALUES ('54207576885', 'PSDB');
INSERT INTO Candidato
VALUES ('42681556036', 'PTB');
INSERT INTO Candidato
VALUES ('37029771979', 'PP');
INSERT INTO Candidato
VALUES ('93058234590', 'PSDB');
INSERT INTO Candidato
VALUES ('61740416085', 'MDB');
INSERT INTO Candidato
VALUES ('12976033654', 'PSDB');
INSERT INTO Candidato
VALUES ('34451081710', 'PSDB');
INSERT INTO Candidato
VALUES ('54988852173', 'PTB');
INSERT INTO Candidato
VALUES ('61664271336', 'PTB');
INSERT INTO Candidato
VALUES ('49630068878', 'PP');
INSERT INTO Candidato
VALUES ('14925663892', 'PSDB');
INSERT INTO Candidato
VALUES ('21988119990', 'PTB');
INSERT INTO Candidato
VALUES ('79759818490', 'PT');
INSERT INTO Candidato
VALUES ('69257088878', 'PP');
INSERT INTO Candidato
VALUES ('82694570559', 'MDB');
INSERT INTO Candidato
VALUES ('77949062872', 'PSDB');
INSERT INTO Candidato
VALUES ('49541541982', 'PT');
INSERT INTO Candidato
VALUES ('88995994818', 'PSDB');
INSERT INTO Candidato
VALUES ('13684269834', 'PDT');
INSERT INTO Candidato
VALUES ('56800358914', 'PSDB');
INSERT INTO Candidato
VALUES ('54613564885', 'MDB');
INSERT INTO Candidato
VALUES ('98651677060', 'PP');
INSERT INTO Candidato
VALUES ('60364329223', 'PSDB');
INSERT INTO Candidato
VALUES ('40367657486', 'PDT');
INSERT INTO Candidato
VALUES ('52453071193', 'PT');
INSERT INTO Candidato
VALUES ('44197359627', 'PTB');
INSERT INTO Candidato
VALUES ('60122351620', 'PT');
INSERT INTO Candidato
VALUES ('63185736755', 'PSDB');
INSERT INTO Candidato
VALUES ('37769212496', 'PT');
INSERT INTO Candidato
VALUES ('46404720542', 'PP');
INSERT INTO Candidato
VALUES ('43316695608', 'MDB');
INSERT INTO Candidato
VALUES ('56392738602', 'PTB');
INSERT INTO Candidato
VALUES ('24243827324', 'MDB');
INSERT INTO Candidato
VALUES ('45290986180', 'PT');
INSERT INTO Candidato
VALUES ('34712144928', 'PT');
INSERT INTO Candidato
VALUES ('49993791026', 'PP');
INSERT INTO Candidato
VALUES ('55661978677', 'PSDB');
INSERT INTO Candidato
VALUES ('39221640580', 'MDB');
INSERT INTO Candidato
VALUES ('27882795822', 'PTB');
INSERT INTO Candidato
VALUES ('57082543941', 'MDB');
INSERT INTO Candidato
VALUES ('29649122953', 'PDT');
INSERT INTO Candidato
VALUES ('17156520811', 'MDB');
INSERT INTO Candidato
VALUES ('12587690399', 'PDT');
INSERT INTO Candidato
VALUES ('18233533741', 'MDB');
INSERT INTO Candidato
VALUES ('28406533049', 'PP');
INSERT INTO Candidato
VALUES ('50569366908', 'PSDB');
INSERT INTO Candidato
VALUES ('18437136497', 'PTB');
INSERT INTO Candidato
VALUES ('38951155769', 'PSDB');
INSERT INTO Candidato
VALUES ('51445510021', 'PT');
INSERT INTO Candidato
VALUES ('32271739926', 'PT');
INSERT INTO Candidato
VALUES ('62067907205', 'PDT');
INSERT INTO Candidato
VALUES ('42256481919', 'PTB');
INSERT INTO Candidato
VALUES ('45378367919', 'PDT');
INSERT INTO Candidato
VALUES ('90374537745', 'MDB');
INSERT INTO Candidato
VALUES ('81480079204', 'PT');
INSERT INTO Candidato
VALUES ('94529897822', 'PT');
INSERT INTO Candidato
VALUES ('31668141162', 'PTB');
INSERT INTO Candidato
VALUES ('77198284929', 'MDB');
INSERT INTO Candidato
VALUES ('89536202107', 'PT');
INSERT INTO Candidato
VALUES ('84538009271', 'PT');
INSERT INTO Candidato
VALUES ('89778357343', 'PT');
INSERT INTO Candidato
VALUES ('69316593371', 'PP');
INSERT INTO Candidato
VALUES ('26499034971', 'PDT');
INSERT INTO Candidato
VALUES ('34354209771', 'PTB');
INSERT INTO Candidato
VALUES ('83672753747', 'PTB');
INSERT INTO Candidato
VALUES ('93187630493', 'PT');
INSERT INTO Candidato
VALUES ('35535540033', 'PTB');
INSERT INTO Candidato
VALUES ('86202337315', 'PSDB');
INSERT INTO Candidato
VALUES ('29039845638', 'PT');
INSERT INTO Candidato
VALUES ('77959251704', 'MDB');
INSERT INTO Candidato
VALUES ('83222212893', 'PDT');
INSERT INTO Candidato
VALUES ('52020327886', 'PSDB');
INSERT INTO Candidato
VALUES ('70247840185', 'PTB');
INSERT INTO Candidato
VALUES ('36680386532', 'PP');
INSERT INTO Candidato
VALUES ('57748351241', 'PDT');
INSERT INTO Candidato
VALUES ('89653281683', 'PT');
INSERT INTO Candidato
VALUES ('79239115805', 'PTB');
INSERT INTO Candidato
VALUES ('40505070846', 'PDT');
INSERT INTO Candidato
VALUES ('12626151097', 'PT');
INSERT INTO Candidato
VALUES ('78491106405', 'PP');
INSERT INTO Candidato
VALUES ('84441573002', 'PDT');
INSERT INTO Candidato
VALUES ('67794386299', 'PT');
INSERT INTO Candidato
VALUES ('25997139057', 'MDB');
INSERT INTO Candidato
VALUES ('40690805627', 'MDB');
INSERT INTO Candidato
VALUES ('40021847444', 'MDB');
INSERT INTO Candidato
VALUES ('87744765498', 'PDT');
INSERT INTO Candidato
VALUES ('14154119554', 'PSDB');
INSERT INTO Candidato
VALUES ('27572791909', 'PSDB');
INSERT INTO Candidato
VALUES ('42253852223', 'PSDB');
INSERT INTO Candidato
VALUES ('81787125857', 'PDT');
INSERT INTO Candidato
VALUES ('51938838479', 'PT');
INSERT INTO Candidato
VALUES ('99122018190', 'PTB');
INSERT INTO Candidato
VALUES ('12367218623', 'PP');
INSERT INTO Candidato
VALUES ('32980330095', 'PTB');
INSERT INTO Candidato
VALUES ('44945997984', 'PTB');
INSERT INTO Candidato
VALUES ('86186453672', 'PTB');
INSERT INTO Candidato
VALUES ('44441414789', 'PSDB');
INSERT INTO Candidato
VALUES ('30491285622', 'PTB');
INSERT INTO Candidato
VALUES ('30731319272', 'PDT');
INSERT INTO Candidato
VALUES ('48772362389', 'MDB');
INSERT INTO Candidato
VALUES ('74306043400', 'PDT');
INSERT INTO Candidato
VALUES ('99258126760', 'PTB');
INSERT INTO Candidato
VALUES ('64313026478', 'PP');
INSERT INTO Candidato
VALUES ('11848160342', 'PSDB');
INSERT INTO Candidato
VALUES ('64592013116', 'PP');
INSERT INTO Candidato
VALUES ('74113580884', 'PT');
INSERT INTO Candidato
VALUES ('29075196001', 'PTB');
INSERT INTO Candidato
VALUES ('48286474652', 'PSDB');
INSERT INTO Candidato
VALUES ('93748753082', 'PSDB');
INSERT INTO Candidato
VALUES ('27857613652', 'MDB');
INSERT INTO Candidato
VALUES ('81158944626', 'MDB');
INSERT INTO Candidato
VALUES ('98059176125', 'MDB');
INSERT INTO Candidato
VALUES ('85147762342', 'PP');
INSERT INTO Candidato
VALUES ('14901188861', 'PT');
INSERT INTO Candidato
VALUES ('34798725692', 'PTB');
INSERT INTO Candidato
VALUES ('91040847708', 'PTB');
INSERT INTO Candidato
VALUES ('63353046625', 'PSDB');
INSERT INTO Candidato
VALUES ('86656567275', 'PT');
INSERT INTO Candidato
VALUES ('16140814840', 'PTB');
INSERT INTO Candidato
VALUES ('39015131085', 'PDT');
INSERT INTO Candidato
VALUES ('90039808077', 'PT');
INSERT INTO Candidato
VALUES ('90751582509', 'PDT');
INSERT INTO Candidato
VALUES ('96217219165', 'PSDB');
INSERT INTO Candidato
VALUES ('83294698440', 'PSDB');
INSERT INTO Candidato
VALUES ('77360690359', 'MDB');
INSERT INTO Candidato
VALUES ('16630750785', 'PSDB');
INSERT INTO Candidato
VALUES ('26629737697', 'PDT');
INSERT INTO Candidato
VALUES ('38676820667', 'PT');
INSERT INTO Candidato
VALUES ('62869147914', 'PT');
INSERT INTO Candidato
VALUES ('60892811592', 'PDT');
INSERT INTO Candidato
VALUES ('21359217371', 'PSDB');
INSERT INTO Candidato
VALUES ('97763730341', 'PP');
INSERT INTO Candidato
VALUES ('79710021100', 'PTB');
INSERT INTO Candidato
VALUES ('16535910640', 'PDT');
INSERT INTO Candidato
VALUES ('85655194001', 'MDB');
INSERT INTO Candidato
VALUES ('64113110627', 'MDB');
INSERT INTO Candidato
VALUES ('59327314610', 'PDT');
INSERT INTO Candidato
VALUES ('23571120649', 'MDB');
INSERT INTO Candidato
VALUES ('86574679580', 'PT');
INSERT INTO Candidato
VALUES ('51842986051', 'MDB');
INSERT INTO Candidato
VALUES ('18336009925', 'PP');
INSERT INTO Candidato
VALUES ('50137497729', 'PTB');
INSERT INTO Candidato
VALUES ('50013432025', 'PDT');
INSERT INTO Candidato
VALUES ('16300685813', 'PDT');
INSERT INTO Candidato
VALUES ('54104066689', 'PSDB');
INSERT INTO Candidato
VALUES ('61741954395', 'PDT');
INSERT INTO Candidato
VALUES ('31951113061', 'PP');
INSERT INTO Candidato
VALUES ('82742590734', 'PDT');
INSERT INTO Candidato
VALUES ('86949663003', 'PTB');
INSERT INTO Candidato
VALUES ('20341535366', 'PTB');
INSERT INTO Candidato
VALUES ('68443179363', 'PP');
INSERT INTO Candidato
VALUES ('41960043215', 'PT');
INSERT INTO Candidato
VALUES ('72847558700', 'PT');
INSERT INTO Candidato
VALUES ('29951727385', 'PTB');
INSERT INTO Candidato
VALUES ('66041600762', 'MDB');
INSERT INTO Candidato
VALUES ('56926663320', 'PTB');
INSERT INTO Candidato
VALUES ('36500291242', 'MDB');
INSERT INTO Candidato
VALUES ('44154843701', 'PT');
INSERT INTO Candidato
VALUES ('52849328536', 'PP');
INSERT INTO Candidato
VALUES ('14247396097', 'MDB');
INSERT INTO Candidato
VALUES ('85431055435', 'PT');
INSERT INTO Candidato
VALUES ('32021542380', 'PT');
INSERT INTO Candidato
VALUES ('37049869918', 'PDT');
INSERT INTO Candidato
VALUES ('31726471120', 'MDB');
INSERT INTO Candidato
VALUES ('60372715506', 'PT');
INSERT INTO Candidato
VALUES ('51658055912', 'PTB');
INSERT INTO Candidato
VALUES ('34965334206', 'PSDB');
INSERT INTO Candidato
VALUES ('80001908850', 'PP');
INSERT INTO Candidato
VALUES ('53773475124', 'PDT');
INSERT INTO Candidato
VALUES ('97353540891', 'PDT');
INSERT INTO Candidato
VALUES ('78830082472', 'PT');
INSERT INTO Candidato
VALUES ('76328378601', 'PDT');
INSERT INTO Candidato
VALUES ('64255168652', 'PTB');
INSERT INTO Candidato
VALUES ('38336047478', 'PP');
INSERT INTO Candidato
VALUES ('94223495926', 'MDB');
INSERT INTO Candidato
VALUES ('30055465318', 'PT');
INSERT INTO Candidato
VALUES ('83335207737', 'PDT');
INSERT INTO Candidato
VALUES ('87576986304', 'PP');
INSERT INTO Candidato
VALUES ('24302018939', 'PDT');
INSERT INTO Candidato
VALUES ('79990477925', 'MDB');
INSERT INTO Candidato
VALUES ('18720562611', 'PT');
INSERT INTO Candidato
VALUES ('89211657708', 'PTB');
INSERT INTO Candidato
VALUES ('56193133238', 'PSDB');
INSERT INTO Candidato
VALUES ('67893272326', 'PTB');
INSERT INTO Candidato
VALUES ('15007094920', 'PSDB');
INSERT INTO Candidato
VALUES ('93245290170', 'PT');
INSERT INTO Candidato
VALUES ('44911381667', 'PT');
INSERT INTO Candidato
VALUES ('69868170775', 'MDB');
INSERT INTO Candidato
VALUES ('48260050807', 'PT');
INSERT INTO Candidato
VALUES ('76437914024', 'PTB');
INSERT INTO Candidato
VALUES ('47086909811', 'PT');
INSERT INTO Candidato
VALUES ('49827746006', 'MDB');
INSERT INTO Candidato
VALUES ('44770700223', 'MDB');
INSERT INTO Candidato
VALUES ('79117540030', 'PDT');
INSERT INTO Candidato
VALUES ('24517586107', 'PP');
INSERT INTO Candidato
VALUES ('35013815364', 'PSDB');
INSERT INTO Candidato
VALUES ('52366501996', 'PDT');
INSERT INTO Candidato
VALUES ('36323933107', 'MDB');
INSERT INTO Candidato
VALUES ('48624392356', 'PP');
INSERT INTO Candidato
VALUES ('86525803739', 'PSDB');
INSERT INTO Candidato
VALUES ('61978392985', 'MDB');
INSERT INTO Candidato
VALUES ('14430595960', 'PT');
INSERT INTO Candidato
VALUES ('41108251772', 'PSDB');
INSERT INTO Candidato
VALUES ('60074036989', 'PP');
INSERT INTO Candidato
VALUES ('73565084710', 'PDT');
INSERT INTO Candidato
VALUES ('28691501056', 'PP');
INSERT INTO Candidato
VALUES ('89854734104', 'PTB');
INSERT INTO Candidato
VALUES ('56150399090', 'PP');
INSERT INTO Candidato
VALUES ('31766336101', 'PP');
INSERT INTO Candidato
VALUES ('80145377612', 'MDB');
INSERT INTO Candidato
VALUES ('13070944417', 'PTB');
INSERT INTO Candidato
VALUES ('90003637734', 'PSDB');
INSERT INTO Candidato
VALUES ('63419523332', 'PT');
INSERT INTO Candidato
VALUES ('14428552011', 'PT');
INSERT INTO Candidato
VALUES ('83848194922', 'PP');
INSERT INTO Candidato
VALUES ('76313567715', 'PSDB');
INSERT INTO Candidato
VALUES ('52794275211', 'MDB');
INSERT INTO Candidato
VALUES ('35354715120', 'PSDB');
INSERT INTO Candidato
VALUES ('86797248676', 'PDT');
INSERT INTO Candidato
VALUES ('83635655883', 'PSDB');
INSERT INTO Candidato
VALUES ('93732622361', 'PTB');
INSERT INTO Candidato
VALUES ('89630639564', 'PP');
INSERT INTO Candidato
VALUES ('43832994084', 'PTB');


-- Insere Cargo
INSERT INTO Cargo
VALUES ('d9adc26e-a49d-47c3-93a4-ee165bebbd3c', 'Vereador', 'São Paulo',
        NULL,
        NULL,
        '20');
INSERT INTO Cargo
VALUES ('5adccbbd-e44f-4318-9a98-0b1eaa2b4a81', 'Prefeito', 'São Paulo',
        NULL,
        NULL,
        '1');
INSERT INTO Cargo
VALUES ('32996742-8098-46dc-9b82-8273266f6716', 'Deputado Estadual', NULL,
        'SP',
        NULL,
        '10');
INSERT INTO Cargo
VALUES ('b9f92267-c96e-4fe6-ba55-5e8593e36310', 'Deputado Federal', NULL,
        NULL,
        'BR',
        '5');
INSERT INTO Cargo
VALUES ('4c22eb15-0280-4f51-ad8d-c24f79bb442e', 'Governador', NULL,
        'SP',
        NULL,
        '1');
INSERT INTO Cargo
VALUES ('f91d0766-2157-4944-ab7f-513ac16b5616', 'Presidente', NULL,
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
VALUES ('5b1182b7-da73-478f-8d8c-47388fb2a9b1', '43096352221', NULL,
        2014,
        'f91d0766-2157-4944-ab7f-513ac16b5616',
        0);
INSERT INTO Candidatura
VALUES ('69b1500f-315a-466d-a272-a1acd8299567', '47783979305', NULL,
        2018,
        'd9adc26e-a49d-47c3-93a4-ee165bebbd3c',
        0);
INSERT INTO Candidatura
VALUES ('08f6b5d0-c507-46b8-9b7b-aa5248e63ffa', '75247511798', NULL,
        2010,
        'b9f92267-c96e-4fe6-ba55-5e8593e36310',
        0);
INSERT INTO Candidatura
VALUES ('4caead96-c19b-4c76-a92d-34d6fd83a133', '67352445363', NULL,
        2018,
        'd9adc26e-a49d-47c3-93a4-ee165bebbd3c',
        0);
INSERT INTO Candidatura
VALUES ('43f26faf-14b8-4779-9925-632f8e5b64cb', '22700045653', NULL,
        2010,
        '5adccbbd-e44f-4318-9a98-0b1eaa2b4a81',
        0);
INSERT INTO Candidatura
VALUES ('e59ca697-8a22-45f7-b6c1-273c07eedf44', '60043165707', NULL,
        2016,
        'd9adc26e-a49d-47c3-93a4-ee165bebbd3c',
        0);
INSERT INTO Candidatura
VALUES ('8e3ff9b2-d8f6-4b35-92ab-a727242efd2e', '34049041755', NULL,
        2020,
        'b9f92267-c96e-4fe6-ba55-5e8593e36310',
        0);
INSERT INTO Candidatura
VALUES ('ab11040b-d0ec-4f4d-abdc-7e38a0c5fe27', '73679764212', NULL,
        2016,
        '32996742-8098-46dc-9b82-8273266f6716',
        0);
INSERT INTO Candidatura
VALUES ('4a4965be-fa5e-416e-b325-14a3ed6d122d', '42611886474', NULL,
        2016,
        '4c22eb15-0280-4f51-ad8d-c24f79bb442e',
        0);
INSERT INTO Candidatura
VALUES ('96f3952e-ad56-48fb-8534-9fc7cd6d8fd5', '66000308196', NULL,
        2010,
        'd9adc26e-a49d-47c3-93a4-ee165bebbd3c',
        0);
INSERT INTO Candidatura
VALUES ('a21804e3-4e38-483f-a7fa-22f5be211587', '11856616593', NULL,
        2016,
        'b9f92267-c96e-4fe6-ba55-5e8593e36310',
        0);
INSERT INTO Candidatura
VALUES ('9373e77c-8364-4eff-92a4-1bf859f2bb96', '15462815286', NULL,
        2012,
        'd9adc26e-a49d-47c3-93a4-ee165bebbd3c',
        0);
INSERT INTO Candidatura
VALUES ('ddcecbde-58e0-4a05-8883-6e599f8ad4ba', '74884315195', NULL,
        2018,
        '32996742-8098-46dc-9b82-8273266f6716',
        0);
INSERT INTO Candidatura
VALUES ('29f7ed80-7bbf-417a-bc54-73d54df821ee', '11792162314', NULL,
        2014,
        'f91d0766-2157-4944-ab7f-513ac16b5616',
        0);
INSERT INTO Candidatura
VALUES ('853a28a6-d013-4c2b-86c2-4974e2ec49fe', '74553356398', NULL,
        2014,
        '5adccbbd-e44f-4318-9a98-0b1eaa2b4a81',
        0);
INSERT INTO Candidatura
VALUES ('f6b23a47-b8b0-4885-a98b-01f9b66137b3', '84577393592', NULL,
        2016,
        'd9adc26e-a49d-47c3-93a4-ee165bebbd3c',
        0);
INSERT INTO Candidatura
VALUES ('fe1edb1c-4bd5-4905-ac92-152c9eed1d0b', '63150459881', NULL,
        2010,
        'b9f92267-c96e-4fe6-ba55-5e8593e36310',
        0);
INSERT INTO Candidatura
VALUES ('4c3bdf70-dba9-4eb2-8241-97f524f8bc5d', '16176439919', NULL,
        2014,
        '32996742-8098-46dc-9b82-8273266f6716',
        0);
INSERT INTO Candidatura
VALUES ('c065728c-8515-4f4c-bd6f-8e77b47f510f', '92002684760', NULL,
        2016,
        '4c22eb15-0280-4f51-ad8d-c24f79bb442e',
        0);
INSERT INTO Candidatura
VALUES ('53238421-e94b-4a86-b15c-2003b00f2845', '38607805878', NULL,
        2018,
        '5adccbbd-e44f-4318-9a98-0b1eaa2b4a81',
        0);
INSERT INTO Candidatura
VALUES ('e3f6c11d-127e-4d33-96d4-ae47df6765d9', '78521770969', NULL,
        2020,
        'f91d0766-2157-4944-ab7f-513ac16b5616',
        0);
INSERT INTO Candidatura
VALUES ('8624d26b-7e14-4170-b192-9655bdbc3beb', '79418088067', NULL,
        2020,
        '4c22eb15-0280-4f51-ad8d-c24f79bb442e',
        0);
INSERT INTO Candidatura
VALUES ('b0350cf5-b002-4d30-a6f0-a9c7f704af51', '71797774885', NULL,
        2020,
        'b9f92267-c96e-4fe6-ba55-5e8593e36310',
        0);
INSERT INTO Candidatura
VALUES ('3f3ba0c5-c95d-4d78-ad2c-8181236e5f67', '81107487515', NULL,
        2012,
        'b9f92267-c96e-4fe6-ba55-5e8593e36310',
        0);
INSERT INTO Candidatura
VALUES ('8ebdc194-880b-474f-92bb-aa4745b5bb96', '55165247858', NULL,
        2016,
        'd9adc26e-a49d-47c3-93a4-ee165bebbd3c',
        0);
INSERT INTO Candidatura
VALUES ('e0038858-f183-4875-8161-c089ecf759f6', '78014859156', NULL,
        2010,
        '32996742-8098-46dc-9b82-8273266f6716',
        0);
INSERT INTO Candidatura
VALUES ('7a67eebf-a357-4a42-938c-b16e07a8a9d4', '33628560900', NULL,
        2012,
        '4c22eb15-0280-4f51-ad8d-c24f79bb442e',
        0);
INSERT INTO Candidatura
VALUES ('1174f2ae-df13-4ca7-8d87-797fb2739ba0', '85471168039', NULL,
        2016,
        'f91d0766-2157-4944-ab7f-513ac16b5616',
        0);
INSERT INTO Candidatura
VALUES ('a9340c32-57cd-4b51-a695-5dd90c08e191', '62563421055', NULL,
        2014,
        '4c22eb15-0280-4f51-ad8d-c24f79bb442e',
        0);
INSERT INTO Candidatura
VALUES ('30c516bf-c593-4548-bfc4-47b329487851', '59100339210', NULL,
        2020,
        'd9adc26e-a49d-47c3-93a4-ee165bebbd3c',
        0);
INSERT INTO Candidatura
VALUES ('bd069ee4-6a7c-4e1c-a52d-88a21c815dab', '86269439584', NULL,
        2018,
        '4c22eb15-0280-4f51-ad8d-c24f79bb442e',
        0);
INSERT INTO Candidatura
VALUES ('a69d95ce-fec2-48db-a4c2-b5bb36e78ef7', '27899335727', NULL,
        2018,
        '4c22eb15-0280-4f51-ad8d-c24f79bb442e',
        0);
INSERT INTO Candidatura
VALUES ('692ce1fd-dcdc-47e5-a050-dbe937bfc708', '86179116971', NULL,
        2018,
        '4c22eb15-0280-4f51-ad8d-c24f79bb442e',
        0);
INSERT INTO Candidatura
VALUES ('c4c07825-f2ad-411d-90dc-d94a59f2b127', '42666099744', NULL,
        2018,
        'f91d0766-2157-4944-ab7f-513ac16b5616',
        0);
INSERT INTO Candidatura
VALUES ('5efec858-80bd-4121-a359-02b9ece2d0ec', '15808746593', NULL,
        2012,
        'd9adc26e-a49d-47c3-93a4-ee165bebbd3c',
        0);
INSERT INTO Candidatura
VALUES ('8ad216e8-c3b0-4b2b-83aa-4618d140de2a', '30063241985', NULL,
        2014,
        '32996742-8098-46dc-9b82-8273266f6716',
        0);
INSERT INTO Candidatura
VALUES ('70d47789-ce52-4053-b16d-893752e80874', '89273748940', NULL,
        2010,
        '32996742-8098-46dc-9b82-8273266f6716',
        0);
INSERT INTO Candidatura
VALUES ('dde12d85-129f-45be-b250-ea39fd59d447', '97542159403', NULL,
        2018,
        '4c22eb15-0280-4f51-ad8d-c24f79bb442e',
        0);
INSERT INTO Candidatura
VALUES ('64a7a412-dcf1-49ca-b642-f37c2df4b3e6', '39886607385', NULL,
        2020,
        '32996742-8098-46dc-9b82-8273266f6716',
        0);
INSERT INTO Candidatura
VALUES ('3733852a-cace-4350-b61a-6695286f3380', '84267205318', NULL,
        2016,
        'd9adc26e-a49d-47c3-93a4-ee165bebbd3c',
        0);
INSERT INTO Candidatura
VALUES ('ce3e0d4a-abde-410a-94d7-45be576a6f39', '70796429398', NULL,
        2020,
        'b9f92267-c96e-4fe6-ba55-5e8593e36310',
        0);
INSERT INTO Candidatura
VALUES ('1d92b744-fdb0-45c3-b55c-23a244f3c4df', '99474227605', NULL,
        2016,
        'd9adc26e-a49d-47c3-93a4-ee165bebbd3c',
        0);
INSERT INTO Candidatura
VALUES ('8186c655-c026-491f-8828-2c5eea1ee135', '59180864153', NULL,
        2020,
        'b9f92267-c96e-4fe6-ba55-5e8593e36310',
        0);
INSERT INTO Candidatura
VALUES ('d14dcf11-70c4-47ea-8d47-75b602964132', '85421043294', NULL,
        2010,
        'd9adc26e-a49d-47c3-93a4-ee165bebbd3c',
        0);
INSERT INTO Candidatura
VALUES ('a73000f8-f0db-490e-a96e-a92e82ca7f9c', '19092043468', NULL,
        2018,
        '5adccbbd-e44f-4318-9a98-0b1eaa2b4a81',
        0);
INSERT INTO Candidatura
VALUES ('28e4be1f-85bf-46e2-8f94-dcea71baf1a8', '24822467043', NULL,
        2020,
        'b9f92267-c96e-4fe6-ba55-5e8593e36310',
        0);
INSERT INTO Candidatura
VALUES ('6fffe677-b8b9-4ace-a173-9f672ec7a79c', '44484618890', NULL,
        2018,
        '4c22eb15-0280-4f51-ad8d-c24f79bb442e',
        0);
INSERT INTO Candidatura
VALUES ('a4aa2b71-8be1-45a1-9c63-059d3ea1e544', '70865662137', NULL,
        2010,
        'f91d0766-2157-4944-ab7f-513ac16b5616',
        0);
INSERT INTO Candidatura
VALUES ('a7abab5c-cc2e-42da-b021-06ccdf28a382', '71078690302', NULL,
        2018,
        '5adccbbd-e44f-4318-9a98-0b1eaa2b4a81',
        0);
INSERT INTO Candidatura
VALUES ('1b21978a-c6a0-4003-9577-121bf841fffc', '95268948602', NULL,
        2010,
        'd9adc26e-a49d-47c3-93a4-ee165bebbd3c',
        0);
INSERT INTO Candidatura
VALUES ('631462a2-b0aa-405a-8c04-f82bedb40efe', '74868324829', NULL,
        2016,
        '5adccbbd-e44f-4318-9a98-0b1eaa2b4a81',
        0);
INSERT INTO Candidatura
VALUES ('ca885acd-0110-4a3f-9852-414bb2bf15c2', '38326898736', NULL,
        2018,
        '4c22eb15-0280-4f51-ad8d-c24f79bb442e',
        0);
INSERT INTO Candidatura
VALUES ('4ba67991-f16b-42ad-9373-660e707c2cd0', '52877239394', NULL,
        2020,
        'b9f92267-c96e-4fe6-ba55-5e8593e36310',
        0);
INSERT INTO Candidatura
VALUES ('6283fcc8-5355-43c9-a722-4cc69bf7f5de', '81840145753', NULL,
        2014,
        'f91d0766-2157-4944-ab7f-513ac16b5616',
        0);
INSERT INTO Candidatura
VALUES ('3ada787a-f75e-4a26-a47b-5ca6c5741a0b', '23029678915', NULL,
        2020,
        'f91d0766-2157-4944-ab7f-513ac16b5616',
        0);
INSERT INTO Candidatura
VALUES ('b320c4b7-0285-4621-93b4-ccfc9c6ad3af', '68440822518', NULL,
        2018,
        'b9f92267-c96e-4fe6-ba55-5e8593e36310',
        0);
INSERT INTO Candidatura
VALUES ('771af538-92a3-41e6-bc5c-f015e2f418e6', '29895040113', NULL,
        2010,
        '32996742-8098-46dc-9b82-8273266f6716',
        0);
INSERT INTO Candidatura
VALUES ('b383fd69-787b-45dc-bc35-ad6ab80e9ae0', '89975072103', NULL,
        2014,
        '4c22eb15-0280-4f51-ad8d-c24f79bb442e',
        0);
INSERT INTO Candidatura
VALUES ('4f49829d-e223-45c8-8d7c-40113f5e1ef8', '21700934006', NULL,
        2020,
        '4c22eb15-0280-4f51-ad8d-c24f79bb442e',
        0);
INSERT INTO Candidatura
VALUES ('0ad29218-a08c-4d67-b625-de514098795a', '48470564924', NULL,
        2020,
        '32996742-8098-46dc-9b82-8273266f6716',
        0);
INSERT INTO Candidatura
VALUES ('257540c7-8f7d-4bef-9239-9b037fa1cb3c', '10616772223', NULL,
        2016,
        'f91d0766-2157-4944-ab7f-513ac16b5616',
        0);
INSERT INTO Candidatura
VALUES ('dbca96cb-8b7a-4068-b5e0-40b972174455', '85698530410', NULL,
        2018,
        'b9f92267-c96e-4fe6-ba55-5e8593e36310',
        0);
INSERT INTO Candidatura
VALUES ('a32fe52f-a36f-41c6-b9aa-367fe9e0564d', '72538530293', NULL,
        2014,
        'f91d0766-2157-4944-ab7f-513ac16b5616',
        0);
INSERT INTO Candidatura
VALUES ('10035cc3-7557-4ee1-b9ad-54ac61a06964', '24966265256', NULL,
        2018,
        'f91d0766-2157-4944-ab7f-513ac16b5616',
        0);
INSERT INTO Candidatura
VALUES ('70f4dc0a-282f-495a-af1b-477d5bfef36c', '33110790541', NULL,
        2014,
        'f91d0766-2157-4944-ab7f-513ac16b5616',
        0);
INSERT INTO Candidatura
VALUES ('abeae1bf-75d5-4c54-8bfd-c2cc4f933864', '91017248921', NULL,
        2010,
        'b9f92267-c96e-4fe6-ba55-5e8593e36310',
        0);
INSERT INTO Candidatura
VALUES ('77a18b1b-6c6c-46bb-96bf-cffa788ed30b', '66609882188', NULL,
        2010,
        'f91d0766-2157-4944-ab7f-513ac16b5616',
        0);
INSERT INTO Candidatura
VALUES ('933c8e7d-e2e4-4c49-8ec1-17fa3823fed0', '32414304846', NULL,
        2016,
        'b9f92267-c96e-4fe6-ba55-5e8593e36310',
        0);
INSERT INTO Candidatura
VALUES ('db1046ca-5c7e-48ac-a1c1-7d942a9acd7b', '12408964524', NULL,
        2020,
        'f91d0766-2157-4944-ab7f-513ac16b5616',
        0);
INSERT INTO Candidatura
VALUES ('f959a757-7d2e-48ec-bb9e-bc670795cb80', '17716842761', NULL,
        2016,
        'b9f92267-c96e-4fe6-ba55-5e8593e36310',
        0);
INSERT INTO Candidatura
VALUES ('b70416e5-1a2c-40be-8ce3-97d4c6324ce5', '88091845146', NULL,
        2016,
        'f91d0766-2157-4944-ab7f-513ac16b5616',
        0);
INSERT INTO Candidatura
VALUES ('63409ca7-7f16-4a80-97c3-3d34641801eb', '27614811982', NULL,
        2010,
        'd9adc26e-a49d-47c3-93a4-ee165bebbd3c',
        0);
INSERT INTO Candidatura
VALUES ('016b6227-8628-42b2-a3fc-e0b17dd52ba7', '47322499984', NULL,
        2014,
        'f91d0766-2157-4944-ab7f-513ac16b5616',
        0);
INSERT INTO Candidatura
VALUES ('4c4b01be-f156-409d-9fd9-bf14c4d89623', '71713129335', NULL,
        2012,
        'b9f92267-c96e-4fe6-ba55-5e8593e36310',
        0);
INSERT INTO Candidatura
VALUES ('2023f4e9-973e-4f7e-a802-ce668c2a9577', '82877426827', NULL,
        2010,
        '4c22eb15-0280-4f51-ad8d-c24f79bb442e',
        0);
INSERT INTO Candidatura
VALUES ('ee418562-06a5-421e-b141-ac5371b3797c', '21997365166', NULL,
        2020,
        'b9f92267-c96e-4fe6-ba55-5e8593e36310',
        0);
INSERT INTO Candidatura
VALUES ('987eb310-7a10-405f-a90c-71f626355261', '61750890677', NULL,
        2012,
        '5adccbbd-e44f-4318-9a98-0b1eaa2b4a81',
        0);
INSERT INTO Candidatura
VALUES ('95221f82-4244-46b2-8015-ebe742c6e6da', '99621701030', NULL,
        2016,
        '4c22eb15-0280-4f51-ad8d-c24f79bb442e',
        0);
INSERT INTO Candidatura
VALUES ('494fe253-ee42-40a0-96e6-682a413b4302', '53326698206', NULL,
        2010,
        '32996742-8098-46dc-9b82-8273266f6716',
        0);
INSERT INTO Candidatura
VALUES ('91a3a2dd-e286-4354-93a8-eba52c14a102', '27553708830', NULL,
        2016,
        '32996742-8098-46dc-9b82-8273266f6716',
        0);
INSERT INTO Candidatura
VALUES ('68c6606b-d157-4a29-bc9e-bd41941a6464', '32085399280', NULL,
        2014,
        '5adccbbd-e44f-4318-9a98-0b1eaa2b4a81',
        0);
INSERT INTO Candidatura
VALUES ('1604709a-2969-40a2-883d-b6881ac7733c', '50722760849', NULL,
        2018,
        'f91d0766-2157-4944-ab7f-513ac16b5616',
        0);
INSERT INTO Candidatura
VALUES ('86690188-e9fa-450f-a44b-b37a88a5ca39', '90507961907', NULL,
        2018,
        '4c22eb15-0280-4f51-ad8d-c24f79bb442e',
        0);
INSERT INTO Candidatura
VALUES ('3e378acc-2524-49b2-a811-f9c9da5e8382', '24439672860', NULL,
        2018,
        'f91d0766-2157-4944-ab7f-513ac16b5616',
        0);
INSERT INTO Candidatura
VALUES ('5dea280f-fc92-4eb1-bf63-28c7ddac1496', '33666146213', NULL,
        2012,
        '5adccbbd-e44f-4318-9a98-0b1eaa2b4a81',
        0);
INSERT INTO Candidatura
VALUES ('b388b6ab-8d74-4843-9ed6-8de3e0fd490e', '16205148608', NULL,
        2014,
        '5adccbbd-e44f-4318-9a98-0b1eaa2b4a81',
        0);
INSERT INTO Candidatura
VALUES ('69557033-c5dc-4baa-acf6-c94030ff6d15', '93827489160', NULL,
        2018,
        'd9adc26e-a49d-47c3-93a4-ee165bebbd3c',
        0);
INSERT INTO Candidatura
VALUES ('5ff570ec-591f-46f7-82dd-362e8027db46', '46842239857', NULL,
        2014,
        'f91d0766-2157-4944-ab7f-513ac16b5616',
        0);
INSERT INTO Candidatura
VALUES ('15aa38cd-857c-4915-ba41-b7437f4a528f', '70917615771', NULL,
        2020,
        'd9adc26e-a49d-47c3-93a4-ee165bebbd3c',
        0);
INSERT INTO Candidatura
VALUES ('297adce3-4ede-49ec-af4b-c90999b1ee08', '58344170006', NULL,
        2018,
        'd9adc26e-a49d-47c3-93a4-ee165bebbd3c',
        0);
INSERT INTO Candidatura
VALUES ('0ac9fcd2-8d47-44b1-9f35-a39e949f3d1f', '95569495800', NULL,
        2012,
        '4c22eb15-0280-4f51-ad8d-c24f79bb442e',
        0);
INSERT INTO Candidatura
VALUES ('32aaab2f-9a57-4c3f-a836-b44c5ea37808', '75949794522', NULL,
        2016,
        '5adccbbd-e44f-4318-9a98-0b1eaa2b4a81',
        0);
INSERT INTO Candidatura
VALUES ('2f740e91-1a6f-4c6f-8537-ac0a458f10cd', '35807526966', NULL,
        2018,
        '5adccbbd-e44f-4318-9a98-0b1eaa2b4a81',
        0);
INSERT INTO Candidatura
VALUES ('2903e693-e909-49b9-be4b-3c1c06527e06', '46037782656', NULL,
        2018,
        '32996742-8098-46dc-9b82-8273266f6716',
        0);
INSERT INTO Candidatura
VALUES ('e2075eb2-f24f-4e4b-b88e-08588978c3f7', '50740862700', NULL,
        2012,
        'f91d0766-2157-4944-ab7f-513ac16b5616',
        0);
INSERT INTO Candidatura
VALUES ('402c655d-c991-4894-8bd6-6924f3f2c0aa', '58672425325', NULL,
        2018,
        '5adccbbd-e44f-4318-9a98-0b1eaa2b4a81',
        0);
INSERT INTO Candidatura
VALUES ('cf12e04a-49c3-4635-8ad6-ef2dd4438dc3', '35566097435', NULL,
        2014,
        '32996742-8098-46dc-9b82-8273266f6716',
        0);
INSERT INTO Candidatura
VALUES ('f15bddba-5206-4998-9ade-c0268f23e206', '15567308135', NULL,
        2012,
        '5adccbbd-e44f-4318-9a98-0b1eaa2b4a81',
        0);
INSERT INTO Candidatura
VALUES ('105ddfc8-ce13-43ab-bbbb-089c38b2a6a3', '26077215422', NULL,
        2012,
        'f91d0766-2157-4944-ab7f-513ac16b5616',
        0);
INSERT INTO Candidatura
VALUES ('2e68e679-c0e9-40d0-b3fd-3fcb43240e71', '34482197472', NULL,
        2010,
        'b9f92267-c96e-4fe6-ba55-5e8593e36310',
        0);
INSERT INTO Candidatura
VALUES ('bda11d38-3481-4b1f-8adb-f41a36c36be2', '81989843735', NULL,
        2016,
        'b9f92267-c96e-4fe6-ba55-5e8593e36310',
        0);
INSERT INTO Candidatura
VALUES ('73d1d28c-128a-47c1-a5a9-442d3b531a87', '28806930759', NULL,
        2020,
        '32996742-8098-46dc-9b82-8273266f6716',
        0);
INSERT INTO Candidatura
VALUES ('33f3e34d-ae93-42d7-81f8-dfe888564b38', '13439644786', NULL,
        2016,
        'f91d0766-2157-4944-ab7f-513ac16b5616',
        0);
INSERT INTO Candidatura
VALUES ('959d424b-9b35-47a0-a513-d458a8d5ef38', '53600938739', NULL,
        2018,
        '4c22eb15-0280-4f51-ad8d-c24f79bb442e',
        0);
INSERT INTO Candidatura
VALUES ('a42f2fc3-d100-4e9b-b098-96dd5ba15add', '15346407331', NULL,
        2014,
        'b9f92267-c96e-4fe6-ba55-5e8593e36310',
        0);
INSERT INTO Candidatura
VALUES ('f0ce9306-5a82-4a8e-9e10-d2806b085ee4', '46951443084', NULL,
        2010,
        '5adccbbd-e44f-4318-9a98-0b1eaa2b4a81',
        0);
INSERT INTO Candidatura
VALUES ('0b2dfd9e-d707-41b0-9efc-3250ec2c1df8', '55553544007', NULL,
        2018,
        '32996742-8098-46dc-9b82-8273266f6716',
        0);
INSERT INTO Candidatura
VALUES ('6f71a191-8a52-4996-ad4a-f62d1e59b775', '25317057166', NULL,
        2016,
        'b9f92267-c96e-4fe6-ba55-5e8593e36310',
        0);
INSERT INTO Candidatura
VALUES ('22e594ff-eda0-407c-99bf-3d646fd30a8e', '17678079477', NULL,
        2012,
        'f91d0766-2157-4944-ab7f-513ac16b5616',
        0);
INSERT INTO Candidatura
VALUES ('a5b965c1-35c9-449f-9076-e0a6fa5d3103', '96162843727', NULL,
        2014,
        '32996742-8098-46dc-9b82-8273266f6716',
        0);
INSERT INTO Candidatura
VALUES ('2c8928a3-3e19-4e28-a8c5-0d0d5548b780', '23646102703', NULL,
        2014,
        'd9adc26e-a49d-47c3-93a4-ee165bebbd3c',
        0);
INSERT INTO Candidatura
VALUES ('9c167fc5-28c9-4fe5-b272-0166ced0354d', '87348033047', NULL,
        2014,
        'd9adc26e-a49d-47c3-93a4-ee165bebbd3c',
        0);
INSERT INTO Candidatura
VALUES ('57d0ebbe-8f17-4178-abc6-504b5533e83e', '93524363834', NULL,
        2012,
        'b9f92267-c96e-4fe6-ba55-5e8593e36310',
        0);
INSERT INTO Candidatura
VALUES ('4104f9ce-2903-4ea9-bf68-b6db1d2f9b28', '23977915302', NULL,
        2020,
        'd9adc26e-a49d-47c3-93a4-ee165bebbd3c',
        0);
INSERT INTO Candidatura
VALUES ('9e725987-bc6a-47bd-9ead-cd826958d360', '74748832648', NULL,
        2016,
        '32996742-8098-46dc-9b82-8273266f6716',
        0);
INSERT INTO Candidatura
VALUES ('6503b3c2-6cee-4a58-a18e-2f0978637e5a', '54927417181', NULL,
        2010,
        'd9adc26e-a49d-47c3-93a4-ee165bebbd3c',
        0);
INSERT INTO Candidatura
VALUES ('3bfc76f3-0406-4b14-b002-833ba5830301', '82239788295', NULL,
        2018,
        'f91d0766-2157-4944-ab7f-513ac16b5616',
        0);
INSERT INTO Candidatura
VALUES ('afd64293-5d94-4595-ae9e-a08acd3cfd8a', '73277497400', NULL,
        2018,
        '32996742-8098-46dc-9b82-8273266f6716',
        0);
INSERT INTO Candidatura
VALUES ('534fbcfc-c0f8-41d4-934f-d623f959aac9', '42148925778', NULL,
        2016,
        'f91d0766-2157-4944-ab7f-513ac16b5616',
        0);
INSERT INTO Candidatura
VALUES ('53f2e3ae-33f3-4e33-a266-cb54c8ba3ff3', '56274953270', NULL,
        2010,
        '5adccbbd-e44f-4318-9a98-0b1eaa2b4a81',
        0);
INSERT INTO Candidatura
VALUES ('089992fb-3f5a-4d4b-a0da-bebaa255f5bb', '48407140278', NULL,
        2012,
        'b9f92267-c96e-4fe6-ba55-5e8593e36310',
        0);
INSERT INTO Candidatura
VALUES ('ef24ffa7-755d-40b5-9909-3fbdfde0e1b6', '62152035068', NULL,
        2014,
        'd9adc26e-a49d-47c3-93a4-ee165bebbd3c',
        0);
INSERT INTO Candidatura
VALUES ('4fb359f5-f149-441d-af8a-3274f9d63e1a', '74856146364', NULL,
        2010,
        'd9adc26e-a49d-47c3-93a4-ee165bebbd3c',
        0);
INSERT INTO Candidatura
VALUES ('6253459f-d87d-4c13-addd-2dd5b2f4dac8', '81856962239', NULL,
        2018,
        'b9f92267-c96e-4fe6-ba55-5e8593e36310',
        0);
INSERT INTO Candidatura
VALUES ('3783c0ff-fc93-43a6-aba7-f9f94dd2698a', '44287939586', NULL,
        2014,
        '4c22eb15-0280-4f51-ad8d-c24f79bb442e',
        0);
INSERT INTO Candidatura
VALUES ('4b1dcf73-fb0f-4640-a82d-55b5a6de02c9', '99031375555', NULL,
        2020,
        'd9adc26e-a49d-47c3-93a4-ee165bebbd3c',
        0);
INSERT INTO Candidatura
VALUES ('5bc34570-37f6-403c-bb94-b5680b222e37', '53815103929', NULL,
        2010,
        'f91d0766-2157-4944-ab7f-513ac16b5616',
        0);
INSERT INTO Candidatura
VALUES ('7d48c51a-22be-4e56-bf7b-ce63f746abda', '92874572738', NULL,
        2020,
        'f91d0766-2157-4944-ab7f-513ac16b5616',
        0);
INSERT INTO Candidatura
VALUES ('fabafacf-74db-4de8-bd08-80363e6bf8ac', '11214965519', NULL,
        2014,
        '32996742-8098-46dc-9b82-8273266f6716',
        0);
INSERT INTO Candidatura
VALUES ('591dfa63-8618-40cb-b789-06d9c3dd5b03', '16354246530', NULL,
        2018,
        '32996742-8098-46dc-9b82-8273266f6716',
        0);
INSERT INTO Candidatura
VALUES ('4d43e49a-49d1-46fd-b1e3-1465a1415dcc', '45949940583', NULL,
        2014,
        '32996742-8098-46dc-9b82-8273266f6716',
        0);
INSERT INTO Candidatura
VALUES ('9f327d65-6cb1-4188-87ba-68330879c237', '84743212782', NULL,
        2010,
        '32996742-8098-46dc-9b82-8273266f6716',
        0);
INSERT INTO Candidatura
VALUES ('e8a0af5a-6683-463e-b79d-b01acd0250a8', '13409115150', NULL,
        2016,
        'd9adc26e-a49d-47c3-93a4-ee165bebbd3c',
        0);
INSERT INTO Candidatura
VALUES ('416f2525-118f-40da-b855-e5135f9c66d1', '98326434637', NULL,
        2020,
        '4c22eb15-0280-4f51-ad8d-c24f79bb442e',
        0);
INSERT INTO Candidatura
VALUES ('36e66fb3-2926-4f90-b1a6-9a203f1fda56', '38843407263', NULL,
        2014,
        '5adccbbd-e44f-4318-9a98-0b1eaa2b4a81',
        0);
INSERT INTO Candidatura
VALUES ('9301565f-fec2-4c68-b49b-7fa73d3af692', '64449079392', NULL,
        2016,
        'd9adc26e-a49d-47c3-93a4-ee165bebbd3c',
        0);
INSERT INTO Candidatura
VALUES ('2726cdd1-05af-48fa-80ce-35a8e027a019', '94982653530', NULL,
        2010,
        'd9adc26e-a49d-47c3-93a4-ee165bebbd3c',
        0);
INSERT INTO Candidatura
VALUES ('9d0a033b-e590-4dc6-a3ca-dc3006b0c77d', '41530032556', NULL,
        2010,
        '5adccbbd-e44f-4318-9a98-0b1eaa2b4a81',
        0);
INSERT INTO Candidatura
VALUES ('0f80c0c0-419a-4a57-9e97-05c318b00790', '29644463055', NULL,
        2010,
        'd9adc26e-a49d-47c3-93a4-ee165bebbd3c',
        0);
INSERT INTO Candidatura
VALUES ('5609512e-2359-49e5-ac67-2faeca1322bb', '89658641323', NULL,
        2016,
        'f91d0766-2157-4944-ab7f-513ac16b5616',
        0);
INSERT INTO Candidatura
VALUES ('fcee04cf-541b-43ac-baee-00cc0489ea49', '37795407914', NULL,
        2010,
        'd9adc26e-a49d-47c3-93a4-ee165bebbd3c',
        0);
INSERT INTO Candidatura
VALUES ('2c2ba771-292e-4fad-8fd8-b69638b67ea8', '12614989210', NULL,
        2016,
        'f91d0766-2157-4944-ab7f-513ac16b5616',
        0);
INSERT INTO Candidatura
VALUES ('b79c361d-bc3a-43fc-bfff-8563e7f7aeb2', '22216452944', NULL,
        2010,
        'b9f92267-c96e-4fe6-ba55-5e8593e36310',
        0);
INSERT INTO Candidatura
VALUES ('a9414437-cd9d-4581-8203-35c8e3a32953', '24567704398', NULL,
        2016,
        'f91d0766-2157-4944-ab7f-513ac16b5616',
        0);
INSERT INTO Candidatura
VALUES ('fcd0c2f4-f34c-43b1-81e8-3b337b237473', '63777786765', NULL,
        2018,
        'f91d0766-2157-4944-ab7f-513ac16b5616',
        0);
INSERT INTO Candidatura
VALUES ('85328b22-4980-4d41-b35e-337b273e1d31', '90085991316', NULL,
        2014,
        '32996742-8098-46dc-9b82-8273266f6716',
        0);
INSERT INTO Candidatura
VALUES ('ef50ef05-a50f-41fb-9278-864e06b0a974', '44480531623', NULL,
        2014,
        'b9f92267-c96e-4fe6-ba55-5e8593e36310',
        0);
INSERT INTO Candidatura
VALUES ('80379871-a0fb-4b6a-9f60-f0423c6c7501', '17017262971', NULL,
        2014,
        'd9adc26e-a49d-47c3-93a4-ee165bebbd3c',
        0);
INSERT INTO Candidatura
VALUES ('6589a19f-85ad-463d-b165-9eea51ff410e', '98058124845', NULL,
        2016,
        '32996742-8098-46dc-9b82-8273266f6716',
        0);
INSERT INTO Candidatura
VALUES ('985de1ee-f070-47ce-a287-4194cc644432', '44611691811', NULL,
        2012,
        'f91d0766-2157-4944-ab7f-513ac16b5616',
        0);
INSERT INTO Candidatura
VALUES ('df252e18-daaf-4885-bb57-764baa56043e', '21012337736', NULL,
        2016,
        '4c22eb15-0280-4f51-ad8d-c24f79bb442e',
        0);
INSERT INTO Candidatura
VALUES ('481e74e8-13f8-4d1e-b90a-c67e0015e6b5', '24722674724', NULL,
        2016,
        '5adccbbd-e44f-4318-9a98-0b1eaa2b4a81',
        0);
INSERT INTO Candidatura
VALUES ('890a4132-f791-463e-bf62-694771070844', '71670214808', NULL,
        2012,
        '32996742-8098-46dc-9b82-8273266f6716',
        0);
INSERT INTO Candidatura
VALUES ('0efdbe00-f460-4acf-acf0-a78dfd905ff1', '48909591054', NULL,
        2014,
        '4c22eb15-0280-4f51-ad8d-c24f79bb442e',
        0);
INSERT INTO Candidatura
VALUES ('c8b2f94f-2e92-4e2e-b30f-db65821ad04f', '51375660479', NULL,
        2012,
        'f91d0766-2157-4944-ab7f-513ac16b5616',
        0);
INSERT INTO Candidatura
VALUES ('9930a36e-1acf-4e80-9dd0-1f075a1d126f', '76136016375', NULL,
        2012,
        'b9f92267-c96e-4fe6-ba55-5e8593e36310',
        0);
INSERT INTO Candidatura
VALUES ('38724fef-5902-495f-997e-65600a482bc5', '12393648503', NULL,
        2020,
        '32996742-8098-46dc-9b82-8273266f6716',
        0);
INSERT INTO Candidatura
VALUES ('c6fcc4e3-9ec0-4f70-987d-aabd232e3bad', '28583832178', NULL,
        2014,
        'd9adc26e-a49d-47c3-93a4-ee165bebbd3c',
        0);
INSERT INTO Candidatura
VALUES ('884c3307-bc79-4be5-a0bc-5556f11a508d', '64631355758', NULL,
        2012,
        '32996742-8098-46dc-9b82-8273266f6716',
        0);
INSERT INTO Candidatura
VALUES ('bec1a6fa-44aa-43d4-92ca-278a959a8022', '76603942574', NULL,
        2018,
        '4c22eb15-0280-4f51-ad8d-c24f79bb442e',
        0);
INSERT INTO Candidatura
VALUES ('ce701bd0-8264-414c-9203-732090b2758d', '24846970050', NULL,
        2020,
        '32996742-8098-46dc-9b82-8273266f6716',
        0);
INSERT INTO Candidatura
VALUES ('b57d2a05-efc8-4e52-abce-b27822c08c10', '62271722485', NULL,
        2010,
        'b9f92267-c96e-4fe6-ba55-5e8593e36310',
        0);
INSERT INTO Candidatura
VALUES ('15212973-0f4e-41b1-9c28-83ac96619cc5', '16016930101', NULL,
        2012,
        'd9adc26e-a49d-47c3-93a4-ee165bebbd3c',
        0);
INSERT INTO Candidatura
VALUES ('ba3ba673-b8a3-497a-9cdc-6c3b25d7f94b', '23662008999', NULL,
        2020,
        'f91d0766-2157-4944-ab7f-513ac16b5616',
        0);
INSERT INTO Candidatura
VALUES ('8dc1cb84-50c9-4023-a07d-f14032294fd7', '87366192734', NULL,
        2016,
        'f91d0766-2157-4944-ab7f-513ac16b5616',
        0);
INSERT INTO Candidatura
VALUES ('d57f5410-460b-49c9-82f9-8b754a4fafed', '65871269844', NULL,
        2010,
        '4c22eb15-0280-4f51-ad8d-c24f79bb442e',
        0);
INSERT INTO Candidatura
VALUES ('6a4f136e-8027-4608-b475-d9986f778430', '10190151415', NULL,
        2020,
        'b9f92267-c96e-4fe6-ba55-5e8593e36310',
        0);
INSERT INTO Candidatura
VALUES ('44e02ed5-4d8b-41e5-a287-8fc5ccc6a2c2', '79579603821', NULL,
        2016,
        '4c22eb15-0280-4f51-ad8d-c24f79bb442e',
        0);
INSERT INTO Candidatura
VALUES ('7ffc95f7-858c-41dd-9e27-2b4fd1a70c3b', '83423976283', NULL,
        2018,
        '32996742-8098-46dc-9b82-8273266f6716',
        0);
INSERT INTO Candidatura
VALUES ('e0bb9e92-3c30-456a-9f5e-38c96a97bb75', '18723273822', NULL,
        2020,
        'b9f92267-c96e-4fe6-ba55-5e8593e36310',
        0);
INSERT INTO Candidatura
VALUES ('c5c7d952-98bf-4354-b22e-1cc01ec63178', '72005313155', NULL,
        2010,
        '4c22eb15-0280-4f51-ad8d-c24f79bb442e',
        0);
INSERT INTO Candidatura
VALUES ('33b92e04-b9fc-47c8-9fbb-8e7bcdb9fe61', '77440287217', NULL,
        2014,
        'b9f92267-c96e-4fe6-ba55-5e8593e36310',
        0);
INSERT INTO Candidatura
VALUES ('8d1ed05b-a004-4bf1-af63-f96b52e0baca', '63629505806', NULL,
        2016,
        'f91d0766-2157-4944-ab7f-513ac16b5616',
        0);
INSERT INTO Candidatura
VALUES ('e46e47eb-61a6-445a-ac4b-4aafa735940d', '79950719017', NULL,
        2016,
        '5adccbbd-e44f-4318-9a98-0b1eaa2b4a81',
        0);
INSERT INTO Candidatura
VALUES ('fefd9228-cb63-4b98-84ae-7bc57c5d5e2c', '42436610548', NULL,
        2010,
        '4c22eb15-0280-4f51-ad8d-c24f79bb442e',
        0);
INSERT INTO Candidatura
VALUES ('711818fa-8264-413a-a9fe-36d9534a0910', '52920149751', NULL,
        2012,
        '5adccbbd-e44f-4318-9a98-0b1eaa2b4a81',
        0);
INSERT INTO Candidatura
VALUES ('e4682f84-f820-4b26-b14c-bb3104fed3d1', '11719256164', NULL,
        2014,
        'd9adc26e-a49d-47c3-93a4-ee165bebbd3c',
        0);
INSERT INTO Candidatura
VALUES ('c073459a-ef72-484c-8c9e-35a6be317e10', '19822962293', NULL,
        2020,
        'd9adc26e-a49d-47c3-93a4-ee165bebbd3c',
        0);
INSERT INTO Candidatura
VALUES ('937954ac-2618-4fef-af38-33fae0400da6', '86761833312', NULL,
        2016,
        '5adccbbd-e44f-4318-9a98-0b1eaa2b4a81',
        0);
INSERT INTO Candidatura
VALUES ('a38e25c0-adc3-435c-99cd-1df58cc907ff', '97532397126', NULL,
        2014,
        '4c22eb15-0280-4f51-ad8d-c24f79bb442e',
        0);
INSERT INTO Candidatura
VALUES ('f6e36c33-ee09-413d-86e4-db0a19f56193', '19756374296', NULL,
        2020,
        '5adccbbd-e44f-4318-9a98-0b1eaa2b4a81',
        0);
INSERT INTO Candidatura
VALUES ('1b1f022a-f6f4-4765-9b1b-0c355a6aa6dc', '44259705774', NULL,
        2018,
        '4c22eb15-0280-4f51-ad8d-c24f79bb442e',
        0);
INSERT INTO Candidatura
VALUES ('84592088-be07-4a06-8da4-c9e1a062950d', '91077021027', NULL,
        2020,
        '32996742-8098-46dc-9b82-8273266f6716',
        0);
INSERT INTO Candidatura
VALUES ('c6a07501-5ba6-49de-a607-9aea8cc7ba10', '65191834932', NULL,
        2010,
        'b9f92267-c96e-4fe6-ba55-5e8593e36310',
        0);
INSERT INTO Candidatura
VALUES ('5ca383a5-7ad6-4c54-a204-d56ae2946116', '24291245951', NULL,
        2010,
        'd9adc26e-a49d-47c3-93a4-ee165bebbd3c',
        0);
INSERT INTO Candidatura
VALUES ('297f1929-22be-4b55-87ae-be428e034073', '47835368167', NULL,
        2010,
        'b9f92267-c96e-4fe6-ba55-5e8593e36310',
        0);
INSERT INTO Candidatura
VALUES ('66cb420f-34e2-470b-aacd-7fefde69b4cd', '48617187398', NULL,
        2016,
        '4c22eb15-0280-4f51-ad8d-c24f79bb442e',
        0);
INSERT INTO Candidatura
VALUES ('3f5a2894-b511-4a4e-885b-0dc22b71903a', '16635875334', NULL,
        2016,
        '4c22eb15-0280-4f51-ad8d-c24f79bb442e',
        0);
INSERT INTO Candidatura
VALUES ('43777765-e725-41e0-aaa6-9f7b7981afa4', '87706230955', NULL,
        2014,
        '5adccbbd-e44f-4318-9a98-0b1eaa2b4a81',
        0);
INSERT INTO Candidatura
VALUES ('45ccdd0e-a9cc-49e6-b1fc-b0dc38975289', '55815897535', NULL,
        2014,
        '5adccbbd-e44f-4318-9a98-0b1eaa2b4a81',
        0);
INSERT INTO Candidatura
VALUES ('1125e5ca-21df-4191-819a-88be41e85fe0', '29543020694', NULL,
        2014,
        'd9adc26e-a49d-47c3-93a4-ee165bebbd3c',
        0);
INSERT INTO Candidatura
VALUES ('57d0d20f-a099-4bb9-9733-93c5e613880b', '71007887653', NULL,
        2016,
        '4c22eb15-0280-4f51-ad8d-c24f79bb442e',
        0);
INSERT INTO Candidatura
VALUES ('c430ae9b-6795-431a-a14d-2f4fc9360d0f', '95178695621', NULL,
        2020,
        '5adccbbd-e44f-4318-9a98-0b1eaa2b4a81',
        0);
INSERT INTO Candidatura
VALUES ('c79e0ceb-247b-4ff0-8ef7-89b8d843394b', '53485558112', NULL,
        2020,
        '32996742-8098-46dc-9b82-8273266f6716',
        0);
INSERT INTO Candidatura
VALUES ('c08070bf-f52e-4efe-abf6-15d391d60c08', '42206480598', NULL,
        2020,
        '4c22eb15-0280-4f51-ad8d-c24f79bb442e',
        0);
INSERT INTO Candidatura
VALUES ('7c180492-4c56-4b4f-b7d8-232fcb269ff6', '34295891087', NULL,
        2014,
        '32996742-8098-46dc-9b82-8273266f6716',
        0);
INSERT INTO Candidatura
VALUES ('1f087b92-f408-4e38-a5d5-9a2fdbdfad97', '75472573232', NULL,
        2018,
        '32996742-8098-46dc-9b82-8273266f6716',
        0);
INSERT INTO Candidatura
VALUES ('91c731a4-eb77-4bb6-bb72-e5593ecce2bf', '96399192840', NULL,
        2018,
        'f91d0766-2157-4944-ab7f-513ac16b5616',
        0);
INSERT INTO Candidatura
VALUES ('659192c8-284a-4333-ad8c-7e2e0b962257', '33861935359', NULL,
        2016,
        '32996742-8098-46dc-9b82-8273266f6716',
        0);
INSERT INTO Candidatura
VALUES ('219881cd-04c6-4932-88c8-99038ec52c7e', '64684924166', NULL,
        2014,
        '4c22eb15-0280-4f51-ad8d-c24f79bb442e',
        0);
INSERT INTO Candidatura
VALUES ('c158bef2-b8ff-4eb0-b184-22faa4bc9a4e', '36536230433', NULL,
        2016,
        'b9f92267-c96e-4fe6-ba55-5e8593e36310',
        0);
INSERT INTO Candidatura
VALUES ('56e572e8-5d66-49f0-a98d-7069e2fa30b5', '32780581086', NULL,
        2010,
        'f91d0766-2157-4944-ab7f-513ac16b5616',
        0);
INSERT INTO Candidatura
VALUES ('72ad6dee-38be-4bbb-923f-bacb5a6bf406', '68663108202', NULL,
        2014,
        'd9adc26e-a49d-47c3-93a4-ee165bebbd3c',
        0);
INSERT INTO Candidatura
VALUES ('d6dae31b-c186-452c-9b17-0431f2189124', '76986037665', NULL,
        2012,
        'f91d0766-2157-4944-ab7f-513ac16b5616',
        0);
INSERT INTO Candidatura
VALUES ('2057c1a4-2055-4c9c-ac0d-b403a9493df7', '79631428855', NULL,
        2012,
        'f91d0766-2157-4944-ab7f-513ac16b5616',
        0);
INSERT INTO Candidatura
VALUES ('68f39bdb-1983-4a3f-8497-9fd46986e435', '63150170790', NULL,
        2010,
        '32996742-8098-46dc-9b82-8273266f6716',
        0);
INSERT INTO Candidatura
VALUES ('16e9b439-0a12-4b0d-932f-a293a0633f74', '86271196368', NULL,
        2016,
        '32996742-8098-46dc-9b82-8273266f6716',
        0);
INSERT INTO Candidatura
VALUES ('46de6358-0f39-4910-89d2-6bccf52e0838', '90251854406', NULL,
        2016,
        'b9f92267-c96e-4fe6-ba55-5e8593e36310',
        0);
INSERT INTO Candidatura
VALUES ('c8a6914f-e543-40bf-b929-61a7755f91c0', '57093701930', NULL,
        2018,
        'f91d0766-2157-4944-ab7f-513ac16b5616',
        0);
INSERT INTO Candidatura
VALUES ('9db5ce88-8b93-4160-b23b-3fae0f59c2f2', '66261561494', NULL,
        2010,
        'd9adc26e-a49d-47c3-93a4-ee165bebbd3c',
        0);
INSERT INTO Candidatura
VALUES ('99d9c466-36ce-4b8b-a89b-6d58eb0d010a', '40792622072', NULL,
        2016,
        '32996742-8098-46dc-9b82-8273266f6716',
        0);
INSERT INTO Candidatura
VALUES ('ba1fbadd-5d97-432d-b83d-0387648332ca', '28458227536', NULL,
        2020,
        'b9f92267-c96e-4fe6-ba55-5e8593e36310',
        0);
INSERT INTO Candidatura
VALUES ('ccf50d24-5e18-4a35-a7c6-6df9ac8f08ef', '30904407899', NULL,
        2020,
        'b9f92267-c96e-4fe6-ba55-5e8593e36310',
        0);
INSERT INTO Candidatura
VALUES ('a843ef8b-a9d3-40fd-b3c9-de7f94509f5f', '36030380690', NULL,
        2010,
        '4c22eb15-0280-4f51-ad8d-c24f79bb442e',
        0);
INSERT INTO Candidatura
VALUES ('b857c28f-c992-497b-8496-4493cfe0ffab', '56126027428', NULL,
        2020,
        'f91d0766-2157-4944-ab7f-513ac16b5616',
        0);
INSERT INTO Candidatura
VALUES ('d659bb2a-fb45-48c8-a7b8-538e4fc6dce6', '68520916590', NULL,
        2018,
        'b9f92267-c96e-4fe6-ba55-5e8593e36310',
        0);
INSERT INTO Candidatura
VALUES ('8b61a4ce-ca83-4c8b-b646-5c289e01db33', '77598187436', NULL,
        2020,
        'f91d0766-2157-4944-ab7f-513ac16b5616',
        0);
INSERT INTO Candidatura
VALUES ('00b67e70-3b60-44ef-a757-e051be64eb7f', '37764165711', NULL,
        2014,
        'f91d0766-2157-4944-ab7f-513ac16b5616',
        0);
INSERT INTO Candidatura
VALUES ('a68b4a1a-bf51-4905-908f-ed81997a5d4b', '97948715968', NULL,
        2020,
        '32996742-8098-46dc-9b82-8273266f6716',
        0);
INSERT INTO Candidatura
VALUES ('c2e5ed73-25e8-4519-a108-229d3cd7bd3c', '68579267167', NULL,
        2018,
        '4c22eb15-0280-4f51-ad8d-c24f79bb442e',
        0);
INSERT INTO Candidatura
VALUES ('5c81ab61-8823-4b74-80b3-1215be408397', '16846755656', NULL,
        2012,
        '5adccbbd-e44f-4318-9a98-0b1eaa2b4a81',
        0);
INSERT INTO Candidatura
VALUES ('8603e7a1-d255-4bd5-b007-d56e01ac7d81', '15525305538', NULL,
        2012,
        '32996742-8098-46dc-9b82-8273266f6716',
        0);
INSERT INTO Candidatura
VALUES ('640c02c4-23ad-4705-aef1-969848c57df6', '96735474125', NULL,
        2012,
        'f91d0766-2157-4944-ab7f-513ac16b5616',
        0);
INSERT INTO Candidatura
VALUES ('fd095140-410d-43a2-a4a8-146a04bffcb1', '27274558073', NULL,
        2020,
        '32996742-8098-46dc-9b82-8273266f6716',
        0);
INSERT INTO Candidatura
VALUES ('de6649bb-2379-4278-b98e-203ac64ab21d', '11138060991', NULL,
        2020,
        'b9f92267-c96e-4fe6-ba55-5e8593e36310',
        0);
INSERT INTO Candidatura
VALUES ('2ab56aae-6acd-45c2-a7c9-c26db3736169', '68928154059', NULL,
        2012,
        'b9f92267-c96e-4fe6-ba55-5e8593e36310',
        0);
INSERT INTO Candidatura
VALUES ('1a2d9145-0ebd-4afa-be0d-bce3110364a2', '42809196475', NULL,
        2020,
        '32996742-8098-46dc-9b82-8273266f6716',
        0);
INSERT INTO Candidatura
VALUES ('5f861330-813a-4fdb-b72b-6aedc881e24e', '24799374230', NULL,
        2020,
        'd9adc26e-a49d-47c3-93a4-ee165bebbd3c',
        0);
INSERT INTO Candidatura
VALUES ('caba4fc5-db56-4364-bed1-0693e7b40090', '89233355857', NULL,
        2016,
        '5adccbbd-e44f-4318-9a98-0b1eaa2b4a81',
        0);
INSERT INTO Candidatura
VALUES ('c86a48c3-7ed8-46c3-879d-173172bcbbf6', '99875636277', NULL,
        2016,
        'b9f92267-c96e-4fe6-ba55-5e8593e36310',
        0);
INSERT INTO Candidatura
VALUES ('2e88f6ad-992a-4ab4-a623-0971d123bef5', '37324441201', NULL,
        2020,
        'f91d0766-2157-4944-ab7f-513ac16b5616',
        0);
INSERT INTO Candidatura
VALUES ('c415b9f0-dfef-4259-8330-6b5330ab8b4d', '64004827691', NULL,
        2016,
        '4c22eb15-0280-4f51-ad8d-c24f79bb442e',
        0);
INSERT INTO Candidatura
VALUES ('815b61df-2c36-4ff7-9ca5-c4d9c2d1fa5e', '35014395120', NULL,
        2018,
        '32996742-8098-46dc-9b82-8273266f6716',
        0);
INSERT INTO Candidatura
VALUES ('3c2e43d4-ca92-407a-a4ae-442825469da0', '96993769449', NULL,
        2012,
        '5adccbbd-e44f-4318-9a98-0b1eaa2b4a81',
        0);
INSERT INTO Candidatura
VALUES ('851513fa-b276-4c1d-8be8-a0f452a62c12', '44908207063', NULL,
        2016,
        'b9f92267-c96e-4fe6-ba55-5e8593e36310',
        0);
INSERT INTO Candidatura
VALUES ('56f4f16e-288f-40ba-b3bd-c7586037d0ae', '39996799803', NULL,
        2014,
        'f91d0766-2157-4944-ab7f-513ac16b5616',
        0);
INSERT INTO Candidatura
VALUES ('38b54a41-ea7f-4f5e-bb9c-f7a73651df59', '68110109437', NULL,
        2014,
        'b9f92267-c96e-4fe6-ba55-5e8593e36310',
        0);
INSERT INTO Candidatura
VALUES ('13e7bcfc-69c9-4d52-b734-480699016a9d', '79857502803', NULL,
        2014,
        'f91d0766-2157-4944-ab7f-513ac16b5616',
        0);
INSERT INTO Candidatura
VALUES ('b582c851-e756-4efa-b9b5-70744b6b1020', '72898224287', NULL,
        2010,
        '4c22eb15-0280-4f51-ad8d-c24f79bb442e',
        0);
INSERT INTO Candidatura
VALUES ('640f433b-d510-4411-b3b5-57a06940939d', '94086229731', NULL,
        2018,
        'b9f92267-c96e-4fe6-ba55-5e8593e36310',
        0);
INSERT INTO Candidatura
VALUES ('e3e9536b-8e35-441f-8d47-d65b68501adb', '87208565492', NULL,
        2010,
        'f91d0766-2157-4944-ab7f-513ac16b5616',
        0);
INSERT INTO Candidatura
VALUES ('514e9986-b391-4756-bfb4-616320d98dc2', '39180499266', NULL,
        2014,
        'f91d0766-2157-4944-ab7f-513ac16b5616',
        0);
INSERT INTO Candidatura
VALUES ('94b73206-c83f-4ceb-be7a-18dba349fcc2', '30165319882', NULL,
        2014,
        'f91d0766-2157-4944-ab7f-513ac16b5616',
        0);
INSERT INTO Candidatura
VALUES ('dee5de45-10ed-4393-b711-0e98e204a8e4', '40928985222', NULL,
        2012,
        '32996742-8098-46dc-9b82-8273266f6716',
        0);
INSERT INTO Candidatura
VALUES ('7295e3a3-57fa-41bc-a530-44b32826903c', '44860848870', NULL,
        2014,
        '4c22eb15-0280-4f51-ad8d-c24f79bb442e',
        0);
INSERT INTO Candidatura
VALUES ('87afcf6f-8c30-4348-a7cc-493b46efa8b8', '74766249782', NULL,
        2010,
        '5adccbbd-e44f-4318-9a98-0b1eaa2b4a81',
        0);
INSERT INTO Candidatura
VALUES ('eeec1312-892d-453b-89cb-76947e59df09', '15051016972', NULL,
        2020,
        'b9f92267-c96e-4fe6-ba55-5e8593e36310',
        0);
INSERT INTO Candidatura
VALUES ('8f50fbe3-520f-491d-95ae-4c1e5861410b', '77664967630', NULL,
        2010,
        '32996742-8098-46dc-9b82-8273266f6716',
        0);
INSERT INTO Candidatura
VALUES ('ab43adca-dd0d-4348-a779-b8c8c8fcf8f9', '54207576885', NULL,
        2016,
        'd9adc26e-a49d-47c3-93a4-ee165bebbd3c',
        0);
INSERT INTO Candidatura
VALUES ('6cb79bb4-351a-46ef-b1ea-79f45f67f5c0', '42681556036', NULL,
        2018,
        'd9adc26e-a49d-47c3-93a4-ee165bebbd3c',
        0);
INSERT INTO Candidatura
VALUES ('ee717286-8f2d-4f33-b191-fe78358f32b5', '37029771979', NULL,
        2010,
        'b9f92267-c96e-4fe6-ba55-5e8593e36310',
        0);
INSERT INTO Candidatura
VALUES ('c1efb915-877d-4260-89c5-a0bbf73f153d', '93058234590', NULL,
        2012,
        'b9f92267-c96e-4fe6-ba55-5e8593e36310',
        0);
INSERT INTO Candidatura
VALUES ('8a9076ea-ceb0-4f0a-b8a8-330770dcbfe8', '61740416085', NULL,
        2014,
        'b9f92267-c96e-4fe6-ba55-5e8593e36310',
        0);
INSERT INTO Candidatura
VALUES ('41040666-f86d-4621-bf5c-c429a33bde6e', '12976033654', NULL,
        2012,
        'f91d0766-2157-4944-ab7f-513ac16b5616',
        0);
INSERT INTO Candidatura
VALUES ('13a3590c-c471-4076-bc0c-7bdffb1cb0db', '34451081710', NULL,
        2010,
        '4c22eb15-0280-4f51-ad8d-c24f79bb442e',
        0);
INSERT INTO Candidatura
VALUES ('3e62fbcc-7f0b-4452-a4c5-b555facf2649', '54988852173', NULL,
        2014,
        '4c22eb15-0280-4f51-ad8d-c24f79bb442e',
        0);
INSERT INTO Candidatura
VALUES ('d22f14ed-3c15-4d63-8187-4adfdb71f319', '61664271336', NULL,
        2012,
        'd9adc26e-a49d-47c3-93a4-ee165bebbd3c',
        0);
INSERT INTO Candidatura
VALUES ('32943a04-0ac8-4a6a-8930-173d555ff846', '49630068878', NULL,
        2020,
        '5adccbbd-e44f-4318-9a98-0b1eaa2b4a81',
        0);
INSERT INTO Candidatura
VALUES ('6d689799-c3b8-47d6-9fa9-97297a5c3f57', '14925663892', NULL,
        2018,
        'b9f92267-c96e-4fe6-ba55-5e8593e36310',
        0);
INSERT INTO Candidatura
VALUES ('267c40ce-30e1-4b96-8875-844e1d93b987', '21988119990', NULL,
        2018,
        'f91d0766-2157-4944-ab7f-513ac16b5616',
        0);
INSERT INTO Candidatura
VALUES ('3418ef88-c75e-4831-ad57-9f40d63555e5', '79759818490', NULL,
        2010,
        '4c22eb15-0280-4f51-ad8d-c24f79bb442e',
        0);
INSERT INTO Candidatura
VALUES ('be7ca7b4-fa4c-4847-bf8a-fc5d7f2c9f26', '69257088878', NULL,
        2014,
        'f91d0766-2157-4944-ab7f-513ac16b5616',
        0);
INSERT INTO Candidatura
VALUES ('0930484e-3141-498f-8805-7df270d5aed9', '82694570559', NULL,
        2014,
        '4c22eb15-0280-4f51-ad8d-c24f79bb442e',
        0);
INSERT INTO Candidatura
VALUES ('321973cc-8766-4f96-8772-fb0271169f9e', '77949062872', NULL,
        2018,
        'b9f92267-c96e-4fe6-ba55-5e8593e36310',
        0);
INSERT INTO Candidatura
VALUES ('0c3e0e9e-f5d0-433b-ba13-9a275a7398c7', '49541541982', NULL,
        2018,
        'f91d0766-2157-4944-ab7f-513ac16b5616',
        0);
INSERT INTO Candidatura
VALUES ('b97a7a11-3b22-45c0-9e4f-1b7b04b6f416', '88995994818', NULL,
        2014,
        'd9adc26e-a49d-47c3-93a4-ee165bebbd3c',
        0);
INSERT INTO Candidatura
VALUES ('edeb3d56-2f60-4fb3-ab5f-e52173b4847f', '13684269834', NULL,
        2014,
        '5adccbbd-e44f-4318-9a98-0b1eaa2b4a81',
        0);
INSERT INTO Candidatura
VALUES ('58ecb8ed-85f8-409e-9f4e-90c4e40bb3db', '56800358914', NULL,
        2014,
        '4c22eb15-0280-4f51-ad8d-c24f79bb442e',
        0);
INSERT INTO Candidatura
VALUES ('190edd00-228b-4894-9b3a-8019ddd95295', '54613564885', NULL,
        2014,
        'd9adc26e-a49d-47c3-93a4-ee165bebbd3c',
        0);
INSERT INTO Candidatura
VALUES ('9cd06905-6f12-4b3c-8a18-d7672301d585', '98651677060', NULL,
        2020,
        'd9adc26e-a49d-47c3-93a4-ee165bebbd3c',
        0);
INSERT INTO Candidatura
VALUES ('4c61a472-269b-4cbc-a22d-a3b00f50a644', '60364329223', NULL,
        2016,
        '32996742-8098-46dc-9b82-8273266f6716',
        0);
INSERT INTO Candidatura
VALUES ('da3c33ec-35aa-4f42-9a21-b398716e789d', '40367657486', NULL,
        2012,
        '32996742-8098-46dc-9b82-8273266f6716',
        0);
INSERT INTO Candidatura
VALUES ('33e3ebaf-04e6-48f9-b796-0157b29f2469', '52453071193', NULL,
        2014,
        'f91d0766-2157-4944-ab7f-513ac16b5616',
        0);
INSERT INTO Candidatura
VALUES ('d8c07196-ef29-485b-809d-6492dbcf2731', '44197359627', NULL,
        2012,
        '5adccbbd-e44f-4318-9a98-0b1eaa2b4a81',
        0);
INSERT INTO Candidatura
VALUES ('f4ad2505-9bea-489d-9ab0-7b15fb4ea854', '60122351620', NULL,
        2016,
        'b9f92267-c96e-4fe6-ba55-5e8593e36310',
        0);
INSERT INTO Candidatura
VALUES ('3247bc4a-0a18-48c5-8dde-ae54069cc989', '63185736755', NULL,
        2018,
        'b9f92267-c96e-4fe6-ba55-5e8593e36310',
        0);
INSERT INTO Candidatura
VALUES ('0986fa74-d1da-44c0-a2d9-fa536fc19bf4', '37769212496', NULL,
        2010,
        'f91d0766-2157-4944-ab7f-513ac16b5616',
        0);
INSERT INTO Candidatura
VALUES ('77bc8e81-8f01-4e5d-989d-1c8bb9b15c83', '46404720542', NULL,
        2010,
        'd9adc26e-a49d-47c3-93a4-ee165bebbd3c',
        0);
INSERT INTO Candidatura
VALUES ('62e87de6-318a-4b26-a85c-177a23a9b203', '43316695608', NULL,
        2014,
        'd9adc26e-a49d-47c3-93a4-ee165bebbd3c',
        0);
INSERT INTO Candidatura
VALUES ('1521fce6-863e-44a5-8831-b81da3f09780', '56392738602', NULL,
        2020,
        'b9f92267-c96e-4fe6-ba55-5e8593e36310',
        0);
INSERT INTO Candidatura
VALUES ('56a90d9c-08bf-40bf-bc40-0cdec9f785cf', '24243827324', NULL,
        2018,
        '5adccbbd-e44f-4318-9a98-0b1eaa2b4a81',
        0);
INSERT INTO Candidatura
VALUES ('bd306737-fc69-4061-8243-9be3242d6feb', '45290986180', NULL,
        2010,
        '5adccbbd-e44f-4318-9a98-0b1eaa2b4a81',
        0);
INSERT INTO Candidatura
VALUES ('e8cc7195-02e1-42ed-ad72-ba6aa621df46', '34712144928', NULL,
        2016,
        '4c22eb15-0280-4f51-ad8d-c24f79bb442e',
        0);
INSERT INTO Candidatura
VALUES ('56690ac5-ef35-468a-b4d7-6b51c03d71e2', '49993791026', NULL,
        2012,
        '32996742-8098-46dc-9b82-8273266f6716',
        0);
INSERT INTO Candidatura
VALUES ('bd58d1f9-2ebb-4678-82dc-808391f2be40', '55661978677', NULL,
        2014,
        '32996742-8098-46dc-9b82-8273266f6716',
        0);
INSERT INTO Candidatura
VALUES ('8d1c6964-5432-48e7-a3e1-1536739eaad4', '39221640580', NULL,
        2020,
        '5adccbbd-e44f-4318-9a98-0b1eaa2b4a81',
        0);
INSERT INTO Candidatura
VALUES ('98329dbb-4ab8-4695-8eda-e3f0cbe8f772', '27882795822', NULL,
        2012,
        'f91d0766-2157-4944-ab7f-513ac16b5616',
        0);
INSERT INTO Candidatura
VALUES ('48b5e119-d9e6-4cd7-a22f-b1dbe455dbe4', '57082543941', NULL,
        2010,
        'b9f92267-c96e-4fe6-ba55-5e8593e36310',
        0);
INSERT INTO Candidatura
VALUES ('ffb278af-8af8-47eb-8f95-2cf921d947b7', '29649122953', NULL,
        2020,
        '4c22eb15-0280-4f51-ad8d-c24f79bb442e',
        0);
INSERT INTO Candidatura
VALUES ('c93a41cf-0a2f-442e-bc7a-7a7b4d17217e', '17156520811', NULL,
        2016,
        'd9adc26e-a49d-47c3-93a4-ee165bebbd3c',
        0);
INSERT INTO Candidatura
VALUES ('54bbd357-a345-427e-a7a8-e497929dc9c9', '12587690399', NULL,
        2014,
        'd9adc26e-a49d-47c3-93a4-ee165bebbd3c',
        0);
INSERT INTO Candidatura
VALUES ('ce4a5e04-1132-4a7e-8618-5de0e43021e1', '18233533741', NULL,
        2020,
        'd9adc26e-a49d-47c3-93a4-ee165bebbd3c',
        0);
INSERT INTO Candidatura
VALUES ('a5b9c626-dc41-4989-bcf1-303d3e9a4c12', '28406533049', NULL,
        2012,
        'b9f92267-c96e-4fe6-ba55-5e8593e36310',
        0);
INSERT INTO Candidatura
VALUES ('3fe1c2f0-4e52-4a0c-8bca-25efd589dda0', '50569366908', NULL,
        2020,
        '4c22eb15-0280-4f51-ad8d-c24f79bb442e',
        0);
INSERT INTO Candidatura
VALUES ('d6132a5c-2d98-4219-a9e2-770383420edb', '18437136497', NULL,
        2016,
        'd9adc26e-a49d-47c3-93a4-ee165bebbd3c',
        0);
INSERT INTO Candidatura
VALUES ('ac46448c-6473-44ea-b7ef-6d223320e7cb', '38951155769', NULL,
        2020,
        'f91d0766-2157-4944-ab7f-513ac16b5616',
        0);
INSERT INTO Candidatura
VALUES ('d8c9c6c0-b593-47cb-8f7e-56561c435dd9', '51445510021', NULL,
        2012,
        '32996742-8098-46dc-9b82-8273266f6716',
        0);
INSERT INTO Candidatura
VALUES ('3a799fea-11ae-466c-9022-f9c6be416a8a', '32271739926', NULL,
        2012,
        'd9adc26e-a49d-47c3-93a4-ee165bebbd3c',
        0);
INSERT INTO Candidatura
VALUES ('b9626d6b-79a5-4d35-8662-bf9462182e25', '62067907205', NULL,
        2014,
        '4c22eb15-0280-4f51-ad8d-c24f79bb442e',
        0);
INSERT INTO Candidatura
VALUES ('74d4bb98-f437-4b5d-9d30-750badbbd606', '42256481919', NULL,
        2012,
        '4c22eb15-0280-4f51-ad8d-c24f79bb442e',
        0);
INSERT INTO Candidatura
VALUES ('281e1a33-c428-4795-9d17-5df70c3021ca', '45378367919', NULL,
        2020,
        'f91d0766-2157-4944-ab7f-513ac16b5616',
        0);
INSERT INTO Candidatura
VALUES ('afb6fdbb-79bc-4631-b49a-83e5c2421281', '90374537745', NULL,
        2012,
        '32996742-8098-46dc-9b82-8273266f6716',
        0);
INSERT INTO Candidatura
VALUES ('140cd5be-ed69-4a9d-8e49-93f6b928f867', '81480079204', NULL,
        2020,
        'd9adc26e-a49d-47c3-93a4-ee165bebbd3c',
        0);
INSERT INTO Candidatura
VALUES ('74aea8d0-c2d4-41b5-ae48-ec59d6a890ad', '94529897822', NULL,
        2010,
        'd9adc26e-a49d-47c3-93a4-ee165bebbd3c',
        0);
INSERT INTO Candidatura
VALUES ('299b4c15-c400-483e-8a20-35c02ebae851', '31668141162', NULL,
        2018,
        '32996742-8098-46dc-9b82-8273266f6716',
        0);
INSERT INTO Candidatura
VALUES ('a162ac72-4be3-44c6-9c4a-8018be6c84d0', '77198284929', NULL,
        2016,
        '32996742-8098-46dc-9b82-8273266f6716',
        0);
INSERT INTO Candidatura
VALUES ('0ca9b602-ccca-485c-9390-dd30a1688d72', '89536202107', NULL,
        2016,
        'd9adc26e-a49d-47c3-93a4-ee165bebbd3c',
        0);
INSERT INTO Candidatura
VALUES ('12a8fba9-a47b-4096-a926-34085e6ffed4', '84538009271', NULL,
        2016,
        'd9adc26e-a49d-47c3-93a4-ee165bebbd3c',
        0);
INSERT INTO Candidatura
VALUES ('92a69a75-66c8-4286-88f4-f840b6b0149d', '89778357343', NULL,
        2014,
        'f91d0766-2157-4944-ab7f-513ac16b5616',
        0);
INSERT INTO Candidatura
VALUES ('ce80c2c0-7ff3-4b7c-8902-5f8c19659eb1', '69316593371', NULL,
        2012,
        '5adccbbd-e44f-4318-9a98-0b1eaa2b4a81',
        0);
INSERT INTO Candidatura
VALUES ('6ecf2052-603b-43fd-a735-89c321b21039', '26499034971', NULL,
        2012,
        '32996742-8098-46dc-9b82-8273266f6716',
        0);
INSERT INTO Candidatura
VALUES ('4dbc5c65-f436-44f7-8bbe-996b68c09ebe', '34354209771', NULL,
        2018,
        'f91d0766-2157-4944-ab7f-513ac16b5616',
        0);
INSERT INTO Candidatura
VALUES ('c72f952e-401a-4202-9c77-29d8f915b624', '83672753747', NULL,
        2018,
        '4c22eb15-0280-4f51-ad8d-c24f79bb442e',
        0);
INSERT INTO Candidatura
VALUES ('17ea4d9d-0f64-4e28-ba58-3ae56e8d66c8', '93187630493', NULL,
        2012,
        '32996742-8098-46dc-9b82-8273266f6716',
        0);
INSERT INTO Candidatura
VALUES ('59f90db8-4b94-4a88-9454-811831b54965', '35535540033', NULL,
        2016,
        'f91d0766-2157-4944-ab7f-513ac16b5616',
        0);
INSERT INTO Candidatura
VALUES ('a68c5eb7-a872-478c-b134-1f456cd762cc', '86202337315', NULL,
        2016,
        'b9f92267-c96e-4fe6-ba55-5e8593e36310',
        0);
INSERT INTO Candidatura
VALUES ('b9cd8513-9e4f-4cad-bd3e-c291b918a517', '29039845638', NULL,
        2014,
        '4c22eb15-0280-4f51-ad8d-c24f79bb442e',
        0);
INSERT INTO Candidatura
VALUES ('eb999932-087b-496e-939d-fc14e5795ace', '77959251704', NULL,
        2018,
        '4c22eb15-0280-4f51-ad8d-c24f79bb442e',
        0);
INSERT INTO Candidatura
VALUES ('d29153b1-19d5-4d53-8297-c1ed6ea45983', '83222212893', NULL,
        2012,
        '32996742-8098-46dc-9b82-8273266f6716',
        0);


-- Insere Equipes de Apoio
INSERT INTO Equipe_Apoio
VALUES ('e07ab672-ae21-4a0c-b47f-beefd1254a35', 'ba3ba673-b8a3-497a-9cdc-6c3b25d7f94b', 2012, 'Apoiar Movimentos');
INSERT INTO Equipe_Apoio
VALUES ('f0dca2ac-0c04-46c5-b90c-c76b8efc0f91', '0ca9b602-ccca-485c-9390-dd30a1688d72', 2010, 'Apoiar Movimentos');
INSERT INTO Equipe_Apoio
VALUES ('1b9cb8b6-4ea4-44ec-a293-ceff141dbc00', 'd57f5410-460b-49c9-82f9-8b754a4fafed', 2010, 'Marketing');
INSERT INTO Equipe_Apoio
VALUES ('633aa71a-9e24-47aa-97a9-21e91dceffbf', '48b5e119-d9e6-4cd7-a22f-b1dbe455dbe4', 2014, 'Comunicação com o Eleitor');
INSERT INTO Equipe_Apoio
VALUES ('1d8c13a2-cc8c-45b8-b253-c283ad9727a5', '7ffc95f7-858c-41dd-9e27-2b4fd1a70c3b', 2012, 'Apoiar Movimentos');
INSERT INTO Equipe_Apoio
VALUES ('e4a07462-93c8-4f6e-b83c-d4eaafaf1e7c', 'a68c5eb7-a872-478c-b134-1f456cd762cc', 2018, 'Arrecador Fundos');
INSERT INTO Equipe_Apoio
VALUES ('db46858a-2b0b-4680-9f7d-b49998199618', '2057c1a4-2055-4c9c-ac0d-b403a9493df7', 2012, 'Marketing');
INSERT INTO Equipe_Apoio
VALUES ('25f47f1e-19e8-4a2b-be05-6a0bbfa097de', 'd22f14ed-3c15-4d63-8187-4adfdb71f319', 2010, 'Comunicação com o Eleitor');
INSERT INTO Equipe_Apoio
VALUES ('532fa460-a154-49fb-9d61-2bfbcd5d72e5', '46de6358-0f39-4910-89d2-6bccf52e0838', 2020, 'Marketing');
INSERT INTO Equipe_Apoio
VALUES ('df8340ef-abdc-4405-af8d-68b2a4ec9825', '8a9076ea-ceb0-4f0a-b8a8-330770dcbfe8', 2016, 'Marketing');
INSERT INTO Equipe_Apoio
VALUES ('1658c6fd-49cc-4141-ad4f-6f8105b18027', 'e4682f84-f820-4b26-b14c-bb3104fed3d1', 2016, 'Apoiar Movimentos');
INSERT INTO Equipe_Apoio
VALUES ('b68ee998-6a1c-4faf-920f-0b5ac190c691', '890a4132-f791-463e-bf62-694771070844', 2016, 'Comunicação com o Eleitor');
INSERT INTO Equipe_Apoio
VALUES ('fc59f5a1-9759-4fa2-a15f-9ea7fae48d5f', '2057c1a4-2055-4c9c-ac0d-b403a9493df7', 2010, 'Arrecador Fundos');
INSERT INTO Equipe_Apoio
VALUES ('4753c42c-beda-463b-a48c-dc72265f11b3', 'ce701bd0-8264-414c-9203-732090b2758d', 2012, 'Apoiar Movimentos');
INSERT INTO Equipe_Apoio
VALUES ('5fc4c231-6aa8-4a4a-b04c-3500c1bc7d00', 'b97a7a11-3b22-45c0-9e4f-1b7b04b6f416', 2016, 'Comunicação com o Eleitor');
INSERT INTO Equipe_Apoio
VALUES ('fbbc4c3a-6e46-432d-8b78-8560d0e7ad2b', 'c158bef2-b8ff-4eb0-b184-22faa4bc9a4e', 2018, 'Arrecador Fundos');
INSERT INTO Equipe_Apoio
VALUES ('6935a37a-e972-46a3-9d11-f2fa629839f1', '29f7ed80-7bbf-417a-bc54-73d54df821ee', 2020, 'Arrecador Fundos');
INSERT INTO Equipe_Apoio
VALUES ('e82aa877-7ba5-4edb-ab77-a2e6b2d94014', '62e87de6-318a-4b26-a85c-177a23a9b203', 2014, 'Marketing');
INSERT INTO Equipe_Apoio
VALUES ('dbe76bbf-43ab-4f41-a637-52dd16d86a3d', '7a67eebf-a357-4a42-938c-b16e07a8a9d4', 2012, 'Comunicação com o Eleitor');
INSERT INTO Equipe_Apoio
VALUES ('28352cb9-2177-4176-a039-374f7ece90c8', 'c8b2f94f-2e92-4e2e-b30f-db65821ad04f', 2016, 'Marketing');
INSERT INTO Equipe_Apoio
VALUES ('b3647076-f29f-4f4d-8b48-7cee68f1f9b8', '640c02c4-23ad-4705-aef1-969848c57df6', 2010, 'Apoiar Movimentos');
INSERT INTO Equipe_Apoio
VALUES ('28f90047-1be8-4087-bb28-50197fc432d8', 'a9414437-cd9d-4581-8203-35c8e3a32953', 2020, 'Arrecador Fundos');
INSERT INTO Equipe_Apoio
VALUES ('337a966c-bd35-444d-be24-2f0908c7d629', '9e725987-bc6a-47bd-9ead-cd826958d360', 2012, 'Arrecador Fundos');
INSERT INTO Equipe_Apoio
VALUES ('b681896d-315e-49ac-ad3e-79b44ba98ebc', 'ce4a5e04-1132-4a7e-8618-5de0e43021e1', 2010, 'Comunicação com o Eleitor');
INSERT INTO Equipe_Apoio
VALUES ('bb10d35a-1942-4cc2-90a1-d691f2f0c5b1', '8e3ff9b2-d8f6-4b35-92ab-a727242efd2e', 2020, 'Arrecador Fundos');
INSERT INTO Equipe_Apoio
VALUES ('8df25899-f660-4805-840d-acd3136d8fc9', '15aa38cd-857c-4915-ba41-b7437f4a528f', 2018, 'Arrecador Fundos');
INSERT INTO Equipe_Apoio
VALUES ('bc002a74-d6b5-485f-8148-ec0c53ff4254', 'abeae1bf-75d5-4c54-8bfd-c2cc4f933864', 2010, 'Comunicação com o Eleitor');
INSERT INTO Equipe_Apoio
VALUES ('c2f108ef-3247-4101-9586-322bdafceb26', '7ffc95f7-858c-41dd-9e27-2b4fd1a70c3b', 2020, 'Apoiar Movimentos');
INSERT INTO Equipe_Apoio
VALUES ('6f46983a-98ab-4d4e-b6db-1808eb081bec', '640c02c4-23ad-4705-aef1-969848c57df6', 2020, 'Marketing');
INSERT INTO Equipe_Apoio
VALUES ('e79861d6-1da6-478b-8fc5-6029f3df5895', 'b57d2a05-efc8-4e52-abce-b27822c08c10', 2016, 'Apoiar Movimentos');
INSERT INTO Equipe_Apoio
VALUES ('34902105-4b19-4c5e-9625-decc41d7f888', 'a42f2fc3-d100-4e9b-b098-96dd5ba15add', 2014, 'Arrecador Fundos');
INSERT INTO Equipe_Apoio
VALUES ('517707cd-392f-4357-91d0-32f93e5c317e', 'b70416e5-1a2c-40be-8ce3-97d4c6324ce5', 2012, 'Apoiar Movimentos');
INSERT INTO Equipe_Apoio
VALUES ('1158bcfd-87ad-4334-a4bf-9feed6e4b6c0', '4c4b01be-f156-409d-9fd9-bf14c4d89623', 2010, 'Arrecador Fundos');
INSERT INTO Equipe_Apoio
VALUES ('b765c522-b0a6-4cb2-945e-503849ff6c83', 'ab43adca-dd0d-4348-a779-b8c8c8fcf8f9', 2014, 'Apoiar Movimentos');
INSERT INTO Equipe_Apoio
VALUES ('641dd373-04ce-4db1-9537-d498568af853', '0930484e-3141-498f-8805-7df270d5aed9', 2010, 'Comunicação com o Eleitor');
INSERT INTO Equipe_Apoio
VALUES ('da94979e-5cae-4b13-8d17-df8cea859966', '3e378acc-2524-49b2-a811-f9c9da5e8382', 2012, 'Marketing');
INSERT INTO Equipe_Apoio
VALUES ('25090d6a-97db-4ce3-af57-0172c0633213', 'ef50ef05-a50f-41fb-9278-864e06b0a974', 2012, 'Comunicação com o Eleitor');
INSERT INTO Equipe_Apoio
VALUES ('66c8ad39-3b9b-4286-9775-67f4d4005dab', '30c516bf-c593-4548-bfc4-47b329487851', 2018, 'Arrecador Fundos');
INSERT INTO Equipe_Apoio
VALUES ('060c5184-a866-4913-8490-db2819031188', 'db1046ca-5c7e-48ac-a1c1-7d942a9acd7b', 2014, 'Apoiar Movimentos');
INSERT INTO Equipe_Apoio
VALUES ('93d0cb45-b867-4785-9eb9-364f6e5eae17', 'c72f952e-401a-4202-9c77-29d8f915b624', 2018, 'Apoiar Movimentos');
INSERT INTO Equipe_Apoio
VALUES ('5934494c-fc11-4cd5-84a3-5bc9e3ed5825', 'e8a0af5a-6683-463e-b79d-b01acd0250a8', 2014, 'Arrecador Fundos');
INSERT INTO Equipe_Apoio
VALUES ('e9764d7c-fed6-41db-86aa-be0817899735', 'e46e47eb-61a6-445a-ac4b-4aafa735940d', 2010, 'Apoiar Movimentos');
INSERT INTO Equipe_Apoio
VALUES ('d1229e26-2128-44d4-8263-624f2ce3a5f6', '10035cc3-7557-4ee1-b9ad-54ac61a06964', 2020, 'Marketing');
INSERT INTO Equipe_Apoio
VALUES ('0d95b1d3-f32c-4cf1-a495-36bd2a10179c', '6503b3c2-6cee-4a58-a18e-2f0978637e5a', 2018, 'Comunicação com o Eleitor');
INSERT INTO Equipe_Apoio
VALUES ('e4804907-e499-4ef3-b776-c4ddcccd14b8', '257540c7-8f7d-4bef-9239-9b037fa1cb3c', 2018, 'Arrecador Fundos');
INSERT INTO Equipe_Apoio
VALUES ('41c8fea7-10d5-4e8a-b7bd-e739f7e465ce', 'ab43adca-dd0d-4348-a779-b8c8c8fcf8f9', 2016, 'Arrecador Fundos');
INSERT INTO Equipe_Apoio
VALUES ('7f69102e-aed1-4082-bd70-d20e5bb8bf0b', '5efec858-80bd-4121-a359-02b9ece2d0ec', 2010, 'Comunicação com o Eleitor');
INSERT INTO Equipe_Apoio
VALUES ('8fae5094-12f9-4192-941a-e2c37e7e2292', '0ca9b602-ccca-485c-9390-dd30a1688d72', 2016, 'Arrecador Fundos');
INSERT INTO Equipe_Apoio
VALUES ('63601471-a526-49fc-ad89-b4ee22ada854', 'a68b4a1a-bf51-4905-908f-ed81997a5d4b', 2020, 'Arrecador Fundos');
INSERT INTO Equipe_Apoio
VALUES ('53521a31-ce2a-409b-bee7-38e096fcd7ba', '33b92e04-b9fc-47c8-9fbb-8e7bcdb9fe61', 2010, 'Marketing');
INSERT INTO Equipe_Apoio
VALUES ('c797565a-73d4-448d-810a-4f147c5b4f10', '0b2dfd9e-d707-41b0-9efc-3250ec2c1df8', 2018, 'Arrecador Fundos');
INSERT INTO Equipe_Apoio
VALUES ('8f090ff5-ab45-41d9-bd3d-a04f55149033', 'f959a757-7d2e-48ec-bb9e-bc670795cb80', 2016, 'Marketing');
INSERT INTO Equipe_Apoio
VALUES ('2b65c0bb-9b45-4fe5-aaeb-b6aeff00edc7', '44e02ed5-4d8b-41e5-a287-8fc5ccc6a2c2', 2020, 'Comunicação com o Eleitor');
INSERT INTO Equipe_Apoio
VALUES ('1213586f-b88b-4203-a479-786704bf5f8f', '640c02c4-23ad-4705-aef1-969848c57df6', 2010, 'Marketing');
INSERT INTO Equipe_Apoio
VALUES ('b6ca2df2-81ff-41c9-a8bb-f52b13a4b278', '99d9c466-36ce-4b8b-a89b-6d58eb0d010a', 2014, 'Marketing');
INSERT INTO Equipe_Apoio
VALUES ('b9a71b94-c0bb-41e5-bd9e-266d596bf40d', '5efec858-80bd-4121-a359-02b9ece2d0ec', 2018, 'Apoiar Movimentos');
INSERT INTO Equipe_Apoio
VALUES ('fd687264-54e1-4c02-aefa-7be8d4fbcde0', '4c3bdf70-dba9-4eb2-8241-97f524f8bc5d', 2014, 'Comunicação com o Eleitor');
INSERT INTO Equipe_Apoio
VALUES ('5ff62aa0-5ba3-4209-88b5-ee5158920330', 'c065728c-8515-4f4c-bd6f-8e77b47f510f', 2010, 'Arrecador Fundos');
INSERT INTO Equipe_Apoio
VALUES ('c1ed2445-7ee6-408c-b7cb-5fb711af6ed6', '016b6227-8628-42b2-a3fc-e0b17dd52ba7', 2020, 'Apoiar Movimentos');
INSERT INTO Equipe_Apoio
VALUES ('2c331bbb-e115-4227-96f0-21904f17b37e', 'fd095140-410d-43a2-a4a8-146a04bffcb1', 2014, 'Apoiar Movimentos');
INSERT INTO Equipe_Apoio
VALUES ('f7ae535d-b0d7-4147-963a-60a6921d46f7', '56a90d9c-08bf-40bf-bc40-0cdec9f785cf', 2014, 'Apoiar Movimentos');
INSERT INTO Equipe_Apoio
VALUES ('cd3ee000-035b-4e94-b7fb-84889c33d0a0', '56a90d9c-08bf-40bf-bc40-0cdec9f785cf', 2010, 'Apoiar Movimentos');
INSERT INTO Equipe_Apoio
VALUES ('4c9d47c6-698f-4ff6-907f-dcdc87a90539', '08f6b5d0-c507-46b8-9b7b-aa5248e63ffa', 2012, 'Marketing');
INSERT INTO Equipe_Apoio
VALUES ('b01dc2dc-fc26-4005-94cc-0f80187a44ac', 'afb6fdbb-79bc-4631-b49a-83e5c2421281', 2014, 'Marketing');
INSERT INTO Equipe_Apoio
VALUES ('be4c705d-9d27-42f4-a661-4571d880c395', 'e2075eb2-f24f-4e4b-b88e-08588978c3f7', 2014, 'Comunicação com o Eleitor');
INSERT INTO Equipe_Apoio
VALUES ('e7a21f3d-7b6d-4fd5-bc52-b0d66d91294b', '38b54a41-ea7f-4f5e-bb9c-f7a73651df59', 2010, 'Marketing');
INSERT INTO Equipe_Apoio
VALUES ('fe277883-6a14-4ff6-8ee9-b5e297c1aef2', 'a4aa2b71-8be1-45a1-9c63-059d3ea1e544', 2012, 'Apoiar Movimentos');
INSERT INTO Equipe_Apoio
VALUES ('f8236523-7c6a-4905-b090-9b9dba1f848e', 'c8b2f94f-2e92-4e2e-b30f-db65821ad04f', 2016, 'Apoiar Movimentos');
INSERT INTO Equipe_Apoio
VALUES ('b261737b-682e-483e-8872-185bdb6d111d', '74aea8d0-c2d4-41b5-ae48-ec59d6a890ad', 2014, 'Apoiar Movimentos');
INSERT INTO Equipe_Apoio
VALUES ('d15bb041-28c3-40d2-a3d1-f59bc4842ef8', 'e3e9536b-8e35-441f-8d47-d65b68501adb', 2014, 'Arrecador Fundos');
INSERT INTO Equipe_Apoio
VALUES ('f82b5022-30ea-435e-ab4f-faf67060e06d', '3bfc76f3-0406-4b14-b002-833ba5830301', 2016, 'Arrecador Fundos');
INSERT INTO Equipe_Apoio
VALUES ('c255b224-b7c1-488a-bd3b-bf64ab564ba0', '53238421-e94b-4a86-b15c-2003b00f2845', 2010, 'Marketing');
INSERT INTO Equipe_Apoio
VALUES ('b137e052-4cc2-4742-b441-f54d7567cd48', '85328b22-4980-4d41-b35e-337b273e1d31', 2020, 'Arrecador Fundos');
INSERT INTO Equipe_Apoio
VALUES ('5cf209f6-1e0c-47ed-b833-7b837aadf92b', '5b1182b7-da73-478f-8d8c-47388fb2a9b1', 2018, 'Arrecador Fundos');
INSERT INTO Equipe_Apoio
VALUES ('7a9b1944-5b18-45c3-aa78-fc1cdb4e6f31', '4b1dcf73-fb0f-4640-a82d-55b5a6de02c9', 2010, 'Marketing');
INSERT INTO Equipe_Apoio
VALUES ('43202e6f-63e5-419d-8805-5372b979551b', '33e3ebaf-04e6-48f9-b796-0157b29f2469', 2012, 'Arrecador Fundos');
INSERT INTO Equipe_Apoio
VALUES ('7f015f17-3990-4247-b520-a7b5407e8ba1', 'afd64293-5d94-4595-ae9e-a08acd3cfd8a', 2018, 'Marketing');
INSERT INTO Equipe_Apoio
VALUES ('b2011c63-8648-4ab4-9274-eec1abcdae13', '5b1182b7-da73-478f-8d8c-47388fb2a9b1', 2012, 'Apoiar Movimentos');
INSERT INTO Equipe_Apoio
VALUES ('4ec11dcb-8a30-4d70-90e3-067fbb3aa0f3', 'db1046ca-5c7e-48ac-a1c1-7d942a9acd7b', 2018, 'Apoiar Movimentos');
INSERT INTO Equipe_Apoio
VALUES ('067fb1bb-a026-402e-bc4e-dd1330ef4f76', '73d1d28c-128a-47c1-a5a9-442d3b531a87', 2020, 'Apoiar Movimentos');
INSERT INTO Equipe_Apoio
VALUES ('3d44897e-3818-4bc3-9611-7b722aebc1c1', '68f39bdb-1983-4a3f-8497-9fd46986e435', 2010, 'Comunicação com o Eleitor');
INSERT INTO Equipe_Apoio
VALUES ('7aaec61d-b866-4f93-bb1f-53fee4353714', '0efdbe00-f460-4acf-acf0-a78dfd905ff1', 2016, 'Comunicação com o Eleitor');
INSERT INTO Equipe_Apoio
VALUES ('309f7259-8987-4295-92e2-fc80966438b8', '4104f9ce-2903-4ea9-bf68-b6db1d2f9b28', 2014, 'Marketing');
INSERT INTO Equipe_Apoio
VALUES ('e80bce56-1604-4fd2-9280-e2997e0db865', '56e572e8-5d66-49f0-a98d-7069e2fa30b5', 2020, 'Comunicação com o Eleitor');
INSERT INTO Equipe_Apoio
VALUES ('408e1a56-2a64-4589-a7bc-033380a7a419', 'a42f2fc3-d100-4e9b-b098-96dd5ba15add', 2016, 'Marketing');
INSERT INTO Equipe_Apoio
VALUES ('4d459a87-ac6c-4afc-b940-ff3c4d0282f6', '43777765-e725-41e0-aaa6-9f7b7981afa4', 2010, 'Comunicação com o Eleitor');
INSERT INTO Equipe_Apoio
VALUES ('130cc387-6214-4cef-8054-f7935c8caf8b', '36e66fb3-2926-4f90-b1a6-9a203f1fda56', 2014, 'Apoiar Movimentos');
INSERT INTO Equipe_Apoio
VALUES ('327185aa-a85e-4f29-89b0-974eaf9bc2be', '68c6606b-d157-4a29-bc9e-bd41941a6464', 2010, 'Apoiar Movimentos');
INSERT INTO Equipe_Apoio
VALUES ('c67d1de2-ab8f-4d9a-bb02-66a5b48427e8', 'c8b2f94f-2e92-4e2e-b30f-db65821ad04f', 2020, 'Arrecador Fundos');
INSERT INTO Equipe_Apoio
VALUES ('66098c88-f2c9-4e0a-b333-7064c3f59d75', '771af538-92a3-41e6-bc5c-f015e2f418e6', 2018, 'Apoiar Movimentos');
INSERT INTO Equipe_Apoio
VALUES ('3260e081-80e6-4d78-9265-162183ac92de', '45ccdd0e-a9cc-49e6-b1fc-b0dc38975289', 2020, 'Arrecador Fundos');
INSERT INTO Equipe_Apoio
VALUES ('8a7d3b1a-6e7c-4422-a2e2-da639adf8e89', '9930a36e-1acf-4e80-9dd0-1f075a1d126f', 2018, 'Marketing');
INSERT INTO Equipe_Apoio
VALUES ('f7cd2730-b5d0-4716-a589-fd7ed0d5a2cd', 'a5b965c1-35c9-449f-9076-e0a6fa5d3103', 2012, 'Marketing');
INSERT INTO Equipe_Apoio
VALUES ('174bd15a-db6b-4e3f-81f8-b6e9ef4329fc', 'b0350cf5-b002-4d30-a6f0-a9c7f704af51', 2020, 'Marketing');
INSERT INTO Equipe_Apoio
VALUES ('94a2c461-d1a0-48c4-b09c-f67ed0660e45', 'c8a6914f-e543-40bf-b929-61a7755f91c0', 2014, 'Marketing');
INSERT INTO Equipe_Apoio
VALUES ('066419fb-a940-491c-a3f6-ab57eb805088', 'c6fcc4e3-9ec0-4f70-987d-aabd232e3bad', 2010, 'Apoiar Movimentos');
INSERT INTO Equipe_Apoio
VALUES ('74fc33c4-3f9a-49d7-ae53-4b76f59ca7e7', '5f861330-813a-4fdb-b72b-6aedc881e24e', 2012, 'Marketing');
INSERT INTO Equipe_Apoio
VALUES ('b717772d-39c3-448b-85c4-1cd401bd1489', '267c40ce-30e1-4b96-8875-844e1d93b987', 2012, 'Marketing');
INSERT INTO Equipe_Apoio
VALUES ('ba544ca5-43e4-4163-af1f-abaca3d79cc2', '6ecf2052-603b-43fd-a735-89c321b21039', 2010, 'Apoiar Movimentos');
INSERT INTO Equipe_Apoio
VALUES ('2416783e-849d-4f0e-8557-8a788cc76d7c', '8186c655-c026-491f-8828-2c5eea1ee135', 2018, 'Marketing');


-- Insere Apoiadores de Campanha
INSERT INTO Apoiador_Campanha
VALUES ('94a2c461-d1a0-48c4-b09c-f67ed0660e45', '75698780661', '7a67eebf-a357-4a42-938c-b16e07a8a9d4');
INSERT INTO Apoiador_Campanha
VALUES ('c2f108ef-3247-4101-9586-322bdafceb26', '71902848579', '0986fa74-d1da-44c0-a2d9-fa536fc19bf4');
INSERT INTO Apoiador_Campanha
VALUES ('2c331bbb-e115-4227-96f0-21904f17b37e', '97253314054', '9930a36e-1acf-4e80-9dd0-1f075a1d126f');
INSERT INTO Apoiador_Campanha
VALUES ('0d95b1d3-f32c-4cf1-a495-36bd2a10179c', '14297463551', '297f1929-22be-4b55-87ae-be428e034073');
INSERT INTO Apoiador_Campanha
VALUES ('2416783e-849d-4f0e-8557-8a788cc76d7c', '27577754918', 'ce80c2c0-7ff3-4b7c-8902-5f8c19659eb1');
INSERT INTO Apoiador_Campanha
VALUES ('2b65c0bb-9b45-4fe5-aaeb-b6aeff00edc7', '64122301510', '2903e693-e909-49b9-be4b-3c1c06527e06');
INSERT INTO Apoiador_Campanha
VALUES ('f7ae535d-b0d7-4147-963a-60a6921d46f7', '44453197566', '2e88f6ad-992a-4ab4-a623-0971d123bef5');
INSERT INTO Apoiador_Campanha
VALUES ('2416783e-849d-4f0e-8557-8a788cc76d7c', '57456171549', '57d0ebbe-8f17-4178-abc6-504b5533e83e');
INSERT INTO Apoiador_Campanha
VALUES ('1658c6fd-49cc-4141-ad4f-6f8105b18027', '74298426869', 'c08070bf-f52e-4efe-abf6-15d391d60c08');
INSERT INTO Apoiador_Campanha
VALUES ('1158bcfd-87ad-4334-a4bf-9feed6e4b6c0', '71301379678', 'a4aa2b71-8be1-45a1-9c63-059d3ea1e544');
INSERT INTO Apoiador_Campanha
VALUES ('66c8ad39-3b9b-4286-9775-67f4d4005dab', '79021790616', '2ab56aae-6acd-45c2-a7c9-c26db3736169');
INSERT INTO Apoiador_Campanha
VALUES ('060c5184-a866-4913-8490-db2819031188', '71713188239', 'afd64293-5d94-4595-ae9e-a08acd3cfd8a');
INSERT INTO Apoiador_Campanha
VALUES ('e4a07462-93c8-4f6e-b83c-d4eaafaf1e7c', '97763730341', '10035cc3-7557-4ee1-b9ad-54ac61a06964');
INSERT INTO Apoiador_Campanha
VALUES ('b2011c63-8648-4ab4-9274-eec1abcdae13', '89630639564', 'a5b965c1-35c9-449f-9076-e0a6fa5d3103');
INSERT INTO Apoiador_Campanha
VALUES ('633aa71a-9e24-47aa-97a9-21e91dceffbf', '16300685813', 'a7abab5c-cc2e-42da-b021-06ccdf28a382');
INSERT INTO Apoiador_Campanha
VALUES ('633aa71a-9e24-47aa-97a9-21e91dceffbf', '32333718526', 'c158bef2-b8ff-4eb0-b184-22faa4bc9a4e');
INSERT INTO Apoiador_Campanha
VALUES ('be4c705d-9d27-42f4-a661-4571d880c395', '41031348041', '692ce1fd-dcdc-47e5-a050-dbe937bfc708');
INSERT INTO Apoiador_Campanha
VALUES ('94a2c461-d1a0-48c4-b09c-f67ed0660e45', '51161424755', '105ddfc8-ce13-43ab-bbbb-089c38b2a6a3');
INSERT INTO Apoiador_Campanha
VALUES ('517707cd-392f-4357-91d0-32f93e5c317e', '16716102720', '2e88f6ad-992a-4ab4-a623-0971d123bef5');
INSERT INTO Apoiador_Campanha
VALUES ('066419fb-a940-491c-a3f6-ab57eb805088', '64122301510', '2e88f6ad-992a-4ab4-a623-0971d123bef5');
INSERT INTO Apoiador_Campanha
VALUES ('34902105-4b19-4c5e-9625-decc41d7f888', '63419523332', 'a68c5eb7-a872-478c-b134-1f456cd762cc');
INSERT INTO Apoiador_Campanha
VALUES ('94a2c461-d1a0-48c4-b09c-f67ed0660e45', '60306908786', 'a9414437-cd9d-4581-8203-35c8e3a32953');
INSERT INTO Apoiador_Campanha
VALUES ('74fc33c4-3f9a-49d7-ae53-4b76f59ca7e7', '27781179496', '591dfa63-8618-40cb-b789-06d9c3dd5b03');
INSERT INTO Apoiador_Campanha
VALUES ('130cc387-6214-4cef-8054-f7935c8caf8b', '72265644003', '4c3bdf70-dba9-4eb2-8241-97f524f8bc5d');
INSERT INTO Apoiador_Campanha
VALUES ('e82aa877-7ba5-4edb-ab77-a2e6b2d94014', '85147762342', '74aea8d0-c2d4-41b5-ae48-ec59d6a890ad');
INSERT INTO Apoiador_Campanha
VALUES ('2b65c0bb-9b45-4fe5-aaeb-b6aeff00edc7', '41520086317', 'a68c5eb7-a872-478c-b134-1f456cd762cc');
INSERT INTO Apoiador_Campanha
VALUES ('c2f108ef-3247-4101-9586-322bdafceb26', '57456171549', '16e9b439-0a12-4b0d-932f-a293a0633f74');
INSERT INTO Apoiador_Campanha
VALUES ('532fa460-a154-49fb-9d61-2bfbcd5d72e5', '71301379678', '0efdbe00-f460-4acf-acf0-a78dfd905ff1');
INSERT INTO Apoiador_Campanha
VALUES ('8df25899-f660-4805-840d-acd3136d8fc9', '47134191666', '4b1dcf73-fb0f-4640-a82d-55b5a6de02c9');
INSERT INTO Apoiador_Campanha
VALUES ('be4c705d-9d27-42f4-a661-4571d880c395', '26663710535', '17ea4d9d-0f64-4e28-ba58-3ae56e8d66c8');
INSERT INTO Apoiador_Campanha
VALUES ('4ec11dcb-8a30-4d70-90e3-067fbb3aa0f3', '45841697754', '105ddfc8-ce13-43ab-bbbb-089c38b2a6a3');
INSERT INTO Apoiador_Campanha
VALUES ('7a9b1944-5b18-45c3-aa78-fc1cdb4e6f31', '17000984330', '77bc8e81-8f01-4e5d-989d-1c8bb9b15c83');
INSERT INTO Apoiador_Campanha
VALUES ('e80bce56-1604-4fd2-9280-e2997e0db865', '94071586923', 'ca885acd-0110-4a3f-9852-414bb2bf15c2');
INSERT INTO Apoiador_Campanha
VALUES ('1213586f-b88b-4203-a479-786704bf5f8f', '31951113061', '80379871-a0fb-4b6a-9f60-f0423c6c7501');
INSERT INTO Apoiador_Campanha
VALUES ('1158bcfd-87ad-4334-a4bf-9feed6e4b6c0', '53504122414', '66cb420f-34e2-470b-aacd-7fefde69b4cd');
INSERT INTO Apoiador_Campanha
VALUES ('1213586f-b88b-4203-a479-786704bf5f8f', '76983075961', 'a69d95ce-fec2-48db-a4c2-b5bb36e78ef7');
INSERT INTO Apoiador_Campanha
VALUES ('8a7d3b1a-6e7c-4422-a2e2-da639adf8e89', '24488041764', '8e3ff9b2-d8f6-4b35-92ab-a727242efd2e');
INSERT INTO Apoiador_Campanha
VALUES ('641dd373-04ce-4db1-9537-d498568af853', '90832039350', '1b1f022a-f6f4-4765-9b1b-0c355a6aa6dc');
INSERT INTO Apoiador_Campanha
VALUES ('5934494c-fc11-4cd5-84a3-5bc9e3ed5825', '44453197566', '33e3ebaf-04e6-48f9-b796-0157b29f2469');
INSERT INTO Apoiador_Campanha
VALUES ('25090d6a-97db-4ce3-af57-0172c0633213', '57748351241', '8dc1cb84-50c9-4023-a07d-f14032294fd7');
INSERT INTO Apoiador_Campanha
VALUES ('fd687264-54e1-4c02-aefa-7be8d4fbcde0', '31480855625', '640f433b-d510-4411-b3b5-57a06940939d');
INSERT INTO Apoiador_Campanha
VALUES ('174bd15a-db6b-4e3f-81f8-b6e9ef4329fc', '59657050718', '5ca383a5-7ad6-4c54-a204-d56ae2946116');
INSERT INTO Apoiador_Campanha
VALUES ('b717772d-39c3-448b-85c4-1cd401bd1489', '42662608220', 'c158bef2-b8ff-4eb0-b184-22faa4bc9a4e');
INSERT INTO Apoiador_Campanha
VALUES ('3260e081-80e6-4d78-9265-162183ac92de', '68096587185', 'ee418562-06a5-421e-b141-ac5371b3797c');
INSERT INTO Apoiador_Campanha
VALUES ('25090d6a-97db-4ce3-af57-0172c0633213', '16300685813', '771af538-92a3-41e6-bc5c-f015e2f418e6');
INSERT INTO Apoiador_Campanha
VALUES ('63601471-a526-49fc-ad89-b4ee22ada854', '97353540891', '281e1a33-c428-4795-9d17-5df70c3021ca');
INSERT INTO Apoiador_Campanha
VALUES ('b9a71b94-c0bb-41e5-bd9e-266d596bf40d', '64255168652', 'de6649bb-2379-4278-b98e-203ac64ab21d');
INSERT INTO Apoiador_Campanha
VALUES ('5ff62aa0-5ba3-4209-88b5-ee5158920330', '76328378601', '9cd06905-6f12-4b3c-8a18-d7672301d585');
INSERT INTO Apoiador_Campanha
VALUES ('2b65c0bb-9b45-4fe5-aaeb-b6aeff00edc7', '14172927623', 'a69d95ce-fec2-48db-a4c2-b5bb36e78ef7');
INSERT INTO Apoiador_Campanha
VALUES ('c255b224-b7c1-488a-bd3b-bf64ab564ba0', '31951113061', 'd6dae31b-c186-452c-9b17-0431f2189124');
INSERT INTO Apoiador_Campanha
VALUES ('5ff62aa0-5ba3-4209-88b5-ee5158920330', '62047257632', 'b0350cf5-b002-4d30-a6f0-a9c7f704af51');
INSERT INTO Apoiador_Campanha
VALUES ('e4804907-e499-4ef3-b776-c4ddcccd14b8', '24966657152', 'ac46448c-6473-44ea-b7ef-6d223320e7cb');
INSERT INTO Apoiador_Campanha
VALUES ('25f47f1e-19e8-4a2b-be05-6a0bbfa097de', '26367881237', '640f433b-d510-4411-b3b5-57a06940939d');
INSERT INTO Apoiador_Campanha
VALUES ('fd687264-54e1-4c02-aefa-7be8d4fbcde0', '82502861178', '59f90db8-4b94-4a88-9454-811831b54965');
INSERT INTO Apoiador_Campanha
VALUES ('7f69102e-aed1-4082-bd70-d20e5bb8bf0b', '44242360976', 'ac46448c-6473-44ea-b7ef-6d223320e7cb');
INSERT INTO Apoiador_Campanha
VALUES ('6f46983a-98ab-4d4e-b6db-1808eb081bec', '77360690359', 'df252e18-daaf-4885-bb57-764baa56043e');
INSERT INTO Apoiador_Campanha
VALUES ('e79861d6-1da6-478b-8fc5-6029f3df5895', '93245290170', '3a799fea-11ae-466c-9022-f9c6be416a8a');
INSERT INTO Apoiador_Campanha
VALUES ('43202e6f-63e5-419d-8805-5372b979551b', '43031963950', 'ffb278af-8af8-47eb-8f95-2cf921d947b7');
INSERT INTO Apoiador_Campanha
VALUES ('309f7259-8987-4295-92e2-fc80966438b8', '86912200003', '77a18b1b-6c6c-46bb-96bf-cffa788ed30b');
INSERT INTO Apoiador_Campanha
VALUES ('8df25899-f660-4805-840d-acd3136d8fc9', '48624392356', 'a9340c32-57cd-4b51-a695-5dd90c08e191');
INSERT INTO Apoiador_Campanha
VALUES ('d15bb041-28c3-40d2-a3d1-f59bc4842ef8', '84247250689', '190edd00-228b-4894-9b3a-8019ddd95295');
INSERT INTO Apoiador_Campanha
VALUES ('641dd373-04ce-4db1-9537-d498568af853', '43031963950', 'ef24ffa7-755d-40b5-9909-3fbdfde0e1b6');
INSERT INTO Apoiador_Campanha
VALUES ('43202e6f-63e5-419d-8805-5372b979551b', '83335207737', '8d1ed05b-a004-4bf1-af63-f96b52e0baca');
INSERT INTO Apoiador_Campanha
VALUES ('1d8c13a2-cc8c-45b8-b253-c283ad9727a5', '84247250689', '771af538-92a3-41e6-bc5c-f015e2f418e6');
INSERT INTO Apoiador_Campanha
VALUES ('3260e081-80e6-4d78-9265-162183ac92de', '82961410374', '6253459f-d87d-4c13-addd-2dd5b2f4dac8');
INSERT INTO Apoiador_Campanha
VALUES ('bb10d35a-1942-4cc2-90a1-d691f2f0c5b1', '42855953916', '48b5e119-d9e6-4cd7-a22f-b1dbe455dbe4');
INSERT INTO Apoiador_Campanha
VALUES ('7f015f17-3990-4247-b520-a7b5407e8ba1', '32050464514', '8d1ed05b-a004-4bf1-af63-f96b52e0baca');
INSERT INTO Apoiador_Campanha
VALUES ('25f47f1e-19e8-4a2b-be05-6a0bbfa097de', '92353644056', '0c3e0e9e-f5d0-433b-ba13-9a275a7398c7');
INSERT INTO Apoiador_Campanha
VALUES ('b717772d-39c3-448b-85c4-1cd401bd1489', '89211657708', 'c93a41cf-0a2f-442e-bc7a-7a7b4d17217e');
INSERT INTO Apoiador_Campanha
VALUES ('c67d1de2-ab8f-4d9a-bb02-66a5b48427e8', '40396111428', 'ab11040b-d0ec-4f4d-abdc-7e38a0c5fe27');
INSERT INTO Apoiador_Campanha
VALUES ('66c8ad39-3b9b-4286-9775-67f4d4005dab', '36970834878', 'c415b9f0-dfef-4259-8330-6b5330ab8b4d');
INSERT INTO Apoiador_Campanha
VALUES ('f82b5022-30ea-435e-ab4f-faf67060e06d', '21959062153', '8f50fbe3-520f-491d-95ae-4c1e5861410b');
INSERT INTO Apoiador_Campanha
VALUES ('66c8ad39-3b9b-4286-9775-67f4d4005dab', '67696900554', '73d1d28c-128a-47c1-a5a9-442d3b531a87');
INSERT INTO Apoiador_Campanha
VALUES ('b681896d-315e-49ac-ad3e-79b44ba98ebc', '82742590734', 'ee717286-8f2d-4f33-b191-fe78358f32b5');
INSERT INTO Apoiador_Campanha
VALUES ('3d44897e-3818-4bc3-9611-7b722aebc1c1', '42354971754', '1f087b92-f408-4e38-a5d5-9a2fdbdfad97');
INSERT INTO Apoiador_Campanha
VALUES ('34902105-4b19-4c5e-9625-decc41d7f888', '79990477925', '089992fb-3f5a-4d4b-a0da-bebaa255f5bb');
INSERT INTO Apoiador_Campanha
VALUES ('c1ed2445-7ee6-408c-b7cb-5fb711af6ed6', '69911227060', 'fd095140-410d-43a2-a4a8-146a04bffcb1');
INSERT INTO Apoiador_Campanha
VALUES ('2c331bbb-e115-4227-96f0-21904f17b37e', '10297100099', '59f90db8-4b94-4a88-9454-811831b54965');
INSERT INTO Apoiador_Campanha
VALUES ('bb10d35a-1942-4cc2-90a1-d691f2f0c5b1', '83634928187', '9d0a033b-e590-4dc6-a3ca-dc3006b0c77d');
INSERT INTO Apoiador_Campanha
VALUES ('5ff62aa0-5ba3-4209-88b5-ee5158920330', '20462237349', 'd6132a5c-2d98-4219-a9e2-770383420edb');
INSERT INTO Apoiador_Campanha
VALUES ('7f015f17-3990-4247-b520-a7b5407e8ba1', '35594983946', 'e3e9536b-8e35-441f-8d47-d65b68501adb');
INSERT INTO Apoiador_Campanha
VALUES ('66098c88-f2c9-4e0a-b333-7064c3f59d75', '43850494597', '91a3a2dd-e286-4354-93a8-eba52c14a102');
INSERT INTO Apoiador_Campanha
VALUES ('7f015f17-3990-4247-b520-a7b5407e8ba1', '54582723022', '3f5a2894-b511-4a4e-885b-0dc22b71903a');
INSERT INTO Apoiador_Campanha
VALUES ('66098c88-f2c9-4e0a-b333-7064c3f59d75', '32882520346', '8624d26b-7e14-4170-b192-9655bdbc3beb');
INSERT INTO Apoiador_Campanha
VALUES ('db46858a-2b0b-4680-9f7d-b49998199618', '85096177156', 'e3f6c11d-127e-4d33-96d4-ae47df6765d9');
INSERT INTO Apoiador_Campanha
VALUES ('f7ae535d-b0d7-4147-963a-60a6921d46f7', '62763315637', '84592088-be07-4a06-8da4-c9e1a062950d');
INSERT INTO Apoiador_Campanha
VALUES ('db46858a-2b0b-4680-9f7d-b49998199618', '69290820988', 'd22f14ed-3c15-4d63-8187-4adfdb71f319');
INSERT INTO Apoiador_Campanha
VALUES ('e80bce56-1604-4fd2-9280-e2997e0db865', '48658048233', '69557033-c5dc-4baa-acf6-c94030ff6d15');
INSERT INTO Apoiador_Campanha
VALUES ('e07ab672-ae21-4a0c-b47f-beefd1254a35', '26316574874', '4dbc5c65-f436-44f7-8bbe-996b68c09ebe');
INSERT INTO Apoiador_Campanha
VALUES ('7f015f17-3990-4247-b520-a7b5407e8ba1', '91491590670', 'c073459a-ef72-484c-8c9e-35a6be317e10');
INSERT INTO Apoiador_Campanha
VALUES ('1d8c13a2-cc8c-45b8-b253-c283ad9727a5', '61250933664', 'fd095140-410d-43a2-a4a8-146a04bffcb1');
INSERT INTO Apoiador_Campanha
VALUES ('b681896d-315e-49ac-ad3e-79b44ba98ebc', '49035936468', 'a162ac72-4be3-44c6-9c4a-8018be6c84d0');
INSERT INTO Apoiador_Campanha
VALUES ('94a2c461-d1a0-48c4-b09c-f67ed0660e45', '34163422295', '5609512e-2359-49e5-ac67-2faeca1322bb');
INSERT INTO Apoiador_Campanha
VALUES ('fbbc4c3a-6e46-432d-8b78-8560d0e7ad2b', '20170554369', 'ccf50d24-5e18-4a35-a7c6-6df9ac8f08ef');
INSERT INTO Apoiador_Campanha
VALUES ('517707cd-392f-4357-91d0-32f93e5c317e', '94656017050', '15aa38cd-857c-4915-ba41-b7437f4a528f');
INSERT INTO Apoiador_Campanha
VALUES ('f82b5022-30ea-435e-ab4f-faf67060e06d', '43381068897', '91a3a2dd-e286-4354-93a8-eba52c14a102');
INSERT INTO Apoiador_Campanha
VALUES ('cd3ee000-035b-4e94-b7fb-84889c33d0a0', '34952035478', 'b79c361d-bc3a-43fc-bfff-8563e7f7aeb2');
INSERT INTO Apoiador_Campanha
VALUES ('d1229e26-2128-44d4-8263-624f2ce3a5f6', '88159796837', 'ce3e0d4a-abde-410a-94d7-45be576a6f39');
INSERT INTO Apoiador_Campanha
VALUES ('8f090ff5-ab45-41d9-bd3d-a04f55149033', '26564529193', 'a5b9c626-dc41-4989-bcf1-303d3e9a4c12');
INSERT INTO Apoiador_Campanha
VALUES ('8df25899-f660-4805-840d-acd3136d8fc9', '57761234645', 'a69d95ce-fec2-48db-a4c2-b5bb36e78ef7');


-- Insere Doadores de Campanha
INSERT INTO Doador_Campanha
VALUES ('50acc5e6-0d4e-4c24-8a38-7f21c49d4eb0', NULL,
        '30652132227551');
INSERT INTO Doador_Campanha
VALUES ('dd35c959-3b44-46ba-b811-bcc8c2bf8061', '83225498516',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('836dd269-e858-42da-afe5-d8a18566fbec', NULL,
        '53428680486977');
INSERT INTO Doador_Campanha
VALUES ('b1f3d41c-6e98-448e-a422-7ea718be8006', NULL,
        '37966980966739');
INSERT INTO Doador_Campanha
VALUES ('775583e9-bd76-4308-b6da-e04c4a2aa3b1', '88774482219',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('fba27c16-e023-4847-a6f9-a43a63731951', '79990477925',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('4d334df8-cc30-451d-821f-2e68eb99862d', NULL,
        '65980468315538');
INSERT INTO Doador_Campanha
VALUES ('5209cb61-015a-4124-9804-a89a87cb8fc9', NULL,
        '89492720942944');
INSERT INTO Doador_Campanha
VALUES ('c59e875e-fb5f-4b65-8174-ac7a64fd7d99', '71410878263',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('70620fd7-e06d-4e6c-a0b8-251d937f5ef9', NULL,
        '13995017244014');
INSERT INTO Doador_Campanha
VALUES ('58f5ba47-93df-4178-bfeb-67d9723ea051', NULL,
        '84881790494546');
INSERT INTO Doador_Campanha
VALUES ('049a6af4-3373-42c0-bcbe-c7a06ffe79a1', '49878119379',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('600bf400-6d2c-4492-bd13-85bdc9c761a0', NULL,
        '40565070081502');
INSERT INTO Doador_Campanha
VALUES ('e89a98fb-b50f-4894-b137-94672b4e7789', NULL,
        '16309791598469');
INSERT INTO Doador_Campanha
VALUES ('45a52d91-be2d-400a-b747-044c5a40e2ab', NULL,
        '37907308794092');
INSERT INTO Doador_Campanha
VALUES ('3ac13bdf-7b8b-4912-add3-907611839a39', NULL,
        '33311130264773');
INSERT INTO Doador_Campanha
VALUES ('364b3ee6-a76b-4155-846c-5eefa249a630', '70247840185',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('efc86741-8a29-4feb-8dea-f49246c490af', '76328378601',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('f9577f50-d91a-4b1c-abe4-570f90cb536e', '34952035478',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('4f0cb2f1-49e2-41d9-95d9-995f7786dc5c', '57362485802',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('832b7500-9cfe-499d-aad0-11ce9d9fb96b', NULL,
        '86919991171453');
INSERT INTO Doador_Campanha
VALUES ('2b8953ae-385f-4aa8-a01d-c49b09ec21f7', '76349967408',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('c8ce6cdc-b04e-44fb-9793-bebce4f7f703', '11940935752',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('6f3ce681-d64b-45c1-9d4e-069bf0ddb664', '85294869835',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('0e873585-b9f4-480d-9835-e1744f04a8f8', NULL,
        '93460058229975');
INSERT INTO Doador_Campanha
VALUES ('92163a89-a6c1-4754-8088-8b133a51aeda', '15692404331',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('f6e4447f-ecb3-47ed-8f35-1ecf6cb4c4be', '24302018939',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('c05a1092-6ddc-4da9-9817-9f22d7c9d2a5', NULL,
        '45365551884751');
INSERT INTO Doador_Campanha
VALUES ('5bd87996-5c8f-4d04-8c78-a56db0df3f32', NULL,
        '23417064768727');
INSERT INTO Doador_Campanha
VALUES ('7c667f6a-d35f-40ab-95f7-8ac455c398c5', '86186453672',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('3d499f92-47c2-401f-948f-a1e471c8808e', NULL,
        '47325077084824');
INSERT INTO Doador_Campanha
VALUES ('88c87da7-5eb0-4af8-b07a-1a5130644839', NULL,
        '71065604118630');
INSERT INTO Doador_Campanha
VALUES ('b8798522-f97f-47e9-900d-059a3e803018', '26254597574',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('3ee23a21-cb0d-43e0-86f1-89072857e341', NULL,
        '89420990773942');
INSERT INTO Doador_Campanha
VALUES ('b326c244-ce80-439b-bcea-57c5754f09d9', NULL,
        '27938486088532');
INSERT INTO Doador_Campanha
VALUES ('56114595-460c-4090-aebb-fdf531d4b0ed', '30055465318',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('44892b4c-0068-413b-9d44-4ae26f6ce7e9', NULL,
        '66019863386172');
INSERT INTO Doador_Campanha
VALUES ('a76df43a-5b6d-4b29-a2c0-2c5ca72212c7', '62330017092',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('5a2ec311-8162-4bde-9866-aa8d0fcd0e02', NULL,
        '40267863553017');
INSERT INTO Doador_Campanha
VALUES ('5c2f7fcc-7bc4-4528-a471-16f368a2f537', '65311654887',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('d245eadd-2426-4862-bc68-1d1029b2a4e0', NULL,
        '75608401051722');
INSERT INTO Doador_Campanha
VALUES ('16cf5c41-c773-4526-ad69-40dbf0569974', '34798725692',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('3ddb2fb4-a49a-4cf6-aaa8-95a1786d9f3a', NULL,
        '64124079856555');
INSERT INTO Doador_Campanha
VALUES ('9671f54f-f1bc-49d5-9b9f-6b752b0d7f2d', NULL,
        '50479142384137');
INSERT INTO Doador_Campanha
VALUES ('22403b01-9b64-48fd-a94b-cd3177d0761e', NULL,
        '31945467786863');
INSERT INTO Doador_Campanha
VALUES ('22e762e6-fc31-4eca-9bd9-b08c139cd819', '46974461216',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('cc5a9a2f-d872-48fb-84f9-114e7bcdfabe', '70054730942',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('78fc5946-776f-4958-b0cf-38571e14beef', NULL,
        '78098274536896');
INSERT INTO Doador_Campanha
VALUES ('d505f23f-1fdf-4204-a725-51345dd83770', '19629932825',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('5555f359-6ac1-4cf9-8cbb-2f5e9297cc1c', NULL,
        '36606559064239');
INSERT INTO Doador_Campanha
VALUES ('a69f07f6-5bda-449d-a8de-dec82f20a1b5', '76437914024',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('fe7b6ea6-52ee-41eb-9828-51f8460aa8f0', NULL,
        '63744421279989');
INSERT INTO Doador_Campanha
VALUES ('0851b645-1622-4648-84f7-6f0dc4d56d12', NULL,
        '44663320123218');
INSERT INTO Doador_Campanha
VALUES ('baf66e24-77ae-459d-b838-d17769d287ac', '21995127492',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('9b45a9f1-c654-4f0a-8b36-80378fcad1a9', '24517586107',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('0d23b4b3-a4e9-4c9b-a81b-0709a5d22c13', NULL,
        '75423667530994');
INSERT INTO Doador_Campanha
VALUES ('c9cc8b52-217f-41a1-acaf-7d5b89d57f4b', '11737644865',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('bd6743c8-11e3-42cd-ac54-abde3327a690', NULL,
        '95086650694720');
INSERT INTO Doador_Campanha
VALUES ('ef5d90ac-8a2d-469e-8947-338097aecd37', '90046827753',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('4b34e288-4e85-4d22-ad99-ac9d3519d100', NULL,
        '34683104630094');
INSERT INTO Doador_Campanha
VALUES ('19e5339d-9458-4125-ad2f-c28b6252b157', NULL,
        '29301971953827');
INSERT INTO Doador_Campanha
VALUES ('2065f8df-b2d9-4361-94de-0e31c492d35f', NULL,
        '44790152483619');
INSERT INTO Doador_Campanha
VALUES ('232403da-9cc1-48f4-a44f-085c2b5706a2', '74158802132',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('d17b8999-91cc-409b-bbb8-18b0b472339a', '42488055673',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('e458bd6e-7958-4220-a74f-6742bf2344f6', '63614471920',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('afa4e8ea-488a-4241-ae4b-912d420a3d09', NULL,
        '80611675709951');
INSERT INTO Doador_Campanha
VALUES ('e4f809c8-f868-4c4e-9d6d-cb12cc3ea684', '52857200317',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('e126b328-d49f-4e94-a807-d6e9e7d37722', '26153816252',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('f88ddf93-7041-4def-82b0-44a0c82a5436', '94493685548',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('735f99cb-ee8c-4cc6-b3e4-726bb734f2a5', NULL,
        '27768687526695');
INSERT INTO Doador_Campanha
VALUES ('3cc63e69-2a44-4e20-a8db-38e5e45df4bd', NULL,
        '66423207460902');
INSERT INTO Doador_Campanha
VALUES ('4d6f867b-f287-49fd-b0fe-93613921ce71', '40021847444',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('c98f740a-5a49-4fff-89f1-eb59d87e0317', '15007094920',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('68a76f8b-70be-4b1b-97f7-382b63785d21', NULL,
        '65459109558723');
INSERT INTO Doador_Campanha
VALUES ('f76b0769-928d-4b66-b86a-b4e9276d154d', '33251189284',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('e377a7e1-67d5-427e-a1d6-e30086a624df', NULL,
        '12367838402278');
INSERT INTO Doador_Campanha
VALUES ('8436e44a-76b4-4a63-89d5-1b1eff8dd317', NULL,
        '97800285685807');
INSERT INTO Doador_Campanha
VALUES ('c84130ee-c05a-4bcf-a568-c32f949ede70', NULL,
        '40480916465166');
INSERT INTO Doador_Campanha
VALUES ('4426245e-991a-4010-bf32-045adb9e6be8', NULL,
        '63459408786147');
INSERT INTO Doador_Campanha
VALUES ('11652e0a-907d-4afa-b6f4-49bcc3245490', NULL,
        '86903622697573');
INSERT INTO Doador_Campanha
VALUES ('cb4dc066-e694-450d-9dea-abb9ce1e665b', NULL,
        '84772430777084');
INSERT INTO Doador_Campanha
VALUES ('9c44e6d0-3535-40f1-9fab-b307af079834', NULL,
        '87865552348084');
INSERT INTO Doador_Campanha
VALUES ('b8452add-955f-42ba-8e50-af4d83757eda', NULL,
        '22443356784060');
INSERT INTO Doador_Campanha
VALUES ('c406f93b-4288-47fd-aad0-541877b8ec91', NULL,
        '82430346023757');
INSERT INTO Doador_Campanha
VALUES ('7b3c8e98-0e67-49c4-9ed6-a571a2d79935', NULL,
        '92254483208525');
INSERT INTO Doador_Campanha
VALUES ('6ee199d7-007d-492f-8a2a-9c035698bbda', '14742387901',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('7dba358b-1cde-4c88-aed8-f28668329e23', '93053958227',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('63557c04-a4a5-4e40-821b-6eac6fa22ee4', '64118797685',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('e811e5f2-2e04-494c-8122-7920d98371b2', NULL,
        '46897029487881');
INSERT INTO Doador_Campanha
VALUES ('a95cdb9b-7e32-4de3-8b97-b756229e421a', '11737644865',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('717211c3-4e03-446f-8e83-f5fbb8420d8f', NULL,
        '73644494400359');
INSERT INTO Doador_Campanha
VALUES ('a694143e-e7e9-46d7-a002-d16c0252fe02', NULL,
        '41904415939934');
INSERT INTO Doador_Campanha
VALUES ('5d84c067-54b6-40fb-8e81-ad2748ec9cc7', '64878309026',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('e49e6378-c55a-4f5e-a6ba-5425a78653e0', NULL,
        '18173039220273');
INSERT INTO Doador_Campanha
VALUES ('95b85a71-1ff0-41c4-9a12-e6bd0c1a39af', '57755531829',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('e110c8a1-5bb1-4e18-99ac-4f1a111306d1', NULL,
        '13939491745550');
INSERT INTO Doador_Campanha
VALUES ('0531fe4f-da16-4bfa-9a29-3fb4d79d793a', NULL,
        '70225851708091');
INSERT INTO Doador_Campanha
VALUES ('db2039dc-c368-4510-9edb-f945dc59c969', '81749686598',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('6a323535-3436-4bfb-940c-e1f3e0c3766a', NULL,
        '35934014641679');
INSERT INTO Doador_Campanha
VALUES ('8e5891b5-48c1-4fcb-9bf6-8cc0d1b12c05', '41570859046',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('f8edc021-cbc4-402a-968d-a9f7a672cf3f', '67193564104',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('55b49a61-c3c0-4e9e-9e27-2dca2a5c3f06', NULL,
        '71557433577254');
INSERT INTO Doador_Campanha
VALUES ('572b8f36-c028-4b3e-b7b9-9c23c99ad3a8', NULL,
        '55913460017181');
INSERT INTO Doador_Campanha
VALUES ('9c8906ea-679d-4e45-9001-11af8bb2bb8e', '34774391916',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('01ff9741-0f56-448f-a312-2c11f77fc8e6', '71934199538',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('2d353b3c-31f9-468d-9a00-83c800c5bdda', '74298426869',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('0e7322e3-ffb7-40b5-9cc2-a49a445b18d9', '96818589621',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('e1e35f7a-14ca-4db0-b28c-abaa4227ab0f', NULL,
        '12678060936741');
INSERT INTO Doador_Campanha
VALUES ('8b82731a-6728-46f7-9515-94d8019bd4da', NULL,
        '40049744388088');
INSERT INTO Doador_Campanha
VALUES ('59cfdb91-d196-4949-97b3-c3df18e178b1', '66001942080',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('0275a66a-7331-42a0-b773-7e4d1926305f', NULL,
        '11227769253309');
INSERT INTO Doador_Campanha
VALUES ('5e8027ad-3939-4950-83fa-81d296332ea2', '14901188861',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('66d7bb0b-4a0e-418b-9504-3681f6a80fa1', NULL,
        '45192478094249');
INSERT INTO Doador_Campanha
VALUES ('b7f32e7e-62aa-4cc8-88cf-9e3828cd8eec', '94223495926',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('22e7cd14-3022-49bd-9712-354576bc34b8', NULL,
        '31760507221333');
INSERT INTO Doador_Campanha
VALUES ('f2c5a08f-28b0-4ffd-9d45-f83a3e13e78e', NULL,
        '25813917191699');
INSERT INTO Doador_Campanha
VALUES ('a11fec21-a19b-4661-ad25-f8c025ee9929', '86249082582',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('b7c48b41-7e79-4672-bfc0-d124ac03cd1a', NULL,
        '90572488354519');
INSERT INTO Doador_Campanha
VALUES ('e71a8899-a249-4901-925b-85000c2e37b4', NULL,
        '76722722460981');
INSERT INTO Doador_Campanha
VALUES ('3dd7dee9-4da0-4b3a-b947-c2da933e7936', '29479615306',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('e070022e-3fee-4d18-be82-36159e7470db', NULL,
        '16601926153525');
INSERT INTO Doador_Campanha
VALUES ('1fc8f428-7253-454b-95fc-1ed295a40b80', '49372404732',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('a941e6de-1187-43b9-ab04-2edbec1fb748', NULL,
        '75194574883207');
INSERT INTO Doador_Campanha
VALUES ('cab1b389-3376-4307-9a25-8d1d3b82afb5', '14247396097',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('490c230f-f9ce-41d8-82f2-71a866dae764', NULL,
        '99704612533096');
INSERT INTO Doador_Campanha
VALUES ('4d698144-9f26-4adb-8c8b-a85bc68a4b6f', NULL,
        '98270009446423');
INSERT INTO Doador_Campanha
VALUES ('10890d85-400f-4b92-8011-1dabedaf706f', NULL,
        '80599393099546');
INSERT INTO Doador_Campanha
VALUES ('913c110a-8540-47a9-81ac-429b5b76b39e', NULL,
        '15652554710395');
INSERT INTO Doador_Campanha
VALUES ('99b4379b-19aa-4e09-b8b2-b278f22a0a96', '29731390641',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('47d6e465-aa53-440c-a8bb-caea10433920', NULL,
        '16006777416914');
INSERT INTO Doador_Campanha
VALUES ('41d32e59-3e42-428e-b8f4-8004e839d26b', '21158760678',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('977f5dec-1375-4312-b00a-5bac653b98dc', '44770700223',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('e597267b-5dd8-455f-a0be-6cad40bc13ab', '87386788851',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('ffffcd8d-8163-48be-8b9c-45d62c6c5ec8', NULL,
        '78729242666158');
INSERT INTO Doador_Campanha
VALUES ('d4479cc4-3318-48b4-b290-821cb1721270', '70177465768',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('cb484f98-e1b5-4742-9632-435a6bb1af65', NULL,
        '87830425887368');
INSERT INTO Doador_Campanha
VALUES ('04c4546e-d4c0-4a7d-adb3-67b67b523c12', NULL,
        '41458196125458');
INSERT INTO Doador_Campanha
VALUES ('10078f2b-1d50-4e0a-8462-2b94d6f86576', NULL,
        '19956263136118');
INSERT INTO Doador_Campanha
VALUES ('b26b2af4-cdef-4d4e-a048-7b05c3e140bf', '69146417120',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('c1121294-0ac8-4350-a07e-5516ad908d0e', NULL,
        '97812169925309');
INSERT INTO Doador_Campanha
VALUES ('ce71384c-c098-426d-aa8d-f2a3a5bb297a', NULL,
        '69983898329082');
INSERT INTO Doador_Campanha
VALUES ('dc7481d8-4561-4e74-9e6a-307d0dcef706', NULL,
        '46072631089482');
INSERT INTO Doador_Campanha
VALUES ('d08fbba2-2c87-49d4-9471-7856fdca6bbd', '41238485593',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('7d34cdc5-097d-43c2-8211-f739e22cdada', NULL,
        '15481387781910');
INSERT INTO Doador_Campanha
VALUES ('d7f6fc25-ed06-4ef8-867e-9a466fad0172', '24653057004',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('341f49d7-e232-4d12-b6da-62d99a2ecedb', '23579627191',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('8ab46c9c-384a-4a37-9b29-17f42e215789', '57456171549',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('df751b3a-1775-4d44-8d35-02b9b6448500', '58712847996',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('78ef4969-bd9f-4e18-91c9-161bb9fa7f9f', '96970153856',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('009fe70b-8546-43bc-9b3a-146b06d56b12', NULL,
        '10100444327108');
INSERT INTO Doador_Campanha
VALUES ('379c2f45-e578-485b-bae7-8f30b0f4db4d', NULL,
        '25825680103152');
INSERT INTO Doador_Campanha
VALUES ('26a372d4-96c4-4306-90ab-a0725acd1fb1', '97409812505',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('7862bf4d-3552-4614-bdea-32e495b6cdc6', NULL,
        '61576899446081');
INSERT INTO Doador_Campanha
VALUES ('ba2a4f1e-d68b-48be-8a57-249551696055', NULL,
        '38194981431588');
INSERT INTO Doador_Campanha
VALUES ('d7cae7ba-6b1c-4626-b206-ee4844121d3b', NULL,
        '82120376266539');
INSERT INTO Doador_Campanha
VALUES ('49f45d09-6096-4402-9dc1-c41a7afd565a', NULL,
        '24608542518690');
INSERT INTO Doador_Campanha
VALUES ('dc437c62-e1e6-491c-b595-f8a54205eba0', NULL,
        '63978737383149');
INSERT INTO Doador_Campanha
VALUES ('2e108ec0-8e68-410e-bb91-dfeba29b1799', '85103842427',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('57119800-75ec-41e4-9392-75506b21d2b7', '31817754048',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('dd6a6c0e-a7d6-4163-afe9-f4ebf13a5038', NULL,
        '62447378195356');
INSERT INTO Doador_Campanha
VALUES ('1ece8537-c872-4d75-b275-14ef2ea8e12a', NULL,
        '27978053868282');
INSERT INTO Doador_Campanha
VALUES ('8a921659-8187-4715-a058-c0bafd7f9d7f', NULL,
        '69705006678123');
INSERT INTO Doador_Campanha
VALUES ('455dd177-67b3-4921-a998-cf26543797c0', '13070944417',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('ce071a5d-0e6e-4d91-af5a-152229b1187a', NULL,
        '99644149255473');
INSERT INTO Doador_Campanha
VALUES ('16112d12-74d6-4c8d-8db6-76c85468a037', NULL,
        '44100885472726');
INSERT INTO Doador_Campanha
VALUES ('f349808e-3d3c-4aec-ac5f-485a65177cd5', NULL,
        '45088688591495');
INSERT INTO Doador_Campanha
VALUES ('17498d97-1395-49bd-be1d-3637b1f020ec', NULL,
        '56587563473731');
INSERT INTO Doador_Campanha
VALUES ('51fa2b48-e304-466c-b2d5-db8577b7602b', NULL,
        '65739238399546');
INSERT INTO Doador_Campanha
VALUES ('f0ba6654-c012-4df7-b019-d6c1582ca9f6', '80311061413',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('d8f56871-6bf2-4f48-93d8-1b6e8dd642c9', NULL,
        '93466366953216');
INSERT INTO Doador_Campanha
VALUES ('f47c97f3-82e5-427c-8684-417638459697', '97341636095',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('e260fd25-adb6-47be-9208-34570a29dfb4', NULL,
        '56821501678787');
INSERT INTO Doador_Campanha
VALUES ('1723a6a8-b012-4cb3-bd7f-9a797d318489', NULL,
        '48644159461837');
INSERT INTO Doador_Campanha
VALUES ('3f554f9b-b1f3-49ae-b1e4-76fdcf2d7f2e', NULL,
        '75961013950873');
INSERT INTO Doador_Campanha
VALUES ('8c7422f2-2ba7-491a-b2df-3c9e6b9ce4e0', NULL,
        '55179805695079');
INSERT INTO Doador_Campanha
VALUES ('999c282f-ad83-49ba-b5ed-8e796e2db869', '30865337816',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('cf6ca021-ff6f-47fb-a192-9ab53bd6888e', '57006225958',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('8bdd644a-467e-4e94-a655-8cd9541446d1', NULL,
        '88495867652818');
INSERT INTO Doador_Campanha
VALUES ('c1aa2ccb-6554-46cc-bcf9-456a573d5274', NULL,
        '25113895381800');
INSERT INTO Doador_Campanha
VALUES ('fea222b7-ef39-4ae9-8f30-dceda72dda69', NULL,
        '43102762261405');
INSERT INTO Doador_Campanha
VALUES ('404fe384-5059-461f-945d-65546af1ba5e', '74298426869',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('3f8dc7b2-e047-499e-b77c-4cb6f29fb4a4', '46631380887',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('ad19126a-fe59-4194-a7b2-77444c21b1a3', '38336047478',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('1dfbe08a-f872-424b-88de-dd916c8d8812', '68939089383',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('e6b44fc6-57f4-49cf-8cd3-166b50dec1ab', '49035936468',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('a4378666-9861-41d6-a91c-c749151dff5a', '56577562082',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('be69efcf-21b2-40cc-88e3-2b699fcb52c4', '48624392356',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('912f1b98-5c92-40db-898e-ac54905a7054', NULL,
        '70696997584309');
INSERT INTO Doador_Campanha
VALUES ('bb539e53-9bc6-4035-96bd-6cd824aa2583', '23965377714',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('14f0b729-bc96-4bbd-8e0a-3d506631232a', NULL,
        '96587012682575');
INSERT INTO Doador_Campanha
VALUES ('14949811-86d2-4306-81b4-ef8444401374', NULL,
        '49449213014449');
INSERT INTO Doador_Campanha
VALUES ('29b4a20d-b9aa-4607-a016-38bd6544301f', NULL,
        '55621471370104');
INSERT INTO Doador_Campanha
VALUES ('654e5406-edce-4f80-bd58-e8127e3170d7', '21959062153',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('09762316-0dac-4cb4-96aa-9a14284435e8', '78064916469',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('4be084a2-0472-4d93-9abc-df35bd4b848e', '67729153551',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('b64eb4f7-04d6-4d43-84cf-8df8b0dde18c', '46791838572',
        NULL);
INSERT INTO Doador_Campanha
VALUES ('a3f79f1f-a6cb-4979-a16d-ced3df95e1cc', NULL,
        '61664700636174');
INSERT INTO Doador_Campanha
VALUES ('961714fa-a037-4e50-8706-bd295b3e5ed2', NULL,
        '29394708890467');
INSERT INTO Doador_Campanha
VALUES ('70f554f6-ad0e-43b9-ac7c-463c794adf29', NULL,
        '25824944779742');
INSERT INTO Doador_Campanha
VALUES ('2bc03b58-198c-4745-a6ae-e4a9f48e65fb', '27393568651',
        NULL);


-- Insere Doacao Candidatura
INSERT INTO Doacao_Candidatura
VALUES ('50acc5e6-0d4e-4c24-8a38-7f21c49d4eb0', 'eeec1312-892d-453b-89cb-76947e59df09', 35825);
INSERT INTO Doacao_Candidatura
VALUES ('dd35c959-3b44-46ba-b811-bcc8c2bf8061', 'a68c5eb7-a872-478c-b134-1f456cd762cc', 38241);
INSERT INTO Doacao_Candidatura
VALUES ('836dd269-e858-42da-afe5-d8a18566fbec', '1f087b92-f408-4e38-a5d5-9a2fdbdfad97', 72613);
INSERT INTO Doacao_Candidatura
VALUES ('b1f3d41c-6e98-448e-a422-7ea718be8006', 'ba1fbadd-5d97-432d-b83d-0387648332ca', 42246);
INSERT INTO Doacao_Candidatura
VALUES ('775583e9-bd76-4308-b6da-e04c4a2aa3b1', 'fcd0c2f4-f34c-43b1-81e8-3b337b237473', 16790);
INSERT INTO Doacao_Candidatura
VALUES ('fba27c16-e023-4847-a6f9-a43a63731951', '1604709a-2969-40a2-883d-b6881ac7733c', 91854);
INSERT INTO Doacao_Candidatura
VALUES ('4d334df8-cc30-451d-821f-2e68eb99862d', 'a68c5eb7-a872-478c-b134-1f456cd762cc', 72612);
INSERT INTO Doacao_Candidatura
VALUES ('5209cb61-015a-4124-9804-a89a87cb8fc9', 'c4c07825-f2ad-411d-90dc-d94a59f2b127', 13298);
INSERT INTO Doacao_Candidatura
VALUES ('c59e875e-fb5f-4b65-8174-ac7a64fd7d99', 'dbca96cb-8b7a-4068-b5e0-40b972174455', 26447);
INSERT INTO Doacao_Candidatura
VALUES ('70620fd7-e06d-4e6c-a0b8-251d937f5ef9', 'c5c7d952-98bf-4354-b22e-1cc01ec63178', 92333);
INSERT INTO Doacao_Candidatura
VALUES ('58f5ba47-93df-4178-bfeb-67d9723ea051', '4fb359f5-f149-441d-af8a-3274f9d63e1a', 70767);
INSERT INTO Doacao_Candidatura
VALUES ('049a6af4-3373-42c0-bcbe-c7a06ffe79a1', 'bd58d1f9-2ebb-4678-82dc-808391f2be40', 4045);
INSERT INTO Doacao_Candidatura
VALUES ('600bf400-6d2c-4492-bd13-85bdc9c761a0', 'bd306737-fc69-4061-8243-9be3242d6feb', 79372);
INSERT INTO Doacao_Candidatura
VALUES ('e89a98fb-b50f-4894-b137-94672b4e7789', '92a69a75-66c8-4286-88f4-f840b6b0149d', 31765);
INSERT INTO Doacao_Candidatura
VALUES ('45a52d91-be2d-400a-b747-044c5a40e2ab', '105ddfc8-ce13-43ab-bbbb-089c38b2a6a3', 46534);
INSERT INTO Doacao_Candidatura
VALUES ('3ac13bdf-7b8b-4912-add3-907611839a39', '7d48c51a-22be-4e56-bf7b-ce63f746abda', 75758);
INSERT INTO Doacao_Candidatura
VALUES ('364b3ee6-a76b-4155-846c-5eefa249a630', '4f49829d-e223-45c8-8d7c-40113f5e1ef8', 32377);
INSERT INTO Doacao_Candidatura
VALUES ('efc86741-8a29-4feb-8dea-f49246c490af', '5c81ab61-8823-4b74-80b3-1215be408397', 91205);
INSERT INTO Doacao_Candidatura
VALUES ('f9577f50-d91a-4b1c-abe4-570f90cb536e', '92a69a75-66c8-4286-88f4-f840b6b0149d', 3805);
INSERT INTO Doacao_Candidatura
VALUES ('4f0cb2f1-49e2-41d9-95d9-995f7786dc5c', 'fefd9228-cb63-4b98-84ae-7bc57c5d5e2c', 73360);
INSERT INTO Doacao_Candidatura
VALUES ('832b7500-9cfe-499d-aad0-11ce9d9fb96b', '2057c1a4-2055-4c9c-ac0d-b403a9493df7', 79998);
INSERT INTO Doacao_Candidatura
VALUES ('2b8953ae-385f-4aa8-a01d-c49b09ec21f7', 'b388b6ab-8d74-4843-9ed6-8de3e0fd490e', 55857);
INSERT INTO Doacao_Candidatura
VALUES ('c8ce6cdc-b04e-44fb-9793-bebce4f7f703', 'b57d2a05-efc8-4e52-abce-b27822c08c10', 34599);
INSERT INTO Doacao_Candidatura
VALUES ('6f3ce681-d64b-45c1-9d4e-069bf0ddb664', '416f2525-118f-40da-b855-e5135f9c66d1', 26153);
INSERT INTO Doacao_Candidatura
VALUES ('0e873585-b9f4-480d-9835-e1744f04a8f8', '9db5ce88-8b93-4160-b23b-3fae0f59c2f2', 68760);
INSERT INTO Doacao_Candidatura
VALUES ('92163a89-a6c1-4754-8088-8b133a51aeda', '1f087b92-f408-4e38-a5d5-9a2fdbdfad97', 51458);
INSERT INTO Doacao_Candidatura
VALUES ('f6e4447f-ecb3-47ed-8f35-1ecf6cb4c4be', 'caba4fc5-db56-4364-bed1-0693e7b40090', 50269);
INSERT INTO Doacao_Candidatura
VALUES ('c05a1092-6ddc-4da9-9817-9f22d7c9d2a5', '0ca9b602-ccca-485c-9390-dd30a1688d72', 5581);
INSERT INTO Doacao_Candidatura
VALUES ('5bd87996-5c8f-4d04-8c78-a56db0df3f32', '6ecf2052-603b-43fd-a735-89c321b21039', 99086);
INSERT INTO Doacao_Candidatura
VALUES ('7c667f6a-d35f-40ab-95f7-8ac455c398c5', 'ba3ba673-b8a3-497a-9cdc-6c3b25d7f94b', 28360);
INSERT INTO Doacao_Candidatura
VALUES ('3d499f92-47c2-401f-948f-a1e471c8808e', '890a4132-f791-463e-bf62-694771070844', 73169);
INSERT INTO Doacao_Candidatura
VALUES ('88c87da7-5eb0-4af8-b07a-1a5130644839', '41040666-f86d-4621-bf5c-c429a33bde6e', 76919);
INSERT INTO Doacao_Candidatura
VALUES ('b8798522-f97f-47e9-900d-059a3e803018', 'd6dae31b-c186-452c-9b17-0431f2189124', 1455);
INSERT INTO Doacao_Candidatura
VALUES ('3ee23a21-cb0d-43e0-86f1-89072857e341', '43f26faf-14b8-4779-9925-632f8e5b64cb', 11579);
INSERT INTO Doacao_Candidatura
VALUES ('b326c244-ce80-439b-bcea-57c5754f09d9', '016b6227-8628-42b2-a3fc-e0b17dd52ba7', 20868);
INSERT INTO Doacao_Candidatura
VALUES ('56114595-460c-4090-aebb-fdf531d4b0ed', '44e02ed5-4d8b-41e5-a287-8fc5ccc6a2c2', 71139);
INSERT INTO Doacao_Candidatura
VALUES ('44892b4c-0068-413b-9d44-4ae26f6ce7e9', '933c8e7d-e2e4-4c49-8ec1-17fa3823fed0', 39696);
INSERT INTO Doacao_Candidatura
VALUES ('a76df43a-5b6d-4b29-a2c0-2c5ca72212c7', 'bd58d1f9-2ebb-4678-82dc-808391f2be40', 55951);
INSERT INTO Doacao_Candidatura
VALUES ('5a2ec311-8162-4bde-9866-aa8d0fcd0e02', '54bbd357-a345-427e-a7a8-e497929dc9c9', 43641);
INSERT INTO Doacao_Candidatura
VALUES ('5c2f7fcc-7bc4-4528-a471-16f368a2f537', '59f90db8-4b94-4a88-9454-811831b54965', 97562);
INSERT INTO Doacao_Candidatura
VALUES ('d245eadd-2426-4862-bc68-1d1029b2a4e0', 'ccf50d24-5e18-4a35-a7c6-6df9ac8f08ef', 31054);
INSERT INTO Doacao_Candidatura
VALUES ('16cf5c41-c773-4526-ad69-40dbf0569974', '54bbd357-a345-427e-a7a8-e497929dc9c9', 51964);
INSERT INTO Doacao_Candidatura
VALUES ('3ddb2fb4-a49a-4cf6-aaa8-95a1786d9f3a', '0f80c0c0-419a-4a57-9e97-05c318b00790', 74834);
INSERT INTO Doacao_Candidatura
VALUES ('9671f54f-f1bc-49d5-9b9f-6b752b0d7f2d', 'ba3ba673-b8a3-497a-9cdc-6c3b25d7f94b', 17984);
INSERT INTO Doacao_Candidatura
VALUES ('22403b01-9b64-48fd-a94b-cd3177d0761e', 'c86a48c3-7ed8-46c3-879d-173172bcbbf6', 59552);
INSERT INTO Doacao_Candidatura
VALUES ('22e762e6-fc31-4eca-9bd9-b08c139cd819', 'e4682f84-f820-4b26-b14c-bb3104fed3d1', 78575);
INSERT INTO Doacao_Candidatura
VALUES ('cc5a9a2f-d872-48fb-84f9-114e7bcdfabe', '985de1ee-f070-47ce-a287-4194cc644432', 87480);
INSERT INTO Doacao_Candidatura
VALUES ('78fc5946-776f-4958-b0cf-38571e14beef', '851513fa-b276-4c1d-8be8-a0f452a62c12', 62802);
INSERT INTO Doacao_Candidatura
VALUES ('d505f23f-1fdf-4204-a725-51345dd83770', 'd659bb2a-fb45-48c8-a7b8-538e4fc6dce6', 121);
INSERT INTO Doacao_Candidatura
VALUES ('5555f359-6ac1-4cf9-8cbb-2f5e9297cc1c', 'bec1a6fa-44aa-43d4-92ca-278a959a8022', 42705);
INSERT INTO Doacao_Candidatura
VALUES ('a69f07f6-5bda-449d-a8de-dec82f20a1b5', '92a69a75-66c8-4286-88f4-f840b6b0149d', 13289);
INSERT INTO Doacao_Candidatura
VALUES ('fe7b6ea6-52ee-41eb-9828-51f8460aa8f0', '4104f9ce-2903-4ea9-bf68-b6db1d2f9b28', 91562);
INSERT INTO Doacao_Candidatura
VALUES ('0851b645-1622-4648-84f7-6f0dc4d56d12', 'ffb278af-8af8-47eb-8f95-2cf921d947b7', 18298);
INSERT INTO Doacao_Candidatura
VALUES ('baf66e24-77ae-459d-b838-d17769d287ac', '937954ac-2618-4fef-af38-33fae0400da6', 53777);
INSERT INTO Doacao_Candidatura
VALUES ('9b45a9f1-c654-4f0a-8b36-80378fcad1a9', '3f3ba0c5-c95d-4d78-ad2c-8181236e5f67', 54941);
INSERT INTO Doacao_Candidatura
VALUES ('0d23b4b3-a4e9-4c9b-a81b-0709a5d22c13', '62e87de6-318a-4b26-a85c-177a23a9b203', 89173);
INSERT INTO Doacao_Candidatura
VALUES ('c9cc8b52-217f-41a1-acaf-7d5b89d57f4b', '57d0d20f-a099-4bb9-9733-93c5e613880b', 99760);
INSERT INTO Doacao_Candidatura
VALUES ('bd6743c8-11e3-42cd-ac54-abde3327a690', 'ba1fbadd-5d97-432d-b83d-0387648332ca', 46549);
INSERT INTO Doacao_Candidatura
VALUES ('ef5d90ac-8a2d-469e-8947-338097aecd37', '2e68e679-c0e9-40d0-b3fd-3fcb43240e71', 36206);
INSERT INTO Doacao_Candidatura
VALUES ('4b34e288-4e85-4d22-ad99-ac9d3519d100', '2903e693-e909-49b9-be4b-3c1c06527e06', 39502);
INSERT INTO Doacao_Candidatura
VALUES ('19e5339d-9458-4125-ad2f-c28b6252b157', '12a8fba9-a47b-4096-a926-34085e6ffed4', 85816);
INSERT INTO Doacao_Candidatura
VALUES ('2065f8df-b2d9-4361-94de-0e31c492d35f', 'a68b4a1a-bf51-4905-908f-ed81997a5d4b', 17576);
INSERT INTO Doacao_Candidatura
VALUES ('232403da-9cc1-48f4-a44f-085c2b5706a2', 'ca885acd-0110-4a3f-9852-414bb2bf15c2', 12079);
INSERT INTO Doacao_Candidatura
VALUES ('d17b8999-91cc-409b-bbb8-18b0b472339a', 'a9414437-cd9d-4581-8203-35c8e3a32953', 46367);
INSERT INTO Doacao_Candidatura
VALUES ('e458bd6e-7958-4220-a74f-6742bf2344f6', '851513fa-b276-4c1d-8be8-a0f452a62c12', 26173);
INSERT INTO Doacao_Candidatura
VALUES ('afa4e8ea-488a-4241-ae4b-912d420a3d09', 'c073459a-ef72-484c-8c9e-35a6be317e10', 69664);
INSERT INTO Doacao_Candidatura
VALUES ('e4f809c8-f868-4c4e-9d6d-cb12cc3ea684', '6253459f-d87d-4c13-addd-2dd5b2f4dac8', 66466);
INSERT INTO Doacao_Candidatura
VALUES ('e126b328-d49f-4e94-a807-d6e9e7d37722', 'dee5de45-10ed-4393-b711-0e98e204a8e4', 88361);
INSERT INTO Doacao_Candidatura
VALUES ('f88ddf93-7041-4def-82b0-44a0c82a5436', '5609512e-2359-49e5-ac67-2faeca1322bb', 75624);
INSERT INTO Doacao_Candidatura
VALUES ('735f99cb-ee8c-4cc6-b3e4-726bb734f2a5', '5c81ab61-8823-4b74-80b3-1215be408397', 44181);
INSERT INTO Doacao_Candidatura
VALUES ('3cc63e69-2a44-4e20-a8db-38e5e45df4bd', '74d4bb98-f437-4b5d-9d30-750badbbd606', 30311);
INSERT INTO Doacao_Candidatura
VALUES ('4d6f867b-f287-49fd-b0fe-93613921ce71', '2c8928a3-3e19-4e28-a8c5-0d0d5548b780', 9848);
INSERT INTO Doacao_Candidatura
VALUES ('c98f740a-5a49-4fff-89f1-eb59d87e0317', '36e66fb3-2926-4f90-b1a6-9a203f1fda56', 59272);
INSERT INTO Doacao_Candidatura
VALUES ('68a76f8b-70be-4b1b-97f7-382b63785d21', '3c2e43d4-ca92-407a-a4ae-442825469da0', 9065);
INSERT INTO Doacao_Candidatura
VALUES ('f76b0769-928d-4b66-b86a-b4e9276d154d', 'd8c07196-ef29-485b-809d-6492dbcf2731', 99317);
INSERT INTO Doacao_Candidatura
VALUES ('e377a7e1-67d5-427e-a1d6-e30086a624df', '9373e77c-8364-4eff-92a4-1bf859f2bb96', 5966);
INSERT INTO Doacao_Candidatura
VALUES ('8436e44a-76b4-4a63-89d5-1b1eff8dd317', '8dc1cb84-50c9-4023-a07d-f14032294fd7', 5420);
INSERT INTO Doacao_Candidatura
VALUES ('c84130ee-c05a-4bcf-a568-c32f949ede70', 'e4682f84-f820-4b26-b14c-bb3104fed3d1', 53814);
INSERT INTO Doacao_Candidatura
VALUES ('4426245e-991a-4010-bf32-045adb9e6be8', '57d0ebbe-8f17-4178-abc6-504b5533e83e', 18947);
INSERT INTO Doacao_Candidatura
VALUES ('11652e0a-907d-4afa-b6f4-49bcc3245490', 'd57f5410-460b-49c9-82f9-8b754a4fafed', 66443);
INSERT INTO Doacao_Candidatura
VALUES ('cb4dc066-e694-450d-9dea-abb9ce1e665b', 'c6fcc4e3-9ec0-4f70-987d-aabd232e3bad', 97681);
INSERT INTO Doacao_Candidatura
VALUES ('9c44e6d0-3535-40f1-9fab-b307af079834', '4ba67991-f16b-42ad-9373-660e707c2cd0', 26635);
INSERT INTO Doacao_Candidatura
VALUES ('b8452add-955f-42ba-8e50-af4d83757eda', '5c81ab61-8823-4b74-80b3-1215be408397', 88122);
INSERT INTO Doacao_Candidatura
VALUES ('c406f93b-4288-47fd-aad0-541877b8ec91', '6cb79bb4-351a-46ef-b1ea-79f45f67f5c0', 34788);
INSERT INTO Doacao_Candidatura
VALUES ('7b3c8e98-0e67-49c4-9ed6-a571a2d79935', '8a9076ea-ceb0-4f0a-b8a8-330770dcbfe8', 81657);
INSERT INTO Doacao_Candidatura
VALUES ('6ee199d7-007d-492f-8a2a-9c035698bbda', '2726cdd1-05af-48fa-80ce-35a8e027a019', 30373);
INSERT INTO Doacao_Candidatura
VALUES ('7dba358b-1cde-4c88-aed8-f28668329e23', 'c2e5ed73-25e8-4519-a108-229d3cd7bd3c', 24320);
INSERT INTO Doacao_Candidatura
VALUES ('63557c04-a4a5-4e40-821b-6eac6fa22ee4', '6d689799-c3b8-47d6-9fa9-97297a5c3f57', 9446);
INSERT INTO Doacao_Candidatura
VALUES ('e811e5f2-2e04-494c-8122-7920d98371b2', '13a3590c-c471-4076-bc0c-7bdffb1cb0db', 27506);
INSERT INTO Doacao_Candidatura
VALUES ('a95cdb9b-7e32-4de3-8b97-b756229e421a', '5bc34570-37f6-403c-bb94-b5680b222e37', 57608);
INSERT INTO Doacao_Candidatura
VALUES ('717211c3-4e03-446f-8e83-f5fbb8420d8f', '74aea8d0-c2d4-41b5-ae48-ec59d6a890ad', 62080);
INSERT INTO Doacao_Candidatura
VALUES ('a694143e-e7e9-46d7-a002-d16c0252fe02', 'bd58d1f9-2ebb-4678-82dc-808391f2be40', 36868);
INSERT INTO Doacao_Candidatura
VALUES ('5d84c067-54b6-40fb-8e81-ad2748ec9cc7', '6589a19f-85ad-463d-b165-9eea51ff410e', 32223);
INSERT INTO Doacao_Candidatura
VALUES ('e49e6378-c55a-4f5e-a6ba-5425a78653e0', '3bfc76f3-0406-4b14-b002-833ba5830301', 50979);
INSERT INTO Doacao_Candidatura
VALUES ('95b85a71-1ff0-41c4-9a12-e6bd0c1a39af', '68c6606b-d157-4a29-bc9e-bd41941a6464', 76910);
INSERT INTO Doacao_Candidatura
VALUES ('e110c8a1-5bb1-4e18-99ac-4f1a111306d1', '8f50fbe3-520f-491d-95ae-4c1e5861410b', 88158);
INSERT INTO Doacao_Candidatura
VALUES ('0531fe4f-da16-4bfa-9a29-3fb4d79d793a', '6a4f136e-8027-4608-b475-d9986f778430', 7076);
INSERT INTO Doacao_Candidatura
VALUES ('db2039dc-c368-4510-9edb-f945dc59c969', '3418ef88-c75e-4831-ad57-9f40d63555e5', 68006);
INSERT INTO Doacao_Candidatura
VALUES ('6a323535-3436-4bfb-940c-e1f3e0c3766a', '5609512e-2359-49e5-ac67-2faeca1322bb', 49082);
INSERT INTO Doacao_Candidatura
VALUES ('8e5891b5-48c1-4fcb-9bf6-8cc0d1b12c05', '6d689799-c3b8-47d6-9fa9-97297a5c3f57', 22918);
INSERT INTO Doacao_Candidatura
VALUES ('f8edc021-cbc4-402a-968d-a9f7a672cf3f', 'a9414437-cd9d-4581-8203-35c8e3a32953', 36552);
INSERT INTO Doacao_Candidatura
VALUES ('55b49a61-c3c0-4e9e-9e27-2dca2a5c3f06', '297f1929-22be-4b55-87ae-be428e034073', 23959);
INSERT INTO Doacao_Candidatura
VALUES ('572b8f36-c028-4b3e-b7b9-9c23c99ad3a8', '32943a04-0ac8-4a6a-8930-173d555ff846', 35232);
INSERT INTO Doacao_Candidatura
VALUES ('9c8906ea-679d-4e45-9001-11af8bb2bb8e', 'a38e25c0-adc3-435c-99cd-1df58cc907ff', 34644);
INSERT INTO Doacao_Candidatura
VALUES ('01ff9741-0f56-448f-a312-2c11f77fc8e6', '32aaab2f-9a57-4c3f-a836-b44c5ea37808', 50512);
INSERT INTO Doacao_Candidatura
VALUES ('2d353b3c-31f9-468d-9a00-83c800c5bdda', '91a3a2dd-e286-4354-93a8-eba52c14a102', 30616);
INSERT INTO Doacao_Candidatura
VALUES ('0e7322e3-ffb7-40b5-9cc2-a49a445b18d9', '73d1d28c-128a-47c1-a5a9-442d3b531a87', 95721);
INSERT INTO Doacao_Candidatura
VALUES ('e1e35f7a-14ca-4db0-b28c-abaa4227ab0f', 'd8c07196-ef29-485b-809d-6492dbcf2731', 69581);
INSERT INTO Doacao_Candidatura
VALUES ('8b82731a-6728-46f7-9515-94d8019bd4da', '6cb79bb4-351a-46ef-b1ea-79f45f67f5c0', 52893);
INSERT INTO Doacao_Candidatura
VALUES ('59cfdb91-d196-4949-97b3-c3df18e178b1', '5f861330-813a-4fdb-b72b-6aedc881e24e', 63444);
INSERT INTO Doacao_Candidatura
VALUES ('0275a66a-7331-42a0-b773-7e4d1926305f', '0ad29218-a08c-4d67-b625-de514098795a', 69475);
INSERT INTO Doacao_Candidatura
VALUES ('5e8027ad-3939-4950-83fa-81d296332ea2', '8e3ff9b2-d8f6-4b35-92ab-a727242efd2e', 91840);
INSERT INTO Doacao_Candidatura
VALUES ('66d7bb0b-4a0e-418b-9504-3681f6a80fa1', '0930484e-3141-498f-8805-7df270d5aed9', 36451);
INSERT INTO Doacao_Candidatura
VALUES ('b7f32e7e-62aa-4cc8-88cf-9e3828cd8eec', '70d47789-ce52-4053-b16d-893752e80874', 62487);
INSERT INTO Doacao_Candidatura
VALUES ('22e7cd14-3022-49bd-9712-354576bc34b8', 'c158bef2-b8ff-4eb0-b184-22faa4bc9a4e', 59824);
INSERT INTO Doacao_Candidatura
VALUES ('f2c5a08f-28b0-4ffd-9d45-f83a3e13e78e', '1174f2ae-df13-4ca7-8d87-797fb2739ba0', 4836);
INSERT INTO Doacao_Candidatura
VALUES ('a11fec21-a19b-4661-ad25-f8c025ee9929', '6a4f136e-8027-4608-b475-d9986f778430', 88282);
INSERT INTO Doacao_Candidatura
VALUES ('b7c48b41-7e79-4672-bfc0-d124ac03cd1a', '54bbd357-a345-427e-a7a8-e497929dc9c9', 42383);
INSERT INTO Doacao_Candidatura
VALUES ('e71a8899-a249-4901-925b-85000c2e37b4', '5f861330-813a-4fdb-b72b-6aedc881e24e', 75158);
INSERT INTO Doacao_Candidatura
VALUES ('3dd7dee9-4da0-4b3a-b947-c2da933e7936', '7c180492-4c56-4b4f-b7d8-232fcb269ff6', 73035);
INSERT INTO Doacao_Candidatura
VALUES ('e070022e-3fee-4d18-be82-36159e7470db', '28e4be1f-85bf-46e2-8f94-dcea71baf1a8', 52235);
INSERT INTO Doacao_Candidatura
VALUES ('1fc8f428-7253-454b-95fc-1ed295a40b80', 'f959a757-7d2e-48ec-bb9e-bc670795cb80', 57924);
INSERT INTO Doacao_Candidatura
VALUES ('a941e6de-1187-43b9-ab04-2edbec1fb748', '8d1ed05b-a004-4bf1-af63-f96b52e0baca', 54967);
INSERT INTO Doacao_Candidatura
VALUES ('cab1b389-3376-4307-9a25-8d1d3b82afb5', '4c3bdf70-dba9-4eb2-8241-97f524f8bc5d', 85756);
INSERT INTO Doacao_Candidatura
VALUES ('490c230f-f9ce-41d8-82f2-71a866dae764', '33e3ebaf-04e6-48f9-b796-0157b29f2469', 58404);
INSERT INTO Doacao_Candidatura
VALUES ('4d698144-9f26-4adb-8c8b-a85bc68a4b6f', 'a162ac72-4be3-44c6-9c4a-8018be6c84d0', 225);
INSERT INTO Doacao_Candidatura
VALUES ('10890d85-400f-4b92-8011-1dabedaf706f', '0ad29218-a08c-4d67-b625-de514098795a', 35292);
INSERT INTO Doacao_Candidatura
VALUES ('913c110a-8540-47a9-81ac-429b5b76b39e', '48b5e119-d9e6-4cd7-a22f-b1dbe455dbe4', 69552);
INSERT INTO Doacao_Candidatura
VALUES ('99b4379b-19aa-4e09-b8b2-b278f22a0a96', '4ba67991-f16b-42ad-9373-660e707c2cd0', 44347);
INSERT INTO Doacao_Candidatura
VALUES ('47d6e465-aa53-440c-a8bb-caea10433920', 'b79c361d-bc3a-43fc-bfff-8563e7f7aeb2', 19304);
INSERT INTO Doacao_Candidatura
VALUES ('41d32e59-3e42-428e-b8f4-8004e839d26b', 'a162ac72-4be3-44c6-9c4a-8018be6c84d0', 94254);
INSERT INTO Doacao_Candidatura
VALUES ('977f5dec-1375-4312-b00a-5bac653b98dc', '2903e693-e909-49b9-be4b-3c1c06527e06', 19043);
INSERT INTO Doacao_Candidatura
VALUES ('e597267b-5dd8-455f-a0be-6cad40bc13ab', 'c6a07501-5ba6-49de-a607-9aea8cc7ba10', 4125);
INSERT INTO Doacao_Candidatura
VALUES ('ffffcd8d-8163-48be-8b9c-45d62c6c5ec8', 'a69d95ce-fec2-48db-a4c2-b5bb36e78ef7', 738);
INSERT INTO Doacao_Candidatura
VALUES ('d4479cc4-3318-48b4-b290-821cb1721270', '92a69a75-66c8-4286-88f4-f840b6b0149d', 84332);
INSERT INTO Doacao_Candidatura
VALUES ('cb484f98-e1b5-4742-9632-435a6bb1af65', 'ce701bd0-8264-414c-9203-732090b2758d', 16932);
INSERT INTO Doacao_Candidatura
VALUES ('04c4546e-d4c0-4a7d-adb3-67b67b523c12', 'e8cc7195-02e1-42ed-ad72-ba6aa621df46', 66261);
INSERT INTO Doacao_Candidatura
VALUES ('10078f2b-1d50-4e0a-8462-2b94d6f86576', '13a3590c-c471-4076-bc0c-7bdffb1cb0db', 44081);
INSERT INTO Doacao_Candidatura
VALUES ('b26b2af4-cdef-4d4e-a048-7b05c3e140bf', '94b73206-c83f-4ceb-be7a-18dba349fcc2', 4148);
INSERT INTO Doacao_Candidatura
VALUES ('c1121294-0ac8-4350-a07e-5516ad908d0e', 'c5c7d952-98bf-4354-b22e-1cc01ec63178', 60228);
INSERT INTO Doacao_Candidatura
VALUES ('ce71384c-c098-426d-aa8d-f2a3a5bb297a', '2023f4e9-973e-4f7e-a802-ce668c2a9577', 97150);
INSERT INTO Doacao_Candidatura
VALUES ('dc7481d8-4561-4e74-9e6a-307d0dcef706', '1f087b92-f408-4e38-a5d5-9a2fdbdfad97', 24500);
INSERT INTO Doacao_Candidatura
VALUES ('d08fbba2-2c87-49d4-9471-7856fdca6bbd', '64a7a412-dcf1-49ca-b642-f37c2df4b3e6', 2892);
INSERT INTO Doacao_Candidatura
VALUES ('7d34cdc5-097d-43c2-8211-f739e22cdada', 'dbca96cb-8b7a-4068-b5e0-40b972174455', 1504);
INSERT INTO Doacao_Candidatura
VALUES ('d7f6fc25-ed06-4ef8-867e-9a466fad0172', '7c180492-4c56-4b4f-b7d8-232fcb269ff6', 23298);
INSERT INTO Doacao_Candidatura
VALUES ('341f49d7-e232-4d12-b6da-62d99a2ecedb', '9cd06905-6f12-4b3c-8a18-d7672301d585', 93300);
INSERT INTO Doacao_Candidatura
VALUES ('8ab46c9c-384a-4a37-9b29-17f42e215789', 'd29153b1-19d5-4d53-8297-c1ed6ea45983', 5152);
INSERT INTO Doacao_Candidatura
VALUES ('df751b3a-1775-4d44-8d35-02b9b6448500', 'b383fd69-787b-45dc-bc35-ad6ab80e9ae0', 48648);
INSERT INTO Doacao_Candidatura
VALUES ('78ef4969-bd9f-4e18-91c9-161bb9fa7f9f', '9f327d65-6cb1-4188-87ba-68330879c237', 65687);
INSERT INTO Doacao_Candidatura
VALUES ('009fe70b-8546-43bc-9b3a-146b06d56b12', '140cd5be-ed69-4a9d-8e49-93f6b928f867', 41699);
INSERT INTO Doacao_Candidatura
VALUES ('379c2f45-e578-485b-bae7-8f30b0f4db4d', 'c158bef2-b8ff-4eb0-b184-22faa4bc9a4e', 9157);
INSERT INTO Doacao_Candidatura
VALUES ('26a372d4-96c4-4306-90ab-a0725acd1fb1', 'c72f952e-401a-4202-9c77-29d8f915b624', 12750);
INSERT INTO Doacao_Candidatura
VALUES ('7862bf4d-3552-4614-bdea-32e495b6cdc6', '4c4b01be-f156-409d-9fd9-bf14c4d89623', 77692);
INSERT INTO Doacao_Candidatura
VALUES ('ba2a4f1e-d68b-48be-8a57-249551696055', '45ccdd0e-a9cc-49e6-b1fc-b0dc38975289', 37491);
INSERT INTO Doacao_Candidatura
VALUES ('d7cae7ba-6b1c-4626-b206-ee4844121d3b', '8d1ed05b-a004-4bf1-af63-f96b52e0baca', 17117);
INSERT INTO Doacao_Candidatura
VALUES ('49f45d09-6096-4402-9dc1-c41a7afd565a', '5efec858-80bd-4121-a359-02b9ece2d0ec', 86917);
INSERT INTO Doacao_Candidatura
VALUES ('dc437c62-e1e6-491c-b595-f8a54205eba0', '45ccdd0e-a9cc-49e6-b1fc-b0dc38975289', 68366);
INSERT INTO Doacao_Candidatura
VALUES ('2e108ec0-8e68-410e-bb91-dfeba29b1799', 'be7ca7b4-fa4c-4847-bf8a-fc5d7f2c9f26', 66392);
INSERT INTO Doacao_Candidatura
VALUES ('57119800-75ec-41e4-9392-75506b21d2b7', 'c93a41cf-0a2f-442e-bc7a-7a7b4d17217e', 89214);
INSERT INTO Doacao_Candidatura
VALUES ('dd6a6c0e-a7d6-4163-afe9-f4ebf13a5038', '63409ca7-7f16-4a80-97c3-3d34641801eb', 79565);
INSERT INTO Doacao_Candidatura
VALUES ('1ece8537-c872-4d75-b275-14ef2ea8e12a', 'e0bb9e92-3c30-456a-9f5e-38c96a97bb75', 42974);
INSERT INTO Doacao_Candidatura
VALUES ('8a921659-8187-4715-a058-c0bafd7f9d7f', 'f0ce9306-5a82-4a8e-9e10-d2806b085ee4', 62708);
INSERT INTO Doacao_Candidatura
VALUES ('455dd177-67b3-4921-a998-cf26543797c0', '1d92b744-fdb0-45c3-b55c-23a244f3c4df', 20638);
INSERT INTO Doacao_Candidatura
VALUES ('ce071a5d-0e6e-4d91-af5a-152229b1187a', '98329dbb-4ab8-4695-8eda-e3f0cbe8f772', 5529);
INSERT INTO Doacao_Candidatura
VALUES ('16112d12-74d6-4c8d-8db6-76c85468a037', 'a38e25c0-adc3-435c-99cd-1df58cc907ff', 85869);
INSERT INTO Doacao_Candidatura
VALUES ('f349808e-3d3c-4aec-ac5f-485a65177cd5', '4c61a472-269b-4cbc-a22d-a3b00f50a644', 42782);
INSERT INTO Doacao_Candidatura
VALUES ('17498d97-1395-49bd-be1d-3637b1f020ec', '53238421-e94b-4a86-b15c-2003b00f2845', 88366);
INSERT INTO Doacao_Candidatura
VALUES ('51fa2b48-e304-466c-b2d5-db8577b7602b', '22e594ff-eda0-407c-99bf-3d646fd30a8e', 86311);
INSERT INTO Doacao_Candidatura
VALUES ('f0ba6654-c012-4df7-b019-d6c1582ca9f6', '9373e77c-8364-4eff-92a4-1bf859f2bb96', 38825);
INSERT INTO Doacao_Candidatura
VALUES ('d8f56871-6bf2-4f48-93d8-1b6e8dd642c9', 'ab11040b-d0ec-4f4d-abdc-7e38a0c5fe27', 7356);
INSERT INTO Doacao_Candidatura
VALUES ('f47c97f3-82e5-427c-8684-417638459697', '41040666-f86d-4621-bf5c-c429a33bde6e', 89537);
INSERT INTO Doacao_Candidatura
VALUES ('e260fd25-adb6-47be-9208-34570a29dfb4', 'eb999932-087b-496e-939d-fc14e5795ace', 45838);
INSERT INTO Doacao_Candidatura
VALUES ('1723a6a8-b012-4cb3-bd7f-9a797d318489', '7d48c51a-22be-4e56-bf7b-ce63f746abda', 25752);
INSERT INTO Doacao_Candidatura
VALUES ('3f554f9b-b1f3-49ae-b1e4-76fdcf2d7f2e', 'ee418562-06a5-421e-b141-ac5371b3797c', 6236);
INSERT INTO Doacao_Candidatura
VALUES ('8c7422f2-2ba7-491a-b2df-3c9e6b9ce4e0', 'a162ac72-4be3-44c6-9c4a-8018be6c84d0', 38969);
INSERT INTO Doacao_Candidatura
VALUES ('999c282f-ad83-49ba-b5ed-8e796e2db869', '64a7a412-dcf1-49ca-b642-f37c2df4b3e6', 21084);
INSERT INTO Doacao_Candidatura
VALUES ('cf6ca021-ff6f-47fb-a192-9ab53bd6888e', '4c61a472-269b-4cbc-a22d-a3b00f50a644', 81829);
INSERT INTO Doacao_Candidatura
VALUES ('8bdd644a-467e-4e94-a655-8cd9541446d1', '29f7ed80-7bbf-417a-bc54-73d54df821ee', 76434);
INSERT INTO Doacao_Candidatura
VALUES ('c1aa2ccb-6554-46cc-bcf9-456a573d5274', '1b21978a-c6a0-4003-9577-121bf841fffc', 6542);
INSERT INTO Doacao_Candidatura
VALUES ('fea222b7-ef39-4ae9-8f30-dceda72dda69', 'e0bb9e92-3c30-456a-9f5e-38c96a97bb75', 23510);
INSERT INTO Doacao_Candidatura
VALUES ('404fe384-5059-461f-945d-65546af1ba5e', 'c6a07501-5ba6-49de-a607-9aea8cc7ba10', 57863);
INSERT INTO Doacao_Candidatura
VALUES ('3f8dc7b2-e047-499e-b77c-4cb6f29fb4a4', 'b0350cf5-b002-4d30-a6f0-a9c7f704af51', 43420);
INSERT INTO Doacao_Candidatura
VALUES ('ad19126a-fe59-4194-a7b2-77444c21b1a3', '70d47789-ce52-4053-b16d-893752e80874', 23796);
INSERT INTO Doacao_Candidatura
VALUES ('1dfbe08a-f872-424b-88de-dd916c8d8812', 'fe1edb1c-4bd5-4905-ac92-152c9eed1d0b', 27021);
INSERT INTO Doacao_Candidatura
VALUES ('e6b44fc6-57f4-49cf-8cd3-166b50dec1ab', '98329dbb-4ab8-4695-8eda-e3f0cbe8f772', 98330);
INSERT INTO Doacao_Candidatura
VALUES ('a4378666-9861-41d6-a91c-c749151dff5a', '15212973-0f4e-41b1-9c28-83ac96619cc5', 4685);
INSERT INTO Doacao_Candidatura
VALUES ('be69efcf-21b2-40cc-88e3-2b699fcb52c4', '815b61df-2c36-4ff7-9ca5-c4d9c2d1fa5e', 83358);
INSERT INTO Doacao_Candidatura
VALUES ('912f1b98-5c92-40db-898e-ac54905a7054', 'c86a48c3-7ed8-46c3-879d-173172bcbbf6', 43772);
INSERT INTO Doacao_Candidatura
VALUES ('bb539e53-9bc6-4035-96bd-6cd824aa2583', 'ac46448c-6473-44ea-b7ef-6d223320e7cb', 31290);
INSERT INTO Doacao_Candidatura
VALUES ('14f0b729-bc96-4bbd-8e0a-3d506631232a', '5ff570ec-591f-46f7-82dd-362e8027db46', 12222);
INSERT INTO Doacao_Candidatura
VALUES ('14949811-86d2-4306-81b4-ef8444401374', '30c516bf-c593-4548-bfc4-47b329487851', 33379);
INSERT INTO Doacao_Candidatura
VALUES ('29b4a20d-b9aa-4607-a016-38bd6544301f', '53238421-e94b-4a86-b15c-2003b00f2845', 7894);
INSERT INTO Doacao_Candidatura
VALUES ('654e5406-edce-4f80-bd58-e8127e3170d7', '28e4be1f-85bf-46e2-8f94-dcea71baf1a8', 58923);
INSERT INTO Doacao_Candidatura
VALUES ('09762316-0dac-4cb4-96aa-9a14284435e8', 'ee717286-8f2d-4f33-b191-fe78358f32b5', 76044);
INSERT INTO Doacao_Candidatura
VALUES ('4be084a2-0472-4d93-9abc-df35bd4b848e', 'bd069ee4-6a7c-4e1c-a52d-88a21c815dab', 46619);
INSERT INTO Doacao_Candidatura
VALUES ('b64eb4f7-04d6-4d43-84cf-8df8b0dde18c', 'b388b6ab-8d74-4843-9ed6-8de3e0fd490e', 30029);
INSERT INTO Doacao_Candidatura
VALUES ('a3f79f1f-a6cb-4979-a16d-ced3df95e1cc', 'dee5de45-10ed-4393-b711-0e98e204a8e4', 9271);
INSERT INTO Doacao_Candidatura
VALUES ('961714fa-a037-4e50-8706-bd295b3e5ed2', '68c6606b-d157-4a29-bc9e-bd41941a6464', 71227);
INSERT INTO Doacao_Candidatura
VALUES ('70f554f6-ad0e-43b9-ac7c-463c794adf29', '640f433b-d510-4411-b3b5-57a06940939d', 51188);
INSERT INTO Doacao_Candidatura
VALUES ('2bc03b58-198c-4745-a6ae-e4a9f48e65fb', 'db1046ca-5c7e-48ac-a1c1-7d942a9acd7b', 34724);


-- Insere Processos Judiciais
INSERT INTO Processo_Judicial
VALUES ('60d7f71b-078d-456a-af3d-134cc8d3f845', '2010-2-10',
        '2020-10-2', true, '33670471631');
INSERT INTO Processo_Judicial
VALUES ('fa09dabb-0168-425c-80c8-8f19c7268fe0', '2015-1-6',
        NULL, true, '88159796837');
INSERT INTO Processo_Judicial
VALUES ('18bc4d76-afd9-4f1e-bc35-f8f8b147e4ba', '2005-9-14',
        '2017-6-7', false, '65810908826');
INSERT INTO Processo_Judicial
VALUES ('1a44c793-ab5e-4690-a77c-0dfc91586bca', '2004-9-6',
        NULL, true, '35014395120');
INSERT INTO Processo_Judicial
VALUES ('001be3c9-1334-4c0e-bc65-19948ff5f663', '2007-11-11',
        NULL, true, '65601518931');
INSERT INTO Processo_Judicial
VALUES ('8bcea302-7420-44f5-8a5f-e92309f18d67', '2019-2-21',
        '2017-8-27', false, '79857502803');
INSERT INTO Processo_Judicial
VALUES ('87c39195-82cf-4379-ace1-14703fbf2456', '2014-2-15',
        '2021-1-14', false, '61570064800');
INSERT INTO Processo_Judicial
VALUES ('5f11c659-4410-4d02-803a-880c641db5c2', '2010-1-25',
        '2021-2-26', true, '80145377612');
INSERT INTO Processo_Judicial
VALUES ('a6f652fb-3b29-474a-aa7a-51aceedcf46c', '2019-2-28',
        '2018-2-14', true, '68224937592');
INSERT INTO Processo_Judicial
VALUES ('3eaceed6-a964-4b9b-baa4-90e97b4ac9fd', '2020-11-16',
        NULL, false, '92310514114');
INSERT INTO Processo_Judicial
VALUES ('0e47e4f8-3a48-4666-95a1-c0d099e28063', '2016-7-21',
        NULL, true, '75320973584');
INSERT INTO Processo_Judicial
VALUES ('979bea35-fd93-4d60-9f59-8aff522aff86', '2012-10-5',
        NULL, true, '21959062153');
INSERT INTO Processo_Judicial
VALUES ('dc9552d4-0c92-44e9-b49f-2aa6e7eb3519', '2003-10-7',
        NULL, false, '88995994818');
INSERT INTO Processo_Judicial
VALUES ('06b39f4b-52ed-4344-814c-bea218372a68', '2002-7-23',
        NULL, false, '45841697754');
INSERT INTO Processo_Judicial
VALUES ('24dd3228-d60c-4c3f-b002-a1d2c13b32e7', '2020-4-12',
        NULL, true, '19962675774');
INSERT INTO Processo_Judicial
VALUES ('ba6f109a-8cb6-4086-998b-f62e7bfbd245', '2010-2-23',
        '2017-5-18', true, '76730977462');
INSERT INTO Processo_Judicial
VALUES ('8e00be91-3005-4ac1-8429-e595a2551840', '2016-1-18',
        NULL, true, '27781179496');
INSERT INTO Processo_Judicial
VALUES ('891736c3-e314-42f0-a4f8-eb8df2e98b9b', '2003-5-2',
        '2020-5-13', true, '29543020694');
INSERT INTO Processo_Judicial
VALUES ('ca8eca3c-cc2d-4b04-a4e5-940256179863', '2010-11-2',
        NULL, true, '16300685813');
INSERT INTO Processo_Judicial
VALUES ('35f4b770-2d1b-4974-8392-7c90ed61caa0', '2003-9-15',
        NULL, false, '38336047478');
INSERT INTO Processo_Judicial
VALUES ('aabf71ce-6b3c-4976-b6bd-79c339ddbef0', '2011-11-6',
        NULL, false, '80985354657');
INSERT INTO Processo_Judicial
VALUES ('c2c5f7e9-ae51-4220-8f60-3c8bc341b8f2', '2016-5-27',
        NULL, true, '56392738602');
INSERT INTO Processo_Judicial
VALUES ('1217fa1c-0622-4f2a-a5fe-b22543de792a', '2009-7-31',
        NULL, false, '97014694346');
INSERT INTO Processo_Judicial
VALUES ('b54b2912-13d3-463f-8eee-7a9a84874637', '2021-10-27',
        NULL, true, '43832994084');
INSERT INTO Processo_Judicial
VALUES ('e84d0d2b-07a9-4d2d-9fdc-4a68301b97ac', '2004-4-25',
        '2017-4-9', true, '74553356398');
INSERT INTO Processo_Judicial
VALUES ('5687a9fa-29fc-466a-9e07-970a5586e855', '2004-11-5',
        '2020-9-12', false, '56392738602');
INSERT INTO Processo_Judicial
VALUES ('62bd4895-b6a1-41e7-b269-12bfc863fd72', '2010-11-23',
        NULL, false, '66261561494');
INSERT INTO Processo_Judicial
VALUES ('7fbbfade-30d2-44e1-87de-2718c12f2b92', '2010-11-25',
        NULL, false, '84538009271');
INSERT INTO Processo_Judicial
VALUES ('5652b489-0e6f-45e5-b8c9-a82a37794692', '2021-4-25',
        '2019-2-3', true, '14911504909');
INSERT INTO Processo_Judicial
VALUES ('bf8cd284-9f17-4283-a42e-523d5af1e793', '2011-3-8',
        '2021-7-17', true, '91828825019');
INSERT INTO Processo_Judicial
VALUES ('3ef471f7-0c32-4eb8-80c1-6b94f8ce93f7', '2013-7-12',
        '2017-2-26', false, '65745125890');
INSERT INTO Processo_Judicial
VALUES ('65033d7f-4f9a-43a3-a14d-70c92cbf8e99', '2008-5-31',
        NULL, false, '98651677060');
INSERT INTO Processo_Judicial
VALUES ('77e8a3b8-329a-4b7f-86c6-11a4fb06b6b7', '2017-6-17',
        NULL, false, '85722795790');
INSERT INTO Processo_Judicial
VALUES ('3982f97a-c8a1-4d2c-8ba3-e6bd3dc0496a', '2021-7-28',
        NULL, false, '85421043294');
INSERT INTO Processo_Judicial
VALUES ('f33396c2-52a8-4a0a-a099-456923f1271e', '2002-8-20',
        NULL, true, '60892811592');
INSERT INTO Processo_Judicial
VALUES ('369cc2dd-b043-45bd-827e-11eddf69da09', '2008-5-15',
        NULL, true, '68440822518');
INSERT INTO Processo_Judicial
VALUES ('c4618bfa-3fd5-47d7-a4fb-e0dd565ddf4d', '2021-1-10',
        NULL, true, '90524761965');
INSERT INTO Processo_Judicial
VALUES ('5ccecdea-0e91-477c-b36a-d589a8fe65c2', '2010-10-31',
        '2018-11-12', false, '44242259408');
INSERT INTO Processo_Judicial
VALUES ('3d6aabec-2c8e-4859-8342-b1a01453b5c9', '2018-4-11',
        '2018-11-12', true, '45378367919');
INSERT INTO Processo_Judicial
VALUES ('b08e2498-3e38-4a88-9c8c-2cd015fc5fb4', '2019-5-29',
        NULL, true, '97948715968');
INSERT INTO Processo_Judicial
VALUES ('b27b3497-e675-4114-9512-b8dec3cafa4e', '2019-10-6',
        NULL, false, '28251362228');
INSERT INTO Processo_Judicial
VALUES ('2ae03a87-71f8-41a5-a254-78f2b11cb155', '2014-12-2',
        '2018-9-23', true, '10297100099');
INSERT INTO Processo_Judicial
VALUES ('76b1f25e-3efd-485e-8f18-80d51e637229', '2004-2-18',
        '2019-7-29', false, '97844949536');
INSERT INTO Processo_Judicial
VALUES ('88e52d14-2ee5-426f-b730-735ebbb3f491', '2006-11-22',
        NULL, true, '20534925025');
INSERT INTO Processo_Judicial
VALUES ('df7b832b-dc80-4154-836f-8222b7813bbc', '2007-10-1',
        NULL, false, '63353046625');
INSERT INTO Processo_Judicial
VALUES ('d32b7522-7d7e-49f5-a4ce-ccb6cd81acaa', '2020-12-29',
        '2019-6-28', true, '44242360976');
INSERT INTO Processo_Judicial
VALUES ('adb03ea6-bf16-4e08-a379-819e46946678', '2012-3-3',
        NULL, true, '50722760849');
INSERT INTO Processo_Judicial
VALUES ('7b4f1d0a-0be8-4df2-9ee7-108481e057a5', '2004-11-24',
        NULL, true, '45841697754');
INSERT INTO Processo_Judicial
VALUES ('6dd2bdc2-f705-49f0-8667-32f55799803a', '2010-12-10',
        NULL, false, '91892894401');
INSERT INTO Processo_Judicial
VALUES ('61f25f91-03f0-41cb-a9eb-4869a5528001', '2017-11-3',
        '2018-10-22', false, '57748351241');
INSERT INTO Processo_Judicial
VALUES ('98af8fe8-2a31-47ab-8cb3-61b471dae83e', '2015-1-9',
        '2021-9-23', false, '32866277098');
INSERT INTO Processo_Judicial
VALUES ('ea0dfc05-6969-4df4-8d0a-e2b89073247a', '2014-8-15',
        '2018-10-11', false, '83326663854');
INSERT INTO Processo_Judicial
VALUES ('ace4d615-aeb4-4cdf-9189-c62281ee32d6', '2002-7-15',
        '2018-2-22', true, '83335207737');
INSERT INTO Processo_Judicial
VALUES ('3049dc8c-dd38-4ea1-8913-08a9bd59b6ac', '2010-12-27',
        NULL, false, '37496586486');
INSERT INTO Processo_Judicial
VALUES ('d8a414c6-bee7-47ac-b75a-f7d61ada9319', '2019-11-30',
        '2021-9-12', true, '64878309026');
INSERT INTO Processo_Judicial
VALUES ('193ea370-59bb-4e9b-804e-e5468f861619', '2015-7-14',
        '2020-10-7', true, '14430595960');
INSERT INTO Processo_Judicial
VALUES ('1f9c9be2-7ed7-4323-b5b4-dda82fa7bb2b', '2021-4-20',
        NULL, false, '69263624604');
INSERT INTO Processo_Judicial
VALUES ('8c5dffc5-f930-499d-af70-3e34d19bb5da', '2014-6-9',
        '2017-4-20', false, '13249461750');
INSERT INTO Processo_Judicial
VALUES ('f6f46254-dab6-4e27-aa7a-51cc5f4565df', '2014-9-14',
        '2020-1-14', false, '33855325537');
INSERT INTO Processo_Judicial
VALUES ('9f7ebac2-df8c-45c6-b676-76e76dfe50ab', '2014-7-5',
        NULL, false, '46951443084');
INSERT INTO Processo_Judicial
VALUES ('9e39dc76-1ee8-4a8d-9f13-62cec76be867', '2014-1-3',
        '2019-12-14', true, '96834017981');
INSERT INTO Processo_Judicial
VALUES ('0c1aa6d8-b743-46a8-8c3e-a3dd86b8b060', '2020-5-6',
        '2019-9-21', false, '22420991435');
INSERT INTO Processo_Judicial
VALUES ('7571577e-e61c-4c41-8ebe-5d7e43d6a2ed', '2003-10-3',
        NULL, true, '80145377612');
INSERT INTO Processo_Judicial
VALUES ('ddec8628-79b9-46cd-ad7b-46fb3f4ffd14', '2004-6-29',
        NULL, false, '53324051348');
INSERT INTO Processo_Judicial
VALUES ('e36bfc16-b91a-449c-856f-8f078c0249ff', '2017-4-17',
        '2020-2-9', false, '12836654633');
INSERT INTO Processo_Judicial
VALUES ('a5e91d11-b88a-4baa-95ef-ce557c387588', '2013-9-1',
        NULL, false, '85471168039');
INSERT INTO Processo_Judicial
VALUES ('c515c5c8-5aaa-4cc6-995a-799939991892', '2011-1-10',
        '2020-9-22', false, '49878119379');
INSERT INTO Processo_Judicial
VALUES ('357099e3-76c5-423f-baf9-df2f2de78a70', '2003-4-6',
        '2021-2-17', false, '13409115150');
INSERT INTO Processo_Judicial
VALUES ('af73fb2b-46e2-4228-be30-4bd7f2b9bb46', '2015-10-17',
        '2021-8-15', false, '64684924166');
INSERT INTO Processo_Judicial
VALUES ('32efef2c-7153-4933-a967-b68e307b23d4', '2019-3-13',
        '2019-8-11', true, '42206480598');
INSERT INTO Processo_Judicial
VALUES ('50d83745-30d9-4828-977c-a6b2b78a691d', '2016-6-14',
        '2020-6-10', true, '88249640718');
INSERT INTO Processo_Judicial
VALUES ('0da73114-1316-43e0-be6c-d72211c9855a', '2017-7-17',
        NULL, true, '28691501056');
INSERT INTO Processo_Judicial
VALUES ('506816ca-ce6b-429c-bd05-90664532fb76', '2004-12-20',
        NULL, true, '29005892204');
INSERT INTO Processo_Judicial
VALUES ('fc87b8e8-7a03-4d67-8560-367fa423254b', '2012-4-8',
        NULL, false, '95325006309');
INSERT INTO Processo_Judicial
VALUES ('b5a78565-4239-40b2-88d7-4b2f7786452d', '2018-2-23',
        '2016-12-25', false, '56392080958');
INSERT INTO Processo_Judicial
VALUES ('253c92b0-f14c-41ad-85fe-2306fc078089', '2003-4-6',
        NULL, true, '40367657486');
INSERT INTO Processo_Judicial
VALUES ('02896caf-1556-4150-ad66-3585cbeefb04', '2007-6-20',
        NULL, false, '85452085987');
INSERT INTO Processo_Judicial
VALUES ('391a6023-27e5-4eb6-b34c-5e1841ab39e7', '2015-11-5',
        '2020-12-31', true, '86912200003');
INSERT INTO Processo_Judicial
VALUES ('533cd580-519b-4913-80a9-05e7a62a39e8', '2017-1-8',
        '2018-9-6', false, '71791716990');
INSERT INTO Processo_Judicial
VALUES ('9a0b44f4-3b83-475c-a506-82e73c2e26f0', '2019-7-26',
        '2021-8-23', true, '88091845146');
INSERT INTO Processo_Judicial
VALUES ('0e0d2bca-c2a9-4161-8762-1fc1da9a5c69', '2008-1-22',
        NULL, true, '81989843735');
INSERT INTO Processo_Judicial
VALUES ('14487a30-a5d7-4c01-86d4-1bb1e320affd', '2012-4-15',
        '2017-2-21', false, '28691501056');
INSERT INTO Processo_Judicial
VALUES ('649b6d67-bce0-4a02-8b65-7588bcd76a25', '2017-12-23',
        '2017-7-23', true, '18472580276');
INSERT INTO Processo_Judicial
VALUES ('29fcde80-497c-468d-b33d-f6c9e5bea2e7', '2003-5-14',
        NULL, true, '15007094920');
INSERT INTO Processo_Judicial
VALUES ('3074112b-58b6-47c7-9013-8b941b4d98d6', '2017-10-15',
        NULL, true, '79631428855');
INSERT INTO Processo_Judicial
VALUES ('b3d29fe1-5410-4779-9b06-aa41ef9d8a56', '2008-8-10',
        '2019-11-21', true, '34295891087');
INSERT INTO Processo_Judicial
VALUES ('d7bd4266-9dd3-41a6-868d-d63962cc3d41', '2015-12-20',
        NULL, false, '57989361614');
INSERT INTO Processo_Judicial
VALUES ('805e4e0b-ef7c-489f-b42f-3f7faa7ae310', '2018-5-22',
        '2017-8-24', true, '57690196863');
INSERT INTO Processo_Judicial
VALUES ('fb091bc9-dae5-4930-a870-c3a0a618b266', '2008-5-3',
        '2018-8-20', false, '28251362228');
INSERT INTO Processo_Judicial
VALUES ('6a4a7142-9590-4b5b-96f0-dbab2cb12f39', '2016-12-2',
        NULL, true, '28583832178');
INSERT INTO Processo_Judicial
VALUES ('e4f8fd24-a79f-48ac-b8d7-90ed6cf6c24d', '2012-7-5',
        NULL, true, '24890993377');
INSERT INTO Processo_Judicial
VALUES ('da6c5d63-3b47-4b71-8101-cfc05237991a', '2019-8-3',
        NULL, true, '19629932825');
INSERT INTO Processo_Judicial
VALUES ('c42ea47f-feaa-41d2-a158-728a738cfb2f', '2006-12-30',
        NULL, false, '96217219165');
INSERT INTO Processo_Judicial
VALUES ('9146d8b7-13a3-425c-9db5-f96c6e7fe4a8', '2014-9-27',
        NULL, true, '44973071531');
INSERT INTO Processo_Judicial
VALUES ('b5182a19-4557-48f6-bbca-84c3d6207ac8', '2012-8-29',
        '2020-5-28', false, '26316265854');
INSERT INTO Processo_Judicial
VALUES ('2fd227fa-06ee-473c-920f-75b28d59e5e9', '2013-6-6',
        NULL, false, '39015131085');
INSERT INTO Processo_Judicial
VALUES ('21453d47-0598-4573-9313-facc3efef1cb', '2006-9-8',
        NULL, false, '75170857366');
INSERT INTO Processo_Judicial
VALUES ('98fee14a-d673-468e-ab5a-af33db06cab3', '2009-7-28',
        NULL, false, '32235214128');
INSERT INTO Processo_Judicial
VALUES ('7936a3fb-309b-4cab-9c80-9998c98df0b0', '2011-7-12',
        '2021-8-5', false, '41570859046');
INSERT INTO Processo_Judicial
VALUES ('ec079a5f-277b-40dc-9e40-e17ede9fa1a7', '2015-7-9',
        NULL, false, '61250933664');
INSERT INTO Processo_Judicial
VALUES ('355d8451-b215-4630-8c34-5d8f8b48a70c', '2005-11-23',
        '2021-1-29', true, '73494647324');
INSERT INTO Processo_Judicial
VALUES ('c4ca57c3-bf58-4464-9a5b-74aac5c9fb60', '2018-9-12',
        NULL, false, '16300685813');
INSERT INTO Processo_Judicial
VALUES ('dd3f6325-5718-4a17-9f9a-4182968b8467', '2002-9-27',
        NULL, false, '61191493880');
INSERT INTO Processo_Judicial
VALUES ('a3b82e39-3f4e-438e-9bad-00959634bb69', '2017-6-14',
        '2020-3-11', false, '96993769449');
INSERT INTO Processo_Judicial
VALUES ('44607a37-4a64-42ae-8f39-976422d4da6d', '2002-5-5',
        '2020-7-4', true, '51767491549');
INSERT INTO Processo_Judicial
VALUES ('c025afc7-ad15-48b6-b8cc-f1a254bf78b5', '2018-6-9',
        NULL, false, '39221640580');
INSERT INTO Processo_Judicial
VALUES ('5e900c6e-7ae3-41c5-900d-f38dd0d5f507', '2020-3-11',
        NULL, true, '78677525506');
INSERT INTO Processo_Judicial
VALUES ('61753cb7-ff7b-49ca-a96b-2680cc985e25', '2003-2-16',
        '2018-9-2', false, '84795078553');
INSERT INTO Processo_Judicial
VALUES ('35cf0228-2ae2-4c22-8938-a19180119cfe', '2003-1-24',
        NULL, true, '12587690399');
INSERT INTO Processo_Judicial
VALUES ('8b2fef1b-4396-410e-aaf8-f0a4e984f7f7', '2021-10-16',
        NULL, false, '27614811982');
INSERT INTO Processo_Judicial
VALUES ('cf85c302-f558-44e9-aaf7-a81ddcba2b86', '2018-6-7',
        '2019-4-24', false, '61191493880');
INSERT INTO Processo_Judicial
VALUES ('866cd270-4bf0-43f0-99ef-64e953aaf73f', '2021-2-10',
        NULL, false, '19962675774');
INSERT INTO Processo_Judicial
VALUES ('0cab49c1-fe38-40f9-b322-5c2880e30f4b', '2001-12-28',
        NULL, false, '85063207736');
INSERT INTO Processo_Judicial
VALUES ('ab8597e2-6e43-4043-baf7-9630807ae680', '2006-5-5',
        NULL, false, '50989122078');
INSERT INTO Processo_Judicial
VALUES ('17154c2b-0e4d-42eb-b453-25cca6f96a15', '2006-3-10',
        '2019-2-2', false, '29665019169');
INSERT INTO Processo_Judicial
VALUES ('b225b4a2-3b68-4d31-a19c-db43565b2616', '2006-8-15',
        '2018-6-29', true, '54988852173');
INSERT INTO Processo_Judicial
VALUES ('cfd672f5-e5cb-4680-9b4f-2f39f78dbb22', '2004-5-28',
        '2018-3-23', true, '43031963950');
INSERT INTO Processo_Judicial
VALUES ('9d4defd8-9e15-4db4-a86f-f433a5ba32e6', '2016-3-13',
        '2017-1-1', false, '73565084710');
INSERT INTO Processo_Judicial
VALUES ('5f5e916b-4d14-4e6c-aa87-26cc4e5d5805', '2008-7-12',
        NULL, false, '32021542380');
INSERT INTO Processo_Judicial
VALUES ('af967e68-54b0-41a3-9df8-dcc387e6c5c2', '2017-6-29',
        NULL, false, '89964209555');
INSERT INTO Processo_Judicial
VALUES ('32ace7cd-5e83-4865-8d13-fdf49b3ad6b3', '2003-6-13',
        NULL, true, '26968071500');
INSERT INTO Processo_Judicial
VALUES ('11cf57cf-5c29-48e4-98c3-bb37d4ccf9ec', '2005-6-17',
        NULL, true, '79117540030');
INSERT INTO Processo_Judicial
VALUES ('7bb1b892-8038-4125-8a36-be101b10a717', '2015-6-25',
        NULL, false, '42253852223');
INSERT INTO Processo_Judicial
VALUES ('723eea6c-b7f3-4741-8b0e-ba17dc4b79fa', '2004-4-25',
        NULL, true, '15051016972');
INSERT INTO Processo_Judicial
VALUES ('72b740e8-00e6-4969-bcfb-9c6813c1040e', '2006-2-24',
        NULL, false, '56604801905');
INSERT INTO Processo_Judicial
VALUES ('6ee37548-b6ce-4249-bcf0-09cd61b812d3', '2012-4-5',
        NULL, true, '23646102703');
INSERT INTO Processo_Judicial
VALUES ('295b495b-0a34-4e81-a001-cc417902cfe3', '2007-11-20',
        NULL, true, '48280321999');
INSERT INTO Processo_Judicial
VALUES ('d010d3e5-5cd9-4f6e-85a5-c6445cf9d6bc', '2004-7-26',
        '2021-6-28', false, '24966265256');
INSERT INTO Processo_Judicial
VALUES ('a35e946c-7061-4c22-927b-5b2b14e71fbf', '2014-1-11',
        NULL, true, '51375660479');
INSERT INTO Processo_Judicial
VALUES ('6a2ed59a-df94-44a0-97fc-bf6e4ccd2dc5', '2014-5-18',
        '2018-3-9', false, '25185088501');
INSERT INTO Processo_Judicial
VALUES ('bbb37307-4c07-4523-9907-18fbe4112a6e', '2010-5-28',
        NULL, false, '53600938739');
INSERT INTO Processo_Judicial
VALUES ('8e081694-c273-4fea-8845-3f73f47ceb3d', '2011-1-11',
        '2021-11-7', true, '31581937542');
INSERT INTO Processo_Judicial
VALUES ('5786d9fb-d85c-4d86-9e7d-8b87e002823c', '2011-9-19',
        NULL, true, '55815897535');
INSERT INTO Processo_Judicial
VALUES ('98156e78-39b2-4f52-8582-64c23813d20f', '2018-11-25',
        '2021-5-3', true, '24488041764');
INSERT INTO Processo_Judicial
VALUES ('b2e34dbf-4cfc-4361-bf76-92dc30a98e59', '2016-10-14',
        NULL, true, '26564529193');
INSERT INTO Processo_Judicial
VALUES ('66dc2f53-baf7-4989-bee5-02747c410ca0', '2002-4-11',
        '2017-1-27', true, '26209410189');
INSERT INTO Processo_Judicial
VALUES ('9e4086f1-8db6-4530-a2cc-02f07000d52d', '2012-1-4',
        NULL, false, '79860785743');
INSERT INTO Processo_Judicial
VALUES ('2e259536-1842-40fe-921a-b232a4968e16', '2021-10-2',
        NULL, false, '58672425325');
INSERT INTO Processo_Judicial
VALUES ('5ea13514-0f48-4507-ac27-58f2fd0e340f', '2003-7-22',
        '2018-6-6', false, '11214965519');
INSERT INTO Processo_Judicial
VALUES ('8761f294-414a-4d62-8ad6-db0389f8d1c5', '2018-2-22',
        NULL, false, '35013815364');
INSERT INTO Processo_Judicial
VALUES ('632b98b5-5bcb-4391-9ca7-b1a2e6fabc51', '2021-5-10',
        '2021-9-23', false, '43096352221');
INSERT INTO Processo_Judicial
VALUES ('b25f74cf-fbfd-43c2-a95f-c6ba98cc3903', '2020-2-8',
        NULL, false, '53600938739');
INSERT INTO Processo_Judicial
VALUES ('ec524c64-99ed-4e14-be39-b0cbaf9ed9aa', '2014-1-12',
        NULL, true, '63353046625');
INSERT INTO Processo_Judicial
VALUES ('212f6d51-61fc-4077-a894-d8c0b5476e64', '2007-6-19',
        '2021-11-18', true, '85655194001');
INSERT INTO Processo_Judicial
VALUES ('84bad2ae-81fe-4e77-b9f6-b6cbf60ee43d', '2005-9-13',
        NULL, true, '59100339210');
INSERT INTO Processo_Judicial
VALUES ('8113db63-551a-4002-b2ea-4eee0c24930d', '2003-11-5',
        '2018-1-21', false, '13749101529');
INSERT INTO Processo_Judicial
VALUES ('7e1210a8-560b-4920-be92-896a58fcb81a', '2005-5-27',
        '2021-2-4', false, '21359217371');
INSERT INTO Processo_Judicial
VALUES ('c0052a2f-1d09-4af0-947f-0eee2c2eb424', '2010-9-28',
        NULL, true, '24653057004');
INSERT INTO Processo_Judicial
VALUES ('c2c4bb0c-ee94-48f8-a366-46390bc81cde', '2006-11-1',
        NULL, true, '68110109437');
INSERT INTO Processo_Judicial
VALUES ('b5c9a8ab-c2cc-4caf-ab49-ebdda70006d7', '2002-8-25',
        NULL, true, '57690196863');
INSERT INTO Processo_Judicial
VALUES ('25bafb8d-2ef1-4db7-8b24-27c52b557d6f', '2012-12-20',
        NULL, false, '84994391954');
INSERT INTO Processo_Judicial
VALUES ('9568251d-fdd2-4305-a42a-6d77bd048997', '2011-4-4',
        NULL, true, '32866277098');
INSERT INTO Processo_Judicial
VALUES ('11957e81-3a14-4955-b85f-f9fa3d36a111', '2012-8-7',
        '2019-7-26', true, '82502861178');
INSERT INTO Processo_Judicial
VALUES ('602b577a-cf96-4098-aa60-b74b2da22e1b', '2009-10-2',
        NULL, false, '86363215206');
INSERT INTO Processo_Judicial
VALUES ('54b0e740-fab4-437f-b81e-f1971f220497', '2012-4-17',
        '2019-5-20', false, '48260050807');
INSERT INTO Processo_Judicial
VALUES ('f2b81911-e203-452a-b060-66c75253836c', '2017-10-25',
        '2020-7-11', false, '58621376936');
INSERT INTO Processo_Judicial
VALUES ('6a9e2ae2-5e9f-4afc-9449-f97f5e9d535c', '2011-12-10',
        '2021-7-14', false, '62047257632');
INSERT INTO Processo_Judicial
VALUES ('ac6510d1-0c10-4287-97f5-031e1a4ba118', '2021-3-28',
        NULL, true, '11214965519');
INSERT INTO Processo_Judicial
VALUES ('8da35ba7-54e4-4f36-80ee-c10cb24b25c0', '2005-10-31',
        NULL, true, '28691501056');
INSERT INTO Processo_Judicial
VALUES ('d811d6d5-b73a-4e5f-8f05-68fdc0f48c0d', '2021-9-19',
        NULL, false, '33585029381');
INSERT INTO Processo_Judicial
VALUES ('b1669342-6937-4841-b639-68e90264be53', '2010-7-10',
        NULL, true, '37496586486');
INSERT INTO Processo_Judicial
VALUES ('20e725bb-80da-444f-b9cd-9d8e291ebf2e', '2013-2-10',
        '2021-7-1', true, '49035936468');
INSERT INTO Processo_Judicial
VALUES ('d09cb468-9e92-4345-a4e8-5146d0776c3f', '2010-8-24',
        NULL, false, '94493685548');
INSERT INTO Processo_Judicial
VALUES ('d29bc1dd-efae-407b-b967-8ae2ae69c0e7', '2019-6-23',
        '2017-1-8', true, '10664018120');
INSERT INTO Processo_Judicial
VALUES ('dd7d6c6c-ba00-4cd8-91e2-b756bed63b0b', '2005-11-12',
        NULL, false, '78677525506');
INSERT INTO Processo_Judicial
VALUES ('a9643778-cf01-40ea-ad55-a92283f98053', '2008-3-26',
        NULL, false, '69472774860');
INSERT INTO Processo_Judicial
VALUES ('bbaa0974-6f3b-417b-8c61-2488be0b5a17', '2015-11-14',
        '2017-10-16', true, '90229740976');
INSERT INTO Processo_Judicial
VALUES ('3a02ce5e-c415-48cc-99e5-1cce958a522c', '2011-4-27',
        NULL, false, '83672753747');
INSERT INTO Processo_Judicial
VALUES ('65b5e85d-90aa-4d5a-a333-d88cd7d0ef94', '2009-9-23',
        NULL, true, '69263624604');
INSERT INTO Processo_Judicial
VALUES ('d1be43ac-643c-4a54-8119-661ad5180ca0', '2010-7-3',
        NULL, true, '91017248921');
INSERT INTO Processo_Judicial
VALUES ('315ad03c-0897-4e07-83ed-818e5a9de059', '2017-7-14',
        '2017-11-19', true, '29610695552');
INSERT INTO Processo_Judicial
VALUES ('3a2dded2-4ade-41dc-8cd2-44685c1f40c1', '2017-3-13',
        NULL, false, '25462423549');
INSERT INTO Processo_Judicial
VALUES ('db994dba-1981-46d2-ab90-0ac47841f976', '2003-10-18',
        NULL, true, '20926508598');
INSERT INTO Processo_Judicial
VALUES ('5b51a131-f87d-4d89-93a7-8e529354a12b', '2015-3-29',
        '2021-3-13', false, '16893356314');
INSERT INTO Processo_Judicial
VALUES ('909ed220-31aa-4483-a5d4-0b09716824eb', '2010-7-29',
        '2017-2-18', true, '16716102720');
INSERT INTO Processo_Judicial
VALUES ('d80c3e38-c89a-47aa-bc78-30a1d538a26b', '2010-11-3',
        '2018-11-19', false, '89233355857');
INSERT INTO Processo_Judicial
VALUES ('a320a8d8-6cd1-42e0-aef3-4da148a4d7f1', '2003-4-26',
        '2018-3-26', false, '70177465768');
INSERT INTO Processo_Judicial
VALUES ('16a352bf-74ab-4742-aea9-f8b03887b4c3', '2016-11-23',
        NULL, true, '78746910984');
INSERT INTO Processo_Judicial
VALUES ('d1545540-b43d-4ae8-b01f-168581b41415', '2011-6-28',
        '2018-8-28', true, '40792622072');
INSERT INTO Processo_Judicial
VALUES ('a04606a4-c2a6-43a1-baa6-0e16bccf8556', '2021-3-21',
        NULL, true, '66659215325');
INSERT INTO Processo_Judicial
VALUES ('de4e1332-697e-4d12-808b-48564e1b8a62', '2008-4-16',
        NULL, true, '69316593371');
INSERT INTO Processo_Judicial
VALUES ('61b42fc9-57d5-4385-a910-22143815b014', '2006-2-3',
        '2021-11-2', true, '80758689786');
INSERT INTO Processo_Judicial
VALUES ('2cc06f10-627f-4f67-95f3-16f70937e18f', '2005-10-17',
        NULL, true, '93052325244');
INSERT INTO Processo_Judicial
VALUES ('c716e58c-7159-4e85-8452-94e1e51d1933', '2020-11-3',
        NULL, false, '20170554369');
INSERT INTO Processo_Judicial
VALUES ('da13029a-dc02-4c0d-a849-4c37f286b164', '2017-9-15',
        NULL, true, '16140814840');
INSERT INTO Processo_Judicial
VALUES ('774a7bae-9483-4a21-9ef6-bc3bba969287', '2015-7-7',
        NULL, false, '87898668807');
INSERT INTO Processo_Judicial
VALUES ('7ffccbf6-0d54-49d3-ac7b-e1a60fc96770', '2016-10-23',
        '2020-9-14', false, '81989843735');
INSERT INTO Processo_Judicial
VALUES ('f358ae7c-5e87-4631-a533-3302b7fe17ec', '2006-6-21',
        NULL, false, '15945927712');
INSERT INTO Processo_Judicial
VALUES ('4b5956f0-736d-4e87-95d4-ca25a9c8f01c', '2017-5-24',
        NULL, false, '84795078553');
INSERT INTO Processo_Judicial
VALUES ('02d3fc21-b58c-4b3b-b979-48b3bc4e5549', '2018-4-30',
        NULL, true, '86269439584');
INSERT INTO Processo_Judicial
VALUES ('eabafeca-3cdd-44c4-94fd-7da72afd067f', '2018-3-4',
        '2020-9-3', true, '62333358894');
INSERT INTO Processo_Judicial
VALUES ('879f75dd-8b2c-4a41-8105-54dfdf03a5e0', '2014-1-9',
        '2018-11-14', true, '10734215972');
INSERT INTO Processo_Judicial
VALUES ('4d95b33a-b17d-40be-bb7c-9d540b292203', '2008-7-27',
        '2019-7-6', true, '63185736755');
INSERT INTO Processo_Judicial
VALUES ('3cc5aacf-f104-40b5-b9ae-0b046b859d3d', '2009-12-19',
        '2020-4-4', true, '15426200556');
INSERT INTO Processo_Judicial
VALUES ('8ba27ef7-96db-4646-92f8-fae55c934be3', '2005-10-11',
        '2021-10-13', false, '42681556036');
INSERT INTO Processo_Judicial
VALUES ('8350e32b-1c83-4ae9-9a3a-8837a35c4ddd', '2010-9-15',
        NULL, false, '42436610548');
INSERT INTO Processo_Judicial
VALUES ('7ff3c02c-1707-4b89-ae2f-4b2dac04115d', '2009-8-17',
        '2018-5-8', true, '33628560900');
INSERT INTO Processo_Judicial
VALUES ('cdb572fe-b48e-4248-8801-cc9b1d8393d7', '2012-12-9',
        NULL, true, '32882520346');
INSERT INTO Processo_Judicial
VALUES ('aa07c4f5-4bbb-4c0a-85a9-5fa7180bf2ae', '2007-8-3',
        NULL, true, '21997365166');
INSERT INTO Processo_Judicial
VALUES ('7d715e78-be31-4d6f-847d-464861200a7e', '2017-12-31',
        '2018-2-12', false, '46404720542');
INSERT INTO Processo_Judicial
VALUES ('8857b06d-7663-4950-aa16-19836a32bdac', '2016-4-23',
        '2020-9-22', false, '13378266729');
INSERT INTO Processo_Judicial
VALUES ('6875140e-8fdf-466f-97ed-18f77887fc56', '2019-10-3',
        NULL, true, '86912200003');
INSERT INTO Processo_Judicial
VALUES ('b865472d-9655-473f-b0fb-ea0468bcd4de', '2018-9-12',
        '2018-4-27', true, '37029771979');
INSERT INTO Processo_Judicial
VALUES ('814f7a15-27e1-42c5-9e98-2b5e112b0392', '2007-8-5',
        '2020-9-18', false, '78620078519');
INSERT INTO Processo_Judicial
VALUES ('ffb10833-a4b9-43cd-b766-22574535faf1', '2015-8-22',
        NULL, false, '49827746006');
INSERT INTO Processo_Judicial
VALUES ('d87cb032-f60a-44a3-80d5-9a6a1aa15591', '2012-7-2',
        '2020-4-12', true, '42809196475');
INSERT INTO Processo_Judicial
VALUES ('7bfaf3d2-d6dc-4548-a2fe-c70b971fa386', '2009-12-19',
        '2018-10-5', true, '24966657152');
INSERT INTO Processo_Judicial
VALUES ('a1bd4cde-e922-43be-bc69-d20d78cf0409', '2003-5-14',
        NULL, true, '86202337315');
INSERT INTO Processo_Judicial
VALUES ('0ce9a7b4-71ee-49f4-b1a9-73c4f4586a44', '2011-6-20',
        '2019-8-3', false, '79710021100');
INSERT INTO Processo_Judicial
VALUES ('3bee3d7d-72c7-4161-b62f-70cd940250a0', '2014-3-25',
        NULL, false, '23578601770');
INSERT INTO Processo_Judicial
VALUES ('5e9d32a1-76c8-48f9-837e-13c4b297d6fc', '2013-5-27',
        NULL, false, '86721126118');
INSERT INTO Processo_Judicial
VALUES ('2136849b-4e17-4c24-8464-8cd57a8f8499', '2015-3-8',
        NULL, true, '82694570559');
INSERT INTO Processo_Judicial
VALUES ('60e7d2ee-edee-4b7a-a547-a6caadc8fccf', '2019-4-4',
        '2019-2-22', false, '46141128463');
INSERT INTO Processo_Judicial
VALUES ('b5e27306-801e-41f1-8a0f-93119fdc159a', '2004-3-3',
        NULL, true, '26968071500');
INSERT INTO Processo_Judicial
VALUES ('98be3327-d49f-40ec-a5af-b7cabfebf024', '2014-12-17',
        '2020-2-26', true, '73565084710');
INSERT INTO Processo_Judicial
VALUES ('271ad752-cc6e-4963-9ed6-f28e0efca181', '2018-7-9',
        NULL, false, '32021542380');
INSERT INTO Processo_Judicial
VALUES ('bbc11b8e-8aa7-4d4a-b227-2b67ad7a5120', '2016-4-11',
        '2021-1-10', false, '93187630493');
INSERT INTO Processo_Judicial
VALUES ('c61972fc-d206-4281-90f8-364989922669', '2009-9-9',
        '2021-5-3', false, '38096104059');
INSERT INTO Processo_Judicial
VALUES ('ab510b7d-1be1-4920-9750-9f5eca43297b', '2011-10-18',
        '2020-9-20', true, '63150459881');
INSERT INTO Processo_Judicial
VALUES ('260e2ce2-0d48-4d7a-be4a-3e69a94da49a', '2021-6-22',
        '2019-9-25', false, '26610598333');
INSERT INTO Processo_Judicial
VALUES ('6c5ca717-dd17-4c56-a7e5-56271d882527', '2013-2-10',
        NULL, false, '42809196475');
INSERT INTO Processo_Judicial
VALUES ('acad63c0-8d77-4693-9a7d-59b51f50e3cf', '2003-1-4',
        NULL, true, '27393568651');
INSERT INTO Processo_Judicial
VALUES ('c583dc75-54af-49d4-a8e5-3e655e664b5b', '2008-6-9',
        '2021-4-4', false, '64004827691');
INSERT INTO Processo_Judicial
VALUES ('24c5f6a5-c896-4093-b374-20beb44164ee', '2011-4-19',
        NULL, true, '27274558073');
INSERT INTO Processo_Judicial
VALUES ('91a80fa2-98e5-4d43-a01b-d467dcd89dc6', '2005-8-9',
        '2021-5-9', true, '29731390641');
INSERT INTO Processo_Judicial
VALUES ('77e94752-ce05-4958-a4cf-c84963cdedea', '2021-2-6',
        NULL, true, '34317429289');
INSERT INTO Processo_Judicial
VALUES ('b0bb34cd-acc1-42c9-98e0-024f171949d6', '2018-6-21',
        '2017-9-5', true, '16519870674');
INSERT INTO Processo_Judicial
VALUES ('9c06b408-1761-4721-898b-d40a6281710c', '2015-1-25',
        '2021-10-24', true, '42436610548');
INSERT INTO Processo_Judicial
VALUES ('a3834adc-802c-4c6c-bdb5-3718e56b5706', '2007-5-22',
        '2020-2-28', true, '49630068878');
INSERT INTO Processo_Judicial
VALUES ('0b2c9041-98b5-4096-9868-4a1a6d439440', '2011-9-26',
        NULL, false, '71321501170');
INSERT INTO Processo_Judicial
VALUES ('b2e37fd3-629c-4303-ab5c-4e8629e003b1', '2015-7-23',
        '2020-10-18', false, '37324441201');
INSERT INTO Processo_Judicial
VALUES ('b3f37034-63e9-4766-8552-c2c4648967d5', '2007-7-21',
        NULL, false, '52849328536');
INSERT INTO Processo_Judicial
VALUES ('fc291e12-3b39-4231-8c87-2f13eae5b9f0', '2019-11-18',
        '2020-11-19', true, '75472573232');
INSERT INTO Processo_Judicial
VALUES ('acafe7e9-9edd-4e62-a27c-fd5936f2cbb5', '2020-12-5',
        NULL, false, '44480531623');
INSERT INTO Processo_Judicial
VALUES ('e39f59ff-5381-436b-b2ea-0cbd5e04d119', '2017-11-18',
        '2018-5-15', false, '49372404732');
INSERT INTO Processo_Judicial
VALUES ('de9cd461-71c0-4030-b17f-4718ffd61e9d', '2002-8-26',
        NULL, true, '54887827818');
INSERT INTO Processo_Judicial
VALUES ('dce3edce-5634-4d85-8905-65e13c66ee05', '2016-5-28',
        '2019-10-10', true, '69263624604');
INSERT INTO Processo_Judicial
VALUES ('45299907-df7d-42a4-a0ac-d6e29c0a3364', '2002-5-4',
        '2021-7-5', false, '62644287729');
INSERT INTO Processo_Judicial
VALUES ('daad502f-dc24-4b19-b8ec-19aa027b96a0', '2002-8-2',
        '2020-4-4', true, '68443179363');
INSERT INTO Processo_Judicial
VALUES ('7b855ffa-b71c-43ea-849d-d41837e8fd90', '2017-12-20',
        NULL, false, '28005878622');
INSERT INTO Processo_Judicial
VALUES ('2db3c175-edef-4a24-8b4f-7d921c39bd62', '2021-3-8',
        '2018-1-4', true, '70566484834');
INSERT INTO Processo_Judicial
VALUES ('27a0940a-ac88-424a-9071-1ac1e334a8f5', '2019-1-11',
        '2018-4-3', false, '89959186364');
INSERT INTO Processo_Judicial
VALUES ('71bda972-ee2f-4c1d-96c6-e49679a22e3f', '2011-3-23',
        NULL, true, '88774482219');
INSERT INTO Processo_Judicial
VALUES ('5e08c981-8050-48d8-b9d3-437307c5578a', '2004-4-30',
        NULL, false, '43850494597');
INSERT INTO Processo_Judicial
VALUES ('453714b3-ecdf-4fa3-b07e-e0897acc9ae0', '2018-12-3',
        NULL, false, '30614520721');
INSERT INTO Processo_Judicial
VALUES ('873d90b9-37e1-4184-92d5-8ebbd626a90f', '2008-2-19',
        '2019-8-20', false, '32085399280');
INSERT INTO Processo_Judicial
VALUES ('eefa48f3-660b-415a-87ed-025e47c28cb4', '2017-4-8',
        NULL, false, '76603942574');
INSERT INTO Processo_Judicial
VALUES ('c66c7d3f-e473-4038-a639-51ebada31993', '2002-8-19',
        NULL, false, '56577562082');
INSERT INTO Processo_Judicial
VALUES ('983bbfd8-2361-4538-9005-d0270df76708', '2007-4-7',
        '2019-1-21', false, '65095990132');
INSERT INTO Processo_Judicial
VALUES ('47d037c3-b479-432b-aed6-e07c9987a683', '2009-4-8',
        NULL, false, '45732964542');
INSERT INTO Processo_Judicial
VALUES ('07e77619-e7f8-4e0c-b0f5-9a14f8ee32ce', '2008-9-23',
        '2017-1-12', true, '69911227060');
INSERT INTO Processo_Judicial
VALUES ('920b8bfc-6ccf-49de-81fc-d5f268005822', '2021-4-10',
        '2018-7-2', false, '70566484834');
INSERT INTO Processo_Judicial
VALUES ('8d0fac78-4825-4c22-9a71-04f7c3470220', '2009-11-1',
        '2020-7-2', false, '88644450863');
INSERT INTO Processo_Judicial
VALUES ('a75be469-f49b-400b-9e90-3cc9d9aa05ad', '2012-12-17',
        '2020-4-15', false, '24746668823');
INSERT INTO Processo_Judicial
VALUES ('2b706e7d-ff39-4696-bc3d-281dabfb9e8e', '2020-3-30',
        '2019-2-21', false, '18437136497');
INSERT INTO Processo_Judicial
VALUES ('28493bed-e2a0-4778-abe0-13af4d74e6e3', '2019-5-24',
        NULL, true, '42220121475');
INSERT INTO Processo_Judicial
VALUES ('ea426b21-8842-4926-a392-b634c9b2760d', '2013-1-15',
        '2020-6-22', false, '85421043294');
INSERT INTO Processo_Judicial
VALUES ('efa9030e-e451-47f2-a069-25e806fd434a', '2014-6-27',
        '2019-10-19', false, '21158760678');
INSERT INTO Processo_Judicial
VALUES ('40516bf5-95db-4426-906f-e634fc946954', '2017-12-3',
        NULL, true, '29951727385');
INSERT INTO Processo_Judicial
VALUES ('676d3b82-f143-4718-98bd-4793204fb80b', '2017-2-15',
        NULL, true, '31901904270');
INSERT INTO Processo_Judicial
VALUES ('3757678d-5e20-4c47-a4f1-223a21816fb0', '2005-1-18',
        NULL, true, '67696900554');
INSERT INTO Processo_Judicial
VALUES ('18120bbc-0f40-43cd-8190-e06bdc52a618', '2017-11-4',
        '2018-3-17', true, '82877426827');
INSERT INTO Processo_Judicial
VALUES ('30137beb-bc86-40f1-8bb9-5c100656ea9a', '2004-12-1',
        '2018-4-16', true, '44860848870');
INSERT INTO Processo_Judicial
VALUES ('a4f27ff8-fe74-4166-b1da-5d0633ae9881', '2011-7-14',
        NULL, true, '48903583744');
INSERT INTO Processo_Judicial
VALUES ('ac994189-1574-424e-9437-339f5b57b5bd', '2006-6-10',
        NULL, false, '26663710535');
INSERT INTO Processo_Judicial
VALUES ('60cda6f9-bfd9-4fa8-b52c-1db6eecff9dc', '2012-3-18',
        NULL, true, '61250933664');
INSERT INTO Processo_Judicial
VALUES ('788b485c-f479-4407-b043-215c0a94afbb', '2010-8-16',
        '2021-1-23', true, '29555345340');
INSERT INTO Processo_Judicial
VALUES ('d221452f-84fd-487c-bc60-083ada7b9238', '2020-12-8',
        NULL, false, '44515146410');
INSERT INTO Processo_Judicial
VALUES ('81b66433-a36e-488e-b4b9-91d310088d2b', '2013-7-3',
        '2017-7-31', false, '70941680760');
INSERT INTO Processo_Judicial
VALUES ('a8ee57af-305b-4d30-b982-da33886ccd1c', '2011-7-10',
        '2019-12-28', false, '68579267167');
INSERT INTO Processo_Judicial
VALUES ('61872440-a29f-4e1c-9962-a763d0c2b850', '2004-10-19',
        '2021-9-23', false, '29479615306');
INSERT INTO Processo_Judicial
VALUES ('61b83554-04e0-4efe-a533-545c937bc00b', '2018-11-3',
        '2018-3-6', true, '37652357325');
INSERT INTO Processo_Judicial
VALUES ('e35376f1-c7a8-42fb-9a71-b32b93b5870e', '2013-6-24',
        NULL, false, '34798725692');
INSERT INTO Processo_Judicial
VALUES ('a045d5de-dbb6-47ed-bab5-61be1153bf75', '2021-4-3',
        '2020-9-14', false, '15525305538');
INSERT INTO Processo_Judicial
VALUES ('d9ca28c2-d9d9-41fd-83bc-d85d6c872a3c', '2011-5-19',
        '2017-8-29', false, '92975085964');
INSERT INTO Processo_Judicial
VALUES ('7cc30142-c917-4675-a70d-3c8e9cdf7626', '2006-5-5',
        NULL, true, '58935807752');
INSERT INTO Processo_Judicial
VALUES ('6486889d-90fd-498d-bda7-85350b4099a1', '2019-5-30',
        NULL, false, '27572791909');
INSERT INTO Processo_Judicial
VALUES ('60437550-270f-4b4a-a362-190d42b8262b', '2013-1-18',
        NULL, true, '33628560900');
INSERT INTO Processo_Judicial
VALUES ('470a36c0-8f46-424a-bcbc-89a672f66a2d', '2021-2-4',
        NULL, false, '99175420803');
INSERT INTO Processo_Judicial
VALUES ('8c2ef0a4-818a-4075-bfab-f8a972d38fa0', '2017-10-24',
        '2017-3-20', false, '57456171549');
INSERT INTO Processo_Judicial
VALUES ('0be255ec-afd5-4f5b-96c4-6362f4294cf2', '2008-11-30',
        '2018-10-10', true, '68110109437');
INSERT INTO Processo_Judicial
VALUES ('950e54d4-0c48-47f8-b11e-2a9eb80ccf07', '2008-1-6',
        NULL, false, '90374537745');
INSERT INTO Processo_Judicial
VALUES ('c74be384-3f24-4c76-908f-f9374f5cae5f', '2009-9-15',
        '2020-4-2', false, '64122301510');
INSERT INTO Processo_Judicial
VALUES ('b739d0e7-0771-40e2-9b31-68da80826332', '2009-1-14',
        '2018-2-24', false, '80961511202');
INSERT INTO Processo_Judicial
VALUES ('17b15487-9cbb-400b-9ee7-dfe2bf2bd19f', '2010-11-8',
        '2020-12-29', true, '14297463551');
INSERT INTO Processo_Judicial
VALUES ('5369b815-8175-4a0e-abe1-864f08d760d8', '2009-12-4',
        NULL, false, '24567704398');
INSERT INTO Processo_Judicial
VALUES ('3f6ec528-b7ca-4e67-ab1e-786362824095', '2007-12-26',
        NULL, true, '36764807719');
INSERT INTO Processo_Judicial
VALUES ('038640e7-7ee3-4bab-ab80-745d5b8b03b1', '2002-9-21',
        NULL, true, '23413005832');
INSERT INTO Processo_Judicial
VALUES ('ec9e09d8-d7b5-4d01-9a94-b99e80c42696', '2008-10-15',
        '2017-11-3', true, '79418088067');
INSERT INTO Processo_Judicial
VALUES ('e0a0ab13-9973-4f64-b521-11da7603da14', '2007-10-23',
        '2020-7-15', false, '62047257632');
INSERT INTO Processo_Judicial
VALUES ('fdada6dc-d6e3-485c-8a83-8880fcfbc47d', '2005-5-4',
        NULL, true, '89233355857');
INSERT INTO Processo_Judicial
VALUES ('7398209c-8b05-4c94-9421-27f1043314f3', '2005-5-21',
        NULL, false, '61750890677');
INSERT INTO Processo_Judicial
VALUES ('43c851fe-8e99-4d92-9386-94282350458a', '2002-8-26',
        NULL, true, '71791716990');
INSERT INTO Processo_Judicial
VALUES ('1a133134-abba-4a97-81e2-01627229b3dc', '2009-5-23',
        NULL, false, '44908207063');
INSERT INTO Processo_Judicial
VALUES ('e6215727-a0a7-41c1-9ef1-b6fd2b0bc506', '2001-12-17',
        '2019-9-20', true, '24890993377');
INSERT INTO Processo_Judicial
VALUES ('c1a60989-be65-4b22-82dd-d373cc9ea128', '2009-8-8',
        '2017-8-25', true, '73277497400');
INSERT INTO Processo_Judicial
VALUES ('4ddd5199-6d8d-4e40-bb34-3e0d45ae3320', '2013-4-2',
        NULL, true, '53326698206');
INSERT INTO Processo_Judicial
VALUES ('9f6ad791-feec-49e0-8257-9a45d49c0be6', '2002-5-20',
        NULL, false, '43068155143');
INSERT INTO Processo_Judicial
VALUES ('c799992b-95d9-4f7a-9de5-5928c9d00faf', '2010-10-16',
        NULL, false, '54988852173');
INSERT INTO Processo_Judicial
VALUES ('0d4b354e-5439-433b-8701-b2c2c61457db', '2007-3-1',
        '2017-5-17', false, '74766249782');
INSERT INTO Processo_Judicial
VALUES ('3e8c05aa-241d-4c44-942e-67faf9bd186a', '2004-9-14',
        NULL, false, '90085991316');
INSERT INTO Processo_Judicial
VALUES ('1b5c5a96-52d8-4b3b-89b8-843d9c82742e', '2018-12-28',
        '2021-9-28', true, '86761833312');
INSERT INTO Processo_Judicial
VALUES ('2aae11ac-4808-4832-ac32-c7b217124557', '2002-6-24',
        '2017-3-10', false, '10297100099');
INSERT INTO Processo_Judicial
VALUES ('46a106c9-a9fb-4234-995c-532c0eb46e69', '2011-3-15',
        '2017-12-29', true, '94086229731');
INSERT INTO Processo_Judicial
VALUES ('30aae50c-dee2-4715-a174-2b2d04a4758f', '2020-11-11',
        '2020-11-16', false, '20454070107');
INSERT INTO Processo_Judicial
VALUES ('42cf59a4-d8ba-4787-8200-1edbf9f372dd', '2007-8-31',
        '2019-4-28', true, '22420991435');
INSERT INTO Processo_Judicial
VALUES ('0f87534f-2dc9-4f56-8045-357fb7341455', '2010-7-15',
        NULL, false, '27781179496');
INSERT INTO Processo_Judicial
VALUES ('7252e9ea-705f-4e5c-9c75-41bdb1de054c', '2002-6-23',
        NULL, false, '96993769449');
INSERT INTO Processo_Judicial
VALUES ('6d7983b0-f156-4fcd-8d6e-690f3931a96c', '2017-5-8',
        NULL, false, '39643863362');
INSERT INTO Processo_Judicial
VALUES ('0995092e-721b-4184-8271-bfd78e9cb6d2', '2017-10-11',
        '2020-2-28', false, '84909864924');
INSERT INTO Processo_Judicial
VALUES ('df61f28a-58d9-4c00-95bb-4f36cc60f174', '2014-7-9',
        '2020-2-24', true, '98058124845');
INSERT INTO Processo_Judicial
VALUES ('75e3325f-f260-4c9a-9ee8-98e6b09a6c48', '2016-12-8',
        NULL, true, '65505142740');
INSERT INTO Processo_Judicial
VALUES ('31cc81f5-8c80-4dc5-b12b-d398008dbedd', '2016-12-7',
        '2021-10-17', false, '21997365166');
INSERT INTO Processo_Judicial
VALUES ('10ce545f-41e4-4c57-b233-968f4b1d41d5', '2016-7-30',
        '2021-4-24', true, '72005313155');
INSERT INTO Processo_Judicial
VALUES ('bd57ec31-8723-462d-afe3-a7881dbf6d55', '2006-8-27',
        NULL, false, '73786580944');
INSERT INTO Processo_Judicial
VALUES ('29b87fb9-342b-4b42-8c52-1c7571ff7c27', '2006-11-10',
        '2018-12-30', true, '59180864153');
INSERT INTO Processo_Judicial
VALUES ('55e0ae05-e0aa-455c-a671-3a002d0622ec', '2019-2-13',
        '2018-8-15', false, '16354246530');
INSERT INTO Processo_Judicial
VALUES ('a86969e8-96d0-48e9-993e-2fec64189d4e', '2002-4-23',
        NULL, true, '52791193877');
INSERT INTO Processo_Judicial
VALUES ('c5912371-f87c-4929-9461-c71091bbb463', '2019-7-22',
        NULL, false, '64118797685');
INSERT INTO Processo_Judicial
VALUES ('ef386e2f-23b2-4115-b401-19135a3533c0', '2012-6-4',
        NULL, true, '29610695552');
INSERT INTO Processo_Judicial
VALUES ('2e9b8aba-d3cf-4c0a-8e20-d29ebc407213', '2018-9-17',
        NULL, true, '47806147113');
INSERT INTO Processo_Judicial
VALUES ('12ddc001-ceac-4bd6-bb74-697184e4b26c', '2017-10-1',
        NULL, true, '31269832097');
INSERT INTO Processo_Judicial
VALUES ('be9ae9e2-7374-4a4d-aa9f-ea87be6311a8', '2006-3-20',
        NULL, true, '87898668807');
INSERT INTO Processo_Judicial
VALUES ('64535e1c-ad82-460e-93a0-47d1ac9c476c', '2006-10-24',
        NULL, false, '59657050718');
INSERT INTO Processo_Judicial
VALUES ('e3cacbed-cdd3-46c4-9b04-9c2332fbcf55', '2017-7-20',
        '2018-11-19', false, '28583832178');
INSERT INTO Processo_Judicial
VALUES ('d25df0cf-8a6a-4b32-87a5-093b01302177', '2011-5-12',
        NULL, true, '83326663854');
INSERT INTO Processo_Judicial
VALUES ('235ec266-2c72-427d-a65c-34a32d867967', '2008-11-25',
        '2020-9-6', false, '32333718526');
INSERT INTO Processo_Judicial
VALUES ('f92b0cf2-f759-485e-8fe3-625109f524fe', '2019-6-7',
        NULL, true, '66261561494');
INSERT INTO Processo_Judicial
VALUES ('9c349f4a-6c31-47d6-8cc8-00a26aa1a018', '2017-6-17',
        '2019-6-13', true, '61664271336');
INSERT INTO Processo_Judicial
VALUES ('6531af0a-631d-44ba-9fce-04c9009be68e', '2017-10-9',
        '2018-11-7', false, '26153816252');
INSERT INTO Processo_Judicial
VALUES ('bf2f2782-3ab9-4795-bb02-4eda6f66fef6', '2018-1-13',
        '2020-7-22', true, '85103842427');
INSERT INTO Processo_Judicial
VALUES ('7ddb26f4-22de-486f-90f0-da8e68e18219', '2020-7-13',
        '2017-10-25', false, '96735474125');
INSERT INTO Processo_Judicial
VALUES ('a1e2c629-afd0-4082-aac9-749b78506aec', '2021-7-4',
        '2020-11-22', true, '86313275324');
INSERT INTO Processo_Judicial
VALUES ('9e4a75a5-240e-454e-93db-1d467d1e53df', '2002-8-14',
        NULL, true, '77440287217');
INSERT INTO Processo_Judicial
VALUES ('893fadbb-1cdd-423b-bab3-12a64618f0d7', '2006-6-21',
        '2020-3-23', true, '27514509037');
INSERT INTO Processo_Judicial
VALUES ('15cfda6c-e700-4758-9879-3d57aba93015', '2016-8-13',
        NULL, false, '69868170775');
INSERT INTO Processo_Judicial
VALUES ('ca62e1c5-38a3-455a-b7d7-4b2c0ccbcdf6', '2021-9-25',
        NULL, false, '93363777676');
INSERT INTO Processo_Judicial
VALUES ('2b2e1068-d1fc-47e8-8be3-25301662670c', '2019-2-27',
        NULL, false, '47835368167');
INSERT INTO Processo_Judicial
VALUES ('23486d4c-142a-4df0-ae96-69858cb96cac', '2004-9-22',
        '2020-10-2', false, '46842239857');
INSERT INTO Processo_Judicial
VALUES ('d88dab57-39c2-4f83-8587-d5849b5084db', '2015-5-11',
        '2020-8-18', true, '14423142687');
INSERT INTO Processo_Judicial
VALUES ('6cf7ba98-25b2-4352-b0d0-bb0be70515d2', '2002-8-2',
        NULL, false, '35535540033');
INSERT INTO Processo_Judicial
VALUES ('5711518e-db97-4759-a90b-92b8a8abc50c', '2002-4-20',
        '2019-5-18', true, '64312151931');
INSERT INTO Processo_Judicial
VALUES ('4b0de873-702a-4fb7-9844-4b7c6a2c662b', '2016-11-16',
        NULL, false, '54887827818');
INSERT INTO Processo_Judicial
VALUES ('169877b9-f9be-4071-86ca-07e22476f30f', '2016-12-17',
        NULL, true, '78014859156');
INSERT INTO Processo_Judicial
VALUES ('8ba2369a-9e50-4355-86ad-2a60b3decbcf', '2005-6-26',
        '2019-1-30', false, '71007887653');
INSERT INTO Processo_Judicial
VALUES ('80dc2806-6a98-4ce6-ae06-6521d42cc017', '2020-11-26',
        NULL, true, '96993769449');
INSERT INTO Processo_Judicial
VALUES ('f6c9bc01-0c66-4625-84e8-3e246be3269d', '2009-6-18',
        NULL, true, '77020872854');
INSERT INTO Processo_Judicial
VALUES ('4529a9e6-6d3e-488e-b2b9-df1b3c4adea8', '2015-8-27',
        '2018-2-24', false, '74298426869');
INSERT INTO Processo_Judicial
VALUES ('1419df0f-046b-4251-9c0e-e733c4e4e321', '2002-9-8',
        '2018-2-3', true, '66122044045');
INSERT INTO Processo_Judicial
VALUES ('5c6d1239-49ef-4185-989d-a56b0f62fb4f', '2004-12-29',
        '2020-1-16', true, '16716102720');
INSERT INTO Processo_Judicial
VALUES ('0096cd56-d000-473c-a435-33f8768ee30c', '2002-2-2',
        '2018-12-7', false, '30063241985');
INSERT INTO Processo_Judicial
VALUES ('224c2648-e57b-4300-8209-947db6655082', '2020-9-28',
        '2021-8-16', false, '44242360976');
INSERT INTO Processo_Judicial
VALUES ('9d5e189f-86be-4766-9096-311ed802f8af', '2008-3-29',
        NULL, true, '47524044020');
INSERT INTO Processo_Judicial
VALUES ('eb59878b-286b-4839-bf52-20ad0f791758', '2009-1-6',
        '2019-9-15', false, '48150026823');
INSERT INTO Processo_Judicial
VALUES ('03bd3dcf-bb5d-4253-8a8c-096b24687247', '2009-5-5',
        '2019-6-6', true, '32021542380');
INSERT INTO Processo_Judicial
VALUES ('3201d1a1-4cc8-445a-b28c-9f17f4134423', '2007-3-6',
        '2019-3-13', true, '27042364289');
INSERT INTO Processo_Judicial
VALUES ('f8eeec8b-5ff6-4550-b655-7c71be219d94', '2009-9-12',
        '2019-10-15', false, '16893356314');
INSERT INTO Processo_Judicial
VALUES ('00aebc25-6c52-4f3a-a87e-be5b287a8f09', '2016-9-30',
        NULL, false, '34712144928');
INSERT INTO Processo_Judicial
VALUES ('c0275b3a-f814-4b8c-a711-fdb39775a3b8', '2019-1-15',
        '2019-5-10', false, '86344928094');
INSERT INTO Processo_Judicial
VALUES ('8e93cfbd-b351-4453-a6f7-8f38717f4b2e', '2007-3-22',
        '2019-1-12', false, '34712144928');
INSERT INTO Processo_Judicial
VALUES ('d649dd46-067b-4454-8683-7907788ee5b6', '2013-4-9',
        '2020-6-4', false, '81158944626');
INSERT INTO Processo_Judicial
VALUES ('0fe0d97a-1a92-4c96-8ff6-0c4b4cedeb19', '2019-5-25',
        NULL, false, '48903583744');
INSERT INTO Processo_Judicial
VALUES ('70f7441c-c64c-484c-883d-38655d5ccc17', '2004-7-9',
        '2021-7-19', true, '97341636095');
INSERT INTO Processo_Judicial
VALUES ('2642da2e-6a4c-4e04-b5b5-d0febf42402f', '2015-7-29',
        '2021-11-12', true, '65095990132');
INSERT INTO Processo_Judicial
VALUES ('2976a2c4-329a-4616-922a-77dda58c39e4', '2017-2-7',
        '2016-12-8', false, '33251189284');
INSERT INTO Processo_Judicial
VALUES ('a7faeb46-e385-4268-a807-d722bf05b24a', '2011-9-28',
        '2021-2-16', false, '35807526966');
INSERT INTO Processo_Judicial
VALUES ('22d5759b-6156-4f96-b498-0c875de96e09', '2003-5-10',
        NULL, true, '94970913690');
INSERT INTO Processo_Judicial
VALUES ('ca110db6-2b52-4cdd-a1be-001d36be932d', '2017-6-2',
        NULL, true, '32050464514');
INSERT INTO Processo_Judicial
VALUES ('33cc8909-f56c-496c-841c-e942f376c483', '2019-1-5',
        NULL, true, '56604801905');
INSERT INTO Processo_Judicial
VALUES ('8be1ce57-90e2-462e-bd2d-f1410fae173f', '2019-1-25',
        NULL, true, '86271196368');
INSERT INTO Processo_Judicial
VALUES ('e6b7262c-f6e4-49c1-8dcf-107ce9f9288f', '2011-8-20',
        '2017-11-7', false, '49993791026');
INSERT INTO Processo_Judicial
VALUES ('8fb74df8-f969-4a03-905e-1f42828d5a4c', '2009-5-23',
        NULL, true, '82961410374');
INSERT INTO Processo_Judicial
VALUES ('315775a8-63ae-4766-82be-911a42a4856e', '2012-1-22',
        NULL, false, '72847558700');
INSERT INTO Processo_Judicial
VALUES ('369261c1-04be-4381-aea5-06be38e05a9a', '2014-2-27',
        '2018-5-3', false, '27393568651');
INSERT INTO Processo_Judicial
VALUES ('16b221bd-1f96-4c6e-9188-aa5d106ee6a9', '2005-1-31',
        '2021-6-30', false, '67352445363');
INSERT INTO Processo_Judicial
VALUES ('8545d4d2-41da-408b-b388-cef869976719', '2013-3-3',
        '2020-1-6', true, '77949062872');
INSERT INTO Processo_Judicial
VALUES ('30334716-8aeb-42a4-a8d0-44c5315b0e2f', '2009-3-11',
        NULL, true, '16716102720');
INSERT INTO Processo_Judicial
VALUES ('e81aef59-778c-4014-8745-47f94dfabc1a', '2011-8-2',
        NULL, false, '79631428855');
INSERT INTO Processo_Judicial
VALUES ('ca6fea32-be4f-40bd-b4db-c447b9367a39', '2019-12-10',
        '2018-10-6', false, '20341535366');
INSERT INTO Processo_Judicial
VALUES ('ced9836a-8986-413e-8e7a-3b53fd5bfe89', '2020-2-27',
        '2017-12-7', false, '44197359627');
INSERT INTO Processo_Judicial
VALUES ('ab4becef-c5c8-4f7f-995e-7b7b1ca4d962', '2009-7-19',
        '2018-3-16', false, '17000984330');
INSERT INTO Processo_Judicial
VALUES ('69ea3f83-798d-4b4f-b64c-46cb620abefa', '2017-7-22',
        NULL, false, '16519870674');
INSERT INTO Processo_Judicial
VALUES ('e4c531b2-83ec-477b-a6ac-8469515b6ab7', '2006-2-10',
        '2020-7-5', false, '77598187436');
INSERT INTO Processo_Judicial
VALUES ('07b3c03c-685e-426d-ac83-f6d63e84cec3', '2004-12-11',
        '2016-12-12', false, '52924657328');
INSERT INTO Processo_Judicial
VALUES ('31864e09-a450-4aa4-b420-d5856c394b7e', '2009-7-24',
        '2018-11-3', true, '42809196475');
INSERT INTO Processo_Judicial
VALUES ('8b73d61f-8e68-4497-8af7-02c1ffcb905e', '2004-9-8',
        NULL, true, '56464298493');
INSERT INTO Processo_Judicial
VALUES ('78ea6c1c-337e-4eaf-9fa3-60627615a7e7', '2018-4-26',
        '2017-5-10', true, '52037642614');
INSERT INTO Processo_Judicial
VALUES ('015f3284-164d-48c4-829b-bc4976117522', '2004-4-15',
        '2016-12-11', true, '76313567715');
INSERT INTO Processo_Judicial
VALUES ('ff68a966-f3d6-40ff-8095-92e94a3def80', '2020-1-14',
        '2020-7-14', true, '46631380887');
INSERT INTO Processo_Judicial
VALUES ('d3e9c70a-43a8-43c3-ad21-75ccb3baaca1', '2013-11-11',
        '2020-5-31', true, '13249461750');
INSERT INTO Processo_Judicial
VALUES ('05cc732b-704d-49c9-bd05-3279e85c1558', '2015-1-9',
        '2018-9-28', false, '25947751102');
INSERT INTO Processo_Judicial
VALUES ('950f34b5-f6ce-4822-93c8-ee8f34c5bc5c', '2010-11-12',
        NULL, true, '12393648503');
INSERT INTO Processo_Judicial
VALUES ('82befe26-3d17-4949-9e8c-ed0723d7e6a4', '2005-2-11',
        '2020-7-28', false, '32021542380');
INSERT INTO Processo_Judicial
VALUES ('83d8aecd-fdeb-4244-b52e-6b75653063cb', '2013-10-31',
        NULL, true, '62654740172');
INSERT INTO Processo_Judicial
VALUES ('70a71886-affc-41bb-9d02-6bff4077a7d9', '2003-10-12',
        '2020-12-27', true, '53966798104');
INSERT INTO Processo_Judicial
VALUES ('fa1cc714-cfc8-4f1c-a5fe-9ab03f860586', '2014-10-31',
        NULL, false, '48260050807');
INSERT INTO Processo_Judicial
VALUES ('bff4350d-0508-41c6-af14-ceba13e9bcf4', '2001-12-8',
        NULL, true, '64118797685');
INSERT INTO Processo_Judicial
VALUES ('5a9211dc-064f-4a59-b035-7a531896130e', '2013-7-13',
        '2019-5-2', false, '83635655883');
INSERT INTO Processo_Judicial
VALUES ('f1b88b29-132b-4498-acb2-4a89b63b100f', '2004-6-12',
        NULL, true, '46218319148');
INSERT INTO Processo_Judicial
VALUES ('c8ae9221-b621-44b7-b2b0-a8c4c943118a', '2020-8-2',
        NULL, false, '33739217927');
INSERT INTO Processo_Judicial
VALUES ('b6be8b07-b755-4a85-a9d6-3c3042bf2ed5', '2012-3-28',
        '2020-8-25', true, '35013815364');
INSERT INTO Processo_Judicial
VALUES ('c28b3649-5949-4cf7-b379-652075a1bc48', '2020-1-20',
        '2019-11-21', false, '24243827324');
INSERT INTO Processo_Judicial
VALUES ('b71ec9d1-de2b-41a5-931d-7041d8fa1dc6', '2011-6-18',
        NULL, false, '46974461216');
INSERT INTO Processo_Judicial
VALUES ('dbe98d8e-7b36-4d20-a6fd-8f266109d3f7', '2016-2-13',
        NULL, false, '72538530293');
INSERT INTO Processo_Judicial
VALUES ('840a63f6-61ef-4598-a4cf-251de1a07c3d', '2008-5-14',
        '2021-4-29', false, '70054730942');
INSERT INTO Processo_Judicial
VALUES ('ca013ba9-acb8-467a-a461-83d0ac681584', '2013-10-7',
        NULL, true, '14448990675');
INSERT INTO Processo_Judicial
VALUES ('b96bc6cc-acde-4493-8adb-c512cf924617', '2009-1-7',
        '2020-9-27', false, '35535540033');
INSERT INTO Processo_Judicial
VALUES ('b15f524b-967f-482c-b1d8-8db7e827ac17', '2018-3-12',
        NULL, false, '99021190118');
INSERT INTO Processo_Judicial
VALUES ('630bf8a3-d1a3-410d-becf-94c9a962c679', '2020-7-16',
        NULL, false, '24966657152');
INSERT INTO Processo_Judicial
VALUES ('1c70217b-bcaf-4b74-85d7-4482151d392c', '2004-8-6',
        '2018-10-22', false, '10190151415');
INSERT INTO Processo_Judicial
VALUES ('50f27c2e-1507-4088-8b00-1892413a6544', '2012-2-28',
        NULL, true, '64278458273');
INSERT INTO Processo_Judicial
VALUES ('14b1c896-e10c-4ce6-9c2d-8757cbaddd9a', '2019-8-27',
        NULL, true, '21655415012');
INSERT INTO Processo_Judicial
VALUES ('85e0a1be-64c3-4ab2-bd59-c8beb0749485', '2013-2-6',
        '2019-8-6', true, '26316574874');
INSERT INTO Processo_Judicial
VALUES ('c2bed273-bc3e-4b68-a118-367820653d08', '2005-2-2',
        NULL, true, '83225498516');
INSERT INTO Processo_Judicial
VALUES ('f0d4eb20-1804-4939-8bf3-75ff4b1aaac2', '2004-12-6',
        '2021-7-20', false, '94656017050');
INSERT INTO Processo_Judicial
VALUES ('2c8f8475-0370-4048-8987-0f243d59a62d', '2021-10-23',
        '2017-4-29', true, '13070944417');
INSERT INTO Processo_Judicial
VALUES ('792a0b27-8a33-486c-af67-1c801507d0dd', '2002-8-3',
        NULL, true, '85759488451');
INSERT INTO Processo_Judicial
VALUES ('b6499df9-b496-4d3a-add3-f97553860a97', '2017-12-8',
        NULL, false, '68663108202');
INSERT INTO Processo_Judicial
VALUES ('595b351a-4962-43d2-ac15-09f1f31aaa55', '2010-4-21',
        NULL, false, '41701333993');
INSERT INTO Processo_Judicial
VALUES ('5304b80f-fa2f-4a45-bbee-27a300b6b75c', '2004-9-11',
        NULL, false, '54175896581');
INSERT INTO Processo_Judicial
VALUES ('d64785ed-e6e7-49db-a45c-99c7a2ef6a39', '2004-6-6',
        '2020-8-1', false, '62330017092');
INSERT INTO Processo_Judicial
VALUES ('eb04ef50-8dc3-4d7d-9777-82e667f70f95', '2008-5-31',
        '2021-9-5', false, '70941680760');
INSERT INTO Processo_Judicial
VALUES ('40f2a98b-872c-42dc-87cc-037cd2c9746d', '2007-2-27',
        '2018-1-12', false, '84994391954');
INSERT INTO Processo_Judicial
VALUES ('9b096f3c-a0ee-4eee-bf07-7798eb5d7cfa', '2003-7-20',
        NULL, true, '20170554369');
INSERT INTO Processo_Judicial
VALUES ('fabf2fd2-21a1-4826-869f-95c0835c6b48', '2014-9-23',
        NULL, false, '63353046625');
INSERT INTO Processo_Judicial
VALUES ('4d87199a-1267-45ec-bf38-92ab542108f0', '2020-7-31',
        '2019-7-29', false, '41160983415');
INSERT INTO Processo_Judicial
VALUES ('719458df-3f94-4add-8aca-afbca00dcb48', '2014-8-4',
        NULL, false, '57082543941');
INSERT INTO Processo_Judicial
VALUES ('39becf27-b57e-4d0b-a26b-b97997989fbe', '2009-4-21',
        NULL, false, '56126027428');
INSERT INTO Processo_Judicial
VALUES ('edd40acb-e390-416a-87fd-26e746214e35', '2014-11-25',
        NULL, true, '98326434637');
INSERT INTO Processo_Judicial
VALUES ('927c5419-0a44-489d-8f52-d9c8a89dcd28', '2006-10-21',
        NULL, true, '79239115805');
INSERT INTO Processo_Judicial
VALUES ('a8605eff-faf7-4a03-918f-f806fea1aec0', '2020-4-30',
        NULL, true, '69316593371');
INSERT INTO Processo_Judicial
VALUES ('8f6e1ed9-ad93-4a9a-9426-c55460896b09', '2019-3-22',
        NULL, true, '14925663892');
INSERT INTO Processo_Judicial
VALUES ('677dca60-fad2-4c59-956c-a89b3f78340c', '2009-1-20',
        NULL, true, '94656017050');
INSERT INTO Processo_Judicial
VALUES ('b232cbe6-6a0b-46fe-8c29-a8bac3da3118', '2015-10-31',
        NULL, false, '75170857366');
INSERT INTO Processo_Judicial
VALUES ('40fe766a-8a36-411d-befb-081b788f40c2', '2009-9-12',
        NULL, false, '68110109437');
INSERT INTO Processo_Judicial
VALUES ('9dd0f822-1d59-41a7-9515-0a7fee57b8c0', '2011-6-22',
        '2021-9-11', false, '14172927623');
INSERT INTO Processo_Judicial
VALUES ('607639fa-764c-4e71-890b-299d31abd508', '2018-9-11',
        '2020-10-25', true, '60984027946');
INSERT INTO Processo_Judicial
VALUES ('c52b4a36-0983-4d03-b6a3-f51d2c93943c', '2013-7-29',
        NULL, true, '48903583744');
INSERT INTO Processo_Judicial
VALUES ('19d78252-a710-47fc-892d-6265d586ee6b', '2018-10-12',
        '2020-2-25', true, '29610695552');
INSERT INTO Processo_Judicial
VALUES ('03d0e177-6ea9-4f30-af05-4b112ec001bf', '2020-2-13',
        '2016-12-24', false, '87482139978');
INSERT INTO Processo_Judicial
VALUES ('c73a288b-e370-42c6-a712-29d584f0d53b', '2009-3-14',
        NULL, false, '46404720542');
INSERT INTO Processo_Judicial
VALUES ('ed572536-b2ba-4621-8a3b-f4d9e4e84606', '2006-2-18',
        '2018-1-10', false, '28029985185');
INSERT INTO Processo_Judicial
VALUES ('9227833d-d084-4bbb-9384-5a4947e734cb', '2005-8-21',
        '2018-10-5', true, '27882795822');
INSERT INTO Processo_Judicial
VALUES ('18a6a002-abe7-4da6-a52d-51177142f91f', '2015-9-23',
        '2019-8-12', false, '42436610548');
INSERT INTO Processo_Judicial
VALUES ('9ee9d2b3-6a9d-4c77-ba98-4392e630e0f8', '2002-1-20',
        '2018-7-29', false, '24799374230');
INSERT INTO Processo_Judicial
VALUES ('e3684f00-123d-4b6a-824b-6fa90fee529d', '2009-6-2',
        NULL, false, '21700934006');
INSERT INTO Processo_Judicial
VALUES ('88afa1f0-c7b1-442d-9e1c-3d73ca05f044', '2020-7-5',
        NULL, false, '15808746593');
INSERT INTO Processo_Judicial
VALUES ('8fd968c9-ae61-4328-972a-1dd62fce9657', '2013-2-5',
        '2017-10-1', true, '41542903429');
INSERT INTO Processo_Judicial
VALUES ('4f0c85f5-edfc-46dd-8740-86767efb9431', '2007-4-23',
        '2019-5-20', false, '15051016972');
INSERT INTO Processo_Judicial
VALUES ('18417df2-9191-4bde-b829-91fe73498426', '2003-3-21',
        '2019-1-29', false, '85096177156');
INSERT INTO Processo_Judicial
VALUES ('0162ab70-4397-481d-82d0-10d8175f6528', '2016-4-16',
        '2016-12-8', false, '69146417120');
INSERT INTO Processo_Judicial
VALUES ('050728b3-ab75-437a-885b-c65b6c3044aa', '2016-11-20',
        '2020-7-14', true, '83423976283');
INSERT INTO Processo_Judicial
VALUES ('508e26ba-70d3-4c1f-9fc7-ed955b4bc5d1', '2015-10-26',
        '2020-5-29', true, '84909864924');
INSERT INTO Processo_Judicial
VALUES ('6e4c29e4-8fb8-45ab-8b36-4a9adff4a26f', '2005-10-24',
        NULL, true, '83635655883');
INSERT INTO Processo_Judicial
VALUES ('2fe7637b-36e8-42c2-80b3-d2a936efb997', '2010-8-18',
        '2020-2-22', true, '10297100099');
INSERT INTO Processo_Judicial
VALUES ('f4d4b051-b94b-46f9-a9ac-566ac8faf830', '2011-7-13',
        NULL, false, '87898668807');
INSERT INTO Processo_Judicial
VALUES ('54ec20cb-d23f-413a-a986-2e6e90912eda', '2021-1-21',
        '2021-1-27', true, '17017262971');
INSERT INTO Processo_Judicial
VALUES ('e4aa6d48-4bd6-468a-8af4-43fccd84c3f2', '2009-10-13',
        '2019-9-5', false, '44197359627');
INSERT INTO Processo_Judicial
VALUES ('128395ac-f843-482c-9f29-b066f1e0f9aa', '2019-2-1',
        NULL, true, '93732622361');
INSERT INTO Processo_Judicial
VALUES ('360b5e59-c1eb-44d9-8247-8de7f13cc20a', '2016-11-18',
        '2020-1-16', true, '42681556036');
INSERT INTO Processo_Judicial
VALUES ('7b36aa4d-86c4-423f-9609-5d80f1c91264', '2005-12-1',
        NULL, false, '48286474652');
INSERT INTO Processo_Judicial
VALUES ('63e9a711-1f71-4281-8281-85faae6282cd', '2020-5-26',
        NULL, true, '11940935752');
INSERT INTO Processo_Judicial
VALUES ('aa50ff7b-da8f-48c0-86c2-d3b54cbdf524', '2002-11-28',
        NULL, true, '99474227605');
INSERT INTO Processo_Judicial
VALUES ('0897a579-9bf2-4232-983c-4f8490f573b8', '2015-11-26',
        NULL, true, '77360690359');
INSERT INTO Processo_Judicial
VALUES ('60bc43d3-76a3-4a3c-b3b3-06bc2ea60a32', '2009-10-11',
        NULL, false, '39244721408');
INSERT INTO Processo_Judicial
VALUES ('72e43594-995e-432d-8687-69791153a265', '2016-12-23',
        NULL, false, '14154119554');
INSERT INTO Processo_Judicial
VALUES ('dee96939-7905-43c5-af1f-7c557f303aca', '2010-5-3',
        '2020-6-19', false, '78521770969');
INSERT INTO Processo_Judicial
VALUES ('6e0c2ccd-f337-47fa-b803-b606b3f527d4', '2010-10-12',
        '2020-3-14', false, '34712144928');
INSERT INTO Processo_Judicial
VALUES ('b523fe2d-0b14-4874-bec6-fd95ec23ab82', '2003-12-18',
        NULL, true, '93187630493');
INSERT INTO Processo_Judicial
VALUES ('9ed1fa1c-2623-4b78-bdb8-8997d4223280', '2003-10-14',
        NULL, false, '59100339210');
INSERT INTO Processo_Judicial
VALUES ('00b8c1ae-1ba5-4fe7-9f2f-e5c30e9d024a', '2005-11-24',
        NULL, true, '84441573002');
INSERT INTO Processo_Judicial
VALUES ('64fa09d8-643a-4b5a-ac65-c62fb1a63254', '2017-10-16',
        NULL, true, '99047559711');
INSERT INTO Processo_Judicial
VALUES ('0b7db16a-079a-4cf2-a3d6-72940a7f62da', '2006-10-9',
        NULL, true, '24567704398');
INSERT INTO Processo_Judicial
VALUES ('ea18505c-2f8a-4156-bbc1-697df2e29dac', '2013-9-26',
        NULL, true, '81112522231');
INSERT INTO Processo_Judicial
VALUES ('0b84374e-e9e1-406f-b052-d2af028dc585', '2002-12-5',
        NULL, true, '16535910640');
INSERT INTO Processo_Judicial
VALUES ('a5ceab85-dc63-403a-aa72-eabfe71cd2a4', '2003-9-28',
        '2017-2-26', false, '44259705774');
INSERT INTO Processo_Judicial
VALUES ('b6891fed-0167-4921-bc64-8137ba6167a5', '2005-11-22',
        '2020-10-31', false, '11737644865');
INSERT INTO Processo_Judicial
VALUES ('d104a141-0b74-41fa-9145-c73edbebc97c', '2011-6-16',
        '2019-6-12', true, '61664271336');
INSERT INTO Processo_Judicial
VALUES ('766167bf-b64b-416f-90f5-a6cab7c72eb0', '2006-11-23',
        NULL, true, '47783979305');
INSERT INTO Processo_Judicial
VALUES ('cf3b4d99-9852-4859-bfb4-9de2674c4cd2', '2001-12-11',
        '2019-12-27', false, '42022861305');
INSERT INTO Processo_Judicial
VALUES ('8ce23351-b910-477c-9ae9-51feade6ec6d', '2012-3-5',
        NULL, true, '37662852117');
INSERT INTO Processo_Judicial
VALUES ('97a3207a-8b01-4576-9587-cfa6c7f95faf', '2016-5-5',
        NULL, true, '35566097435');
INSERT INTO Processo_Judicial
VALUES ('c66ace2d-854a-47ae-92cc-c3c2c3f2e9be', '2017-12-29',
        NULL, false, '96834017981');
INSERT INTO Processo_Judicial
VALUES ('7741e060-c688-4b6c-8100-0ae06072a709', '2019-6-12',
        '2020-6-15', true, '72167665150');
INSERT INTO Processo_Judicial
VALUES ('27c29632-58cf-4fe4-8022-94666e27fb99', '2002-6-18',
        NULL, true, '15692404331');
INSERT INTO Processo_Judicial
VALUES ('1384eefc-6f09-449a-b782-30ed792f5ffa', '2021-9-11',
        NULL, false, '21158760678');
INSERT INTO Processo_Judicial
VALUES ('0abbcbe3-9e6d-4272-a6b0-1083de4bb460', '2005-5-17',
        NULL, true, '53190602837');
INSERT INTO Processo_Judicial
VALUES ('2275acba-77d6-4013-a542-ab14d864b191', '2012-4-14',
        NULL, true, '41238485593');
INSERT INTO Processo_Judicial
VALUES ('3d02172e-7ff4-4983-a102-aab0183c47e2', '2003-4-10',
        NULL, true, '97542159403');
INSERT INTO Processo_Judicial
VALUES ('69a6e491-4232-4cf3-8733-20e8bb24e631', '2009-10-4',
        NULL, true, '46791838572');
INSERT INTO Processo_Judicial
VALUES ('ca28d613-b59b-4d2e-9422-601b884ec520', '2016-12-15',
        '2019-12-1', true, '52857200317');
INSERT INTO Processo_Judicial
VALUES ('bc0b6afe-5170-4f39-93c9-b46b7f832973', '2010-12-5',
        NULL, false, '64179538718');
INSERT INTO Processo_Judicial
VALUES ('078532a6-7cde-4e9d-9e02-bb838205569f', '2004-11-19',
        NULL, false, '19354682923');
INSERT INTO Processo_Judicial
VALUES ('a83250d7-b45b-44bd-82c2-cd41fefcb333', '2007-12-13',
        NULL, true, '52849328536');
INSERT INTO Processo_Judicial
VALUES ('6a391522-00df-4c5c-b0c7-27b9211b3402', '2019-3-13',
        NULL, true, '70865662137');
INSERT INTO Processo_Judicial
VALUES ('e0b18d6d-05e6-480c-96a2-f5472c2e662b', '2002-6-29',
        NULL, true, '59657050718');
INSERT INTO Processo_Judicial
VALUES ('b04bf3ac-f05f-4af0-9293-21e6a9387f09', '2014-4-24',
        NULL, true, '58344170006');
INSERT INTO Processo_Judicial
VALUES ('47d08a05-369c-494e-9036-826a09ec895b', '2003-12-7',
        '2019-3-27', false, '33585029381');
INSERT INTO Processo_Judicial
VALUES ('5debe072-ca7c-4d42-a585-3d83b1cce15b', '2019-5-17',
        '2018-2-21', false, '24394065793');
INSERT INTO Processo_Judicial
VALUES ('364face2-a544-41eb-a7ef-66668371533d', '2011-3-26',
        '2021-4-1', true, '61741954395');
INSERT INTO Processo_Judicial
VALUES ('2629bbd0-9f0c-496d-9cb1-bd8185c1bc26', '2015-3-29',
        '2019-4-14', false, '42611886474');
INSERT INTO Processo_Judicial
VALUES ('d841a7ae-49db-40c4-9548-b83a5427a4c1', '2020-10-16',
        '2021-8-28', false, '63185736755');
INSERT INTO Processo_Judicial
VALUES ('175ed050-6cd4-46b3-a44d-aa6d039fc0b9', '2014-4-27',
        NULL, true, '58344170006');
INSERT INTO Processo_Judicial
VALUES ('df049d72-08a2-414d-95e7-831d0190afec', '2007-10-13',
        NULL, false, '80777933001');
INSERT INTO Processo_Judicial
VALUES ('b26e140d-bd59-46dd-a3bf-c128584fdbd3', '2021-4-24',
        NULL, true, '54743101750');
INSERT INTO Processo_Judicial
VALUES ('c98b9615-976b-4ae3-afbc-93eab61383e7', '2010-1-12',
        '2019-9-30', true, '23369654125');
INSERT INTO Processo_Judicial
VALUES ('4e0ceeb0-43b1-4fc6-9d44-f52fdc833b02', '2014-3-2',
        NULL, true, '80985354657');
INSERT INTO Processo_Judicial
VALUES ('58e58f16-2675-4873-b4ba-c6f64e841d86', '2006-8-29',
        NULL, false, '82545323397');
INSERT INTO Processo_Judicial
VALUES ('a3b2840f-f9a6-4eea-b36e-950430566ee4', '2008-11-6',
        '2019-9-4', false, '89653281683');
INSERT INTO Processo_Judicial
VALUES ('29127ae6-1c45-4d7a-afbc-ed159b85755d', '2011-3-8',
        '2018-11-1', false, '66041600762');
INSERT INTO Processo_Judicial
VALUES ('00cac624-aff4-403f-98d1-563fde3f9489', '2008-12-26',
        '2019-11-4', false, '13218261646');
INSERT INTO Processo_Judicial
VALUES ('6d9358e7-a99e-4547-b3ff-974fd88ffa84', '2010-2-21',
        NULL, true, '30165319882');
INSERT INTO Processo_Judicial
VALUES ('8c4e5ff5-3f3f-4a32-abb0-9b072ca5a63b', '2021-9-23',
        NULL, false, '86525803739');
INSERT INTO Processo_Judicial
VALUES ('57936c02-5ce5-4edc-9787-58b168f179a0', '2020-4-18',
        NULL, false, '85471168039');
INSERT INTO Processo_Judicial
VALUES ('2d9635f3-27a5-40f6-97a3-3fe53544bad1', '2016-10-13',
        NULL, true, '40696949039');
INSERT INTO Processo_Judicial
VALUES ('acb77b2f-5f76-4a65-ad8f-46fa766e39ae', '2016-7-6',
        '2020-3-28', true, '32271739926');
INSERT INTO Processo_Judicial
VALUES ('cbc8ce6c-54f8-4f5a-8efe-1fb4a039ed55', '2021-10-13',
        '2021-10-16', true, '88644450863');
INSERT INTO Processo_Judicial
VALUES ('36c44e1b-d9c2-423f-97fb-42f91a2d9b1a', '2002-9-20',
        '2020-1-27', true, '15216369207');
INSERT INTO Processo_Judicial
VALUES ('356f9bd9-2593-44f7-a137-68fad912e49e', '2003-6-20',
        '2019-10-13', true, '91892894401');
INSERT INTO Processo_Judicial
VALUES ('242635f4-4420-4010-b478-b030abdf7a4b', '2016-7-28',
        NULL, true, '63419523332');
INSERT INTO Processo_Judicial
VALUES ('46c4d17c-86bf-4818-9297-4a9a62d98d31', '2006-7-25',
        '2016-11-29', true, '83335207737');
INSERT INTO Processo_Judicial
VALUES ('b3ffa883-9933-43c0-ab09-94ade8848e80', '2001-12-21',
        NULL, false, '26316574874');
INSERT INTO Processo_Judicial
VALUES ('b9d788e6-0990-45bc-a055-2d3a05f3725b', '2016-4-26',
        '2017-1-6', true, '32206475872');
INSERT INTO Processo_Judicial
VALUES ('c706d9b8-f379-45f2-b0a0-b81ecf97bd04', '2005-8-27',
        '2021-1-15', true, '48909591054');
INSERT INTO Processo_Judicial
VALUES ('788e336c-da66-439f-ba3d-0725d9cc4094', '2019-10-4',
        '2016-12-23', false, '60984027946');
INSERT INTO Processo_Judicial
VALUES ('5b30ce47-95bb-4e9b-ab59-53467ad7d4fb', '2020-3-2',
        NULL, true, '19121663228');
INSERT INTO Processo_Judicial
VALUES ('027bb5b9-5722-4ac5-975c-df6f1b7ad316', '2017-8-13',
        '2018-9-9', false, '83326663854');
INSERT INTO Processo_Judicial
VALUES ('1c13db3a-3d0e-4deb-ab2c-e8fe5d2da154', '2019-2-5',
        '2018-10-18', true, '63353046625');
INSERT INTO Processo_Judicial
VALUES ('7fd9c106-6021-4111-9df0-33ada88a06a2', '2006-11-20',
        '2019-10-13', true, '15456776062');
INSERT INTO Processo_Judicial
VALUES ('7c73e83c-6c87-4c48-b39b-fa7bd6c7f9cd', '2005-7-27',
        '2020-12-25', true, '47134191666');
INSERT INTO Processo_Judicial
VALUES ('cf01c080-f28a-4f58-943d-52b49faff2c8', '2012-7-16',
        '2018-11-10', false, '44911381667');
INSERT INTO Processo_Judicial
VALUES ('1ebabbbd-1c10-4ae7-abad-8ad79e9618eb', '2019-1-4',
        '2020-5-3', false, '86949663003');
INSERT INTO Processo_Judicial
VALUES ('6f306be6-88e8-4317-a4dd-27ca97a7b9c2', '2001-12-7',
        '2021-1-4', true, '91017248921');
INSERT INTO Processo_Judicial
VALUES ('503e6cb5-ad7b-4708-ac26-1a4b7291642d', '2003-11-11',
        NULL, true, '12836654633');
INSERT INTO Processo_Judicial
VALUES ('4f76a3cf-44f9-469e-ae14-323d2a9749a8', '2009-5-26',
        '2019-12-1', true, '81158944626');
INSERT INTO Processo_Judicial
VALUES ('65433484-3b66-4874-bff0-b2aea0de1801', '2009-10-16',
        '2019-1-28', false, '25317057166');
INSERT INTO Processo_Judicial
VALUES ('9949db53-82f9-4da2-aeff-62831418be0d', '2015-4-5',
        NULL, false, '78677525506');
INSERT INTO Processo_Judicial
VALUES ('12a43580-f651-49a0-81ed-6bb4084d5cd4', '2004-1-5',
        NULL, true, '24746668823');
INSERT INTO Processo_Judicial
VALUES ('977ab356-2ad7-4b61-99ef-d3c58f59b0d6', '2013-5-8',
        '2020-7-13', false, '69862666106');
INSERT INTO Processo_Judicial
VALUES ('6de6bb9e-ea47-4881-9713-ab5955b3f3be', '2011-10-25',
        NULL, true, '72085512168');
INSERT INTO Processo_Judicial
VALUES ('2d97b152-a216-4b80-9f38-6ee06435fed1', '2008-8-27',
        NULL, false, '93245290170');
INSERT INTO Processo_Judicial
VALUES ('628e65ce-8523-4222-90ce-e3f4b70d181e', '2011-12-27',
        NULL, true, '31951113061');
INSERT INTO Processo_Judicial
VALUES ('78409d90-f78f-450b-a531-2061bc255bdc', '2019-3-10',
        NULL, false, '92002684760');
INSERT INTO Processo_Judicial
VALUES ('e4df50df-0ca8-4123-9adf-2fbead6eac2a', '2004-12-23',
        NULL, true, '19822962293');
INSERT INTO Processo_Judicial
VALUES ('cf8441d9-0bee-423e-a186-a2ea249b757a', '2003-2-16',
        '2019-11-6', true, '58621376936');
INSERT INTO Processo_Judicial
VALUES ('e3098f19-45eb-41b0-b7f6-4efa3c68152b', '2014-11-4',
        NULL, true, '79860785743');
INSERT INTO Processo_Judicial
VALUES ('51289913-88a4-49f7-9b8a-c04193415fbc', '2018-8-21',
        '2019-10-13', false, '74929202487');
INSERT INTO Processo_Judicial
VALUES ('57907170-736c-4c55-be3d-d72c692d5e1e', '2015-8-3',
        '2019-6-6', true, '89395024664');
INSERT INTO Processo_Judicial
VALUES ('81274a4c-f61f-417b-818d-202f32beb68c', '2016-1-3',
        NULL, false, '56604801905');
INSERT INTO Processo_Judicial
VALUES ('070ed3b5-7ea6-421b-aa9e-3ccaa255699f', '2021-9-7',
        NULL, false, '86721126118');
INSERT INTO Processo_Judicial
VALUES ('a04c8f0c-e90a-43e3-8f3b-43951e01c6d3', '2007-2-27',
        NULL, false, '28458227536');
INSERT INTO Processo_Judicial
VALUES ('1597b17d-095b-4a32-a738-b5a4cc566317', '2006-12-8',
        NULL, false, '70566484834');
INSERT INTO Processo_Judicial
VALUES ('df8e3af0-1a42-4fe5-b652-f862c4a9a429', '2004-3-24',
        '2020-3-23', false, '43832994084');
INSERT INTO Processo_Judicial
VALUES ('d9378765-6bc2-4967-8470-e6dd50db336f', '2010-9-14',
        NULL, true, '22216452944');
INSERT INTO Processo_Judicial
VALUES ('b3d43710-01ab-4692-9183-f1e462837efc', '2013-2-10',
        '2017-12-1', false, '86271196368');
INSERT INTO Processo_Judicial
VALUES ('d35302cc-f721-4761-a53d-c7531afb6de4', '2015-4-10',
        NULL, false, '28806930759');
INSERT INTO Processo_Judicial
VALUES ('1bf70ef4-1a15-40a9-bbb8-f41bce250181', '2009-9-25',
        NULL, true, '34049041755');
INSERT INTO Processo_Judicial
VALUES ('b2f97211-508c-4793-b2da-23b8da2596d5', '2014-4-27',
        '2017-11-28', false, '84538009271');
INSERT INTO Processo_Judicial
VALUES ('65656e25-e0e4-461c-bf79-27901a6a9241', '2004-3-24',
        NULL, true, '13751666853');
INSERT INTO Processo_Judicial
VALUES ('7340b48c-96aa-40fc-9f3c-2bb260d4c86a', '2003-5-22',
        '2019-11-20', true, '80961511202');
INSERT INTO Processo_Judicial
VALUES ('613fec82-94a3-49f8-a944-a1debba4d0d0', '2003-9-8',
        NULL, false, '78491106405');
INSERT INTO Processo_Judicial
VALUES ('21c98385-4046-4123-aa7b-41a41636d547', '2002-5-20',
        '2018-11-1', false, '21991884345');
INSERT INTO Processo_Judicial
VALUES ('2ecf40e4-748e-4f6b-b218-d7668ccd5fcc', '2018-1-22',
        '2020-5-15', false, '48617187398');
INSERT INTO Processo_Judicial
VALUES ('8606faac-5ecf-4871-ba7a-0e6e23214675', '2006-3-1',
        '2019-2-16', true, '87482139978');
INSERT INTO Processo_Judicial
VALUES ('c709fd0f-84ed-48bc-bfa2-48eae6dc9183', '2006-1-13',
        '2018-8-13', true, '82966468287');
INSERT INTO Processo_Judicial
VALUES ('4e08ee79-d9eb-4eb3-a9c6-6bbac38c638b', '2004-12-7',
        NULL, false, '79310353223');
INSERT INTO Processo_Judicial
VALUES ('fd63e2dd-37f1-44c6-9419-227c90f96efd', '2014-2-7',
        NULL, true, '30063241985');
INSERT INTO Processo_Judicial
VALUES ('3507e94c-d0d9-40c2-932d-c8e00d76a03c', '2008-3-5',
        NULL, true, '90751582509');
INSERT INTO Processo_Judicial
VALUES ('724c67f9-a1e9-4c24-b68b-2a3cf0c2b266', '2011-4-6',
        NULL, false, '78797397429');
INSERT INTO Processo_Judicial
VALUES ('bbf169a8-d9f0-4e91-b29e-c64e39ff648b', '2002-8-5',
        NULL, true, '64255168652');
INSERT INTO Processo_Judicial
VALUES ('279fccf4-af9c-4163-8eaa-571185c6be93', '2016-4-10',
        '2019-8-31', true, '94223495926');
INSERT INTO Processo_Judicial
VALUES ('01838af8-2fee-432d-b07f-8891d970a4e1', '2019-1-22',
        NULL, false, '48407140278');
INSERT INTO Processo_Judicial
VALUES ('716c8fc6-79cd-4e2a-8822-4cb953e2b82c', '2016-8-4',
        '2019-5-20', false, '10734215972');
INSERT INTO Processo_Judicial
VALUES ('bd91891b-f425-43d7-bb63-81faffc8835d', '2019-3-10',
        NULL, false, '75698780661');
INSERT INTO Processo_Judicial
VALUES ('72c51dd3-bfd2-4ee4-94cd-9bc81b4cb21f', '2014-7-9',
        NULL, true, '80710820276');
INSERT INTO Processo_Judicial
VALUES ('5d2f53a9-ce77-46ac-bc97-54503d221caf', '2013-12-1',
        '2021-6-13', true, '10546498305');
INSERT INTO Processo_Judicial
VALUES ('f0990cfa-fc4b-4cfc-9458-db96a3cffa56', '2017-4-24',
        NULL, false, '12393648503');
INSERT INTO Processo_Judicial
VALUES ('a3837ea0-bbef-4dbc-b6ec-2655f8afc93a', '2004-7-26',
        '2017-6-2', true, '28251362228');
INSERT INTO Processo_Judicial
VALUES ('f50f60d4-6048-4af9-b166-662c81cc084b', '2004-9-17',
        '2018-9-9', false, '94656017050');
INSERT INTO Processo_Judicial
VALUES ('4663e440-c53c-42a6-8946-67bccddc4767', '2012-5-31',
        NULL, true, '23965377714');
INSERT INTO Processo_Judicial
VALUES ('2a86d655-735c-4344-8c9e-e42086a241d1', '2019-3-20',
        '2018-11-13', true, '50740862700');
INSERT INTO Processo_Judicial
VALUES ('14a01eea-3d79-4fd4-b934-32aee0105772', '2006-4-28',
        NULL, true, '22420991435');
INSERT INTO Processo_Judicial
VALUES ('02d0ed67-5c50-498d-b289-bb15306be8d3', '2013-9-25',
        '2017-12-25', true, '87348033047');
INSERT INTO Processo_Judicial
VALUES ('f1b46314-aa34-47f3-b889-d00afe0483d8', '2003-3-9',
        '2018-9-7', false, '64122301510');
INSERT INTO Processo_Judicial
VALUES ('9f973fd3-b351-487b-b863-831cb3020216', '2002-3-17',
        NULL, true, '89959186364');
INSERT INTO Processo_Judicial
VALUES ('4450ebcc-a673-4f8d-a885-2cd4f7058d2e', '2003-8-28',
        NULL, false, '40021847444');
INSERT INTO Processo_Judicial
VALUES ('3de87700-9867-4b9c-8880-362eca75cc79', '2005-9-26',
        '2017-11-21', false, '46404720542');
INSERT INTO Processo_Judicial
VALUES ('ba99deea-ba32-4f3f-8b85-3b2a6c97d395', '2004-4-28',
        '2017-6-5', false, '82545323397');
INSERT INTO Processo_Judicial
VALUES ('fe5e0d7c-0c6f-4b9d-a202-5e502fa4cdce', '2014-8-6',
        '2017-5-10', true, '81107487515');
INSERT INTO Processo_Judicial
VALUES ('4e3dad03-2c99-44ed-b679-4189b4a33eb0', '2019-10-7',
        '2019-11-2', true, '27684655510');
INSERT INTO Processo_Judicial
VALUES ('b5efbefe-f60c-4123-a0ad-a44ba9e11ca2', '2013-4-7',
        NULL, true, '23578601770');
INSERT INTO Processo_Judicial
VALUES ('6c9fbeb8-a971-4539-8f77-07f85efa28fb', '2006-5-31',
        NULL, false, '73877129219');
INSERT INTO Processo_Judicial
VALUES ('2cbefcbe-c628-47f0-99b5-637804366c2b', '2011-12-28',
        '2019-7-29', true, '87312114937');
INSERT INTO Processo_Judicial
VALUES ('5cf275db-7dc7-43eb-a3d8-b0806effa525', '2003-2-17',
        NULL, true, '26153816252');
INSERT INTO Processo_Judicial
VALUES ('f3d09acc-11f9-47a9-9697-09cf748ef93b', '2012-8-13',
        '2018-1-8', true, '34451081710');
INSERT INTO Processo_Judicial
VALUES ('5b71d799-4468-44fb-9695-da54668e7e4e', '2007-7-22',
        '2016-12-30', false, '82961410374');
INSERT INTO Processo_Judicial
VALUES ('466b3f47-98ec-4510-b878-e00d8a5349f7', '2006-9-6',
        NULL, true, '46218319148');
INSERT INTO Processo_Judicial
VALUES ('75f364c4-9fd6-40b0-9c16-16450f0b03ca', '2019-7-7',
        '2018-3-10', false, '96818589621');
INSERT INTO Processo_Judicial
VALUES ('7ab5e5f5-20a8-4cea-b59c-0df73b16b537', '2016-12-13',
        NULL, false, '88091845146');
INSERT INTO Processo_Judicial
VALUES ('cff5f6fc-8bd1-4e2b-a0a0-8cc7a1f100da', '2006-7-29',
        NULL, false, '42662608220');
INSERT INTO Processo_Judicial
VALUES ('0b500f2c-8017-49e6-ab21-b79e95e3fb5d', '2013-11-1',
        NULL, true, '26146796492');
INSERT INTO Processo_Judicial
VALUES ('3c897992-635d-4493-af27-f447de81c74d', '2016-3-22',
        NULL, false, '38653304902');
INSERT INTO Processo_Judicial
VALUES ('a3682225-49ba-42a3-bba8-f679bdad8bdf', '2018-4-28',
        NULL, true, '44770700223');
INSERT INTO Processo_Judicial
VALUES ('3ac66a1d-5e93-40fe-b1cb-ead71a68e9f3', '2007-10-5',
        NULL, false, '22216452944');
INSERT INTO Processo_Judicial
VALUES ('1b25ff3b-f042-4899-ae18-638925125dec', '2021-6-3',
        '2020-9-23', false, '28974858648');
INSERT INTO Processo_Judicial
VALUES ('b96584f7-2a01-4082-a848-2cae4247c90e', '2008-12-18',
        '2020-2-9', false, '28806930759');
INSERT INTO Processo_Judicial
VALUES ('0a67c6d9-6150-4cb8-ade9-80e4cd96e1c8', '2020-9-28',
        '2020-3-9', true, '11802864642');
INSERT INTO Processo_Judicial
VALUES ('f0824eb5-3420-4a91-819a-4882a3a9474e', '2010-11-2',
        NULL, false, '70941680760');
INSERT INTO Processo_Judicial
VALUES ('ee188da8-c930-4c73-b0c5-ec246915d77d', '2004-5-21',
        '2016-12-14', true, '10734215972');
INSERT INTO Processo_Judicial
VALUES ('07660308-c6ad-47cc-9a80-984b1e01a7b0', '2011-6-2',
        NULL, true, '52057552337');
INSERT INTO Processo_Judicial
VALUES ('34197d32-015c-4134-9f80-e4ba614d8e04', '2020-8-13',
        NULL, true, '35354715120');
INSERT INTO Processo_Judicial
VALUES ('bf4494c3-27d2-4c1b-b192-a1c5eb9a4cd5', '2021-9-16',
        '2019-2-18', true, '47509506070');
INSERT INTO Processo_Judicial
VALUES ('fa0dcd00-1253-4177-b800-7d43e75a49d1', '2011-1-16',
        '2018-2-6', false, '15007094920');
INSERT INTO Processo_Judicial
VALUES ('eb19e8e8-a69a-415a-8ee7-dbd44fcef037', '2004-11-17',
        NULL, true, '34712144928');
INSERT INTO Processo_Judicial
VALUES ('a2c36085-ecdc-46f8-aa52-109f5e6b18ad', '2019-10-30',
        '2019-7-31', false, '24394065793');
INSERT INTO Processo_Judicial
VALUES ('dc3aa30b-fce7-4b10-a3aa-f67aa96e7f2a', '2021-8-22',
        '2019-12-13', true, '92975085964');
INSERT INTO Processo_Judicial
VALUES ('e6ded452-4954-4f09-b69f-81200a32e5ef', '2021-9-17',
        NULL, true, '79310353223');
INSERT INTO Processo_Judicial
VALUES ('248398cd-a122-46cd-aba2-b075e4f98783', '2020-11-2',
        '2018-10-1', true, '78677525506');
INSERT INTO Processo_Judicial
VALUES ('16c46cdb-127b-4853-925f-7bea4817b031', '2018-9-13',
        NULL, true, '31668141162');
INSERT INTO Processo_Judicial
VALUES ('3ef175e1-975b-4089-b688-4aeb16961e5f', '2020-3-6',
        NULL, true, '40021847444');
INSERT INTO Processo_Judicial
VALUES ('4eb0c8c0-db93-470b-9421-5f460654d89a', '2010-8-6',
        NULL, true, '51445510021');
INSERT INTO Processo_Judicial
VALUES ('ed9ea5e5-750a-47bc-a796-047e0c6adcba', '2002-1-24',
        NULL, false, '49451829111');
INSERT INTO Processo_Judicial
VALUES ('7c0521c7-9093-4710-adec-bb124339078e', '2019-9-27',
        NULL, true, '94086229731');
INSERT INTO Processo_Judicial
VALUES ('2570c051-96af-49b1-8b0a-06f888d171ba', '2013-1-22',
        '2018-9-7', true, '77011687273');
INSERT INTO Processo_Judicial
VALUES ('aefb20f2-9887-48ce-aa12-277860dc4ce3', '2006-8-9',
        '2019-12-22', false, '31668141162');
INSERT INTO Processo_Judicial
VALUES ('fe8597f4-ec9c-4620-99f4-fd38a179666c', '2013-7-22',
        '2021-2-2', false, '82877426827');
INSERT INTO Processo_Judicial
VALUES ('f05667dd-7c0f-47f0-87b5-2e877615d2fc', '2011-9-2',
        '2019-5-9', false, '19756374296');
INSERT INTO Processo_Judicial
VALUES ('60dd24fc-0f17-4688-a56f-960f40c583b1', '2021-1-31',
        NULL, false, '31904155020');
INSERT INTO Processo_Judicial
VALUES ('5762a71b-6b8a-4986-a388-69f9ca4ec5d3', '2009-12-15',
        '2019-9-17', true, '73277497400');
INSERT INTO Processo_Judicial
VALUES ('662e8440-3c0a-41f4-afc7-6afd62f51280', '2015-5-11',
        '2020-2-5', true, '78540902768');
INSERT INTO Processo_Judicial
VALUES ('ddf99121-b6da-4889-83aa-dea5d93ec717', '2015-12-9',
        '2020-11-18', true, '15462815286');
INSERT INTO Processo_Judicial
VALUES ('05ed35c6-2b43-491e-8646-cf0e14c2e471', '2003-2-10',
        '2020-7-21', false, '34965334206');
INSERT INTO Processo_Judicial
VALUES ('9d3c86ab-1049-4351-ab43-65e935a8e39d', '2009-12-1',
        '2016-12-19', false, '78620078519');
INSERT INTO Processo_Judicial
VALUES ('0f60d9cc-e4ed-4fdf-8f19-4ca2950a48f3', '2008-3-17',
        NULL, false, '71359896301');
INSERT INTO Processo_Judicial
VALUES ('5fd26e44-c92d-4327-af55-6bad77059b6c', '2016-10-30',
        '2020-9-6', false, '62763315637');
INSERT INTO Processo_Judicial
VALUES ('f81d292a-0f7c-42a7-a01f-d2457c02c723', '2017-12-31',
        '2020-5-17', true, '21988119990');
INSERT INTO Processo_Judicial
VALUES ('36de3550-636d-495e-92f2-7ba1af35ada5', '2012-12-17',
        NULL, true, '49878119379');
INSERT INTO Processo_Judicial
VALUES ('348344b6-c127-4e66-a053-070688cf5a0f', '2019-5-20',
        '2018-4-29', false, '24394065793');
INSERT INTO Processo_Judicial
VALUES ('1ae35d77-c40a-4ac7-bd05-b5efff29ca47', '2002-8-20',
        NULL, true, '82694570559');
INSERT INTO Processo_Judicial
VALUES ('1cc66262-1c2b-4a3b-8646-323531e1ea1b', '2018-11-27',
        NULL, false, '13378266729');
INSERT INTO Processo_Judicial
VALUES ('d0a603db-acc9-46f2-ae65-08a0d4d70563', '2014-6-26',
        '2017-9-23', true, '68421083828');
INSERT INTO Processo_Judicial
VALUES ('faeae200-7b43-45a4-a199-d56af4061f05', '2012-10-22',
        NULL, true, '70941680760');
INSERT INTO Processo_Judicial
VALUES ('ccabeec2-3cbd-4de8-9516-a39f47c5606b', '2017-7-28',
        '2017-9-22', false, '46974461216');
INSERT INTO Processo_Judicial
VALUES ('da177782-7f40-4f8b-86a4-1fa782091b1d', '2003-7-23',
        NULL, false, '90085991316');
INSERT INTO Processo_Judicial
VALUES ('b719e1ae-531c-4e82-8ffb-91a09ec87973', '2002-5-10',
        '2017-8-5', false, '17060522225');
INSERT INTO Processo_Judicial
VALUES ('a964b910-4e50-4d28-bd87-f0b4873d4e28', '2010-1-11',
        NULL, true, '57362485802');
INSERT INTO Processo_Judicial
VALUES ('5656fc67-9dc3-49fb-95dd-b68cb2324b98', '2016-11-19',
        '2017-5-10', false, '73957219352');
INSERT INTO Processo_Judicial
VALUES ('8d00b675-8d98-488f-b555-90d6f308a518', '2012-5-10',
        '2019-1-7', true, '15525305538');
INSERT INTO Processo_Judicial
VALUES ('21aef944-25dd-4860-98f3-e34925636ebb', '2006-3-22',
        '2017-10-27', false, '34952035478');
INSERT INTO Processo_Judicial
VALUES ('5d7302a4-e12f-4e5a-b5bc-2089d3cf3204', '2016-1-25',
        '2018-7-5', true, '98058124845');
INSERT INTO Processo_Judicial
VALUES ('4e5ef97e-eca7-4f45-bd87-3103b7bb915c', '2013-9-6',
        '2017-2-5', true, '61570064800');
INSERT INTO Processo_Judicial
VALUES ('676c943e-0790-46d6-ad82-0906fa1d0ec6', '2005-5-8',
        '2019-3-17', false, '83423976283');
INSERT INTO Processo_Judicial
VALUES ('dd8a40dd-4f30-44f3-b42b-9fa3867d46f8', '2016-10-9',
        '2019-7-28', false, '50722760849');
INSERT INTO Processo_Judicial
VALUES ('f206f8db-0fb9-49a1-bb7d-fd2bc8db474c', '2009-2-12',
        '2021-7-18', false, '87386788851');
INSERT INTO Processo_Judicial
VALUES ('fb735597-dbc3-471d-ab1a-a8161794e74b', '2020-11-14',
        '2020-12-18', true, '50013432025');
INSERT INTO Processo_Judicial
VALUES ('4265c7e4-f8b9-461b-aef3-ae1665681d54', '2015-9-24',
        '2021-1-30', false, '72847558700');
INSERT INTO Processo_Judicial
VALUES ('c78df575-d04a-4408-95c9-3399f891b765', '2015-1-3',
        '2019-3-23', false, '27393568651');
INSERT INTO Processo_Judicial
VALUES ('feaae522-96cd-4168-9089-9f4dba5e6fc7', '2008-3-31',
        '2018-1-9', true, '89653281683');
INSERT INTO Processo_Judicial
VALUES ('f31b882d-f43d-40ae-9a03-1ae45a210fb3', '2005-10-1',
        '2020-6-27', true, '49472601814');
INSERT INTO Processo_Judicial
VALUES ('2209e28c-de16-405d-a334-a79516eed50b', '2020-2-3',
        '2021-4-24', true, '42611886474');
INSERT INTO Processo_Judicial
VALUES ('5a5a4d29-0be8-4cff-8a62-aaf1f7c53547', '2009-1-8',
        '2021-1-9', true, '55661978677');
INSERT INTO Processo_Judicial
VALUES ('bb01910e-c08e-437e-8756-61c3dd1d7132', '2018-3-8',
        '2021-3-18', false, '40396111428');
INSERT INTO Processo_Judicial
VALUES ('74c6cf2b-0350-4a8e-a424-b3c96a79264a', '2002-7-4',
        '2021-6-10', true, '42436610548');
INSERT INTO Processo_Judicial
VALUES ('b5fc0e4a-56cd-46c7-9ce1-f4e840657275', '2008-12-10',
        NULL, false, '13684269834');
INSERT INTO Processo_Judicial
VALUES ('62d06ec6-7387-46c2-b0ca-3753d28c0c30', '2013-8-29',
        '2018-9-6', false, '11792162314');
INSERT INTO Processo_Judicial
VALUES ('0bd06717-9571-4582-a0a3-94284b86f469', '2011-10-5',
        '2016-11-29', false, '48617187398');
INSERT INTO Processo_Judicial
VALUES ('5f05c277-45ce-430c-ae62-963b302c532f', '2012-3-1',
        '2017-8-10', false, '47086909811');
INSERT INTO Processo_Judicial
VALUES ('5d48776a-a2a6-4aaa-bf00-ee6ad03071ff', '2002-5-5',
        NULL, false, '20341535366');
INSERT INTO Processo_Judicial
VALUES ('235f5018-52a0-44c1-bea6-896d0cd9c391', '2015-12-20',
        NULL, true, '76349967408');
INSERT INTO Processo_Judicial
VALUES ('3c22087f-07ca-4350-a0c9-a59a0cefa125', '2017-4-21',
        NULL, false, '56926663320');
INSERT INTO Processo_Judicial
VALUES ('40c42d9d-bc50-4344-9dc5-0e44bcb06783', '2017-10-2',
        '2018-5-4', false, '30624507255');
INSERT INTO Processo_Judicial
VALUES ('12f2e6f5-eba6-4595-a696-e2c0da01c5a7', '2003-1-30',
        '2019-11-4', false, '90832039350');
INSERT INTO Processo_Judicial
VALUES ('965af704-8994-4c36-897f-9008c0ee5655', '2016-6-26',
        '2019-5-26', true, '57082543941');
INSERT INTO Processo_Judicial
VALUES ('32c95c78-a677-41b4-a3e6-6a382e2485f1', '2017-3-1',
        NULL, false, '56392738602');
INSERT INTO Processo_Judicial
VALUES ('123c2a85-3f1c-43a1-9c58-4277a9ebc3cc', '2006-7-26',
        '2020-9-30', true, '40690805627');
INSERT INTO Processo_Judicial
VALUES ('3ecdfd7c-10ac-453a-8284-ed52191f0a85', '2007-7-21',
        NULL, false, '53966798104');
INSERT INTO Processo_Judicial
VALUES ('2dc424b6-ecef-4a8b-907e-b20886b2e059', '2007-2-6',
        '2021-10-7', false, '68096587185');
INSERT INTO Processo_Judicial
VALUES ('f6395020-c5c3-4d78-9ad9-71f68bf3f972', '2002-5-7',
        '2017-9-17', false, '16354246530');
INSERT INTO Processo_Judicial
VALUES ('02621450-a583-414a-a75f-b1ba601ae3fc', '2017-2-21',
        NULL, false, '33110790541');
INSERT INTO Processo_Judicial
VALUES ('a086745e-a1ae-43d8-bdd8-2ff3ddb2bf04', '2002-9-23',
        NULL, true, '38326898736');
INSERT INTO Processo_Judicial
VALUES ('edb75b41-91ae-4f1d-8787-6f1cbb408d35', '2020-1-16',
        NULL, false, '42022861305');
INSERT INTO Processo_Judicial
VALUES ('e9357c51-b01d-4dd3-a1e8-434e274919c9', '2004-7-5',
        NULL, false, '32980330095');
INSERT INTO Processo_Judicial
VALUES ('970371a0-9d85-4123-9fe8-3652380fb63e', '2017-8-6',
        '2020-5-8', true, '68520916590');
INSERT INTO Processo_Judicial
VALUES ('c5be82af-646f-47a9-89a1-f1ab8f86c859', '2006-8-1',
        '2018-1-30', false, '81749686598');
INSERT INTO Processo_Judicial
VALUES ('05ec362a-a942-4cfb-a6d3-d217255d79cd', '2003-2-14',
        NULL, true, '82742590734');
INSERT INTO Processo_Judicial
VALUES ('667f0caa-ded4-4e53-8f78-ce4b3f7cef35', '2017-7-5',
        NULL, true, '16893356314');
INSERT INTO Processo_Judicial
VALUES ('68753c03-4d41-4a15-8fa2-2767b7429f8c', '2004-7-25',
        NULL, true, '56193133238');
INSERT INTO Processo_Judicial
VALUES ('65faec1f-60fc-43cf-973f-be8cf106ee28', '2018-5-8',
        '2018-7-16', false, '16381429000');
INSERT INTO Processo_Judicial
VALUES ('6952c9c2-8c25-4830-8e09-ab70a39c0cc5', '2009-6-20',
        '2021-8-1', false, '41108251772');
INSERT INTO Processo_Judicial
VALUES ('563c2f86-c6f8-48d4-a9be-0014bc1b3139', '2011-11-15',
        NULL, true, '77009138378');
INSERT INTO Processo_Judicial
VALUES ('05805fb3-9326-4f82-970e-76152739e5ce', '2021-5-2',
        NULL, false, '72005313155');
INSERT INTO Processo_Judicial
VALUES ('d6e27b36-8039-4377-bd2b-89271db66497', '2013-8-31',
        NULL, false, '48624392356');
INSERT INTO Processo_Judicial
VALUES ('6258a2ea-d1d6-4b2a-b2c5-e387bd2701d6', '2003-4-30',
        NULL, true, '23965377714');
INSERT INTO Processo_Judicial
VALUES ('eaf17391-b100-4e8e-8814-b8f02358b945', '2009-3-26',
        '2016-12-30', true, '83335207737');
INSERT INTO Processo_Judicial
VALUES ('655899bd-0eb7-4536-868c-69e8dee5d5a2', '2019-6-11',
        '2020-8-27', true, '87898668807');
INSERT INTO Processo_Judicial
VALUES ('5d92038c-0175-452a-9015-5e1488e5f07c', '2006-8-17',
        NULL, true, '18922563376');
INSERT INTO Processo_Judicial
VALUES ('d77f1b44-415d-4e99-b30d-d64ef019d4d1', '2019-10-2',
        '2019-6-26', true, '16846755656');
INSERT INTO Processo_Judicial
VALUES ('7a30875b-f5b5-477b-86a2-a5c8f472c006', '2010-1-26',
        '2018-1-17', false, '57748351241');
INSERT INTO Processo_Judicial
VALUES ('b31fe085-1752-45f1-844e-c5d0eac08885', '2020-7-17',
        '2021-1-18', true, '87366192734');
INSERT INTO Processo_Judicial
VALUES ('0af02f8f-afe0-475b-9237-f83f5cc8d972', '2020-7-22',
        NULL, false, '24722674724');
INSERT INTO Processo_Judicial
VALUES ('1fb9ee9c-b865-471d-9684-f03905fe2000', '2007-8-24',
        NULL, true, '84267205318');
INSERT INTO Processo_Judicial
VALUES ('6057c590-b326-4f32-b80c-40305725e995', '2007-3-29',
        NULL, false, '74766249782');
INSERT INTO Processo_Judicial
VALUES ('b1ac8be3-af0a-4a18-a4c7-d11c08fd22cc', '2004-11-26',
        NULL, true, '94656017050');
INSERT INTO Processo_Judicial
VALUES ('bf22d83f-64a1-4999-a6b5-c3b16eda7434', '2017-9-28',
        NULL, false, '50722760849');
INSERT INTO Processo_Judicial
VALUES ('7a34bb7f-6b0e-4ad7-aca6-84bc83db346a', '2007-6-17',
        '2020-10-26', false, '82239788295');
INSERT INTO Processo_Judicial
VALUES ('ab7cc07a-18a2-464d-a346-2c5ff09655bd', '2017-12-25',
        '2020-4-8', false, '44480531623');
INSERT INTO Processo_Judicial
VALUES ('48a1bc02-d298-48ec-b5b9-48ea9702658b', '2004-6-12',
        '2018-2-15', true, '80553411089');
INSERT INTO Processo_Judicial
VALUES ('dcb5959c-7550-4e4c-80e3-8c42f4246892', '2012-7-20',
        NULL, false, '44908207063');
INSERT INTO Processo_Judicial
VALUES ('1755bde0-2b8b-46db-a9cc-cdfb6b3dbcce', '2018-11-6',
        NULL, false, '74082964621');
INSERT INTO Processo_Judicial
VALUES ('ec6a207e-4968-43f2-9e76-d93b6b8b8bfe', '2010-3-30',
        NULL, false, '23413005832');
INSERT INTO Processo_Judicial
VALUES ('74834515-b0ee-452e-a0e6-20b95538d718', '2013-9-24',
        '2021-1-15', true, '77198284929');
INSERT INTO Processo_Judicial
VALUES ('bc49188a-fe4a-4def-9571-8b8658eab21a', '2019-5-19',
        NULL, true, '58344170006');
INSERT INTO Processo_Judicial
VALUES ('0d07b91b-4afd-43a7-82b3-f2c72457c151', '2005-8-9',
        '2021-11-2', true, '66367407455');
INSERT INTO Processo_Judicial
VALUES ('a37e7b33-5772-4313-9d33-9d7d2e5db86c', '2008-7-15',
        NULL, false, '90229740976');
INSERT INTO Processo_Judicial
VALUES ('e1130ad7-5756-4a00-8725-a742ca3201a8', '2013-11-23',
        NULL, false, '56881690993');
INSERT INTO Processo_Judicial
VALUES ('9ceb6e24-a66c-431f-8814-82d810e2bfe9', '2003-4-20',
        NULL, true, '41530032556');
INSERT INTO Processo_Judicial
VALUES ('aab67d21-2a73-49eb-9299-8aa8edc26406', '2012-4-9',
        NULL, true, '64684924166');
INSERT INTO Processo_Judicial
VALUES ('99696ad9-cabf-4dc0-8033-4c6c170297fa', '2011-10-21',
        NULL, false, '99474227605');
INSERT INTO Processo_Judicial
VALUES ('3ab3cefd-3da7-4fea-ae16-2a968991a195', '2002-6-9',
        '2020-9-1', false, '34806180221');
INSERT INTO Processo_Judicial
VALUES ('59dbb114-6ea0-4807-8690-66cb9642e937', '2020-6-11',
        NULL, false, '11973855195');
INSERT INTO Processo_Judicial
VALUES ('161f4728-e71a-4f0a-b1b5-502f53bb7d1d', '2012-7-22',
        '2021-9-5', false, '86574679580');
INSERT INTO Processo_Judicial
VALUES ('50554370-ba0a-4997-8c36-a86ba73c8fbb', '2003-8-19',
        NULL, false, '85294869835');
INSERT INTO Processo_Judicial
VALUES ('babdb8cc-7bc7-4cbf-a506-c7429b8efeba', '2009-3-6',
        '2021-1-7', false, '13684269834');
INSERT INTO Processo_Judicial
VALUES ('c801042e-5739-4b7c-acf3-4a6081bb578b', '2005-8-25',
        NULL, false, '68421083828');
INSERT INTO Processo_Judicial
VALUES ('d8994c3d-223a-4f96-b679-4bd490133d96', '2014-7-1',
        '2018-11-4', true, '30165319882');
INSERT INTO Processo_Judicial
VALUES ('ffe061e9-9dee-4e2a-b6c9-758c4d0d57b1', '2004-10-29',
        '2020-3-2', true, '49472601814');
INSERT INTO Processo_Judicial
VALUES ('cb945338-87ec-4b1d-9811-9d0d81205651', '2010-7-24',
        '2020-11-30', false, '16176439919');
INSERT INTO Processo_Judicial
VALUES ('dbbb7f54-bebc-4160-b4b0-33af503c780a', '2020-4-19',
        NULL, true, '46974461216');
INSERT INTO Processo_Judicial
VALUES ('3707f8e6-f861-4099-8adb-f8e643d05ce0', '2014-7-25',
        NULL, false, '26316574874');
INSERT INTO Processo_Judicial
VALUES ('db7aa58f-dfff-4868-8ca9-35d7fbd3818a', '2015-12-1',
        NULL, false, '98058124845');
INSERT INTO Processo_Judicial
VALUES ('6045a619-79bc-41ea-aace-ebafbd99549e', '2007-4-11',
        '2021-11-20', false, '83635655883');
INSERT INTO Processo_Judicial
VALUES ('9810d889-eff1-46d9-bb42-f4aad2065404', '2018-2-27',
        '2020-9-26', false, '77011687273');
INSERT INTO Processo_Judicial
VALUES ('1e2bde87-e83b-44dd-8601-722a8fe236cd', '2003-12-1',
        '2017-5-18', false, '50137497729');
INSERT INTO Processo_Judicial
VALUES ('f4f94845-e63e-460d-baae-982685c79823', '2010-12-3',
        '2018-11-29', false, '68110109437');
INSERT INTO Processo_Judicial
VALUES ('698966fa-9507-4115-af9e-c9bbe09d6dc7', '2004-10-18',
        '2020-7-14', false, '76349967408');
INSERT INTO Processo_Judicial
VALUES ('44916bca-bfdd-442f-9e5d-7211bbb26d6c', '2018-3-17',
        '2020-10-17', true, '44611691811');
INSERT INTO Processo_Judicial
VALUES ('43b7897d-d03c-478e-8cfd-7ed1212330ae', '2013-3-8',
        '2017-10-1', true, '38533823639');
INSERT INTO Processo_Judicial
VALUES ('aed14ffa-a394-468d-9dc6-7058228ddf10', '2019-4-11',
        NULL, false, '91491590670');
INSERT INTO Processo_Judicial
VALUES ('01fba494-c6dd-46c4-9617-9319598811ff', '2004-1-7',
        NULL, true, '74868324829');
INSERT INTO Processo_Judicial
VALUES ('fb6eee8a-c271-4490-80a0-71988e5f1503', '2006-4-9',
        '2021-5-20', true, '61978392985');
INSERT INTO Processo_Judicial
VALUES ('a0b80bfb-fbce-439a-b1cb-f4c25e01d1de', '2013-4-16',
        '2020-12-29', true, '95659425617');
INSERT INTO Processo_Judicial
VALUES ('3af3d382-8333-4686-a329-047e28d18d39', '2012-10-3',
        '2019-10-21', true, '99175420803');
INSERT INTO Processo_Judicial
VALUES ('0262ed3a-cc15-4318-b721-fc1b1f8e8f83', '2021-5-9',
        '2018-3-18', true, '90003637734');
INSERT INTO Processo_Judicial
VALUES ('b2e9cfc9-fb55-4304-827e-3048c39e0a30', '2020-9-13',
        NULL, true, '69957945945');
INSERT INTO Processo_Judicial
VALUES ('6fbb1d3d-3383-43df-895a-a17c32247c8c', '2018-4-22',
        '2018-11-7', false, '96399192840');
INSERT INTO Processo_Judicial
VALUES ('a35db84b-091f-4395-9f40-839d377d2cbe', '2021-1-21',
        '2018-12-4', false, '13409115150');
INSERT INTO Processo_Judicial
VALUES ('72769bea-fa07-4d58-896c-feb807f8a3c3', '2021-6-6',
        NULL, true, '57093701930');
INSERT INTO Processo_Judicial
VALUES ('c4f44d23-b817-46e4-b704-1a20149d05b2', '2016-6-22',
        '2021-5-16', true, '67688139935');
INSERT INTO Processo_Judicial
VALUES ('1b851776-377a-4286-a279-772eacf9823d', '2005-4-14',
        NULL, true, '23029678915');
INSERT INTO Processo_Judicial
VALUES ('d5bd5072-8067-4a4d-bea3-c0f2b11fb502', '2019-3-10',
        '2017-3-15', false, '29555345340');
INSERT INTO Processo_Judicial
VALUES ('e69af6e3-94a9-41f1-a1d6-49af2cf83be9', '2017-4-29',
        '2018-9-28', true, '33251189284');
INSERT INTO Processo_Judicial
VALUES ('e4f1719d-b905-4102-8109-2b8f05bd90a9', '2003-10-13',
        '2018-3-13', false, '60372715506');
INSERT INTO Processo_Judicial
VALUES ('d11cd68f-f435-47da-96b6-aeedc186c1ac', '2013-3-27',
        '2017-7-27', true, '77598187436');
INSERT INTO Processo_Judicial
VALUES ('e81c7d3c-9650-4a7c-a447-af9ef743b3a7', '2012-12-13',
        NULL, false, '68421083828');
INSERT INTO Processo_Judicial
VALUES ('75b012b0-288c-4aae-af74-bfa66b32d347', '2020-11-10',
        '2020-4-12', true, '21158760678');
INSERT INTO Processo_Judicial
VALUES ('15209286-57b7-4ee1-8b9e-f57c8e4bd2a8', '2021-4-17',
        '2018-7-5', true, '57989361614');
INSERT INTO Processo_Judicial
VALUES ('1c91d350-dc30-46a5-9a08-8f527cddde52', '2020-5-14',
        NULL, true, '21995127492');
INSERT INTO Processo_Judicial
VALUES ('da739b25-cf43-4479-b4a4-0b2e0120d915', '2015-7-6',
        NULL, false, '10555255529');
INSERT INTO Processo_Judicial
VALUES ('2f198bc5-2be9-4da0-ae0f-ade6f894978a', '2017-12-27',
        '2019-7-13', true, '89067652127');
INSERT INTO Processo_Judicial
VALUES ('09ca90eb-58c2-427c-aac0-666c2eb7ec11', '2009-5-23',
        NULL, true, '85096177156');
INSERT INTO Processo_Judicial
VALUES ('55bb5a9d-4718-41ed-939f-012b6a60cc31', '2015-11-16',
        NULL, false, '86912200003');
INSERT INTO Processo_Judicial
VALUES ('e5b4808b-1410-4f46-bcbd-c58f56464eab', '2004-10-16',
        '2021-8-8', true, '36323933107');
INSERT INTO Processo_Judicial
VALUES ('4edc3e6f-2cf1-40bc-8edb-57ca0a958fd9', '2015-12-24',
        NULL, true, '22420991435');
INSERT INTO Processo_Judicial
VALUES ('995b4182-77e5-4e2b-a9aa-577bbe2814b3', '2003-9-25',
        NULL, true, '21310869527');
INSERT INTO Processo_Judicial
VALUES ('643ac341-4a71-422f-97be-97269cea42b7', '2018-2-3',
        NULL, true, '48617187398');
INSERT INTO Processo_Judicial
VALUES ('fbbfd5ae-6b73-4115-8052-707dd599d4ef', '2008-4-20',
        '2019-12-18', false, '45365409015');
INSERT INTO Processo_Judicial
VALUES ('87c8d483-32c2-4cf0-882b-ecddfb8a198e', '2007-7-4',
        '2021-5-21', false, '82742590734');
INSERT INTO Processo_Judicial
VALUES ('5652a514-6694-4f5a-9edc-017a66e7a8e6', '2007-1-22',
        NULL, false, '19179157342');
INSERT INTO Processo_Judicial
VALUES ('af3a3392-b3fb-4567-b1cd-8e01693eadf6', '2014-9-30',
        NULL, false, '80310637017');
INSERT INTO Processo_Judicial
VALUES ('f90a5907-c766-493e-9bcf-e1cbd6802c9a', '2004-12-8',
        NULL, true, '99875636277');
INSERT INTO Processo_Judicial
VALUES ('47f9f434-c3eb-4a4a-9912-ccf7d7d2ca0c', '2015-11-23',
        NULL, false, '44611691811');
INSERT INTO Processo_Judicial
VALUES ('820c5051-4f37-4051-ba3b-0c966c6ebcf9', '2012-6-30',
        '2020-11-15', true, '73494647324');
INSERT INTO Processo_Judicial
VALUES ('fe3cc234-8ead-4f13-b45a-b30674226fc5', '2005-2-12',
        NULL, false, '79759818490');
INSERT INTO Processo_Judicial
VALUES ('74de028b-20f6-4183-8795-abae252a7887', '2019-5-7',
        '2017-10-22', false, '85421043294');
INSERT INTO Processo_Judicial
VALUES ('cdb64667-1e3c-4c27-ab19-a0937ed0e8f1', '2002-2-21',
        NULL, true, '62563421055');
INSERT INTO Processo_Judicial
VALUES ('d3c3e879-857a-4517-b2ca-6dd9afaffca2', '2012-10-9',
        NULL, false, '78830082472');
INSERT INTO Processo_Judicial
VALUES ('aadb12ca-1109-4699-bfab-ea7589c1e135', '2006-2-9',
        NULL, true, '99547809399');
INSERT INTO Processo_Judicial
VALUES ('8bebe2e2-1677-4c21-8a05-25e86b5c92e0', '2011-6-26',
        NULL, false, '38336047478');
INSERT INTO Processo_Judicial
VALUES ('3bdd1c2a-d7ca-40e7-b7f0-3cfe98c8852b', '2007-5-20',
        '2017-8-12', true, '85063207736');
INSERT INTO Processo_Judicial
VALUES ('ec26f290-8863-47b9-9c73-309b3ffb6a8e', '2020-2-5',
        '2018-5-12', false, '66636465038');
INSERT INTO Processo_Judicial
VALUES ('ffbeb2b1-5ffa-4d95-9693-3f15dcaad401', '2019-12-29',
        '2018-4-30', true, '30063241985');
INSERT INTO Processo_Judicial
VALUES ('f98ff5ac-b66f-42e2-a76e-bd87a5f6e953', '2018-2-18',
        '2016-11-28', false, '90046827753');
INSERT INTO Processo_Judicial
VALUES ('07a31536-f812-470c-aa2a-7e824345c288', '2014-11-25',
        '2020-11-26', false, '24722674724');
INSERT INTO Processo_Judicial
VALUES ('4b8c0d0b-90b6-4d32-813e-48470aee8b14', '2012-4-3',
        NULL, false, '81856962239');
INSERT INTO Processo_Judicial
VALUES ('a2ab6b89-f5d2-44e6-99e6-88fd70ef4b71', '2020-10-22',
        NULL, true, '64312151931');
INSERT INTO Processo_Judicial
VALUES ('f67d4c84-9446-4116-b359-f84fc5bddfbb', '2013-5-13',
        '2017-1-24', false, '42611886474');
INSERT INTO Processo_Judicial
VALUES ('f21ed74d-3faa-4e84-abce-a2f952bebc12', '2017-6-4',
        NULL, true, '78491106405');
INSERT INTO Processo_Judicial
VALUES ('3ff45622-8424-47e0-9fae-75950246d766', '2003-1-4',
        NULL, true, '85103842427');
INSERT INTO Processo_Judicial
VALUES ('b0185970-d820-48b5-8a35-41888315f457', '2011-9-17',
        '2018-12-23', true, '14172927623');
INSERT INTO Processo_Judicial
VALUES ('9b344df6-fb1c-4e52-b54e-7c86be1af100', '2020-11-20',
        '2017-9-27', false, '21700934006');
INSERT INTO Processo_Judicial
VALUES ('04aa5a74-56ee-4ff5-baeb-3581a7f90ed1', '2013-12-15',
        '2017-5-29', true, '70917615771');
INSERT INTO Processo_Judicial
VALUES ('876890da-f337-4217-b9bb-30a363ea3a1b', '2005-9-3',
        '2017-2-11', true, '10546498305');
INSERT INTO Processo_Judicial
VALUES ('497bee59-664e-417f-b7ba-a4cb86199ffb', '2006-10-13',
        '2018-4-24', false, '44242360976');
INSERT INTO Processo_Judicial
VALUES ('a83bf51b-5466-4cf7-9762-71d1792e410b', '2004-1-12',
        NULL, false, '38843407263');
INSERT INTO Processo_Judicial
VALUES ('119cb6a6-6d56-4d11-83ec-0087db96ffec', '2018-9-17',
        NULL, false, '67688139935');
INSERT INTO Processo_Judicial
VALUES ('ef8cdcbb-8655-4887-a76e-2756d74c825c', '2004-7-14',
        NULL, true, '40367657486');
INSERT INTO Processo_Judicial
VALUES ('206e24ee-9a39-4823-aa28-2ce56952ff16', '2017-8-15',
        '2021-7-24', true, '21655415012');
INSERT INTO Processo_Judicial
VALUES ('a0953640-cf43-4cfd-8174-c4a84e3259a4', '2020-8-3',
        NULL, true, '85294869835');
INSERT INTO Processo_Judicial
VALUES ('e3373620-0512-4973-b9f1-d9b6ee601adc', '2005-2-11',
        '2016-12-16', false, '79990477925');
INSERT INTO Processo_Judicial
VALUES ('a898487e-0edd-4a7c-9b2e-2ee05fbf019a', '2009-5-2',
        '2019-6-5', false, '28251362228');
INSERT INTO Processo_Judicial
VALUES ('7a41dba5-a70b-436b-a936-19eaf58a59c8', '2020-5-19',
        '2017-12-7', true, '16016930101');
INSERT INTO Processo_Judicial
VALUES ('81700e14-dd20-4630-8149-e3882174ba8d', '2007-6-15',
        '2018-4-19', true, '28437440353');
INSERT INTO Processo_Judicial
VALUES ('47dba908-2f54-4b76-b70c-4377c9eee1b3', '2004-10-12',
        NULL, false, '65601518931');
INSERT INTO Processo_Judicial
VALUES ('986a91a8-569f-4065-bf20-fe28067a61e2', '2006-11-10',
        NULL, false, '62333358894');
INSERT INTO Processo_Judicial
VALUES ('fb2b9620-b537-4098-88f5-db9173052466', '2004-6-11',
        '2020-7-7', false, '24567704398');
INSERT INTO Processo_Judicial
VALUES ('075f4979-4212-472d-a2d7-221ad3939fd7', '2016-10-5',
        '2019-11-7', true, '44441414789');
INSERT INTO Processo_Judicial
VALUES ('9900edc3-3f2b-48b7-a70b-02291c229222', '2015-8-3',
        NULL, false, '61750890677');
INSERT INTO Processo_Judicial
VALUES ('3741b541-798a-4e98-b5bd-33521e1f7621', '2019-2-3',
        '2021-7-22', true, '66001942080');
INSERT INTO Processo_Judicial
VALUES ('ce3864d5-005f-4d08-8c60-6830e9ff18e1', '2005-11-28',
        NULL, false, '18472580276');
INSERT INTO Processo_Judicial
VALUES ('e1a02704-b780-4f7d-8ae2-0cee4964b4ac', '2019-1-15',
        '2020-4-26', false, '81112522231');
INSERT INTO Processo_Judicial
VALUES ('bc126a6e-d621-4a81-92f2-80fa5127bded', '2014-5-22',
        NULL, true, '15456776062');
INSERT INTO Processo_Judicial
VALUES ('e39a1a13-df30-4903-b0e7-57937893316c', '2006-8-4',
        NULL, false, '64313026478');
INSERT INTO Processo_Judicial
VALUES ('ea696569-3c05-4472-b756-6a8f6885ed02', '2014-4-15',
        '2021-5-2', false, '68579267167');
INSERT INTO Processo_Judicial
VALUES ('9c1a8e38-7387-4b0f-95ed-ca38c9f33a97', '2007-1-9',
        '2017-10-15', true, '99047559711');
INSERT INTO Processo_Judicial
VALUES ('249304ff-372d-4a7b-9af4-957f40a5c31d', '2009-9-11',
        NULL, false, '30731319272');
INSERT INTO Processo_Judicial
VALUES ('5c8c219f-beab-4158-8ff3-f1481366e464', '2017-2-28',
        NULL, true, '97948715968');
INSERT INTO Processo_Judicial
VALUES ('05bd27e9-249b-4af2-b049-6c8eca638b77', '2006-10-18',
        NULL, false, '97664171834');
INSERT INTO Processo_Judicial
VALUES ('cf5d188f-951b-4e49-b891-02e5c75863f6', '2009-9-3',
        '2017-7-11', false, '23571120649');
INSERT INTO Processo_Judicial
VALUES ('1ca0a18d-7d24-4855-baf9-503f87c2f9c0', '2011-10-17',
        NULL, true, '78677525506');
INSERT INTO Processo_Judicial
VALUES ('f92a06cd-84fd-4343-ae41-fda861cf67fa', '2009-3-21',
        NULL, true, '13409115150');
INSERT INTO Processo_Judicial
VALUES ('55c3482c-405b-4b73-b981-c46bc1eaf2bf', '2002-6-4',
        NULL, true, '90039808077');
INSERT INTO Processo_Judicial
VALUES ('2032e12d-0449-4a21-aa7b-e139cfc17be0', '2011-12-19',
        '2020-1-11', false, '21988119990');
INSERT INTO Processo_Judicial
VALUES ('791ee9af-5ff5-4c12-b799-5d9c1d9252d6', '2015-2-11',
        '2020-4-13', true, '62330017092');
INSERT INTO Processo_Judicial
VALUES ('793d017a-841a-4152-a74d-aeee4a617444', '2003-9-8',
        NULL, true, '64631355758');
INSERT INTO Processo_Judicial
VALUES ('7945d8b4-c0cd-48a0-9973-ef61c54b17b2', '2003-5-23',
        '2018-1-3', true, '78064916469');
INSERT INTO Processo_Judicial
VALUES ('5ca81542-8e87-474b-a739-bada600146cf', '2009-10-28',
        NULL, false, '83672753747');
INSERT INTO Processo_Judicial
VALUES ('a936f672-df15-4204-a165-a555a98eaa36', '2006-9-4',
        '2021-8-13', false, '74082964621');
INSERT INTO Processo_Judicial
VALUES ('c9a63376-aab4-4a9f-82b3-9add433e5b48', '2015-8-18',
        '2016-12-18', true, '97844949536');
INSERT INTO Processo_Judicial
VALUES ('8d470ecf-ad9c-4910-b07a-e0c72a03e72c', '2020-1-8',
        NULL, false, '26316265854');
INSERT INTO Processo_Judicial
VALUES ('e733227a-1277-4ce5-b662-e17e8a4fe6f8', '2015-9-10',
        '2021-11-5', true, '64449079392');
INSERT INTO Processo_Judicial
VALUES ('addbdcd4-107d-437a-936c-a4969aee48e6', '2017-3-25',
        '2018-4-28', true, '54927417181');
INSERT INTO Processo_Judicial
VALUES ('d102af05-59bb-4f50-92e4-068c7830f762', '2016-11-24',
        '2017-12-3', true, '33628560900');
INSERT INTO Processo_Judicial
VALUES ('dd5979c7-c2ab-4f92-b71c-1841be9b1265', '2018-3-24',
        '2018-12-12', true, '52037642614');
INSERT INTO Processo_Judicial
VALUES ('34ca64f7-fe37-486e-8477-8ce25e2ffae1', '2018-7-7',
        '2021-5-17', true, '61664271336');
INSERT INTO Processo_Judicial
VALUES ('e15478e2-75e3-4119-875a-f326e80e1d48', '2005-9-15',
        NULL, true, '77011687273');
INSERT INTO Processo_Judicial
VALUES ('e7cf25f5-e6d5-4781-8970-b21c5037d395', '2015-11-26',
        '2018-12-23', false, '89658641323');
INSERT INTO Processo_Judicial
VALUES ('8a1ee1c0-874d-4f31-baa0-6f939142100c', '2009-5-20',
        '2018-5-5', true, '93748753082');
INSERT INTO Processo_Judicial
VALUES ('3836651e-2858-4dc5-92ec-35f4b98a1d00', '2008-11-30',
        '2017-6-2', false, '30055465318');
INSERT INTO Processo_Judicial
VALUES ('b41da8ee-7664-4019-b780-1cfc5657207e', '2006-12-9',
        '2017-11-8', true, '72196090049');
INSERT INTO Processo_Judicial
VALUES ('c227ea27-192f-425d-9eb6-21542d0885bf', '2018-9-20',
        NULL, false, '32333718526');
INSERT INTO Processo_Judicial
VALUES ('64767ddb-512c-4957-ad21-efbcf08b9084', '2014-10-2',
        NULL, false, '16176439919');
INSERT INTO Processo_Judicial
VALUES ('271a5e48-eb0c-4f6d-a754-39348d96265c', '2011-2-20',
        NULL, true, '80145377612');
INSERT INTO Processo_Judicial
VALUES ('7b144e81-29c0-429b-8f6b-2eb92247379b', '2011-2-10',
        '2018-12-17', true, '27899335727');
INSERT INTO Processo_Judicial
VALUES ('ebc1d892-c058-424d-b417-54448b81323c', '2007-11-12',
        NULL, false, '64449079392');
INSERT INTO Processo_Judicial
VALUES ('bce77e08-9cba-4202-9f18-4f0162af041a', '2013-5-26',
        NULL, false, '15525305538');
INSERT INTO Processo_Judicial
VALUES ('35be8cbd-bdea-43e5-9577-156a5cd21caa', '2011-4-30',
        NULL, false, '60372715506');
INSERT INTO Processo_Judicial
VALUES ('3aaf6e10-a474-4127-a0b0-4ba976fa7aa2', '2014-9-22',
        '2021-9-7', true, '41530032556');
INSERT INTO Processo_Judicial
VALUES ('6ded7181-6106-4f6f-9fcf-7aace7d44608', '2008-10-8',
        NULL, false, '66367407455');
INSERT INTO Processo_Judicial
VALUES ('a27c8db9-9b8e-4013-9d38-983015f4f8fd', '2003-4-8',
        '2019-7-12', false, '30624507255');
INSERT INTO Processo_Judicial
VALUES ('8ea0b099-eca4-4cf0-9ed5-0f0b13fb660c', '2021-11-19',
        NULL, true, '12408964524');
INSERT INTO Processo_Judicial
VALUES ('5e62e070-4412-41aa-a9fc-9e34de62a93b', '2015-8-18',
        NULL, true, '90722480562');
INSERT INTO Processo_Judicial
VALUES ('998b2b0c-86af-4609-ae76-42b75262988d', '2019-11-28',
        NULL, false, '52057552337');
INSERT INTO Processo_Judicial
VALUES ('ee55f630-156a-42cd-889f-25a72fc752d6', '2003-1-16',
        NULL, true, '71670214808');
INSERT INTO Processo_Judicial
VALUES ('9f2ff0fb-a741-4690-a02c-dce73ea8e231', '2007-6-2',
        '2017-3-29', true, '52877239394');
INSERT INTO Processo_Judicial
VALUES ('768acdb2-669c-4c3d-a575-9c758b5b018b', '2017-3-27',
        NULL, true, '42681556036');
INSERT INTO Processo_Judicial
VALUES ('98ae34dd-ed56-4713-8d17-86fdd528a150', '2006-9-15',
        '2018-9-10', true, '42666099744');
INSERT INTO Processo_Judicial
VALUES ('10eb1517-6f79-4348-ad40-9df1b655a3a5', '2014-10-13',
        '2018-1-22', false, '64631355758');
INSERT INTO Processo_Judicial
VALUES ('722c8eb9-3a8c-45ed-913c-fb235e444f99', '2013-6-28',
        '2017-1-13', false, '40160910950');
INSERT INTO Processo_Judicial
VALUES ('0e91bd10-0227-4861-8549-449d81dccf0a', '2006-2-26',
        NULL, false, '23369654125');
INSERT INTO Processo_Judicial
VALUES ('5c9d467b-eff4-4edd-ab67-138f0a91f413', '2012-3-11',
        NULL, true, '81107487515');
INSERT INTO Processo_Judicial
VALUES ('1accb4df-4fd2-49eb-b024-aa2215a41264', '2003-10-20',
        NULL, false, '98488777014');
INSERT INTO Processo_Judicial
VALUES ('603d3fc9-2a8a-4a62-aa4a-70dd7a11ecdf', '2010-3-29',
        NULL, false, '19451177760');
INSERT INTO Processo_Judicial
VALUES ('cd3ad6af-af1e-461f-9d2d-1f8e963c10d5', '2019-6-19',
        NULL, true, '29555345340');
INSERT INTO Processo_Judicial
VALUES ('5203fef1-de9a-4d9a-b1c3-f11c020c74f4', '2010-11-16',
        NULL, true, '46842239857');
INSERT INTO Processo_Judicial
VALUES ('1eed8823-e71c-418b-ad28-b6edc8804271', '2002-4-30',
        NULL, true, '32021542380');
INSERT INTO Processo_Judicial
VALUES ('404f48ba-383f-463f-bc8e-9a86e334dcea', '2016-11-8',
        NULL, true, '64122301510');
INSERT INTO Processo_Judicial
VALUES ('581df1f5-51e9-46c4-b207-28ab6bb571f5', '2006-1-20',
        NULL, false, '83590763018');
INSERT INTO Processo_Judicial
VALUES ('f52b7843-4975-4e3a-ba84-3ff2d3b624d5', '2020-1-8',
        NULL, false, '29610695552');
INSERT INTO Processo_Judicial
VALUES ('a59ec6b6-66e5-4954-9142-db7c831c8ebd', '2007-4-5',
        '2021-5-26', false, '83222212893');
INSERT INTO Processo_Judicial
VALUES ('d57854c9-3c0b-4d5b-9f08-afdce6c6fae4', '2018-12-18',
        '2018-1-11', true, '10729401176');
INSERT INTO Processo_Judicial
VALUES ('93c0e8c6-8d68-4dec-97a5-954aaa83399f', '2007-12-4',
        '2020-5-4', true, '90524761965');
INSERT INTO Processo_Judicial
VALUES ('184225c8-c722-41ce-82c2-9a7aa69e50d9', '2015-10-25',
        NULL, true, '36747011074');
INSERT INTO Processo_Judicial
VALUES ('d7f56126-dd53-445e-8995-1ab3dc50c7ea', '2004-3-1',
        '2017-8-10', true, '34965334206');
INSERT INTO Processo_Judicial
VALUES ('31087fe0-a32b-4b2c-9963-7686285a9418', '2020-5-22',
        NULL, false, '30057355521');
INSERT INTO Processo_Judicial
VALUES ('8a4b7d9b-5679-40ed-b7ab-a787aafd5e40', '2008-9-7',
        NULL, true, '12626151097');
INSERT INTO Processo_Judicial
VALUES ('e3233f0d-9185-42eb-a5f3-210045ffb380', '2012-3-10',
        '2019-5-21', false, '51938838479');
INSERT INTO Processo_Judicial
VALUES ('a25ae80b-d18f-46a4-a019-d1680295c246', '2004-9-17',
        NULL, true, '88249640718');
INSERT INTO Processo_Judicial
VALUES ('e49ac437-f6cd-49e9-a861-6439f578699b', '2009-8-16',
        '2019-6-22', false, '39470596222');
INSERT INTO Processo_Judicial
VALUES ('3e0c2775-124a-4652-95a3-c2f93bf43b48', '2019-2-11',
        '2021-1-20', true, '27553708830');
INSERT INTO Processo_Judicial
VALUES ('16345b0a-e486-420e-a430-ce185e9f1347', '2015-2-3',
        NULL, true, '97844949536');
INSERT INTO Processo_Judicial
VALUES ('27445805-c636-455d-adb1-165bdeefe6d3', '2020-2-19',
        '2020-1-3', false, '48617187398');
INSERT INTO Processo_Judicial
VALUES ('950a89d6-d923-4030-8ba4-1fb266bc4a48', '2005-12-15',
        '2020-8-4', false, '70796429398');
INSERT INTO Processo_Judicial
VALUES ('45438636-c323-4750-80ac-e50a606706cc', '2007-1-20',
        '2017-8-10', true, '47322499984');
INSERT INTO Processo_Judicial
VALUES ('0511c693-84f5-4b5d-ba6a-4ac648abaf62', '2003-2-18',
        '2018-6-19', true, '83225498516');
INSERT INTO Processo_Judicial
VALUES ('8d3bd8b3-1d2c-4139-a670-81830d2fafbf', '2007-7-11',
        NULL, false, '95178695621');
INSERT INTO Processo_Judicial
VALUES ('bb1b1382-6536-4790-a170-a5644e2747f1', '2021-5-13',
        '2021-3-25', false, '87312114937');
INSERT INTO Processo_Judicial
VALUES ('9ba963cc-2c28-490b-806a-a260ca40f443', '2013-11-14',
        '2019-7-21', true, '23369654125');
INSERT INTO Processo_Judicial
VALUES ('5f5104ee-a477-4ab4-ad63-c87f426f9167', '2005-10-6',
        NULL, false, '23965377714');
INSERT INTO Processo_Judicial
VALUES ('bea274c4-6ceb-408f-aab4-ebfed3982fb2', '2002-11-30',
        NULL, true, '12408964524');
INSERT INTO Processo_Judicial
VALUES ('4891ebe0-2ae2-49b5-a8f2-87885ab84c6c', '2013-7-12',
        '2017-2-12', false, '70054730942');
INSERT INTO Processo_Judicial
VALUES ('771b5134-7cfb-4d92-8f16-bb3fa8cf72da', '2014-8-19',
        '2020-5-17', false, '46791838572');
INSERT INTO Processo_Judicial
VALUES ('b5c85d73-0001-47ec-8d57-ae0f6f0226fa', '2016-5-24',
        NULL, true, '56392080958');
INSERT INTO Processo_Judicial
VALUES ('5cbd7f3c-5c58-47bd-83ac-31032f941c26', '2003-8-20',
        '2019-1-14', false, '60892811592');
INSERT INTO Processo_Judicial
VALUES ('9995df87-b10f-4a96-95a3-52cf75cdba39', '2012-9-27',
        '2018-10-27', true, '35013815364');
INSERT INTO Processo_Judicial
VALUES ('dfba8d5b-f59d-4655-8d1f-8d6dab61757d', '2011-1-29',
        '2020-4-6', false, '19629932825');
INSERT INTO Processo_Judicial
VALUES ('16a8daea-8e32-4d22-8db5-418bd0d83b0a', '2016-2-26',
        NULL, false, '85063207736');
INSERT INTO Processo_Judicial
VALUES ('8536ab9c-d629-42ba-94cb-512c058a1c66', '2005-12-28',
        NULL, true, '86202337315');
INSERT INTO Processo_Judicial
VALUES ('15f16a06-aafe-4026-8436-f8fb9641c1dc', '2005-10-26',
        '2017-6-17', false, '28691501056');
INSERT INTO Processo_Judicial
VALUES ('ee73d5ea-1f77-47f0-ba69-deb2381313fb', '2013-6-16',
        '2021-4-7', false, '83326663854');
INSERT INTO Processo_Judicial
VALUES ('ffd81dc4-cd74-496a-a2a0-73b8d9fa2a84', '2016-6-14',
        '2020-12-26', true, '27809734062');
INSERT INTO Processo_Judicial
VALUES ('0d77a2a8-17f3-4e4c-b1d9-8eb51aa1e421', '2019-12-18',
        '2021-6-25', true, '52849328536');
INSERT INTO Processo_Judicial
VALUES ('444a40b9-0e89-47da-a03b-ca23ffe14bfc', '2015-1-14',
        '2021-3-22', true, '85431055435');
INSERT INTO Processo_Judicial
VALUES ('4bf58fe5-4396-4e59-9ced-2c24a6a1f5bb', '2018-2-2',
        '2019-5-13', true, '62644287729');
INSERT INTO Processo_Judicial
VALUES ('67a23214-df36-45ef-a90b-a79b59ad8c54', '2017-2-18',
        NULL, true, '48407140278');
INSERT INTO Processo_Judicial
VALUES ('ea157a0d-3326-4298-b678-bf7b4a6384ff', '2015-12-17',
        '2021-2-14', false, '45841697754');
INSERT INTO Processo_Judicial
VALUES ('f0b4d9a9-699f-4372-befc-d91394ed2d87', '2003-7-17',
        NULL, false, '86344928094');
INSERT INTO Processo_Judicial
VALUES ('2cd79552-741a-43fd-bb93-cde46310cc55', '2002-10-18',
        '2020-4-22', true, '68421083828');
INSERT INTO Processo_Judicial
VALUES ('cb747533-17fe-405c-9c04-3bfe2b9e5b56', '2006-8-13',
        '2020-11-19', false, '16535910640');
INSERT INTO Processo_Judicial
VALUES ('63924a38-6898-4be3-a005-773e3aff8b80', '2005-6-24',
        '2017-4-21', true, '50989122078');
INSERT INTO Processo_Judicial
VALUES ('1f88c830-6491-4d76-bd25-51ad00b9d389', '2009-6-7',
        '2017-12-5', false, '16140814840');
INSERT INTO Processo_Judicial
VALUES ('2f201500-00ff-4a1e-be87-88372d5d56f4', '2004-12-30',
        '2018-6-12', true, '21959062153');
INSERT INTO Processo_Judicial
VALUES ('b06f9424-18cc-46fc-8aff-831aaecd27a9', '2009-9-30',
        NULL, false, '96970153856');
INSERT INTO Processo_Judicial
VALUES ('6e53a611-99d4-4d0f-927b-1d359ba90b1a', '2015-5-22',
        '2020-10-16', true, '69042728620');
INSERT INTO Processo_Judicial
VALUES ('743d5eba-34cd-4daa-ae91-7556944b2a42', '2015-2-28',
        NULL, true, '31080767794');
INSERT INTO Processo_Judicial
VALUES ('02f424a4-95f7-40bb-9fe8-885cbb34fbe7', '2019-6-3',
        NULL, false, '89395024664');
INSERT INTO Processo_Judicial
VALUES ('c1f4a909-a21e-4c9c-98f6-c929188f0a0c', '2013-9-25',
        '2019-10-27', false, '49993791026');
INSERT INTO Processo_Judicial
VALUES ('b1b719e8-dede-4ec7-b054-ca7f194e96d7', '2016-10-28',
        '2021-6-25', true, '60391245295');
INSERT INTO Processo_Judicial
VALUES ('e2ad1b7d-d96b-460b-b7a1-45ad790b2176', '2006-12-20',
        NULL, true, '41701333993');
INSERT INTO Processo_Judicial
VALUES ('2de55537-0f08-41b0-98b4-15be3935b690', '2005-6-2',
        '2020-4-23', false, '16716102720');
INSERT INTO Processo_Judicial
VALUES ('52e67b34-65ac-4f1c-9917-6ec6fa6df5ba', '2008-7-10',
        '2020-11-4', true, '59381403052');
INSERT INTO Processo_Judicial
VALUES ('4e200baa-270e-4239-b16a-8097a5195941', '2004-7-30',
        NULL, true, '66001942080');
INSERT INTO Processo_Judicial
VALUES ('530e54a6-6a8a-4680-b405-3ec554291903', '2010-1-25',
        '2017-12-27', true, '41031348041');
INSERT INTO Processo_Judicial
VALUES ('5bae3bd1-d0e6-42fd-bbbe-580951184339', '2007-6-29',
        '2019-8-24', false, '80710820276');
INSERT INTO Processo_Judicial
VALUES ('16274b5b-c102-48de-8f46-97001403ca25', '2005-11-23',
        NULL, false, '35014395120');
INSERT INTO Processo_Judicial
VALUES ('1ff04eb0-5f9c-40aa-a707-aecb20ce706f', '2010-6-5',
        '2017-9-23', true, '40396111428');
INSERT INTO Processo_Judicial
VALUES ('8ec5fafd-7c6e-4639-8cca-bb119da7a5fa', '2010-3-21',
        '2020-1-23', false, '53485558112');
INSERT INTO Processo_Judicial
VALUES ('27673817-dfa0-4813-aef1-676f4e539331', '2017-7-15',
        NULL, false, '84909864924');
INSERT INTO Processo_Judicial
VALUES ('a0264653-4815-4423-970b-0459042d441c', '2019-2-7',
        NULL, true, '68425539585');
INSERT INTO Processo_Judicial
VALUES ('d053d470-521f-429b-abda-26dbe385d90c', '2010-10-30',
        '2017-3-27', true, '20926508598');
INSERT INTO Processo_Judicial
VALUES ('ff80ada2-c421-4755-9e43-cfec2121795e', '2007-3-21',
        '2021-7-11', false, '38337135156');
INSERT INTO Processo_Judicial
VALUES ('bd25c5a4-35a1-48d1-a95f-26eff3eb81b3', '2009-12-26',
        '2021-9-29', true, '69868170775');
INSERT INTO Processo_Judicial
VALUES ('028cf551-b7fb-4db8-bfe6-93b6dadb6f06', '2004-7-12',
        '2019-8-13', false, '56571923072');
INSERT INTO Processo_Judicial
VALUES ('66ab8f71-3718-4045-a26a-1fb97cb58c26', '2004-8-1',
        NULL, false, '81749686598');
INSERT INTO Processo_Judicial
VALUES ('a71c9bb8-f9c5-42a1-8ae8-2afd0d19af68', '2016-4-15',
        '2017-8-24', true, '62330017092');
INSERT INTO Processo_Judicial
VALUES ('b263f9c5-e471-4a68-883a-9e9062be7e28', '2020-2-23',
        NULL, true, '87706230955');
INSERT INTO Processo_Judicial
VALUES ('750555c3-fb7a-4003-8e20-b0c65de69bcf', '2010-8-24',
        NULL, true, '67893272326');
INSERT INTO Processo_Judicial
VALUES ('1b30675b-732f-44cd-b83c-34732594fd12', '2020-1-12',
        NULL, true, '26153816252');
INSERT INTO Processo_Judicial
VALUES ('4551ffdc-4333-4a8d-80db-3c9255515d71', '2009-6-16',
        NULL, true, '24439672860');
INSERT INTO Processo_Judicial
VALUES ('808ece9a-68dd-43ad-bc89-d5dc71fe410e', '2020-10-7',
        '2017-12-29', false, '16630750785');
INSERT INTO Processo_Judicial
VALUES ('3c8bb93d-0699-4829-a090-b6bf5c678999', '2006-3-19',
        '2021-4-6', false, '91491590670');
INSERT INTO Processo_Judicial
VALUES ('14031940-4d25-49d5-9bd4-29b721d9d239', '2002-4-8',
        '2021-8-5', true, '42580829826');
INSERT INTO Processo_Judicial
VALUES ('d320ea81-b29a-4e99-9591-623d1a9601f2', '2016-10-6',
        NULL, true, '10814941977');
INSERT INTO Processo_Judicial
VALUES ('8d6256f6-7ff6-4667-aea9-e2e347ac7631', '2015-8-3',
        NULL, false, '51767491549');
INSERT INTO Processo_Judicial
VALUES ('a74df462-fb4a-47df-93c2-5446e77bba0e', '2012-1-8',
        '2019-9-20', true, '78491106405');
INSERT INTO Processo_Judicial
VALUES ('b0d8aa96-3df0-4e64-abd1-4c003bdfaa70', '2001-12-25',
        NULL, false, '71410878263');
INSERT INTO Processo_Judicial
VALUES ('0c035a81-7906-4c36-a678-778736ec982f', '2021-2-26',
        NULL, false, '74298426869');
INSERT INTO Processo_Judicial
VALUES ('7e57d4c7-7a0f-4a46-bdc3-d91d77db7c56', '2014-9-13',
        '2019-10-18', false, '29649122953');
INSERT INTO Processo_Judicial
VALUES ('cd7b2392-e738-4bc2-b545-39393f70ba80', '2018-7-12',
        NULL, false, '45732964542');
INSERT INTO Processo_Judicial
VALUES ('28e7640e-b4e3-47e9-a7e1-c29320031a8e', '2008-7-31',
        NULL, false, '31581937542');
INSERT INTO Processo_Judicial
VALUES ('65a71fc2-44ab-40e7-ac84-029e1c187440', '2003-12-31',
        NULL, true, '87482139978');
INSERT INTO Processo_Judicial
VALUES ('bc232559-f9b3-4b84-a941-8e75d8931127', '2018-12-11',
        '2020-1-31', false, '52205724709');
INSERT INTO Processo_Judicial
VALUES ('cec5a96e-42a6-4f80-956e-4d57e5f6534b', '2012-9-5',
        '2018-1-31', true, '94493685548');
INSERT INTO Processo_Judicial
VALUES ('8fc68b7a-d512-4690-b8db-f420bb68dc8c', '2017-5-9',
        NULL, false, '13749101529');
INSERT INTO Processo_Judicial
VALUES ('d623493e-adeb-4b59-abce-188797903777', '2002-1-19',
        '2020-7-21', true, '89653281683');
INSERT INTO Processo_Judicial
VALUES ('759d3a0e-ca82-4f0b-b8cf-ea62d8a573c0', '2013-2-13',
        NULL, false, '16354246530');
INSERT INTO Processo_Judicial
VALUES ('04272b05-b075-482f-8cc2-4650fab9e16f', '2012-3-20',
        '2017-2-15', true, '28437440353');
INSERT INTO Processo_Judicial
VALUES ('99da958a-b4f4-48b2-9342-8d0fd3a3866d', '2009-12-21',
        '2021-6-13', false, '57755531829');
INSERT INTO Processo_Judicial
VALUES ('4d44fcfa-af8f-401f-8d88-e2259a66ba84', '2021-11-10',
        NULL, false, '81856962239');
INSERT INTO Processo_Judicial
VALUES ('2da64936-b5be-449e-a7ed-ce23a01dae05', '2020-7-27',
        '2018-1-3', false, '82877426827');
INSERT INTO Processo_Judicial
VALUES ('e3d47a4a-eabb-4d91-9fed-db6347922029', '2019-12-19',
        '2018-12-2', false, '94071586923');
INSERT INTO Processo_Judicial
VALUES ('4f45de04-2d55-4339-aa33-2f0853dc9c26', '2018-12-6',
        NULL, false, '69316593371');
INSERT INTO Processo_Judicial
VALUES ('2764dab5-dedb-4032-94c5-06cc710dba23', '2012-1-3',
        '2018-9-9', false, '57755531829');
INSERT INTO Processo_Judicial
VALUES ('b7abbef1-37f7-487d-a702-f8968a095ead', '2019-1-20',
        '2021-7-24', true, '33670471631');
INSERT INTO Processo_Judicial
VALUES ('83f0b000-ee16-4f89-b22b-532258407df3', '2012-10-6',
        '2020-11-14', true, '68096587185');
INSERT INTO Processo_Judicial
VALUES ('03da9226-6acc-42cc-b6fb-dbe762e52e72', '2018-7-10',
        '2019-9-8', false, '88774482219');
INSERT INTO Processo_Judicial
VALUES ('e09945fd-3fb1-47fc-9f28-cb844289ff32', '2020-9-1',
        '2021-5-12', true, '83035852278');
INSERT INTO Processo_Judicial
VALUES ('675b7dda-9dfa-41d1-bd12-839815e134fa', '2019-5-22',
        NULL, true, '50722760849');
INSERT INTO Processo_Judicial
VALUES ('9fe67377-3ccc-4eb5-9a3e-7d8b8749693e', '2012-9-16',
        '2018-2-4', true, '14018435610');
INSERT INTO Processo_Judicial
VALUES ('d04d0c9a-489f-4185-814c-39ae6fda9c66', '2010-6-5',
        '2018-12-29', true, '20341535366');
INSERT INTO Processo_Judicial
VALUES ('29356676-9b58-4900-b1da-62e31f4d752e', '2018-10-29',
        '2021-4-20', true, '14172927623');
INSERT INTO Processo_Judicial
VALUES ('79040d1d-c7dd-4332-96af-625b8634ca93', '2009-12-29',
        '2020-4-27', true, '64122301510');
INSERT INTO Processo_Judicial
VALUES ('38dac494-95a0-4b00-ac44-4093a20ea0e7', '2015-8-9',
        '2021-7-19', true, '36024964263');
INSERT INTO Processo_Judicial
VALUES ('c58fad51-acbd-4ab6-8493-28c22fdffa4c', '2009-3-1',
        '2018-12-28', false, '48150026823');
INSERT INTO Processo_Judicial
VALUES ('b9050622-5204-4a29-abc4-107fb0517ae7', '2001-12-30',
        NULL, false, '27393568651');
INSERT INTO Processo_Judicial
VALUES ('57d1469f-4e0a-472e-8c9b-97bbe5eb3165', '2003-8-9',
        '2020-7-31', false, '94086229731');
INSERT INTO Processo_Judicial
VALUES ('3658adcb-f97f-46eb-8e71-45ba2734e785', '2003-9-13',
        NULL, true, '68110109437');
INSERT INTO Processo_Judicial
VALUES ('8c6453e5-089b-4cb5-aae8-bb4fefe86bcb', '2009-4-21',
        NULL, false, '90524761965');
INSERT INTO Processo_Judicial
VALUES ('a27ffc08-0385-468e-97c7-41566b4c551f', '2020-5-22',
        NULL, true, '44080556528');
INSERT INTO Processo_Judicial
VALUES ('9474db3b-e4a6-426b-8489-d0ff282c3ff1', '2012-5-12',
        NULL, true, '74884315195');
INSERT INTO Processo_Judicial
VALUES ('a83db96c-0d6c-4939-9671-04c64808e4c4', '2007-10-17',
        '2017-3-7', true, '17678079477');
INSERT INTO Processo_Judicial
VALUES ('9eb209b8-7e5f-47b2-a60f-4d9f3e7e9a60', '2019-2-17',
        NULL, true, '79860785743');
INSERT INTO Processo_Judicial
VALUES ('f9399f62-12f8-47a4-aa92-d2d9a8785ec2', '2002-5-12',
        NULL, true, '13439644786');
INSERT INTO Processo_Judicial
VALUES ('ba3cf808-7a1c-47d2-97d4-ae7d4917ecf0', '2008-7-25',
        NULL, false, '48280321999');
INSERT INTO Processo_Judicial
VALUES ('904d5a86-3656-482e-836f-a81c051493fc', '2008-9-27',
        '2019-7-23', false, '27577754918');
INSERT INTO Processo_Judicial
VALUES ('f1ee0e21-0562-4779-a330-df8a72d4c42f', '2011-4-28',
        NULL, false, '98488777014');
INSERT INTO Processo_Judicial
VALUES ('d47bf1da-8c13-4045-a092-b375846225e5', '2006-7-6',
        '2020-8-2', false, '26209410189');
INSERT INTO Processo_Judicial
VALUES ('bfc00da7-e200-4382-a2b5-8151480d091e', '2017-12-18',
        NULL, false, '29555345340');
INSERT INTO Processo_Judicial
VALUES ('6d861bcf-6eae-44f8-aeb2-0f177d1774ad', '2011-1-3',
        NULL, false, '17678079477');
INSERT INTO Processo_Judicial
VALUES ('fcc0d94c-c855-4bc6-893e-3db6612b4edb', '2018-9-3',
        NULL, true, '15456776062');
INSERT INTO Processo_Judicial
VALUES ('98ec1b41-b1fd-461a-87ed-7d81b45152ca', '2002-10-6',
        NULL, false, '17156520811');
INSERT INTO Processo_Judicial
VALUES ('68d01944-91ed-4c70-918f-34046e47f8ca', '2004-11-24',
        NULL, true, '10190151415');
INSERT INTO Processo_Judicial
VALUES ('aaab52fe-d835-476e-9593-b298fff52933', '2018-3-27',
        '2017-2-23', true, '36323933107');
INSERT INTO Processo_Judicial
VALUES ('ed56ef54-f85a-4050-a84b-a4ab29cb6a00', '2015-4-15',
        NULL, false, '84441573002');
INSERT INTO Processo_Judicial
VALUES ('952309cc-724e-439c-a377-b8a460123903', '2010-5-17',
        '2021-4-13', false, '47783979305');
INSERT INTO Processo_Judicial
VALUES ('dd08ebd4-6466-418a-abcf-b2423d06798a', '2015-9-26',
        '2017-4-28', true, '56274953270');
INSERT INTO Processo_Judicial
VALUES ('08f57484-5dc6-409e-bee3-c2b2acb681a0', '2013-2-23',
        '2019-1-19', false, '73877129219');
INSERT INTO Processo_Judicial
VALUES ('86088e26-6c04-4ceb-8435-cb8ae85d1e1c', '2016-10-22',
        '2019-8-19', false, '28005878622');
INSERT INTO Processo_Judicial
VALUES ('8f79a4b7-ec61-4646-8c81-578e63404a7a', '2018-2-9',
        NULL, true, '50137497729');
INSERT INTO Processo_Judicial
VALUES ('7f1ba76c-ec50-43c4-b7d8-a702bf7f164f', '2020-8-17',
        NULL, true, '16300685813');
INSERT INTO Processo_Judicial
VALUES ('f8ffc22f-d23e-4ab9-afed-7e1098883a69', '2010-3-18',
        '2017-11-21', false, '17017262971');
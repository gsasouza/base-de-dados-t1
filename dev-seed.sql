CREATE TABLE Programas_Partido
(
    ID_Programa int,
    Versao      int  NOT NULL,
    Data        DATE NOT NULL,
    CONSTRAINT PK_ID_PROGRAMA PRIMARY KEY (ID_Programa)
);

CREATE TABLE Partidos
(
    Nro_partido   int,
    Sigla         VARCHAR(2)   NOT NULL,
    --Deferencia
    Nome          VARCHAR(255) NOT NULL,
    Pres_Nacional VARCHAR(255) NOT NULL,
    Data_fund     DATE         NOT NULL,
    Programa      int,
    CONSTRAINT PK_NRO_PARTIDO PRIMARY KEY (Nro_partido),
    CONSTRAINT FK_PROGRAMA FOREIGN KEY (Programa) REFERENCES Programas_Partido (ID_Programa)
);

CREATE TABLE Cargos
(
    Cod_cargo          int,
    Nome_cargo         VARCHAR(255) NOT NULL,
    Cidade             VARCHAR(255) NOT NULL,
    Estado             VARCHAR(255) NOT NULL,
    Federacao          VARCHAR(255) NOT NULL,
    Quantidade_eleitos int          NOT NULL,
    CONSTRAINT PK_COD_CARGO PRIMARY KEY (Cod_cargo)
);

CREATE TABLE Pessoas
(
    Nro_Tit_Eleitor int          NOT NULL,
    CPF             DECIMAL(11),
    Nome_Pessoa     VARCHAR(255) NOT NULL,
    End_Pessoa      VARCHAR(255) NOT NULL,
    Escolaridade    VARCHAR(255) NOT NULL,
    Nro_Zona        int          NOT NULL,
    Nro_Secao       int          NOT NULL,
    Situacao_Ficha  VARCHAR(255) NOT NULL,
    CONSTRAINT PK_NRO_TIT_ELEITOR PRIMARY KEY (Nro_tit_eleitor),
    --CONSTRAINT FK_NRO_TIT_ELEITOR FOREIGN KEY (Nro_tit_eleitor) REFERENCES Candidatos(Tit_eleitor),
    --CONSTRAINT PK_CPF PRIMARY KEY (CPF),
    --CONSTRAINT FK_CPF FOREIGN KEY (CPF) REFERENCES Candidatos(CPF),
    CONSTRAINT CK_ESCOLARIDADE CHECK (Escolaridade IN ('sem escolaridade', 'ensino basico concluido', 'ensino medio concluido', 'faculdade concluida', 'mestre', 'doutor', 'PHD')),
    CONSTRAINT CK_FICHA CHECK (Situacao_Ficha IN ('ficha_limpa', 'ficha_suja'))
);



CREATE TABLE Candidatos
(
    ID_candidato   int,
    Tit_eleitor    int,
    CPF            DECIMAL(11),
    RG             DECIMAL(8)   NOT NULL,
    Nome_Candidato VARCHAR(255) NOT NULL,
    Data_Filiacao  DATE         NOT NULL,
    Cod_Cargo      int,
    Nro_Partido    int,
    CONSTRAINT PK_ID_CANDIDATO PRIMARY KEY (ID_candidato),

    CONSTRAINT Candidatos_fk1 FOREIGN KEY (Tit_eleitor) REFERENCES Pessoas (Nro_Tit_eleitor) ON DELETE CASCADE,
    --CONSTRAINT Candidatos_fk2 FOREIGN KEY (CPF) REFERENCES Pessoas(CPF) ON DELETE CASCADE,
    --CONSTRAINT Candidatos_fk1 FOREIGN KEY (Tit_eleitor) REFERENCES Pessoas(Tit_eleitor) ON DELETE CASCADE,
    CONSTRAINT FK_COD_CARGO FOREIGN KEY (Cod_Cargo) REFERENCES Cargos (Cod_Cargo),
    CONSTRAINT FK_NRO_PARTIDO FOREIGN KEY (Nro_Partido) REFERENCES Partidos (Nro_Partido)
);



CREATE TABLE Equipes_de_apoio
(
    ID_Equipe   int,
    Nome_equipe VARCHAR(255) NOT NULL,
    Funcao      VARCHAR(255) NOT NULL,
    CONSTRAINT PK_ID_EQUIPE PRIMARY KEY (ID_Equipe)
    --CONSTRAINT FK_CANDIDATURA FOREIGN KEY (Candidatura) REFERENCES Candidaturas(Nome_Candidatura)
);

CREATE TABLE Processos_Judiciais
(
    Nro_Processo int,
    Autor        VARCHAR(255) NOT NULL,
    Vara_Judicial  VARCHAR(255) NOT NULL,
    Data_inicio  DATE         NOT NULL,
    Status       VARCHAR(20),
    Veredito     VARCHAR(20),
    CONSTRAINT PK_NRO_PROCESSO PRIMARY KEY (Nro_Processo),
    CONSTRAINT CK_STATUS CHECK (Status IN ('em_processo', 'julgado')),
    CONSTRAINT CK_VEREDITO CHECK (Veredito IN ('culpado', 'inocente'))
);

CREATE TABLE Participantes_Equipe
(
    ID_Participante int,
    Funcao          VARCHAR(255) NOT NULL,
    CONSTRAINT PK_PARTICIPANTE PRIMARY KEY (ID_Participante) --,
    --CONSTRAINT PK_CPF PRIMARY KEY (CPF),
    --CONSTRAINT FK_CPF FOREIGN KEY (CPF) REFERENCES Pessoas(CPF),
    --CONSTRAINT FK_NOME FOREIGN KEY (Nome) REFERENCES Pessoas(Nome)
);

CREATE TABLE Doadores_Campanha
(
    ID_Doador   int,
    CNPJ_Doador DECIMAL(14),
    Nome_Doador VARCHAR(255),
    Valor       int  NOT NULL,
    Data        DATE NOT NULL,
    CONSTRAINT PK_ID_DOADOR PRIMARY KEY (ID_Doador)--,
    --CONSTRAINT FK_CPF_DOADOR FOREIGN KEY (CPF_Doador) REFERENCES Pessoas(CPF),
    --CONSTRAINT FK_CAMPANHA FOREIGN KEY (Campanha) REFERENCES Candidaturas(Nome_Candidatura)
);


CREATE TABLE Pleitos_eleicao
(
    Cargo            int,
    Ano_Pleito       DATE,
    Local            VARCHAR(255),
    Quantidade_Votos int NOT NULL,
    CONSTRAINT PK_ANO_PLEITO PRIMARY KEY (Ano_Pleito),
    --CONSTRAINT PK_CARGO PRIMARY KEY (Cargo),
    CONSTRAINT FK_CARGO FOREIGN KEY (Cargo) REFERENCES Cargos (Cod_Cargo) --,
    --CONSTRAINT PK_LOCAL PRIMARY KEY (Local)
);


/*Para apagar as tabelas use a sequencia abaixo:

DROP TABLE candidatos
DROP TABLE equipes_de_apoio
DROP TABLE doadores_campanha
DROP TABLE participantes_equipe
DROP TABLE partidos
DROP TABLE pleitos_eleicao
DROP TABLE cargos
DROP TABLE processos_judiciais
DROP TABLE programas_partido
DROP TABLE pessoas*/
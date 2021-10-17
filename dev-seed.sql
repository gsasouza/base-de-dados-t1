-- DROP
-- TABLE Candidate;

CREATE TABLE Candidate
(
    name   VARCHAR(100) NOT NULL,
    number NUMERIC(10)  NOT NULL,

    CONSTRAINT candidate_pk PRIMARY KEY (name),
    CONSTRAINT candidate_un UNIQUE (name)
);

INSERT INTO Candidate
VALUES ('NOME 1', '22');
INSERT INTO Candidate
VALUES ('NOME 2', '17');
INSERT INTO Candidate
VALUES ('NOME 3', '12');
const Faker = require('faker/locale/pt_BR')
const fs = require("fs");

const formatDate = (date: Date) => `${date.getFullYear()}-${date.getMonth() + 1}-${date.getDate()}`;

class Pessoa {
  CPF: string;
  private readonly Titulo_Eleitor: string;
  private readonly Nome: string;
  private readonly Endereco: string;
  private readonly Escolaridade: string;

  constructor() {
    this.CPF = Faker.datatype.number({
      min: 10000000000,
      max: 99999999999
    }).toString()
    this.Titulo_Eleitor = Faker.datatype.number({
      min: 100000000000,
      max: 999999999999
    }).toString()
    this.Nome = `${Faker.name.firstName()} ${Faker.name.lastName()}`
    this.Endereco = `${Faker.address.streetName().replaceAll(`'`, '')}, ${Faker.datatype.number()}, ${Faker.address.city().replaceAll(`'`, '')}, ${Faker.address.stateAbbr().replaceAll(`'`, '')}`;
    this.Escolaridade = Faker.random.arrayElement(['analfabeto', '1 grau completo', '2 grau incompleto',
      '2 grau completo', 'superior incompleto', 'superior completo', 'pos-graduação',
      'mestrado', 'doutorado'])
  }

  toSQL = () => `INSERT INTO Pessoa
                 VALUES ('${this.CPF}', '${this.Titulo_Eleitor}', '${this.Nome}', '${this.Endereco}',
                         '${this.Escolaridade}');`
}

class Partido {
  Sigla: string;
  private readonly Nome: string;
  private readonly CPF_Predidente: string;
  private readonly Data_Fundacao: string;
  private readonly ID_Programa: string

  constructor(sigla: string, nome: string, cpf_presidente: string, programa: string) {
    this.Sigla = sigla;
    this.Nome = nome;
    this.CPF_Predidente = cpf_presidente;
    this.Data_Fundacao = formatDate(Faker.date.past(25))
    this.ID_Programa = programa
  }

  toSQL = () => `INSERT INTO Partido
                 VALUES ('${this.Sigla}', '${this.Nome}', '${this.CPF_Predidente}', '${this.Data_Fundacao}',
                         '${this.ID_Programa}');`
}

class ProgramaPartido {
  ID: string;
  private readonly Conteudo: string;
  private readonly Data_Publicacao: string;

  constructor() {
    this.ID = Faker.datatype.uuid();
    this.Conteudo = Faker.lorem.sentence(20).substr(0, 255);
    this.Data_Publicacao = formatDate(Faker.date.past(15));
  }

  toSQL = () => `INSERT INTO Programa_Partido
                 VALUES ('${this.ID}', '${this.Conteudo}', '${this.Data_Publicacao}');`
}

class Candidato {
  CPF_Candidato: string;
  private readonly Sigla_Partido: string;

  constructor(sigla: string, cpf: string) {
    this.CPF_Candidato = cpf;
    this.Sigla_Partido = sigla;
  }

  toSQL = () => `INSERT INTO Candidato
                 VALUES ('${this.CPF_Candidato}', '${this.Sigla_Partido}');`
}

class Cargo {
  ID: string
  Nome: string
  private readonly Cidade: string
  private readonly Estado: string
  private readonly Federacao: string
  private readonly Quantidade_Eleitos: number

  constructor(nome: string, type: 'Cidade' | 'Estado' | 'Federacao', quantidade: number) {
    this.ID = Faker.datatype.uuid();
    this.Nome = nome;
    this.Cidade = type === 'Cidade' ? 'São Paulo' : null;
    this.Estado = type === 'Estado' ? 'SP' : null;
    this.Federacao = type === 'Federacao' ? 'BR' : null;
    this.Quantidade_Eleitos = quantidade
  }

  toSQL = () => `INSERT INTO Cargo
                 VALUES ('${this.ID}', '${this.Nome}', ${this.Cidade ? `'${this.Cidade}'` : 'NULL'},
                         ${this.Estado ? `'${this.Estado}'` : 'NULL'},
                         ${this.Federacao ? `'${this.Federacao}'` : 'NULL'},
                         '${this.Quantidade_Eleitos}');`;

}

class Pleito {
  Ano: string;
  private readonly Total_Votos: number;

  constructor(ano: string) {
    this.Ano = ano;
    this.Total_Votos = 0
  }

  toSQL = () => `INSERT INTO Pleito
                 VALUES (${this.Ano}, ${this.Total_Votos});`;
}

class Candidatura {
  ID: string;
  private readonly CPF_Candidato: string;
  private readonly CPF_Vice: string;
  private readonly Ano_Pleito: number;
  private readonly Votos_Recebidos: number;
  private readonly ID_Cargo: string;

  constructor(cpf_candidato: string, cpf_vice: string, ano_pleito: number, cargo: string) {
    this.ID = Faker.datatype.uuid();
    this.CPF_Candidato = cpf_candidato;
    this.CPF_Vice = cpf_vice;
    this.Ano_Pleito = ano_pleito;
    this.ID_Cargo = cargo;
    this.Votos_Recebidos = Faker.datatype.number(1000)
  }

  toSQL = () => `INSERT INTO Candidatura
                 VALUES ('${this.ID}', '${this.CPF_Candidato}', ${this.CPF_Vice ? `'${this.CPF_Vice}'` : 'NULL'},
                         ${this.Ano_Pleito},
                         '${this.ID_Cargo}',
                         ${this.Votos_Recebidos});`
}

class EquipeApoio {
  ID: string;
  private ID_Candidatura: string;
  private Ano_Pleito: any;
  private Objetivo: string;

  constructor(candidatura: string, ano: number) {
    this.ID = Faker.datatype.uuid();
    this.ID_Candidatura = candidatura;
    this.Ano_Pleito = ano;
    this.Objetivo = Faker.random.arrayElement(['Arrecador Fundos', 'Marketing', 'Apoiar Movimentos', 'Comunicação com o Eleitor'])
  }

  toSQL = () => `INSERT INTO Equipe_Apoio
                 VALUES ('${this.ID}', '${this.ID_Candidatura}', ${this.Ano_Pleito}, '${this.Objetivo}');`
}

class ApoiadorCampanha {
  private ID_Equipe_Apoio: string;
  private CPF_Apoiador: string;
  private ID_Candidatura: string;

  constructor(equipe: string, cpf: string, candidatura: string) {
    this.ID_Equipe_Apoio = equipe;
    this.CPF_Apoiador = cpf;
    this.ID_Candidatura = candidatura
  }

  toSQL = () => `INSERT INTO Apoiador_Campanha
                 VALUES ('${this.ID_Equipe_Apoio}', '${this.CPF_Apoiador}', '${this.ID_Candidatura}');`
}


class DoadorCampanha {
  ID: string;
  private CPF: string;
  private CNPJ: string;

  constructor(cpf: string, cnpj: string) {
    this.ID = Faker.datatype.uuid();
    this.CPF = cpf;
    this.CNPJ = cnpj
  }

  toSQL = () => `INSERT INTO Doador_Campanha
                 VALUES ('${this.ID}', ${this.CPF ? `'${this.CPF}'` : 'NULL'},
                         ${this.CNPJ ? `'${this.CNPJ}'` : 'NULL'});`
}

class DoacaoCandidatura {
  private ID_Doador: any;
  private ID_Candidatura: any;
  private Valor: number;

  constructor(doador: string, candidatura: string) {
    this.ID_Doador = doador;
    this.ID_Candidatura = candidatura;
    this.Valor = Faker.datatype.number(100000)
  }

  toSQL = () => `INSERT INTO Doacao_Candidatura
                 VALUES ('${this.ID_Doador}', '${this.ID_Candidatura}', ${this.Valor});`
}

class ProcessoJudicial {
  private ID: string;
  private CPF_Reu: string;
  private Procedente: boolean;
  private Data_Inicio: string
  private Date_Fim: string

  constructor(cpf: string) {
    this.ID = Faker.datatype.uuid();
    this.Data_Inicio = formatDate(Faker.date.past(20));
    this.Date_Fim = Faker.datatype.boolean() ? formatDate(Faker.date.past(5)) : null;
    this.Procedente = Faker.datatype.boolean()
    this.CPF_Reu = cpf
  }

  toSQL = () => `INSERT INTO Processo_Judicial
                 VALUES ('${this.ID}', '${this.Data_Inicio}',
                         ${this.Date_Fim ? `'${this.Date_Fim}'` : 'NULL'}, ${this.Procedente}, '${this.CPF_Reu}');`

}
const pessoas = Array.from(Array(1000)).map(_ => new Pessoa());
const programas_partido = Array.from(Array(20)).map(_ => new ProgramaPartido())

const partidos = [
  new Partido('MDB', 'Movimento Democrático Brasileiro', pessoas[Faker.datatype.number(pessoas.length - 1)].CPF, programas_partido[Faker.datatype.number(programas_partido.length - 1)].ID),
  new Partido('PT', 'Partido dos Trabalhadores', pessoas[Faker.datatype.number(pessoas.length - 1)].CPF, programas_partido[Faker.datatype.number(programas_partido.length - 1)].ID),
  new Partido('PSDB', 'Partido da Social Democracia Brasileira', pessoas[Faker.datatype.number(pessoas.length - 1)].CPF, programas_partido[Faker.datatype.number(programas_partido.length - 1)].ID),
  new Partido('PP', 'Progressistas', pessoas[Faker.datatype.number(pessoas.length - 1)].CPF, programas_partido[Faker.datatype.number(programas_partido.length - 1)].ID),
  new Partido('PDT', 'Partido Democrático Trabalhista', pessoas[Faker.datatype.number(pessoas.length - 1)].CPF, programas_partido[Faker.datatype.number(programas_partido.length - 1)].ID),
  new Partido('PTB', 'Partido Trabalhista Brasileiro', pessoas[Faker.datatype.number(pessoas.length - 1)].CPF, programas_partido[Faker.datatype.number(programas_partido.length - 1)].ID),
]

const setOfCandidates = array => {
  const uniqueKeys = [...new Set(array.map(({ CPF_Candidato }) => Number.parseInt(CPF_Candidato)))];
  return uniqueKeys.map(key => array.find(({ CPF_Candidato }) => CPF_Candidato === key.toString()));
}

const candidatos = setOfCandidates(Array.from(Array(400))
  .map((_, __, array,) => new Candidato(partidos[Faker.datatype.number(partidos.length - 1)].Sigla, Faker.random.arrayElement(pessoas).CPF)))

const votantes = pessoas.filter(({ CPF }) => !candidatos.find(({ CPF_Candidato }) => CPF_Candidato === CPF))

const cargos = [
  new Cargo('Vereador', 'Cidade', 20),
  new Cargo('Prefeito', 'Cidade', 1),
  new Cargo('Deputado Estadual', 'Estado', 10),
  new Cargo('Deputado Federal', 'Federacao', 5),
  new Cargo('Governador', 'Estado', 1),
  new Cargo('Presidente', 'Federacao', 1),
]

const pleitos = [
  new Pleito('2020'),
  new Pleito('2018'),
  new Pleito('2016'),
  new Pleito('2014'),
  new Pleito('2012'),
  new Pleito('2010'),
]

const uniqueVices = () => {
  const person = Faker.random.arrayElement(votantes);
  if (candidatos.find(({ CPF_Candidato }) => CPF_Candidato === person.CPF)) return uniqueVices();
  return person;
}

const candidaturas = candidatos.map(candidato => {
  const cargo = Faker.random.arrayElement(cargos);
  let vice = null;
  if (['Presidente', 'Governador', 'Prefeito'].includes(cargo.Nome)) {
    vice = new Candidato(partidos[Faker.datatype.number(partidos.length - 1)].Sigla, uniqueVices().CPF);
    candidatos.push(vice);
  }
  return new Candidatura(candidato.CPF_Candidato, vice ? vice.CPF_Candidato : null, Faker.random.arrayElement(pleitos).Ano, cargo.ID);
})

const equipes_apoio = Array.from(Array(100)).map(_ => new EquipeApoio(Faker.random.arrayElement(candidaturas).ID, Faker.random.arrayElement(pleitos).Ano))

const apoiadores = Array.from(Array(100)).map(_ => new ApoiadorCampanha(Faker.random.arrayElement(equipes_apoio).ID, Faker.random.arrayElement(votantes).CPF, Faker.random.arrayElement(candidaturas).ID))

const doadores = Array.from(Array(200)).map(_ => {
  if (Faker.datatype.boolean()) return new DoadorCampanha(Faker.random.arrayElement(votantes).CPF, null);
  return new DoadorCampanha(null, Faker.datatype.number({ min: 10000000000000, max: 99999999999999 }).toString())
})

const doacao_candidatura = doadores.map(({ ID }) => new DoacaoCandidatura(ID, Faker.random.arrayElement(candidaturas).ID));

const processos = Array.from(Array(1000)).map(_ => new ProcessoJudicial(Faker.random.arrayElement(pessoas).CPF));


const all_seeds = [
  '\n\n--- Insere pessoas \n',
  pessoas.map(pessoa => pessoa.toSQL()).join('\n'),
  '\n\n--- Insere programa partidos \n',
  programas_partido.map(i => i.toSQL()).join('\n'),
  '\n\n--- Insere partidos ',
  partidos.map(i => i.toSQL()).join('\n'),
  '\n\n-- Insere Candidato ',
  candidatos.map(i => i.toSQL()).join('\n'),
  '\n\n-- Insere Cargo ',
  cargos.map(i => i.toSQL()).join('\n'),
  '\n\n-- Insere Pleitos ',
  pleitos.map(i => i.toSQL()).join('\n'),
  '\n\n-- Insere Candidaturas ',
  candidaturas.map(i => i.toSQL()).join('\n'),
  '\n\n-- Insere Equipes de Apoio ',
  equipes_apoio.map(i => i.toSQL()).join('\n'),
  '\n\n-- Insere Apoiadores de Campanha',
  apoiadores.map(i => i.toSQL()).join('\n'),
  '\n\n-- Insere Doadores de Campanha',
  doadores.map(i => i.toSQL()).join('\n'),
  '\n\n-- Insere Doacao Candidatura',
  doacao_candidatura.map(i => i.toSQL()).join('\n'),
  '\n\n-- Insere Processos Judiciais',
  processos.map(i => i.toSQL()).join('\n'),
]


fs.readFile('./base-seed.sql', 'utf8', function (err, data) {
  if (err) throw err;
  fs.writeFile('./seed.sql', [data, ...all_seeds].join("\n"), (error) => {
    if (error) console.error(error)
  });
});



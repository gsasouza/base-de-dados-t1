import * as React from 'react'
import { GetServerSidePropsContext, NextPage } from 'next'
import { ParsedUrlQuery } from 'querystring'

import Layout from '../components/Layout'
import Table from '../components/Table'
import { HeadCell } from '../components/TableHeader'
import { rawQuery } from "../services/database";

interface Data {
  nome: string,
  ano_pleito: string,
  nome_cargo: string,
  cpf_candidato: string,
  votos_recebidos: number
}

const columns: readonly HeadCell<Data>[] = [
  {
    id: 'nome',
    numeric: false,
    disablePadding: true,
    label: 'Nome Candidato',
  },
  {
    id: 'cpf_candidato',
    numeric: false,
    disablePadding: false,
    label: 'CPF',
  },
   {
    id: 'ano_pleito',
    numeric: false,
    disablePadding: false,
    label: 'Ano',
  },
  {
    id: 'nome_cargo',
    numeric: false,
    disablePadding: false,
    label: 'Cargo',
  },
  {
    id: 'votos_recebidos',
    numeric: false,
    disablePadding: false,
    label: 'Votos Recebidos',
  },
]

type Props = {
  query: ParsedUrlQuery,
  data: Data[]
}

const Candidaturas: NextPage<Props> = ({ query, data }) => {
  return (
    <Layout>
      <Table<Data> title="Candidaturas" rows={data} columns={columns} filters={query}/>
    </Layout>
  )
}

export async function getServerSideProps({ req, query }: GetServerSidePropsContext) {
  const { orderBy, order } = query

  const data = await rawQuery({
    query: 'SELECT Cargo.Nome as Nome_Cargo, Ano_Pleito, CPF_Candidato, Candidatura_Pessoa.Nome, Votos_Recebidos FROM Cargo JOIN (SELECT * FROM Candidatura JOIN Pessoa ON Candidatura.CPF_Candidato = Pessoa.CPF) AS Candidatura_Pessoa ON Cargo.ID = Candidatura_Pessoa.ID_Cargo',
    order: order as string,
    orderBy: orderBy as string
  })

  return { props: { data: data, query } }
}


export default Candidaturas
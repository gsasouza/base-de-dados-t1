import * as React from 'react'
import { GetServerSidePropsContext, NextPage } from 'next'
import { ParsedUrlQuery } from 'querystring'

import Layout from '../components/Layout'
import Table from '../components/Table'
import { HeadCell } from '../components/TableHeader'
import { rawQuery } from "../services/database";


interface Data {
  cpf: string,
  nome: string,
  titulo_eleitor: number,
  endereco: string,
  escolaridade: string,
}


const columns: readonly HeadCell<Data>[] = [
  {
    id: 'cpf',
    numeric: true,
    disablePadding: true,
    label: 'CPF`',
  },
  {
    id: 'titulo_eleitor',
    numeric: false,
    disablePadding: false,
    label: 'Titulo Eleitor',
  },
  {
    id: 'nome',
    numeric: false,
    disablePadding: false,
    label: 'nome',
  },
  {
    id: 'endereco',
    numeric: false,
    disablePadding: false,
    label: 'Endereco',
  },
  {
    id: 'escolaridade',
    numeric: false,
    disablePadding: false,
    label: 'Escolaridade',
  },
]
type Props = {
  query: ParsedUrlQuery,
  data: Data[]
}

const FichaLimpa: NextPage<Props> = ({ query, data }) => {
  return (
    <Layout>
      <Table<Data> title="Pessoas com Ficha Limpa" rows={data} columns={columns} filters={query}/>
    </Layout>
  )
}

export async function getServerSideProps({ req, query }: GetServerSidePropsContext) {
  const { orderBy, order } = query

  const data = await rawQuery({
    query: 'SELECT * FROM Pessoa WHERE Pessoa.CPF NOT IN (SELECT CPF_Reu FROM Processo_Judicial WHERE Procedente = TRUE AND Data_Fim BETWEEN CURRENT_DATE - INTERVAL \'5 YEARS\' AND CURRENT_DATE)',
    order: order as string,
    orderBy: orderBy as string
  })

  return { props: { data: data, query } }
}


export default FichaLimpa
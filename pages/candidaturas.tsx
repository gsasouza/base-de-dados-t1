import * as React from 'react'
import { GetServerSidePropsContext, NextPage } from 'next'
import { ParsedUrlQuery } from 'querystring'

import Layout from '../components/Layout'
import Table from '../components/Table'
import { HeadCell } from '../components/TableHeader'

interface Data {
  Nome: string,
  Ano: string,
  Cargo: string,
}

const columns: readonly HeadCell<Data>[] = [
  {
    id: 'Nome',
    numeric: false,
    disablePadding: true,
    label: 'Nome Candidato',
  },
  {
    id: 'Ano',
    numeric: false,
    disablePadding: false,
    label: 'Ano',
  },
  {
    id: 'Cargo',
    numeric: false,
    disablePadding: false,
    label: 'Cargo',
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
  const { rowsPerPage = '10', page = '0', orderBy, order } = query
  // const data = await selectAll({
  //   fields: columns.map(({ id }) => id).filter(id => id !== 'delete'),
  //   table: 'Candidaturas',
  //   offset: Number.parseInt(rowsPerPage as string, 10) * Number.parseInt(page as string, 10),
  //   limit: rowsPerPage as string,
  //   orderBy: orderBy as string,
  //   order: order as string,
  // })

  return { props: { data: [], query } }
}


export default Candidaturas
import Layout from '../../components/Layout'
import Table from '../../components/Table'

import * as React from 'react'
import Router from 'next/router'
import { HeadCell } from '../../components/TableHeader'
import { GetServerSidePropsContext, NextPage } from 'next'
import { ParsedUrlQuery } from 'querystring'
import { selectAll } from '../../services/database'
import { deleteRow } from '../../services/api'

interface Data {
  Cargo: number,
  Ano_Pleito: Date
  Local: string
  Quantidade_Votos: number
}


const columns: readonly HeadCell<Data>[] = [
  {
    id: 'Cargo',
    numeric: true,
    disablePadding: true,
    label: 'Cargo',
  },
  {
    id: 'Ano_Pleito',
    numeric: false,
    disablePadding: false,
    label: 'Ano_Pleito',
  },
  {
    id: 'Local',
    numeric: false,
    disablePadding: false,
    label: 'Local',
  },
  {
    id: 'Quantidade_Votos',
    numeric: true,
    disablePadding: false,
    label: 'Quantidade_Votos',
  },
  {
    id: 'delete',
    label: 'Deletar',
    action: async (row: Data) => {
      await deleteRow({ table: 'Pleitos_Eleicao', property: 'Ano_Pleito', value: row.Ano_Pleito })
      Router.reload()
    },
  },

]

type Props = {
  query: ParsedUrlQuery,
  data: Data[]
}

const Pleitos_Eleicao: NextPage<Props> = ({ query, data }) => {
  return (
    <Layout>
      <Table<Data> title="Pleitos Eleição" rows={data} columns={columns} filters={query}/>
    </Layout>
  )
}

export async function getServerSideProps({ req, query }: GetServerSidePropsContext) {
  const { rowsPerPage = '10', page = '0', orderBy, order } = query
  const data = await selectAll({
    fields: columns.map(({ id }) => id).filter(id => id !== 'delete'),
    table: 'Pleitos_Eleicao',
    offset: Number.parseInt(rowsPerPage as string, 10) * Number.parseInt(page as string, 10),
    limit: rowsPerPage as string,
    orderBy: orderBy as string,
    order: order as string,
  })

  return { props: { data, query } }
}


export default Pleitos_Eleicao
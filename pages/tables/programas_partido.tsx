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
  ID_Programa: number,
  Versao: number
  Data: Date
}


const columns: readonly HeadCell<Data>[] = [
  {
    id: 'ID_Programa',
    numeric: true,
    disablePadding: true,
    label: 'ID_Programa',
  },
  {
    id: 'Versao',
    numeric: true,
    disablePadding: false,
    label: 'Versao',
  },
  {
    id: 'Data',
    numeric: false,
    disablePadding: false,
    label: 'Data',
  },
  {
    id: 'delete',
    label: 'Deletar',
    action: async (row: Data) => {
      await deleteRow({ table: 'Programas_Partido', property: 'ID_Programa', value: row.ID_Programa })
      Router.reload()
    },
  },

]

type Props = {
  query: ParsedUrlQuery,
  data: Data[]
}

const Programas_Partido: NextPage<Props> = ({ query, data }) => {
  return (
    <Layout>
      <Table<Data> title="Programas Partido" rows={data} columns={columns} filters={query}/>
    </Layout>
  )
}

export async function getServerSideProps({ req, query }: GetServerSidePropsContext) {
  const { rowsPerPage = '10', page = '0', orderBy, order } = query
  const data = await selectAll({
    fields: columns.map(({ id }) => id).filter(id => id !== 'delete'),
    table: 'Programas_Partido',
    offset: Number.parseInt(rowsPerPage as string, 10) * Number.parseInt(page as string, 10),
    limit: rowsPerPage as string,
    orderBy: orderBy as string,
    order: order as string,
  })

  return { props: { data, query } }
}


export default Programas_Partido
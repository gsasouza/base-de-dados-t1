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
  Nro_Processo: number,
  Autor: string,
  Vara_Judicial: string
  Data_inicio: Date
  Status: string
  Veredito: string
}


const columns: readonly HeadCell<Data>[] = [
  {
    id: 'Nro_Processo',
    numeric: true,
    disablePadding: true,
    label: 'Nro_Processo',
  },
  {
    id: 'Autor',
    numeric: false,
    disablePadding: false,
    label: 'Autor',
  },
  {
    id: 'Vara_Judicial',
    numeric: false,
    disablePadding: false,
    label: 'Funcao',
  },
  {
    id: 'Data_inicio',
    numeric: false,
    disablePadding: false,
    label: 'Data_inicio',
  },
  {
    id: 'Status',
    numeric: false,
    disablePadding: false,
    label: 'Status',
  },
  {
    id: 'Veredito',
    numeric: false,
    disablePadding: false,
    label: 'Veredito',
  },
  {
    id: 'delete',
    label: 'Deletar',
    action: async (row: Data) => {
      await deleteRow({ table: 'Processos_Judiciais', property: 'Nro_Processo', value: row.Nro_Processo })
      Router.reload()
    },
  },
]

type Props = {
  query: ParsedUrlQuery,
  data: Data[]
}

const Processos_Judiciais: NextPage<Props> = ({ query, data }) => {
  return (
    <Layout>
      <Table<Data> title="Processos Judiciais" rows={data} columns={columns} filters={query}/>
    </Layout>
  )
}

export async function getServerSideProps({ req, query }: GetServerSidePropsContext) {
  const { rowsPerPage = '10', page = '0', orderBy, order } = query
  const data = await selectAll({
    fields: columns.map(({ id }) => id).filter(id => id !== 'delete'),
    table: 'Processos_Judiciais',
    offset: Number.parseInt(rowsPerPage as string, 10) * Number.parseInt(page as string, 10),
    limit: rowsPerPage as string,
    orderBy: orderBy as string,
    order: order as string,
  })

  return { props: { data, query } }
}


export default Processos_Judiciais
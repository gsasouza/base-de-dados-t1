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
  Nro_partido: number,
  Sigla: string,
  Nome: string,
  Pres_Nacional: string,
  Data_fund: Date,
  Programa: number,
}


const columns: readonly HeadCell<Data>[] = [
  {
    id: 'Nro_partido',
    numeric: true,
    disablePadding: true,
    label: 'Nro_partido',
  },
  {
    id: 'Sigla',
    numeric: false,
    disablePadding: false,
    label: 'Sigla',
  },
  {
    id: 'Nome',
    numeric: false,
    disablePadding: false,
    label: 'Nome',
  },
  {
    id: 'Pres_Nacional',
    numeric: false,
    disablePadding: false,
    label: 'Pres_Nacional',
  },
  {
    id: 'Data_fund',
    numeric: false,
    disablePadding: false,
    label: 'Data_fund',
  },
  {
    id: 'Programa',
    numeric: false,
    disablePadding: false,
    label: 'Nome_Candidato',
  },
  {
    id: 'delete',
    label: 'Deletar',
    action: async (row: Data) => {
      await deleteRow({ table: 'Partidos', property: 'Nro_partido', value: row.Nro_partido })
      Router.reload()
    },
  },

]

type Props = {
  query: ParsedUrlQuery,
  data: Data[]
}

const Partidos: NextPage<Props> = ({ query, data }) => {
  return (
    <Layout>
      <Table<Data> title="Partidos" rows={data} columns={columns} filters={query}/>
    </Layout>
  )
}

export async function getServerSideProps({ req, query }: GetServerSidePropsContext) {
  const { rowsPerPage = '10', page = '0', orderBy, order } = query
  const data = await selectAll({
    fields: ['Nro_partido', 'Sigla', 'Nome', 'Pres_Nacional', 'Data_fund', 'Programa'],
    table: 'Partidos',
    offset: Number.parseInt(rowsPerPage as string, 10) * Number.parseInt(page as string, 10),
    limit: rowsPerPage as string,
    orderBy: orderBy as string,
    order: order as string,
  })

  return { props: { data, query } }
}


export default Partidos
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
  ID_Doador: number,
  CNPJ_Doador: number
  Nome_Doador: string
  Valor: string
  Data: Date
}


const columns: readonly HeadCell<Data>[] = [
  {
    id: 'ID_Doador',
    numeric: true,
    disablePadding: true,
    label: 'ID_Doador',
  },
  {
    id: 'CNPJ_Doador',
    numeric: true,
    disablePadding: false,
    label: 'CNPJ_Doador',
  },
  {
    id: 'Nome_Doador',
    numeric: false,
    disablePadding: false,
    label: 'Nome_Doador',
  },
  {
    id: 'Valor',
    numeric: true,
    disablePadding: false,
    label: 'Valor',
  },
  {
    id: 'Data',
    numeric: true,
    disablePadding: false,
    label: 'Data',
  },
  {
    id: 'delete',
    label: 'Deletar',
    action: async (row: Data) => {
      await deleteRow({ table: 'Doadores_Campanha', property: 'ID_Doador', value: row.ID_Doador })
      Router.reload()
    },
  },

]

type Props = {
  query: ParsedUrlQuery,
  data: Data[]
}

const Doadores_Campanha: NextPage<Props> = ({ query, data }) => {
  return (
    <Layout>
      <Table<Data> title="Doadores Campanha" rows={data} columns={columns} filters={query}/>
    </Layout>
  )
}

export async function getServerSideProps({ req, query }: GetServerSidePropsContext) {
  const { rowsPerPage = '10', page = '0', orderBy, order } = query
  const data = await selectAll({
    fields: columns.map(({ id }) => id).filter(id => id !== 'delete'),
    table: 'Doadores_Campanha',
    offset: Number.parseInt(rowsPerPage as string, 10) * Number.parseInt(page as string, 10),
    limit: rowsPerPage as string,
    orderBy: orderBy as string,
    order: order as string,
  })

  return { props: { data, query } }
}


export default Doadores_Campanha
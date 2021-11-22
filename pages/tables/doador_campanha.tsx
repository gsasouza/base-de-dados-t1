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
  id: string,
  cpf: string
  cnpj: string
}


const columns: readonly HeadCell<Data>[] = [
  {
    id: 'id',
    numeric: false,
    disablePadding: true,
    label: 'ID',
  },
  {
    id: 'cpf',
    numeric: false,
    disablePadding: true,
    label: 'CPF',
  },
  {
    id: 'cnpj',
    numeric: true,
    disablePadding: false,
    label: 'CNPJ_Doador',
  },
  {
    id: 'delete',
    label: 'Deletar',
    action: async (row: Data) => {
      await deleteRow({ table: 'Doador_campanha', property: 'id', value: row.id })
      Router.reload()
    },
  },

]

type Props = {
  query: ParsedUrlQuery,
  data: Data[]
}

const Doador_campanha: NextPage<Props> = ({ query, data }) => {
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
    table: 'Doador_Campanha',
    offset: Number.parseInt(rowsPerPage as string, 10) * Number.parseInt(page as string, 10),
    limit: rowsPerPage as string,
    orderBy: orderBy as string,
    order: order as string,
  })

  return { props: { data, query } }
}


export default Doador_campanha
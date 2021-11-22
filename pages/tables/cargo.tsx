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
  nome: string,
  cidade: string,
  estado: string,
  federacao: string,
  quantidade_eleitos: number,
}


const columns: readonly HeadCell<Data>[] = [
  {
    id: 'id',
    numeric: true,
    disablePadding: true,
    label: 'ID',
  },
  {
    id: 'nome',
    numeric: false,
    disablePadding: false,
    label: 'Nome',
  },
  {
    id: 'cidade',
    numeric: false,
    disablePadding: false,
    label: 'Cidade',
  },
  {
    id: 'estado',
    numeric: false,
    disablePadding: false,
    label: 'Estado',
  },
  {
    id: 'federacao',
    numeric: false,
    disablePadding: false,
    label: 'Federacao',
  },
  {
    id: 'quantidade_eleitos',
    numeric: false,
    disablePadding: false,
    label: 'Quantidade_eleitos',
  },
  {
    id: 'delete',
    label: 'Deletar',
    action: async (row: Data) => {
      await deleteRow({ table: 'Cargo', property: 'id', value: row.id })
      Router.reload()
    },
  },

]

type Props = {
  query: ParsedUrlQuery,
  data: Data[]
}

const Cargo: NextPage<Props> = ({ query, data }) => {
  console.log(data)
  return (
    <Layout>
      <Table<Data> title="Cargo" rows={data} columns={columns} filters={query}/>
    </Layout>
  )
}

export async function getServerSideProps({ req, query }: GetServerSidePropsContext) {
  const { rowsPerPage = '10', page = '0', orderBy, order } = query
  const data = await selectAll({
    fields: columns.map(({ id }) => id).filter(id => id !== 'delete'),
    table: 'Cargo',
    offset: Number.parseInt(rowsPerPage as string, 10) * Number.parseInt(page as string, 10),
    limit: rowsPerPage as string,
    orderBy: orderBy as string,
    order: order as string,
  })

  return { props: { data, query } }
}


export default Cargo
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
  Cod_cargo: number,
  Nome_cargo: string,
  Cidade: string,
  Estado: string,
  Federacao: Date,
  Quantidade_eleitos: number,
}


const columns: readonly HeadCell<Data>[] = [
  {
    id: 'Cod_cargo',
    numeric: true,
    disablePadding: true,
    label: 'Cod_cargo',
  },
  {
    id: 'Nome_cargo',
    numeric: false,
    disablePadding: false,
    label: 'Nome_cargo',
  },
  {
    id: 'Cidade',
    numeric: false,
    disablePadding: false,
    label: 'Cidade',
  },
  {
    id: 'Estado',
    numeric: false,
    disablePadding: false,
    label: 'Estado',
  },
  {
    id: 'Federacao',
    numeric: false,
    disablePadding: false,
    label: 'Federacao',
  },
  {
    id: 'Quantidade_eleitos',
    numeric: false,
    disablePadding: false,
    label: 'Quantidade_eleitos',
  },
  {
    id: 'delete',
    label: 'Deletar',
    action: async (row: Data) => {
      await deleteRow({ table: 'Cargos', property: 'Cod_cargo', value: row.Cod_cargo })
      Router.reload()
    },
  },

]

type Props = {
  query: ParsedUrlQuery,
  data: Data[]
}

const Cargos: NextPage<Props> = ({ query, data }) => {
  return (
    <Layout>
      <Table<Data> title="Cargos" rows={data} columns={columns} filters={query}/>
    </Layout>
  )
}

export async function getServerSideProps({ req, query }: GetServerSidePropsContext) {
  const { rowsPerPage = '10', page = '0', orderBy, order } = query
  const data = await selectAll({
    fields: columns.map(({ id }) => id).filter(id => id !== 'delete'),
    table: 'Cargos',
    offset: Number.parseInt(rowsPerPage as string, 10) * Number.parseInt(page as string, 10),
    limit: rowsPerPage as string,
    orderBy: orderBy as string,
    order: order as string,
  })

  return { props: { data, query } }
}


export default Cargos
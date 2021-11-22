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
  id_candidatura: string,
  ano_pleito: string
  objetivo: string
}


const columns: readonly HeadCell<Data>[] = [
  {
    id: 'id',
    numeric: true,
    disablePadding: true,
    label: 'ID',
  },
  {
    id: 'id_candidatura',
    numeric: false,
    disablePadding: false,
    label: 'ID_Candidatura',
  },
  {
    id: 'ano_pleito',
    numeric: false,
    disablePadding: false,
    label: 'Ano_Pleito',
  },
  {
    id: 'objetivo',
    numeric: false,
    disablePadding: false,
    label: 'Objetivo',
  },
  {
    id: 'delete',
    label: 'Deletar',
    action: async (row: Data) => {
      await deleteRow({ table: 'Equipe_Apoio', property: 'id', value: row.id })
      Router.reload()
    },
  },

]

type Props = {
  query: ParsedUrlQuery,
  data: Data[]
}

const Equipe_apoio: NextPage<Props> = ({ query, data }) => {
  return (
    <Layout>
      <Table<Data> title="Equipe_Apoio" rows={data} columns={columns} filters={query}/>
    </Layout>
  )
}

export async function getServerSideProps({ req, query }: GetServerSidePropsContext) {
  const { rowsPerPage = '10', page = '0', orderBy, order } = query
  const data = await selectAll({
    fields: columns.map(({ id }) => id).filter(id => id !== 'delete'),
    table: 'Equipe_apoio',
    offset: Number.parseInt(rowsPerPage as string, 10) * Number.parseInt(page as string, 10),
    limit: rowsPerPage as string,
    orderBy: orderBy as string,
    order: order as string,
  })

  return { props: { data, query } }
}


export default Equipe_apoio
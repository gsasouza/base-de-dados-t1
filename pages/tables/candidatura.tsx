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
  id: string
  cpf_candidato: string,
  cpf_vice: string,
  ano_pleito: string,
  id_cargo: string,
  votos_recebidos: string,
}

const columns: readonly HeadCell<Data>[] = [
  {
    id: 'id',
    numeric: false,
    disablePadding: true,
    label: 'ID',
  },
  {
    id: 'cpf_candidato',
    numeric: false,
    disablePadding: true,
    label: 'CPF_Candidato',
  },
  {
    id: 'cpf_vice',
    numeric: false,
    disablePadding: true,
    label: 'CPF_Vice',
  },
  {
    id: 'ano_pleito',
    numeric: false,
    disablePadding: true,
    label: 'ano_pleito',
  },
  {
    id: 'id_cargo',
    numeric: false,
    disablePadding: true,
    label: 'ID_Cargo',
  },
  {
    id: 'votos_recebidos',
    numeric: false,
    disablePadding: true,
    label: 'Votos_Recebidos',
  },
  {
    id: 'delete',
    label: 'Deletar',
    action: async (row: Data) => {
      await deleteRow({ table: 'Candidatura', property: 'id', value: row.id })
      Router.reload()
    },
  },

]

type Props = {
  query: ParsedUrlQuery,
  data: Data[]
}

const Candidatura: NextPage<Props> = ({ query, data }) => {
  return (
    <Layout>
      <Table<Data> title="Candidatura" rows={data} columns={columns} filters={query}/>
    </Layout>
  )
}

export async function getServerSideProps({ req, query }: GetServerSidePropsContext) {
  const { rowsPerPage = '10', page = '0', orderBy, order } = query
  const data = await selectAll({
    fields: columns.map(({ id }) => id).filter(id => id !== 'delete'),
    table: 'Candidatura',
    offset: Number.parseInt(rowsPerPage as string, 10) * Number.parseInt(page as string, 10),
    limit: rowsPerPage as string,
    orderBy: orderBy as string,
    order: order as string,
  })

  return { props: { data, query } }
}


export default Candidatura
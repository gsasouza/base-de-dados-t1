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
  ID_Equipe: number,
  Nome_equipe: string,
  Funcao: string
}


const columns: readonly HeadCell<Data>[] = [
  {
    id: 'ID_Equipe',
    numeric: true,
    disablePadding: true,
    label: 'ID_Equipe',
  },
  {
    id: 'Nome_equipe',
    numeric: false,
    disablePadding: false,
    label: 'Nome_equipe',
  },
  {
    id: 'Funcao',
    numeric: false,
    disablePadding: false,
    label: 'Funcao',
  },
  {
    id: 'delete',
    label: 'Deletar',
    action: async (row: Data) => {
      await deleteRow({ table: 'Equipes_de_apoio', property: 'ID_Equipe', value: row.ID_Equipe })
      Router.reload()
    },
  },

]

type Props = {
  query: ParsedUrlQuery,
  data: Data[]
}

const Equipes_de_Apoio: NextPage<Props> = ({ query, data }) => {
  return (
    <Layout>
      <Table<Data> title="Equipes de Apoio" rows={data} columns={columns} filters={query}/>
    </Layout>
  )
}

export async function getServerSideProps({ req, query }: GetServerSidePropsContext) {
  const { rowsPerPage = '10', page = '0', orderBy, order } = query
  const data = await selectAll({
    fields: columns.map(({ id }) => id).filter(id => id !== 'delete'),
    table: 'Equipes_de_Apoio',
    offset: Number.parseInt(rowsPerPage as string, 10) * Number.parseInt(page as string, 10),
    limit: rowsPerPage as string,
    orderBy: orderBy as string,
    order: order as string,
  })

  return { props: { data, query } }
}


export default Equipes_de_Apoio
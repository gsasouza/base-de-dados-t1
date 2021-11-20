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
  ID_Participante: number,
  Funcao: string
}


const columns: readonly HeadCell<Data>[] = [
  {
    id: 'ID_Participante',
    numeric: true,
    disablePadding: true,
    label: 'ID_Participante',
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
      await deleteRow({ table: 'Participantes_Equipe', property: 'ID_Participante', value: row.ID_Participante })
      Router.reload()
    },
  },

]

type Props = {
  query: ParsedUrlQuery,
  data: Data[]
}

const Participantes_Equipe: NextPage<Props> = ({ query, data }) => {
  return (
    <Layout>
      <Table<Data> title="Participantes Equipe" rows={data} columns={columns} filters={query}/>
    </Layout>
  )
}

export async function getServerSideProps({ req, query }: GetServerSidePropsContext) {
  const { rowsPerPage = '10', page = '0', orderBy, order } = query
  const data = await selectAll({
    fields: columns.map(({ id }) => id).filter(id => id !== 'delete'),
    table: 'Participantes_Equipe',
    offset: Number.parseInt(rowsPerPage as string, 10) * Number.parseInt(page as string, 10),
    limit: rowsPerPage as string,
    orderBy: orderBy as string,
    order: order as string,
  })

  return { props: { data, query } }
}


export default Participantes_Equipe
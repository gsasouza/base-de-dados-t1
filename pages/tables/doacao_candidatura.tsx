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
  id_doador: string,
  id_candidatura: string
  valor: string
}


const columns: readonly HeadCell<Data>[] = [
  {
    id: 'id_doador',
    numeric: false,
    disablePadding: true,
    label: 'ID_Doador',
  },
  {
    id: 'id_candidatura',
    numeric: false,
    disablePadding: true,
    label: 'ID_Candidatura',
  },
  {
    id: 'valor',
    numeric: true,
    disablePadding: false,
    label: 'Valor',
  },
  {
    id: 'delete',
    label: 'Deletar',
    action: async (row: Data) => {
      await deleteRow({
        table: 'Doacao_candidatura',
        property: 'id_doador',
        value: row.id_doador,
        property2: 'id_candidatura',
        value2: row.id_candidatura
    })
      Router.reload()
    },
  },

]

type Props = {
  query: ParsedUrlQuery,
  data: Data[]
}

const Doacao_candidatura: NextPage<Props> = ({ query, data }) => {
  return (
    <Layout>
      <Table<Data> title="Doacao_Candidautra" rows={data} columns={columns} filters={query}/>
    </Layout>
  )
}

export async function getServerSideProps({ req, query }: GetServerSidePropsContext) {
  const { rowsPerPage = '10', page = '0', orderBy, order } = query
  const data = await selectAll({
    fields: columns.map(({ id }) => id).filter(id => id !== 'delete'),
    table: 'Doacao_candidatura',
    offset: Number.parseInt(rowsPerPage as string, 10) * Number.parseInt(page as string, 10),
    limit: rowsPerPage as string,
    orderBy: orderBy as string,
    order: order as string,
  })

  return { props: { data, query } }
}


export default Doacao_candidatura
import Layout from '../../components/Layout'
import Table from '../../components/Table'

import * as React from 'react'
import Router from 'next/router'
import { HeadCell } from '../../components/TableHeader'
import { GetServerSidePropsContext, NextPage } from 'next'
import { ParsedUrlQuery } from 'querystring'
import { selectAll } from '../../services/database'
import { deleteRow } from '../../services/api'
import { formatDate } from "../../services/date";

interface Data {
  id: string,
  conteudo: string
  data_publicacao: string
}


const columns: readonly HeadCell<Data>[] = [
  {
    id: 'id',
    numeric: true,
    disablePadding: true,
    label: 'ID',
  },
  {
    id: 'conteudo',
    numeric: true,
    disablePadding: false,
    label: 'Conteudo',
  },
  {
    id: 'data_publicacao',
    numeric: false,
    disablePadding: false,
    label: 'Data_Publicacao',
  },
  {
    id: 'delete',
    label: 'Deletar',
    action: async (row: Data) => {
      await deleteRow({ table: 'Programa_Partidoo', property: 'id', value: row.id })
      Router.reload()
    },
  },

]

type Props = {
  query: ParsedUrlQuery,
  data: Data[]
}

const Programa_partido: NextPage<Props> = ({ query, data }) => {
  return (
    <Layout>
      <Table<Data> title="Programas Partido" rows={data} columns={columns} filters={query}/>
    </Layout>
  )
}

export async function getServerSideProps({ req, query }: GetServerSidePropsContext) {
  const { rowsPerPage = '10', page = '0', orderBy, order } = query
  const data = await selectAll({
    fields: columns.map(({ id }) => id).filter(id => id !== 'delete'),
    table: 'Programa_Partido',
    offset: Number.parseInt(rowsPerPage as string, 10) * Number.parseInt(page as string, 10),
    limit: rowsPerPage as string,
    orderBy: orderBy as string,
    order: order as string,
  })

  return {
    props: {
      data: data.map(({ data_publicacao, ...rest }) => ({
        ...rest,
        data_publicacao: formatDate(data_publicacao)
      })), query
    }
  }
}


export default Programa_partido
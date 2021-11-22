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
  id: number,
  data_inicio: string,
  data_fim: string
  procedente: Date
  cpf_reu: string
}


const columns: readonly HeadCell<Data>[] = [
  {
    id: 'id',
    numeric: true,
    disablePadding: true,
    label: 'ID',
  },
  {
    id: 'data_inicio',
    numeric: false,
    disablePadding: false,
    label: 'Data_Inicio',
  },
  {
    id: 'data_fim',
    numeric: false,
    disablePadding: false,
    label: 'Data_Fim',
  },
  {
    id: 'procedente',
    numeric: false,
    disablePadding: false,
    label: 'Procedente',
  },
  {
    id: 'cpf_reu',
    numeric: false,
    disablePadding: false,
    label: 'CPF_Reu',
  },
  {
    id: 'delete',
    label: 'Deletar',
    action: async (row: Data) => {
      await deleteRow({ table: 'Processo_judicial', property: 'id', value: row.id })
      Router.reload()
    },
  },
]

type Props = {
  query: ParsedUrlQuery,
  data: Data[]
}

const Processo_judicial: NextPage<Props> = ({ query, data }) => {
  return (
    <Layout>
      <Table<Data> title="Processo_Judicial" rows={data} columns={columns} filters={query}/>
    </Layout>
  )
}

export async function getServerSideProps({ req, query }: GetServerSidePropsContext) {
  const { rowsPerPage = '10', page = '0', orderBy, order } = query
  const data = await selectAll({
    fields: columns.map(({ id }) => id).filter(id => id !== 'delete'),
    table: 'Processo_judicial',
    offset: Number.parseInt(rowsPerPage as string, 10) * Number.parseInt(page as string, 10),
    limit: rowsPerPage as string,
    orderBy: orderBy as string,
    order: order as string,
  })

  return {
    props: {
      data: data.map(({ data_inicio, data_fim, procedente,...rest }) => ({
        ...rest,
        data_inicio: formatDate(data_inicio),
        data_fim: data_fim ? formatDate(data_fim) : null,
        procedente: procedente ? 'Sim' : 'Não'
      })), query
    }
  }
}


export default Processo_judicial
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
  sigla: string,
  nome: string,
  cpf_presidente: string,
  data_fundacao: Date,
  id_programa: number,
}


const columns: readonly HeadCell<Data>[] = [
  {
    id: 'sigla',
    numeric: false,
    disablePadding: false,
    label: 'Sigla',
  },
  {
    id: 'nome',
    numeric: false,
    disablePadding: false,
    label: 'Nome',
  },
  {
    id: 'cpf_presidente',
    numeric: false,
    disablePadding: false,
    label: 'CPF_Presidente',
  },
  {
    id: 'data_fundacao',
    numeric: false,
    disablePadding: false,
    label: 'Data_Fundacao',
  },
  {
    id: 'id_programa',
    numeric: false,
    disablePadding: false,
    label: 'ID_Programa',
  },
  {
    id: 'delete',
    label: 'Deletar',
    action: async (row: Data) => {
      await deleteRow({ table: 'Partido', property: 'sigla', value: row.sigla })
      Router.reload()
    },
  },

]

type Props = {
  query: ParsedUrlQuery,
  data: Data[]
}

const Partido: NextPage<Props> = ({ query, data }) => {
  return (
    <Layout>
      <Table<Data> title="Partido" rows={data} columns={columns} filters={query}/>
    </Layout>
  )
}

export async function getServerSideProps({ req, query }: GetServerSidePropsContext) {
  const { rowsPerPage = '10', page = '0', orderBy, order } = query
  const data = await selectAll({
    fields: ['Sigla', 'Nome', 'CPF_Presidente', 'Data_Fundacao', 'ID_Programa'],
    table: 'Partido',
    offset: Number.parseInt(rowsPerPage as string, 10) * Number.parseInt(page as string, 10),
    limit: rowsPerPage as string,
    orderBy: orderBy as string,
    order: order as string,
  })


  return {
    props: {
      data: data.map(({ data_fundacao, ...rest }) => ({
        ...rest,
        data_fundacao: formatDate(data_fundacao)
      })), query
    }
  }
}


export default Partido
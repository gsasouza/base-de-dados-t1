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
  Nro_Tit_Eleitor: number,
  CPF: number,
  Nome_Pessoa: string,
  End_Pessoa: string,
  Escolaridade: string,
  Nro_Zona: number,
  Nro_Secao: number,
  Situacao_Ficha: string,
}


const columns: readonly HeadCell<Data>[] = [
  {
    id: 'Nro_Tit_Eleitor',
    numeric: true,
    disablePadding: true,
    label: 'Nro_Tit_Eleitor',
  },
  {
    id: 'CPF',
    numeric: false,
    disablePadding: false,
    label: 'CPF',
  },
  {
    id: 'Nome_Pessoa',
    numeric: false,
    disablePadding: false,
    label: 'Nome_Pessoa',
  },
  {
    id: 'End_Pessoa',
    numeric: false,
    disablePadding: false,
    label: 'End_Pessoa',
  },
  {
    id: 'Escolaridade',
    numeric: false,
    disablePadding: false,
    label: 'Escolaridade',
  },
  {
    id: 'Nro_Zona',
    numeric: true,
    disablePadding: false,
    label: 'Nro_Zona',
  },
  {
    id: 'Nro_Secao',
    numeric: true,
    disablePadding: false,
    label: 'Nro_Secao',
  },
  {
    id: 'Situacao_Ficha',
    numeric: false,
    disablePadding: false,
    label: 'Situacao_Ficha',
  },
  {
    id: 'delete',
    label: 'Deletar',
    action: async (row: Data) => {
      await deleteRow({ table: 'Pessoas', property: 'Nro_Tit_Eleitor', value: row.Nro_Tit_Eleitor })
      Router.reload()
    },
  },

]

type Props = {
  query: ParsedUrlQuery,
  data: Data[]
}

const Pessoas: NextPage<Props> = ({ query, data }) => {
  return (
    <Layout>
      <Table<Data> title="Pessoas" rows={data} columns={columns} filters={query}/>
    </Layout>
  )
}

export async function getServerSideProps({ req, query }: GetServerSidePropsContext) {
  const { rowsPerPage = '10', page = '0', orderBy, order } = query
  const data = await selectAll({
    fields: columns.map(({ id }) => id).filter(id => id !== 'delete'),
    table: 'Pessoas',
    offset: Number.parseInt(rowsPerPage as string, 10) * Number.parseInt(page as string, 10),
    limit: rowsPerPage as string,
    orderBy: orderBy as string,
    order: order as string,
  })

  return { props: { data, query } }
}


export default Pessoas
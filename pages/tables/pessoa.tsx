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
  cpf: string,
  nome: string,
  titulo_eleitor: number,
  endereco: string,
  escolaridade: string,
}


const columns: readonly HeadCell<Data>[] = [
  {
    id: 'cpf',
    numeric: true,
    disablePadding: true,
    label: 'CPF`',
  },
  {
    id: 'titulo_eleitor',
    numeric: false,
    disablePadding: false,
    label: 'Titulo Eleitor',
  },
  {
    id: 'nome',
    numeric: false,
    disablePadding: false,
    label: 'nome',
  },
  {
    id: 'endereco',
    numeric: false,
    disablePadding: false,
    label: 'Endereco',
  },
  {
    id: 'escolaridade',
    numeric: false,
    disablePadding: false,
    label: 'Escolaridade',
  },
  {
    id: 'delete',
    label: 'Deletar',
    action: async (row: Data) => {
      await deleteRow({ table: 'Pessoa', property: 'cpf', value: row.cpf })
      Router.reload()
    },
  },

]

type Props = {
  query: ParsedUrlQuery,
  data: Data[]
}

const Pessoa: NextPage<Props> = ({ query, data }) => {
  return (
    <Layout>
      <Table<Data> title="Pessoa" rows={data} columns={columns} filters={query}/>
    </Layout>
  )
}

export async function getServerSideProps({ req, query }: GetServerSidePropsContext) {
  const { rowsPerPage = '10', page = '0', orderBy, order } = query
  const data = await selectAll({
    fields: columns.map(({ id }) => id).filter(id => id !== 'delete'),
    table: 'Pessoa',
    offset: Number.parseInt(rowsPerPage as string, 10) * Number.parseInt(page as string, 10),
    limit: rowsPerPage as string,
    orderBy: orderBy as string,
    order: order as string,
  })

  return { props: { data, query } }
}


export default Pessoa
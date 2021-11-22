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
  cpf_candidato: string,
  sigla_partido: string,
}


const columns: readonly HeadCell<Data>[] = [
  {
    id: 'cpf_candidato',
    numeric: false,
    disablePadding: true,
    label: 'CPF_Candidato',
  },
  {
    id: 'sigla_partido',
    numeric: false,
    disablePadding: true,
    label: 'Sigla_Partido',
  },
  {
    id: 'delete',
    label: 'Deletar',
    action: async (row: Data) => {
      await deleteRow({ table: 'Candidato', property: 'cpf_candidato', value: row.cpf_candidato })
      Router.reload()
    },
  },

]

type Props = {
  query: ParsedUrlQuery,
  data: Data[]
}

const Candidato: NextPage<Props> = ({ query, data }) => {
  console.log(data)
  return (
    <Layout>
      <Table<Data> title="Candidato" rows={data} columns={columns} filters={query}/>
    </Layout>
  )
}

export async function getServerSideProps({ req, query }: GetServerSidePropsContext) {
  const { rowsPerPage = '10', page = '0', orderBy, order } = query
  const data = await selectAll({
    fields: ['CPF_Candidato', 'Sigla_Partido'],
    table: 'Candidato',
    offset: Number.parseInt(rowsPerPage as string, 10) * Number.parseInt(page as string, 10),
    limit: rowsPerPage as string,
    orderBy: orderBy as string,
    order: order as string,
  })

  return { props: { data, query } }
}


export default Candidato
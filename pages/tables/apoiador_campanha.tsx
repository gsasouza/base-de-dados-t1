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
  id_equipe_apoio: string,
  cpf_apoiador: string,
  id_candidatura: string
}

const columns: readonly HeadCell<Data>[] = [
  {
    id: 'id_equipe_apoio',
    numeric: true,
    disablePadding: true,
    label: 'ID_Equipe_Apoio',
  },
  {
    id: 'cpf_apoiador',
    numeric: false,
    disablePadding: false,
    label: 'CPF_Apoiador',
  },
  {
    id: 'id_candidatura',
    numeric: false,
    disablePadding: false,
    label: 'ID_Candidatura',
  },
  {
    id: 'delete',
    label: 'Deletar',
    action: async (row: Data) => {
      await deleteRow({ table: 'Apoiador_campanha', property: 'id_equipe_apoio', value: row.id_equipe_apoio, property2: 'cpf_apoiador', value2: row.cpf_apoiador })
      Router.reload()
    },
  },

]

type Props = {
  query: ParsedUrlQuery,
  data: Data[]
}

const Apoiador_campanha: NextPage<Props> = ({ query, data }) => {
  return (
    <Layout>
      <Table<Data> title="Apoiador_Campanha" rows={data} columns={columns} filters={query}/>
    </Layout>
  )
}

export async function getServerSideProps({ req, query }: GetServerSidePropsContext) {
  const { rowsPerPage = '10', page = '0', orderBy, order } = query
  const data = await selectAll({
    fields: columns.map(({ id }) => id).filter(id => id !== 'delete'),
    table: 'Apoiador_campanha',
    offset: Number.parseInt(rowsPerPage as string, 10) * Number.parseInt(page as string, 10),
    limit: rowsPerPage as string,
    orderBy: orderBy as string,
    order: order as string,
  })

  return { props: { data, query } }
}


export default Apoiador_campanha
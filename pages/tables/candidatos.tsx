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
  ID_candidato: number,
  Tit_eleitor: number,
  CPF: number,
  RG: number,
  Nome_Candidato: string,
  Data_Filiacao: Date,
  Cod_Cargo: number,
  Nro_Partido: number,
}


const columns: readonly HeadCell<Data>[] = [
  {
    id: 'ID_candidato',
    numeric: true,
    disablePadding: true,
    label: 'ID_candidato',
  },
  {
    id: 'Tit_eleitor',
    numeric: true,
    disablePadding: false,
    label: 'Tit_eleitor',
  },
  {
    id: 'CPF',
    numeric: true,
    disablePadding: false,
    label: 'CPF',
  },
  {
    id: 'RG',
    numeric: true,
    disablePadding: false,
    label: 'RG',
  },
  {
    id: 'Nome_Candidato',
    numeric: false,
    disablePadding: false,
    label: 'Nome_Candidato',
  },
  {
    id: 'Data_Filiacao',
    numeric: false,
    disablePadding: false,
    label: 'Nome_Candidato',
  },
  {
    id: 'Cod_Cargo',
    numeric: true,
    disablePadding: false,
    label: 'Cod_Cargo',
  },
  {
    id: 'Nro_Partido',
    numeric: true,
    disablePadding: false,
    label: 'Nro_Partido',
  },
  {
    id: 'delete',
    label: 'Deletar',
    action: async (row: Data) => {
      await deleteRow({ table: 'Candidatos', property: 'ID_candidato', value: row.ID_candidato })
      Router.reload()
    },
  },

]

type Props = {
  query: ParsedUrlQuery,
  data: Data[]
}

const Candidatos: NextPage<Props> = ({ query, data }) => {
  return (
    <Layout>
      <Table<Data> title="Candidatos" rows={data} columns={columns} filters={query}/>
    </Layout>
  )
}

export async function getServerSideProps({ req, query }: GetServerSidePropsContext) {
  const { rowsPerPage = '10', page = '0', orderBy, order } = query
  const data = await selectAll({
    fields: ['ID_candidato', 'Tit_eleitor', 'CPF', 'RG', 'Nome_Candidato', 'Data_Filiacao', 'Cod_Cargo', 'Nro_Partido'],
    table: 'Candidatos',
    offset: Number.parseInt(rowsPerPage as string, 10) * Number.parseInt(page as string, 10),
    limit: rowsPerPage as string,
    orderBy: orderBy as string,
    order: order as string,
  })

  return { props: { data, query } }
}


export default Candidatos
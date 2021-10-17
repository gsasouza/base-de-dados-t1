import Layout from '../../components/Layout'
import Table from '../../components/Table'

import * as React from 'react'
import { HeadCell } from '../../components/TableHeader'
import { GetServerSidePropsContext, NextPage } from 'next'
import { ParsedUrlQuery } from 'querystring'
import { selectAll } from '../../services/postgres'

interface Data {
  name: string;
  number: number;
}


const columns: readonly HeadCell<Data>[] = [
  {
    id: 'name',
    numeric: false,
    disablePadding: true,
    label: 'Nome',
  },
  {
    id: 'number',
    numeric: true,
    disablePadding: false,
    label: 'Número',
  },
]

type Props = {
  query: ParsedUrlQuery,
  data: Data[]
}

const Candidates: NextPage<Props> = ({ query, data }) => {
  console.log(data)
  return (
    <Layout>
      <Table<Data> title="Candidatos" rows={data} columns={columns} filters={query}/>
    </Layout>
  )
}

export async function getServerSideProps({ req, query }: GetServerSidePropsContext) {
  const { rowsPerPage = '10', page = '0', orderBy, order } = query
  const data = await selectAll({
    fields: ['name', 'number'],
    table: 'Candidate',
    offset: Number.parseInt(rowsPerPage as string, 10) * Number.parseInt(page as string, 10),
    limit: rowsPerPage,
    orderBy,
    order,
  })

  return { props: { data, query } }
}


export default Candidates
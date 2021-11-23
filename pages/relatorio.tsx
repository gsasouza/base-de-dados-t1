import * as React from 'react'
import { GetServerSidePropsContext, NextPage } from 'next'
import { ParsedUrlQuery } from 'querystring'

import Layout from '../components/Layout'
import { TableBodySolo } from '../components/Table'
import { HeadCell } from '../components/TableHeader'
import { rawQuery } from "../services/database";
import Typography from "@mui/material/Typography";

interface Data {
  nome_vice: string,
  ano_pleito: string,
  cargo: string,
  nome_candidato: string,
  votos_recebidos: number,
  eleito: string
}

const columns: readonly HeadCell<Data>[] = [
  {
    id: 'nome_candidato',
    numeric: false,
    disablePadding: false,
    label: 'Nome Candidato',
  },
  {
    id: 'nome_vice',
    numeric: false,
    disablePadding: false,
    label: 'Nome Vice',
  },
  {
    id: 'ano_pleito',
    numeric: false,
    disablePadding: false,
    label: 'Ano',
  },
  {
    id: 'cargo',
    numeric: false,
    disablePadding: false,
    label: 'Cargo',
  },
  {
    id: 'votos_recebidos',
    numeric: false,
    disablePadding: false,
    label: 'Votos Recebidos',
  },
  {
    id: 'eleito',
    numeric: false,
    disablePadding: false,
    label: 'Eleito?',
  },
]

const columnsMinusVice: readonly HeadCell<Data>[] = columns.filter(({ id }) => id !== 'nome_vice')

const hasVice = (cargo: string) => ['Presidente', 'Governador', 'Prefeito'].includes(cargo);

type Props = {
  query: ParsedUrlQuery,
  data: Data[]
}

const groupByYear = (data) => data.reduce((acc, cur) => ({
  ...acc,
  [cur.ano_pleito]: [...acc[cur.ano_pleito], cur]
}), { 2020: [], 2018: [], 2016: [], 2014: [], 2012: [], 2010: [] });

const groupByCargo = (data) => data.reduce((acc, cur) => ({
  ...acc,
  [cur.cargo]: [...(acc[cur.cargo] ?? []), cur]
}), {})

const orderByCargo = (data) => Object.fromEntries(Object.entries(data).map(([ano, candidaturas]) => [ano, groupByCargo(candidaturas)]))

const orderCargo = ['Presidente', 'Governador', 'Deputado Federal', 'Deputado Estadual', 'Prefeito', 'Vereador'];

const Candidaturas: NextPage<Props> = ({ query, data }) => {

  console.log(orderByCargo(groupByYear(data)))
  return (
    <Layout>
      {Object.entries(orderByCargo(groupByYear(data))).reverse().map(([ano, cargos]) => Object.keys(cargos).length ? (
          <>
            <Typography
              sx={{ flex: '1 1 100%', marginBottom: '2rem' }}
              variant="h2"
              id="tableTitle"
              component="div"
            >
              Pleito de {ano}
            </Typography>
            {orderCargo.map(cargo => cargos[cargo] ? (
              <>
                <Typography
                  sx={{ flex: '1 1 100%', marginBottom: '2rem' }}
                  variant="h4"
                  id="tableTitle"
                  component="div"
                >
                  {cargo}
                </Typography>
                <div style={{ marginBottom: '3rem' }}>
                  <TableBodySolo columns={hasVice(cargo) ? columns : columnsMinusVice}
                                 rows={
                                   cargos[cargo].map((candidatura, index) => index < candidatura.quantidade_eleitos ? {
                                     ...candidatura,
                                     eleito: 'Sim'
                                   } : { ...candidatura, eleito: 'Não' })
                                 }/>
                </div>

              </>

            ) : null)}
          </>
        ) : null
      )}
    </Layout>
  )
}

export async function getServerSideProps({ req, query }: GetServerSidePropsContext) {

  const data = await rawQuery({
    query: `SELECT CPF_Candidato,
                   CPF_Vice,
                   Votos_Recebidos,
                   Ano_Pleito,
                   Cargo,
                   Quantidade_Eleitos,
                   Candidato.Nome as Nome_Candidato,
                   Vice.Nome      as Nome_Vice
            FROM (SELECT CPF_Candidato, CPF_Vice, Votos_Recebidos, Ano_Pleito, Cargo.Nome as Cargo, Quantidade_Eleitos
                  FROM Candidatura
                           JOIN Cargo ON Candidatura.ID_Cargo = Cargo.ID) AS Candidatura_Cargo
                     LEFT JOIN Pessoa AS Candidato ON Candidatura_Cargo.CPF_Candidato = Candidato.CPF
                     LEFT JOIN Pessoa AS Vice ON Candidatura_Cargo.CPF_Vice = Vice.CPF
            ORDER BY Candidatura_Cargo.Ano_Pleito DESC, Candidatura_Cargo.Votos_Recebidos DESC;`,
  })

  return { props: { data, query } }
}


export default Candidaturas
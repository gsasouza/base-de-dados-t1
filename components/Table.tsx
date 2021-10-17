import * as React from 'react'
import { useRouter } from 'next/router'
import Box from '@mui/material/Box'
import MUITable from '@mui/material/Table'
import TableBody from '@mui/material/TableBody'
import TableCell from '@mui/material/TableCell'
import TableContainer from '@mui/material/TableContainer'
import TablePagination from '@mui/material/TablePagination'
import TableRow from '@mui/material/TableRow'
import Paper from '@mui/material/Paper'
import TableHeader, { HeadCell } from './TableHeader'
import TableToolbar from './TableToolbar'
import IconButton from '@mui/material/IconButton'
import DeleteIcon from '@mui/icons-material/Delete'


export interface TableFilter<T> {
  page: string,
  orderBy: string,
  order: string
  rowsPerPage: string,
}


function useTable<T>(filters: TableFilter<T>) {
  const router = useRouter()
  const { pathname, push } = router
  const { page = '0', rowsPerPage = '10', orderBy = '', order = 'asc' } = filters

  const handlePaginate = (page) => push({
    pathname,
    query: { ...filters, page },
  })

  const handleChangeRowsPerPage = (event: React.ChangeEvent<HTMLInputElement>) => push({
    pathname,
    query: { ...filters, rowsPerPage: event.target.value, page: 0 },
  })

  const handleChangeOrderBy = (orderBy, order) => push({
    pathname,
    query: { ...filters, orderBy, order },
  })

  const handleRequestSort = (
    event: React.MouseEvent<unknown>,
    property: keyof T,
  ) => {
    const isAsc = orderBy === property && order === 'asc'
    handleChangeOrderBy(property, isAsc ? 'desc' : 'asc')
  }

  return {
    orderBy,
    order,
    rowsPerPage: Number.parseInt(rowsPerPage, 10),
    page: Number.parseInt(page, 10),
    handlePaginate,
    handleChangeRowsPerPage,
    handleChangeOrderBy,
    handleRequestSort,
  }
}

type Props<T> = {
  title: string,
  rows: T[],
  filters: TableFilter<T>
  columns: HeadCell<T>[]
}

function Table<T>({ title, rows, columns, filters }): React.ReactElement<Props<T>> {
  const {
    handlePaginate,
    handleChangeRowsPerPage,
    handleRequestSort,
    orderBy,
    order,
    page,
    rowsPerPage,
  } = useTable(filters)

  // Avoid a layout jump when reaching the last page with empty rows.
  const emptyRows =
    page > 0 ? Math.max(0, (1 + page) * rowsPerPage - rows.length) : 0

  return (
    <Box sx={{ width: '100%' }}>
      <Paper sx={{ width: '100%', mb: 2 }}>
        <TableToolbar title={title}/>
        <TableContainer>
          <MUITable
            sx={{ minWidth: 750 }}
            aria-labelledby="tableTitle"
            size={'medium'}
          >
            <TableHeader
              header={columns}
              order={order}
              orderBy={orderBy}
              onRequestSort={handleRequestSort}
              rowCount={rows.length}
            />
            <TableBody>
              {rows.map((row, index) => {
                return (
                  <TableRow
                    hover
                    tabIndex={-1}
                    key={index}
                  >
                    {columns.map(({ id, action }: { id: string, action: (row: T) => void}) =>
                      id === 'delete' ? (
                        <TableCell
                          id={id + index}
                        >
                          <IconButton onClick={() => action(row)}>
                            <DeleteIcon/>
                          </IconButton>
                        </TableCell>
                      ) : (
                        <TableCell
                          id={id + index}
                        >
                          {row[id]}
                        </TableCell>
                      ),
                    )}
                  </TableRow>
                )
              })}
              {emptyRows > 0 && (
                <TableRow
                  style={{
                    height: 53 * emptyRows,
                  }}
                >
                  <TableCell colSpan={6}/>
                </TableRow>
              )}
            </TableBody>
          </MUITable>
        </TableContainer>
        <TablePagination
          rowsPerPageOptions={[5, 10, 25]}
          component="div"
          count={rows.length}
          rowsPerPage={rowsPerPage}
          page={page}
          onPageChange={(_, newPage) => handlePaginate(newPage)}
          onRowsPerPageChange={handleChangeRowsPerPage}
        />
      </Paper>
    </Box>
  )
}

export default Table
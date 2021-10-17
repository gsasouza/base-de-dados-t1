import * as React from 'react'
import Toolbar from '@mui/material/Toolbar'
import { alpha } from '@mui/material/styles'
import Typography from '@mui/material/Typography'
import Tooltip from '@mui/material/Tooltip'
import IconButton from '@mui/material/IconButton'
import DeleteIcon from '@mui/icons-material/Delete'

interface Props {
  title: string
}

const TableToolbar: React.FC<Props> = ({ title }) => {

  return (
    <Toolbar
      sx={{
        pl: { sm: 2 },
        pr: { xs: 1, sm: 1 },
      }}
    >
      <Typography
        sx={{ flex: '1 1 100%' }}
        variant="h6"
        id="tableTitle"
        component="div"
      >
        {title}
      </Typography>
      {/*{numSelected > 0 ? (*/}
      {/*  <Tooltip title="Delete">*/}
      {/*    <IconButton>*/}
      {/*      <DeleteIcon/>*/}
      {/*    </IconButton>*/}
      {/*  </Tooltip>*/}
      {/*) : null}*/}
    </Toolbar>
  )
}

export default TableToolbar
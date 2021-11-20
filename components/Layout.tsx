import * as React from 'react'
import Box from '@mui/material/Box'
import Drawer from '@mui/material/Drawer'
import AppBar from '@mui/material/AppBar'
import CssBaseline from '@mui/material/CssBaseline'
import Toolbar from '@mui/material/Toolbar'
import List from '@mui/material/List'
import Typography from '@mui/material/Typography'
import Divider from '@mui/material/Divider'
import ListItem from '@mui/material/ListItem'
import ListItemText from '@mui/material/ListItemText'
import Link from 'next/link'
import { useRouter } from 'next/router'

const DRAWER_WIDTH = 240

const TABLES = ['Pessoas', 'Candidatos', 'Partidos', 'Programas_Partido', 'Cargos', 'Doadores_Campanha', 'Equipes_de_Apoio', 'Participantes_Equipe', 'Pleitos_Eleicao', 'Processos_Judiciais']

const OTHERS = ['Candidaturas', 'Relatórios', 'Candidatos Ficha Limpa']

const Layout: React.FC = ({ children }) => {
  const router = useRouter()
  return (
    <Box sx={{ display: 'flex' }}>
      <CssBaseline/>
      <AppBar position="fixed" sx={{ zIndex: (theme) => theme.zIndex.drawer + 1 }}>
        <Toolbar>
          <Typography variant="h6" noWrap component="div">
            Projeto - Base de Dados
          </Typography>
        </Toolbar>
      </AppBar>
      <Drawer
        variant="permanent"
        sx={{
          width: DRAWER_WIDTH,
          flexShrink: 0,
          [`& .MuiDrawer-paper`]: { width: DRAWER_WIDTH, boxSizing: 'border-box' },
        }}
      >
        <Toolbar/>
        <Box sx={{ overflow: 'auto' }}>
          <List>
            {TABLES.map((text) => (
              <Link href={`/tables/${text.toLowerCase()}`} key={text}>
                <ListItem button selected={router.pathname === `/tables/${text.toLowerCase()}`}>
                  <ListItemText primary={text}/>
                </ListItem>
              </Link>
            ))}
          </List>
          <Divider/>
          <List>
            {OTHERS.map((text) => (
              <ListItem button key={text}>
                <ListItemText primary={text}/>
              </ListItem>
            ))}
          </List>
        </Box>
      </Drawer>
      <Box component="main" sx={{ flexGrow: 1, p: 3 }}>
        <Toolbar/>
        <Box component="section">
          {children}
        </Box>
      </Box>
    </Box>
  )
}

export default Layout
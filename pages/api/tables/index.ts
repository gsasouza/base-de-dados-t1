import type { NextApiRequest, NextApiResponse } from 'next'
import { deleteRowFromDatabase } from '../../../services/database'

export default async (req: NextApiRequest, res: NextApiResponse) => {
  if (req.method === 'DELETE') {
    const { table, property, value, property2, value2 } = JSON.parse(req.body);
    try {
      await deleteRowFromDatabase({ table, property, value, property2, value2 })
      return res.status(200).send({});
    } catch (error) {
      return res.status(500).send({ error });
    }
  }
}
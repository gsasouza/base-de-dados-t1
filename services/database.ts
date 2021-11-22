const db = require('./postgres')

type SelectAllArgs = {
  fields: string[],
  table: string,
  offset: number,
  limit: string,
  orderBy?: string,
  order?: string
}

export const selectAll = async ({
                                  fields,
                                  table,
                                  offset,
                                  limit,
                                  orderBy,
                                  order,
                                }: SelectAllArgs) => {

  const select = fields?.length > 0 ? fields.join(',') : '*'
  const ordered = orderBy ? `ORDER BY ${orderBy} ${order.toUpperCase()}` : ''

  return await db.any(`SELECT ${select} FROM ${table} ${ordered};`)
}

type DeleteArgs = {
  table: string,
  property: string,
  value: string
}

export const deleteRowFromDatabase = async ({ table, property, value }: DeleteArgs) => {
  return db.none(`DELETE FROM ${table} WHERE ${property}='${value}';`)
}
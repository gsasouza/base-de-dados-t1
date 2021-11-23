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
                                  orderBy,
                                  order,
                                }: SelectAllArgs) => {

  const select = fields?.length > 0 ? fields.join(',') : '*'
  const ordered = orderBy ? `ORDER BY ${orderBy} ${order.toUpperCase()}` : ''

  return await db.any(`SELECT ${select}
                       FROM ${table} ${ordered};`)
}

type RawQueryArgs = {
  query: string,
  orderBy?: string,
  order?: string
}

export const rawQuery = async ({ query, orderBy, order }: RawQueryArgs) => {
  const ordered = orderBy ? `ORDER BY ${orderBy} ${order.toUpperCase()}` : ''

  return await db.any(`${query} ${ordered};`);
}

type DeleteArgs = {
  table: string,
  property: string,
  value: string
  property2?: string,
  value2?: string
}

export const deleteRowFromDatabase = async ({ table, property, value, property2, value2 }: DeleteArgs) => {
  const and = property2 ? `AND ${property2} = '${value2}'` : '';
  return db.none(`DELETE
                  FROM ${table}
                  WHERE ${property} = '${value}' ${and};`)
}
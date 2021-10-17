import pgp from 'pg-promise'
const db = pgp({})('postgres://local:local@127.0.0.1:5432/t1');


export const selectAll = async ({
  fields,
  table,
  offset,
  limit,
  orderBy,
  order
}) => {

  const select = fields?.length > 0 ? fields.join(',') : '*';
  const ordered = orderBy ? `ORDER BY ${orderBy} ${order.toUpperCase()}` : '';

  return await db.any(`SELECT ${select} FROM ${table} ${ordered} LIMIT ${limit} OFFSET ${offset} ;`);
}
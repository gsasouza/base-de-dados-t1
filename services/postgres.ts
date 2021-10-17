import pgp from 'pg-promise'
const db = pgp({})('postgres://local:local@127.0.0.1:5432/t1');


// Exporting the database object for shared use:
module.exports = db;
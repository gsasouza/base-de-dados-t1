import pgp from 'pg-promise'
const db = pgp({})('postgres://local:local@localhost:5432/t1');


// Exporting the database object for shared use:
module.exports = db;
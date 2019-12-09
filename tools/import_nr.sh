#! /bin/bash
set -eu

db="nr.db"

nr="nr.tab"

function import_table {
  db_file=${1}
  table_file=${2}
  echo Importing ${table_file}...
  sqlite3 -batch ${db_file} << EOF
.separator "\t"
DROP TABLE IF EXISTS ${table_file%.*};
BEGIN TRANSACTION;
CREATE TABLE ${table_file%.*} (
  'accession.version' varchar(16) NOT NULL
,  'description' text NOT NULL
,  'sequence' text NOT NULL
,  PRIMARY KEY ('accession.version')
,  UNIQUE ('accession.version')
);
END TRANSACTION;
.separator "\t"
.import ${table_file} ${table_file%.*}
EOF
}


#
# Create the database
#

# Initialize table
rm -f ${db}

sqlite3 -batch ${db} << EOF
PRAGMA synchronous = Off;
PRAGMA journal_mode = MEMORY;
EOF
 
# Import data into separate tables
import_table "${db}" "${nr}"

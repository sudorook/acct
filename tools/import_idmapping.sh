#! /bin/bash
set -eu

db="idmapping_selected.db"

idmapping="idmapping_selected.tab"

function import_table {
  db_file=${1}
  table_file=${2}
  echo Importing ${table_file}...
  sqlite3 -batch ${db_file} << EOF
DROP TABLE IF EXISTS ${table_file%.*};
BEGIN TRANSACTION;
CREATE TABLE ${table_file%.*} (
  'uniprotkb_ac' varchar(16) NOT NULL
, 'uniprotkb_id' varchar(16) NOT NULL
, 'geneid' integer NOT NULL
, 'refseq' varchar(16) NOT NULL
, 'gi' varchar(32) NOT NULL
, 'pdb' varchar(16)
, 'go' varchar(16)
, 'uniref100' varchar(32)
, 'uniref90' varchar(32)
, 'uniref50' varchar(32)
, 'uniparc' varchar(32)
, 'pir' varchar(16)
, 'taxid' integer NOT NULL
, 'mim' varchar(32)
, 'unigene' varchar(32)
, 'pubmed' varchar(16)
, 'embl' varchar(16)
, 'embl_cds' varchar(16)
, 'ensembl' varchar(16)
, 'ensembl_trs' varchar(16)
, 'ensembl_pro' varchar(16)
, 'additional_pubmed' blob
,  PRIMARY KEY ('uniprotkb_ac')
,  UNIQUE ('uniprotkb_id')
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
import_table "${db}" "${idmapping}"

#! /bin/bash
set -eu

db="pfamseq.db"

pfamseq="pfamseq.txt"

function import_table {
  db_file=${1}
  table_file=${2}
  echo Importing ${table_file}...
  sqlite3 -batch ${db_file} << EOF
DROP TABLE IF EXISTS ${table_file%.*};
BEGIN TRANSACTION;
CREATE TABLE ${table_file%.*} (
  'pfamseq_acc' varchar(10) NOT NULL
, 'pfamseq_id' varchar(16) NOT NULL
, 'seq_version' integer NOT NULL
, 'crc64' varchar(16) NOT NULL
, 'md5' varchar(32) NOT NULL
, 'description' text NOT NULL
, 'evidence' integer NOT NULL
, 'length' integer NOT NULL DEFAULT '0'
, 'species' text NOT NULL
, 'taxonomy' text
, 'is_fragment' integer DEFAULT NULL
, 'sequence' text NOT NULL
, 'updated' timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP
, 'created' datetime DEFAULT NULL
, 'ncbi_taxid' integer unsigned NOT NULL DEFAULT '0'
, 'auto_architecture' integer DEFAULT NULL
, 'treefam_acc' varchar(8) DEFAULT NULL
, 'swissprot' integer DEFAULT '0'
,  PRIMARY KEY ('pfamseq_acc')
,  UNIQUE ('pfamseq_id')
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
import_table "${db}" "${pfamseq}"

#! /bin/bash
set -eu

db="accession2taxid.db"

dead_nucl="dead_nucl.accession2taxid"
dead_prot="dead_prot.accession2taxid"
dead_wgs="dead_wgs.accession2taxid"
nucl_gb="nucl_gb.accession2taxid"
nucl_wgs="nucl_wgs.accession2taxid"
pdb="pdb.accession2taxid"
prot="prot.accession2taxid"


# The first line of the file are column headers, so remove them if they haven't
# been removed already.
function strip_header {
  local db_name="${1}"
  if [[ "$(head -n 1 ${db_name})" =~ \
        "accession	accession.version	taxid	gi" ]]; then 
    tail -n +2 "${db_name}" >> tmp && mv tmp ${db_name} && sync
  fi 
}

# Wrapper for creating a table within a database and then importing
# tab-delimited data to the table. Wacky indentation is intentional.
function import_table {
  db_file=${1}
  table_file=${2}
  echo Importing ${table_file}...
  sqlite3 -batch ${db_file} << EOF
.separator "\t"
DROP TABLE IF EXISTS ${table_file%.*};
BEGIN TRANSACTION;
CREATE TABLE ${table_file%.*} (
  'accession' varchar(10) NOT NULL
, 'accession.version' varchar(16) NOT NULL
, 'taxid' varchar(10) NOT NULL
, 'gi' varchar(16) NOT NULL
,  PRIMARY KEY ('accession')
,  UNIQUE ('accession')
,  UNIQUE ('accession.version')
,  UNIQUE ('gi')
);
END TRANSACTION;
.separator "\t"
.import ${table_file} ${table_file%.*}
EOF
}


#
# Create the database
#

# Remove headers
strip_header "${dead_nucl}"
strip_header "${dead_prot}"
strip_header "${dead_wgs}"
strip_header "${nucl_gb}"
strip_header "${nucl_wgs}"
strip_header "${pdb}"
strip_header "${prot}"

# Initialize table
rm -f ${db}

sqlite3 -batch ${db} << EOF
PRAGMA synchronous = Off;
PRAGMA journal_mode = MEMORY;
EOF
 
# Import data into separate tables
import_table "${db}" "${dead_nucl}"
import_table "${db}" "${dead_prot}"
import_table "${db}" "${dead_wgs}"
import_table "${db}" "${nucl_gb}"
import_table "${db}" "${nucl_wgs}"
import_table "${db}" "${pdb}"
import_table "${db}" "${prot}"

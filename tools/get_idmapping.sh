#! /bin/bash
set -eu

url="ftp://ftp.uniprot.org/pub/databases/uniprot/current_release/knowledgebase/idmapping"
idmapping="idmapping_selected.tab"

wget -nc "${url}/${idmapping}.gz"
pigz -dv "${idmapping}.gz"

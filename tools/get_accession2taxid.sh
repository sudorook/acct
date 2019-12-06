#! /bin/bash
set -eu

url="https://ftp.ncbi.nlm.nih.gov/pub/taxonomy/accession2taxid"

dead_nucl="dead_nucl.accession2taxid"
dead_prot="dead_prot.accession2taxid"
dead_wgs="dead_wgs.accession2taxid"
nucl_gb="nucl_gb.accession2taxid"
nucl_wgs="nucl_wgs.accession2taxid"
pdb="pdb.accession2taxid"
prot="prot.accession2taxid"

# Simple wrapper function that will check the MD5 sum for a file against the
# sum downloaded from the server. Probably redundant with `wget -nc`.
function check_md5sum {
  local file="${1}"

  # Return failure if md5 file not found.
  if ! [ -f "${file}.md5" ]; then
    return 1
  fi

  # Check the md5sum against the md5 file.
  if `cat "${file}.md5" | diff - <(md5sum "${file}") >/dev/null`; then
    return 0
  else
    return 1
  fi
}


#
# Download the files
#

wget -nc "${url}/${dead_nucl}.gz"
wget -nc "${url}/${dead_prot}.gz"
wget -nc "${url}/${dead_wgs}.gz"
wget -nc "${url}/${nucl_gb}.gz"
wget -nc "${url}/${nucl_wgs}.gz"
wget -nc "${url}/${pdb}.gz"
wget -nc "${url}/${prot}.gz"

wget -nc "${url}/${dead_nucl}.gz.md5"
wget -nc "${url}/${dead_prot}.gz.md5"
wget -nc "${url}/${dead_wgs}.gz.md5"
wget -nc "${url}/${nucl_gb}.gz.md5"
wget -nc "${url}/${nucl_wgs}.gz.md5"
wget -nc "${url}/${pdb}.gz.md5"
wget -nc "${url}/${prot}.gz.md5"


#
# Extract the data
#

if `check_md5sum "${dead_nucl}.gz"`; then
  echo "MD5 match."
  rm ${dead_nucl}.gz.md5
  pigz -dv "${dead_nucl}"
else
  echo "MD5 mismatch for ${dead_nucl}. Exiting."
  exit 1
fi

if `check_md5sum "${dead_prot}.gz"`; then
  echo "MD5 match."
  rm ${dead_prot}.gz.md5
  pigz -dv "${dead_prot}"
else
  echo "MD5 mismatch for ${dead_prot}. Exiting."
  exit 1
fi

if `check_md5sum "${dead_wgs}.gz"`; then
  echo "MD5 match."
  rm ${dead_wgs}.gz.md5
  pigz -dv "${dead_wgs}"
else
  echo "MD5 mismatch for ${dead_wgs}. Exiting."
  exit 1
fi

if `check_md5sum "${nucl_gb}.gz"`; then
  echo "MD5 match."
  rm ${nucl_gb}.gz.md5
  pigz -dv "${nucl_gb}"
else
  echo "MD5 mismatch for ${nucl_gb}. Exiting."
  exit 1
fi

if `check_md5sum "${nucl_wgs}.gz"`; then
  echo "MD5 match."
  rm ${nucl_wgs}.gz.md5
  pigz -dv "${nucl_wgs}"
else
  echo "MD5 mismatch for ${nucl_wgs}. Exiting."
  exit 1
fi

if `check_md5sum "${pdb}.gz"`; then
  echo "MD5 match."
  rm ${pdb}.gz.md5
  pigz -dv "${pdb}"
else
  echo "MD5 mismatch for ${pdb}. Exiting."
  exit 1
fi

if `check_md5sum "${prot}.gz"`; then
  echo "MD5 match."
  rm ${prot}.gz.md5
  pigz -dv "${prot}"
else
  echo "MD5 mismatch for ${prot}. Exiting."
  exit 1
fi

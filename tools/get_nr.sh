#! /bin/bash
set -eu

url="ftp://ftp.ncbi.nlm.nih.gov/blast/db/FASTA"
nr="nr"

# Simple wrapper function that will check the MD5 sum for a file against the
# sum downloaded from the server. Probably redundant with `wget -nc`.
function check_md5sum {
  local file="${1}"

  # Return failure if md5 file not found.
  if ! [ -f "${file}.md5" ]; then
    return 1
  fi

  # Check the md5sum against the md5 file.
  if `cat "${file}.md5" | \
      diff - <(md5sum "${file}") >/dev/null`; then
    return 0
  else
    return 1
  fi
}

wget -nc ${url}/${nr}.gz
wget -nc ${url}/${nr}.gz.md5

# Check data integrity before decompressing.
if `check_md5sum "${nr}.gz"`; then
  echo "MD5 match."
  rm "${nr}.gz.md5"
  pigz -d "${nr}.gz"
else
  echo "MD5 mismatch. Exiting."
  exit 1
fi

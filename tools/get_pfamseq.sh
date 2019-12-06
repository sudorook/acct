#! /bin/bash
set -eu


url="ftp://ftp.ebi.ac.uk/pub/databases/Pfam/current_release/database_files"

pfamseq=pfamseq.txt
checksums=md5_checksums

# Simple wrapper function that will check the MD5 sum for a file against the
# sum downloaded from the server. Probably redundant with `wget -nc`.
function check_md5sum {
  local file="${1}"
  local checksums="${2}"

  # Return failure if md5 file not found.
  if ! [ -f "${checksums}" ]; then
    return 1
  fi

  # Check the md5sum against the md5 file.
  if `cat "${checksums}" | grep "${file}" | \
      diff - <(md5sum "${file}") >/dev/null`; then
    return 0
  else
    return 1
  fi
}

wget -nc "${url}/${pfamseq}.gz"
wget -nc "${url}/${checksums}"

if `check_md5sum "${pfamseq}.gz" "${checksums}"`; then
  echo "MD5 match for ${pfamseq}."
  pigz -dv "${pfamseq}.gz"
else
  echo "MD5 mismatch for ${pfamseq}. Exiting."
  exit 1
fi

rm "${checksums}"

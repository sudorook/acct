# Scripts

These are scripts for downloading the data and then generating SQLite
databases.

The data files are pretty huge and the generated databases correspondingly
huger, so don't run these scripts on resource-constrained systems.

Be sure to have at least 1TB of space available. Everything is single threaded,
so you'll only need a single core free, but expect the scripts to monopolize
available memory.

## Databases

The scripts will generate the following databases:

1. `accession2taxid.db` - contains mappings between accession numbers, GI
   numbers, and taxonomy IDs.
2. `pfamseq.db` - contains all of the fields from the latest release of Pfam.
3. `taxonomy.db` - maps taxonomy IDs to species and lineage (i.e. phylogeny
   information).
4. `nr.db` - accession numbers and sequences from the nr (non-redundant)
   database of protein sequences.
5. `nt.db` - accession numbers and sequences from the nt database of nucleotide
   sequences.

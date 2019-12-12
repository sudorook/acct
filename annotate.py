#! /usr/bin/env python3
""" Script for annotating sequences. """

import os
import re
import sys
import csv
import argparse
import sqlite3
from Bio import SeqIO


ACCESSION2TAXID = "accession2taxid.db"
PFAM = "pfamseq.db"
TAXONOMY = "taxonomy.db"
NR = "nr.db"


def parse_options():
    """ Make the command line parser. """
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "-i",
        "--input",
        dest="input",
        required=True,
        help="Input sequences (FASTA format)",
    )
    parser.add_argument(
        "-d",
        "--dbdir",
        dest="dbdir",
        default=None,
        help="Path to (all) SQLite databases",
    )
    parser.add_argument(
        "-f",
        "--format",
        dest="format",
        default="multiple",
        help="Database of origin for ALL sequences (omit for multiple sources)",
    )
    return parser.parse_args()


def load_sequences(sequence_file, sequence_format="fasta"):
    """ Load the sequences for annotation. """
    sequences = list(SeqIO.parse(sequence_file, sequence_format))
    return sequences


def query_database(
    database_path, database_name, return_field_list, query_dict
):
    """ Wrapper for making SQLite queries. """
    with sqlite3.connect(database_path) as conn:
        cur = conn.cursor()
        cmd = (
            "SELECT "
            + ",".join(["`" + field + "`" for field in return_field_list])
            + " FROM "
            + database_name
            + " WHERE "
            + " AND ".join(["`" + key + "` = ?" for key in query_dict.keys()])
            + ";"
        )
        keys = tuple(query_dict.values())
        cur.execute(cmd, keys)

        res = cur.fetchall()

        # Only return unique results
        if res:
            if len(res) == 1:
                return res
        return None


def identify_database(record):
    """ Identify (i.e. guess) the database where a sequence originated. """
    header = record.id

    database = None
    if "jgi|" in header:
        database = "jgi"
    elif "XM_" in header:
        database = "ncbi"
    else:
        database = "pfam"
    return database


def read_species_map(path):
    """ Return JGI species map. """
    species_map = {}
    with open(path) as handle:
        csv_reader = csv.reader(handle, delimiter=",")
        next(csv_reader)
        for row in csv_reader:
            species_map[row[6]] = row[0]
    return species_map


def annotate_pfam(record, dbdir):
    """ Annotate header with the pfam accessio number. """
    pfamseq_acc = record.id
    domain_number = re.findall(
        r"domain.*\[*(\d)\]*$", record.description
    )[0]
    res = query_database(
        os.path.join(dbdir, PFAM),
        "pfamseq",
        ["description", "species", "taxonomy", "ncbi_taxid"],
        {"pfamseq_acc": pfamseq_acc},
    )
    if res:
        taxid = str(res[0][3])
        description = res[0][0]
    else:
        print(record)
        sys.exit("Pfam accession %s not found." % str(pfamseq_acc))

    res = query_database(
        os.path.join(dbdir, TAXONOMY),
        "taxonomy",
        ["species", "lineage"],
        {"taxid": taxid},
    )
    if res:
        header = (
            pfamseq_acc
            + "||"
            + description
            + "||"
            + domain_number
            + "||"
            + taxid
            + "||"
            + res[0][0]
            + "||"
            + res[0][1]
        )
    else:
        print(record)
        sys.exit("NCBI taxid %s not found." % str(taxid))
    return header


def annotate_ncbi(record, dbdir):
    """ Annotate a header using its nucleotide refseq accesion number. """
    accession_version = record.id.split("  ")[0]
    description = "".join(record.description.split("  ")[1:])
    domain_number = re.findall(
        r"domain.*\[*(\d)\]*$", record.description
    )[0]
    res = query_database(
        os.path.join(dbdir, ACCESSION2TAXID),
        "nucl_gb",
        ["taxid"],
        {"accession.version": accession_version},
    )
    if res:
        taxid = str(res[0][0])
    else:
        sys.exit(
            "NCBI accession.version %s not found."
            % str(accession_version)
        )
    res = query_database(
        os.path.join(dbdir, TAXONOMY),
        "taxonomy",
        ["species", "lineage"],
        {"taxid": taxid},
    )
    if res:
        header = (
            accession_version
            + "||"
            + description
            + "||"
            + domain_number
            + "||"
            + str(taxid)
            + "||"
            + res[0][0]
            + "||"
            + res[0][1]
        )
    else:
        print(record)
        sys.exit("NCBI taxid %s not found." % str(taxid))
    return header


def main():
    """ Main """
    options = parse_options()
    if not options.dbdir:
        try:
            options.dbdir = os.environ(["SQLITEDB"])
        except BaseException as error:
            sys.exit("No database directory provided. Exiting.")

    bad = []

    jgi2taxid = read_species_map("data/jgi_species_map.csv")

    records = load_sequences(options.input, "fasta")
    for record in records:
        record_db = identify_database(record)
        if record_db == "pfam":
            header = annotate_pfam(record, options.dbdir)
            record.id = "pfam||" + header
            record.name = record.id
            record.description = ""
        elif record_db == "ncbi":
            header = annotate_ncbi(record, options.dbdir)
            record.id = "ncbi||" + header
            record.name = record.id
            record.description = ""
        elif record_db == "jgi":
            fields = record.description.split("|")
            species_id = fields[1]
            transcript_id = fields[2]
            taxid = jgi2taxid[species_id]
            protein_id = fields[3]
            if len(fields) == 4:
                domain_number = re.findall(r"domain.*\[*(\d)\]*$", protein_id)[
                    0
                ]
            elif len(fields) == 5:  # hard-code workaround for now...
                domain_number = re.findall(r"domain.*\[*(\d)\]*$", fields[4])[
                    0
                ]
            species_db = os.path.join(
                options.dbdir, "jgi/" + species_id + "_kog.db"
            )

            if not species_id == "Neute_mat_a1":  # hard code this for now...
                res = query_database(
                    species_db,
                    species_id,
                    ["kogdefline"],
                    {"transcriptID": transcript_id},
                )
            else:
                res = None
            if res:
                protein_description = res[0][0] + "||" + domain_number
            else:
                protein_description = (
                    re.split(r"_*domain", protein_id)[0] + "||" + domain_number
                )
                bad.append(record)

            res = query_database(
                os.path.join(options.dbdir, TAXONOMY),
                "taxonomy",
                ["species", "lineage"],
                {"taxid": taxid},
            )
            if res:
                header = (
                    "jgi||"
                    + transcript_id
                    + "||"
                    + protein_description
                    + "||"
                    + str(taxid)
                    + "||"
                    + res[0][0]
                    + "||"
                    + res[0][1]
                )
                record.id = header
                record.description = ""
                record.name = ""
            else:
                print(record)
                sys.exit("NCBI taxid %s not found." % str(taxid))
        else:
            sys.exit(
                "Cannot match %s to an existsing database."
                % record.description
            )

    with open(options.input + ".an", "w") as handle:
        SeqIO.write(records, handle, "fasta-2line")

    if bad:
        with open("failure.fasta", "w") as handle:
            SeqIO.write(bad, handle, "fasta-2line")


if __name__ == "__main__":
    main()

#!/bin/bash

set -euxo pipefail
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
DB="$DIR/../DB"
TMP="/tmp/test-temp"
CONTIGS="$DIR/phage-contigs.fna"



echo Test environment

if [[ -d "$TMP" ]]; then
  rm -rf "$TMP"
else
    mkdir "$TMP"
fi

if [[ ! -d "$DB" ]]; then
  echo "DB not installed"
  exit 1
fi

if [[ ! -e "$CONTIGS" ]]; then
    echo "Contigs not found: $CONTIGS"
    exit 1
fi
# Check tools available

seqfu version


# Run tools
virsorter run --use-conda-off --working-dir "$TMP"/virsorter2 --seqfile "$CONTIGS" --db-dir "$DB"/virsorter2/ -j 8 

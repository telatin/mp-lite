mamba create -n MPLITE_V1 -y -c conda-forge -c bioconda \
  nextflow pigz "seqfu>=1.9" "multiqc>1.9" \
  "samtools>=1.12" bwa fastp "bamtocov>=2.6" "megahit" \
  "virsorter=2.2.3" "r-virfinder" "vibrant=1.2.1" \
  python numpy theano=1.0.3 keras=2.2.4 scikit-learn Biopython h5py \
  seaborn imbalanced-learn screed=1  ncbi-genome-download last


# VIBRANT ~12Gb 
# download-db.sh PATH

# VIRSORTER 2
#

process MINREADS {
    tag "filter $sample_id"
    label 'process_low'

    input:
    tuple val(sample_id), path(reads) 
    val(min)
    
    output:
    tuple val(sample_id), path("pass/${sample_id}_R*.fastq.gz"), emit: reads optional true 
    
    script:
    // # TOT=\$(seqfu count ${reads[0]} ${reads[1]} | cut -f 2 )
    """
    TOT=\$(seqfu head -n ${min} ${reads[0]} | seqfu count | cut -f 2 )
    echo "HEAD READS ${reads[0]}: \$TOT"
    mkdir -p pass
    if [[ \$TOT -eq ${min} ]]; then
        echo "PASS"
        mv ${reads[0]} pass/${sample_id}_R1.fastq.gz
        mv ${reads[1]} pass/${sample_id}_R2.fastq.gz
    fi
    file ${reads[0]}
    
    """

}


process VIBRANT {
    /*

    export VIBRANT_DATA_PATH=/absolute/path/to/store/databases/

    Useful Outputs

    FASTA file of identified virus genomes: 
        VIBRANT_phages_<input_file>/<input_file>.phages_combined.fna
    List of identified virus genomes: 
        VIBRANT_phages_<input_file>/<input_file>.phages_combined.txt
    GenBank file of identified virus genomes (if -f nucl): 
        VIBRANT_phages_<input_file>/<input_file>.phages_combined.gbk
        
    ./VIBRANT_test/VIBRANT_phages_test/test.phages_circular.fna
    ./VIBRANT_test/VIBRANT_phages_test/test.phages_combined.fna
    ./VIBRANT_test/VIBRANT_phages_test/test.phages_lysogenic.fna
    ./VIBRANT_test/VIBRANT_phages_test/test.phages_lytic.fna
    */
    tag "$sampleId"

    input:
    tuple val(sampleId), path(read1), path(read2), path(ctg)
    path vibrantdb

    output:
    tuple val(sampleId), path("${sampleId}_vibrant/VIBRANT_phages_*/*.phages_combined.fna"), emit: fasta optional true
    tuple val(sampleId), path("${sampleId}_vibrant/VIBRANT_results*/"), emit: results optional true
    

    script:
    """
    expandIfGz.py -i "${ctg}" -o "decompressed_contigs.fa"

    # -virome if enriched!
    VIBRANT_run.py \
        -t ${task.cpus} \
        -i decompressed_contigs.fa \
        -d ${vibrantdb}/databases/ \
        -m ${vibrantdb}/files/
        
    rm decompressed_contigs.fa

    mv VIBRANT_*/ ${sampleId}_vibrant/

    """
}

/*
--use-conda-off 
virsorter run --working-dir data/output/vs2 --seqfile test.fa --db-dir DB/virsorter2/ -j 8 


See if GZIPPED:
https://github.com/nf-core/modules/blob/master/modules/ssuissero/main.nf
*/
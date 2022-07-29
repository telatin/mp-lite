

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
    label 'process_medium'
    conda (params.enable_conda ? "bioconda::vibrant=1.2.1" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/vibrant:1.2.1--hdfd78af_2' :
        'quay.io/biocontainers/vibrant:1.2.1--hdfd78af_2' }"
        
    input:
    tuple val(sampleId), path(ctg)
    path vibrantdb

    output:
    tuple val(sampleId), path("${sampleId}_vibrant/VIBRANT_phages_*/*.phages_combined.fna"), emit: fasta optional true
    tuple val(sampleId), path("${sampleId}_vibrant/VIBRANT_results*/"), emit: results optional true
    

    script:
    def is_compressed = ctg.getName().endsWith(".gz") ? true : false
    def fasta_name = ctg.getName().replace(".gz", "")
   
    """
    if [ "$is_compressed" == "true" ]; then
        gzip -c -d $ctg > $fasta_name
    fi

    # -virome if enriched!
    VIBRANT_run.py \
        -t ${task.cpus} \
        -i "$fasta_name" \
        -d ${vibrantdb}/databases/ \
        -m ${vibrantdb}/files/
        
    

    mv VIBRANT_*/ ${sampleId}_vibrant/

    """
}


process VIRSORTER2 {
    /*


    --use-conda-off 
    virsorter run --working-dir data/output/vs2 --seqfile test.fa --db-dir DB/virsorter2/ -j 8 


    */
    tag "$sampleId"
    label 'process_high'

    conda (params.enable_conda ? "bioconda::virsorter=2.2.3" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/virsorter:2.2.3--pyhdfd78af_1' :
        'quay.io/biocontainers/virsorter:2.2.3--pyhdfd78af_1' }"

    input:
    tuple val(sampleId), path(ctg)
    path virsorterdb


    script:
    def is_compressed = ctg.getName().endsWith(".gz") ? true : false
    def fasta_name = ctg.getName().replace(".gz", "")
   
    """
    if [ "$is_compressed" == "true" ]; then
        gzip -c -d $ctg > $fasta_name
    fi

    python --version  > py.ver
    which virsorter   > vir.ver
    virsorter run --working-dir vs2 --seqfile "$fasta_name" \
         --db-dir "${virsorterdb}" -j ${task.cpus}
    
    """
}

process VIRFINDER {
    /*
    */
    tag "$sampleId"
    label 'process_medium'

    conda (params.enable_conda ? "bioconda::r-virfinder=1.1" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/r-virfinder:1.1--r41h87f3376_4  ' :
        'quay.io/biocontainers/r-virfinder:1.1--r41h87f3376_4  ' }"

    input:
    tuple val(sampleId), path(ctg)

    output:
    tuple val(sampleId), path("${sampleId}.csv")

    script:
    def is_compressed = ctg.getName().endsWith(".gz") ? true : false
    def fasta_name = ctg.getName().replace(".gz", "")
   
    """
    if [ "$is_compressed" == "true" ]; then
        gzip -c -d $ctg > $fasta_name
    fi
    mkdir -p tmp
    runvirfinder.py --input "$fasta_name" --output "${sampleId}.csv" --verbose --tmpdir ./tmp/ 2>&1 | tee "${sampleId}.log"
    """
}

process VIRFINDER_FASTA {
    /*
    */
    tag "$sampleId"

    conda (params.enable_conda ? 'bioconda::seqfu=1.9.3' : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/seqfu:1.9.3--hbd632db_0' :
        'quay.io/biocontainers/seqfu:1.9.3--hbd632db_0' }"
        
    input:
    tuple val(sampleId), path(ctg)
    tuple val(sampleId), path("virfinder.csv")


    output:
    tuple val(sampleId), path("${sampleId}_virfinder.fasta")

    script:
    def is_compressed = ctg.getName().endsWith(".gz") ? true : false
    def fasta_name = ctg.getName().replace(".gz", "")
   
    """
    if [ "$is_compressed" == "true" ]; then
        gzip -c -d $ctg > $fasta_name
    fi
    fu-virfilter --max-pvalue 0.05 --min-score 0.90 virfinder.csv "$fasta_name" > "${sampleId}_virfinder.fasta"
    
    """    
}
/*
See if GZIPPED:
https://github.com/nf-core/modules/blob/master/modules/ssuissero/main.nf
*/
process STATS {
    tag "${sampleId}"
    label 'process_low'
    input:
    tuple val(sampleId), path(ctg)

    conda (params.enable_conda ? "$baseDir/deps/sequtils.yaml" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/seqfu:1.9.3--hbd632db_0' :
        'quay.io/biocontainers/seqfu:1.9.3--hbd632db_0' }"
        
    output:
    tuple val(sampleId), path("*.txt"), emit: mqc

    script:
    """
    seqfu stats --multiqc ${sampleId}_mqc.txt $ctg > /dev/null
    """
}

process DEREP {
    tag "${sampleId}"
    label 'process_medium'
    input:
    tuple val(sampleId), path(read1), path(read2), path(ctg)

    conda (params.enable_conda ? "$baseDir/deps/sequtils.yaml" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/seqfu:1.9.3--hbd632db_0' :
        'quay.io/biocontainers/seqfu:1.9.3--hbd632db_0' }"
        
    output:
    tuple val(sampleId), path("${sampleId}_derep.fasta")

    script:
    """
    seqfu derep "$ctg" > "${sampleId}_derep.fasta"
    """
}

process SPLITFASTA {
    tag "${sampleId}"
    label 'process_low'
    
    input:
    tuple val(sampleId), path(read1), path(read2), path(ctg)
    val numfasta

    conda (params.enable_conda ? "$baseDir/deps/sequtils.yaml" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/seqfu:1.9.3--hbd632db_0' :
        'quay.io/biocontainers/seqfu:1.9.3--hbd632db_0' }"
    
    output:
    tuple val(sampleId), path("*.part_*.*")

    script:
    """
    seqkit split --by-part $numfasta "$ctg" --threads ${task.cpus} --line-width 500 --out-dir
    """
}
process MERGESTATS {
    label 'process_low'
    
    input:
    path "*"

    output:
    path "stats_mqc.txt"

    script:
    """
    # Get header
    grep "^#" \$(ls *.txt | head -n 1 ) > stats_mqc.txt
    grep "^Sample" \$(ls *.txt | head -n 1 ) | head -n 1 >> stats_mqc.txt
    # Get data
    grep -v "^#" *.txt | grep -v -w col10 | cut -f 2 -d : >> stats_mqc.txt
    """

}
 
process MULTIQC {
    label 'process_low'


    conda (params.enable_conda ? 'bioconda::multiqc=1.13a' : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/multiqc:1.13a--pyhdfd78af_1' :
        'quay.io/biocontainers/multiqc:1.13a--pyhdfd78af_1' }"

    publishDir "$params.outdir/", 
        mode: 'copy'
        
    input:
    path '*'  
    
    output:
    path 'multiqc_*'
     
    script:
    """
    multiqc . 
    """
} 
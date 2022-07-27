process STATS {
    tag "${sampleId}"
    input:
    tuple val(sampleId), path(read1), path(read2), path(ctg)

    output:
    tuple val(sampleId), path("*.txt"), emit: mqc

    script:
    """
    seqfu stats --multiqc ${sampleId}_mqc.txt $ctg > /dev/null
    """
}

process MERGESTATS {
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
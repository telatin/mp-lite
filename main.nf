/*  Input parameters   */
nextflow.enable.dsl = 2
params.samplesheet = "metadata.tsv"
params.outdir = "metaphage-lite"

params.vibrantdb = "$baseDir/DB/vibrant-1.2.1"
// prints to the screen and to the log
log.info """
         GMH MetaPhage Lite (version 1.0)
         ===================================
         samplesheet  : ${params.samplesheet}
         outdir       : ${params.outdir}

         vibrantdb    : ${params.vibrantdb}
         """
         .stripIndent()

sampledata = Channel
    .fromPath(params.samplesheet)
    .splitCsv(header:true)
    .map{ row -> tuple(row.Sample, file(row.R1), file(row.R2), file(row.Ctg) )  }
 
/* 
   check reference path exists 
*/

def vibrantPath = file(params.vibrantdb, checkIfExists: true)
 file("${params.vibrantdb}/databases/Pfam-A_v32.HMM.h3m", checkIfExists: true)      //check valid path with a sample file
 file("${params.vibrantdb}/files/VIBRANT_categories.tsv", checkIfExists: true)      //check valid path with a sample file
 

/*    Modules  */
include { STATS; MERGESTATS; MULTIQC } from './modules/utils'
include { VIBRANT } from './modules/mining'



workflow {
  STATS(sampledata)
  MERGESTATS(STATS.out.mqc.map{it -> it[1]}.collect())

  VIBRANT(sampledata, vibrantPath)
  
  MULTIQC(MERGESTATS.out)
}
 

# MetaPhage Lite

Compact pipeline for phage mining in metagenomes

```mermaid
graph TD
    A[Sample,Reads,Contigs] --> B1[VirFinder]
    A[Sample,Reads,Contigs] --> B2[VirSorter 2]
    A[Sample,Reads,Contigs] --> B3[Vibrant]
    A[Sample,Reads,Contigs] --> B4[Phigaro]
    B1 --> B1X[ToFasta]
    B1X --> C[Dereplicate]
    B2 --> C[Dereplicate]
    B3 --> C[Dereplicate]
    B4 --> C[Dereplicate]
    A --> D[Mapping]
    C --> D
 ```

### Citation

* Mattia Pandolfo, Andrea Telatin, Gioele Lazzari, Evelien M. Adriaenssens, Nicola Vitulo (2022) **MetaPhage: an automated pipeline for analyzing, annotating, and classifying bacteriophages in metagenomics sequencing data** [bioRxiv](https://doi.org/10.1101/2022.04.17.488583)

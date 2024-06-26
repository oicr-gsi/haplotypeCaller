# haplotypeCaller

Workflow to run the GATK Haplotype Caller

## Dependencies

* [GATK4](https://gatk.broadinstitute.org/hc/en-us/articles/360037225632-HaplotypeCaller)


## Usage

### Cromwell
```
java -jar cromwell.jar run haplotypeCaller.wdl --inputs inputs.json
```

### Inputs

#### Required workflow parameters:
Parameter|Value|Description
---|---|---
`bai`|File|The index for the BAM file to be used.
`bam`|File|The BAM file to be used.
`reference`|String|Assembly id, i.e. hg38
`intervalsToParallelizeBy`|String|Comma separated list of intervals to split by (e.g. chr1,chr2,chr3,chr4).
`mergeGVCFs.modules`|String|Required environment modules.


#### Optional workflow parameters:
Parameter|Value|Default|Description
---|---|---|---
`filterIntervals`|String?|None|Path to a BED file that restricts calling to only the regions in the file.
`outputFileNamePrefix`|String|basename(bam,".bam")|Prefix for output file.


#### Optional task parameters:
Parameter|Value|Default|Description
---|---|---|---
`splitStringToArray.lineSeparator`|String|","|line separator for intervalsToParallelizeBy. 
`splitStringToArray.jobMemory`|Int|1|Memory allocated to job (in GB).
`splitStringToArray.cores`|Int|1|The number of cores to allocate to the job.
`splitStringToArray.timeout`|Int|1|Maximum amount of time (in hours) the task can run for.
`callHaplotypes.extraArgs`|String?|None|Additional arguments to be passed directly to the command.
`callHaplotypes.intervalPadding`|Int|100|The number of bases of padding to add to each interval.
`callHaplotypes.intervalSetRule`|String|"INTERSECTION"|Set merging approach to use for combining interval inputs.
`callHaplotypes.erc`|String|"GVCF"|Mode for emitting reference confidence scores.
`callHaplotypes.jobMemory`|Int|24|Memory allocated to job (in GB).
`callHaplotypes.overhead`|Int|6|Java overhead memory (in GB). jobMemory - overhead == java Xmx/heap memory.
`callHaplotypes.cores`|Int|1|The number of cores to allocate to the job.
`callHaplotypes.timeout`|Int|72|Maximum amount of time (in hours) the task can run for.
`mergeGVCFs.jobMemory`|Int|24|Memory allocated to job (in GB).
`mergeGVCFs.overhead`|Int|6|Java overhead memory (in GB). jobMemory - overhead == java Xmx/heap memory.
`mergeGVCFs.cores`|Int|1|The number of cores to allocate to the job.
`mergeGVCFs.timeout`|Int|24|Maximum amount of time (in hours) the task can run for.


### Outputs

Output | Type | Description | Labels
---|---|---|---
`outputVcf`|File|output vcf|vidarr_label: outputVcf
`outputVcfIndex`|File|output vcf index|vidarr_label: outputVcfIndex


## Commands
This section lists commands run by haplotypeCaller workflow
 
* Running haplotypeCaller
 
Workflow to run the GATK Haplotype Caller
 
### Parsing intervals
 
```
     echo INTERVALS_TO_PARALLELIZE_BY | tr 'LINE_SEPARATOR' '\n'
```
 
### Running haplotypeCaller
 
```
     set -euo pipefail
 
     gatk --java-options -Xmx[JOB_MEMORY - OVERHEAD]G 
        HaplotypeCaller 
     -R REFERENCE_FASTA
     -I INPUT_BAM
     -L INTERVAL_FILE
     -L FILTER_INTERVALS -isr INTERVAL_SetRule -ip INTERVAL_Padding # Optional
     -D DBSNP_VCF
     -ERC ERC EXTRA_ARGUMENTS
     -O OUTPUT
```
 
### Merging vcf files
 
```
     set -euo pipefail
 
     gatk --java-options "-Xmx[JOB_MEMORY - OVERHEAD]G" MergeVcfs
     -I VCF_FILES
     -O OUTPUT
```
## Support

For support, please file an issue on the [Github project](https://github.com/oicr-gsi) or send an email to gsi@oicr.on.ca .

_Generated with generate-markdown-readme (https://github.com/oicr-gsi/gsi-wdl-tools/)_

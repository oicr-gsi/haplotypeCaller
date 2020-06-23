# haplotypeCaller

Workflow to run the GATK Haplotype Caller

## Overview

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
`intervalsToParallelizeBy`|String|Comma separated list of intervals to split by (e.g. chr1,chr2,chr3,chr4).
`callHaplotypes.dbsnpFilePath`|String|The dbSNP VCF to call against.
`callHaplotypes.modules`|String|Required environment modules.
`callHaplotypes.refFasta`|String|The file path to the reference genome.
`mergeGVCFs.modules`|String|Required environment modules.


#### Optional workflow parameters:
Parameter|Value|Default|Description
---|---|---|---
`filterIntervals`|File?|None|A BED file that restricts calling to only the regions in the file.
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

Output | Type | Description
---|---|---
`outputVcf`|File|output vcf
`outputVcfIndex`|File|output vcf index


## Niassa + Cromwell

This WDL workflow is wrapped in a Niassa workflow (https://github.com/oicr-gsi/pipedev/tree/master/pipedev-niassa-cromwell-workflow) so that it can used with the Niassa metadata tracking system (https://github.com/oicr-gsi/niassa).

* Building
```
mvn clean install
```

* Testing
```
mvn clean verify \
-Djava_opts="-Xmx1g -XX:+UseG1GC -XX:+UseStringDeduplication" \
-DrunTestThreads=2 \
-DskipITs=false \
-DskipRunITs=false \
-DworkingDirectory=/path/to/tmp/ \
-DschedulingHost=niassa_oozie_host \
-DwebserviceUrl=http://niassa-url:8080 \
-DwebserviceUser=niassa_user \
-DwebservicePassword=niassa_user_password \
-Dcromwell-host=http://cromwell-url:8000
```

## Support

For support, please file an issue on the [Github project](https://github.com/oicr-gsi) or send an email to gsi@oicr.on.ca .

_Generated with generate-markdown-readme (https://github.com/oicr-gsi/gsi-wdl-tools/)_

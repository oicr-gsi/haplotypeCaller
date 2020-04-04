# haplotype

Workflow to run the GATK Haplotype Caller

## Overview

## Dependencies

* [GATK4](https://gatk.broadinstitute.org/hc/en-us/articles/360037225632-HaplotypeCaller)


## Usage

### Cromwell
```
java -jar cromwell.jar run haploptypecaller.wdl --inputs inputs.json
```

### Inputs

#### Required workflow parameters:
Parameter|Value|Description
---|---|---
`bamIndices`|Array[File]+|The indicies for the BAM files to be used
`bams`|Array[File]+|The BAM files to be used
`dbsnpFilePath`|String|The dbSNP VCF to call against
`outputFileNamePrefix`|String|The desired output file name
`referenceChromosomeSizes`|String|
`referenceModule`|String|The environment module containing the reference genome and/or dbSNP
`referenceSequence`|String|The file path to the reference genome
`callHaplotypes.intervalPadding`|Int|The number of bases of padding to add to each interval


#### Optional workflow parameters:
Parameter|Value|Default|Description
---|---|---|---
`filterIntervals`|String?|None|A BED file that restricts calling to only the regions in the file
`intervalPadding`|Int|0|The number of bases of padding to add to each interval
`modules`|String|"gatk/4.1.5.0"|The environment modules for GATK
`timeout`|Int|24|The maximum runtime of the workflow in hours.


#### Optional task parameters:
Parameter|Value|Default|Description
---|---|---|---
`callHaplotypes.extraArgs`|String|""|Additional arguments to be passed directly to the command.
`callHaplotypes.mem`|Int|8|The memory for this task in GB
`callHaplotypes.timeout`|Int|24|The maximum runtime of the task in hours.
`combine.mem`|Int|8|The memory for this task in GB
`combine.timeout`|String|24|The maximum runtime of the task in hours.


### Outputs

Output | Type | Description
---|---|---
`vcf`|File|The VCF of for the input BAMs
`index`|File|The index of the VCF


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

_Generated with wdl_doc_gen (https://github.com/oicr-gsi/wdl_doc_gen/)_

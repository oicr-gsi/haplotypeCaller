version 1.0

workflow haplotypeCaller {
  input {
    File bai
    File bam
    File? filterIntervals
    String outputFileNamePrefix = basename(bam, ".bam")
    String intervalsToParallelizeBy
  }
  parameter_meta {
      bai: "The index for the BAM file to be used."
      bam: "The BAM file to be used."
      filterIntervals: "A BED file that restricts calling to only the regions in the file."
      outputFileNamePrefix: "Prefix for output file."
      intervalsToParallelizeBy: "Comma separated list of intervals to split by (e.g. chr1,chr2,chr3,chr4)."
  }

  meta {
      author: "Andre Masella, Xuemei Luo"
      description: "Workflow to run the GATK Haplotype Caller"
      dependencies: [{
          name: "GATK4",
          url: "https://gatk.broadinstitute.org/hc/en-us/articles/360037225632-HaplotypeCaller"
      }]
      output_meta: {
        outputVcf: "output vcf",
        outputVcfIndex: "output vcf index"
      }
  }

  call splitStringToArray {
    input:
      intervalsToParallelizeBy = intervalsToParallelizeBy
  }
  
  scatter (intervals in splitStringToArray.out) {
     call callHaplotypes {
       input:
         bamIndex = bai,
         bam = bam,
         interval = intervals[0],
         filterIntervals = filterIntervals,
         outputFileNamePrefix = outputFileNamePrefix,
     }
  }

  call mergeGVCFs {
    input:
      outputFileNamePrefix = outputFileNamePrefix,
      vcfs = callHaplotypes.output_vcf
  }
  output {
    File outputVcf = mergeGVCFs.mergedVcf
    File outputVcfIndex = mergeGVCFs.mergedVcfTbi
  }

}

task splitStringToArray {
  input {
    String intervalsToParallelizeBy
    String lineSeparator = ","
    Int jobMemory = 1
    Int cores = 1
    Int timeout = 1
  }

  command <<<
    echo "~{intervalsToParallelizeBy}" | tr '~{lineSeparator}' '\n'
  >>>

  output {
    Array[Array[String]] out = read_tsv(stdout())
  }

  runtime {
    memory: "~{jobMemory} GB"
    cpu: "~{cores}"
    timeout: "~{timeout}"
  }

  parameter_meta {
    intervalsToParallelizeBy: "Interval string to split (e.g. chr1,chr2,chr3,chr4)."
    lineSeparator: "line separator for intervalsToParallelizeBy. "
    jobMemory: "Memory allocated to job (in GB)."
    cores: "The number of cores to allocate to the job."
    timeout: "Maximum amount of time (in hours) the task can run for."
  }
}

task callHaplotypes {
  input {
    File bamIndex
    File bam
    String dbsnpFilePath
    String? extraArgs
    String interval
    File? filterIntervals
    Int intervalPadding = 100
    String intervalSetRule = "INTERSECTION"
    String erc = "GVCF"
    String modules
    String refFasta
    String outputFileNamePrefix
    Int jobMemory = 24
    Int overhead = 6
    Int cores = 1
    Int timeout = 72
  }
 
  String outputName = "~{outputFileNamePrefix}.~{interval}.g.vcf.gz"

  command <<<
    set -euo pipefail

    gatk --java-options -Xmx~{jobMemory - overhead}G \
      HaplotypeCaller \
      -R ~{refFasta} \
      -I ~{bam} \
      -L ~{interval} \
      ~{if defined(filterIntervals) then "-L ~{filterIntervals} -isr ~{intervalSetRule} -ip ~{intervalPadding}" else ""} \
      -D ~{dbsnpFilePath} \
      -ERC ~{erc} ~{extraArgs} \
      -O "~{outputName}"
  >>>

  output {
    File output_vcf = "~{outputName}"
  }

  runtime {
    memory: "~{jobMemory} GB"
    cpu: "~{cores}"
    timeout: "~{timeout}"
    modules: "~{modules}"
  }

  parameter_meta {
    bamIndex: "The index for the BAM file to be used."
    bam: "The BAM file to be used."
    dbsnpFilePath: "The dbSNP VCF to call against."
    extraArgs: "Additional arguments to be passed directly to the command."
    filterIntervals: "A BED file that restricts calling to only the regions in the file."
    intervalPadding: "The number of bases of padding to add to each interval."
    intervalSetRule: "Set merging approach to use for combining interval inputs."
    interval: "The interval (chromosome) for this shard to work on."
    erc: "Mode for emitting reference confidence scores."
    modules: "Required environment modules."
    refFasta: "The file path to the reference genome."
    outputFileNamePrefix: "Prefix for output file."
    jobMemory:  "Memory allocated to job (in GB)."
    overhead: "Java overhead memory (in GB). jobMemory - overhead == java Xmx/heap memory."
    cores: "The number of cores to allocate to the job."
    timeout: "Maximum amount of time (in hours) the task can run for."
  }
  meta {
      output_meta: {
          output_vcf: "Output vcf file for this interval"
      }
  }
}

task mergeGVCFs {
  input {
    String modules
    Array[File] vcfs
    String outputFileNamePrefix
    Int jobMemory = 24
    Int overhead = 6
    Int cores = 1
    Int timeout = 24
  }

  String outputName = "~{outputFileNamePrefix}.g.vcf.gz"

  command <<<
    set -euo pipefail

    gatk --java-options "-Xmx~{jobMemory - overhead}G" MergeVcfs \
    -I ~{sep=" -I " vcfs} \
    -O ~{outputName}
  >>>

  runtime {
    memory: "~{jobMemory} GB"
    cpu: "~{cores}"
    timeout: "~{timeout}"
    modules: "~{modules}"
  }

  output {
    File mergedVcf = "~{outputName}"
    File mergedVcfTbi = "~{outputName}.tbi"
  }

  parameter_meta {
    modules: "Required environment modules."
    vcfs: "Vcf's from scatter to merge together."
    jobMemory:  "Memory allocated to job (in GB)."
    overhead: "Java overhead memory (in GB). jobMemory - overhead == java Xmx/heap memory."
    cores: "The number of cores to allocate to the job."
    timeout: "Maximum amount of time (in hours) the task can run for."
  }

  meta {
    output_meta: {
      mergedVcf: "Merged vcf",
      mergedVcfTbi: "Merged vcf index"
    }
  }

}



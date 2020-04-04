version 1.0

struct Interval {
   String range
   String fileSuffix
}

workflow haplotype {
  input {
    Array[File]+ bamIndices
    Array[File]+ bams
    String dbsnpFilePath
    String? filterIntervals
    Int intervalPadding = 0
    String modules = "gatk/4.1.5.0"
    String outputFileNamePrefix
    String referenceChromosomeSizes
    String referenceModule
    String referenceSequence
    Int timeout = 24
  }
  parameter_meta {
      bamIndices: "The indicies for the BAM files to be used"
      bams: "The BAM files to be used"
      dbsnpFilePath: "The dbSNP VCF to call against"
      filterIntervals: "A BED file that restricts calling to only the regions in the file"
      intervalPadding: "The number of bases of padding to add to each interval"
      modules: "The environment modules for GATK"
      outputFileNamePrefix: "The desired output file name"
      referenceChromoesomeSizes: "The file path to the chromosome sizes. These are used for parallelisation"
      referenceModule: "The environment module containing the reference genome and/or dbSNP"
      referenceSequence: "The file path to the reference genome"
      timeout: "The maximum runtime of the workflow in hours."
  }

  meta {
      author: "Andre Masella"
      description: "Workflow to run the GATK Haplotype Caller"
      dependencies: [{
          name: "GATK4",
          url: "https://gatk.broadinstitute.org/hc/en-us/articles/360037225632-HaplotypeCaller"
      }]
  }

  call bed2intervals {
    input:
      referenceChromosomeSizes = referenceChromosomeSizes,
      referenceModule = referenceModule
  }
  scatter (interval in bed2intervals.intervals) {
     call callHaplotypes {
       input:
         bamIndices = bamIndices,
         bams = bams,
         dbsnpFilePath = dbsnpFilePath,
         filterIntervals = filterIntervals,
         interval = interval.range,
         modules = modules,
         outputFileNamePrefix = "~{outputFileNamePrefix}~{interval.fileSuffix}",
         referenceModule = referenceModule,
         referenceSequence = referenceSequence
     }
  }

  call combine{
    input:
      modules = modules,
      outputFileNamePrefix = outputFileNamePrefix,
      vcfs = callHaplotypes.rawVcf
  }
  output {
    File vcf = combine.vcf
    File index = combine.index
  }

}

task bed2intervals {
  input {
    String referenceChromosomeSizes
    String referenceModule
  }
  parameter_meta {
      referenceChromoesomeSizes: "The file path to the chromosome sizes. These are used for parallelisation"
      referenceModule: "The environment module containing the reference genome and/or dbSNP"
  }
  command <<<
    awk 'BEGIN {print "[" } {print "{\"range\":\""$1":"$2"-"$3"\",\"fileSuffix\":\""$1"_"$2"_"$3"\"}"(NR == 1 ? "" : ",")} END {print"]"}' ~{referenceChromosomeSizes}
  >>>

  runtime {
    memory: "~{100} MB"
    modules: "~{referenceModule}"
  }

  output {
    Array[Interval] intervals = read_json(stdout())
  }
}

task callHaplotypes {
  input {
    Array[File]+ bamIndices
    Array[File]+ bams
    String dbsnpFilePath
    String extraArgs = ""
    String? filterIntervals
    Int intervalPadding
    String interval
    Int mem = 8
    String modules
    String outputFileNamePrefix
    String referenceModule
    String referenceSequence
    Int timeout = 24
  }
  parameter_meta {
      bamIndices: "The indicies for the BAM files to be used"
      bams: "The BAM files to be used"
      dbsnpFilePath: "The dbSNP VCF to call against"
      extraArgs: "Additional arguments to be passed directly to the command."
      filterIntervals: "A BED file that restricts calling to only the regions in the file"
      intervalPadding: "The number of bases of padding to add to each interval"
      interval: "The interval (chromosome) for this shard to work on."
      mem: "The memory for this task in GB"
      modules: "The environment modules for GATK"
      outputFileNamePrefix: "The desired output file name"
      referenceModule: "The environment module containing the reference genome and/or dbSNP"
      referenceSequence: "The file path to the reference genome"
      timeout: "The maximum runtime of the task in hours."
  }
  meta {
      output_meta : {
          rawVcf: "Output .vcf file for this interval"
      }
  }
  Array[String] bamArgs = prefix("--input ", bams)

  command <<<
    gatk --java-options -Xmx~{mem-1}g \
      HaplotypeCaller \
      --verbosity INFO \
      --intervals "~{interval}" \
      ~{if defined(filterIntervals) then "--interval ~{filterIntervals} --interval-merging-rule OVERLAPPING_ONLY" else ""} \
      --interval-padding ~{intervalPadding} \
      --dbsnp ~{dbsnpFilePath} \
      --reference ~{referenceSequence} \
      ~{sep=" " bamArgs} \
      ~{extraArgs} \
      --output "~{outputFileNamePrefix}.vcf"
  >>>

  runtime {
    memory: "~{mem} GB"
    modules: "~{modules} ~{referenceModule}"
    timeout: "~{timeout}"
  }

  output {
    File rawVcf = "~{outputFileNamePrefix}.vcf"
  }
}

task combine {
  input{
    Int mem = 8
    String modules
    String outputFileNamePrefix
    String timeout = 24
    Array[File] vcfs
  }
  Array[String] vcfArgs = prefix("--INPUT ", vcfs)

  command <<<
    gatk --java-options -Xmx~{mem-1}g \
      SortVcf \
      ~{sep=" " vcfArgs} \
      --OUTPUT "./~{outputFileNamePrefix}.g.vcf.gz"
  >>>

  runtime {
    memory: "~{mem} GB"
    modules: "~{modules}"
    timeout: "~{timeout}"
  }

  output {
    File vcf = "~{outputFileNamePrefix}.g.vcf.gz"
    File index = "~{outputFileNamePrefix}.g.vcf.gz.tbi"
  }

  parameter_meta {
    mem: "The memory for this task in GB"
    modules: "The environment modules for GATK"
    outputFileNamePrefix: "The desired output file name"
    timeout: "The maximum runtime of the task in hours."
    vcfs: "Input txt file containing file paths for all VCFs to be combined."
  }

  meta {
    output_meta: {
      vcf: "The VCF of for the input BAMs",
      index: "The index of the VCF"
    }
  }
}



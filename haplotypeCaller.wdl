version 1.0

struct genomicResources {
  String modules
  String data_modules
  String refFasta
  String dbsnpFilePath
}

workflow haplotypeCaller {
  input {
    File bai
    File bam
    String? filterIntervals
    String outputFileNamePrefix = basename(bam, ".bam")
    String reference
    String intervalsToParallelizeBy
    Boolean rnaMode = false
    Boolean GVCF = true
    String local_code_modulefile_path = "/home/ubuntu/local_modules/gsi/modulator/modulefiles/Ubuntu24.04"
    String local_data_modulefile_path = "/home/ubuntu/local_modules/gsi/modulator/modulefiles/data"
  }
  parameter_meta {
      bai: "The index for the BAM file to be used."
      bam: "The BAM file to be used."
      filterIntervals: "Path to a BED file that restricts calling to only the regions in the file."
      reference: "Assembly id, i.e. hg38"
      outputFileNamePrefix: "Prefix for output file."
      intervalsToParallelizeBy: "Comma separated list of intervals to split by (e.g. chr1,chr2,chr3,chr4)."
      rnaMode: "flag to indicate whether to run RNA sequencing data. Default is false (DNA mode)."
      GVCF: "flag to indicated whether the output is VCF or GVCF (default)."
      local_code_modulefile_path: "Path to locally build code modulefiles"
      local_data_modulefile_path: "Path to locally build data modulefiles"
  }

  meta {
      author: "Andre Masella, Xuemei Luo, Monica L. Rojas-Pena"
      description: "Workflow to run the GATK Haplotype Caller, a tool from GATK suite capable of calling SNPs and indels simultaneously via local de-novo assembly of haplotypes in an active region. The workflow accepts bam files as the main input, generates vcf and gvcf files. Annotates variants with dbSNP information, when available. Supports RNA mode."
      dependencies: [{
          name: "GATK4",
          url: "https://gatk.broadinstitute.org/hc/en-us/articles/360037225632-HaplotypeCaller"
      }]
    output_meta: {
    outputVcf: {
        description: "output vcf",
        vidarr_label: "outputVcf"
    },
    outputVcfIndex: {
        description: "output vcf index",
        vidarr_label: "outputVcfIndex"
    }
}
  }

  Map[String,genomicResources] resources = {
    "hg19": {"modules":  "gatk/4.2.6.1",
             "data_modules": "hg19/p13 hg19-dbsnp-leftaligned/138",
             "refFasta": "/home/ubuntu/module_data/hg19_data/hg19_random.fa",
             "dbsnpFilePath": "/home/ubuntu/module_data/hg19_data/dbsnp_138.hg19.leftAligned.vcf.gz"
    },
    "hg38": {"modules":   "gatk/4.2.6.1",
             "data_modules": "hg38/p12 hg38-dbsnp/138",
             "refFasta":  "/home/ubuntu/module_data/hg38_data/hg38_random.fa",
             "dbsnpFilePath": "/home/ubuntu/module_data/hg38_data/dbsnp_138.hg38.vcf.gz"
    }
  }
  

     call callHaplotypes {
       input:
         bamIndex = bai,
         bam = bam,
         filterIntervals = filterIntervals,
         outputFileNamePrefix = outputFileNamePrefix,
         modules  = resources[reference].modules,
         data_modules = resources[reference].data_modules,
         refFasta = resources[reference].refFasta,
         dbsnpFilePath = resources[reference].dbsnpFilePath,
         local_code_modulefile_path = local_code_modulefile_path, 
         local_data_modulefile_path = local_data_modulefile_path,
         rnaMode = rnaMode,
         GVCF = GVCF
     }
  
  output {
    File outputVcf = callHaplotypes.output_vcf
    File outputVcfIndex = callHaplotypes.output_vcf_index
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
    String? filterIntervals
    Int intervalPadding = 100
    String intervalSetRule = "INTERSECTION"
    String modules
    String data_modules
    String local_code_modulefile_path
    String local_data_modulefile_path
    String refFasta
    String outputFileNamePrefix
    Int jobMemory = 16
    Int overhead = 4
    Int cores = 1
    Int timeout = 72
    Boolean rnaMode
    Boolean GVCF
  }
 

String outputName = "~{outputFileNamePrefix}~{if GVCF then '.g.vcf.gz' else '.vcf.gz'}"


  command <<<
    set -euo pipefail
    # Create python symlink which used in gatk python wrapper
    mkdir -p ./temp_bin
    ln -sf $(which python3) ./temp_bin/python
    export PATH="./temp_bin:$PATH"

    . /usr/share/modules/init/bash
    module use ~{local_code_modulefile_path }
    module load ~{modules}
    module use ~{local_data_modulefile_path }
    module load ~{data_modules}

    gatk --java-options -Xmx~{jobMemory - overhead}G \
      HaplotypeCaller \
      -R ~{refFasta} \
      -I ~{bam} \
      ~{if defined(filterIntervals) 
      then "-L ~{filterIntervals} -isr ~{intervalSetRule} -ip ~{intervalPadding}" 
      else ""} \
      -D ~{dbsnpFilePath} \
      ~{if rnaMode then "--dont-use-soft-clipped-bases --standard-min-confidence-threshold-for-calling 20 --max-reads-per-alignment-start 0 -G StandardAnnotation -G StandardHCAnnotation" 
      else ""} \
      ~{if GVCF then "-ERC GVCF" else "-ERC NONE"} \
      ~{extraArgs} \
      -O "~{outputName}" \
      --create-output-variant-index
  >>>


  output {
    File output_vcf = "~{outputName}"
    File output_vcf_index= "~{outputName}.tbi"
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
    filterIntervals: "Path to a BED file that restricts calling to only the regions in the file."
    intervalPadding: "The number of bases of padding to add to each interval."
    intervalSetRule: "Set merging approach to use for combining interval inputs."
    modules: "Required environment modules."
    data_modules: "Names and versions of data modules to load"
    local_code_modulefile_path: "Path to locally build code modulefiles"
    local_data_modulefile_path: "Path to locally build data modulefiles"
    refFasta: "The file path to the reference genome."
    outputFileNamePrefix: "Prefix for output file."
    jobMemory:  "Memory allocated to job (in GB)."
    overhead: "Java overhead memory (in GB). jobMemory - overhead == java Xmx/heap memory."
    cores: "The number of cores to allocate to the job."
    timeout: "Maximum amount of time (in hours) the task can run for."
    rnaMode: "flag to indicate whether to run RNA sequencing data. Default is false (DNA mode)."
    GVCF: "flag to indicated whether the output is VCF or GVCF (default)."
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
    String local_code_modulefile_path
    Int jobMemory = 24
    Int overhead = 6
    Int cores = 1
    Int timeout = 24
    Boolean rnaMode
    Boolean GVCF
  }

  String outputName = "~{outputFileNamePrefix}" + (if GVCF then ".g.vcf.gz" else ".vcf.gz")

  command <<<
    set -euo pipefail
    . /usr/share/modules/init/bash
    module use ~{local_code_modulefile_path }
    module load ~{modules}

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
    local_code_modulefile_path: "Path to locally build code modulefiles"
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
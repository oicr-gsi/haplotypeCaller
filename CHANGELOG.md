# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## 2.3.0 - 2025-03-04
### Removed
- Removed String erc = "GVCF" from the task and now is controlled dinamically via ERC flag

### Changed
- The output file extension now conditionally depends on the ERC flag

### Added
- New parameter rnaMode: A boolean flag to handle RNA-seq data (dfault is false)
- New parameter GVCF: for flexibility to choose output format (defaul is true)
- [GRD-872](https://jira.oicr.on.ca/browse/GRD-872)

## 2.2.0 - 2024-06-25
### Added
- add vidarr labels to outputs (changes to medata only)
[GRD-797](https://jira.oicr.on.ca/browse/GRD-797) 

## 2.1.1 - 2024-01-23
### Changed
- update GATK version from 4.1.7.0 to 4.2.6.1

## 2.1.0 - 2023-07-07
### Changed
- moving assembly-specific settings into wdl
- [GRD-662](https://jira.oicr.on.ca/browse/GRD-662)

## 2.0.3 - 2022-08-31
### Added
- added `haplotypeCaller_by_tumor_group` workflow for clinical

## 2.0.2 - 2021-10-06
### Changed
- changed the type of filterIntervals to String? to avoid troubles with EXTERNAL type

## 2.0.1 - 2021-06-01
### Changed
- migrate to Vidarr

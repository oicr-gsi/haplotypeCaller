#!/bin/bash
set -o nounset
set -o errexit
set -o pipefail

#enter the workflow's final output directory ($1)
cd $1

#find all files, return their md5sums to std out
ls | sort

for f in $(find -name *.vcf.gz);do zgrep -v ^# $f | awk 'NF{NF--};1' | md5sum;done | sort -V

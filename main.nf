#!/usr/bin/env nextflow

// Copyright (C) 2022 IRB Barcelona

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

params.help = null
params.input_folder = null
params.output_folder = "SV-simulation_output"
params.path_to_sim_it = "Sim-it/Sim-it1.3.2.pl"

log.info ""
log.info "-----------------------------------------------------------------------"
log.info "Nextflow pipeline to simulate tumor/normal long read data"
log.info "-----------------------------------------------------------------------"
log.info "Copyright (C) IRB Barcelona"
log.info "This program comes with ABSOLUTELY NO WARRANTY; for details see LICENSE"
log.info "This is free software, and you are welcome to redistribute it"
log.info "under certain conditions; see LICENSE for details."
log.info "--------------------------------------------------------"
if (params.help) {
    log.info "--------------------------------------------------------"
    log.info "                     USAGE                              "
    log.info "--------------------------------------------------------"
    log.info ""
    log.info "nextflow run main.nf [OPTIONS]"
    log.info ""
    log.info "Mandatory arguments:"
    log.info "--input_folder              FOLDER                 Input folder containing one germline genome fasta for each sample"
    log.info "--reference_genome          FILE                   Reference genome fasta file for minimap2 alignment"
    log.info ""
    log.info "Optional arguments:"
    log.info '--output_folder             FOLDER                 Output folder (default: SV-simulation_output)'
    log.info '--path_to_sim_it            PATH                   Path to sim-it perl script (default: Sim-it/Sim-it1.3.2.pl)'
    log.info ""
    log.info "Flags:"
    log.info "--help                                             Display this message"
    log.info ""
    exit 1
}

assert (params.input_folder != null) : "please provide the --input_folder option"

input_files = Channel.fromPath( params.input_folder+'/*gz' )


process sim_it {

  publishDir params.output_folder+"/PVALS/", mode: 'copy', pattern: "*pvalue*"

  input:
  file input_fasta from input_files

  output:
  file '*pvalue' into skatpvalues

  shell:
  '''
  $f=!{input_fasta}
  sed "s/FASTA/$f/" !{baseDir}/files/config_g.txt
  sed "s/FASTA/$f/" !{baseDir}/files/config_t.txt
  perl !{params.path_to_sim_it} -c !{baseDir}/files/config_g.txt -o germline_reads
  perl !{params.path_to_sim_it} -c !{baseDir}/files/config_t.txt -o tumor_reads
  '''
}
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
params.input_folder = null
params.reference_genome = null
params.output_folder = "SV-simulation_output"
params.path_to_sim_it = "Sim-it/Sim-it1.3.2.pl"
params.cpu = "8"
params.mem = "48"

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
    log.info "--input_folder              FOLDER                 Input folder containing one normal genome fasta for each sample"
    log.info "--reference_genome          FILE                   Reference genome fasta file for minimap2 alignment"
    log.info "--error_profile             FILE                   Error profile file, given by Sim-it"
    log.info ""
    log.info "Optional arguments:"
    log.info '--output_folder             FOLDER                 Output folder (default: SV-simulation_output)'
    log.info '--path_to_sim_it            PATH                   Path to sim-it perl script (default: Sim-it/Sim-it1.3.2.pl)'
    log.info "--cpu                       INTEGER                Number of cpu to use (default: 2)"
    log.info "--mem                       INTEGER                Memory in GB (default: 20)"
    log.info ""
    log.info "Flags:"
    log.info "--help                                             Display this message"
    log.info ""
    exit 1
}

assert (params.input_folder != null) : "please provide the --input_folder option"
assert (params.reference_genome != null) : "please provide the --reference_genome option"
assert (params.error_profile != null) : "please provide the --error_profile option"

input_files = Channel.fromPath( params.input_folder+'/*gz' )
ref = file(params.reference_genome)
error_profile = file(params.error_profile)

process sim_it {
  cpus params.cpu
  memory params.mem+'GB'
  tag {sample}

  publishDir params.output_folder+"/FASTA/", mode: 'copy', pattern: "SV_simulation*.fasta.gz"

  input:
  file input_fasta from input_files
  file error_profile

  output:
  file 'SV_simulation*.fasta.gz' into sv_fasta mode flatten

  shell:
  sample = input_fasta.baseName
  '''
  source ~/.profile

  cp !{error_profile} error_profile.txt

  f=!{input_fasta}
  cp !{baseDir}/files/config_*.txt .
  sed -i "s/FASTA/$f/" config_g.txt
  sed -i "s/FASTA/$f/" config_t.txt
  perl !{params.path_to_sim_it} -c config_g.txt -o normal_reads
  perl !{params.path_to_sim_it} -c config_t.txt -o tumor_reads
  mv normal_reads/SV_simulation.fasta SV_simulation_normal.fasta && gzip -c SV_simulation_normal.fasta > SV_simulation_normal.fasta.gz
  mv tumor_reads/SV_simulation.fasta SV_simulation_tumor.fasta && gzip -c SV_simulation_tumor.fasta > SV_simulation_tumor.fasta.gz
  '''
}

process minimap2 {
  cpus params.cpu
  memory params.mem+'GB'
  errorStrategy { task.exitStatus == 143 ? 'retry' : 'terminate' }
  maxRetries = 4

  publishDir params.output_folder+"/BAM/", mode: 'copy', pattern: "*bam*"

  input:
  file svf from sv_fasta
  file ref

  output:
  file '*bam*' into sv_bam

  shell:
  tag = svf.baseName.replace(".fasta","")
  '''
  minimap2 -a -x map-ont !{ref} !{svf} > tmp
  samtools view -S -b tmp > !{tag}.bam
  '''
}

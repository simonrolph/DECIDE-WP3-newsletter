#!/bin/bash 
#SBATCH --partition=short-serial-4hr
#SBATCH --account=short4hr
#SBATCH --job-name=newsletterRender
#SBATCH -o out/%A_%a.out
#SBATCH -e err/%A_%a.err
#SBATCH --time=5:00
#SBATCH --array=1-854
#SBATCH --mem=4000
module add jasr
Rscript 2_render_newsletter_slurm.R ${SLURM_ARRAY_TASK_ID}

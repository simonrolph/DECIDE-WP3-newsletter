#!/bin/bash 
#SBATCH --partition=test
#SBATCH --job-name=newsletterRender
#SBATCH -o out/%A_%a.out
#SBATCH -e err/%A_%a.err
#SBATCH --time=5:00
#SBATCH --array=1-10
#SBATCH --mem=8000
module add jasr
Rscript 2_render_newsletter_slurm.R ${SLURM_ARRAY_TASK_ID}
#!/bin/bash 
#SBATCH --partition=short-serial-4hr
#SBATCH --account=short4hr
#SBATCH --job-name=newsletterRender
#SBATCH -o out/%A_%a.out
#SBATCH -e err/%A_%a.err
#SBATCH --time=5:00
#SBATCH --array=153,155,162,167,173,174,191,192,292,297,300,307,310,318,325,328,336,385,391,402,406,412,418,532,535,560,568,571
#SBATCH --mem=4000
module add jasr
Rscript 2_render_newsletter_slurm.R ${SLURM_ARRAY_TASK_ID}

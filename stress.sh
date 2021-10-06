#!/bin/bash
#
#SBATCH --job-name=stress
#SBATCH --nodelist=test-desktop
#SBATCH --output=/home/test/stress
#SBATCH -c 4
#SBATCH --ntasks=1
#SBATCH --time=40:00
#SBATCH --mem-per-cpu=1

stress --cpu  4 --timeout 20

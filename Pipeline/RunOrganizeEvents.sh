#!/bin/bash
#PBS -l walltime=10:00:00
#PBS -l select=1:ncpus=1:mem=1gb

module load anaconda3/personal
source activate RKerasEnv

cd $PBS_O_WORKDIR

echo "R is about to run"
R --vanilla < OrganizeEvents.R
echo "R is finished running"


#end of file

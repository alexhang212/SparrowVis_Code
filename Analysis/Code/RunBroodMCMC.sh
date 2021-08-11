#!/bin/bash
#PBS -l walltime=40:00:00
#PBS -l select=1:ncpus=2:mem=2gb

cd $PBS_O_WORKDIR

sleep $[ ( $RANDOM % 60 ) +30]


module load anaconda3/personal
source activate MCMCEnv

echo "R is about to run"
R --vanilla < BroodAnalysis_cluster.R
echo "R is finished running"


#end of file

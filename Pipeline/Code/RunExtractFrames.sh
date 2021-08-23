#!/bin/bash
#PBS -l walltime=10:00:00
#PBS -l select=1:ncpus=8:mem=20gb

module load anaconda3/personal

cd $PBS_O_WORKDIR

echo "R is about to run"
python ExtractFrames.py
echo "R is finished running"


#end of file

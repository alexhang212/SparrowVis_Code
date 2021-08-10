#!/bin/bash
#PBS -l walltime=20:00:00
#PBS -l select=1:ncpus=8:mem=1gb

module load anaconda3/personal
source activate SparrowVis

work_dir=$PBS_O_WORKDIR/$PBS_ARRAY_INDEX #create new directory for each sub run
mkdir $work_dir
cd $work_dir

#initialize array to store vid names:
VidArr=()

#Get all video files from MeerkatInput
for entry in "../../MeerkatInput"/*
do
VidArr+=("$entry")
#echo $entry

done

#get index of video to run
Index=$PBS_ARRAY_INDEX
let Index-=1
echo $Index

vid=${VidArr[$Index]} # path to video to run
vidBase=$(basename -- "$vid") #vid with extension
vidName=$(basename -- "$vid"| cut -f 1 -d '.') # get name of video without extension or path
echo $vidBase
echo $vidName

#copy model and video to working directory:
cp $vid ./
cp -r ../../DeepMeerkat/DeepMeerkat/model/ ./

#running meerkat:
echo "Meerkat is about to run"
python ../../DeepMeerkat/DeepMeerkat/Meerkat.py --input $vidBase --path_to_model model/ --output ./
err=$? #save success of previous step($?) as err
echo "Meerkat is finished running"

if [[ $err -eq 0 ]]
then
    #run successful, move folder to output, delete video
    echo "script succeeded!"
    mv $vidName ../../MeerkatOutput
    rm -r $work_dir
    mv $vid ../../../ModelTraining/RawVideos #remove source vid
else
    #run not successful
    echo "script failed!"
    rm -r $work_dir

fi


#end of file

#!/bin/bash

# General principles for a job script
# 1. output -> currently set this to just one file, whos name must be specified
# 2. command -> something that makes the output
# 3. input -> the command may need and input, this should be provided, ideally in the /pnfs/ area that is exposed to the batch system.
# 4. workarea -> required software to setup so the command can be run.

# FILE_LIST="/pnfs/dune/resilient/users/sbhuller/missing.txt"
# FHICL="runPi0_BeamSim.fcl"
INPUT="some input" # point 3. above are examples of inputs when running lar
OUTPUT_NAME="output" # point 1, specify a name for output file or just leave it as default
OUTDIR_NAME="output file directory name (automatically placed in scratch storage)"

echo "Running on $(hostname) at ${GLIDEIN_Site}. GLIDEIN_DUNESite = ${GLIDEIN_DUNESite}"

# set the output location for copyback
OUTDIR=/pnfs/dune/scratch/users/${GRID_USER}/${OUTDIR_NAME}/
echo "Output directoty is ${OUTDIR}"

#Let's rename the output file so it's unique in case we send multiple jobs.
STDOUT=out_${CLUSTER}_${PROCESS}.log

#make sure we see what we expect
pwd

ls -l $CONDOR_DIR_INPUT

# This runs a bash script that sets up the job enviroment i.e. point 4.
if [ -e ${INPUT_TAR_DIR_LOCAL}/setup-jobenv.sh ]; then
    . ${INPUT_TAR_DIR_LOCAL}/setup-jobenv.sh
else
echo "Error, setup script not found. Exiting."
exit 1
fi

# cd back to the top-level directory since we know that's writable
cd ${_CONDOR_SETTINGS_IWD}

#symlink the desired fcl to the current directory, use this is you want to run lar.
# ln -s ${INPUT_TAR_DIR_LOCAL}/localProducts*/protoduneana/*/job/${FHICL}.

# set some other very useful environment variables for xrootd and IFDH
export IFDH_CP_MAXRETRIES=2
export XRD_CONNECTIONRETRY=32
export XRD_REQUESTTIMEOUT=14400
export XRD_REDIRECTLIMIT=255
export XRD_LOADBALANCERTTL=7200
export XRD_STREAMTIMEOUT=14400 # many vary for your job/file type


# make sure the output directory exists
ifdh ls $OUTDIR 0 # set recursion depth to 0 since we are only checking for the directory; we don't care about the full listing.

if [ $? -ne 0 ]; then
    # if ifdh ls failed, try to make the directory
    ifdh mkdir_p $OUTDIR || { echo "Error creating or checking $OUTDIR"; exit 2; }
    ifdh mkdir_p $OUTDIR/out/  || { echo "Error creating or checking $OUTDIR/out/"; exit 2; }
fi

# LIST_NAME=`basename ${FILE_LIST}`
# ifdh cp ${FILE_LIST} ${LIST_NAME} || { echo "Error copying ${FILE_LIST}"; exit 3; }

#* run lar (or add some other command you want to run) and redirect the output to pipe
mkfifo pipe
tee $STDOUT < pipe &

#* Add you commands here i.e. point 2.
touch $OUTPUT_NAME

echo Hi! > $OUTPUT_NAME
echo $(ls)
# lar -c ${FHICL} ${FILE_NAME} > pipe
# LAR_RESULT=$?   # ALWAYS keep track of the exit status or your main command!!!

#* print the output messages from lar
if [ -f $STDOUT ]; then
    ifdh cp -D $STDOUT $OUTDIR/out/ # copy the log file

    #check the exit status to see if the copyback actually worked. Print a message if it did not.
    IFDH_RESULT=$?
    if [ $IFDH_RESULT -ne 0 ]; then
    echo "Error during output copyback. See output logs."
    exit $IFDH_RESULT
    fi
fi

# if [ $LAR_RESULT -ne 0 ]; then
#     echo "lar exited with abnormal status $LAR_RESULT. See error outputs."
#     exit $LAR_RESULT
# fi


#* check your output file was created, and copy to your permanent storage i.e. point 1.
if [ -f $OUTPUT_NAME ]; then

    NAME="${OUTPUT_NAME%%.*}"
    EXT="${OUTPUT_NAME#*.}"
    OUTFILE=${NAME}_${CLUSTER}_${PROCESS}_$(date -u +%Y%m%dT%H%M%SZ).${EXT} # uniquely timestamp file
    echo $OUTFILE
    mv $OUTPUT_NAME $OUTFILE
    
    # and copy our output file back
    ifdh cp -D $OUTFILE $OUTDIR

    # check the exit status to see if the copyback actually worked. Print a message if it did not.
    IFDH_RESULT=$?
    if [ $IFDH_RESULT -ne 0 ]; then
    echo "Error during output copyback. See output logs."
    exit $IFDH_RESULT
    fi
fi

# If we got this far, we succeeded.
echo "Completed successfully."
exit 0
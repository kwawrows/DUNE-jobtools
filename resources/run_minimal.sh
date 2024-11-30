#!/bin/bash

# FILE_LIST="/pnfs/dune/resilient/users/sbhuller/missing.txt"
# FHICL="runPi0_BeamSim.fcl"
OUTDIR_NAME="PDSPProd4a_MC_6GeV_reco1_sce_datadriven_v1_02/missing"

echo "Running on $(hostname) at ${GLIDEIN_Site}. GLIDEIN_DUNESite = ${GLIDEIN_DUNESite}"

# set the output location for copyback
OUTDIR=/pnfs/dune/scratch/users/${GRID_USER}/${OUTDIR_NAME}/
echo "Output directoty is ${OUTDIR}"

#Let's rename the output file so it's unique in case we send multiple jobs.
# OUTFILE=pi0Test_output_${CLUSTER}_${PROCESS}_$(date -u +%Y%m%dT%H%M%SZ).root
STDOUT=out_${CLUSTER}_${PROCESS}.log

#make sure we see what we expect
pwd

ls -l $CONDOR_DIR_INPUT

if [ -e ${INPUT_TAR_DIR_LOCAL}/setup-jobenv.sh ]; then
    . ${INPUT_TAR_DIR_LOCAL}/setup-jobenv.sh
else
echo "Error, setup script not found. Exiting."
exit 1
fi

# cd back to the top-level directory since we know that's writable
cd ${_CONDOR_SETTINGS_IWD}

#symlink the desired fcl to the current directory
ln -s ${INPUT_TAR_DIR_LOCAL}/localProducts*/protoduneana/*/job/${FHICL} .

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

#now we should be in the work dir if setupMay2021Tutorial-grid.sh worked
# FILE_NAME=`sed -n "$((PROCESS+1))p" < ${LIST_NAME}`
# echo "ROOT file name:"
# echo $FILE_NAME
echo $(pwd)
echo $(ls)

#* run lar (or add some other command you want to run) and redirect the output to pipe
mkfifo pipe
tee $STDOUT < pipe &
touch output.txt
echo Hi! > output.txt
echo $(ls)
# lar -c ${FHICL} ${FILE_NAME} > pipe
# LAR_RESULT=$?   # ALWAYS keep track of the exit status or your main command!!!

#* print the output messages from lar
if [ -f $STDOUT ]; then
    ifdh cp -D $STDOUT $OUTDIR/out/

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


#* check your output file was created, and copy to your permanent storage
if [ -f output.txt ]; then

    OUTFILE=output_${CLUSTER}_${PROCESS}_$(date -u +%Y%m%dT%H%M%SZ).txt
    mv output.txt $OUTFILE
    
    #and copy our output file back
    ifdh cp -D $OUTFILE $OUTDIR

    #check the exit status to see if the copyback actually worked. Print a message if it did not.
    IFDH_RESULT=$?
    if [ $IFDH_RESULT -ne 0 ]; then
    echo "Error during output copyback. See output logs."
    exit $IFDH_RESULT
    fi
fi

#If we got this far, we succeeded.
echo "Completed successfully."
exit 0

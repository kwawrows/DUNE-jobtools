# DUNE-jobtools
## Installation
Clone repo into a work area on a machine that has jobsub and cvmfs installed.

## Setup
Each time you want to use the tools, run
```[bash]
source setup_tools.sh
```

Make sure you can submit jobs on the grid.

if you are in a dunesw environment you can just run
```
setup_fnal_security
```

If not, run:
```
kinit -l 7d
```
to make a kerberos ticket for grid submissions that lasts one week.

Then
```
kx509
```
To make a CI certificate to submit grid jobs.

Now setup the proxy: 
```
voms-proxy-init -rfc -noregen -valid 120:00
```

## Submitting jobs

### Submit a quick test job.
In the top level directory run the following:
```[bash]
submit_job.py -s test/job_config.ini
```
This can take up to a ~1 minute to upload the tarball, but it should submit and you can use the following to check your job is on the list:

```[bash]
jobsub_q -G dune --user <your-fnal-username>
```

The example job runs quite quickly, so you mey not see anything, you can also check on [fifmon](https://fifemon.fnal.gov/monitor/d/000000116/user-batch-details?orgId=1&var-cluster=fifebatch).


the output files will automatically be transferred to your scratch area under the name specified by `OUTDIR_NAME`. In this case it is `/pnfs/dune/scratch/users/<your-fnal-username>/test/`, and you should see an output text file.

### Details and customising your jobs.
***Note that while developing/debugging, you can add the `--debug` command to `submit_job.py` to check your script and settings are correct.***

The command `submit_job.py` submits jobs via jobsub and takes a configuration file as input. The configuration file has settings for the jobs such as resource usage. An example config file is given under `test/job_config.ini`. In this configuration, the parameter to note is `script`. This is the bach script that is run to execute your job, a basic script that can be used as a template is `resources/run.sh`.

Make a copy of this and modify as needed to run the commands you want. In the configuration file there is a heading called `VARIABLES`, this contains all the enviroment variables you want to define for your job, the three required ones are provided in the example config, but more can be added e.g. a varaible for you `fhicl` file name or some command line arguments to pass to `lar`. Note the varaible names must be capitalised.

Note that when customising your job script there are few things to bear in mind.
 - If you want to pass some large data file as input, do not copy this into the tarball! Instead move the data to a location in `/pnfs/dune`. All the directoris there should be exposed to the remote cluster and doing this will be reduce your resources an run time.
 - The tarball is not necessary and does not need to be a dunesw environment, it can be anything the can run self-contained e.g. a miniforge3 python environment. In the tarball it is Ok to put configuration files/metadata.

### Troubleshooting
 - If the submission is taking a really long time, make sure your credentials for grid job submission were initialised/updated.
 - If you see no output file check the stdout and stderr logs inthe batch history located on the fifemon dashboard
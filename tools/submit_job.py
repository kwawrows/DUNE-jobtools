#!/cvmfs/larsoft.opensciencegrid.org/products/python/v3_9_2/Linux64bit+3.10-2.17/bin/python3
import subprocess
import argparse
import configparser
import os
#bashCommand = "jobsub_submit -G dune -M -N 10 --memory=2800MB --disk=3GB --expected-lifetime=3h --cpu=1 --resource-provides=usage_model=DEDICATED,OPPORTUNISTIC,OFFSITE --tar_file_name=dropbox:///dune/app/users/sbhuller/dunesw/dunesw-test.tar.gz -l '+SingularityImage=\"/cvmfs/singularity.opensciencegrid.org/fermilab/fnal-wn-sl7:latest\"' --lines '+FERMIHTC_AutoRelease=True' --lines '+FERMIHTC_GraceMemory=1024' --lines '+FERMIHTC_GraceLifetime=1800' --append_condor_requirements='(TARGET.HAS_Singularity==true&&TARGET.HAS_CVMFS_dune_opensciencegrid_org==true&&TARGET.HAS_CVMFS_larsoft_opensciencegrid_org==true&&TARGET.CVMFS_dune_opensciencegrid_org_REVISION>=1105&&TARGET.HAS_CVMFS_fifeuser1_opensciencegrid_org==true&&TARGET.HAS_CVMFS_fifeuser2_opensciencegrid_org==true&&TARGET.HAS_CVMFS_fifeuser3_opensciencegrid_org==true&&TARGET.HAS_CVMFS_fifeuser4_opensciencegrid_org==true)' file:///dune/app/users/sbhuller/dunesw/job/run_test_multi_sbhuller.sh"

class Options:
    def __init__(self):
        self.numberOfJobs = 1
        self.memory = "2800MB"
        self.disk = "10GB"
        self.lifetime = "8h"
        self.cpu = 1
        self.tarball = ""
        self.blacklist = ""
    def read_config(self, config):
        for var in vars(self):
            if var in config["SETTINGS"]:
                print(f"found {var}")
                setattr(self, var, config["SETTINGS"][var])
        self.variables = dict(config["VARIABLES"])
    def read_args(self, args):
        for var in vars(self):
            setattr(self, var, getattr(args, var))


def add_entry(lines : list[str], var_name : str, value : any):
    if var_name not in "\n".join(lines):
        print(f"Warning: {var_name} was not found in the run script!")
    for i in range(len(lines)):
        if f"{var_name}=" in lines[i] and value != "":
            print(f"variable {var_name} found")
            lines[i] = f"{var_name}=\"{value}\"\n"
            continue


def configure_scripts(script_vars : dict):
    with open(os.environ["JOBTOOLS_DIR"] + "/resources/run.sh", "r") as bash_script:
        lines = bash_script.readlines()

    for k, v in script_vars.items():
        add_entry(lines, k, v)

    f = open("/tmp/job_script.sh", "w")
    f.write("".join(lines))
    f.close()
    return


def main(options, debug=False):
    # nJobs = 10
    # memory = "2800MB"
    # disk = "3GB"
    # lifetime = "3h"
    # cpu = 1
    # tar_file = "/dune/app/users/sbhuller/dunesw/dunesw-test.tar.gz"
    # script = "/dune/app/users/sbhuller/dunesw/job/run_test_multi_sbhuller.sh"

    print(options.variables)
    configure_scripts(options.variables)

    bash_command = "jobsub_submit --mail_never -G dune --resource-provides=usage_model=DEDICATED,OPPORTUNISTIC -l '+SingularityImage=\"/cvmfs/singularity.opensciencegrid.org/fermilab/fnal-wn-sl7:latest\"' --lines '+FERMIHTC_AutoRelease=True' --lines '+FERMIHTC_GraceMemory=1024' --lines '+FERMIHTC_GraceLifetime=1800' --append_condor_requirements='(TARGET.HAS_Singularity==true&&TARGET.HAS_CVMFS_dune_opensciencegrid_org==true&&TARGET.HAS_CVMFS_larsoft_opensciencegrid_org==true&&TARGET.CVMFS_dune_opensciencegrid_org_REVISION>=1105&&TARGET.HAS_CVMFS_fifeuser1_opensciencegrid_org==true&&TARGET.HAS_CVMFS_fifeuser2_opensciencegrid_org==true&&TARGET.HAS_CVMFS_fifeuser3_opensciencegrid_org==true&&TARGET.HAS_CVMFS_fifeuser4_opensciencegrid_org==true)' "

    bash_command += f"-N {options.numberOfJobs} " # 1
    bash_command += f"--memory={options.memory} " # 2800MB
    bash_command += f"--disk={options.disk} " # 10GB
    bash_command += f"--expected-lifetime={options.lifetime} " # 3h
    bash_command += f"--cpu={options.cpu} " # 1
    bash_command += f"--tar_file_name=dropbox://{options.tarball} "
    bash_command += f"--blacklist={options.blacklist} "
    bash_command += f"file:///tmp/job_script.sh "

    print(bash_command.split())
    if debug is False:
        process = subprocess.Popen(bash_command.split(), stdout=subprocess.PIPE)
        output, error = process.communicate()
        if output: print(output.decode("utf-8"))
        if error: print(error.decode("utf-8"))


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Submit job using jobsub_submit (but nicer)")
    parser.add_argument("-s", "--settings", dest="settings", type=str, default=None, help="settings file so you don't need to pass arguements through the command line")
    parser.add_argument("-n", "--number-of-jobs", dest="numberOfJobs", type=int, default=1, help="number of jobs to submit")
    parser.add_argument("-m", "--memory-usage", dest="memory", type=str, default="2800MB", help="memory used per job")
    parser.add_argument("-d", "--disk-uasge", dest="disk", type=str, default="10GB", help="disk space used per job")
    parser.add_argument("-l", "--lifetime", dest="lifetime", type=str, default="3h", help="job lifetime")
    parser.add_argument("-c", "--cpu-uasge", dest="cpu", type=int, default=1, help="number of threads used")
    parser.add_argument("-t", "--tarball", dest="tarball", type=str, default="", help="custom tarball to use")
    parser.add_argument("-b", "--blacklist", dest="blacklist", type=str, default="", help="sites to blacklist")
    parser.add_argument("--debug", dest="debug", action="store_true", help="debug code without sumbitting a job")
    args = parser.parse_args()
    options = Options()
    options.read_args(args)
    if args.settings:
        print("we have a configuation file!")
        config = configparser.ConfigParser()
        config.optionxform = str
        config.read(args.settings)
        options.read_config(config)
    main(options, args.debug)
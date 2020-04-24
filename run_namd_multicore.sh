#!/bin/bash
#SBATCH --job-name=run_namd
#SBATCH --mem=40000
#SBATCH --array=1
#SBATCH --gres=gpu:titan-x:1
#SBATCH --time=0-01:00:00
#SBATCH --exclude node017,node018
#SBATCH --mail-type=ALL
#SBATCH --mail-user=ehoseini@mit.edu
#SBATCH --output=namd_multi_result_%j.out
#SBATCH --error=namd_multi_result_%j.err

set -e; set -o pipefail

# Load required modules
module add openmind/singularity
export SINGULARITY_CACHEDIR=/om/user/`whoami`/st/
# Download APOA1 example input
wget -O - https://gitlab.com/NVHCP/ngc-examples/raw/master/namd/2.13/get_apoa1.sh | bash
INPUT="/host_pwd/apoa1/apoa1.namd"

# Generate charmrun nodelist
NODELIST=$(pwd)/nodelist.${SLURM_JOBID}
for host in $(scontrol show hostnames); do
  echo "host ${host} ++cpus ${SLURM_CPUS_ON_NODE}" >> ${NODELIST}
done

# singularity alias which will launch charmrun and namd2
SIMG="/om/user/ehoseini/simg_images/namd_2.13-multinode.simg"
SINGULARITY="$(which singularity) exec --nv -B $(pwd):/host_pwd ${SIMG}"

# charmrun alias
SSH="ssh -o PubkeyAcceptedKeyTypes=+ssh-dss -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o LogLevel=ERROR"
CHARMRUN="charmrun ++remote-shell \"${SSH}\" ++nodelist ${NODELIST} ++p ${SLURM_NTASKS} ++ppn ${SLURM_CPUS_ON_NODE}"
# namd2 alias
NAMD2="namd2 +setcpuaffinity +idlepoll ${INPUT}"
# Launch parallel namd
#eval "${SINGULARITY} ${CHARMRUN} ${SINGULARITY} ${NAMD2}"
printf "${SINGULARITY} ${NAMD2} \n"
eval "${SINGULARITY} ${NAMD2}"

# Cleanup nodelist
rm ${NODELIST}

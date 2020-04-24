#!/bin/bash

#SBATCH --nodes 2
#SBATCH --ntasks=16
#SBATCH --time 00:10:00

set -e; set -o pipefail

# Load required modules
module load singularity

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
eval "${SINGULARITY} ${CHARMRUN} ${SINGULARITY} ${NAMD2}"

# Cleanup nodelist
rm ${NODELIST}

#!/bin/bash

#SBATCH --job-name=run_namd
#SBATCH --mem=40000
#SBATCH --array=1
#SBATCH --gres=gpu:titan-x:1
#SBATCH --time=0-01:00:00
#SBATCH --exclude node017,node018
#SBATCH --mail-type=ALL
#SBATCH --mail-user=ehoseini@mit.edu
#SBATCH --output=namd_single_result_%j.out
#SBATCH --error=namd_single_result_%j.err

set -e; set -o pipefail

GPU_COUNT=${1:-1}
SIMG="/om/user/ehoseini/simg_images/namd_2.13-singlenode.simg"

echo "Downloading APOA1 Dataset..."
wget -O - https://gitlab.com/NVHCP/ngc-examples/raw/master/namd/2.13/get_apoa1.sh | bash
INPUT="/host_pwd/apoa1/apoa1.namd"

SINGULARITY="singularity exec --nv -B $(pwd):/host_pwd ${SIMG}"
NAMD2="namd2 ${INPUT}"

echo "Running APOA1 example in ${SIMG} on ${GPU_COUNT} GPUS..."
${SINGULARITY} ${NAMD2}

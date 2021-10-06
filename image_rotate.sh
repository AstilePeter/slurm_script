#!/usr/bin/env python3
#
#SBATCH --job-name=image1
#SBATCH --partition=test
#SBATCH --output=/home/astile/image3.txt
#SBATCH --nodelist=astile-desktop
#SBATCH --cpus-per-task=4 
#SBATCH --ntasks=1
#SBATCH --time=40:00
#SBATCH --mem-per-cpu=1

from PIL import Image
with Image.open("/home/slurm/index.png") as im:
    im_rotate = im.rotate(45)
    im_rotate.save("/home/astile/index5.png")

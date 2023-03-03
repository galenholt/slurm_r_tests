# slurm_r_tests
template repo for testing use of R on SLURM HPCs

# Use
I'm using this to develop tests of how to do things on SLURM HPCs. The basic use is to clone this repo onto the slurm machine, then use `renv` to reconstruct the packages. 

I tend to make all changes locally, push, and then pull to the HPC repo- ie not doing any actual dev on the HPC.

# slurm_r_tests
template repo for testing use of R on SLURM HPCs

# Use
I'm using this to develop tests of how to do things on SLURM HPCs. The basic use is to clone this repo onto the slurm machine, then use `renv` to reconstruct the packages. 

I tend to make all changes locally, push, and then pull to the HPC repo- ie not doing any actual dev on the HPC.

# Scripts
`any_R.sh` allows running any R script, potentially including arguments to that script with `sbatch any_R.sh rscriptname.R arguments_to_R`.

`print_command_args.R` is a simple R script to print the arguments R is recieving, useful for checking order and setting up R scripts that need to accept argument from the sbatch call or slurm script.

`testing_plans.R` lets the user set the plan or plans, and returns information about the resources they're using, e.g. `sbatch any_R.sh testing_plans.R sequential multisession multicore` to test those three plan types.

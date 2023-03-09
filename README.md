# slurm_r_tests
template repo for testing use of R on SLURM HPCs

# Use
I'm using this to develop tests of how to do things on SLURM HPCs. The basic use is to clone this repo onto the slurm machine, then use `renv` to reconstruct the packages. 

I tend to make all changes locally, push, and then pull to the HPC repo- ie not doing any actual dev on the HPC.

More specifically, my workflow is local dev, ssh to the HPC, get to the right directory, `git pull`, and then call `sbatch ARGUMENTS` to run code that I tend to have save output I come back for later. In the simplest form, that looks like `sbatch slurmscript.sh`, where slurmscript.sh is a SLURM shell script that calls a specific R script. But see for example `any_R.sh` for more flexible situations where we can call `sbatch any_R.sh arbitraryArguments` to pass args in from the command line, which is super useful.

HPC testing is tricky because behaviour changes depending on SLURM setup (or more generally, queue management, including TORQUE, etc), nodes, cores, and other infrastructure. Some of the resources I ask for might not work on other HPCs, and values will likely need to be adjusted. 

See the parallelisation section of [my website](https://galenholt.github.io/code_demos.html) for a lot more text about what I'm doing here. I should probably bring a lot of that over here, but for now we'll have to cross-reference.

# Scripts

## Shell scripts (SLURM, mostly)
`any_R.sh` allows running any R script, potentially including arguments to that script with `sbatch any_R.sh rscriptname.R arguments_to_R`.

`batchtools_R.sh` is a tuned version of `any_R.sh` designed to run the master R session from `sbatch` in a minimally-resourced process, while the R session it starts spawns lots of `sbatch` calls to do the work.

`node_core_check.R` is an example of a script-targetted shell that calls a specific R script, in this case `testing_plans.R`


## R scripts
`print_command_args.R` is a simple R script to print the arguments R is receiving, useful for checking order and setting up R scripts that need to accept argument from the sbatch call or slurm script.

`testing_plans.R` lets the user set the plan or plans (but NOT future.batchtools plans), and returns information about the resources they're using, e.g. `sbatch any_R.sh testing_plans.R sequential multisession multicore` to test those three plan types.

`testing_future_batchtools.R` is a simple script to run `plan(batchtools_slurm)`, and allows setting the template as a command-line argument to test the differences between them. It was built primarily to get `future.batchtools` working.

`tweak_resources_bt.R`, `tweak_resources_default.R`, and `tweak_resources_fbt.R` have `tweak` calls to adjust the `plan` with a `resources` list. There are three because the way the `resources` list gets parsed into the template depends on the template. `*bt` tweaks the batchtools-provided template `batchtools_templates/slurm-simple.tmpl`, `*fbt` tweaks the future.batchtools-provided template `batchtools_templates/slurm.tmpl`, and `*default` tweaks the default template `batchtools.slurm.tmpl` that I have made changes to.

`master_timeouts.R` a script that purposefully tries to get the master R session to timeout before some futures have started and while others have started but not finished. Designed to test what happens when the master dies.

`nested_plan.R` tests nested plans using `list`, to use a `future.batchtools` plan as an outer layer of parallelisation (typically over nodes), with an inner layer that then parallelises over cpus on the node. Includes an example with a `workers` argument to control the number of nodes.

# Templates

`batchtools_templates/slurm-simple.tmpl`- template from [{batchtools}](https://github.com/mllg/batchtools)

`batchtools_templates/slurm.tmpl`- template from [{future.batchtools}](https://github.com/HenrikBengtsson/future.batchtools)

`batchtools.slurm.tmpl` a *very* slightly modified version of the {future.batchtools} template that handles SLURM variables with '-' in their names. In the default location for a template, so `plan(batchtools_slurm)` will find this one without having to specify a `template` argument.

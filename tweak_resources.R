# Testing future.batchtools

library(dplyr)
library(tibble)
library(doFuture)
library(future.batchtools)
registerDoFuture()

# I'll use the same simple nested testing function as in `testing_plans.R`, at
# least for the first pass

# The loop function
nest_test <- function(outer_size, inner_size, planname) {
  outer_out <- foreach(i = 1:outer_size,
                       .combine = bind_rows) %:% 
    foreach(j = 1:inner_size,
            .combine = bind_rows) %dopar% {
              
              thisproc <- tibble(node = Sys.getenv("SLURMD_NODENAME"),
                                 outer_iteration = i,
                                 inner_iteration = j, 
                                 pid = Sys.getpid())
            }
  
  return(outer_out)
}

# Declare the plan and see what it is
# Let's pass the template path in as an argument, or set to NULL (autochoose)
scriptargs <- commandArgs()
if (length(scriptargs) > 5) {temp_path <- scriptargs[6]} else {temp_path = NULL}


plan(tweak(batchtools_slurm,
           template = temp_path,
           resources = list(ncpus = 12,
                            memory = "1GB",
                            walltime="0:05:00",
                            nodes=1)))

cat("\n Plan is:\n")

plan("list")

# What do we see for resources *before* we call anything?
cat('\n### available workers:\n')
cat(availableWorkers(), sep = "\n")
cat('\n\n### total workers:\n')
cat(length(availableWorkers()))
cat('\n\n### unique workers:\n')
cat(unique(availableWorkers()))



cat('\n\n### available Cores:\n')
cat("\n#### non-slurm\n")
cat(availableCores(), sep = "\n")
cat("\n#### slurm method\n")
cat(availableCores(methods = 'Slurm'), sep = "\n")

# base R process id
cat('\n### Main PID:\n')
cat(Sys.getpid(), sep = "\n")

# The loop
looptib <- nest_test(25, 25, planname)

cat('\n### Unique processes\n')
cat(length(unique(looptib$pid)))
cat("\n\nIDs of all cores used\n\n")
cat(unique(looptib$pid), sep = "\n")

cat('\n## Nodes and pids\n')
looptib %>% 
  group_by(node, pid) %>% 
  summarize(n_reps = n()) %>% 
  print(n = Inf)
cat("\n")

# Testing future.batchtools

library(dplyr)
library(tibble)
library(doFuture)
library(future.batchtools)
registerDoFuture()

# Declare the plan and see what it is. I should be able to use any of the
plan(tweak(batchtools_slurm,
           template = "batchtools.slurm.tmpl",
           resources = list(time = "0:02:00",
                            ntasks.per.node = 1,
                            mem = 200, # MB by default
                            job.name = 'mastertest')))


cat("\n Plan is:\n")

plan("list")



# I'll modify the same simple nested testing function as in `testing_plans.R` to
# produce output, which we can then see if it exists

# Create directories to print into
startdir <- file.path('testout', 'timeouts', 'startdir')
enddir <- file.path('testout', 'timeouts', 'enddir')
if (!dir.exists(startdir)) {dir.create(startdir, recursive = TRUE)}
if (!dir.exists(enddir)) {dir.create(enddir, recursive = TRUE)}

# The loop function
nest_test <- function(outer_size, inner_size, planname) {
  outer_out <- foreach(i = 1:outer_size,
                       .combine = bind_rows) %:% 
    foreach(j = 1:inner_size,
            .combine = bind_rows) %dopar% {
              
              # Create a file to see the loop started
              file.create(file.path(startdir, 
                                    paste0('outer_loop_', i, 
                                           'inner_loop_', j, '.txt')))
              
              thisproc <- tibble(all_job_nodes = paste(Sys.getenv("SLURM_JOB_NODELIST"),
                                                       collapse = ","),
                                 node = Sys.getenv("SLURMD_NODENAME"),
                                 outer_iteration = i,
                                 inner_iteration = j, 
                                 pid = Sys.getpid(),
                                 taskid = Sys.getenv("SLURM_LOCALID"),
                                 cpus_avail = Sys.getenv("SLURM_JOB_CPUS_PER_NODE"))
              
              # output the results of the loop
              write.csv(thisproc, file = file.path(enddir, 
                                                   paste0('outer_loop_', i,
                                                          'inner_loop_', j,
                                                          '.csv')))
              
              # still return the output of the whole thing so we can see if it finishes
              thisproc
            }
  
  return(outer_out)
}

# We likely won't get to this bit- that's the point. But if we do, it's here.

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
  group_by(all_job_nodes, node, pid, taskid, cpus_avail) %>% 
  summarize(n_reps = n()) %>% 
  print(n = Inf)
cat("\n")

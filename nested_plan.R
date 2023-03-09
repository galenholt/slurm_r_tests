# Testing future.batchtools

library(dplyr)
library(tibble)
library(doFuture)
library(doRNG)
library(future.batchtools)
registerDoFuture()

# The goal here is to paralellise within nodes, so ask for > 1 tasks per node,
# and then use a second plan to parallelise over those

# Declare the plan and see what it is. I should be able to use any of the
# argument formats SLURM accepts. E.g. both time = "0:05:00" and time = 5 should
# both work
# plan(list(tweak(batchtools_slurm,
#                 template = "batchtools.slurm.tmpl",
#                 resources = list(time = 5,
#                                  ntasks.per.node = 12, 
#                                  mem = 1000,
#                                  job.name = 'NewName')),
#           multicore))

# A version with `workers` declared, rather than the default 100
plan(list(tweak(batchtools_slurm,
                workers = 5,
                template = "batchtools.slurm.tmpl",
                resources = list(time = 15,
                                 ntasks.per.node = 12, 
                                 mem = 1000,
                                 job.name = 'NewName')),
          multicore))

cat("\n Plan is:\n")

plan("list")

# We want to return the same sort of thing as before, but now in a nested way.
# Let's have an outer function with a foreach that calls an inner function with
# a foreach
inner_par <- function(inner_size, outer_it, outer_pid) {
  inner_out <- foreach(j = 1:inner_size,
                       .combine = bind_rows) %dorng% {
                         thisproc <- tibble(all_job_nodes = paste(Sys.getenv("SLURM_JOB_NODELIST"),
                                                                  collapse = ","),
                                            node = Sys.getenv("SLURMD_NODENAME"),
                                            loop = "inner",
                                            outer_iteration = outer_it,
                                            outer_pid = outer_pid,
                                            inner_iteration = j, 
                                            inner_pid = Sys.getpid(),
                                            taskid = Sys.getenv("SLURM_LOCALID"),
                                            cpus_avail = Sys.getenv("SLURM_JOB_CPUS_PER_NODE"))
                         
                       }
  return(inner_out)
}

# The outer loop calls the inner one
outer_par <- function(outer_size, inner_size) {
  outer_out <- foreach(i = 1:outer_size,
                       .combine = bind_rows) %dorng% {
                         
                         # do some stupid work so this isn't trivially nested
                         a <- 1
                         b <- 1
                         d <- a+b
                         # Now iterate over the values in c to do somethign else
                         inner_out <- inner_par(inner_size = inner_size,
                                                outer_it = i, outer_pid = Sys.getpid())
                         
                         inner_out
                       }
  
  return(outer_out)
}


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


# LOOP --------------------------------------------------------------------


looptib <- outer_par(25,25)

# OUTPUT ------------------------------------------------------------------



cat('\n### Unique nodes\n')
cat(length(unique(looptib$outer_pid)))
cat("\n\nIDs of all nodes used\n\n")
cat(unique(looptib$outer_pid), sep = "\n")

cat('\n### Unique cores\n')
cat(length(unique(looptib$inner_pid)))
cat("\n\nIDs of all cores used\n\n")
cat(unique(looptib$inner_pid), sep = "\n")

cat('\n## Nodes and pids simple\n')
looptib %>% 
  group_by(outer_pid) %>% 
  summarise(n_inner = n_distinct(inner_pid)) %>% 
  print(n = Inf)
cat("\n")

cat('\n## Each PID could get used for multiple jobs potentially\n')
looptib %>% 
  group_by(outer_pid, inner_pid) %>% 
  summarise(n_reps = n()) %>% 
  print(n = Inf)
cat("\n")

cat("\n## Nodes and PIDS more info\n")
looptib %>% 
  group_by(all_job_nodes, node, outer_pid, taskid, cpus_avail) %>% 
  summarize(n_reps = n(),
            n_inner = n_distinct(inner_pid)) %>% 
  print(n = Inf)
cat("\n")

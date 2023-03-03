# trying to sort out auto-arraying and different plan()s

library(dplyr)
library(tibble)
library(doFuture)
registerDoFuture()

# plans to test first
# plan(sequential)
# plan(multisession)
# plan(multicore)

# Later move on to
# plan(cluster)
# plan(future.batchtools::batchtools_slurm) # Spits out each future into slurm nodes
# # # Probably better to do 
# plan(list(future.batchtools::batchtools_slurm, multisession)) # and include an outer layer of futures around catchment or something.
# # basically, according to 
# # https://future.batchtools.futureverse.org/ 

scriptargs <- commandArgs()
plannames <- scriptargs[6:length(scriptargs)]
# plannames <- c('sequential', 'multisession', 'multicore')

# The loopings
nest_test <- function(outer_size, inner_size, planname) {
  outer_out <- foreach(i = 1:outer_size,
                       .combine = bind_rows) %:% 
    foreach(j = 1:inner_size,
            .combine = bind_rows) %dopar% {
              
              thisproc <- tibble(plan = planname,
                                 outer_iteration = i,
                                 inner_iteration = j, 
                                 pid = Sys.getpid())
            }
  
  return(outer_out)
}


for (planname in plannames) {
  cat(paste0("\n## ", planname, "\n"))
  plan(planname)
  
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
  
  looptib <- nest_test(25, 25, planname)
  
  cat('\n### Unique processes\n')
  cat(length(unique(looptib$pid)))
  cat("\n\nIDs of all cores used\n\n")
  cat(unique(looptib$pid), sep = "\n")
  
  # cat('\n## Full loop data\n')
  # print(looptib)
  cat("\n")
  
}




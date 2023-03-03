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

plannames <- c('sequential', 'multisession', 'multicore')

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
  print(paste0("\n# ", planname, "\n"))
  plan(planname)
  
  print('\n## available Workers:\n')
  print(availableWorkers())
  
  print('\n## available Cores:\n')
  print("\n### non-slurm\n")
  print(availableCores())
  print("\n### slurm method\n")
  print(availableCores(methods = 'Slurm'))
  
  # base R process id
  print('\n## Main PID:\n')
  print(Sys.getpid())
  
  looptib <- nest_test(25, 25, planname)
  
  print('\n## Unique processes\n')
  print(length(unique(looptib$pid)))
  print("\nThis should be the IDs of all cores used\n")
  print(unique(looptib$pid))
  
  print('\n## Full loop data\n')
  print(looptib)
  print("\n")
  
}




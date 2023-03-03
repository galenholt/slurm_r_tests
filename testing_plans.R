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

for (i in 1:length(plannames)) {
  print(paste0("# ", planname))
  plan(planname)
  
  print('## available Workers:')
  print(availableWorkers())
  
  print('## available Cores:')
  print("### non-slurm")
  print(availableCores())
  print("### slurm method")
  print(availableCores(methods = 'Slurm'))
  
  # base R process id
  print('## Main PID:')
  print(Sys.getpid())
  
  looptib <- nest_test(25, 25)
  
  print('## Unique processes')
  print(length(unique(looptib$pid)))
  print("This should be the IDs of all cores used")
  print(unique(looptib$pid))
  
  print('## Full loop data')
  print(processtest)
  
  
}




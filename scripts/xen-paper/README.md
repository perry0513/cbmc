# Dependencies:
 Docker
 Flex
 Bison
 g++ version 5.0 or newer


# I don't recommend running these scripts but this is the order they would be run in:
build_xen_binaries.sh - only necessary if you need to build Xen. Needs to be done in docker on the cloud-dev-desktop. 
config_script.sh - exports global variables that are necessary for the following scripts to configure job name and the region
make_folder_for_batch_jobs.sh - copies the Xen binaries and the cbmc binaries into the folder binaries_for_batch, and uploads to s3
setup_batch.sh - Don't run this script! It sets up batch, but i haven't worked out how to automatically get the compute environment right automatically for each region. But it does contain all the commands you need if you need to update anything
submit_jobs.sh - submits jobs to batch. 


If you want to-rerun stuff using the paper-runner AWS account, and from the clouddev desktop, the only scripts you need to care about are
build_xen_binaries, make_folder_for_batch_jobs and submit_jobs. 

Everything is currently configured to put stuff in 
s3://xen-paper-bucket

And Batch is set up to run in us-east-1, us-east-2 and eu-central-1

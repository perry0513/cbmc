export home=$(pwd)
export AWS_ACCOUNT_NUMBER="742113291861"
export BUCKETNAME="xen-paper-bucket"
export JOBNAME="final_scripted_run"
export REGION="us-east-2"

sed "s/region.*/region = $REGION/g" ~/.aws/config


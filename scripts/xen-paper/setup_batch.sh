home=$(pwd)

AWS_ACCOUNT_NUMBER=
REGION="us-east-1"

#build docker file
cd batch_scripts/docker
docker build -t awsbatch/fetch_and_run .

#Create an ECR repository
aws ecr create-repository --repository-name awsbatch/fetch_and_run

docker tag awsbatch/fetch_and_run:latest $AWS_ACCOUNT_NUMBER.dkr.ecr.us-east-1.amazonaws.com/awsbatch/fetch_and_run:latest
docker push $AWS_ACCOUNT_NUMBER.dkr.ecr.$REGION.amazonaws.com/awsbatch/fetch_and_run:latest

#create bucket
aws s3api create-bucket --bucket $BUCKETNAME --region $REGION

cd ..

sed -i -e "s/bucket_name/$BUCKETNAME/g" myjob.sh

aws cp myjob.sh $BUCKETNAME/myjob.sh

#the following steps may not work unless you have already used batch at least once in this region. It seems to create 
#some roles automatically the first time batch is used.

aws batch register-job-definition --cli-input-json file://xen_job.json

#replace with correct compute envirotnment
aws batch create-compute-environment --cli-input-json file://us_east_2_compute_envt.json

aws batch create-job-queue --cli-input-json file://jobqueue.json
from pprint import pprint
from subprocess import call



REGIONS=['eu-west-1', 'eu-west-2','ap-southeast-2']
for region in REGIONS :
  rc=call("sed \"s/region.*/region = "+region+"/g\" ~/.aws/config", shell=True)
  rc=call("aws batch create-job-queue --cli-input-json file://jobqueue.json ", shell=True)
      
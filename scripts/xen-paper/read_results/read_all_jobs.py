import json
from pprint import pprint
from subprocess import call
import csv
import boto3
from pyodinhttp import OdinClient, OdinOperationError
from odin_client import AWSCredentialsProvider, TimedRefresher
import os.path
import time
import string
import re

material_set='com.amazon.credentials.isengard.742113291861.user/polgreen-iam'
refresher = TimedRefresher(90)  # refresh creds every 90 seconds
credentials_provider = AWSCredentialsProvider(material_set, refresher)
 # fetches and caches the credentials for the duration of TimedRefresher
aws_access_key_id, aws_secret_access_key = credentials_provider.aws_access_key_pair
BUCKETNAME = 'xen-paper-bucket/'

batch=boto3.client('batch')
s3=boto3.resource('s3')

REGIONS=['us-east-1', 'us-east-2', 'us-west-1', 'us-west-2','eu-west-1','eu-central-1', 'eu-west-2','ap-southeast-2']


for region in REGIONS :
  rc=call("sed -i \"s/region.*/region = "+region+"/g\" ~/.aws/config", shell=True)

  rc=call("aws batch list-jobs --job-queue xen-paper-queue-110 --job-status FAILED > failedjobs.json", shell=True)
  json_data=open('failedjobs.json').read()
  data=json.loads(json_data)

  with open(region+'failedjobs.csv', 'wb') as csvfile:
   filewriter=csv.writer(csvfile, delimiter=',', quotechar='|', quoting=csv.QUOTE_MINIMAL)
   filewriter.writerow(['Job Name', 'trace name' ,'XSA number', 'depth', 'unwind', 'directpaths','fullslice', 'FP','statusReason', 'start time', 'stop time', 'got file', 'trace status', 'cbmc start time', 'cbmc end time'])

   for x in data["jobSummaryList"]:
     jobid=x["jobId"]
     rc=call('aws batch describe-jobs --jobs ' +jobid + ' > jobdescription.json', shell=True)
     job_json_data=open('jobdescription.json').read()   
     job_data=json.loads(job_json_data)  
     XSA_num=job_data["jobs"][0]["parameters"].get("XSA_num","unknown")
     DEPTH=job_data["jobs"][0]["parameters"].get("depth","unknown")
     UNWIND=job_data["jobs"][0]["parameters"].get("unwind", "unknown")
     DP=job_data["jobs"][0]["parameters"].get("direct_paths","unknown")
     fullslice=job_data["jobs"][0]["parameters"].get("fullslice", "0")
     fp=job_data["jobs"][0]["parameters"].get("functionpointers", "0")

     filewriter.writerow([x["jobName"], "no trace ", XSA_num,DEPTH,UNWIND,DP,fullslice, fp, x["statusReason"], x.get("startedAt"), x.get("stoppedAt"),"no trace" , "no trace","" ,"" ])

  rc=call("aws batch list-jobs --job-queue xen-paper-queue-110 --job-status SUCCEEDED > successjobs.json", shell=True)
  json_data=open('successjobs.json').read()
  data=json.loads(json_data)

  with open(region+'successjobs.csv', 'wb') as csvfile:
    filewriter=csv.writer(csvfile, delimiter=',', quotechar='|', quoting=csv.QUOTE_MINIMAL)
    filewriter.writerow(['Job Name', 'XSA number', 'depth', 'unwind', 'directpaths','fullslice','statusReason', 'start time', 'stop time'])

    for x in data["jobSummaryList"]:
      jobid=x["jobId"]
      rc=call('aws batch describe-jobs --jobs ' +jobid + ' > jobdescription.json', shell=True)
      job_json_data=open('jobdescription.json').read()
      job_data=json.loads(job_json_data)
     # job_data=batch.describe_jobs(jobs=[jobid])
      XSA_num=job_data["jobs"][0]["parameters"].get("XSA_num","unknown")
      DEPTH=job_data["jobs"][0]["parameters"].get("depth","unknown")
      UNWIND=job_data["jobs"][0]["parameters"].get("unwind", "unknown")
      DP=job_data["jobs"][0]["parameters"].get("direct_paths","unknown")
      fullslice=job_data["jobs"][0]["parameters"].get("fullslice", "0")
      fp=job_data["jobs"][0]["parameters"].get("functionpointers", "0")
      NAME=job_data["jobs"][0]["parameters"].get("tracename", "final_run")

      tracename=NAME+"xsa"+XSA_num+".depth"+DEPTH+"-unwind"+UNWIND+"-dp"+DP+"-fs"+fullslice+"-fp"+fp+".trace"
      string="aws s3 cp s3://"+BUCKETNAME+tracename+" succeeded_jobs/"
      print(string)
      rc=call(string, shell=True)
      goteloc=0
      start_time_stamp=0
      done_slicing=0
      end=0
      cbmc_start_time="unknown"
      trace_status = "unknown error"
      cbmc_end_time="unknown"
      if os.path.exists("succeeded_jobs/"+tracename):
      	with open("succeeded_jobs/"+tracename) as tracepath :
      	  for line in tracepath :
            if "CBMC version" in line :
              cbmc_start_time=re.search(r'\d+.\d+', line).group()
            if "VERIFICATION FAILED" in line :
              cbmc_end_time=re.search(r'\d+.\d+', line).group()
              trace_status="found trace"
            if "SAT checker ran out of memory" in line :
              trace_status = "SAT out of memory"
              cbmc_end_time=re.search(r'\d+.\d+', line).group()
            if "VERIFICATION SUCCESSFUL" in line:
              cbmc_end_time=re.search(r'\d+.\d+', line).group()
              trace_status = "no trace found"
            if "invariant violation" in line:
              trace_status = "CBMC error: invariant violation"
            if "Killed" in line:
              trace_status = "Killed"
            if "Done slicing" in line:
              done_slicing=re.sub("\D","",line)
            if "Start analysis" in line:
              start_time_stamp=re.sub("\D","",line)
            if "End time" in line:
              end=re.sub("\D","",line)      
            if "Effective lines of code:" in line:
              if goteloc==0:
              	goteloc=1
              	ELOC=re.sub("\D", "", line)
      else:
      	cbmc_start_time="unknown"
      	cbmc_end_time="unknown"
      	trace_status="no trace file"





      filewriter.writerow([x["jobName"], tracename, XSA_num,DEPTH,UNWIND,DP,fullslice, fp, x["statusReason"], x.get("startedAt"), x.get("stoppedAt"),rc, trace_status, cbmc_start_time, cbmc_end_time, ELOC, start_time_stamp, done_slicing, end])


rc=call('cat *successjobs.csv > allsucceededjobs.csv', shell=True)
rc=call('cat *failedjobs.csv > allfailjobs.csv', shell=True)
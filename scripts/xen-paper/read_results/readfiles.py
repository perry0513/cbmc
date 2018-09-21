import json
from pprint import pprint
from subprocess import call
import csv
import boto3
from pyodinhttp import OdinClient, OdinOperationError
from odin_client import AWSCredentialsProvider, TimedRefresher
import re
import string
import time
import os.path
import sys

#the name and bucket name must be the same as NAME declared at line 5 of batch_script.sh
if len(sys.argv)==1 :
  print "using final_run as name"
  NAME="final_run"
else:
  NAME=sys.argv[1]
  print "name of run is "+NAME
  
BUCKETNAME = 'xen-paper-bucket/' #but without the s3://prefix

timestamp = str(time.time())

material_set = 'com.amazon.credentials.isengard.742113291861.user/polgreen-iam'
refresher = TimedRefresher(90)  # refresh creds every 90 seconds
credentials_provider = AWSCredentialsProvider(material_set, refresher)
 # fetches and caches the credentials for the duration of TimedRefresher
aws_access_key_id, aws_secret_access_key = credentials_provider.aws_access_key_pair

batch = boto3.client('batch')
s3 = boto3.resource('s3')

#XSAs = ["200", "212", "213", "227", "238", "999"]
XSAs = ["212", "200" ]

with open(timestamp+'succeeded_jobs.csv', 'wb') as csvfile:
  filewriter = csv.writer(csvfile, delimiter=',',
                          quotechar='|', quoting=csv.QUOTE_MINIMAL)
  filewriter.writerow(['Job Name', 'trace name', 'XSA number', 'depth', 'unwind', 'directpaths', 'fullslice', 'FP'
                      'statusReason', 'start time', 'stop time', 'got file', 'trace status', 'cbmc start time', 'cbmc end time'])

  for XSA_num in XSAs:
    for DP in range(2):
      for UNWIND in range(3):
        for DEPTH in range(3):
          for fullslice in range(2):
            for fp in range(4):

              tracename = NAME+"xsa"+XSA_num+".depth"+str(DEPTH) +"-unwind"+str(UNWIND)+"-dp"+str(DP)+"-fs"+str(fullslice)+"-fp"+str(fp)+".trace"
              string = "aws s3 cp s3://"+BUCKETNAME+tracename+" succeeded_jobs/"
              rc = call(string, shell=True)
              goteloc = 0
              cbmc_start_time = "unknown"
              trace_status = "unknown error"
              cbmc_end_time = "unknown"
              trace_status = "unknown"
              ELOC="unknown"

              if os.path.exists("succeeded_jobs/"+tracename):
                with open("succeeded_jobs/"+tracename) as tracepath:
                  for line in tracepath:
                    if "CBMC version" in line:
                      cbmc_start_time = re.search(r'\d+.\d+', line).group()
                    if "VERIFICATION FAILED" in line:
                      cbmc_end_time = re.search(r'\d+.\d+', line).group()
                      trace_status = "found trace"
                    if "SAT checker ran out of memory" in line:
                      trace_status = "SAT out of memory"
                      cbmc_end_time = re.search(r'\d+.\d+', line).group()
                    if "VERIFICATION SUCCESSFUL" in line:
		      cbmc_end_time = re.search(r'\d+.\d+', line).group()
		      trace_status = "no trace found"
                    if "invariant violation" in line:
		      trace_status = "CBMC error: invariant violation"
                    if "Killed" in line:
                      trace_status = "Killed "
		    if "Effective lines of code:" in line:
		      if goteloc == 0:
		        goteloc = 1
		      	ELOC = re.sub("\D", "", line)
              else:
                trace_status = "no trace file"

              filewriter.writerow([" ", tracename, XSA_num, DEPTH, UNWIND, DP, fullslice, fp," " ," " ," " , rc, trace_status, cbmc_start_time, cbmc_end_time, ELOC])

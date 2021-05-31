import eyed3
import boto3
import json

event = '{"bucket": "spleeter-web-service-uploads", "key": "example.mp3", "size": 8412525, "last_modified_date": "2021-05-31T21:08:47+00:00", "timestamp": 1622501090240}'
event = json.loads(event)
print(event)

s3 = boto3.client('s3')
s3.download_file(event['bucket'], event['key'], event['key'], ExtraArgs={"ServerSideEncryption": "aws:kms"})

import eyed3
import boto3
import json
import logging

from botocore.exceptions import ClientError

logger = logging.getLogger()
logger.setLevel(logging.INFO)
s3 = boto3.client('s3')

def lambda_handler(event, context):
    ''' main handler '''
    if 'key' not in event.keys():
        raise Exception(f"No S3 Object in event: {event}")
    output_path = f"/tmp/{event['key']}"
    logger.info(f"[*] downloading file from s3://{event['bucket']}/{event['key']} to {output_path}")
    s3.download_file(event['bucket'], event['key'], output_path)

    if eyed3.load(output_path) == None:
        raise Exception("Not a valid .mp3 file")
    else:
        logger.info(f"[*] '{event['key']}' is a valid .mp3 file")
        return event

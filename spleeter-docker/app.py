import boto3
import json
import logging
import ffmpeg
import uuid
import os

from os import listdir
from os.path import isfile, join
from botocore.exceptions import ClientError
from spleeter.separator import Separator

result_s3_bucket = "spleeter-web-service-processed"

def lambda_handler(event, context):
    ''' main handler '''

    # Using embedded configuration.
    separator = Separator('spleeter:2stems')
    logger = logging.getLogger()
    logger.setLevel(logging.INFO)
    s3 = boto3.client('s3')

    # download file
    if 'key' not in event.keys():
        raise Exception(f"No S3 Object in event: {event}")
    download_path = f"{event['key']}"
    processed_path = "output"
    logger.info(f"[*] downloading file from s3://{event['bucket']}/{event['key']} to {download_path}")
    s3.download_file(event['bucket'], event['key'], download_path)

    # process file
    logger.info(f"[*] processing...")
    logger.info(f"[*] L_DEBUG: {listdir('./')}")
    separator.separate_to_file(download_path, processed_path)
    debug_processed_path = listdir(processed_path)
    logger.info(f"[*] L_DEBUG: {debug_processed_path}")

    # upload processed files
    try:
        processed_files_path = processed_path + "/" + event['key'].split(".")[0] # uncomment for lambda
        # processed_files_path = event['key'] + "/" + event['key'].split(".")[0] # local testing
        processed_files = [f for f in listdir(processed_files_path) if isfile(join(processed_files_path, f))]
        s3_prefix = str(uuid.uuid4())

        for file in processed_files:
            logger.info(f"[*] uploading file from {processed_files_path}/{file} to s3://{result_s3_bucket}/{s3_prefix}/{processed_files_path}/{file}")
            s3.upload_file(f'{processed_files_path}/{file}', result_s3_bucket, f'{s3_prefix}/{processed_files_path}/{file}')
    except Exception as e:
        logger.error(f"[!] issue uploading processed files: {e}")
        raise e


if __name__ == '__main__':

    event = {'bucket': 'spleeter-web-service-uploads', 'key': 'example.mp3', 'size': 8412525, 'last_modified_date': '2021-05-31T21:08:47+00:00', 'timestamp': 1622525039298}
    lambda_handler(event, None)

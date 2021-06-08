import logging
import os
from os import listdir
from os.path import isfile, join
from botocore.exceptions import ClientError
from spleeter.separator import Separator
import boto3
import ffmpeg


result_s3_bucket = "spleeter-web-service-processed"
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ['DDB_TABLE_NAME'])

def update_status(id, status):
    response = table.update_item(
        Key={
            'id': id
        },
        UpdateExpression='SET #s = :val1',
        ExpressionAttributeValues={
            ':val1': status
        },
        ExpressionAttributeNames={
            "#s": "status"
        }
    )

def handler(event):
    ''' main handler '''

    # Using embedded configuration.
    separator = Separator('spleeter:2stems')
    logger = logging.getLogger()
    logger.setLevel(logging.INFO)
    s3 = boto3.client('s3')

    # update status
    update_status(event['process_id'], 'PROCESSING')

    # download file
    if 'key' not in event.keys():
        raise Exception(f"No S3 Object in event: {event}")
    download_path = f"{event['key']}"
    processed_path = "output"
    logger.info(f"[*] downloading file from s3://{event['bucket']}/{event['key']} to {download_path}")
    s3.download_file(event['bucket'], event['key'], download_path)

    # process file
    logger.info("[*] processing...")
    separator.separate_to_file(download_path, processed_path)

    # upload processed files
    try:
        processed_files_path = processed_path + "/" + event['key'].split(".")[0]
        processed_files = [f for f in listdir(processed_files_path) if isfile(join(processed_files_path, f))]
        s3_prefix = event['process_id']

        for file in processed_files:
            logger.info(f"[*] uploading file from {processed_files_path}/{file} to s3://{result_s3_bucket}/{s3_prefix}/{processed_files_path}/{file}")
            s3.upload_file(f'{processed_files_path}/{file}', result_s3_bucket, f'{s3_prefix}/{processed_files_path}/{file}')

        # update status
        update_status(event['process_id'], 'PROCESSED')

    except Exception as e:
        logger.error(f"[!] issue uploading processed files: {e}")

        # update status
        update_status(event['process_id'], 'FAILED')
        raise e


if __name__ == '__main__':

    # validate environment
    ENVIRONMENT_VARIABLES = ['INPUT_S3_BUCKET', 'INPUT_S3_KEY', 'PROCESS_ID']
    for variable in ENVIRONMENT_VARIABLES:
        if variable not in os.environ:
            raise Exception(f"[!] missing environment variable: {variable}")

    # create event
    event = {}
    event['bucket'] = os.environ.get('INPUT_S3_BUCKET')
    event['key'] = os.environ.get('INPUT_S3_KEY')
    event['process_id'] = os.environ.get('PROCESS_ID')
    print(f"[*] valid event: {event}\n[*] starting processing")

    # test data
    if os.environ.get('USE_TEST_DATA') == 'true':
        event = {'bucket': 'spleeter-web-service-uploads', 'key': 'example.mp3', 'size': 8412525, 'last_modified_date': '2021-05-31T21:08:47+00:00', 'timestamp': 1622525039298}

    # start processing
    handler(event)

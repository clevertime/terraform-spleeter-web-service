import os
import json
from datetime import datetime
import logging
import uuid
import time

from urllib.parse import unquote_plus

import boto3
from botocore.exceptions import ClientError

logger = logging.getLogger()
logger.setLevel(logging.INFO)
sfn_client = boto3.client('stepfunctions')
statemachine_arn=os.environ['STATEMACHINE_ARN']
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ['DDB_TABLE_NAME'])
ttl = int(os.environ['TTL'])

def get_ttl(offset):
    ''' return unix epoch ms ttl based of arg: `offset` (days) '''

    offset_in_seconds = offset * 24 * 60 * 60 * 1000
    return round(time.time()) + offset_in_seconds

def update_status_table(id, message):
    ''' update dynamo with process status '''

    message['id'] = id
    message['status'] = 'UPLOADED'
    message['ttl'] = get_ttl(ttl)
    table.put_item(Item=message)

def start_statemachine(message):
    ''' invoke state machine '''

    logger.info("[*] Invoking statemachine")
    process_id = str(uuid.uuid4())
    message['process_id'] = process_id
    try:
        update_status_table(process_id, message)
    except Exception as e:
        logger.error("Fatal error", exc_info=True)
        raise e
    try:
        start_execution = sfn_client.start_execution(
            stateMachineArn=statemachine_arn,
            name = f"{message['key']}-{process_id[0:7]}",
            input=json.dumps(message)
        )
        execution_arn = start_execution['executionArn']
        logger.info(f'[*] started execution: {execution_arn}')
    except Exception as e:
        logger.error("Fatal error", exc_info=True)
        raise e

    return execution_arn

def parse_event(event):
    return {
        'bucket': event['bucket']['name'],
        'key': unquote_plus(event['object']['key']),
        'size': event['object']['size']
    }

def lambda_handler(event, context):
    try:
        logger.info('Received {} messages'.format(len(event['Records'])))

        # get events from sqs
        for record in event['Records']:
            logger.info('Parsing S3 Events')

            # pull individual batched events from s3
            try:
                s3_upload_events = json.loads(json.loads(record['body'])['Message'])
                logger.info('Received {} S3 upload events'.format(len(s3_upload_events['Records'])))
            except Exception as e:
                logger.info(f"Didn't find any S3 events: {e}")

            for event in s3_upload_events['Records']:
                print(f"[*] event: {event}")
                message = parse_event(event['s3'])
                print(f"[*] message: {message}")
                execution_arn = start_statemachine(message)

    except Exception as e:
        logger.error("Fatal error", exc_info=True)
        raise e
    return

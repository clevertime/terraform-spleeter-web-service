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

def parse_s3_event(s3_event):
    return {
        'bucket': s3_event['s3']['bucket']['name'],
        'key': unquote_plus(s3_event['s3']['object']['key']),
        'size': s3_event['s3']['object']['size'],
        'last_modified_date': s3_event['eventTime'].split('.')[0]+'+00:00',
        'timestamp': int(round(datetime.utcnow().timestamp()*1000, 0)),
    }


def lambda_handler(event, context):
    try:
        logger.info('Received {} messages'.format(len(event['Records'])))
        for record in event['Records']:
            logger.info('Parsing S3 Event')
            message = parse_s3_event(record)
            print(f"[*] message: {message}")
            execution_arn = start_statemachine(message)
    except Exception as e:
        logger.error("Fatal error", exc_info=True)
        raise e
    return

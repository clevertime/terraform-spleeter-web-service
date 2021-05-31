import os
import json
from datetime import datetime
import logging
import uuid
from urllib.parse import unquote_plus

import boto3
from botocore.exceptions import ClientError

logger = logging.getLogger()
logger.setLevel(logging.INFO)


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
    except Exception as e:
        logger.error("Fatal error", exc_info=True)
        raise e
    return

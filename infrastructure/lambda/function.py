import logging
import os
import boto3
import requests
import time
import json

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def handler(event, context):
    url = "https://yahoo-weather5.p.rapidapi.com/weather?location=milano&format=json&u=c"

    headers = {
        'X-RapidAPI-Host': 'yahoo-weather5.p.rapidapi.com',
        'X-RapidAPI-Key': os.getenv("RAPID_API_KEY")
    }

    response = requests.get(url, headers=headers)

    logger.info(response.text)

    bucket_name = os.getenv("BUCKET_NAME")
    file_name = f"{int(time.time())}.json"
    s3_path = "open-weather/" + file_name

    s3 = boto3.resource("s3")
    s3.Bucket(bucket_name).put_object(Key=s3_path, Body=(bytes(json.dumps(response.json()).encode('UTF-8'))))

    return {
        'statusCode': 200,
    }

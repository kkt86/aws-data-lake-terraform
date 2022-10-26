import logging
import os
import boto3
import requests

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def handler(event, context):
    url = "https://yahoo-weather5.p.rapidapi.com/weather?location=milano&format=json&u=c"

    headers = {
        'X-RapidAPI-Host': 'yahoo-weather5.p.rapidapi.com',
        'X-RapidAPI-Key': os.getenv("RAPID_API_KEY")
    }

    response = requests.request("GET", url, headers=headers)

    logger.info(response.text)

    return {
        'statusCode': 200,
    }

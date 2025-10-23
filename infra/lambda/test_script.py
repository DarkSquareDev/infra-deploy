import json

def lambda_handler(event, context):
    print("Lambda invoked with event:", event)
    return {
        "statusCode": 200,
        "body": json.dumps("Hello from Lambda!")
    }

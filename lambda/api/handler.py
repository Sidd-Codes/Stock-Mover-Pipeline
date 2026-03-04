import json
import boto3
import os
from datetime import datetime, timedelta
from boto3.dynamodb.conditions import Key

DYNAMODB_TABLE = os.environ["DYNAMODB_TABLE"]


def cors_headers():
    return {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers": "Content-Type",
        "Access-Control-Allow-Methods": "GET,OPTIONS",
        "Content-Type": "application/json",
    }


def get_last_7_dates():
    dates = []
    for i in range(1, 14):
        date = (datetime.utcnow() - timedelta(days=i)).strftime("%Y-%m-%d")
        dates.append(date)
    return dates


def lambda_handler(event, context):
    print("API Lambda triggered")

    if event.get("httpMethod") == "OPTIONS":
        return {"statusCode": 200, "headers": cors_headers(), "body": ""}

    try:
        dynamodb = boto3.resource("dynamodb")
        table = dynamodb.Table(DYNAMODB_TABLE)

        dates = get_last_7_dates()
        results = []

        for date in dates:
            response = table.get_item(Key={"date": date})
            item = response.get("Item")

            if item:
                results.append({
                    "date": item["date"],
                    "ticker": item["ticker"],
                    "percent_change": float(item["percent_change"]),
                    "close_price": float(item["close_price"]),
                    "is_gain": item["is_gain"],
                })

        results.sort(key=lambda x: x["date"], reverse=True)

        print(f"Returning {len(results)} records")

        return {
            "statusCode": 200,
            "headers": cors_headers(),
            "body": json.dumps(results),
        }

    except Exception as e:
        print(f"error: {str(e)}")
        return {
            "statusCode": 500,
            "headers": cors_headers(),
            "body": json.dumps({"error": "Internal server error"}),
        }
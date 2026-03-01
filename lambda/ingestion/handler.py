import json
import boto3
import urllib.request
import os
from datetime import datetime, timedelta

WATCHLIST = ["AAPL", "MSFT", "GOOGL", "AMZN", "TSLA", "NVDA"]
DYNAMODB_TABLE = os.environ["DYNAMODB_TABLE"]
SECRET_NAME    = os.environ["SECRET_NAME"]


def get_api_key():
    client = boto3.client("secretsmanager")
    response = client.get_secret_value(SecretId=SECRET_NAME)
    secret = json.loads(response["SecretString"])
    return secret["STOCK_API_KEY"]


def fetch_stock_data(ticker, date_str, api_key):
    url = f"https://api.massive.com/v1/open-close/{ticker}/{date_str}?adjusted=true&apiKey={api_key}"

    try:
        with urllib.request.urlopen(url, timeout=5) as response:
            data = json.loads(response.read().decode())

            if data.get("status") != "OK":
                print(f"[WARN] No data for {ticker} on {date_str}: {data.get('status')}")
                return None

            return {
                "ticker": ticker,
                "open":   data["open"],
                "close":  data["close"],
            }

    except Exception as e:
        print(f"[ERROR] Failed to fetch {ticker}: {str(e)}")
        return None


def calc_percent_change(open_price, close_price):
    return ((close_price - open_price) / open_price) * 100


def save_to_dynamodb(date_str, ticker, percent_change, close_price):
    dynamodb = boto3.resource("dynamodb")
    table    = dynamodb.Table(DYNAMODB_TABLE)

    table.put_item(Item={
        "date":           date_str,
        "ticker":         ticker,
        "percent_change": str(round(percent_change, 4)),
        "close_price":    str(round(close_price, 4)),
        "is_gain":        percent_change > 0,
    })

    print(f"[INFO] Saved: {ticker} {percent_change:.2f}% on {date_str}")


def lambda_handler(event, context):
    print("[INFO] Ingestion Lambda started")

    api_key  = get_api_key()

    yesterday = (datetime.utcnow() - timedelta(days=1)).strftime("%Y-%m-%d")
    print(f"[INFO] Fetching data for {yesterday}")

    results = []
    for ticker in WATCHLIST:
        data = fetch_stock_data(ticker, yesterday, api_key)
        if data:
            pct = calc_percent_change(data["open"], data["close"])
            results.append({
                "ticker":         ticker,
                "percent_change": pct,
                "close_price":    data["close"],
            })

    if not results:
        print("[WARN] No results returned for any ticker. Possibly a market holiday.")
        return {"statusCode": 200, "body": "No data available — market may be closed."}

    top_mover = max(results, key=lambda x: abs(x["percent_change"]))
    print(f"[INFO] Top mover: {top_mover['ticker']} at {top_mover['percent_change']:.2f}%")

    save_to_dynamodb(
        date_str       = yesterday,
        ticker         = top_mover["ticker"],
        percent_change = top_mover["percent_change"],
        close_price    = top_mover["close_price"],
    )

    return {
        "statusCode": 200,
        "body": json.dumps({
            "date":           yesterday,
            "top_mover":      top_mover["ticker"],
            "percent_change": round(top_mover["percent_change"], 4),
            "close_price":    top_mover["close_price"],
        })
    }
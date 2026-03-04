import json
import os
import boto3
import urllib.request
import time
from datetime import datetime, timedelta


API_KEY = os.environ["MASSIVE_API_KEY"]
TABLE_NAME = "top_movers"
WATCHLIST = ["AAPL", "MSFT", "GOOGL", "AMZN", "TSLA", "NVDA"]
DAYS_BACK = 7


def fetch_stock_data(ticker, date_str):
    url = f"https://api.massive.com/v1/open-close/{ticker}/{date_str}?adjusted=true&apiKey={API_KEY}"
    try:
        with urllib.request.urlopen(url, timeout=5) as response:
            data = json.loads(response.read().decode())
            if data.get("status") != "OK":
                return None
            return {
                "ticker": ticker,
                "open": data["open"],
                "close": data["close"],
            }
    except Exception as e:
        print(f"error: {ticker} on {date_str}: {e}")
        return None


def save_to_dynamodb(table, date_str, ticker, percent_change, close_price):
    table.put_item(Item={
        "date": date_str,
        "ticker": ticker,
        "percent_change": str(round(percent_change, 4)),
        "close_price": str(round(close_price, 4)),
        "is_gain": percent_change > 0,
    })


def main():
    dynamodb = boto3.resource("dynamodb", region_name="us-east-1")
    table = dynamodb.Table(TABLE_NAME)

    print(f"Starting backfill for last {DAYS_BACK} days\n")

    for i in range(1, DAYS_BACK + 1):
        date = (datetime.utcnow() - timedelta(days=i)).strftime("%Y-%m-%d")

        day_of_week = (datetime.utcnow() - timedelta(days=i)).weekday()
        if day_of_week >= 5:
            print(f"[SKIP] {date} — weekend")
            continue

        print(f"[FETCH] {date}")
        results = []

        for ticker in WATCHLIST:
            data = fetch_stock_data(ticker, date)
            if data:
                pct = ((data["close"] - data["open"]) / data["open"]) * 100
                results.append({
                    "ticker": ticker,
                    "percent_change": pct,
                    "close_price": data["close"],
                })
            time.sleep(12)

        if not results:
            print(f"No data returned, likely a market holiday")
            continue

        top = max(results, key=lambda x: abs(x["percent_change"]))
        save_to_dynamodb(table, date, top["ticker"], top["percent_change"], top["close_price"])
        print(f"saved {top['ticker']} {top['percent_change']:.2f}%")

    print("\nBackfill complete")

if __name__ == "__main__":
    main()
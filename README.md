# Stock Mover Pipeline

A fully serverless AWS pipeline that tracks a watchlist of tech stocks, identifies the biggest daily mover, and displays a 7-day history on a live dashboard.

## Live Demo

**Frontend:** http://stock-pipeline-frontend-7fbfde33.s3-website-us-east-1.amazonaws.com

**API:** https://ksik6p1o6k.execute-api.us-east-1.amazonaws.com/prod/movers

---

## Architecture
```
EventBridge (Cron 6:30pm EST)
        │
        ▼

Lambda (Ingestion)

Calls Massive API for each stock
Finds biggest % mover
Saves to DynamoDB

        │
        ▼

DynamoDB (top_movers table)

        │
        ▼

Lambda (API) ← API Gateway (GET /movers)

        │
        ▼

Next.js Frontend (S3 Static Hosting)
```

**Watchlist:** AAPL · MSFT · GOOGL · AMZN · TSLA · NVDA

---

## AWS Services Used

- **EventBridge** - Schedules the daily cron job
- **Lambda** - Two functions: ingestion and API
- **DynamoDB** - Stores one top mover record per trading day
- **API Gateway** - REST API exposing GET /movers
- **S3** - Hosts the Next.js static frontend
- **Secrets Manager** - Stores the stock API key securely
- **SQS** - Dead Letter Queue for failed Lambda invocations
- **CloudWatch** - Lambda logs and monitoring

---

## Requirements

1. **AWS CLI** 
2. **Terraform v1.5+**
3. **Node.js v18+**
4. **A free Massive API key**

---

## Deployment

### Step 1 — Configure AWS credentials
```bash
aws configure
```

Enter your Access Key ID, Secret Access Key, region (`us-east-1`), and output format (`json`).

### Step 2 — Store your API key in Secrets Manager
```bash
aws secretsmanager create-secret \
  --name "stock-pipeline/api-key" \
  --secret-string '{"STOCK_API_KEY":"YOUR_KEY_HERE"}'
```

### Step 3 — Deploy all AWS infrastructure
```bash
cd terraform
terraform init
terraform apply
```

Type `yes` when prompted. After apply completes, note the outputs:
- `api_gateway_url` — paste this into `frontend/stock-dashboard/app/page.js`
- `frontend_url` — your live dashboard URL

### Step 4 — Deploy the frontend
```bash
cd ../frontend/stock-dashboard
npm install
npm run build
aws s3 sync out/ s3://YOUR_BUCKET_NAME --delete
```

Replace `YOUR_BUCKET_NAME` with the bucket name from the Terraform output.

### Step 5 — Backfill historical data (first deploy only)

This seeds the last 7 trading days so the dashboard is populated immediately:
```bash
export MASSIVE_API_KEY="your_key_here"
python3 scripts/backfill.py
```

### Step 6 — Test the API
```bash
curl https://YOUR_API_GATEWAY_URL/prod/movers
```

Output should be a JSON array of the last 7 trading days.

---

## Project Structure
```
stock-mover-pipeline/
├── terraform/
│   ├── provider.tf       # AWS provider config
│   ├── variables.tf      # All configurable values
│   ├── dynamodb.tf       # DynamoDB table
│   ├── iam.tf            # Lambda permissions
│   ├── lambda.tf         # Both Lambda functions
│   ├── eventbridge.tf    # Daily cron schedule
│   ├── apigateway.tf     # REST API
│   ├── sqs.tf            # Dead Letter Queue
│   └── s3.tf             # Frontend hosting
├── lambda/
│   ├── ingestion/
│   │   └── handler.py    # Fetches stock data, saves top mover
│   └── api/
│       └── handler.py    # Reads DynamoDB, returns last 7 days
├── frontend/
│   └── stock-dashboard/  # Next.js dashboard
├── scripts/
│   └── backfill.py       # One-time historical data seeder
└── README.md
```

---

## Design Decisions & Trade-offs

**Two separate Lambda functions** - the ingestion Lambda and API Lambda are intentionally separate to follow the separation of concerns principle where one function owns writing data and the other owns reading it. They can be scaled, updated, and debugged independently.

**DynamoDB partition key is `date`** - one record per trading day keeps the data model simple. The API Lambda does individual `get_item` lookups by date which are fast and cheap on DynamoDB.

**PAY_PER_REQUEST billing** - chosen over provisioned capacity because the pipeline writes once per day and reads occasionally.

**Secrets Manager over environment variables** - the stock API key is stored in Secrets Manager and fetched at Lambda runtime. This means the key never exists in code, config files, or environment variables.

**SQS Dead Letter Queue** - if the ingestion Lambda crashes entirely, the failed event is captured in SQS for inspection and retry rather than disappearing silently.

**Backfill script** - on first deploy the DynamoDB table is empty. The backfill script seeds the last 7 trading days so the dashboard is populated immediately rather than waiting a week for the cron to accumulate data.
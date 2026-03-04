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

## Trade-offs

**Used two Lambda functions instead of one** - I separated ingestion and retrieval into distinct Lambda functions rather than combining them. This adds a small amount of infrastructure overhead but follows separation of concerns since each function has a single responsibility, can be scaled independently, and is easier to debug in isolation.

**DynamoDB over RDS** - A relational database would allow more complex queries but DynamoDB's key-value model feature worked well in this case. I stored one record per trading day and look up by date so no joins were needed. PAY_PER_REQUEST billing also helps to keep it within the free tier.

**Static export over SSR** - Next.js supports server-side rendering but hosting on S3 requires a fully static export. This means the frontend fetches data client-side on load rather than at build time, causing a brief loading state but it keeps the hosting cost at zero with no server required.

**Secrets Manager over environment variables** - storing the API key in Secrets Manager adds a small Lambda cold start overhead (one extra API call per invocation) but eliminates any risk of credentials being exposed in code or config files.

## Challenges

**Terraform state on first deploy** - managing forward references between resources (Lambda referencing SQS before SQS existed) required understanding how Terraform resolves dependency ordering.

**API rate limiting** - the free tier on Massive API limits requests per minute. The backfill script hit 429 errors initially, which I resolved by adding a delay between requests.

**CORS configuration** - wiring up CORS correctly across API Gateway and the Lambda response headers required handling both the OPTIONS preflight request and the actual GET response headers separately.

**Cold start problem** - initially the DynamoDB table was empty so the dashboard had no data. I solved this by building a backfill script that seeds the last 7 trading days on initial deploy.

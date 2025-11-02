#!/usr/bin/env bash
# Sets up the BigQuery dataset, partitioned tables, and service account needed by Travel Wizards.
# Usage: ./setup_bigquery.sh -p <gcp-project-id> [-l <location>] [-d <dataset>] [-t <table>] [-s <service-account>] [--key-output <path>]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
default_dataset="travel_wizards"
default_location="us-central1"
default_table="trip_events"
default_service_account="travel-wizards-bq-writer"
key_output=""

usage() {
  cat <<'EOF'
Usage: setup_bigquery.sh -p <gcp-project-id> [options]

Options:
  -p  Google Cloud project id (required)
  -l  BigQuery location/region (default: us-central1)
  -d  Dataset id to create (default: travel_wizards)
  -t  Table id to create in the dataset (default: trip_events)
  -s  Service account id for BigQuery writes (default: travel-wizards-bq-writer)
      The full email becomes <service-account>@<project-id>.iam.gserviceaccount.com
  --key-output  Optional path to write a JSON key for the service account
  -h  Show this help message

Examples:
  ./setup_bigquery.sh -p my-project
  ./setup_bigquery.sh -p my-project -l asia-south1 --key-output ./keys/bq-writer.json
EOF
}

PROJECT_ID=""
LOCATION="$default_location"
DATASET_ID="$default_dataset"
TABLE_ID="$default_table"
SERVICE_ACCOUNT_ID="$default_service_account"

while [[ $# -gt 0 ]]; do
  case "$1" in
    -p)
      PROJECT_ID="$2"
      shift 2
      ;;
    -l)
      LOCATION="$2"
      shift 2
      ;;
    -d)
      DATASET_ID="$2"
      shift 2
      ;;
    -t)
      TABLE_ID="$2"
      shift 2
      ;;
    -s)
      SERVICE_ACCOUNT_ID="$2"
      shift 2
      ;;
    --key-output)
      key_output="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [[ -z "$PROJECT_ID" ]]; then
  echo "Error: -p <project-id> is required" >&2
  usage
  exit 1
fi

if ! command -v gcloud >/dev/null 2>&1; then
  echo "Error: gcloud CLI not found. Install the Google Cloud SDK first." >&2
  exit 1
fi

if ! command -v bq >/dev/null 2>&1; then
  echo "Error: bq CLI not found. Install the Google Cloud SDK BigQuery component." >&2
  exit 1
fi

echo "Using project: $PROJECT_ID"
gcloud config set project "$PROJECT_ID" >/dev/null

DATASET="${PROJECT_ID}:${DATASET_ID}"
TABLE="${DATASET}.${TABLE_ID}"
SERVICE_ACCOUNT_EMAIL="${SERVICE_ACCOUNT_ID}@${PROJECT_ID}.iam.gserviceaccount.com"

# Create dataset if it does not exist
existing_datasets=$(bq ls --project_id="$PROJECT_ID" | awk 'NR>2 {print $1}')
if echo "$existing_datasets" | grep -Fx "$DATASET_ID" >/dev/null 2>&1; then
  echo "Dataset $DATASET already exists. Skipping creation."
else
  echo "Creating dataset $DATASET in $LOCATION..."
  bq --location="$LOCATION" mk --dataset \
    --description "Canonical dataset for Travel Wizards trip planning telemetry and feedback" \
    "$DATASET"
fi

SCHEMA_FILE="$SCRIPT_DIR/schemas/${TABLE_ID}_schema.json"
if [[ ! -f "$SCHEMA_FILE" ]]; then
  echo "Error: schema file $SCHEMA_FILE not found." >&2
  exit 1
fi

# Create partitioned table if it does not exist
if bq show "$TABLE" >/dev/null 2>&1; then
  echo "Table $TABLE already exists. Skipping creation."
else
  echo "Creating table $TABLE with partitioning on created_at..."
  bq mk \
    --table \
    --time_partitioning_field created_at \
  --description "Trip events telemetry partitioned by created_at" \
    "$TABLE" \
    "$SCHEMA_FILE"
fi

echo "Ensuring service account $SERVICE_ACCOUNT_EMAIL exists..."
if gcloud iam service-accounts describe "$SERVICE_ACCOUNT_EMAIL" >/dev/null 2>&1; then
  echo "Service account already exists."
else
  gcloud iam service-accounts create "$SERVICE_ACCOUNT_ID" \
    --display-name "Travel Wizards BigQuery Writer"
fi

echo "Granting BigQuery roles to $SERVICE_ACCOUNT_EMAIL..."
gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member "serviceAccount:${SERVICE_ACCOUNT_EMAIL}" \
  --role "roles/bigquery.dataEditor" >/dev/null

gcloud projects add-iam-policy-binding "$PROJECT_ID" \
  --member "serviceAccount:${SERVICE_ACCOUNT_EMAIL}" \
  --role "roles/bigquery.jobUser" >/dev/null

if [[ -n "$key_output" ]]; then
  mkdir -p "$(dirname "$key_output")"
  echo "Creating service account key at $key_output..."
  gcloud iam service-accounts keys create "$key_output" \
    --iam-account "$SERVICE_ACCOUNT_EMAIL"
  echo "Key created. Store this file securely and never commit it to source control."
else
  echo "Skipping key creation. Use --key-output <path> if you need a JSON key."
fi

echo "BigQuery setup complete."

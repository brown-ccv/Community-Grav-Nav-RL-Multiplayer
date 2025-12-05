#!/bin/bash
set -e

# ============================================================================
# GCP Service Account Setup Script
# ============================================================================
# This script creates a PROJECT-LEVEL service account for Cloud Run deployment
# and assigns necessary IAM roles.
#
# For ORGANIZATION-LEVEL service accounts, contact your GCP admin.
# See DEPLOYMENT.md "Service Account Options" section for details.
# ============================================================================

echo "🔧 Setting up GCP Service Account for Cloud Run Deployment"
echo ""
echo "ℹ️  This script creates a PROJECT-LEVEL service account."
echo "ℹ️  For organization-level service accounts, see DEPLOYMENT.md"
echo ""

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    echo "❌ ERROR: gcloud CLI is not installed"
    echo "Please install it from: https://cloud.google.com/sdk/docs/install"
    exit 1
fi

# Prompt for project ID
read -p "Enter your GCP Project ID: " PROJECT_ID

if [ -z "$PROJECT_ID" ]; then
    echo "❌ ERROR: Project ID cannot be empty"
    exit 1
fi

# Set the project
echo "📍 Setting project to: $PROJECT_ID"
gcloud config set project "$PROJECT_ID"

# Define service account details
SA_NAME="grav-nav-cloud-run-sa"
SA_EMAIL="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"
SA_DISPLAY_NAME="Grav Nav Cloud Run Service Account"

# Check if service account already exists
if gcloud iam service-accounts describe "$SA_EMAIL" &> /dev/null; then
    echo "⚠️  Service account $SA_EMAIL already exists"
    read -p "Do you want to update its roles? (y/n): " UPDATE_ROLES
    if [ "$UPDATE_ROLES" != "y" ]; then
        echo "ℹ️  Skipping role assignment"
        exit 0
    fi
else
    # Create service account
    echo "📝 Creating service account: $SA_NAME"
    gcloud iam service-accounts create "$SA_NAME" \
        --display-name="$SA_DISPLAY_NAME" \
        --description="Service account for Grav Nav multiplayer game Cloud Run deployment"
fi

# Required IAM roles for Cloud Run deployment
ROLES=(
    "roles/run.admin"                    # Deploy and manage Cloud Run services
    "roles/iam.serviceAccountUser"       # Act as service account
    "roles/storage.admin"                # Manage Cloud Storage (for models and persistent data)
    "roles/artifactregistry.writer"      # Push images to Artifact Registry
    "roles/logging.logWriter"            # Write logs
    "roles/cloudtrace.agent"             # Send traces
)

echo ""
echo "🔐 Assigning IAM roles to service account..."

for ROLE in "${ROLES[@]}"; do
    echo "  → Assigning $ROLE"
    gcloud projects add-iam-policy-binding "$PROJECT_ID" \
        --member="serviceAccount:$SA_EMAIL" \
        --role="$ROLE" \
        --quiet > /dev/null
done

echo ""
echo "🔑 Creating and downloading service account key..."
KEY_FILE="grav-nav-sa-key.json"

# Remove old key file if exists
if [ -f "$KEY_FILE" ]; then
    rm "$KEY_FILE"
fi

# Create new key
gcloud iam service-accounts keys create "$KEY_FILE" \
    --iam-account="$SA_EMAIL"

echo ""
echo "✅ Service account setup complete!"
echo ""
echo "📋 Summary:"
echo "  • Service Account: $SA_EMAIL"
echo "  • Key File: $KEY_FILE"
echo ""
echo "🔒 IMPORTANT: Store the key file securely!"
echo ""
echo "📌 Next Steps:"
echo "  1. Add the following secrets to your GitHub repository:"
echo ""
echo "     GCP_PROJECT_ID: $PROJECT_ID"
echo ""
echo "     GCP_SERVICE_ACCOUNT_KEY: <contents of $KEY_FILE>"
echo ""
echo "  2. Run the GitHub secrets setup script:"
echo "     ./deployment/scripts/github/setup-github-secrets.sh"
echo ""
echo "  3. Enable required GCP APIs:"
echo "     gcloud services enable run.googleapis.com"
echo "     gcloud services enable artifactregistry.googleapis.com"
echo "     gcloud services enable cloudbuild.googleapis.com"
echo "     gcloud services enable storage.googleapis.com"
echo ""

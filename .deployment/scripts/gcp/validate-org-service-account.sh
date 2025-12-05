#!/bin/bash
set -e

# ============================================================================
# Organization Service Account Validation Script
# ============================================================================
# This script validates that an organization-level service account has
# the required permissions for Cloud Run deployment.
# ============================================================================

echo "🔍 Validating Organization Service Account Permissions"
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

# Prompt for organization service account email
read -p "Enter organization service account email: " ORG_SA_EMAIL

if [ -z "$ORG_SA_EMAIL" ]; then
    echo "❌ ERROR: Service account email cannot be empty"
    exit 1
fi

# Set the project
echo "📍 Setting project to: $PROJECT_ID"
gcloud config set project "$PROJECT_ID"

echo ""
echo "🔍 Checking if service account exists..."

# Check if service account exists
if gcloud iam service-accounts describe "$ORG_SA_EMAIL" &> /dev/null; then
    echo "✅ Service account exists: $ORG_SA_EMAIL"
else
    echo "❌ ERROR: Service account does not exist or you don't have permission to view it"
    echo "Please contact your GCP organization administrator"
    exit 1
fi

echo ""
echo "🔐 Checking IAM permissions on project: $PROJECT_ID"
echo ""

# Required IAM roles for Cloud Run deployment
REQUIRED_ROLES=(
    "roles/run.admin"
    "roles/iam.serviceAccountUser"
    "roles/storage.admin"
    "roles/artifactregistry.writer"
    "roles/logging.logWriter"
    "roles/cloudtrace.agent"
)

# Get current IAM policy for the project
POLICY=$(gcloud projects get-iam-policy "$PROJECT_ID" --flatten="bindings[].members" --filter="bindings.members:serviceAccount:$ORG_SA_EMAIL" --format="value(bindings.role)")

MISSING_ROLES=()
FOUND_ROLES=()

for ROLE in "${REQUIRED_ROLES[@]}"; do
    if echo "$POLICY" | grep -q "$ROLE"; then
        echo "  ✅ $ROLE"
        FOUND_ROLES+=("$ROLE")
    else
        echo "  ❌ $ROLE (MISSING)"
        MISSING_ROLES+=("$ROLE")
    fi
done

echo ""

if [ ${#MISSING_ROLES[@]} -eq 0 ]; then
    echo "✅ All required permissions are present!"
    echo ""
    echo "📋 Summary:"
    echo "  • Service Account: $ORG_SA_EMAIL"
    echo "  • Project: $PROJECT_ID"
    echo "  • Permissions: ${#FOUND_ROLES[@]}/${#REQUIRED_ROLES[@]} roles granted"
    echo ""
    echo "✅ This organization service account is ready to use!"
    echo ""
    echo "📌 Next Steps:"
    echo "  1. Obtain the JSON key file from your GCP administrator"
    echo "  2. Add GitHub secrets:"
    echo "     gh secret set GCP_PROJECT_ID --body \"$PROJECT_ID\""
    echo "     gh secret set GCP_SERVICE_ACCOUNT_KEY < org-service-account-key.json"
    echo ""
else
    echo "⚠️  WARNING: Missing ${#MISSING_ROLES[@]} required permission(s)"
    echo ""
    echo "📋 Missing Roles:"
    for ROLE in "${MISSING_ROLES[@]}"; do
        echo "  • $ROLE"
    done
    echo ""
    echo "🔧 To grant missing permissions, run these commands (requires project owner/admin):"
    echo ""
    for ROLE in "${MISSING_ROLES[@]}"; do
        echo "gcloud projects add-iam-policy-binding $PROJECT_ID \\"
        echo "    --member=\"serviceAccount:$ORG_SA_EMAIL\" \\"
        echo "    --role=\"$ROLE\""
        echo ""
    done
    echo "OR contact your GCP organization administrator to grant these permissions."
    echo ""
    exit 1
fi

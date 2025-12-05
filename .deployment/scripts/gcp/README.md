# GCP Setup Scripts

This directory contains scripts for setting up Google Cloud Platform resources for the Grav Nav RL Multiplayer deployment.

## Scripts Overview

### `setup-artifact-registry.sh`
Creates a Docker repository in Google Artifact Registry for storing container images.

**When to use:** Always run this first as part of initial GCP setup.

```bash
./setup-artifact-registry.sh
```

---

### `setup-service-account.sh`
Creates a **project-level** service account with all required permissions for Cloud Run deployment.

**When to use:** 
- ✅ First-time setup for individual projects
- ✅ Single project deployments
- ✅ When you have project owner/admin permissions

**NOT needed if:**
- ❌ Using an organization-level service account
- ❌ Service account already exists

```bash
./setup-service-account.sh
```

---

### `validate-org-service-account.sh`
Validates that an **organization-level** service account has the required permissions.

**When to use:**
- ✅ Using an organization service account (e.g., from Brown CCV)
- ✅ Multi-project deployments
- ✅ When your organization manages service accounts centrally

**Prerequisites:**
- Organization service account already created by your admin
- Service account email address

```bash
./validate-org-service-account.sh
```

---

## Decision Tree: Which Service Account Should I Use?

```
Do you have an organization service account from your admin?
├─ YES → Use organization service account
│         1. Run: validate-org-service-account.sh
│         2. Obtain JSON key from your admin
│         3. Skip setup-service-account.sh
│
└─ NO → Create project-level service account
          1. Run: setup-artifact-registry.sh
          2. Run: setup-service-account.sh
          3. Use generated grav-nav-sa-key.json
```

## Required Permissions

Both project-level and organization-level service accounts need these IAM roles **on your project**:

| Role | Purpose |
|------|---------|
| `roles/run.admin` | Deploy and manage Cloud Run services |
| `roles/iam.serviceAccountUser` | Act as service account |
| `roles/storage.admin` | Manage Cloud Storage |
| `roles/artifactregistry.writer` | Push Docker images |
| `roles/logging.logWriter` | Write application logs |
| `roles/cloudtrace.agent` | Send performance traces |

## For Brown CCV Users

If you're part of the Brown Center for Computation and Visualization:

1. **Check with your team lead** about existing organization service accounts
2. **Use the organization service account** if available for better resource management
3. **Run `validate-org-service-account.sh`** to verify permissions
4. **Contact CCV support** if you need a new organization service account created

## Troubleshooting

### "Permission Denied" Errors
- Verify you have the right permissions to create service accounts (Project IAM Admin role)
- Try using an organization service account instead

### "Service Account Already Exists"
- The setup script will ask if you want to update roles
- Or skip to the next step if the service account is already configured

### "Organization Service Account Not Found"
- Verify the email address is correct
- Check with your GCP organization administrator
- Ensure you're authenticated with the right account: `gcloud auth list`

## Additional Resources

- [GCP Service Accounts Documentation](https://cloud.google.com/iam/docs/service-accounts)
- [Cloud Run IAM Permissions](https://cloud.google.com/run/docs/reference/iam/roles)
- [Main Deployment Guide](../../DEPLOYMENT.md)

#!/bin/bash
set -euo pipefail
AWS_REGION="${AWS_REGION:-us-east-1}"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
BUCKET_NAME="terraform-state-${ACCOUNT_ID}-${AWS_REGION}"
DYNAMODB_TABLE="terraform-state-lock"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " Bootstrapping Terraform Backend"
echo " Account:  ${ACCOUNT_ID}"
echo " Bucket:   ${BUCKET_NAME}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "[1/5] Creating S3 bucket..."
if aws s3api head-bucket --bucket "${BUCKET_NAME}" 2>/dev/null; then
  echo "  ✓ Bucket already exists"
else
  aws s3api create-bucket --bucket "${BUCKET_NAME}" --region "${AWS_REGION}"
  echo "  ✓ Bucket created"
fi
echo "[2/5] Enabling versioning..."
aws s3api put-bucket-versioning --bucket "${BUCKET_NAME}" --versioning-configuration Status=Enabled
echo "  ✓ Done"
echo "[3/5] Enabling encryption..."
aws s3api put-bucket-encryption --bucket "${BUCKET_NAME}" --server-side-encryption-configuration '\{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"},"BucketKeyEnabled":true}]\}'
echo "  ✓ Done"
echo "[4/5] Blocking public access..."
aws s3api put-public-access-block --bucket "${BUCKET_NAME}" --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true
echo "  ✓ Done"
echo "[5/5] Creating DynamoDB lock table..."
if aws dynamodb describe-table --table-name "${DYNAMODB_TABLE}" --region "${AWS_REGION}" 2>/dev/null; then
  echo "  ✓ Table already exists"
else
  aws dynamodb create-table --table-name "${DYNAMODB_TABLE}" --attribute-definitions AttributeName=LockID,AttributeType=S --key-schema AttributeName=LockID,KeyType=HASH --billing-mode PAY_PER_REQUEST --region "${AWS_REGION}"
  echo "  ✓ Done"
fi
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " Bootstrap Complete! Bucket: ${BUCKET_NAME}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

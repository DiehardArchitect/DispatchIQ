# Lessons Learned & Troubleshooting Log

## 2026-02-19 — Bootstrap Script Encryption Command Failed on macOS

**What I was trying to do:**
Running bootstrap.sh to configure the Terraform S3 backend with AES-256 encryption.

**What went wrong:**
Error parsing parameter '--server-side-encryption-configuration': 
Expected: '=', received: '\'

**Why it happened:**
The bootstrap script escaped the JSON curly braces with backslashes for bash 
compatibility. macOS zsh interprets those escape characters differently — it 
broke the JSON string before the AWS CLI could parse it.

**How I fixed it:**
Ran the encryption command manually with single-quoted JSON directly in terminal:

aws s3api put-bucket-encryption \
  --bucket "terraform-state-975050048256-us-east-1" \
  --server-side-encryption-configuration \
  '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'

**What I learned:**
Shell escaping behaves differently between bash and zsh, and between Linux and 
macOS. When writing scripts meant to run cross-platform, use single quotes around 
JSON arguments rather than escaped double quotes. The AWS CLI expects raw JSON.

---
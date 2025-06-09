#!/bin/bash
# AWS Deployment Script for FlashLoan Arbitrage Bot

set -e

GREEN='\033[0;32m'
NC='\033[0m'

log() { echo -e "${GREEN}[INFO]${NC} $1"; }

log "🚀 AWS Deployment for FlashLoan Arbitrage Bot"
log "============================================="

AWS_REGION="${AWS_REGION:-us-east-1}"
INSTANCE_TYPE="${INSTANCE_TYPE:-t3.medium}"
KEY_NAME="${KEY_NAME:-flashloan-key}"
SECURITY_GROUP="${SECURITY_GROUP:-flashloan-sg}"
REPO_URL="${REPO_URL:-https://github.com/your-org/flash-bot.git}"
BRANCH="${BRANCH:-main}"
AMI_ID="${AMI_ID:-ami-0c02fb55956c7d316}"

# Create key pair if it doesn't exist
if ! aws ec2 describe-key-pairs --key-name "$KEY_NAME" --region "$AWS_REGION" >/dev/null 2>&1; then
  log "Creating EC2 key pair $KEY_NAME"
  aws ec2 create-key-pair --key-name "$KEY_NAME" --region "$AWS_REGION" \
    --query 'KeyMaterial' --output text > "${KEY_NAME}.pem"
  chmod 400 "${KEY_NAME}.pem"
fi

# Setup security group
SG_ID=$(aws ec2 describe-security-groups --group-names "$SECURITY_GROUP" --region "$AWS_REGION" \
  --query 'SecurityGroups[0].GroupId' --output text 2>/dev/null || true)
if [ -z "$SG_ID" ] || [ "$SG_ID" = "None" ]; then
  log "Creating security group $SECURITY_GROUP"
  SG_ID=$(aws ec2 create-security-group --group-name "$SECURITY_GROUP" \
    --description "FlashLoan bot SG" --region "$AWS_REGION" \
    --query 'GroupId' --output text)
  aws ec2 authorize-security-group-ingress --group-id "$SG_ID" --protocol tcp --port 22 --cidr 0.0.0.0/0 --region "$AWS_REGION"
  aws ec2 authorize-security-group-ingress --group-id "$SG_ID" --protocol tcp --port 80 --cidr 0.0.0.0/0 --region "$AWS_REGION"
  aws ec2 authorize-security-group-ingress --group-id "$SG_ID" --protocol tcp --port 443 --cidr 0.0.0.0/0 --region "$AWS_REGION"
fi

log "Launching EC2 instance..."
cat > user-data.sh <<EOF
#!/bin/bash
set -e
yum update -y
curl -fsSL https://rpm.nodesource.com/setup_18.x | bash -
yum install -y nodejs git python3 python3-venv docker
systemctl enable --now docker
usermod -aG docker ec2-user
npm install -g pm2

cd /home/ec2-user
git clone $REPO_URL flash-bot
cd flash-bot
git checkout $BRANCH

if [ ! -f .env ]; then
  cp .env.example .env
fi

npm run install-all

cd contract
npx hardhat run scripts/deploy.js --network polygon
cd ..

cd frontend && npm run build && cd ..
pm2 start ecosystem.config.js
pm2 start --name flashloan-frontend npx serve -s frontend/dist -l 80
pm2 save
EOF

INSTANCE_ID=$(aws ec2 run-instances --image-id "$AMI_ID" --instance-type "$INSTANCE_TYPE" \
  --key-name "$KEY_NAME" --security-group-ids "$SG_ID" \
  --user-data file://user-data.sh --region "$AWS_REGION" \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=flashloan-bot}]' \
  --query 'Instances[0].InstanceId' --output text)

aws ec2 wait instance-running --instance-ids "$INSTANCE_ID" --region "$AWS_REGION"
PUBLIC_IP=$(aws ec2 describe-instances --instance-ids "$INSTANCE_ID" --region "$AWS_REGION" \
  --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)

log "Instance created: $PUBLIC_IP"
log "Access the dashboard after a few minutes: http://$PUBLIC_IP"

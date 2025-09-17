# DIY Dynamic DNS with AWS CLI v2 + Route 53

Implement a **Dynamic DNS (DDNS)** solution using **AWS CLI v2** and **Route 53** for a home server (Orange Pi, Raspberry Pi, or Linux box). Updates a DNS A record automatically when your public IP changes.

---

## ⚙️ Prerequisites

### 1. Install AWS CLI v2

**ARM64 (Orange Pi / Raspberry Pi):**
```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
aws --version
```

**x86_64:**
```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
aws --version
```

### 2. Route 53 Hosted Zone & Subdomain

- Ensure you have a **hosted zone** (e.g., `example.com`).
- Create a **new A record** (`home.example.com`) — the script will update this automatically.

### 3. IAM Policy

Least-privilege example (replace `ZXXXXXXXXXXXXX` with your hosted zone ID):
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "route53:ListHostedZones",
        "route53:ListResourceRecordSets",
        "route53:ChangeResourceRecordSets"
      ],
      "Resource": "arn:aws:route53:::hostedzone/ZXXXXXXXXXXXXX"
    }
  ]
}
```
Generate **Access Key ID & Secret Access Key** for this user.

### 4. Configure AWS CLI

```bash
aws configure --profile ddns
```

Stores credentials in `~/.aws/credentials`:
```
[ddns]
aws_access_key_id = YOUR_ACCESS_KEY
aws_secret_access_key = YOUR_SECRET_KEY
```

---

## 🖥️ Script: `update-ddns.sh`

```bash
#!/bin/bash
ZONE_ID="ZXXXXXXXXXXXXX"
RECORD_NAME="home.example.com."
PROFILE="ddns"
TTL=300

CURRENT_IP=$(curl -s https://checkip.amazonaws.com)
DNS_IP=$(aws route53 list-resource-record-sets \
    --hosted-zone-id "$ZONE_ID" \
    --query "ResourceRecordSets[?Name=='$RECORD_NAME'].ResourceRecords[0].Value" \
    --output text --profile "$PROFILE")

if [ "$CURRENT_IP" != "$DNS_IP" ]; then
    echo "Updating DNS record from $DNS_IP to $CURRENT_IP"
    CHANGE_BATCH=$(cat <<EOF
{
  "Comment": "DDNS update",
  "Changes":[{"Action":"UPSERT","ResourceRecordSet":{"Name":"$RECORD_NAME","Type":"A","TTL":$TTL,"ResourceRecords":[{"Value":"$CURRENT_IP"}]}}]
}
EOF
)
    aws route53 change-resource-record-sets --hosted-zone-id "$ZONE_ID" --change-batch "$CHANGE_BATCH" --profile "$PROFILE"
else
    echo "IP has not changed ($CURRENT_IP). No update needed."
fi
```

Make it executable:
```bash
chmod +x update-ddns.sh
```

---

## ⏰ Cron Job

Run daily at midnight:
```
0 0 * * * /home/ubuntu/update-ddns.sh >>/home/ubuntu/dns-update.log 2>&1
```

Or every 15 minutes:
```
*/15 * * * * /home/ubuntu/update-ddns.sh >>/home/ubuntu/dns-update.log 2>&1
```


**Examples:**
- IP changed:
```
Updating DNS record from 81.23.45.67 to 81.56.78.90
```
- No change:
```
IP has not changed (81.56.78.90). No update needed.
```
- Errors: AWS credentials or zone/record misconfigured.

---

## ✅ Benefits

- No third-party DDNS provider
- Minimal cost (Route 53 hosted zone + updates)
- Simple, portable, easy to maintain
- Secure with least-privilege IAM policy

---


## ⚡ Alternative Approach (Optional)

- Use **API Gateway → Lambda → Route 53** with a **static key**.
- Pros: no credentials on your server, centralized updates.
- Cons: more complex setup, slightly higher latency, extra security management.

💡 For a home server, **CLI + cron** is simpler, secure, and easy to maintain.

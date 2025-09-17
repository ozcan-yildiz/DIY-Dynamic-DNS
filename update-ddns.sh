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

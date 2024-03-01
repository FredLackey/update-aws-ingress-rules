#!/bin/bash

main() {

  PATH=/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:/opt/homebrew/bin/jq

  # Check if profile name and security group ID are provided
  if [ $# -lt 2 ]; then
    echo "Usage: $0 <profile-name> <security-group-id>"
    exit 1
  fi

  export AWS_PAGER=""

  local profile_name="$1"
  local group_id="$2"

  # Detect current public IP address
  public_ip=$(curl -s https://api.ipify.org)

  # Get ingress rules for the security group
  ingress_rules=$(aws ec2 describe-security-groups --profile "$profile_name" --group-ids "$group_id" --query 'SecurityGroups[0].IpPermissions[].IpRanges[].CidrIp' --output text)

  # Check if public IP is in any of the ingress rules
  if echo "$ingress_rules" | grep -q "$public_ip"; then
    echo "Your public IP ($public_ip) is already in the security group $group_id."
    return 0
  fi

  eval "aws ec2 authorize-security-group-ingress --profile $profile_name --group-id $group_id --protocol tcp --port 0-65535 --cidr $public_ip/32 --no-paginate"
  eval "aws ec2 authorize-security-group-ingress --profile $profile_name --group-id $group_id --protocol udp --port 0-65535 --cidr $public_ip/32 --no-paginate"

  echo "Ingress rules for TCP and UDP traffic from your current public IP ($public_ip) have been successfully added to the security group."
}

# Call the main function with provided arguments
main "$@"

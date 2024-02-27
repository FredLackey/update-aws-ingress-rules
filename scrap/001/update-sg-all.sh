#!/bin/bash

main() {

  if [ "$#" -ne 2 ]; then
    echo "Usage: $0 profileName securityGroupId"
    echo "Example"
    echo " "
    echo "   $0 pbx sg-01234567890123456"
    echo " "
    exit 1
  fi

  local profileName=$1
  local securityGroupId=$2

  delete_all_ipv4_ingress_rules() {
    local groupId=$1
    echo "Delete old rule..."
    eval "aws ec2 revoke-security-group-ingress --profile $profileName --group-id $groupId --protocol all --port all"
  }

  # Delete existing ingress rules allowing all IPv4 traffic
# Delete existing ingress rules allowing all IPv4 traffic
  # delete_all_ipv4_ingress_rules() {
  #     local groupId=$1
  #     echo "Deleting existing ingress rules allowing all IPv4 traffic for security group $groupId"
      
  #     # Check if any rules allowing all IPv4 traffic exist (dry run)
  #     local remaining_count=$(aws ec2 describe-security-groups --profile $profileName --group-ids $groupId --query "length(SecurityGroups[].IpPermissions[?IpRanges[0].CidrIp=='0.0.0.0/0'])" 2>/dev/null)
  #     if [ "$remaining_count" -eq 0 ]; then
  #         echo "No ingress rules allowing all IPv4 traffic found. Skipping deletion."
  #         return
  #     fi
      
  #     # Delete the ingress rules
  #     echo "Delete old rule..."
  #     if aws ec2 revoke-security-group-ingress --profile $profileName --group-id $groupId --protocol all --port all > /dev/null; then
  #         # Verify if the rules have been successfully deleted
  #         local remaining_count=$(aws ec2 describe-security-groups --profile $profileName --group-ids $groupId --query "length(SecurityGroups[].IpPermissions[?IpRanges[0].CidrIp=='0.0.0.0/0'])")
  #         if [ "$remaining_count" -eq 0 ]; then
  #             echo "Ingress rules allowing all IPv4 traffic have been successfully deleted."
  #         else
  #             echo "Failed to delete ingress rules allowing all IPv4 traffic."
  #         fi
  #     else
  #         echo "Failed to delete ingress rules allowing all IPv4 traffic."
  #     fi
  # }






  add_ingress_rule() {
    local groupId=$1
    local publicIp=$(get_public_ip)

    echo "Create new rule..."

    if aws ec2 describe-security-groups --profile $profileName --group-ids $groupId --query "SecurityGroups[].IpPermissions[?IpRanges[0].CidrIp=='$publicIp/32']" &> /dev/null; then
      echo "  > NOT NEEDED"
      return
    fi


    eval "aws ec2 authorize-security-group-ingress --profile $profileName --group-id $groupId --protocol all --port all --cidr $publicIp/32"

    if aws ec2 describe-security-groups --profile $profileName --group-ids $groupId --query "SecurityGroups[].IpPermissions[?IpRanges[0].CidrIp=='$publicIp/32']" &> /dev/null; then
     echo "  > SUCCESS"
    else
      echo "  > FAILED"
    fi
  }

  delete_all_ipv4_ingress_rules "$securityGroupId"

  add_ingress_rule "$securityGroupId"
}

get_public_ip() {
  local publicIp
  publicIp=$(curl -s https://api.ipify.org)
  echo "$publicIp"
}

main "$@"

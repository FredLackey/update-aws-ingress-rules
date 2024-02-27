#!/bin/bash

main() {
  # Check if profileName and securityGroupId are provided
  if [ $# -ne 2 ]; then
    echo "Usage: $0 <profileName> <securityGroupId>"
    return 1
  fi

  local profile_name="$1"
  local sg_id="$2"

  # Function to check if an ingress rule exists
  ingress_rule_exists() {
    local rule="$1"
    local ingress_rules="$2"

    # Check if the rule exists in the list of ingress rules
    if [[ "$ingress_rules" == *"$rule"* ]]; then
      return 0 # Rule exists
    else
      return 1 # Rule does not exist
    fi
  }

  # Loop until all ingress rules are removed
  while :; do
    # AWS CLI command to describe ingress rules of the specified security group
    ingress_rules=$(aws ec2 describe-security-groups --profile "$profile_name" --group-ids "$sg_id" --query 'SecurityGroups[].IpPermissions[]' --output json)

    # Check if there are any ingress rules
    if [ -z "$ingress_rules" ]; then
      echo "No ingress rules found for security group $sg_id."
      break
    fi

    # Flag to track if any rules were removed in this iteration
    removed=false

    # Loop through the ingress rules and delete each one
    # Loop through the ingress rules and delete each one
    for rule in $(echo "$ingress_rules" | jq -r '.[] | @base64'); do
      _jq() {
        echo "${rule}" | base64 --decode | jq -r "$1"
      }

      # Extract rule information
      ip_protocol=$(_jq '.IpProtocol')
      from_port=$(_jq '.FromPort')
      to_port=$(_jq '.ToPort')
      ip_ranges=$(_jq '.IpRanges[].CidrIp')

      # Delete the ingress rule
      echo "Deleting ingress rule: Protocol: $ip_protocol, From Port: $from_port, To Port: $to_port, IP Ranges: $ip_ranges"
      aws ec2 revoke-security-group-ingress --profile "$profile_name" --group-id "$sg_id" --protocol "$ip_protocol" --port "$from_port" --cidr "$ip_ranges" >/dev/null 2>&1

      # Check if the rule still exists
      if ingress_rule_exists "$rule" "$ingress_rules"; then
        echo "Ingress rule not yet removed. Retrying..."
        removed=false
        break
      else
        removed=true
        echo "Ingress rule removed successfully."
      fi

      # Update the list of ingress rules after removal
      ingress_rules=$(aws ec2 describe-security-groups --profile "$profile_name" --group-ids "$sg_id" --query 'SecurityGroups[].IpPermissions[]' --output json)
    done

    # If no rules were removed in this iteration, exit the loop
    if [ "$removed" = false ]; then
      break
    fi
  done
}

# Call the main function with command-line arguments
main "$@"

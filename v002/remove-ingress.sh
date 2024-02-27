#!/bin/bash

main() {
    # Check if at least two arguments are provided
    if [ $# -lt 2 ]; then
        echo "Usage: $0 <profile-name> <security-group-id>"
        exit 1
    fi

    local profile_name="$1"
    local group_id="$2"

    # Step 1: Describe the security group to get its rules
    rules=$(aws ec2 describe-security-groups --profile "$profile_name" --group-id "$group_id" --query 'SecurityGroups[*].IpPermissions[]')

    # Iterate over each rule and revoke it
    while IFS= read -r rule; do
        ip_protocol=$(jq -r '.IpProtocol' <<< "$rule")
        from_port=$(jq -r '.FromPort' <<< "$rule")
        to_port=$(jq -r '.ToPort' <<< "$rule")

        # If the rule has specific IP ranges, revoke them
        for ip_range in $(jq -r '.IpRanges[].CidrIp' <<< "$rule"); do
            echo "Revoking rule for $ip_protocol traffic from port $from_port to port $to_port for CIDR block: $ip_range"
            aws ec2 revoke-security-group-ingress --profile "$profile_name" --group-id "$group_id" --protocol "$ip_protocol" --port "$from_port-$to_port" --cidr "$ip_range"
        done

        # If the rule has specific security groups referenced, revoke them
        for group_id_ref in $(jq -r '.UserIdGroupPairs[].GroupId' <<< "$rule"); do
            echo "Revoking rule for $ip_protocol traffic from port $from_port to port $to_port for Security Group ID: $group_id_ref"
            aws ec2 revoke-security-group-ingress --profile "$profile_name" --group-id "$group_id" --protocol "$ip_protocol" --port "$from_port-$to_port" --source-group "$group_id_ref"
        done
    done <<< "$(echo "$rules" | jq -c '.[]')"
}

main "$@"

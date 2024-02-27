#!/bin/bash

main() {
    # Check if AWS CLI is installed
    if ! command -v aws &>/dev/null; then
        echo "AWS CLI is not installed. Please install it and configure credentials."
        exit 1
    fi

    # Check if profile name is provided
    if [[ -z $1 ]]; then
        echo "Usage: $0 <profileName> <securityGroupId>"
        exit 1
    fi

    # Check if security group ID is provided
    if [[ -z $2 ]]; then
        echo "Usage: $0 <profileName> <securityGroupId>"
        exit 1
    fi

    profileName=$1
    securityGroupId=$2

    # Fetch existing ingress rules
    ingress_rules=$(aws ec2 describe-security-group-rules --profile "$profileName" --group-id "$securityGroupId" --query "SecurityGroupRules[?Type == 'ingress']")

    # Revoke all ingress rules
    for rule in $(echo "$ingress_rules" | jq -c '.[]'); do
        protocol=$(echo "$rule" | jq -r '.IpProtocol')
        from_port=$(echo "$rule" | jq -r '.FromPort')
        to_port=$(echo "$rule" | jq -r '.ToPort')
        cidr=$(echo "$rule" | jq -r '.IpRanges[0].CidrIp')
        aws ec2 revoke-security-group-ingress --profile "$profileName" --group-id "$securityGroupId" --protocol "$protocol" --port "$from_port" --cidr "$cidr" &>/dev/null
    done

    echo "All ingress rules within the security group $securityGroupId have been deleted."
}

# Call main function with arguments passed from command line
main "$@"

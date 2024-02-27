#!/bin/bash

main() {
    # Check if profile name and security group ID are provided
    if [ $# -lt 2 ]; then
        echo "Usage: $0 <profile-name> <security-group-id>"
        exit 1
    fi

    local profile_name="$1"
    local group_id="$2"

    # Detect current public IP address
    public_ip=$(curl -s https://api.ipify.org)

    # Create ingress rules for TCP and UDP traffic from the public IP
    aws ec2 authorize-security-group-ingress \
        --profile "$profile_name" \
        --group-id "$group_id" \
        --protocol tcp \
        --port 0-65535 \
        --cidr "$public_ip/32"

    aws ec2 authorize-security-group-ingress \
        --profile "$profile_name" \
        --group-id "$group_id" \
        --protocol udp \
        --port 0-65535 \
        --cidr "$public_ip/32"

    echo "Ingress rules for TCP and UDP traffic from your current public IP ($public_ip) have been successfully added to the security group."
}

# Call the main function with provided arguments
main "$@"

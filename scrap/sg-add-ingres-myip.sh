#!/bin/bash

main() {
    # Check if profileName and securityGroupId are provided
    if [ $# -ne 2 ]; then
        echo "Usage: $0 <profileName> <securityGroupId>"
        return 1
    fi

    local profile_name="$1"
    local sg_id="$2"

    # Get public IP address
    my_ip=$(curl -s https://api.ipify.org)

    # Add ingress rule to allow traffic from your IP
    echo "Adding ingress rule to allow traffic from your IP ($my_ip) to security group $sg_id..."
    aws ec2 authorize-security-group-ingress --profile "$profile_name" --group-id "$sg_id" --protocol all --cidr "$my_ip/32" > /dev/null 2>&1
    echo "Ingress rule added successfully."
}

# Call the main function with command-line arguments
main "$@"

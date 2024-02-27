# Update AWS Ingress Rules with Dynamic IP

Script to update AWS Security Group Ingress Rules with the current public IP address of the machine running the script.

## Background  

There are many reasons why we may want to restrict access to AWS resources to a specific IP address or range of IP addresses.  For example, we may want to restrict access to a database server to only the IP address of the application server.  Or, we may want to restrict access to a web server to only the IP address of the load balancer.  In these cases, we can use AWS Security Groups to restrict access to the resources.  Additionally, as developers, we may want to restrict access to our development environment to only our public IP address.  In this case, we can use the script in this repository to update the AWS Security Group Ingress Rules with the current public IP address of the machine running the script.

## Example Scenarios

### Hosted PBX

The phone system my family and home office use was created from an ISO and is hosted in AWS.  By default the instance has outbound access.  Inbound access should be restricted to my wife and my home office.  Our phones need to connect tothe PBX and we need to be able to reach the web interface from our home office.  However, we don't need this access from anywhere else.  Also complicating the scenario is our use of Starlink, as an ISP, and the fact that our IP address is dynmaic and can change at any tmie.  One way of tackling this is with a point-to-point VPN.  However, this is overkill for our needs.  Instead, we can use the script in this repository to update the AWS Security Group Ingress Rules with our current public IP address.  Whenever it is run, the script will determine our current public IP address and then leverage the AWS CLI to replace the existing Ingress Rules with the new IP address.

## Version History

### v001 - First Draft  

Think this was a bit too much for a simple process.  It worked, granted, kinda felt messy and quite a bit unneccesary.

### v002 - Simplify & Split  

Simplified the steps into simply, first, remove all ingress rules and, second, add my public IP to ingress rules for both TCP and UDP.

## Contact Info  

**Fred Lackey**  
[fred.lackey@gmail.com](mailto:fred.lackey@gmail.com)  
[http://fredlackey.com](http://fredlackey.com) 
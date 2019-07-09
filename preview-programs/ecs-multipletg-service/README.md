# Multiple target groups for ECS services preview!

Hello,  
  
Thank you for participating in the early access preview for multiple target group support for ECS services. This document is meant to serve as an explanation of the feature and be a guide for getting on-boarded prior to having official documentation. Please send an email to akshram@amazon.com with your AWS account ID(s) and AWS Region(s) to set up to testing of this feature.  
  
We have heard from customers of two use cases 1) A task running as a part of an ECS service to serve traffic from internal and external facing load balancers 2) A task running as a part of an ECS service that exposes multiple ports for use cases such as an application port and an administrative port. With this preview feature, customers should be able to attach multiple target groups per ECS service, allowing for multiple load balancers or multiple load balanced ports attached to an ECS service.  
  
Console support will be available when this feature is generally available. During the early access period, there will be API and AWS CloudFormation support.  
  
Before you get started please note that this feature is in preview and the intention is to ensure it meets your requirements and give us any feedback on your use case. **Please do not run production workloads till we announce the general availability of this feature. Using the instructions and assets in this repository folder is governed as a preview program under the  [AWS Service Terms](https://aws.amazon.com/service-terms/).**  
  
The rest of this document has instructions to run a sample application to test this feature.  
  
**Supported regions for the preview:**  

-   US East (N. Virginia) us-east-1
-   US East (Ohio) us-east-2
-   US West (N. California) us-west-1
-   US West (Oregon) us-west-2
-   Asia Pacific (Mumbai) ap-south-1
-   Asia Pacific (Singapore) ap-southeast-1
-   Asia Pacific (Sydney) ap-southeast-2
-   Asia Pacific (Tokyo) ap-northeast-1
-   Asia Pacific (Seoul) ap-northeast-2
-   EU (Frankfurt) eu-central-1
-   EU (Ireland) eu-west-1
-   EU (London) eu-west-2
-   EU (Paris) eu-west-3

# Setup Instructions 

For customers who are well versed with the ECS API, the following snippet shows an ECS service definition with two load balancer configurations as an example for you to get started. 
    		  
    "cluster": "multiple-tg-service-cluster",  
    "serviceName": "multiple-tg-service",  
    "taskDefinition": "multiple-tg-task-definition",  
    "desiredCount": 1,  
    "loadBalancers": [  
	    {  
	        "targetGroupArn": "<Enter Target group 1 ARN>",  
	        "containerName": "simple-app",  
	        "containerPort": <Enter port>  
	    },  
	    {  
	        "targetGroupArn": "<Enter Target group 2 ARN>",  
	        "containerName": "admin-app",  
	        "containerPort": <Enter port>  
	    }  
    ]	

A detailed step by step demo application follows. We introduce CloudFormation stacks with two use cases across Fargate and EC2 launch types:  

### Use Case 1 : An ECS/Fargate Service that serves traffic from internal and external Application Load Balancer (ALB) . The CloudFormation stack creates an ECS task definition with one NGNIX container exposing a single port 80. Then it creates an ECS service with one external ALB and one internal ALB attached to the service. Finally, the example hits the two different ALB DNS to validate the setup.

**Create Cloud formation stack to create multiple target groups Fargate launch type service**  
  
If you use the console to create CFN stack, go to CloudFormation:  

-   Go to the CloudFormation console
-   Click 'Create stack'
-   Choose the file cloud_formation_template_fargate.json from this repository folder
-   Enter stack name.
-   Select VPC, and subnet (Please only select public subnets and a minimum of 2 is required)
-   Click 'Next' and create the CFN stack
-   Wait until the cloud formation stack is successfully created

-   If your cloud formation takes more than 10 minutes to complete, you need to check your VPC settings. Ensure only use public subnets and it can access ECS endpoint.

If you know your VPC and subnet, below is the CLI command to create the stack  
  
    aws cloudformation --region us-west-2 create-stack \  
        --stack-name mtg-bugbash \  
        --template-url https://aws-ecs-multiple-target-groups.s3-us-west-2.amazonaws.com/cloud_formation_template_fargate.json \  
        --parameters ParameterKey=KeyName,ParameterValue=<Key Name> ParameterKey=VpcId,ParameterValue=<VPC ID> ParameterKey=SubnetId,ParameterValue=\"<Subnet 1>,<Subnet 2>,<Subnet 3>\"

**Grab stack output (Go to “Outputs” of the CloudFormation Stack)**  

-   External ELB DNS
-   Internal ELB DNS

**Verifying**  
  
**1. Verify ECS service start task and become steady state from ECS console.**  
  
**2. Check you can access the target behind a load balancer**  

-   `http://<EXTERNAL_ELB_LOAD_BALANCER_DNS> - Should be accessible from the browser`
-   `http://<INTERNAL_ELB_LOAD_BALANCER_DNS> - Should be accessible from only from within the VPC. You can check this by curling the URL through an EC2 instance in your VPC` 

**3. Check the target are registered in both target groups**  
  
**4. Scale down the service and verify that targets are correctly deregistered from the target groups.**  

    aws ecs --region <region>  
    update-service --service <multiple-tg-service-name> --cluster <cluster-name> --desired-count 0

**5. Delete the CloudFormation stack to cleanup**

### Use Case 2 : An ECS/EC2 service that exposes multiple ports eg. application and admin ports. The CloudFormation stack creates an ECS task definition with two NGNIX containers both exposing the port 80 as an example. Then it creates an ECS service with two ALB targets attached to the service. Finally, the example hits the two different ALB DNS to validate the setup.

**Create Cloud formation stack  **to create multiple target groups EC2 launch type service****  
  
If you use console to create CFN stack, go to CloudFormation:  

-   Go to the CloudFormation console
-   Click 'Create stack'
-   Choose the file cloud_formation_template_ec2.json from this repository folder
-   Enter stack name.
-   Select Key pair name
-   Select VPC, and subnet (Please only select public subnets and a minimum of 2 is required)
-   Click 'Next' and create the CFN stack
-   Wait until the cloud formation stack is successfully created

-   If your cloud formation takes more than 10 minutes to complete, you need to check your VPC settings. Ensure only use public subnets and it can access ECS endpoint.

  
If you know your VPC and subnet, key name, below is the CLI command to create the stack  
  

    aws cloudformation --region us-west-2 create-stack \  
        --stack-name mtg-bugbash \  
        --template-url https://aws-ecs-multiple-target-groups.s3-us-west-2.amazonaws.com/cloud_formation_template_ec2.json \  
        --parameters ParameterKey=KeyName,ParameterValue=<Key Name> ParameterKey=VpcId,ParameterValue=<VPC ID> ParameterKey=SubnetId,ParameterValue=\"<Subnet 1>,<Subnet 2>,<Subnet 3>\" \  
        --capabilities CAPABILITY_IAM

  
 
**Grab stack output (Go to “Outputs” of the CloudFormation Stack)**  

-   ELB 1 DNS
-   ELB 2 DNS

**Verifying**  
  
**1. Verify ECS service start task and become steady state from ECS console.**  
  
**2. Check you can access the both customer application and admin application. You can get the DNSs from from the CloudFormation Outputs.**  

-   `http://<ELB1_LOAD_BALANCER_DNS> - Should be accessible from your browser and be served by the first container `
-   `http://<ELB2_LOAD_BALANCER_DNS> - Should also be accessible from your browser and be served by the second container `

  
**3. Check the target are registered in both target groups**  
  
**4. Scale down the service and verify that targets are correctly deregistered from the target groups.**  

    aws ecs --region <region>  
    update-service --service <multiple-tg-service-name> --cluster <cluster-name> --desired-count 0

**5. Delete the CloudFormation stack to cleanup**  
  
  
# FAQ
  
**I am getting an error of “load balancers can have at most 1 items” when I deploy the CloudFormation stack. Why?**  
This can happen if either your account is not set up by reaching out to akshram@amazon.com or your are testing in a region that the preview is currently not supported.   
  
**How can I leave Feedback for the AWS Container Services team?**  
We would love to hear your feedback. Please add a comment on the Github [feature page](https://github.com/aws/containers-roadmap/issues/104) with a detailed description of the issue/feedback being faced.  
  
**Will this work on Fargate?**  
Yes. This feature should work with ECS Services created on both the EC2 and Fargate launch type.


# Amazon EKS EC2 ARM Instances Preview Program

Start here to participate in the EC2 ARM instance preview program for [Amazon Elastic Container Service for Kubernetes (EKS)](https://aws.amazon.com/eks). Using the instructions and code in this repository you can run docker containers using EC2 ARM instances on a Kubernetes cluster that is managed by Amazon EKS.

**Note:** The assets and instructions in this repository folder are offered as part of a _public preview_ program administered by AWS.

Using the instructions and assets in this repository folder is governed as a preview program under the [AWS Service Terms](https://aws.amazon.com/service-terms/).

#### Contents
* [Before you begin](#before-you-begin)
* [Key resources](#key-resources)
* [Instructions](#instructions)

#### Leaving feedback and getting help
* The assets and instructions in this repository are offered on an _as-is_ basis as part of a public preview program for new AWS service functionality.
* Leave comments or questions on our [GitHub issue](https://github.com/aws/containers-roadmap/issues/xx).
* To send more detailed problem information or feedback directly to the EKS Windows preview team, email [eks-arm-preview@amazon.com](mailto:eks-arm-preview@amazon.com). _(Please give 24-48 hours for a reply.)_
* For issues with the Amazon EKS service (creating, modifying, deleting a cluster) or with your AWS account, please contact AWS support using the AWS console.

## Before you begin
* Make sure you have an active and valid AWS account. If you don't, you can create one [here](https://portal.aws.amazon.com/gp/aws/developer/registration/index.html).
* If you haven't used Kubernetes before, familiarize yourself with the [basics of Kubernetes](https://kubernetes.io/docs/concepts/)
* If you haven't used Amazon EKS before, familiarize yourself with the [EKS user guide](https://docs.aws.amazon.com/eks/latest/userguide/what-is-eks.html). We also have a [tutorial](https://eksworkshop.com) that is a good starting point for new users.

**Important Considerations for ARM nodes**
* TBD

## Key Resources
The specific resources you need to run containers on ARM EC2 instances with Amazon EKS are within this repository folder. All other resources needed to successfully start and manage an EKS cluster can be found within the [EKS user guide](https://docs.aws.amazon.com/eks/latest/userguide/what-is-eks.html).

### Latest EKS Windows AMIs

**Kubernetes 1.11**

*AMI Name: Windows_Server-2019-English-{Full / Core}-Containers-EKS*

**Note**: Windows Full AMI is the full Windows Server. Windows Core AMI is the smaller AMI that only includes components necessary to run containers. You can use either version as part of this guide.

|  Region         | EKS Optimized AMI ID |                                        
| --------------- | ---------------------------------------------  |
| us-west-2       |           ami-047f9f0be88cb9b8b		|
| us-west-1       |           ami-0dca600383dc83e8e           |



## Instructions
Follow these instructions to create a Kubernetes cluster with Amazon EKS and start a service on EC2 ARM nodes.

**Note**: This guide requires that you create a new EKS cluster. Please ensure you complete all steps to avoid issues.

### Step 1. Install and Configure kubectl for Amazon EKS
Refer to the Amazon EKS [getting started guide prerequisites](https://docs.aws.amazon.com/eks/latest/userguide/getting-started.html#eks-prereqs).

### Step 2. Create Your VPC, IAM Role, Amazon EKS Cluster & Worker nodes
1. Open the AWS CloudFormation console at [https://console.aws.amazon.com/cloudformation](https://console.aws.amazon.com/cloudformation/home).
2. From the navigation bar, select an AWS region where Amazon EKS is available.
3. Upload the template

### Step 3. Launch an app
1. Start the app
2. See the app

## Next steps

* Run your own containers on your new EKS cluster.

* Leave comments or questions on our [GitHub issue](https://github.com/aws/containers-roadmap/issues/69).

* To send more detailed problem information or feedback directly to the EKS preview team, email [eks-arm-preview@amazon.com](mailto:eks-arm-preview@amazon.com). _(Please give 24-48 hours for a reply.)_

* This is an evolving project. As we roll out new features and functionality, we will update this repository and the roadmap issue.
# Amazon EKS A1 Instances Preview Program

Start here to participate in the Amazon EC2 A1 instance preview program for [Amazon Elastic Container Service for Kubernetes (EKS)](https://aws.amazon.com/eks). Using the instructions and code in this repository you can run containers using [EC2 A1 instances](https://aws.amazon.com/ec2/instance-types/a1) on a Kubernetes cluster that is managed by Amazon EKS.

[Amazon EC2 A1 instances](https://aws.amazon.com/ec2/instance-types/a1) deliver significant cost savings for scale-out and Arm-based applications such as web servers, containerized microservices, caching fleets, and distributed data stores.

**Note:** The assets and instructions in this repository folder are offered as part of a _public preview_ program administered by AWS.

Using the instructions and assets in this repository folder is governed as a preview program under the [AWS Service Terms](https://aws.amazon.com/service-terms/).

#### Contents
* [Before you begin](#before-you-begin)
* [Key resources](#key-resources)
* [Instructions](#instructions)

#### Leaving feedback and getting help
* The assets and instructions in this repository are offered on an _as-is_ basis as part of a public preview program for new AWS service functionality.
* Leave comments or questions on our [GitHub issue](https://github.com/aws/containers-roadmap/issues/264).
* To send more detailed problem information or feedback directly to the EKS Windows preview team, email [eks-a1-preview@amazon.com](mailto:eks-a1-preview@amazon.com). _(Please give 24-48 hours for a reply.)_
* For issues with the Amazon EKS service (creating, modifying, deleting a cluster) or with your AWS account, please contact AWS support using the AWS console.

## Before you begin
* Make sure you have an active and valid AWS account. If you don't, you can create one [here](https://portal.aws.amazon.com/gp/aws/developer/registration/index.html).
* If you haven't used Kubernetes before, familiarize yourself with the [basics of Kubernetes](https://kubernetes.io/docs/concepts/)
* If you haven't used Amazon EKS before, familiarize yourself with the [EKS user guide](https://docs.aws.amazon.com/eks/latest/userguide/what-is-eks.html). We also have a [tutorial](https://eksworkshop.com) that is a good starting point for new users.

**Important Considerations for ARM nodes**
* EKS currently supports running A1 instances with Kubernetes version 1.12 only
* VPC resource controller and coredns will be running in x86_64 node

## Key Resources
The specific resources you need to run containers on EC2 A1 instances with Amazon EKS are within this repository folder. All other resources needed to successfully start and manage an EKS cluster can be found within the [EKS user guide](https://docs.aws.amazon.com/eks/latest/userguide/what-is-eks.html).

### Latest EKS A1 AMIs

**Kubernetes 1.12**

|  Region         | EKS Optimized AMI ID  |                                        
| --------------- | --------------------  |
| ap-northeast-1 	| ami-0a42ad9c1fe6baea0 |
| ap-northeast-2 	| ami-095f645bf91f3c86d |
| p-south-1       | ami-0e2a734b3e8ddcc02 |
| ap-southeast-1  | ami-04bdd6a19a2b7f5f9 |
| ap-southeast-2  | ami-07913747b3a60dc99 |
| ca-central-1    | ami-08fed1c771f5f08e2 |
| eu-central-1 	  | ami-083f7885e39e64013 |
| eu-north-1   	  | ami-0dc496f6339c15efb |
| eu-west-1    	  | ami-0d4aed258d782efc4 |
| eu-west-2    	  | ami-019917add06c6e302 |
| eu-west-3      	| ami-09e44f67871ddc702 |
| sa-east-1       | ami-0d9650de0ddb605b7 |
| us-east-1    	  | ami-01b50e73cd22564a2 |
| us-east-2    	  | ami-0b77c47c7966395a6 |
| us-west-1    	  | ami-011edf0d0b571fe0c |
| us-west-2    	  | ami-032f6f730a078ac1d |


## Instructions
Follow these instructions to create a Kubernetes cluster with Amazon EKS and start a service on EC2 A1 nodes.

**Note**: This guide requires that you create a new EKS cluster. Please ensure you complete all steps to avoid issues.

### Step 1. Install eksctl, the EKS command line tool
1. Ensure you have the latest version of [Homebrew](https://brew.sh/) installed.
If you don't have Homebrew, you can install it with the command: `/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"`
2. Install the Weaveworks Homebrew tap: `brew tap weaveworks/tap`
3. Install ekstctl: `brew install weaveworks/tap/eksctl`
4. Test that your installation was successful: `eksctl --help`

### Step 2. Install kubectl and AWS IAM authenticator
If you used the Homebrew instructions above to install eksctl on macOS, then kubectl and the aws-iam-authenticator have already been installed on your system. Otherwise, you can refer to the Amazon EKS [getting started guide prerequisites](https://docs.aws.amazon.com/eks/latest/userguide/getting-started.html#eks-prereqs).

### Step 3. Create Your VPC, IAM role, and Amazon EKS Cluster with a single linux worker node
Create an EKS cluster with a single linux worker node using the following eksctl command:

```
eksctl create cluster \
--name a1-preview \
--version 1.12 \
--nodegroup-name standard-workers \
--node-type t3.medium \
--nodes 1 \
--nodes-min 1 \
--nodes-max 1 \
--node-ami auto
```

This process typically takes 10-15 minutes. You can monitor the progress in the [EKS console](https://console.aws.amazon.com/eks).

Test that your cluster is running using `kubectl get svc`.

### Step 4. Deploy ARM CNI Plugin
1. Check that your Linux worker node joined the cluster: `kubectl get nodes`
2. Deploy the vpc-resource-controller: `kubectl apply -f https://raw.githubusercontent.com/aws/containers-roadmap/master/preview-programs/eks-ec2-a1-preview/aws-k8s-cni-arm64.yaml`

### Step 5. Launch and Configure Amazon EKS ARM Worker Nodes
1. Choose the correct AMI ID for your region from the [AMI table](#latest-eks-a1-amis)
2. Create a nodegroup using EKSctl for your A1 AMIs, be sure to fill in your AMI ID.

```
eksctl create nodegroup --cluster a1-preview \
--name a1-nodes
--node-type a1.medium \
--nodes 3 \
--nodes-min 1 \
--nodes-max 4 \
--node-ami <ami-id>
--BootstrapArguments --pause-container-account 940911992744
```

3. Record the **NodeInstanceRole** for your node group.

### Step 6. Configure the AWS authenticator configuration map to enable worker nodes to join your cluster
1. Download the configuration map
`wget https://raw.githubusercontent.com/aws/containers-roadmap/master/preview-programs/eks-ec2-a1-preview/aws-auth-cm-arm64.yaml`

2. Open the file with your favorite text editor. Replace the _<ARN of instance role (not instance profile)>_ snippet with the **NodeInstanceRole** value that you recorded in the previous procedure, and save the file.

**Important**: Do not modify any other lines in this file.

```
apiVersion: v1
kind: ConfigMap
metadata:  
  name: aws-auth  
  namespace: kube-system
data:  
  mapRoles: |  
    - rolearn: <ARN of instance role (not instance profile) of **linux** node>
      username: system:node:{{EC2PrivateDNSName}}
      groups:
        - system:bootstrappers
        - system:nodes
```

3. Apply the configuration. This command may take a few minutes to finish: `kubectl apply -f aws-auth-cm-arm64.yaml`

**Note**: If you receive the error `"aws-iam-authenticator": executable file not found in PATH`, then **kubectl** on your machine is not configured correctly for Amazon EKS. For more information, see [Installing aws-iam-authenticator](https://docs.aws.amazon.com/eks/latest/userguide/install-aws-iam-authenticator.html).

If you receive any other authorization or resource type errors, see [Unauthorized or Access Denied (kubectl)](https://docs.aws.amazon.com/eks/latest/userguide/troubleshooting.html#unauthorized).

4. Watch the status of your nodes and wait for them to reach the **Ready** status: `kubectl get nodes --watch`

### Step 7. Launch an app
Launch the demo Guest Book application from the [EKS Getting Started Guide](https://docs.aws.amazon.com/eks/latest/userguide/getting-started.html)

1. Create the Redis master replication controller.

## Next steps

* Run your own containers on your new EKS cluster.

* Leave comments or questions on our [GitHub issue](https://github.com/aws/containers-roadmap/issues/69).

* To send more detailed problem information or feedback directly to the EKS preview team, email [eks-a1-preview@amazon.com](mailto:eks-a1-preview@amazon.com). _(Please give 24-48 hours for a reply.)_

* This is an evolving project. As we roll out new features and functionality, we will update this repository and the roadmap issue.

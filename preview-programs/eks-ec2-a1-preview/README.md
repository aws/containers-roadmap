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
* For issues with the Amazon EKS service (creating, modifying, deleting a cluster) or with your AWS account, please contact AWS support using the AWS console.

## Before you begin
* Make sure you have an active and valid AWS account. If you don't, you can create one [here](https://portal.aws.amazon.com/gp/aws/developer/registration/index.html).
* If you haven't used Kubernetes before, familiarize yourself with the [basics of Kubernetes](https://kubernetes.io/docs/concepts/)
* If you haven't used Amazon EKS before, familiarize yourself with the [EKS user guide](https://docs.aws.amazon.com/eks/latest/userguide/what-is-eks.html). We also have a [tutorial](https://eksworkshop.com) that is a good starting point for new users.

**Important Considerations for ARM nodes**
* EKS currently supports running A1 instances with Kubernetes version 1.12 only
* EC2 A1 instances are not available in all AWS regions. See the [AWS website for region availability](https://aws.amazon.com/about-aws/global-infrastructure/regional-product-services/). You must create your cluster in one of the regions listed below.
* VPC resource controller and coredns will be running in x86_64 node

## Key Resources
The specific resources you need to run containers on EC2 A1 instances with Amazon EKS are within this repository folder. All other resources needed to successfully start and manage an EKS cluster can be found within the [EKS user guide](https://docs.aws.amazon.com/eks/latest/userguide/what-is-eks.html).

### Latest EKS A1 AMIs

**Kubernetes 1.12**

|  Region         | EKS Optimized AMI ID  |                                        
| --------------- | --------------------  |
| eu-west-1    	  | ami-0d4aed258d782efc4 |
| us-east-1    	  | ami-01b50e73cd22564a2 |
| us-east-2    	  | ami-0b77c47c7966395a6 |
| us-west-2    	  | ami-032f6f730a078ac1d |


## Instructions
Follow these instructions to create a Kubernetes cluster with Amazon EKS and start a service on EC2 A1 nodes.

**Note**: This guide requires that you create a new EKS cluster. Please ensure you complete all steps to avoid issues.

### Step 1. Install eksctl, the EKS command line tool
To create our cluster, we will use [eksctl](https://eksctl.io/), a command line tool for EKS.

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
--region <eu-west-1, us-east-1, us-east-2, us-west-2> \
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
1. Open the AWS CloudFormation console at https://console.aws.amazon.com/cloudformation. Ensure that you are in the AWS region that you created your EKS cluster in.
2. Choose **Create stack**.
3. For **Choose a template**, select **Specify an Amazon S3 template URL**.
4. Paste the following URL into the text area and choose **Next**
`https://s3-us-west-2.amazonaws.com/amazon-eks-arm-beta/templates/latest/amazon-eks-arm-nodegroup.yaml`
5. On the Specify Details page, fill out the following parameters accordingly, and choose **Next**.
  * **Stack name**: Choose a stack name for your AWS CloudFormation stack. For example, you can call it <cluster-name>-worker-nodes.
  * **ClusterName**: Enter the name that you used when you created your Amazon EKS cluster.
    **Important**
    This name must exactly match the name you used in Step 1: Create Your Amazon EKS Cluster; otherwise, your worker nodes cannot join the cluster.
  * **ClusterControlPlaneSecurityGroup**: Choose the SecurityGroups value from the AWS CloudFormation output that you generated with Create your Amazon EKS Cluster VPC.
  * **NodeGroupName**: Enter a name for your node group. This name can be used later to identify the Auto Scaling node group that is created for your worker nodes.
  * **NodeAutoScalingGroupMinSize**: Enter the minimum number of nodes that your worker node Auto Scaling group can scale in to.
  * **NodeAutoScalingGroupDesiredCapacity**: Enter the desired number of nodes to scale to when your stack is created.
  * **NodeAutoScalingGroupMaxSize**: Enter the maximum number of nodes that your worker node Auto Scaling group can scale out to.
  * **NodeInstanceType**: Choose an instance type for your worker nodes.
  * **NodeImageId**: Enter the current Amazon EKS worker node AMI ID for your region from the [AMI table](#latest-eks-a1-amis).
  * **BootstrapArguments**: --pause-container-account 940911992744
  * **KeyName**: Enter the name of an Amazon EC2 key pair that you can use to decrypt administrator password while RDP into your worker nodes after they launch. If you don't already have an Amazon EC2 keypair, you can create one in the AWS Management Console. For more information, see Amazon EC2 Key Pairs in the Amazon EC2 User Guide for Linux Instances.

  **Note**: If you do not provide a keypair here, the AWS CloudFormation stack creation fails.

  * **VpcId**: Enter the ID for the VPC that you created in Create your Amazon EKS Cluster VPC.
  * **Subnets**: Choose the subnets that you created in Create your Amazon EKS Cluster VPC.
  * **NodeSecurityGroup**: Choose the security group that your linux node is part of.

6. On the **Options** page, you can choose to tag your stack resources. Choose **Next**.
7. On the **Review** page, review your information, acknowledge that the stack might create IAM resources, and then choose **Create**.
8. When your stack has finished creating, select it in the console and choose the **Outputs** tab.
9. Record the **NodeInstanceRole** for the node group that was created. You need this when you configure your Amazon EKS worker nodes.

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
`kubectl apply -f https://raw.githubusercontent.com/kubernetes/examples/master/guestbook-go/redis-master-controller.json`

 * Output:
 `replicationcontroller "redis-master" created`

2. Create the Redis master service.
`kubectl apply -f https://raw.githubusercontent.com/kubernetes/examples/master/guestbook-go/redis-master-service.json`

 * Output:
 `service "redis-master" created`

3. Create the Redis slave replication controller.
`kubectl apply -f https://raw.githubusercontent.com/kubernetes/examples/master/guestbook-go/redis-slave-controller.json`

 * Output:
 `replicationcontroller "redis-slave" created`

4. Create the Redis slave service.
`kubectl apply -f https://raw.githubusercontent.com/kubernetes/examples/master/guestbook-go/redis-slave-service.json`

 * Output:
 `service "redis-slave" created`

5. Create the guestbook replication controller.
`kubectl apply -f https://raw.githubusercontent.com/kubernetes/examples/master/guestbook-go/guestbook-controller.json`

 * Output:
 `replicationcontroller "guestbook" created`

6. Create the guestbook service.
`kubectl apply -f https://raw.githubusercontent.com/kubernetes/examples/master/guestbook-go/guestbook-service.json`

 * Output:
 `service "guestbook" created`

7. Query the services in your cluster and wait until the External IP column for the guestbook service is populated.

 * **Note**: It may take several minutes before the IP address is available.
 * `kubectl get services -o wide`

After your external IP address is available, point a web browser to that address at port 3000 to view your guest book.
For example, http://a7a95c2b9e69711e7b1a3022fdcfdf2e-1985673473.us-west-2.elb.amazonaws.com:3000

**Note**: It may take several minutes for DNS to propagate and for your guest book to show up.

## Next steps

* Run your own containers on your new EKS cluster.

* Leave comments or questions on our [GitHub issue](https://github.com/aws/containers-roadmap/issues/264).

* This is an evolving project. As we roll out new features and functionality, we will update this repository and the roadmap issue.

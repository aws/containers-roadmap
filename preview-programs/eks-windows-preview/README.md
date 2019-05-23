# Amazon EKS Windows Preview Program
Start here to participate in the Windows node preview program for [Amazon Elastic Container Service for Kubernetes (EKS)](https://aws.amazon.com/eks). Using the instructions and code in this repository you can run Windows server docker containers on a Kubernetes cluster that is managed by Amazon EKS.

**Note:** The assets and instructions in this repository folder are offered as part of a _public preview_ program administered by AWS.

Using the instructions and assets in this repository folder as well as running Windows Server EC2 instances (worker nodes) with Amazon EKS is governed as a preview program under the [AWS Service Terms](https://aws.amazon.com/service-terms/).

#### Contents
* [Before you begin](#before-you-begin)
* [Key resources](#key-resources)
* [Instructions](#instructions)

#### Leaving feedback and getting help
* The assets and instructions in this repository are offered on an _as-is_ basis as part of a public preview program for new AWS service functionality.
* Leave comments or questions on our [GitHub issue](https://github.com/aws/containers-roadmap/issues/69).
* To send more detailed problem information or feedback directly to the EKS Windows preview team, email [eks-windows-preview@amazon.com](mailto:eks-windows-preview@amazon.com). _(Please give 24-48 hours for a reply.)_
* For issues with the Amazon EKS service (creating, modifying, deleting a cluster) or with your AWS account, please contact AWS support using the AWS console.

## Before you begin
* Make sure you have an active and valid AWS account. If you don't, you can create one [here](https://portal.aws.amazon.com/gp/aws/developer/registration/index.html).
* If you haven't used Kubernetes before, familiarize yourself with the [basics of Kubernetes](https://kubernetes.io/docs/concepts/)
* If you haven't used Amazon EKS before, familiarize yourself with the [EKS user guide](https://docs.aws.amazon.com/eks/latest/userguide/what-is-eks.html). We also have a [tutorial](https://eksworkshop.com) that is a good starting point for new users.

**Important Considerations for Windows nodes**
* EKS Windows nodes are only supported by Kubernetes version 1.11 (1.10 is not supported).
* Windows EC2 instance types C3, C4, D2, I2, M4 (excluding m4.16xlarge), and R3 instances are **not supported**.
* Microsoft doesn't support hostnetworking mode in Windows yet. Hence an EKS Windows cluster will be a mixed mode cluster (1 Linux node and 3+ Windows nodes).
* The VPC resource controller and coredns will be running in linux node.
* Kubelet and kube-proxy event logs are redirected to Windows Event log (Log : EKS) and is set to 200 MB limit.
* There is no support for secondary CIDR blocks with Windows nodes.
* Workloads must have valid node selectors:

```
# Windows specific targeting
nodeSelector:
        beta.kubernetes.io/os: windows
        beta.kubernetes.io/arch: amd64

# Linux specific targeting
nodeSelector:
        beta.kubernetes.io/os: linux
        beta.kubernetes.io/arch: amd64
```

Occasionally, when a node leaves and rejoins the cluster, the vpc-resource-controller is not notified. This results in the node not advertising the correct capacity. To workaround this issue, simply delete the "vpc-resource-controller" pod.

## Key Resources
The specific resources you need to run Windows containers with Amazon EKS are within this repository folder. All other resources needed to successfully start and manage an EKS cluster can be found within the [EKS user guide](https://docs.aws.amazon.com/eks/latest/userguide/what-is-eks.html).

### Latest EKS Windows AMIs

**Kubernetes 1.11**

*AMI Name: Windows_Server-2019-English-{Full / Core}-Containers-EKS*

**Note**: Windows Full AMI is the full Windows Server. Windows Core AMI is the smaller AMI that only includes components necessary to run containers. You can use either version as part of this guide.

|  Region         | Server-2019-Engligh-Full-Container-EKS AMI ID | Server-2019-Engligh-Core-Container-EKS AMI ID  |                                        
| --------------- | --------------------------------------------- | ---------------------------------------------- |
| us-west-2       |           ami-047f9f0be88cb9b8b               |              ami-0244aa185d17572b8             |
| us-west-1       |           ami-0dca600383dc83e8e               |              ami-04a97de1d98e226fe             |
| us-east-2       |           ami-0d25014b4e2b56ef0               |              ami-0134b9dc88d95105e             |
| us-east-1       |           ami-0d4ec559ed3b0a03d               |              ami-032bdf5292844295a             |
| sa-east-1       |           ami-0762395a2c696beba               |              ami-099df69dcf073a3fd             |
| eu-west-3       |           ami-005543548e9d4126a               |              ami-0b0a0aba0d6f5bccb             |
| eu-west-2       |           ami-0a9fb38fe97a64b6e               |              ami-0f6c6e5d4e4d01c64             |
| eu-west-1       |           ami-07ffb428f41e17b71               |              ami-0cd07b7c0ae250af0             |
| eu-north-1      |           ami-03bcc606bf2df8d2d               |              ami-074e35c9d14b11091             |
| eu-central-1    |           ami-0c60c20c5f3e73d04               |              ami-07cefde331d18762e             |
| ca-central-1    |           ami-090a238aa660f6f1e               |              ami-0050e658348c3a4cb             |
| ap-southeast-2  |           ami-058bed43fa0d7e6e8               |              ami-074fab9fc535c1f82             |
| ap-southeast-1  |           ami-0fefd03bb8473f13a               |              ami-0e0327c40f458981e             |
| ap-south-1      |           ami-0c5caa6c28ed258ed               |              ami-050cbb5254365fdaf             |
| ap-northeast-2  |           ami-00f43a9a837b9d1e3               |              ami-0fbb7a510d13e0c14             |
| ap-northeast-1  |           ami-0c4de1c5133449009               |              ami-01e36132b6e450597             |


## Instructions
Follow these instructions to create a Kubernetes cluster with Amazon EKS and start a service using Windows server Docker containers.

**Note**: This guide requires that you create a new EKS cluster. Please ensure you complete all steps to avoid issues.

### Step 1. Install and Configure kubectl for Amazon EKS
Refer to the Amazon EKS [getting started guide prerequisites](https://docs.aws.amazon.com/eks/latest/userguide/getting-started.html#eks-prereqs).

### Step 2. Create Your VPC, IAM Role, Amazon EKS Cluster & Worker nodes
1. Open the AWS CloudFormation console at [https://console.aws.amazon.com/cloudformation](https://console.aws.amazon.com/cloudformation/home).
2. From the navigation bar, select an AWS region where Amazon EKS is available.

**Note**
The Amazon EKS Windows preview works in [all regions where Amazon EKS is available](https://aws.amazon.com/about-aws/global-infrastructure/regional-product-services/).

3. Choose Create stack.
4. For Choose a template, select use an Amazon S3 URL and add the QuickStart YAML file: `https://amazon-eks.s3-us-west-2.amazonaws.com/cloudformation/windows-public-preview/amazon-eks-cfn-quickstart-windows.yaml`.
11. On the **Specify Details** page, fill out the parameters accordingly, and then choose **Next**.

    * **Stack name**: Choose a stack name for your AWS CloudFormation stack. For example, you can call it `eks-vpc`.
    * **ClusterName**: Enter the name that you want to use for your Amazon EKS cluster.
    * **KeyName**: Enter the name of an Amazon EC2 SSH key pair that you can use to connect using SSH / RDP into your worker nodes with after they launch. If you don't already have an Amazon EC2 keypair, you can create one in the AWS Management Console. For more information, see [Amazon EC2 Key Pairs](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html).

    **Note**
    If you do not provide a keypair, the AWS CloudFormation stack creation will fail.

    * **LinuxNodeImageId**: Enter the current Amazon EKS Linux worker node AMI ID for your Region. The AMI IDs for the latest Amazon EKS-optimized AMI are shown [here](https://docs.aws.amazon.com/eks/latest/userguide/eks-optimized-ami.html) (Refer to Kubernetes version 1.11).
    * **WindowsNodeAutoScalingGroupDesiredCapacity**: Enter the desired number of nodes to scale to when your stack is created.
    * **WindowsNodeAutoScalingGroupMaxSize**: Enter the maximum number of nodes that your worker node Auto Scaling group can scale out to.
    * **WindowsNodeAutoScalingGroupMinSize**: Enter the minimum number of nodes that your worker node Auto Scaling group can scale in to.
    * **WindowsNodeImageId**: Enter the latest [Amazon EKS Windows worker node AMI ID](#latest-eks-windows-amis) for your Region.
    * **WindowsNodeInstanceType**: Choose an instance type for your worker nodes (see [Before you begin](#before-you-begin)).

12. (Optional) On the **Options** page, tag your stack resources. Choose **Next**.
13. On the **Review** page, choose **Create**.
14. When your stack is created, select it in the console and choose **Outputs**.
15. Record the `LinuxNodeInstanceRole` and `WindowsNodeInstanceRole` values for the node instance roles that were created. You need this when you configure your Amazon EKS worker nodes.

### Step 3. Deploy VPC Resource controller & kube-proxy-windows-cluster-role-binding
1. Download cluster addons file locally

`curl -o eks-clusteraddons-quickstart-windows.yaml https://raw.githubusercontent.com/aws/containers-roadmap/master/preview-programs/eks-windows-preview/eks-clusteraddons-quickstart-windows.yaml`

2. Deploy the cluster addons

`kubectl apply -f eks-clusteraddons-quickstart-windows.yaml`

### Step 4. Deploy the VPC admission webhook
1. Install **openssl** and **jq**
   * openssl (https://github.com/openssl/openssl/releases)
   * jq (https://github.com/stedolan/jq/wiki/Installation)
2. Setup the vpc admission webhook
   * Download the required scripts and deployment files
```
   curl -o webhook-create-signed-cert.sh https://raw.githubusercontent.com/aws/containers-roadmap/preview-programs/eks-windows-preview/webhook-create-signed-cert.sh
   curl -o webhook-patch-ca-bundle.sh https://raw.githubusercontent.com/aws/containers-roadmap/preview-programs/eks-windows-preview/webhook-patch-ca-bundle.sh
   curl -o vpc-admission-webhook-deployment.yaml https://raw.githubusercontent.com/aws/containers-roadmap/preview-programs/eks-windows-preview/vpc-admission-webhook-deployment.yaml

   chmod +x webhook-create-signed-cert.sh
   chmod +x webhook-patch-ca-bundle.sh
```
   
   * Setup secret for secure communication

    `./webhook-create-signed-cert.sh`

   * Verify secret

    `kubectl get secret vpc-admission-webhook-certs`

   * Configure webhook and create deployment file

    `cat ./vpc-admission-webhook-deployment.yaml| ./webhook-patch-ca-bundle.sh > vpc-admission-webhook.yaml`

3. Deploy the vpc-admission-webhook

    `kubectl apply -f vpc-admission-webhook.yaml`

### 5. Enable worker nodes to join the cluster
1. Download, edit, and apply the AWS authenticator configuration map
   * Download the configuration map

   `curl -o aws-auth-cm-windows.yaml https://raw.githubusercontent.com/aws/containers-roadmap/master/preview-programs/eks-windows-preview/aws-auth-cm-windows.yaml`

   * Open the file with your favorite text editor. Replace the <ARN of instance role (not instance profile)> snippet with the **NodeInstanceRole** value that you recorded in the previous procedure, and save the file.

   **Important:** Do not modify any other lines in this file.

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
    - rolearn: <ARN of instance role (not instance profile) of **windows** node>  
      username: system:node:{{EC2PrivateDNSName}}  
      groups:  
        - system:bootstrappers  
        - system:nodes
        - eks:kube-proxy-windows
```

   * Apply the configuration. This command may take a few minutes to finish.

   `kubectl apply -f aws-auth-cm-windows.yaml`

   **Note:** If you receive the error "aws-iam-authenticator": executable file not found in PATH, then **kubectl** is not configured for your Amazon EKS cluster. For more information, see [Installing aws-iam-authenticator](https://docs.aws.amazon.com/eks/latest/userguide/install-aws-iam-authenticator.html).

2. Watch the status of your nodes and wait for them to reach the Ready status

`kubectl get nodes --watch`

Your cluster and workers are ready. You can launch a Windows webserver application to test your setup.

### 6. Launch a Windows webserver application

Watch the status of your nodes and wait for them to reach the Ready status. Then download the sample application from this GitHub repository.

`curl -o windows-server-iis.yaml https://raw.githubusercontent.com/aws/containers-roadmap/master/preview-programs/eks-windows-preview/windows-server-IIS.yaml`

`kubectl apply -f windows-server-iis.yaml`

`kubectl get pods -w`

Watch for the pod to transition to "RUNNING" state. Then check pod details.

`kubectl get services`

Note down the External-IP and wait for few min. to propagate DNS record.

In browser, access `http://<<ExternalIP of windows-server-iis-service>>/default.html`

## Next steps

* Run your own Windows containers on your new EKS cluster.

* Leave comments or questions on our [GitHub issue](https://github.com/aws/containers-roadmap/issues/69).

* To send more detailed problem information or feedback directly to the EKS Windows preview team, email [eks-windows-preview@amazon.com](mailto:eks-windows-preview@amazon.com). _(Please give 24-48 hours for a reply.)_

* This is an evolving project. As we roll out new features and functionality, we will update this repository and the roadmap issue.

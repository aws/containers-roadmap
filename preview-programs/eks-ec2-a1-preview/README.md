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
* EKS currently supports the ability to run all nodes on A1 instances with Kubernetes version 1.13 and 1.14.
* The preview is only available in us-west-2. You must create your EKS cluster in this region.

## Key Resources
The specific resources you need to run containers on EC2 A1 instances with Amazon EKS are within this repository folder. All other resources needed to successfully start and manage an EKS cluster can be found within the [EKS user guide](https://docs.aws.amazon.com/eks/latest/userguide/what-is-eks.html).

### Latest EKS A1 AMIs

|  Region         | Kubernetes Version    | EKS Optimized AMI ID  |                                        
| --------------- | --------------------- | --------------------- |
| us-west-2    	  | 1.13                  | ami-004a838b8dd73e3d4 |
| us-west-2       | 1.14                  | ami-0f1e49dadf307aa92 |

## Instructions
Follow these instructions to create a Kubernetes cluster with Amazon EKS and start a service on EC2 A1 nodes.

**Note**: This guide requires that you create a new EKS cluster. Please ensure you complete all steps to avoid issues.

### **Step 1.** Install eksctl, the EKS command line tool
To create our cluster, we will use [eksctl](https://eksctl.io/), the command line tool for EKS.

1. Ensure you have the latest version of [Homebrew](https://brew.sh/) installed.
If you don't have Homebrew, you can install it with the command: `/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"`
2. Install the Weaveworks Homebrew tap: `brew tap weaveworks/tap`
3. Install ekstctl: `brew install weaveworks/tap/eksctl`
4. Test that your installation was successful: `eksctl --help`

### **Step 2.** Install kubectl and AWS IAM authenticator
If you used the Homebrew instructions above to install eksctl on macOS, then kubectl and the aws-iam-authenticator have already been installed on your system. Otherwise, you can refer to the Amazon EKS [getting started guide prerequisites](https://docs.aws.amazon.com/eks/latest/userguide/getting-started.html#eks-prereqs).

### **Step 3.** Create Your VPC, IAM role, and Amazon EKS Cluster without worker nodes
Create an EKS cluster without provisioning worker nodes using the following eksctl command, choosing the version of Kubernetes you would like to use:

```
eksctl create cluster \
--name a1-preview \
--version << Choose 1.13 or 1.14 >> \
--region us-west-2 \
--without-nodegroup
```

Launching an EKS cluster using eksctl creates a CloudFormation stack. The launch process for this stack typically takes 10-15 minutes. You can monitor the progress in the [EKS console](https://console.aws.amazon.com/eks).

Once the launch process has completed, we will want to review the CloudFormation stack to record the IDs of the Control Plane security group as well as the VPC ID. Navigate to the [CloudFormation console](https://console.aws.amazon.com/cloudformation). You will see a stack named `eksctl-<cluster name>-cluster`. Select this stack, and on the right-hand side panel, click the tab for `Outputs`. Record the values of the items for `SecurityGroup` and `VPC`.

Test that your cluster is running using `kubectl get svc`. It should return information such as the following:

```
NAME         TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)   AGE
kubernetes   ClusterIP   ww.xx.yy.zz      <none>        443/TCP   20m
```

In order to support having only A1 nodes on our EKS cluster, we need to update some of the Kubernetes components. Follow the steps below to update CoreDNS, Kube-Proxy, and install the AWS ARM64 CNI plugin.

### **Step 4.** Update the image ID used for CoreDNS
Run one of the below commands based upon the version of Kubernetes you are using to install an updated version of `CoreDNS`:

**Kubernetes 1.13**
```shell
kubectl set image -n kube-system deployment.apps/coredns \
coredns=602401143452.dkr.ecr.us-west-2.amazonaws.com/eks/coredns-arm64:v1.2.6
```

**Kubernetes 1.14**
```shell
kubectl set image -n kube-system deployment.apps/coredns \
coredns=602401143452.dkr.ecr.us-west-2.amazonaws.com/eks/coredns-arm64:v1.3.1
```

### **Step 5.** Update the image ID used for kube-proxy
Run the below command based upon the version of Kubernetes you are using to install an updated version of `kube-proxy`:

**Kubernetes 1.13**
```shell
kubectl set image -n kube-system daemonset.apps/kube-proxy \
kube-proxy=602401143452.dkr.ecr.us-west-2.amazonaws.com/eks/kube-proxy-arm64:v1.13.10
```

**Kubernetes 1.14**
```shell
kubectl set image -n kube-system daemonset.apps/kube-proxy \
kube-proxy=602401143452.dkr.ecr.us-west-2.amazonaws.com/eks/kube-proxy-arm64:v1.14.7
```

### *Step 6.* Deploy the ARM CNI Plugin
Run the below command to install the AWS ARM64 CNI Plugin (this command will work for both 1.13 as well as 1.14):

```shell
kubectl apply -f https://raw.githubusercontent.com/aws/containers-roadmap/master/preview-programs/eks-ec2-a1-preview/aws-k8s-cni-arm64.yaml
```

### **Step 7.** Update the node affinity of kube-proxy and CoreDNS
Before we launch our A1 instances, we will need to update the node affinity of kube-proxy and CoreDNS. 
After running each of the commands below, an editor will open (e.g.: vi for Linux or MacOS clients, notepad for Windows 
clients). Once the editor has opened, scroll down to the bottom of the file to where the node affinity is defined. 
In each case, update the value of `amd64` to `arm64` (see example below):

**Example: Updating the affinity for kube-proxy**
```
...
spec:
  revisionHistoryLimit: 10
  selector:
    matchLabels:
      k8s-app: kube-proxy
  template:
    metadata:
      creationTimestamp: null
      labels:
        k8s-app: kube-proxy
    spec:
      affinity:
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: kubernetes.io/os
                operator: In
                values:
                - linux
              - key: kubernetes.io/arch
                operator: In
                values:
                - amd64 <-- change to arm64
...
```

```shell
kubectl -n kube-system edit ds kube-proxy
kubectl -n kube-system edit deployment coredns
```

### *Step 8.* Launch and Configure Amazon EKS ARM Worker Nodes
1. Open the AWS CloudFormation console at https://console.aws.amazon.com/cloudformation. Ensure that you are in the AWS 
region that you created your EKS cluster in.
2. Choose **Create stack**.
3. For **Choose a template**, select **Specify an Amazon S3 template URL**.
4. Paste the following URL into the text area and choose **Next**
`https://amazon-eks.s3-us-west-2.amazonaws.com/cloudformation/2019-11-15/amazon-eks-arm-nodegroup.yaml`
1. On the Specify Details page, fill out the following parameters accordingly, and choose **Next**.
  * **Stack name**: Choose a stack name for your AWS CloudFormation stack. For example, you can call it <cluster-name>-worker-nodes.
  * **ClusterName**: Enter the name that you used when you created your Amazon EKS cluster.
    **Important**
    This name must exactly match the name you used in Step 1: Create Your Amazon EKS Cluster; otherwise, your worker nodes cannot join the cluster.
  * **ClusterControlPlaneSecurityGroup**: You will be presented with a drop-down list of security groups. Choose the value from the AWS CloudFormation 
  output that you captured in the Create your Amazon EKS Cluster VPC step. (e.g. eksctl-\<cluster name\>-cluster-ControlPlaneSecurityGroup-XXXXXXXXXXXXX)
  * **NodeGroupName**: Enter a name for your node group. This name can be used later to identify the Auto Scaling node group that is created for your worker nodes.
  * **NodeAutoScalingGroupMinSize**: Enter the minimum number of nodes that your worker node Auto Scaling group can scale in to.
  * **NodeAutoScalingGroupDesiredCapacity**: Enter the desired number of nodes to scale to when your stack is created.
  * **NodeAutoScalingGroupMaxSize**: Enter the maximum number of nodes that your worker node Auto Scaling group can scale out to.
  * **NodeInstanceType**: Choose one of the A1 instance types for your worker nodes (e.g.: `a1.large`).
  * **NodeImageId**: Enter the current Amazon EKS worker node AMI ID for your region from the [AMI table](#latest-eks-a1-amis).
  * **NodeVolumeSize**: Enter node volume size. The default of 20 is fine.
  * **KeyName**: Enter the name of an Amazon EC2 key pair that you can use to decrypt administrator password while RDP into your 
  worker nodes after they launch. If you don't already have an Amazon EC2 key pair, you can create one in the AWS Management Console. 
  For more information, see Amazon EC2 Key Pairs in the Amazon EC2 User Guide for Linux Instances.

  **Note**: If you do not provide a key pair here, the AWS CloudFormation stack creation will fail.

  * **VpcId**: Choose the value from the AWS CloudFormation output that you captured in the Create your Amazon EKS 
  Cluster VPC step. (e.g. eksctl-\<cluster name\>-cluster/VPC)
  * **Subnets**: Choose the subnets that you created in Create your Amazon EKS Cluster VPC.
  
6. On the **Options** page, you can choose to tag your stack resources. Choose **Next**.
7. On the **Review** page, review your information, acknowledge that the stack might create IAM resources, and then choose **Create**.

### **Step 9.** Record the ARM64 instance role ARN.
1. After the ARM worker nodes stack has finished creating, select it in the console and choose the **Outputs** tab.
2. Record the value of **NodeInstanceRole** for the node group that was created. You need this when you configure your Amazon EKS worker nodes in step 11.

### **Step 10.** Configure the AWS authenticator configuration map to enable worker nodes to join your cluster
1. Download the configuration map
`wget https://raw.githubusercontent.com/aws/containers-roadmap/master/preview-programs/eks-ec2-a1-preview/aws-auth-cm-arm64.yaml`

2. Open the file with your favorite text editor. Replace the _<ARN of instance role (not instance profile) of arm64 nodes (see step 10)>_ snippet with the **NodeInstanceRole** values that you recorded from step 10 above, and save the file.

**Important**: Do not modify any other lines in this file.

```
apiVersion: v1
kind: ConfigMap
metadata:  
  name: aws-auth  
  namespace: kube-system
data:  
  mapRoles: |  
    - rolearn: <ARN of instance role (not instance profile) of arm64 nodes (see step 10)>
      username: system:node:{{EC2PrivateDNSName}}
      groups:
        - system:bootstrappers
        - system:nodes
```

3. Apply the configuration. This command may take a few minutes to finish: `kubectl apply -f aws-auth-cm-arm64.yaml`

**Note**: If you receive the error `"aws-iam-authenticator": executable file not found in PATH`, then **kubectl** on your machine is not configured correctly for Amazon EKS. For more information, see [Installing aws-iam-authenticator](https://docs.aws.amazon.com/eks/latest/userguide/install-aws-iam-authenticator.html).

If you receive any other authorization or resource type errors, see [Unauthorized or Access Denied (kubectl)](https://docs.aws.amazon.com/eks/latest/userguide/troubleshooting.html#unauthorized).

4. Watch the status of your nodes and wait for them to reach the **Ready** status: `kubectl get nodes --watch`

### **Step 11.** Launch an app
Launch the metrics server to test that you can schedule pods.

```
kubectl apply -f https://raw.githubusercontent.com/aws/containers-roadmap/master/preview-programs/eks-ec2-a1-preview/cni-metrics-helper-arm64.yaml
```
 * Output:
```
clusterrole.rbac.authorization.k8s.io/cni-metrics-helper created
serviceaccount/cni-metrics-helper created
clusterrolebinding.rbac.authorization.k8s.io/cni-metrics-helper created
deployment.extensions/cni-metrics-helper created
``` 

Check the scheduled pods:

 * `kubectl -n kube-system get pods -o wide`


## Next steps

* Run your own containers on your new EKS cluster.

* Leave comments or questions on our [GitHub issue](https://github.com/aws/containers-roadmap/issues/264).

* This is an evolving project. As we roll out new features and functionality, we will update this repository and the roadmap issue.

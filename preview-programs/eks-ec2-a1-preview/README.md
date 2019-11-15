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
| us-west-2    	  | 1.13                  | ami-05546e5b2e87ae067 |
| us-west-2       | 1.14                  | ami-07d9ce1e5c7cfb536 |

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
kubernetes   ClusterIP   ww.xx.yy.zz      <none>        443/TCP   24h
```

In order to support having only A1 nodes on our EKS cluster, we need to update some of the Kubernetes components. Follow the steps below to update CoreDNS, Kube-Proxy, and install the AWS ARM64 CNI plugin.

### **Step 4.** Update the image ID used for CoreDNS
Run one of the below commands based upon the version of Kubernetes you are using to install an updated version of CoreDNS:

**Kubernetes 1.13**
```shell
kubectl set image --namespace kube-system deployment.apps/coredns \
coredns=940911992744.dkr.ecr.us-west-2.amazonaws.com/eks/coredns-arm64:v1.2.6
```

**Kubernetes 1.14**
```shell
kubectl set image --namespace kube-system deployment.apps/coredns \
coredns=940911992744.dkr.ecr.us-west-2.amazonaws.com/eks/coredns-arm64:v1.3.1
```

### **Step 5.** Update the image ID used for Kube-Proxy
Run the below command based upon the version of Kubernetes you are using to install an updated version of Kube-Proxy:

**Kubernetes 1.13**
```shell
kubectl set image daemonset.apps/kube-proxy \
-n kube-system \
kube-proxy=940911992744.dkr.ecr.us-west-2.amazonaws.com/eks/kube-proxy-arm64:v1.13.10
```

**Kubernetes 1.14**
```shell
kubectl set image daemonset.apps/kube-proxy \
-n kube-system \
kube-proxy=940911992744.dkr.ecr.us-west-2.amazonaws.com/eks/kube-proxy-arm64:v1.14.7
```

### *Step 6.* Deploy the ARM CNI Plugin
Deploy the vpc-resource-controller: kubectl apply -f https://raw.githubusercontent.com/aws/containers-roadmap/master/preview-programs/eks-ec2-a1-preview/aws-k8s-cni-arm64.yaml

### **Step 7.** Patch the aws-node DaemonSet to use the ARM CNI plugin
Run the below command to install the AWS ARM64 CNI Plugin (this command will work for both 1.13 as well as 1.14):
```shell
kubectl patch daemonset aws-node \
-n kube-system \
-p '{"spec": {"template": {"spec": {"containers": [{"image": "940911992744.dkr.ecr.us-west-2.amazonaws.com/amazon-k8s-cni-arm64:v1.5.3","name":"aws-node"}]}}}}'
```

### **Step 8.** Update the node affinity of Kube-Proxy, AWS-Node, and CoreDNS
Before we launch our A1 instances, we will need to udpate the node affinity for the Kube-Proxy, AWS-Node, and CoreDNS. After running each of the commands below, an editor will open (e.g.: vi for Linux or MacOS clients, notepad for Windows clients). Once the editor has opened, scroll down to the bottom of the file to where the node affinity is defined. In each case, update the value of `amd64` to `arm64` (see example below):

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
              - key: beta.kubernetes.io/os
                operator: In
                values:
                - linux
              - key: beta.kubernetes.io/arch
                operator: In
                values:
                - amd64 <-- change to arm64
...
```

```shell
kubectl -n kube-system edit ds kube-proxy
kubectl -n kube-system edit ds aws-node
kubectl -n kube-system edit deployment coredns
```

### *Step 9.* Launch and Configure Amazon EKS ARM Worker Nodes
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
  * **ClusterControlPlaneSecurityGroup**: You will be presented with a drop-down list of security groups. Choose the value from the AWS CloudFormation output that you captured in the Create your Amazon EKS Cluster VPC step. (e.g. eksctl-<cluster name>-cluster-ControlPlaneSecurityGroup-XXXXXXXXXXXXX)
  * **NodeGroupName**: Enter a name for your node group. This name can be used later to identify the Auto Scaling node group that is created for your worker nodes.
  * **NodeAutoScalingGroupMinSize**: Enter the minimum number of nodes that your worker node Auto Scaling group can scale in to.
  * **NodeAutoScalingGroupDesiredCapacity**: Enter the desired number of nodes to scale to when your stack is created.
  * **NodeAutoScalingGroupMaxSize**: Enter the maximum number of nodes that your worker node Auto Scaling group can scale out to.
  * **NodeInstanceType**: Choose one of the A1 instance types for your worker nodes (e.g.: a1-large).
  * **NodeImageId**: Enter the current Amazon EKS worker node AMI ID for your region from the [AMI table](#latest-eks-a1-amis).
  * **BootstrapArguments**: --pause-container-account 940911992744
  * **KeyName**: Enter the name of an Amazon EC2 key pair that you can use to decrypt administrator password while RDP into your worker nodes after they launch. If you don't already have an Amazon EC2 keypair, you can create one in the AWS Management Console. For more information, see Amazon EC2 Key Pairs in the Amazon EC2 User Guide for Linux Instances.

  **Note**: If you do not provide a keypair here, the AWS CloudFormation stack creation will fail.

  * **VpcId**: Choose the value from the AWS CloudFormation output that you captured in the Create your Amazon EKS Cluster VPC step. (e.g. eksctl-<cluster name>-cluster/VPC)
  * **Subnets**: Choose the subnets that you created in Create your Amazon EKS Cluster VPC.
  
6. On the **Options** page, you can choose to tag your stack resources. Choose **Next**.
7. On the **Review** page, review your information, acknowledge that the stack might create IAM resources, and then choose **Create**.

### **Step 10.** Record the ARM64 instance role ARN.
1. After the ARM worker nodes stack has finished creating, select it in the console and choose the **Outputs** tab.
2. Record the value of **NodeInstanceRole** for the node group that was created. You need this when you configure your Amazon EKS worker nodes in step 11.

### **Step 11.** Configure the AWS authenticator configuration map to enable worker nodes to join your cluster
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

### **Step 12.** Launch an app
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

 * `kubectl get services -o wide`
 * **Note**: It may take several minutes before the IP address is available.

After your external IP address is available, point a web browser to that address at port 3000 to view your guest book.
For example, http://a7a95c2b9e69711e7b1a3022fdcfdf2e-1985673473.us-west-2.elb.amazonaws.com:3000

**Note**: It may take several minutes for DNS to propagate and for your guest book to show up.

## Next steps

* Run your own containers on your new EKS cluster.

* Leave comments or questions on our [GitHub issue](https://github.com/aws/containers-roadmap/issues/264).

* This is an evolving project. As we roll out new features and functionality, we will update this repository and the roadmap issue.

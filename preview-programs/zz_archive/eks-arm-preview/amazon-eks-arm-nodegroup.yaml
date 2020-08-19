---
AWSTemplateFormatVersion: 2010-09-09
Description: Amazon EKS - Node Group

Parameters:

  KeyName:
    Description: The EC2 Key Pair to allow SSH access to the instances
    Type: AWS::EC2::KeyPair::KeyName

  KubernetesVersion:
    Type: String
    Default: '1.15'
    AllowedValues:
      - '1.13'
      - '1.14'
      - '1.15'

  NodeInstanceType:
    Description: EC2 instance type for the node instances
    Type: String
    Default: a1.large
    ConstraintDescription: Must be a valid EC2 instance type
    AllowedValues:
      - a1.medium
      - a1.large
      - a1.xlarge
      - a1.2xlarge
      - a1.4xlarge
      - m6g.medium
      - m6g.large
      - m6g.xlarge
      - m6g.2xlarge
      - m6g.4xlarge
      - m6g.8xlarge
      - m6g.12xlarge
      - m6g.16xlarge

  NodeAutoScalingGroupMinSize:
    Description: Minimum size of Node Group ASG.
    Type: Number
    Default: 1

  NodeAutoScalingGroupMaxSize:
    Description: Maximum size of Node Group ASG. Set to at least 1 greater than NodeAutoScalingGroupDesiredCapacity.
    Type: Number
    Default: 4

  NodeAutoScalingGroupDesiredCapacity:
    Description: Desired capacity of Node Group ASG.
    Type: Number
    Default: 3

  NodeVolumeSize:
    Description: Node volume size
    Type: Number
    Default: 20

  ClusterName:
    Description: The cluster name provided when the cluster was created. If it is incorrect, nodes will not be able to join the cluster.
    Type: String

  BootstrapArguments:
    Description: Arguments to pass to the bootstrap script. See files/bootstrap.sh in https://github.com/awslabs/amazon-eks-ami
    Type: String
    Default: "--pause-container-account 602401143452"

  NodeGroupName:
    Description: Unique identifier for the Node Group.
    Type: String

  ClusterControlPlaneSecurityGroup:
    Description: The security group of the cluster control plane.
    Type: AWS::EC2::SecurityGroup::Id

  VpcId:
    Description: The VPC of the worker instances
    Type: AWS::EC2::VPC::Id

  Subnets:
    Description: The subnets where workers can be created.
    Type: List<AWS::EC2::Subnet::Id>

  NodeImageAMI113:
    Description: The SSM parameter that contains the Amazon Machine Image (AMI) ID for Kubernetes 1.13 nodes.
    Type : 'AWS::SSM::Parameter::Value<AWS::EC2::Image::Id>'
    Default: /aws/service/eks/optimized-ami/1.13/amazon-linux-2-arm64/recommended/image_id

  NodeImageAMI114:
    Description: The SSM parameter that contains the Amazon Machine Image (AMI) ID for Kubernetes 1.14 nodes.
    Type : 'AWS::SSM::Parameter::Value<AWS::EC2::Image::Id>'
    Default: /aws/service/eks/optimized-ami/1.14/amazon-linux-2-arm64/recommended/image_id

  NodeImageAMI115:
    Description: The SSM parameter that contains the Amazon Machine Image (AMI) ID for Kubernetes 1.15 nodes.
    Type : 'AWS::SSM::Parameter::Value<AWS::EC2::Image::Id>'
    Default: /aws/service/eks/optimized-ami/1.15/amazon-linux-2-arm64/recommended/image_id

Mappings:
  PartitionMap:
    aws:
      EC2ServicePrincipal: "ec2.amazonaws.com"
    aws-cn:
      EC2ServicePrincipal: "ec2.amazonaws.com.cn"

Metadata:

  AWS::CloudFormation::Interface:
    ParameterGroups:
      - Label:
          default: EKS Cluster
        Parameters:
          - KubernetesVersion
          - ClusterName
          - ClusterControlPlaneSecurityGroup
      - Label:
          default: Worker Node Configuration
        Parameters:
          - NodeGroupName
          - NodeAutoScalingGroupMinSize
          - NodeAutoScalingGroupDesiredCapacity
          - NodeAutoScalingGroupMaxSize
          - NodeInstanceType
          - NodeImageAMI
          - NodeVolumeSize
          - KeyName
          - BootstrapArguments
      - Label:
          default: Worker Network Configuration
        Parameters:
          - VpcId
          - Subnets
      - Label:
          default: Amazon Machine Image information
        Parameters:
          - NodeImageAMI113
          - NodeImageAMI114
          - NodeImageAMI115

Conditions:
  Kubernetes113: !Equals [!Ref KubernetesVersion, '1.13']
  Kubernetes114: !Equals [!Ref KubernetesVersion, '1.14']
  Kubernetes115: !Equals [!Ref KubernetesVersion, '1.15']

Resources:

  NodeInstanceProfile:
    Type: AWS::IAM::InstanceProfile
    Properties:
      Path: "/"
      Roles:
        - !Ref NodeInstanceRole

  NodeInstanceRole:
    Type: AWS::IAM::Role
    Properties:
      AssumeRolePolicyDocument:
        Version: 2012-10-17
        Statement:
          - Effect: Allow
            Principal:
              Service:
                - !FindInMap [PartitionMap, !Ref "AWS::Partition", EC2ServicePrincipal]
            Action: sts:AssumeRole
      Path: "/"
      ManagedPolicyArns:
        - !Sub "arn:${AWS::Partition}:iam::aws:policy/AmazonEKSWorkerNodePolicy"
        - !Sub "arn:${AWS::Partition}:iam::aws:policy/AmazonEKS_CNI_Policy"
        - !Sub "arn:${AWS::Partition}:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"

  NodeSecurityGroup:
    Type: AWS::EC2::SecurityGroup
    Properties:
      GroupDescription: Security group for all nodes in the cluster
      VpcId: !Ref VpcId
      Tags:
        - Key: !Sub kubernetes.io/cluster/${ClusterName}
          Value: owned

  NodeSecurityGroupIngress:
    Type: AWS::EC2::SecurityGroupIngress
    DependsOn: NodeSecurityGroup
    Properties:
      Description: Allow node to communicate with each other
      GroupId: !Ref NodeSecurityGroup
      SourceSecurityGroupId: !Ref NodeSecurityGroup
      IpProtocol: -1
      FromPort: 0
      ToPort: 65535

  NodeSecurityGroupFromControlPlaneIngress:
    Type: AWS::EC2::SecurityGroupIngress
    DependsOn: NodeSecurityGroup
    Properties:
      Description: Allow worker Kubelets and pods to receive communication from the cluster control plane
      GroupId: !Ref NodeSecurityGroup
      SourceSecurityGroupId: !Ref ClusterControlPlaneSecurityGroup
      IpProtocol: tcp
      FromPort: 1025
      ToPort: 65535

  ControlPlaneEgressToNodeSecurityGroup:
    Type: AWS::EC2::SecurityGroupEgress
    DependsOn: NodeSecurityGroup
    Properties:
      Description: Allow the cluster control plane to communicate with worker Kubelet and pods
      GroupId: !Ref ClusterControlPlaneSecurityGroup
      DestinationSecurityGroupId: !Ref NodeSecurityGroup
      IpProtocol: tcp
      FromPort: 1025
      ToPort: 65535

  NodeSecurityGroupFromControlPlaneOn443Ingress:
    Type: AWS::EC2::SecurityGroupIngress
    DependsOn: NodeSecurityGroup
    Properties:
      Description: Allow pods running extension API servers on port 443 to receive communication from cluster control plane
      GroupId: !Ref NodeSecurityGroup
      SourceSecurityGroupId: !Ref ClusterControlPlaneSecurityGroup
      IpProtocol: tcp
      FromPort: 443
      ToPort: 443

  ControlPlaneEgressToNodeSecurityGroupOn443:
    Type: AWS::EC2::SecurityGroupEgress
    DependsOn: NodeSecurityGroup
    Properties:
      Description: Allow the cluster control plane to communicate with pods running extension API servers on port 443
      GroupId: !Ref ClusterControlPlaneSecurityGroup
      DestinationSecurityGroupId: !Ref NodeSecurityGroup
      IpProtocol: tcp
      FromPort: 443
      ToPort: 443

  ClusterControlPlaneSecurityGroupIngress:
    Type: AWS::EC2::SecurityGroupIngress
    DependsOn: NodeSecurityGroup
    Properties:
      Description: Allow pods to communicate with the cluster API Server
      GroupId: !Ref ClusterControlPlaneSecurityGroup
      SourceSecurityGroupId: !Ref NodeSecurityGroup
      IpProtocol: tcp
      ToPort: 443
      FromPort: 443

  NodeGroup:
    Type: AWS::AutoScaling::AutoScalingGroup
    Properties:
      DesiredCapacity: !Ref NodeAutoScalingGroupDesiredCapacity
      LaunchConfigurationName: !Ref NodeLaunchConfig
      MinSize: !Ref NodeAutoScalingGroupMinSize
      MaxSize: !Ref NodeAutoScalingGroupMaxSize
      VPCZoneIdentifier: !Ref Subnets
      Tags:
        - Key: Name
          Value: !Sub ${ClusterName}-${NodeGroupName}-Node
          PropagateAtLaunch: true
        - Key: !Sub kubernetes.io/cluster/${ClusterName}
          Value: owned
          PropagateAtLaunch: true
    UpdatePolicy:
      AutoScalingRollingUpdate:
        MaxBatchSize: 1
        MinInstancesInService: !Ref NodeAutoScalingGroupDesiredCapacity
        PauseTime: PT5M

  NodeLaunchConfig:
    Type: AWS::AutoScaling::LaunchConfiguration
    Properties:
      IamInstanceProfile: !Ref NodeInstanceProfile
      ImageId:
        Fn::Join:
          - ''
          - - !If [ Kubernetes114, !Ref NodeImageAMI114, '' ]
            - !If [ Kubernetes113, !Ref NodeImageAMI113, '' ]
            - !If [ Kubernetes115, !Ref NodeImageAMI115, '' ]
      InstanceType: !Ref NodeInstanceType
      KeyName: !Ref KeyName
      SecurityGroups:
        - !Ref NodeSecurityGroup
      BlockDeviceMappings:
        - DeviceName: /dev/xvda
          Ebs:
            VolumeSize: !Ref NodeVolumeSize
            VolumeType: gp2
            DeleteOnTermination: true
      UserData:
        Fn::Base64:
          !Sub |
            #!/bin/bash
            set -o xtrace
            /etc/eks/bootstrap.sh ${ClusterName} ${BootstrapArguments}
            /opt/aws/bin/cfn-signal --exit-code $? \
                     --stack  ${AWS::StackName} \
                     --resource NodeGroup  \
                     --region ${AWS::Region}

Outputs:

  NodeInstanceRole:
    Description: The node instance role
    Value: !GetAtt NodeInstanceRole.Arn

  NodeSecurityGroup:
    Description: The security group for the node group
    Value: !Ref NodeSecurityGroup

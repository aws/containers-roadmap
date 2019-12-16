# Amazon ECS and AWS Fargate FireLens Preview Program

Start here to participate in the FireLens preview program for [Amazon Elastic Container Service (ECS)](https://aws.amazon.com/ecs). FireLens is available for ECS tasks using the EC2 and Fargate launch types.

FireLens works with [Fluentd](https://www.fluentd.org/) and [Fluent Bit](https://fluentbit.io/). With FireLens, you can route your logs to a large number of AWS and partner destinations using simple configuration in your ECS Task Definition.

We are providing FireLens with a basic set of functionality as a public preview to allow you to test it out, and give us feedback. Once we announce the general availability of FireLens it will be ready for production workloads, and will support more uses cases.

**Note:** FireLens is no longer under public preview. The feature is generally available. Please see the [official AWS Documentation](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/using_firelens.html).

#### Contents
* [Leaving feedback and getting help](#leaving-feedback-and-getting-help)
* [Before you begin](#before-you-begin)
* [Availability](#availability)
* [Use Cases](#use-cases)
* [Using the aws-for-fluent-bit image](#using-the-aws-for-fluent-bit-image)
* [FireLens Task Definitions](#firelens-task-definitions)
* [Permissions](#permissions)
* [Supported Fluentd and Fluent Bit Docker Images](#supported-fluentd-and-fluent-bit-docker-images)
* [Examples](#examples)
* [Troubleshooting](#troubleshooting)

#### Leaving feedback and getting help
* The assets and instructions in this repository are offered on an _as-is_ basis as part of a public preview program for new AWS service functionality.
* Leave comments or questions on our [GitHub issue](https://github.com/aws/containers-roadmap/issues/10).
* For issues with the Amazon ECS or AWS Fargate service or with your AWS account, please contact AWS support using the AWS console.

## Before you begin
* Make sure you have an active and valid AWS account. If you don't, you can create one [here](https://portal.aws.amazon.com/gp/aws/developer/registration/index.html).
* If you haven't used Amazon ECS before, familiarize yourself with the [AWS Documentation](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/Welcome.html)

## Availability

FireLens is supported in all regions where Amazon ECS is supported. FireLens for ECS Tasks using the Fargate Launch Type is supported in all AWS Fargate regions.

During the public preview, creating FireLens Task Definitions is only supported via the AWS SDKs, and AWS CLI. 

FireLens is supported in the bridge, host, and awsvpc network modes.

## Use Cases

The Firelens Public Preview is intended to serve three key use cases.

### 1. Provide a simple method of sending container standard out logs to almost any destination

FireLens allows you to configure Fluentd or Fluent Bit outputs in your Task Definition. Fluentd supports a number of log destinations in its with its built-in plugins; see its [official documentation for a list](https://docs.fluentd.org/output). Support for more destinations can be obtained by [installing plugins](https://www.fluentd.org/plugins/all).

We recommend that you use Fluent Bit as your log router because its resource utilization is significantly lower than Fluentd. If you use the [AWS Fluent Bit Image](#using-the-aws-for-fluent-bit-image), you have access to all of its [built-in outputs](https://fluentbit.io/documentation/0.14/output/) and [Amazon CloudWatch Logs](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/WhatIsCloudWatchLogs.html) and [Amazon Kinesis Data Firehose](https://aws.amazon.com/kinesis/data-firehose/).

Note that you can forward from Fluent Bit to Fluentd, and vice versa. So for example, you could use FireLens to forward logs from a Fargate task to a [Centralized Fluentd Aggregator](https://aws.amazon.com/blogs/compute/building-a-scalable-log-solution-aggregator-with-aws-fargate-fluentd-and-amazon-kinesis-data-firehose/).

### 2. Filter Logs at Source

Not all logs are of equal importance. Some may be unneeded; you can save on log storage costs by only sending the logs that you need. Fluentd and Fluent Bit both support filtering of logs via regular expressions. You can drop all logs that match a pattern, or only send logs that match a pattern. FireLens allows you to easily configure this via the Task Definition.

### 3. Decorate Logs with ECS Metadata

By default, FireLens will add useful metadata to each log message. This can be disabled.

When enabled, a log event will look like the following:

```
{
    "source": "stdout",
    "log": "116.82.105.169 - Homenick7462 197 [2018-11-27T21:53:38Z] \"HEAD /enable/relationships/cross-platform/partnerships\" 501 13886",
    "container_id": "e54cccfac2b87417f71877907f67879068420042828067ae0867e60a63529d35",
    "container_name": "/ecs-demo-6-container2-a4eafbb3d4c7f1e16e00"
    "ecs_cluster": "mycluster",
    "ecs_task_arn": "arn:aws:ecs:us-east-2:01234567891011:task/mycluster/3de392df-6bfa-470b-97ed-aa6f482cd7a6",
    "ecs_task_definition": "demo:7"
    "ec2_instance_id": "i-06bc83dbc2ac2fdf8"
}
```

## Using the aws-for-fluent-bit image

We recommend that you use Fluent Bit as your log router because its resource utilization is significantly lower than Fluentd. AWS provides a Fluent Bit image with plugins for [CloudWatch Logs](https://github.com/aws/amazon-cloudwatch-logs-for-fluent-bit) and [Kinesis Firehose](https://github.com/aws/amazon-kinesis-firehose-for-fluent-bit).

This image is available on [Docker Hub](https://hub.docker.com/r/amazon/aws-for-fluent-bit), however, we recommend that you use the regionalized [Amazon ECR](https://aws.amazon.com/ecr/) image repositories because they provide higher availability.


| Region         | Registry ID  | Full Image Names                                                          |
|----------------|--------------|-------------------------------------------------------------------------|
| us-east-1      | 906394416424 | 906394416424.dkr.ecr.us-east-1.amazonaws.com/aws-for-fluent-bit:latest      |
| eu-west-1      | 906394416424 | 906394416424.dkr.ecr.eu-west-1.amazonaws.com/aws-for-fluent-bit:latest      |
| us-west-1      | 906394416424 | 906394416424.dkr.ecr.us-west-1.amazonaws.com/aws-for-fluent-bit:latest      |
| ap-southeast-1 | 906394416424 | 906394416424.dkr.ecr.ap-southeast-1.amazonaws.com/aws-for-fluent-bit:latest |
| ap-northeast-1 | 906394416424 | 906394416424.dkr.ecr.ap-northeast-1.amazonaws.com/aws-for-fluent-bit:latest |
| us-west-2      | 906394416424 | 906394416424.dkr.ecr.us-west-2.amazonaws.com/aws-for-fluent-bit:latest      |
| sa-east-1      | 906394416424 | 906394416424.dkr.ecr.sa-east-1.amazonaws.com/aws-for-fluent-bit:latest      |
| ap-southeast-2 | 906394416424 | 906394416424.dkr.ecr.ap-southeast-2.amazonaws.com/aws-for-fluent-bit:latest |
| eu-central-1   | 906394416424 | 906394416424.dkr.ecr.eu-central-1.amazonaws.com/aws-for-fluent-bit:latest   |
| ap-northeast-2 | 906394416424 | 906394416424.dkr.ecr.ap-northeast-2.amazonaws.com/aws-for-fluent-bit:latest |
| ap-south-1     | 906394416424 | 906394416424.dkr.ecr.ap-south-1.amazonaws.com/aws-for-fluent-bit:latest     |
| us-east-2      | 906394416424 | 906394416424.dkr.ecr.us-east-2.amazonaws.com/aws-for-fluent-bit:latest      |
| ca-central-1   | 906394416424 | 906394416424.dkr.ecr.ca-central-1.amazonaws.com/aws-for-fluent-bit:latest   |
| eu-west-2      | 906394416424 | 906394416424.dkr.ecr.eu-west-2.amazonaws.com/aws-for-fluent-bit:latest      |
| eu-west-3      | 906394416424 | 906394416424.dkr.ecr.eu-west-3.amazonaws.com/aws-for-fluent-bit:latest      |
| ap-northeast-3 | 906394416424 | 906394416424.dkr.ecr.ap-northeast-3.amazonaws.com/aws-for-fluent-bit:latest |
| eu-north-1     | 906394416424 | 906394416424.dkr.ecr.eu-north-1.amazonaws.com/aws-for-fluent-bit:latest     |
| ap-east-1      | 449074385750 | 449074385750.dkr.ecr.ap-east-1.amazonaws.com/aws-for-fluent-bit:latest      |
| me-south-1     | 741863432321 | 741863432321.dkr.ecr.me-south-1.amazonaws.com/aws-for-fluent-bit:latest     |
| cn-north-1     | 128054284489 | 128054284489.dkr.ecr.cn-north-1.amazonaws.com.cn/aws-for-fluent-bit:latest     |
| cn-northwest-1 | 128054284489 | 128054284489.dkr.ecr.cn-northwest-1.amazonaws.com.cn/aws-for-fluent-bit:latest |
| us-gov-east-1  | 161423150738 | 161423150738.dkr.ecr.us-gov-east-1.amazonaws.com/aws-for-fluent-bit:latest  |
| us-gov-west-1  | 161423150738 | 161423150738.dkr.ecr.us-gov-west-1.amazonaws.com/aws-for-fluent-bit:latest  |


## FireLens Task Definitions

A Task Definition that uses FireLens has two parts; the log router container definition and the log configuration for application containers.

### 1. FireLens Log Router Container Definition

Create a container definition with either Fluentd or Fluent Bit, and mark it as the FireLens container:

```
{
	"essential": true,
	"image": "amazon/aws-for-fluent-bit:latest",
	"name": "log_router",
	"firelensConfiguration": {
		"type": "fluentbit",
		"options": {
			"enable-ecs-log-metadata": "true"
		}
	}
}
```

The option `enable-ecs-log-metadata` toggles the metadata fields described in the Use Cases section. It can be either `true` or `false`. It is enabled by default- not specifying this key is equivalent to setting it to `true`.

The container with `firelensConfiguration` must be marked as essential.

### 2. Application Containers that use FireLens for Logs

You configure an application container to use FireLens for logs the same way you would configure it to use a [Docker Log Driver](https://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_LogConfiguration.html). Use the pseudo-driver `awsfirelens` and specify the key value pairs present in a Fluentd or Fluent Bit output section as the log driver options.

For example, a Fluent Bit output definition looks like the following:

```
[OUTPUT]
    Name   firehose
    Match  *
    region us-west-2
    delivery_stream my-stream
```

If you want your application container to use that configuration for its container standard out logs, specify the following as its [logConfiguration]((https://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_LogConfiguration.html)):

```
"logConfiguration": {
	"logDriver": "awsfirelens",
	"options": {
		"Name": "firehose",
		"region": "us-west-2",
		"delivery_stream": "my-stream"
	}
}
```

The Fluent Bit `Match` field is not needed; that configuration is managed by FireLens.

**Note**: The FireLens container must start before any application containers that use it. Normally, ECS will handle this for you. However, you can control the start ordering of containers using [Container Dependencies](https://docs.aws.amazon.com/AmazonECS/latest/APIReference/API_ContainerDependency.html) in your Task Definition. If you use this field on containers which use FireLens for logs, ensure that each container has a `START` or `HEALTHY` (if you have configured a health check for Fluentd or Fluent Bit) dependency on the FireLens container.

#### Filtering Logs Using Regular Expressions

Fluentd and Fluent Bit both support filtering of logs based on their content. FireLens provides a simple short hand for enabling this. The options section of a container's logConfiguration can contain the special keys `exclude-pattern` and `include-pattern` that take regular expressions as their values. The `exclude-pattern` key will cause all logs that match its regular expression to be dropped. With `include-pattern`, only logs which match its regular expression will be sent. These keys can be used together.

Here is an example usage that also contains a Fluentd output definition for CloudWatch Logs:
```
"logConfiguration": {
	"logDriver":"awsfirelens",
	"options": {
	   "@type": "cloudwatch_logs",
	   "log_group_name": "firelens-testing",
	   "auto_create_stream": "true",
	   "use_tag_as_stream": "true",
	   "region": "us-west-2",
	   "exclude-pattern": "^[a-z][aeiou].*$",
	   "include-pattern": "^.*[aeiou]$"
   }
}
```

Fluentd and Fluent Bit use Ruby Regular expressions; you can use the [Rubular](https://rubular.com/) website to test expressions.

## Permissions

Fluentd/Fluent Bit runs as a side-car in your task. Thus, it uses the [ECS Task IAM Role](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-iam-roles.html) for access to AWS Services. Ensure that you have given your task the necessary permissions.

## Supported Fluentd and Fluent Bit Docker Images

FireLens support Fluentd versions `v1.0` and greater, and Fluent Bit versions `v1.0.0` and greater.

Your Fluent Bit image must be configured to use a configuration file at `/fluent-bit/etc/fluent-bit.conf`. The [aws-for-fluent-bit](https://hub.docker.com/r/amazon/aws-for-fluent-bit) image and the [fluent/fluent-bit](https://hub.docker.com/r/fluent/fluent-bit/) images all use this default path. The command in the Dockerfile for your Fluent Bit image should look something like the following:

```
CMD ["/fluent-bit/bin/fluent-bit", "-c", "/fluent-bit/etc/fluent-bit.conf"]
```

Your Fluentd image must be configured to use a configuration file at `/fluentd/etc/fluent.conf`. The [fluent/fluentd](https://hub.docker.com/r/fluent/fluentd) images all use this default path. See the official [fluentd-docker-image](https://github.com/fluent/fluentd-docker-image) repo for examples.

## Examples

We have provided example Task Definitions for the preview program. Use these as a starting point and customize them for your own needs:
* [Fluent Bit CloudWatch Logs Example](cloudwatch_task_definition.json)
* [Fluent Bit Kinesis Firehose Example](firehose_task_definition.json)
* [Forward to external Fluentd/Fluent Bit Example](forward_task_definition.json)

## Troubleshooting

Here are common problems that you may encounter when configuring FireLens:

#### 1. No logs are present at your log destination

Likely Causes:
* Incorrect network configuration. Make sure that you have configured the networking in your VPC so that your task can access your log destination.
* Incorrect permissions. Make sure that you have given your Task all needed permissions in its [Task IAM Role](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-iam-roles.html).
* Incorrect configuration of your Fluentd/Fluent Bit output.

To help debug these problems, we recommend enabling logs for your Fluentd/Fluent Bit container using the [`awslogs` Docker Log Driver](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/using_awslogs.html). Any errors or warnings produced by your log router will be sent to CloudWatch.

#### 2. Incorrectly specifying the Fluentd/Fluent Bit Plugin options

Carefully consult the documentation for the output plugin you are using.

##### Fluentd Errors

```
2019-08-29 18:07:07 +0000 [error]: config error file="/fluentd/etc/fluent.conf" error_class=Fluent::ConfigError error="Unknown output plugin 'firehouse'.
```

Make sure you have correctly specified the plugin name with `@type` in your logConfiguration options:

```
{
    "@type": "kinesis_firehose"
}
```

Furthermore, most Fluentd plugins have to be installed. In many cases, you need to create a custom docker image with Fluentd and the plugin(s) that you want to use.

```
gem install fluent-plugin-kinesis
```

The [Fluentd Docker Hub page](https://hub.docker.com/r/fluent/fluentd/) has instructions on building a custom images.


##### Fluent Bit Errors

```
Output plugin 'foward' cannot be loaded
Error: You must specify an output target. Aborting
```

Make sure you have correctly specified the plugin `Name` in your logConfiguration options:

```
{
    "Name": "forward"
}
```

We recommend using the [aws-for-fluent-bit](https://hub.docker.com/r/amazon/aws-for-fluent-bit) Docker image with FireLens.


#### 3. Specifying your own configuration

This is not supported in the FireLens preview. If you specify your own configuration file for Fluentd or Fluent Bit at the default path, it will be overridden by ECS.

Specifying custom configuration will be supported after the FireLens preview.

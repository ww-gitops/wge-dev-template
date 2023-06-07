provider "aws" {
  region = var.region

  default_tags {
    tags = merge({
      source = "Terraform Managed"
    }, var.tags)
  }
}

data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "ssm_automation_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }

    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["arn:aws:ssm:*:${data.aws_caller_identity.current.account_id}:automation-execution/*"]
    }

    principals {
      type        = "Service"
      identifiers = ["ssm.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "events_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "resource_cleanup" {
  statement {
    effect = "Allow"

    actions = [
      "ec2:DeleteSecurityGroup",
      "ec2:DescribeSecurityGroups",
      "eks:DescribeCluster",
      "elasticloadbalancing:DeleteLoadBalancer",
      "elasticloadbalancing:DescribeLoadBalancers",
      "elasticloadbalancing:DescribeTags"
    ]

    resources = ["*"]
  }
}

data "aws_iam_policy_document" "allow_automation" {
  statement {
    effect    = "Allow"
    actions   = ["ssm:StartAutomationExecution"]
    resources = ["${replace(aws_ssm_document.resource_cleanup.arn, "document/", "automation-definition/")}:*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["iam:PassRole"]
    resources = [aws_iam_role.resource_cleanup.arn]

    condition {
      test     = "StringLikeIfExists"
      variable = "iam:PassedToService"
      values   = ["ssm.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "resource_cleanup" {
  assume_role_policy = data.aws_iam_policy_document.ssm_automation_assume_role.json
  name               = "cluster-resource-cleanup-role-${var.region}"
}

resource "aws_iam_role" "resource_cleanup_events" {
  assume_role_policy = data.aws_iam_policy_document.events_assume_role.json
  name               = "cluster-resource-cleanup-events-${var.region}"
}

resource "aws_iam_role_policy" "resource_cleanup" {
  name   = "${var.ssm_document_name}-policy"
  role   = aws_iam_role.resource_cleanup.id
  policy = data.aws_iam_policy_document.resource_cleanup.json
}

resource "aws_iam_role_policy" "resource_cleanup_automation" {
  name   = "${var.ssm_document_name}-automation"
  role   = aws_iam_role.resource_cleanup_events.id
  policy = data.aws_iam_policy_document.allow_automation.json
}

resource "aws_ssm_document" "resource_cleanup" {
  name            = var.ssm_document_name
  document_format = "YAML"
  document_type   = "Automation"

  content = <<-DOC
    description: "Cleanup hanging resources that might exist after a cluster is destroyed"
    schemaVersion: '0.3'
    assumeRole: "${aws_iam_role.resource_cleanup.arn}"
    parameters:
      ClusterName:
          type: String
          description: "(Required) Name of the EKS cluster to cleanup resources for."
          default: ''
    mainSteps:
    - name: cleanupLoadBalancers
      action: aws:executeScript
      onFailure: Abort
      inputs:
        Runtime: python3.8
        Handler: script_handler
        InputPayload:
          clusterName: '{{ClusterName}}'
        Script: |-
          import boto3

          def script_handler(events, context):
            elbv2_client = boto3.client('elbv2')
            cluster_name = events['clusterName']
            load_balancers = elbv2_client.describe_load_balancers()

            lb_arns = []
            for lb in load_balancers['LoadBalancers']:
              lb_arns.append(lb['LoadBalancerArn'])

            describe_tags = elbv2_client.describe_tags(ResourceArns=lb_arns)

            delete_lbs = []
            for td in describe_tags['TagDescriptions']:
              for tag in td['Tags']:
                if tag['Key'] == f'kubernetes.io/cluster/{cluster_name}' and tag['Value'] == 'owned':
                  delete_lbs.append(td['ResourceArn'])
                elif tag['Key'] == 'elbv2.k8s.aws/cluster' and tag['Value'] == cluster_name:
                  delete_lbs.append(td['ResourceArn'])
            
            for lb in delete_lbs:
              print(f'deleteing load balancer {lb}')
              elbv2_client.delete_load_balancer(LoadBalancerArn=lb)
            
            print('done')
    - name: cleanupSecurityGroups
      action: aws:executeScript
      onFailure: Abort
      inputs:
        Runtime: python3.8
        Handler: script_handler
        InputPayload:
          clusterName: '{{ClusterName}}'
        Script: |-
          import boto3
          import botocore
          import time

          def script_handler(events, context):
            ec2_client = boto3.client('ec2')
            eks_client = boto3.client('eks')
            cluster_name = events['clusterName']

            while True:
              try:
                eks_client.describe_cluster(name=cluster_name)
                print('waiting for cluster to be removed...')
                time.sleep(10)
              except botocore.exceptions.ClientError as error:
                if error.response['Error']['Code'] == 'ResourceNotFoundException':
                  print('cluster has been removed')
                  break
                else:
                  raise error
            
            cluster_security_groups = ec2_client.describe_security_groups(Filters=[
              {'Name': f'tag:kubernetes.io/cluster/{cluster_name}', 'Values': ['owned']},
            ])

            for sg in cluster_security_groups['SecurityGroups']:
              id = sg['GroupId']
              print(f'deleteing security group {id}')
              ec2_client.delete_security_group(GroupId=id)

            elbv2_security_groups = ec2_client.describe_security_groups(Filters=[
              {'Name': 'tag:elbv2.k8s.aws/cluster', 'Values': [cluster_name]},
            ])

            for sg in elbv2_security_groups['SecurityGroups']:
              id = sg['GroupId']
              print(f'deleteing security group {id}')
              ec2_client.delete_security_group(GroupId=id)
            
            print('done')
    DOC
}

resource "aws_cloudwatch_event_rule" "delete_cluster" {
  name = var.event_rule_name

  event_pattern = <<-EOF
  {
    "source": ["aws.eks"],
    "detail-type": ["AWS API Call via CloudTrail"],
    "detail": {
      "eventSource": ["eks.amazonaws.com"],
      "eventName": ["DeleteCluster"]
    }
  }
  EOF
}

resource "aws_cloudwatch_event_target" "cleanup_cluster" {
  rule     = aws_cloudwatch_event_rule.delete_cluster.name
  arn      = replace(aws_ssm_document.resource_cleanup.arn, "document/", "automation-definition/")
  role_arn = aws_iam_role.resource_cleanup_events.arn

  input_transformer {
    input_paths = {
      cluster = "$.detail.requestParameters.name"
    }
    input_template = <<-EOF
    {
      "ClusterName": ["<cluster>"]
    }
    EOF
  }
}

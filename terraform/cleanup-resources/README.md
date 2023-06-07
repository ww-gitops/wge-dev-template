# cleanup-resources
Cleanup EKS related resources that might exist after cluster has been deleted.

## Overview
This code uses terraform to create an SSM automation document that can ran to cleanup EKS resources.  It also creates AWS EventBridge event rules and targets to trigger the document to run whenever a `DeleteCluster` api call is made.

***This applies to all EKS clusters in a given AWS account, not just clusters created by these cluster-templates.***

## Apply
Default values for all variables are already provided.  No vars are required to be set unless overrides are necessary.

```
terraform apply
```

## Destroy
```
terraform destroy
```

## TF Docs
The following is a generated overview of the terraform requirements

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 4.33 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 4.52.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_event_rule.delete_cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule) | resource |
| [aws_cloudwatch_event_target.cleanup_cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) | resource |
| [aws_iam_role.resource_cleanup](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.resource_cleanup_events](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.resource_cleanup](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.resource_cleanup_automation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_ssm_document.resource_cleanup](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ssm_document) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.allow_automation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.events_assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.resource_cleanup](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.ssm_automation_assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_event_rule_name"></a> [event\_rule\_name](#input\_event\_rule\_name) | name of EventBridge rule | `string` | `"eks-cluster-deletion"` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS region | `string` | `"us-east-1"` | no |
| <a name="input_ssm_document_name"></a> [ssm\_document\_name](#input\_ssm\_document\_name) | name of ssm automation document | `string` | `"cluster-resource-cleanup"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | resource tags | `map(string)` | `null` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->

# tag-enforcement

Makes every dollar traceable to an owner. You can't cut costs you can't attribute: this module finds untagged resources and, if you opt in, standardises tag keys and values across your AWS Organization.

## What it creates
| Layer | Resource | Default |
|---|---|---|
| **Detect** | AWS Config `required-tags` rule that flags non-compliant resources | **on** |
| **Standardise** | Organizations tag policy for consistent keys and allowed values | off (opt-in) |
| **Enforce** | Tag-policy `enforced_for`, which blocks wrong tag *values* at create time | off (opt-in) |

## Usage
```hcl
# Member account: detect only
module "tags" {
  source = "github.com/sajedul5/aws-finops-guardrails//modules/tag-enforcement?ref=v0.1.0"

  required_tags = {
    Owner       = []
    Environment = ["prod", "staging", "dev", "test"]
    CostCenter  = []
  }
}

# Management account: also publish an Organizations tag policy
module "tag_policy" {
  source = "github.com/sajedul5/aws-finops-guardrails//modules/tag-enforcement?ref=v0.1.0"

  create_config_rule    = false
  create_tag_policy     = true
  tag_policy_target_ids = ["r-abcd"] # org root or OU IDs
}
```

## Estimated benefit
The goal is **100% of spend allocated** to a team or cost center, so showback and chargeback become possible. Teams that see their own costs typically cut 10–20% on their own (typical estimate from FinOps practice; results vary).

## Notes
- The Config rule needs an AWS Config recorder already running in the account and region.
- AWS Config `required-tags` supports at most 6 keys; the module checks this.
- Remember to **activate** the tag keys as cost allocation tags in the Billing console, or they won't show in Cost Explorer.

<!-- BEGIN_TF_DOCS -->
## Inputs
| Name | Description | Type | Default |
|---|---|---|---|
| required_tags | Tag keys mapped to allowed values (`[]` = any value), 1–6 keys | map(list(string)) | Owner, Environment, CostCenter |
| create_config_rule | Create the Config `required-tags` rule | bool | `true` |
| config_resource_types | Resource types to evaluate (`[]` = all) | list(string) | EC2, EBS, RDS, S3, Lambda, DynamoDB |
| create_tag_policy | Create an Organizations tag policy | bool | `false` |
| tag_policy_target_ids | Root, OU or account IDs to attach the policy to | list(string) | `[]` |
| enforce_for_resource_types | Block non-compliant values for these types (for example `ec2:instance`) | list(string) | `[]` |
| name_prefix | Prefix for resource names | string | `"finops"` |
| tags | Tags for taggable resources | map(string) | `{}` |

## Outputs
| Name | Description |
|---|---|
| config_rule_arn | Config rule ARN, or `null` |
| tag_policy_id | Tag policy ID, or `null` |
| tag_policy_json | Rendered tag policy, for review |
<!-- END_TF_DOCS -->

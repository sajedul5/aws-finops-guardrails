variable "name_prefix" {
  description = "Prefix for the tag policy and Config rule names."
  type        = string
  default     = "finops"
}

variable "required_tags" {
  description = "Tag keys every resource must carry, with optional allowed values (empty list = any value). AWS Config supports at most 6 keys."
  type        = map(list(string))
  default = {
    Owner       = []
    Environment = ["prod", "staging", "dev", "test"]
    CostCenter  = []
  }

  validation {
    condition     = length(var.required_tags) >= 1 && length(var.required_tags) <= 6
    error_message = "required_tags must contain between 1 and 6 keys (AWS Config required-tags limit)."
  }
}

variable "create_config_rule" {
  description = "Create the AWS Config required-tags rule. Requires an AWS Config recorder in the account/region."
  type        = bool
  default     = true
}

variable "config_resource_types" {
  description = "Resource types the Config rule evaluates. Empty list = all supported types."
  type        = list(string)
  default = [
    "AWS::EC2::Instance",
    "AWS::EC2::Volume",
    "AWS::RDS::DBInstance",
    "AWS::S3::Bucket",
    "AWS::Lambda::Function",
    "AWS::DynamoDB::Table",
  ]
}

variable "create_tag_policy" {
  description = "Create an AWS Organizations tag policy. Run only from the management (or delegated admin) account."
  type        = bool
  default     = false
}

variable "tag_policy_target_ids" {
  description = "Organization root, OU or account IDs to attach the tag policy to."
  type        = list(string)
  default     = []
}

variable "enforce_for_resource_types" {
  description = "Resource types where non-compliant tag VALUES are blocked at create time (for example \"ec2:instance\"). Empty = report only."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags applied to every taggable resource."
  type        = map(string)
  default     = {}
}

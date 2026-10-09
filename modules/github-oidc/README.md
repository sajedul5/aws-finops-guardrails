# github-oidc

Lets GitHub Actions run Terraform against AWS **without storing any AWS keys**. GitHub proves its identity to AWS with a signed OIDC token and gets credentials that expire after 1 hour. Nothing long-lived can leak.

## What it creates
| Resource | Who can use it | Permissions |
|---|---|---|
| GitHub OIDC identity provider | (one per AWS account) | — |
| **plan role** | Pull requests and `main` of **one repo** | `ReadOnlyAccess`, plus state read and lock file if `state_bucket_name` is set |
| **apply role** | Only jobs running in the GitHub **`production` environment** of that repo | **Nothing by default.** You grant exactly what your Terraform needs. |

Security built in:
- **One repository only.** Wildcards like `owner/*` are rejected at plan time.
- **The audience is pinned** to `sts.amazonaws.com`.
- **The apply role uses an exact match** (`StringEquals`) on the environment. In GitHub, add **required reviewers** to that environment, so every deploy waits for a human approval.

## Usage
```hcl
module "github_oidc" {
  source = "github.com/sajedul5/aws-finops-guardrails//modules/github-oidc?ref=v0.1.0"

  github_repository = "sajedul5/aws-finops-guardrails"
  state_bucket_name = "my-terraform-state"
  apply_policy_arns = [aws_iam_policy.finops_deployer.arn] # least privilege, not AdministratorAccess
}
```
If the account already has a GitHub OIDC provider:
```hcl
  create_oidc_provider = false
  oidc_provider_arn    = "arn:aws:iam::111122223333:oidc-provider/token.actions.githubusercontent.com"
```

In the GitHub workflow:
```yaml
permissions:
  id-token: write   # required for OIDC
  contents: read

jobs:
  plan:
    runs-on: ubuntu-latest
    steps:
      - uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ vars.AWS_PLAN_ROLE_ARN }}
          aws-region: us-east-1

  deploy:
    runs-on: ubuntu-latest
    environment: production   # must match apply_environment; approval happens here
    steps:
      - uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ vars.AWS_APPLY_ROLE_ARN }}
          aws-region: us-east-1
```

## Benefit
- **No access keys to rotate, leak or offboard.** Leaked CI keys are one of the most common ways AWS accounts get compromised.
- **Every change is reviewed.** Plans run on every PR, and deploys need an approval in GitHub.
- **Audit trail.** CloudTrail shows the GitHub repo and workflow behind every action, through the role session.

Running cost: free. IAM and OIDC have no charge.

## Notes
- An AWS account can have only **one** provider for `token.actions.githubusercontent.com`. Use `create_oidc_provider = false` in every other stack.
- The plan role's `ReadOnlyAccess` can read most resource configuration. Narrow `plan_policy_arns` if that's too broad for you.

<!-- BEGIN_TF_DOCS -->
## Inputs
| Name | Description | Type | Default |
|---|---|---|---|
| github_repository | The one repo allowed, as `owner/name` | string | required |
| create_oidc_provider | Create the OIDC provider | bool | `true` |
| oidc_provider_arn | Existing provider ARN, when not creating one | string | `null` |
| plan_allowed_subjects | Subject suffixes trusted by the plan role | list(string) | `["pull_request", "ref:refs/heads/main"]` |
| plan_policy_arns | Plan role policies (short AWS-managed name or ARN) | list(string) | `["ReadOnlyAccess"]` |
| create_apply_role | Create the apply role | bool | `true` |
| apply_environment | GitHub environment the apply role is locked to | string | `"production"` |
| apply_policy_arns | Apply role policies (full ARNs) | list(string) | `[]` |
| state_bucket_name | Terraform state bucket | string | `null` |
| max_session_duration | Session length in seconds (3600 to 43200) | number | `3600` |
| name_prefix | Prefix for role names | string | `"finops"` |
| tags | Tags for taggable resources | map(string) | `{}` |

## Outputs
| Name | Description |
|---|---|
| oidc_provider_arn | OIDC provider ARN |
| plan_role_arn | Read-only plan role ARN |
| apply_role_arn | Apply role ARN, or `null` |
| allowed_subjects | Exact subjects each role trusts |
<!-- END_TF_DOCS -->

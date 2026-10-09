output "alert_topics" {
  description = "SNS topics to connect to Slack/Teams via AWS Chatbot."
  value = {
    budgets   = module.budgets.sns_topic_arn
    anomalies = module.cost_anomaly.sns_topic_arn
  }
}

output "scheduler" {
  description = "Off-hours scheduler: Lambda name, logs and the opt-in tag."
  value = {
    function   = module.offhours.lambda_function_name
    logs       = module.offhours.log_group_name
    opt_in_tag = module.offhours.opt_in_tag
  }
}

output "tag_policy_json" {
  description = "The rendered tag policy, for review before attaching it."
  value       = module.tag_enforcement.tag_policy_json
}

output "github_roles" {
  description = "Set these as GitHub repository variables AWS_PLAN_ROLE_ARN and AWS_APPLY_ROLE_ARN."
  value = var.github_repository == null ? null : {
    plan  = module.github_oidc[0].plan_role_arn
    apply = module.github_oidc[0].apply_role_arn
  }
}

plugin "aws" {
  enabled = true
  version = "0.24.1"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}

config {
  module = true
  force = false
  disabled_by_default = false
}

rule "terraform_deprecated_interpolation" {
  enabled = true
}

rule "terraform_deprecated_index" {
  enabled = true
}

rule "terraform_unused_declarations" {
  enabled = true
}

rule "terraform_comment_syntax" {
  enabled = true
}

rule "terraform_documented_outputs" {
  enabled = true
}

rule "terraform_documented_variables" {
  enabled = true
}

rule "terraform_typed_variables" {
  enabled = true
}

rule "terraform_module_pinned_source" {
  enabled = true
}

rule "terraform_naming_convention" {
  enabled = true
  format  = "snake_case"
}

rule "terraform_standard_module_structure" {
  enabled = true
}

rule "aws_instance_invalid_type" {
  enabled = true
}

rule "aws_instance_previous_type" {
  enabled = true
}

rule "aws_alb_invalid_security_group" {
  enabled = true
}

rule "aws_alb_invalid_subnet" {
  enabled = true
}

rule "aws_eks_cluster_invalid_version" {
  enabled = true
}

rule "aws_s3_bucket_invalid_region" {
  enabled = true
}

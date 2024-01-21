variable "aws_region" {
  description = "The AWS region to use"
  type        = string
  default     = "eu-west-1"
}

variable "aws_vpc" {
  description = "The AWS VPC name"
  type        = string
  default     = "saeed-app-vpc"
}

variable "availability_zone_public_a" {
  description = "The availability_zone for subnet public_a"
  type        = string
  default     = "eu-west-1a"
}

variable "availability_zone_public_b" {
  description = "The availability_zone for subnet public_b"
  type        = string
  default     = "eu-west-1b"
}

variable "availability_zone_public_c" {
  description = "The availability_zone for subnet public_c"
  type        = string
  default     = "eu-west-1c"
}

variable "aws_lb" {
  description = "The aws load balancer name"
  type        = string
  default     = "saeed-alb"
}

variable "aws_lb_target_group" {
  description = "The aws load balancer target group name"
  type        = string
  default     = "saeed-tg"
}

variable "instance-profile_role" {
  description = "The aws_iam_role name for role instance-profile_role"
  type        = string
  default     = "saeed-instance-profile_role"
}

variable "iam-instance-profile" {
  description = "The aws_iam_instance_profile name for iam-instance-profile"
  type        = string
  default     = "saeed-instance-profile"
}

variable "my_launch_template" {
  description = "The aws_launch_template name for my_launch_template"
  type        = string
  default     = "saeed_launch_template"
}

variable "my_asg" {
  description = "The aws_autoscaling_group name for my_asg"
  type        = string
  default     = "saeed_asg"
}

variable "codedeploy_app" {
  description = "The aws_codedeploy_app name for codedeploy_app"
  type        = string
  default     = "saeed-app"
}

variable "codedeploy_service_role" {
  description = "The aws_iam_role name for codedeploy_service_role"
  type        = string
  default     = "saeed-codedeploy-service-role"
}

variable "deployment_group" {
  description = "The aws_codedeploy_deployment_group name for deployment_group"
  type        = string
  default     = "saeed-deployment-group"
}

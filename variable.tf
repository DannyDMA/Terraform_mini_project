variable "region" {
  description = "AWS region for all resources"
  type        = string
  default     = "us-west-2"
}

variable "project_name" {
  description = "Project name used as a prefix for resources"
  type        = string
  default     = "terraform-asg-alb-project"
}

variable "instance_type" {
  description = "Instance type for the web servers"
  type        = string
  default     = "t2.micro"
}

variable "min_size" {
  description = "Minimum number of instances in the Auto Scaling group"
  type        = number
  default     = 2
}

variable "desired_capacity" {
  description = "Desired number of instances in the Auto Scaling group"
  type        = number
  default     = 2
}

variable "max_size" {
  description = "Maximum number of instances in the Auto Scaling group"
  type        = number
  default     = 3
}

variable "acm_certificate_arn" {
  description = "ARN of my ACM certificate"
  type        = string
}

variable "message" {
  description = "Message displayed on the Apache index page"
  type        = string
  default     = "LiquidDMA Musical To the World"
}
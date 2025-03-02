output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.alb.dns_name
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.alb.arn
}

output "asg_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.web_asg.name
}

output "target_group_arn" {
  description = "ARN of the target group used by the ALB"
  value       = aws_lb_target_group.tg.arn
}
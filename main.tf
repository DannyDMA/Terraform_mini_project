# Terraform & Backend
terraform {
  required_version = ">= 1.0"

  backend "s3" {
    bucket = "terraformdma"
    key    = "terraform-project/terraform.tfstate"
    region = "us-west-2"
    encrypt = true
  }
}

# Data Sources

# Default VPC
data "aws_vpc" "default" {
  default = true
}

#subnets in default VPC
data "aws_subnets" "default_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Latest Amazon Linux 2023 AMI
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

# Security Groups

# ALB security group – allow HTTPS from anywhere
resource "aws_security_group" "alb_sg" {
  name        = "${var.project_name}-alb-sg"
  description = "Allow HTTPS to ALB"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "HTTPS from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project_name}-alb-sg"
    Project = var.project_name
  }
}

# ASG instances security group – allow HTTP(80) only from ALB
resource "aws_security_group" "asg_sg" {
  name        = "${var.project_name}-asg-sg"
  description = "Allow HTTP from ALB"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description     = "HTTP from ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "${var.project_name}-asg-sg"
    Project = var.project_name
  }
}

# Application Load Balancer + Target Group

resource "aws_lb" "alb" {
  name               = "${var.project_name}-alb"
  load_balancer_type = "application"
  internal           = false
  subnets            = data.aws_subnets.default_subnets.ids
  security_groups    = [aws_security_group.alb_sg.id]

  tags = {
    Name    = "${var.project_name}-alb"
    Project = var.project_name
  }
}

resource "aws_lb_target_group" "tg" {
  name     = "${var.project_name}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }

  tags = {
    Name    = "${var.project_name}-tg"
    Project = var.project_name
  }
}

# HTTPS listener on port 443
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.acm_certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

# Launch Template (Amazon Linux 2023 + Apache)

resource "aws_launch_template" "web_lt" {
  name_prefix   = "${var.project_name}-lt-"
  image_id      = data.aws_ami.al2023.id
  instance_type = var.instance_type

  vpc_security_group_ids = [aws_security_group.asg_sg.id]

  user_data = base64encode(<<-EOF
    #!/bin/bash
    set -xe
    dnf update -y
    dnf install -y httpd
    systemctl enable httpd
    systemctl start httpd
    echo "<h1>${var.message} - $(hostname)</h1>" > /var/www/html/index.html
  EOF
  )

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name    = "${var.project_name}-web"
      Project = var.project_name
    }
  }
}

# Auto Scaling Group

resource "aws_autoscaling_group" "web_asg" {
  name                      = "${var.project_name}-asg"
  max_size                  = var.max_size
  min_size                  = var.min_size
  desired_capacity          = var.desired_capacity
  vpc_zone_identifier       = data.aws_subnets.default_subnets.ids
  health_check_type         = "ELB"
  health_check_grace_period = 300
  target_group_arns         = [aws_lb_target_group.tg.arn]

  launch_template {
    id      = aws_launch_template.web_lt.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${var.project_name}-web"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}
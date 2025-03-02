region       = "us-west-2"
project_name = "terraform-asg-alb-project"

instance_type    = "t2.micro"
min_size         = 2
desired_capacity = 2
max_size         = 4

acm_certificate_arn = "arn:aws:acm:us-west-2:867468445868:certificate/92e1fa0b-b4c6-495c-bfaf-7fa4210406a4"

message = "LiquidDMA Musical To the World"
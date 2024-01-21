terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "4.49.0"
    }
  }
}

provider "aws" {
  region     = var.aws_region
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  
  tags = {
    Name = var.aws_vpc
  }
}

resource "aws_subnet" "public_a" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  availability_zone = var.availability_zone_public_a

  tags = {
    Name = "public_a"
  }
}

resource "aws_subnet" "public_b" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.2.0/24"
  availability_zone = var.availability_zone_public_b

  tags = {
    Name = "public_b"
  }
}

resource "aws_subnet" "public_c" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.3.0/24"
  availability_zone = var.availability_zone_public_c

  tags = {
    Name = "public_c"
  }
}

resource "aws_internet_gateway" "main-igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main-igw"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main-igw.id
  }

  tags = {
    Name = "public_rt"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "c" {
  subnet_id      = aws_subnet.public_c.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_security_group" "my_sg" {
  name        = "my-sg"
  vpc_id      = aws_vpc.main.id

  ingress {
    description      = "Allow http from everywhere"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "Allow http from everywhere"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    description      = "Allow outgoing traffic"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "my-sg"
  }
}

resource "aws_lb" "my_alb" {
  name               = var.aws_lb
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.my_sg.id]
  subnets            = [aws_subnet.public_a.id, aws_subnet.public_b.id, aws_subnet.public_c.id]
}

resource "aws_lb_listener" "my_lb_listener" {
  load_balancer_arn = aws_lb.my_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.my_tg.arn
  }
}

resource "aws_lb_target_group" "my_tg" {
  # name     = "saeed-tg"
  name     = var.aws_lb_target_group
  target_type = "instance"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
}

resource "aws_iam_role" "instance-profile_role" {
  name = var.instance-profile_role

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "instance-profile_role_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforAWSCodeDeploy"
  role       = aws_iam_role.instance-profile_role.name
}

resource "aws_iam_role_policy_attachment" "instance-profile_role_policy_attachment2" {
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeDeployFullAccess"
  role       = aws_iam_role.instance-profile_role.name
}

resource "aws_iam_role_policy_attachment" "instance-profile_role_policy_attachment3" {
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeDeployDeployerAccess"
  role       = aws_iam_role.instance-profile_role.name
}


resource "aws_iam_instance_profile" "iam-instance-profile" {
  name = var.iam-instance-profile
  role = aws_iam_role.instance-profile_role.name
}
resource "aws_launch_template" "my_launch_template" {
  name = var.my_launch_template
  
  image_id = "ami-05147510eb2885c80"
  instance_type = "t2.nano"
  key_name = "saeed_ubuntu"
  
  user_data = filebase64("${path.module}/server.sh")

  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_size = 8
      volume_type = "gp2"
    }
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups = [aws_security_group.my_sg.id]
  }
  iam_instance_profile {
    name = aws_iam_instance_profile.iam-instance-profile.name
  }
}

resource "aws_autoscaling_group" "my_asg" {
  name                      = var.my_asg
  max_size                  = 5
  min_size                  = 2
  health_check_type         = "ELB"
  desired_capacity          = 2
  target_group_arns = [aws_lb_target_group.my_tg.arn]

  vpc_zone_identifier       = [aws_subnet.public_a.id, aws_subnet.public_b.id, aws_subnet.public_c.id]
  
  launch_template {
    id      = aws_launch_template.my_launch_template.id
    version = "$Latest"
  }
}

resource "aws_autoscaling_policy" "scale_up" {
  name                   = "scale_up"
  policy_type            = "SimpleScaling"
  autoscaling_group_name = aws_autoscaling_group.my_asg.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = "1"    # add one instance
  cooldown               = "300"  # cooldown period after scaling
}

resource "aws_cloudwatch_metric_alarm" "scale_up_alarm" {
  alarm_name          = "scale-up-alarm"
  alarm_description   = "asg-scale-up-cpu-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "50"
  dimensions = {
    "AutoScalingGroupName" = aws_autoscaling_group.my_asg.name
  }
  actions_enabled = true
  alarm_actions   = [aws_autoscaling_policy.scale_up.arn]
}

resource "aws_autoscaling_policy" "scale_down" {
  name                   = "asg-scale-down"
  autoscaling_group_name = aws_autoscaling_group.my_asg.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = "-1"
  cooldown               = "300"
  policy_type            = "SimpleScaling"
}

resource "aws_cloudwatch_metric_alarm" "scale_down_alarm" {
  alarm_name          = "asg-scale-down-alarm"
  alarm_description   = "asg-scale-down-cpu-alarm"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "30"
  dimensions = {
    "AutoScalingGroupName" = aws_autoscaling_group.my_asg.name
  }
  actions_enabled = true
  alarm_actions   = [aws_autoscaling_policy.scale_down.arn]
}

# Create the CodeDeploy application
resource "aws_codedeploy_app" "codedeploy_app" {
  # name = "saeed-app"
  name = var.codedeploy_app
  compute_platform = "Server"
}

resource "aws_iam_role" "codedeploy_service_role" {
  name = var.codedeploy_service_role

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "codedeploy.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "codedeploy_service_role_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
  role       = aws_iam_role.codedeploy_service_role.name
}

resource "aws_iam_role_policy_attachment" "codedeploy_service_role_policy_attachment2" {
  policy_arn = "arn:aws:iam::aws:policy/AutoScalingFullAccess"
  role       = aws_iam_role.codedeploy_service_role.name
}

resource "aws_iam_role_policy_attachment" "codedeploy_service_role_policy_attachment3" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
  role       = aws_iam_role.codedeploy_service_role.name
}

resource "aws_iam_role_policy_attachment" "codedeploy_service_role_policy_attachment4" {
  policy_arn = "arn:aws:iam::aws:policy/IAMFullAccess"
  role       = aws_iam_role.codedeploy_service_role.name
}

resource "aws_iam_role_policy_attachment" "codedeploy_service_role_policy_attachment5" {
  policy_arn = "arn:aws:iam::aws:policy/AWSCodeDeployFullAccess"
  role       = aws_iam_role.codedeploy_service_role.name
}

# Create the CodeDeploy deployment group
resource "aws_codedeploy_deployment_group" "deployment_group" {
  app_name = aws_codedeploy_app.codedeploy_app.name
  deployment_group_name = var.deployment_group

  service_role_arn       = aws_iam_role.codedeploy_service_role.arn
  autoscaling_groups    = [aws_autoscaling_group.my_asg.name]

  # Specify the deployment settings
  deployment_config_name = "CodeDeployDefault.AllAtOnce"
  auto_rollback_configuration {
    enabled = true
    events = ["DEPLOYMENT_FAILURE"]
  }
}

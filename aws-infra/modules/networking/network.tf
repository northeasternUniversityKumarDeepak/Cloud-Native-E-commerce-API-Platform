# Create a VPC
resource "aws_vpc" "my_vpc" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.profile}-vpc"
  }
}

# Create Public subnets
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.my_vpc.id
  count                   = length(var.public_subnets_cidr)
  cidr_block              = var.public_subnets_cidr[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "public subnet-${count.index + 0}"
  }
}

# Create Private subnets
resource "aws_subnet" "private_subnet" {
  vpc_id                  = aws_vpc.my_vpc.id
  count                   = length(var.private_subnets_cidr)
  cidr_block              = var.private_subnets_cidr[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name = "private subnet-${count.index + 0}"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "internet gateway"
  }
}

# Create Public Route table
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "public route table"
  }
}

# Create Private Route table
resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "private route table"
  }
}

# Create Public Route Table Assocation
resource "aws_route_table_association" "public_assoc" {
  count          = length(var.public_subnets_cidr)
  subnet_id      = aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.public_route_table.id
}

# Create Private Route Table Assocation
resource "aws_route_table_association" "private_assoc" {
  count          = length(var.private_subnets_cidr)
  subnet_id      = aws_subnet.private_subnet[count.index].id
  route_table_id = aws_route_table.private_route_table.id
}

# Create Public Route
resource "aws_route" "public_route" {
  route_table_id         = aws_route_table.public_route_table.id
  destination_cidr_block = var.destination_cidr_block
  gateway_id             = aws_internet_gateway.internet_gateway.id
}

# Create Security group
resource "aws_security_group" "application_sg" {
  name        = "application-sg"
  description = "Security group for EC2 instance with web application"
  vpc_id      = aws_vpc.my_vpc.id
  depends_on  = [aws_vpc.my_vpc]

  ingress {
    protocol        = "tcp"
    from_port       = "22"
    to_port         = "22"
    security_groups = [aws_security_group.loadbalancer_sg.id]
  }
  # ingress {
  #   protocol    = "tcp"
  #   from_port   = "80"
  #   to_port     = "80"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }
  # ingress {
  #   protocol    = "tcp"
  #   from_port   = "443"
  #   to_port     = "443"
  #   cidr_blocks = ["0.0.0.0/0"]
  # }

  ingress {
    protocol        = "tcp"
    from_port       = "3000"
    to_port         = "3000"
    security_groups = [aws_security_group.loadbalancer_sg.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    "Name" = "application-sg"
  }
}

# Create EC2 instance

# resource "aws_instance" "ec2" {
#   ami                     = var.ami
#   instance_type           = var.instance_type
#   subnet_id               = aws_subnet.public_subnet[0].id
#   key_name                = var.key_name
#   security_groups         = [aws_security_group.application_sg.id]
#   disable_api_termination = false
#   iam_instance_profile    = aws_iam_instance_profile.app_instance_profile.name
#   ebs_block_device {
#     device_name           = "/dev/xvda"
#     volume_type           = var.instance_vol_type
#     volume_size           = var.instance_vol_size
#     delete_on_termination = true
#   }
#   #   code for the user data
#   user_data = <<EOF

# #!/bin/bash

# echo "export DB_USER=${var.database_username} " >> /home/ec2-user/webapp/.env
# echo "export DB_PASSWORD=${var.database_password} " >> /home/ec2-user/webapp/.env
# echo "export DB_PORT=${var.port} " >> /home/ec2-user/webapp/.env
# echo "export DB_HOST=$(echo ${aws_db_instance.db_instance.endpoint} | cut -d: -f1)" >> /home/ec2-user/webapp/.env
# echo "export DB_NAME=${var.database_name} " >> /home/ec2-user/webapp/.env
# echo "export BUCKET_NAME=${aws_s3_bucket.mybucket.bucket} " >> /home/ec2-user/webapp/.env
# echo "export BUCKET_REGION=${var.region} " >> /home/ec2-user/webapp/.env
# sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
# -a fetch-config \
# -m ec2 \
# -c file:/home/ec2-user/webapp/packer/cloudwatch-config.json \
# -s
# sudo chmod +x setenv.sh
# sh setenv.sh
# sudo systemctl restart webapp.service
#  EOF

#   tags = {
#     "Name" = "ec2"
#   }
# }

#Create database security group
resource "aws_security_group" "database" {
  name        = "database"
  description = "Security group for RDS instance for database"
  vpc_id      = aws_vpc.my_vpc.id
  ingress {
    protocol        = "tcp"
    from_port       = "3306"
    to_port         = "3306"
    security_groups = [aws_security_group.application_sg.id]
  }

  tags = {
    "Name" = "database-sg"
  }
}


resource "random_id" "id" {
  byte_length = 8
}
#Create s3 bucket
resource "aws_s3_bucket" "mybucket" {
  bucket        = "mywebappbucket-${random_id.id.hex}"
  acl           = "private"
  force_destroy = true
  lifecycle_rule {
    id      = "StorageTransitionRule"
    enabled = true
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
  }
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

}

resource "aws_s3_bucket_public_access_block" "s3bucketPrivate" {
  bucket                  = aws_s3_bucket.mybucket.id
  ignore_public_acls      = true
  restrict_public_buckets = true
  block_public_acls       = true
  block_public_policy     = true
}

#Create iam policy to accress s3
resource "aws_iam_policy" "WebAppS3_policy" {
  name = "WebAppS3"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
        ]
        Resource = "arn:aws:s3:::${aws_s3_bucket.mybucket.bucket}/*"
        Resource = "arn:aws:s3:::${aws_s3_bucket.mybucket.bucket}/*"
      }
    ]
  })
}

#Create iam role for ec2 to access s3
resource "aws_iam_role" "WebAppS3_role" {
  name = "EC2-CSYE6225"
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

#Create iam role policy attachment
resource "aws_iam_role_policy_attachment" "WebAppS3_role_policy_attachment" {
  role       = aws_iam_role.WebAppS3_role.name
  policy_arn = aws_iam_policy.WebAppS3_policy.arn
}

#attach iam role to ec2 instance
resource "aws_iam_instance_profile" "app_instance_profile" {
  name = "app_instance_profile"
  role = aws_iam_role.WebAppS3_role.name
}

#Create Rds subnet group
resource "aws_db_subnet_group" "db_subnet_group" {
  name        = "db_subnet_group"
  description = "RDS subnet group for database"
  subnet_ids  = aws_subnet.private_subnet.*.id
  tags = {
    Name = "db_subnet_group"
  }
}

#Create Rds parameter group
resource "aws_db_parameter_group" "db_parameter_group" {
  name        = "db-parameter-group"
  family      = "mysql8.0"
  description = "RDS parameter group for database"
  parameter {
    name  = "character_set_server"
    value = "utf8"
  }
}

#Create Rds instance
resource "aws_db_instance" "db_instance" {
  identifier                = var.db_identifier
  engine                    = "mysql"
  engine_version            = "8.0.28"
  instance_class            = "db.t3.micro"
  name                      = var.database_name
  username                  = var.database_username
  password                  = var.database_password
  parameter_group_name      = aws_db_parameter_group.db_parameter_group.name
  allocated_storage         = 20
  storage_type              = "gp2"
  multi_az                  = false
  skip_final_snapshot       = true
  final_snapshot_identifier = "final-snapshot"
  publicly_accessible       = false
  db_subnet_group_name      = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids    = [aws_security_group.database.id]
  storage_encrypted         = true
  kms_key_id                = aws_kms_key.rds_key.arn


  tags = {
    Name = "db_instance"
  }
}

#Fetch Hosted Zone

data "aws_route53_zone" "hosted_zone" {
  name = "${var.profile}.${var.root_domain}"
}

# Create Record
resource "aws_route53_record" "app_record" {
  zone_id = data.aws_route53_zone.hosted_zone.zone_id
  name    = "${var.profile}.${var.root_domain}"
  type    = "A"
  alias {
    name                   = aws_lb.app_lb.dns_name
    zone_id                = aws_lb.app_lb.zone_id
    evaluate_target_health = true
  }
}

resource "aws_cloudwatch_log_group" "csye6225" {
  name = "csye6225"
}


# cloudwatch_policy attached to ec2 role

resource "aws_iam_role_policy_attachment" "cloudwatch_policy" {
  role       = aws_iam_role.WebAppS3_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Load Balancer Security Groups

resource "aws_security_group" "loadbalancer_sg" {
  name        = "loadbalancer_sg"
  description = "Allow TCP traffic on ports"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "loadbalancer_sg"
  }
}

# Launch Configuration

resource "aws_launch_template" "my_template" {
  name          = "my_template"
  image_id      = var.ami
  instance_type = var.instance_type
  key_name      = var.key_name
  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.application_sg.id]
  }

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_type           = var.instance_vol_type
      volume_size           = var.instance_vol_size
      delete_on_termination = true
      encrypted             = true
      kms_key_id            = aws_kms_key.ebs_key.arn
    }
  }
  iam_instance_profile {
    name = aws_iam_instance_profile.app_instance_profile.name
  }
  lifecycle {
    create_before_destroy = true
  }
  user_data = base64encode(
    <<-EOF
    #!/bin/bash
    echo "export DB_USER=${var.database_username} " >> /home/ec2-user/webapp/.env
		echo "export DB_PASSWORD=${var.database_password} " >> /home/ec2-user/webapp/.env
		echo "export DB_PORT=${var.port} " >> /home/ec2-user/webapp/.env
		echo "export DB_HOST=$(echo ${aws_db_instance.db_instance.endpoint} | cut -d: -f1)" >> /home/ec2-user/webapp/.env
		echo "export DB_NAME=${var.database_name} " >> /home/ec2-user/webapp/.env
		echo "export BUCKET_NAME=${aws_s3_bucket.mybucket.bucket} " >> /home/ec2-user/webapp/.env
		echo "export BUCKET_REGION=${var.region} " >> /home/ec2-user/webapp/.env
		sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
		-a fetch-config \
		-m ec2 \
		-c file:/home/ec2-user/webapp/packer/cloudwatch-config.json \
		-s
		sudo chmod +x setenv.sh
		sh setenv.sh
		sudo systemctl restart webapp.service
EOF
  )

}

# Target groups

resource "aws_lb_target_group" "lb_tg" {
  name                 = "lb-tg"
  port                 = 3000
  protocol             = "HTTP"
  target_type          = "instance"
  vpc_id               = aws_vpc.my_vpc.id
  deregistration_delay = 30

  health_check {
    path    = "/healthz"
    matcher = 200
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "autoscaling_group" {
  name             = "autoscaling_group"
  default_cooldown = 60
  launch_template {
    id      = aws_launch_template.my_template.id
    version = "$Latest"
  }
  min_size            = 1
  max_size            = 3
  desired_capacity    = 1
  vpc_zone_identifier = aws_subnet.public_subnet.*.id
  target_group_arns   = [aws_lb_target_group.lb_tg.arn]

  health_check_type = "EC2"

  tag {
    key                 = "Name"
    value               = "ec2"
    propagate_at_launch = true
  }
}


# Autoscaling scale up policy

# resource "aws_autoscaling_policy" "scaleup_policy" {
#   name                   = "scaleup_policy"
#   autoscaling_group_name = aws_autoscaling_group.autoscaling_group.name
#   adjustment_type        = "ChangeInCapacity"
#   policy_type            = "TargetTrackingScaling"

#   target_tracking_configuration {

#     predefined_metric_specification {
#       predefined_metric_type = "ASGAverageCPUUtilization"
#     }
#     target_value = 5.0
#   }
# }

resource "aws_autoscaling_policy" "scaleup_policy" {
  name                   = "scaleup_policy"
  autoscaling_group_name = aws_autoscaling_group.autoscaling_group.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = 1
  cooldown               = 60

}

# scaling up metric
resource "aws_cloudwatch_metric_alarm" "high_alarm" {
  alarm_name          = "high_alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "5"
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.autoscaling_group.name
  }
  alarm_description = "Alarm if average CPU usage is above 5%"
  alarm_actions     = [aws_autoscaling_policy.scaleup_policy.arn]

}

# Autoscaling scale down policy

# resource "aws_autoscaling_policy" "scaledown_policy" {
#   name                   = "scaledown_policy"
#   autoscaling_group_name = aws_autoscaling_group.autoscaling_group.name
#   adjustment_type        = "ChangeInCapacity"
#   policy_type            = "TargetTrackingScaling"

#   target_tracking_configuration {

#     predefined_metric_specification {
#       predefined_metric_type = "ASGAverageCPUUtilization"
#     }
#     target_value = 3.0
#   }
# }

resource "aws_autoscaling_policy" "scaledown_policy" {
  name                   = "scaledown_policy"
  autoscaling_group_name = aws_autoscaling_group.autoscaling_group.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = -1
  cooldown               = 60

}

# scaling down metric
resource "aws_cloudwatch_metric_alarm" "low_alarm" {
  alarm_name          = "low_alarm"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "3"
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.autoscaling_group.name
  }
  alarm_description = "Alarm if average CPU usage is below 3%"
  alarm_actions     = [aws_autoscaling_policy.scaledown_policy.arn]

}

# Load balancer

resource "aws_lb" "app_lb" {
  name               = "app-lb"
  internal           = false
  load_balancer_type = "application"
  ip_address_type    = "ipv4"
  security_groups    = [aws_security_group.loadbalancer_sg.id]
  subnets            = aws_subnet.public_subnet.*.id

  tags = {
    "Name" = "app_lb"
  }
}
# ACM Cerificate

data "aws_acm_certificate" "ssl_certificate" {
  domain   = "${var.profile}.${var.root_domain}"
  types = ["IMPORTED"] #AMAZON_ISSUED for dev and IMPORTED for prod
  statuses = ["ISSUED"]
}

# Load balancer listener

resource "aws_lb_listener" "loadbalancer_listener" {
  load_balancer_arn = aws_lb.app_lb.arn
  port              = 443
  protocol          = "HTTPS"
  certificate_arn   = data.aws_acm_certificate.ssl_certificate.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lb_tg.arn
  }
}

resource "aws_kms_key" "ebs_key" {
  description             = " A symmetric KMS key for EBS"
  deletion_window_in_days = 10
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Allow IAM user permissions"
        Effect = "Allow"
        Principal = {
          AWS = [
            "arn:aws:iam::${var.aws_account_number}:root",
          ]
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow access for Key Administrators"
        Effect = "Allow"
        Principal = {
          AWS = [
            "arn:aws:iam::${var.aws_account_number}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling",
          ]
        }
        Action = [
          "kms:Create*",
          "kms:Describe*",
          "kms:Enable*",
          "kms:List*",
          "kms:Put*",
          "kms:Update*",
          "kms:Revoke*",
          "kms:Disable*",
          "kms:Get*",
          "kms:Delete*",
          "kms:TagResource",
          "kms:UntagResource",
          "kms:ScheduleKeyDeletion",
          "kms:CancelKeyDeletion",
        ]
        Resource = "*"
      },
      {
        Sid    = "Allow use of the key"
        Effect = "Allow"
        Principal = {
          AWS = [
            "arn:aws:iam::${var.aws_account_number}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling",
          ]
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey",
        ]
        Resource = "*"
      },
    ]
  })
}

resource "aws_kms_alias" "ebs_key_alias" {
  name          = "alias/ebsKey"
  target_key_id = aws_kms_key.ebs_key.id
}

resource "aws_kms_key" "rds_key" {
  description             = " A symmetric KMS key for RDS"
  deletion_window_in_days = 10
  policy = jsonencode({
    Version = "2012-10-17"
    Id      = "kms-key-for-rds"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.aws_account_number}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow access for Key Administrators"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.aws_account_number}:role/aws-service-role/rds.amazonaws.com/AWSServiceRoleForRDS"
        }
        Action = [
          "kms:Create*",
          "kms:Describe*",
          "kms:Enable*",
          "kms:List*",
          "kms:Put*",
          "kms:Update*",
          "kms:Revoke*",
          "kms:Disable*",
          "kms:Get*",
          "kms:Delete*",
          "kms:TagResource",
          "kms:UntagResource",
          "kms:ScheduleKeyDeletion",
          "kms:CancelKeyDeletion"
        ]
        Resource = "*"
      },
      {
        Sid    = "Allow use of the key"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.aws_account_number}:role/aws-service-role/rds.amazonaws.com/AWSServiceRoleForRDS"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "arn:aws:rds:${var.region}:${var.aws_account_number}:db:*"
      }
    ]
  })
}

resource "aws_kms_alias" "rds_key_alias" {
  name          = "alias/rdsKey"
  target_key_id = aws_kms_key.rds_key.id
}

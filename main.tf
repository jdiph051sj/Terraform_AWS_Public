#Configuring an AWS provider-plugin

provider "aws" {
  #Ommited the version as it is optional, terraform will download the latest
  #region = "us-east-1" #Using N.Virginia as our DC
  region     = var.region
  access_key = "AKIAW3MECY7VHFBC3WQF"
  secret_key = "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"

}

#Setup a S3 bucket and Dynamo_DB table back-end configuration to store the state file and state lock remotely

#terraform {
#       backend "s3" {
#       bucket = "mys3bucketremote"
#       region = "us-east-1"
#       key    = "s3remotestate"
#       dynamodb_table = "mystatelock"
#}
#}

#Create a VPC with a cidr_block range of 10.0.0.0/16

resource "aws_vpc" "my_vpc" {

  #Network to be used for my_vpc
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "my_vpc"
  }
}


#Create 3 subnets within the "my_vpc" in 2 different AZ's. Public, Private and Data subnets
#Subnet - everytime we create a subnet we need to /assign/associate/attach it to a route table

#Public_Subnet

resource "aws_subnet" "public_subnet_1" {

  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "public_subnet_1"
  }

}

#Private_Subnet

resource "aws_subnet" "private_subnet_1" {

  vpc_id = aws_vpc.my_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1c"


  tags = {
    Name = "private_subnet_1"
  }
}

#Data_Subnet

resource "aws_subnet" "data_subnet_1" {

  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1c"


  tags = {
    Name = "data_subnet_1"
  }
}

#Create Nginx Webserver and bootstrap/install/enable a Nginx webserver

resource "aws_instance" "my_nginx_webserver" {
  ami               = "ami-04b70fa74e45c3917"
  instance_type     = "t2.micro"
  availability_zone = "us-east-1c"
  count             = 1
  #subnet_id = aws_instance.my_nginx_webserver[count.index]
  subnet_id = aws_subnet.private_subnet_1.id
  key_name  = "key_pair"

  user_data = <<-EOF

                #!/bin/bash
                sudo apt update -y
                sudo apt install nginx -y
                sudo systemctl start nginx
                sudo bash -c 'echo Hello MyNginx-WebServer > /var/www/html/index.html'
                EOF

  tags = {
    Name = "nginx_webserver"
  }
}

#Create Security Group for the EC2 instance

resource "aws_security_group" "my_sg_ec2" {

  vpc_id = aws_vpc.my_vpc.id


  tags = {
    Name = "my_sg_ec2"
  }

}

#Create the Security Group rule to open main port:8080 from the ALB to the EC2 instance

resource "aws_security_group_rule" "my_sg_ec2_ingress" {

  type                     = "ingress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  security_group_id        = aws_security_group.my_sg_ec2.id
  source_security_group_id = aws_security_group.my_sg_alb.id

}

#Create Security Group rule to open port:8081 for the health checks

resource "aws_security_group_rule" "my_sg_health_check_ec2" {

  type                     = "ingress"
  from_port                = 8081
  to_port                  = 8081
  protocol                 = "tcp"
  security_group_id        = aws_security_group.my_sg_ec2.id
  source_security_group_id = aws_security_group.my_sg_alb.id

}

#Create Security Group for the Application Load Balancer

resource "aws_security_group" "my_sg_alb" {

  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "my_sg_alb"
  }

}

#Create FireWall rules for the Application Load Balancer

resource "aws_security_group_rule" "my_sg_alb_ingress" {

  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  security_group_id        = aws_security_group.my_sg_ec2.id
  #source_security_group_id = aws_security_group.my_sg_alb.id
  cidr_blocks = ["0.0.0.0/0"]

}

#Create/open Firewall/Egress rules to redirect the requests to the EC2 instance

resource "aws_security_group_rule" "my_sg_alb_egress" {

  type                     = "egress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.my_sg_ec2.id
  security_group_id        = aws_security_group.my_sg_alb.id
  #cidr_blocks = ["0.0.0.0/0"]

}

##Create Security Group rule to open port:8081 for the health checks

#resource "aws_security_group_rule" "my_sg_health_check_alb" {

# type                     = "egress"
# from_port                = 8081
# to_port                  = 8081
# protocol                 = "tcp"
# source_security_group_id = aws_security_group.my_sg_ec2.id
# security_group_id       = aws_security_group.my_sg_alb.id

#}

#Create Target Group for the ALB to distribute traffic to the application

resource "aws_lb_target_group" "my_nginx_webserver_tg" {


  port = 8080
  protocol = "HTTP"
  vpc_id = aws_vpc.my_vpc.id
slow_start = 0
  load_balancing_algorithm_type = "round_robin"

  stickiness {

    enabled = true
    type = "lb_cookie"
}

#Do the health checks on the EC2 instance and if it fails ALB will remove it from the pool
  health_check {

    enabled = true
    port = 8081
    interval = 30
    protocol = "HTTP"
    path = "/health"
    matcher = "200"
    healthy_threshold = 3
    unhealthy_threshold = 3

}

}

#Manually register the EC2 instance to the  Target Group

resource "aws_lb_target_group" "my_lb_tg" {

  vpc_id = aws_vpc.my_vpc.id
  port = 8080
  protocol = "HTTP"

}

#Create an Application Load Balancer

#resource "aws_lb" "my_lb" {
  #name = "my_nginx_webserver_lb"
  #internal = false
# load_balancer_type = "application"
  #security_groups = [aws_security_group.my_sg_alb.id]

  #access_logs {

   # bucket = "mys3bucketremote"
   # prefix = "my_app_lb"
  #  enabled = true
#}

  #subnet_mapping {
#       aws_subnet.private_subnet_1.id

# }
#}



#Craete a listener for an ALB to accept incoming request

#resource "aws_lb_listener" "my_lb_listener_http" {

# load_balancer_arn = aws_lb.my_lb.arn
  #port = "80"
  #protocol = "HTTP"

  ##Default action to route traffic
  #default_action {

   # type = "forward"
   # target_group_arn = aws_lb_target_group.my_nginx_webserver_tg.arn
#}
#}

#Create a custom domain and obtain a TLS certificate using Route53 zone

#data "aws_route53_zone" "my_public_domain" {

#       name = "devopsengineering.com"
#       private_zone = false

#}

#Create

#resource "aws_acm_certificate" "my_tls_cert" {

#       domain_name = "my_tls_cert.devopsengineering.com"
#       validation_method = "DNS"

#}

### ---Testing my public subnet--- ###

resource "aws_instance" "my_nginx_webserver_pub" {
  ami               = "ami-04b70fa74e45c3917"
  instance_type     = "t2.micro"
  availability_zone = "us-east-1b"
  count             = 1
  #subnet_id = aws_instance.my_nginx_webserver[count.index]
  subnet_id = aws_subnet.public_subnet_1.id
key_name  = "key_pair"
  #vpc_id = aws_instance.my_nginx_webserver.vpc_id
  #vpc_security_group_ids = aws_instance.my_nginx_webserver.vpc_security_group_ids
  #name = aws_security_group.my_sg.name
  associate_public_ip_address = true

  user_data = <<-EOF

                #!/bin/bash
                sudo apt update -y
                sudo apt install nginx -y
                sudo systemctl start nginx
                sudo bash -c 'echo Hello MyNginx-WebServer > /var/www/html/index.html'
                EOF

  tags = {
    Name = "nginx_webserver_pub"
  }

}

#Create Security Group for my public subnet

resource "aws_security_group" "my_sg_pub" {
  description = "SSH on port:22"
  vpc_id      = aws_vpc.my_vpc.id
  #        subnet_id  = aws_subnet.public_subnet_1.id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    #               cidr_blocks = ["0.0.0.0/0"]

  }

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


  tags = {
    Name = "my_sg_pub"
  }

}

# create security group for the application load balancer

resource "aws_security_group" "public_lb_security_group" {
  name        = "public lb security group"
  description = "enable http/https access on port 80/443"
  vpc_id      = var.vpc_id

  ingress {
    description      = "http access"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "https access"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = -1
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags   = {
    Name = "public lb security groups"
  }
}



resource "aws_security_group" "private_instance_security_group" {
  name        = "public instance security group"
  description = "enable http/https access on port 80/443 from loadbalancer"
  vpc_id      = var.vpc_id

  ingress {
    description      = "ssh access"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"] #should be from know
  }

  ingress {
    description      = "http access"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    security_groups =   [aws_security_group.public_lb_security_group.id]
  }

  ingress {
    description      = "https access"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    security_groups = [aws_security_group.public_lb_security_group.id]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = -1
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags   = {
    Name = "public instance security groups"
  }
}

# create security group for the private subnet instance
resource "aws_security_group" "private_data_security_group" {
  name        = "private instance security group"
  description = "enable http/https access on port 80/443 via public instance sg"
  vpc_id      = var.vpc_id

  ingress {
    description = "database access"
    from_port = 3306
    to_port = 3306
    protocol = "tcp"
    security_groups =  [aws_security_group.private_instance_security_group.id]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = -1
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags   = {
    Name = "Private data security groups"
  }
}
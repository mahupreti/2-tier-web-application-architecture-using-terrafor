#use data source helps to get information that is already in cloud provider

data "aws_availability_zones" "available_zones" {}


# create the subnet group for the rds instance
resource "aws_db_subnet_group" "database_subnet_group" {
  name         = "database-subnets"
  subnet_ids   = [var.private_data_subnet_az1_id, var.private_data_subnet_az2_id]
  description  = "subnets for the database instance"
  tags   = {
    Name = "Database subnets "
  }
}

# create the rds instance
resource "aws_db_instance" "db_instance" {
  engine                  = "mysql"
  engine_version          = "8.0.31"
  multi_az                = false
  identifier              = "rds-instance"
  username                = var.db_username
  password                = var.db_password
  instance_class          = "db.t2.micro"
  allocated_storage       = 50
  db_subnet_group_name    = aws_db_subnet_group.database_subnet_group.name
  vpc_security_group_ids  = [var.private_data_security_group_id]
  availability_zone       = data.aws_availability_zones.available_zones.names[0]
  db_name                 = "mydatabase"
  skip_final_snapshot     = true
}


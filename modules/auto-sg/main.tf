resource "aws_key_pair" "key-tf" {
  key_name   = "key-tf"
  public_key = file("${path.module}/id_rsa.pub")
}

#create launch template for ec2 instance in private subnet
resource "aws_launch_template" "private_instance_launch_template" {
  name     = "${var.project_name}-publiclaunch-template"
  image_id   = var.image_id
  instance_type = var.instance_type 
  key_name  = aws_key_pair.key-tf.key_name
  user_data =  filebase64("../modules/auto-sg/ec2-init.sh")
  block_device_mappings {
    device_name = "/dev/sdf"

    ebs {
      volume_size = 20
      delete_on_termination= true
    }
  }

  monitoring {
    enabled =true

  }

  placement {
    availability_zone = "all"
    tenancy = "default"
  }

  # vpc_security_group_ids= [var.public_instance_security_group_id]

  network_interfaces {
  associate_public_ip_address = true
  security_groups = [var.private_instance_security_group_id]

  }

  tag_specifications {
    resource_type = "instance"
    tags   =  {
      name=   "private launch template"
  }

    }    

}

#create autoscaling group
resource "aws_autoscaling_group" "private_instance_autoscaling_group" {

  name                      = "${var.project_name}-autoscaling-group"
  desired_capacity          = var.desired_capacity
  min_size                  = var.min_size
  max_size                  = var.max_size
  health_check_grace_period = 300
  health_check_type         = "ELB"
  vpc_zone_identifier = [var.private_instance_subnet_az1_id, var.private_instance_subnet_az2_id]
  target_group_arns   = [var.public_loadbalancer_target_group_arn] 

  enabled_metrics = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupTotalInstances"
  ]

  metrics_granularity = "1Minute"

  launch_template {
    id      = aws_launch_template.private_instance_launch_template.id
    version = aws_launch_template.private_instance_launch_template.latest_version 
  }
  depends_on = [aws_launch_template.private_instance_launch_template]
  # load_balancers = [var.public_loadbalancer_arn

  tag {
    key                 = "Name"
    value               = "web"
    propagate_at_launch = true
  }
}

# scale up policy
resource "aws_autoscaling_policy" "private_instance_scale_up" {
  name                   = "${var.project_name}-asg-scale-up"
  autoscaling_group_name = aws_autoscaling_group.private_instance_autoscaling_group.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = "1" #increasing instance by 1 
  cooldown               = "300"
  policy_type            = "SimpleScaling"
}

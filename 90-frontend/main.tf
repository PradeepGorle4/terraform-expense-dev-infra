resource "aws_instance" "frontend" {
  ami                    = data.aws_ami.joindevops.id
  instance_type          = "t2.micro"
  vpc_security_group_ids = [data.aws_ssm_parameter.frontend_sg_id.value]
  subnet_id              = local.public_subnet_id

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-frontend"
    }
  )
}

resource "null_resource" "frontend" {
  # Changes to any instance of the cluster requires re-provisioning
  triggers = {
    instance_id = aws_instance.frontend.id
  }

  # Bootstrap script can run on any instance of the cluster
  # So we just choose the first in this case
  connection {
    host     = aws_instance.frontend.public_ip # We should give private IP here in Projects, but vpn should be on evertime if we give that. so giving public since vpn slows us down
    type     = "ssh"
    user     = "ec2-user"
    password = "DevOps321"
  }

  provisioner "file" {
    source      = "frontend.sh"
    destination = "/tmp/frontend.sh"
  }

  provisioner "remote-exec" {
    # Bootstrap script called with private_ip of each node in the cluster
    inline = [
      "sudo chmod +x /tmp/frontend.sh",
      "sudo sh /tmp/frontend.sh ${var.environment}"
    ]
  }
}

resource "aws_ec2_instance_state" "frontend_stop" {
  instance_id = aws_instance.frontend.id
  state       = "stopped"
  depends_on = [ null_resource.frontend ]
}

resource "aws_ami_from_instance" "frontend_ami" {
  name               = local.resource_name
  source_instance_id = aws_instance.frontend.id
  depends_on = [ aws_ec2_instance_state.frontend_stop ]
}

resource "null_resource" "frontend_delete" {
  provisioner "local-exec" {
    command = "aws ec2 terminate-instances --instance-ids=${aws_instance.frontend.id}"
  }
  depends_on = [ aws_ami_from_instance.frontend_ami ]
}

resource "aws_alb_target_group" "frontend" {
  name = local.resource_name
  port = "80"
  protocol = "HTTP"
  vpc_id = local.vpc_id

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 5
    protocol = "HTTP"
    port = "80"
    path = "/"
    matcher = "200-299"
    interval = 10
  }
}

resource "aws_launch_template" "frontend" {
  name = local.resource_name
  image_id = aws_ami_from_instance.frontend_ami.id
  instance_initiated_shutdown_behavior = "terminate"
  instance_type = "t2.micro"

  vpc_security_group_ids = [local.frontend_sg_id]

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = local.resource_name
    }
  }
}

resource "aws_autoscaling_group" "frontend" {
  name                      = local.resource_name
  max_size                  = 5
  min_size                  = 1
  health_check_grace_period = 120 # 2mins for instance to initialize
  health_check_type         = "ELB"
  desired_capacity          = 1

  launch_template {
    id      = aws_launch_template.frontend.id
    version = "$Latest"
  }

  vpc_zone_identifier       = [local.public_subnet_ids]

  target_group_arns = [aws_alb_target_group.frontend.arn]

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
    triggers = ["launch_template"]
  }

  tag {
    key                 = "Name"
    value               = local.resource_name
    propagate_at_launch = true
  }

  timeouts {
    delete = "5m" # ASG delete the instance when it is not up in 5 mins
  }

  tag {
    key                 = "Project"
    value               = var.project_name
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }
}

resource "aws_autoscaling_policy" "frontend" { # Configuring ASG Policy
  name = local.resource_name
  policy_type = "TargetTrackingScaling"
  autoscaling_group_name = aws_autoscaling_group.frontend.name

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
     target_value = 70.0
  }
}

resource "aws_alb_listener_rule" "frontend" {
  listener_arn = local.web_alb_listener_arn
  priority = 10

  action {
    type = "forward"
    target_group_arn = aws_alb_target_group.frontend.arn
  }

  condition {
    host_header {
      values = ["expense-${var.environment}.${var.domain_name}"] # so here, expense-dev-pradeepdevops.online
    }
  }
}

# Frontend should be accessed as below

# in DEV - expense-dev.pradeepdevops.online
# in QA - expense-qa.pradeepdevops.online
# in PROD - pradeepdevops.online



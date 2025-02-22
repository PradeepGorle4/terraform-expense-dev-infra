module "alb" {
  source   = "terraform-aws-modules/alb/aws"
  internal = true
  # expense-dev-alb
  name                  = "${var.project_name}-${var.environment}-web-alb"
  vpc_id                = data.aws_ssm_parameter.vpc_id.value
  subnets               = local.public_subnet_ids
  create_security_group = false
  security_groups       = [local.web_alb_sg_id]
  enable_deletion_protection = false

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-web-alb"
    }
  )
}

resource "aws_alb_listener" "https" {
    load_balancer_arn = module.alb.arn
    protocol = "HTTPS"
    port = "443"
    default_action {
      type = "fixed-response"

      fixed_response {
        content_type = "text/html"
        message_body = "<h1>Hello, Iam from Backend App ALB</h1>"
        status_code = 200
      }

    }
}

resource "aws_route53_record" "web_alb" {
    zone_id = var.zone_id
    name = "*.web-dev.${var.domain_name}"
    type = "A"

# These are APP ALB name and Zone ID information
    alias {
      name = module.alb.dns_name
      zone_id = module.alb.zone_id
      evaluate_target_health = true
    }
}
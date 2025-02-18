locals {
  private_subnet_id = split(",", data.aws_ssm_parameter.private_subnet_ids.value)[0]
  private_subnet_ids = data.aws_ssm_parameter.private_subnet_ids.value
  resource_name = "${var.project_name}-${var.environment}-backend"
  vpc_id = data.aws_ssm_parameter.vpc_id.value
  backend_sg_id = data.aws_ssm_parameter.backend_sg_id.value
}

locals {
  backend_app_alb_listener_arn = data.aws_ssm_parameter.backend_app_alb_listener_arn.value
}
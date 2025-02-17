locals {
  private_subnet_id = split(",", data.aws_ssm_parameter.private_subnet_ids.value)[0]
  resource_name = "${var.project_name}-${var.environment}-backend"
}
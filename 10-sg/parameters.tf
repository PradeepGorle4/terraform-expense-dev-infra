resource "aws_ssm_parameter" "mysql_sg_id" {
    name = "/${var.project_name}/${var.environment}/mysql_sg_id"
    type = "String"
    value = module.mysql_sg.mysql_sg_id
}
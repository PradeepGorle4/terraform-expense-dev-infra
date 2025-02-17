module "mysql_sg" {
    source = "../../terraform-aws-securitygroup"
    project_name = var.project_name
    environment = var.environment
    sg_name = "mysql"
    sg_description = "created for mysql instances in expense-dev"
    vpc_id = data.aws_ssm_parameter.vpc_id.value
    common_tags = var.common_tags
}

module "backend_sg" {
    source = "../../terraform-aws-securitygroup"
    project_name = var.project_name
    environment = var.environment
    sg_name = "backend"
    sg_description = "created for backend instances in expense-dev"
    vpc_id = data.aws_ssm_parameter.vpc_id.value
    common_tags = var.common_tags
}

module "frontend_sg" {
    source = "../../terraform-aws-securitygroup"
    project_name = var.project_name
    environment = var.environment
    sg_name = "frontend"
    sg_description = "created for frontend instances in expense-dev"
    vpc_id = data.aws_ssm_parameter.vpc_id.value
    common_tags = var.common_tags
}

module "bastion_sg" {
    source = "../../terraform-aws-securitygroup"
    project_name = var.project_name
    environment = var.environment
    sg_name = "bastion"
    sg_description = "created for bastion instances in expense-dev"
    vpc_id = data.aws_ssm_parameter.vpc_id.value
    common_tags = var.common_tags
}

module "app_alb_sg" {
    source = "../../terraform-aws-securitygroup"
    project_name = var.project_name
    environment = var.environment
    sg_name = "app-alb"
    sg_description = "created for Backend App Load balancer in expense-dev"
    vpc_id = data.aws_ssm_parameter.vpc_id.value
    common_tags = var.common_tags
}

# port 22, 443, 1194, 943 - ports to be opened for VPN
module "vpn_sg" {
    source = "../../terraform-aws-securitygroup"
    project_name = var.project_name
    environment = var.environment
    sg_name = "vpn"
    sg_description = "created for VPN Instances in expense-dev"
    vpc_id = data.aws_ssm_parameter.vpc_id.value
    common_tags = var.common_tags
}


# App ALB accepting traffic from bastion

resource "aws_security_group_rule" "app_alb_bastion" {
    type = "ingress"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    source_security_group_id = module.bastion_sg.sg_id
    security_group_id = module.app_alb_sg.sg_id
}

# (snow or jira ticket number) Bastion host should be access from office N/W(i.e. via vpn, connect to office n/w and then access)
resource "aws_security_group_rule" "bastion_public" {
    type = "ingress"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Usually u can give your office cidrs or static IP's so that only traffic is allowed from office N/W
    security_group_id = module.bastion_sg.sg_id
}

resource "aws_security_group_rule" "vpn_22" {
    type = "ingress"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Usually u can give your office cidrs or static IP's so that only traffic is allowed from office N/W
    security_group_id = module.vpn_sg.sg_id
}

resource "aws_security_group_rule" "vpn_443" {
    type = "ingress"
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Usually u can give your office cidrs or static IP's so that only traffic is allowed from office N/W
    security_group_id = module.vpn_sg.sg_id
}

resource "aws_security_group_rule" "vpn_1194" {
    type = "ingress"
    from_port = 1194
    to_port = 1194
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Usually u can give your office cidrs or static IP's so that only traffic is allowed from office N/W
    security_group_id = module.vpn_sg.sg_id
}

resource "aws_security_group_rule" "vpn_943" {
    type = "ingress"
    from_port = 943
    to_port = 943
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Usually u can give your office cidrs or static IP's so that only traffic is allowed from office N/W
    security_group_id = module.vpn_sg.sg_id
}

resource "aws_security_group_rule" "app_alb_vpn" {
    type = "ingress"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    source_security_group_id = module.vpn_sg.sg_id
    security_group_id = module.app_alb_sg.sg_id
}

resource "aws_security_group_rule" "mysql_bastion" {
    type = "ingress"
    from_port = 3306
    to_port = 3306
    protocol = "tcp"
    source_security_group_id = module.bastion_sg.sg_id
    security_group_id = module.mysql_sg.sg_id
}

resource "aws_security_group_rule" "mysql_vpn" { # This means mysql accepting traffic from vpn
    type = "ingress"
    from_port = 3306
    to_port = 3306
    protocol = "tcp"
    source_security_group_id = module.vpn_sg.sg_id
    security_group_id = module.mysql_sg.sg_id
}

resource "aws_security_group_rule" "backend_vpn" {
  type = "ingress"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    source_security_group_id = module.vpn_sg.sg_id
    security_group_id = module.backend_sg.sg_id
}


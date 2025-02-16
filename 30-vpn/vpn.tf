resource "aws_key_pair" "openvpnas" {
  key_name = "openvpnas"
  public_key = file("C:\\Devops\\daws-82s\\openvpnas.pub") # should use \\ for windows path while giving it in scripts or programs
}

resource "aws_instance" "open_vpn" {
  ami                    = data.aws_ami.openvpn.id
  instance_type          = "t2.micro"
  key_name = aws_key_pair.openvpnas.key_name
  vpc_security_group_ids = [data.aws_ssm_parameter.vpn_sg_id.value]
  subnet_id = local.public_subnet_id
  user_data = file("user-data.sh")

  tags = merge(
    var.common_tags,
    {
        Name = "${var.project_name}-${var.environment}-vpn"
    }
  )
}

output "vpn_id" {
    value = aws_instance.open_vpn.public_ip
}
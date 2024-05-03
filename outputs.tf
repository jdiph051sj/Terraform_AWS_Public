#Define the output values for "my_vpc" and it's provisioned/deployed resources

output "my_vpc_id" {
  value = aws_vpc.my_vpc.id

}

output "public_subnet_1" {
  value = aws_subnet.public_subnet_1.id
}

output "private_subnet_1" {
  value = aws_subnet.private_subnet_1.id
}

output "data_subnet_1" {
  value = aws_subnet.data_subnet_1.id
}

output "my_sg_ec2" {
  value = aws_security_group.my_sg_ec2.id
}

output "my_sg_alb" {
  value = aws_security_group.my_sg_alb.id
}

output "my_sg_health_check_ec2" {
  value = aws_security_group_rule.my_sg_health_check_ec2.id
}

#output "my_sg_health_check_alb" {
# value = aws_security_group_rule.my_sg_health_check_alb.id
#}

output "my_sg_alb_ingress" {
  value = aws_security_group_rule.my_sg_alb_ingress.id
}

output "my_sg_ec2_ingress" {
  value = aws_security_group_rule.my_sg_ec2_ingress.id
}

output "my_sg_pub" {
  value = aws_security_group.my_sg_ec2.id
}


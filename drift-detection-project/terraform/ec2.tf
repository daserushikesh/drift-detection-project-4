resource "aws_instance" "project_ec2" {
  ami           = var.ami_id
  instance_type = var.instance_type

  vpc_security_group_ids = [aws_security_group.project_sg.id]

  tags = {
    Name        = "${var.project_name}-ec2"
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}

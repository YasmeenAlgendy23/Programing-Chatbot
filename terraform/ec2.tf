data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-2023*-x86_64"]
  }
  filter {
    name   = "state"
    values = ["available"]
  }
}

resource "aws_instance" "deployment" {
  count                  = var.enable_ec2 ? 1 : 0
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.ec2_instance_type
  key_name               = aws_key_pair.main.key_name
  subnet_id              = aws_subnet.public_1.id
  vpc_security_group_ids = [aws_security_group.ec2.id]

  root_block_device {
    volume_size = 100
    volume_type = "gp3"
  }

  user_data = <<-USERDATA
    #!/bin/bash
    yum install -y zstd docker
    systemctl start docker
    systemctl enable docker
    usermod -a -G docker ec2-user
  USERDATA

  tags = { Name = "${var.netid}-ec2-deployment" }
}
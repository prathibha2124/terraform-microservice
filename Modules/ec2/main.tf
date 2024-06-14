resource "aws_iam_role" "ec2_instance_role" {
  name = "ec2-instance-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecr_read_only_access" {
  role       = aws_iam_role.ec2_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "ec2-instance-profile"
  role = aws_iam_role.ec2_instance_role.name
}


resource "aws_instance" "my_instance" {
  ami             = "ami-0d191299f2822b1fa" #Amazon Linux 2
  instance_type   = "t2.micro"
  key_name        =  var.key_name
  subnet_id       =  var.public_subnet_id
  security_groups =  [var.security_group_id]

  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              amazon-linux-extras install docker -y
              service docker start
              usermod -a -G docker ec2-user
              aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 211125333633.dkr.ecr.us-east-1.amazonaws.com
              docker pull 211125333633.dkr.ecr.us-east-1.amazonaws.com/nginx-server:v1
              docker run -d -p 80:80 211125333633.dkr.ecr.us-east-1.amazonaws.com/nginx-server:v1
              EOF
}

#output "instance_id" {
 # value = aws_instance.my_instance.id
#}

#output "public_ip" {
 # value = aws_instance.my_instance.public_ip
#}

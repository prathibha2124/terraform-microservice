provider "aws" {
 region = var.aws_region
}

module "vpc" {
  source = "./vpc"
}

module "security_groups" {
  source    = "./security_groups"
  vpc_id    = module.vpc.vpc_id
}

module "ecr" {
  source = "./ecr"
  repository_name = var.repository_name
}

data "aws_caller_identity" "current" {}

data "aws_ecr_authorization_token" "auth" {}

module "keypair" {
  source          = "./keypair"
  key_name        = var.key_name
  public_key_path = var.public_key_path
}


module "ec2" {
  source                 = "./ec2"
  vpc_id                 = module.vpc.vpc_id
  security_group_id      = module.security_groups.ec2_sg_id
  public_subnet_id       = module.vpc.public_subnet_ids[0]
  key_name               = module.keypair.key_name
  ecr_repository_url     = module.ecr.repository_url
  #ecr_repository_name    = var.ecr.repository_name
  aws_region             = var.aws_region
}

module "alb" {
  source                 = "./alb"
  vpc_id                 = module.vpc.vpc_id
  public_subnet_ids      = module.vpc.public_subnet_ids
  security_group_id      = module.security_groups.alb_sg_id
  instance_id            = module.ec2.instance_id
}

resource "null_resource" "push_docker_image" {
  provisioner "local-exec" {
   command = <<-EOT
      aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 211125333633.dkr.ecr.us-east-1.amazonaws.com
      docker build -t my-repos:image
      docker tag my-repos:latest 211125333633.dkr.ecr.us-east-1.amazonaws.com/my-repos:image
      docker push 211125333633.dkr.ecr.us-east-1.amazonaws.com/my-repos:image
    EOT

    #interpreter = ["cmd", "/C"]
  }

  #depends_on = [module.ecr]
} 
################################################################################
# AMI - Ubuntu 24.04 LTS, latest. Cleanest path for mssql-tools18.
################################################################################

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

################################################################################
# Security group - SSH from allowed CIDRs, all egress.
################################################################################

resource "aws_security_group" "this" {
  name        = "${var.identifier}-bastion"
  description = "RDI bastion SSH access for ${var.identifier}"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH from allowed CIDRs"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidrs
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.identifier}-bastion"
  }
}

################################################################################
# IAM - instance profile granting describe-RDS + read-Secrets + SSM (bonus).
################################################################################

resource "aws_iam_role" "this" {
  name = "${var.identifier}-bastion"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Permissions used by db-shell.sh: describe RDS resources + read deployment secrets.
resource "aws_iam_role_policy" "ops" {
  name = "${var.identifier}-bastion-ops"
  role = aws_iam_role.this.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "rds:DescribeDBClusters",
          "rds:DescribeDBInstances",
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:ListSecrets",
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret",
        ]
        # Scoped to this deployment's secrets via name prefix.
        Resource = "arn:aws:secretsmanager:*:*:secret:${var.identifier}-*"
      },
      {
        # Secrets are encrypted with per-DB customer-managed KMS keys.
        # `kms:Decrypt` is required for `GetSecretValue` to actually return the value.
        # The KMS keys live in this account, so we don't need to enumerate ARNs.
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
        ]
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_instance_profile" "this" {
  name = "${var.identifier}-bastion"
  role = aws_iam_role.this.name
}

################################################################################
# EC2 instance.
#
# The bastion's ops scripts (db-shell.sh, Makefile, update/reset SQL) are bundled
# into a single base64+gzip JSON blob and embedded in user_data. EC2 has a hard
# 16 KB user_data limit; compression keeps us under it.
################################################################################

locals {
  # All files written to the bastion, keyed by destination path.
  bastion_files = merge(
    {
      "/opt/rdi-tools/db-shell.sh" = file("${path.module}/files/db-shell.sh")
      "/opt/rdi-tools/Makefile"    = file("${path.module}/files/Makefile")
    },
    { for k, v in var.update_scripts : "/opt/rdi-tools/updates/${k}.sql" => v },
    { for k, v in var.reset_scripts : "/opt/rdi-tools/resets/${k}.sql" => v },
  )

  scripts_archive = base64gzip(jsonencode(local.bastion_files))
}

resource "aws_instance" "this" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = var.public_subnet_id
  vpc_security_group_ids      = [aws_security_group.this.id]
  iam_instance_profile        = aws_iam_instance_profile.this.name
  associate_public_ip_address = true

  user_data = templatefile("${path.module}/user_data.sh.tftpl", {
    ssh_password    = var.ssh_password
    aws_region      = var.aws_region
    prefix          = var.identifier
    scripts_archive = local.scripts_archive
  })

  # Force replacement if the bootstrap script changes - simplest way to roll a
  # fresh image with updated user-data/clients.
  user_data_replace_on_change = true

  tags = {
    Name = "${var.identifier}-bastion"
  }
}

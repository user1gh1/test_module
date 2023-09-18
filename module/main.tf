resource "aws_vpc" "mainvpc" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = "${var.name} VPC"
  }
}
#========================================================> version 4.0.0 #========================================================>
resource "aws_iam_role_policy" "ec2_policy" {
  name = "ec2_policy"
  role = aws_iam_role.role_for_s3.id

  #ec2:*Describe
  policy = data.aws_iam_policy_document.policy_s3_bucket.json
}

resource "aws_iam_role" "role_for_s3" {
  name = "role_for_s3"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_instance_profile" "ec2_profile" {
  name = "instance_allow_to_s3_bucket"
  role = aws_iam_role.role_for_s3.name
}
#====================================>
resource "aws_iam_policy" "policy_for_ec2" {
  name   = "s3-bucket-allow"
  policy = data.aws_iam_policy_document.policy_s3_bucket.json
}
resource "aws_iam_role" "instance" {
  name                = "instance_role"
  path                = "/system/"
  assume_role_policy  = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
        
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
  managed_policy_arns = [aws_iam_policy.policy_for_ec2.arn]
}
data "aws_iam_policy_document" "policy_s3_bucket" {
  statement {
    effect = "Allow"
    actions = [
      "s3:ListBucket"
    ]
    resources = [
      "*"
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject"
    ]
    resources = [
      "${aws_s3_bucket.s3_bucket.arn}/*"
    ]
  }
}

#========================================================> version 3.0.0 #========================================================>
resource "aws_s3_bucket" "s3_bucket" {
  bucket_prefix       = "${var.name}-s3-"
  force_destroy       = var.force_destroy
  object_lock_enabled = var.object_lock_enabled

  tags = {
    Name        = "${var.name}s3"
    Environment = "Environment"
  }
}

resource "aws_security_group" "main_security_group" {
  name   = "${var.name}-security-group"
  vpc_id = aws_vpc.mainvpc.id
  dynamic "ingress" {
    for_each = var.ingress_ports #(for_each) works with set and map
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }

  }
  dynamic "egress" {
    for_each = var.egress_ports
    content {
      from_port   = egress.value
      to_port     = egress.value
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  tags = {
    Name = "${var.name}-security-group"
  }
}
#========================================================> version 2.0.0
resource "aws_key_pair" "generated_key" {
  key_name   = "my_aws_key"
  public_key = file(var.Path_to_ssh)
}

#========================================================>
resource "aws_instance" "Test" {
  count                  = 1
  ami                    = data.aws_ami.latest_free_ami.id
  instance_type          = var.ec2_instance_type
  subnet_id              = aws_subnet.public_subnets[count.index].id
  key_name               = aws_key_pair.generated_key.key_name
  vpc_security_group_ids = [aws_security_group.main_security_group.id]
  #========================================================>
  disable_api_stop        = var.disable_api_stop
  disable_api_termination = var.disable_api_termination
  ebs_optimized           = var.ebs_optimized
  get_password_data       = var.get_password_data
  hibernation             = var.hibernation
  host_id                 = var.host_id
  host_resource_group_arn = var.host_resource_group_arn
  iam_instance_profile    = aws_iam_instance_profile.ec2_profile.name
  monitoring              = var.monitoring
  tenancy                 = var.tenancy
  user_data               = var.user_data
  ipv6_address_count      = var.ipv6_address_count
  tags = {
    Name = "${var.name}-${var.aws_instance_count[count.index]}"
  }
}
#========================================================>
resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.mainvpc.id
  tags = {
    Name = "${var.name} internet_gateway"
  }
}

resource "aws_subnet" "public_subnets" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.mainvpc.id
  cidr_block              = element(var.public_subnet_cidrs, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = var.map_public_ip_on_launch
  tags = {
    Name = "${var.name}-public-${count.index + 1}"
  }
}

resource "aws_route_table" "public_route" {

  vpc_id = aws_vpc.mainvpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }
  tags = {
    Name = "${var.name}-public-route-table"
  }
}

resource "aws_route_table_association" "public_route_attach" {
  count          = length(aws_subnet.public_subnets[*].id)
  route_table_id = aws_route_table.public_route.id
  subnet_id      = element(aws_subnet.public_subnets[*].id, count.index)
}

resource "aws_subnet" "private_subnets" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.mainvpc.id
  cidr_block        = element(var.private_subnet_cidrs, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags = {
    Name = "${var.name}-private-${count.index + 1}"
  }
}
# added instance creation implementation

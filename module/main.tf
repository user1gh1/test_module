resource "aws_vpc" "mainvpc" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = "${var.name} VPC"
  }
}
#========================================================> version 2.0.0
resource "aws_key_pair" "generated_key" {
  key_name   = "my_aws_key"
  public_key = file(var.Path_to_ssh)
}
variable "Path_to_ssh" {
  type    = string
  default = "C:/Users/Godlike/.ssh/my_aws_key.pub"
}
#========================================================>
resource "aws_instance" "Test" {
  #count         = var.module_version == "2.0.0" ? 1 : 0
  count         = 1
  ami           = data.aws_ami.latest_free_ami.id
  instance_type = var.ec2_instance_type
  subnet_id     = aws_subnet.public_subnets[count.index].id
  key_name      = aws_key_pair.generated_key.key_name
  #========================================================>
  disable_api_stop        = var.disable_api_stop
  disable_api_termination = var.disable_api_termination
  ebs_optimized           = var.ebs_optimized
  get_password_data       = var.get_password_data
  hibernation             = var.hibernation
  host_id                 = var.host_id
  host_resource_group_arn = var.host_resource_group_arn
  iam_instance_profile    = var.iam_instance_profile
  monitoring              = var.monitoring
  tenancy                 = var.tenancy
  user_data               = var.user_data
  ipv6_address_count      = var.ipv6_address_count
  tags = {
    Name = "${var.name}${var.aws_instance_count[count.index]}"
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
  map_public_ip_on_launch = true
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

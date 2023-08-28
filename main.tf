resource "aws_vpc" "mainvpc" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = "${var.name} VPC"
  }
}
# resource "aws_instance" "Test" {
#   count                  = length(var.aws_instance_count)
#   ami                    = data.aws_ami.latest_free_ami.id
#   instance_type          = var.ec2_instance_type
#   subnet_id              = element(aws_subnet.public_subnets.id,length(var.public_subnet_cidrs))
#   key_name               = aws_key_pair.generated_key.key_name # Reference the key pair resource
#   vpc_security_group_ids = [aws_security_group.my_security_group.id]
#   #user_data = file("NginxInstall.sh")
#   user_data = templatefile("NginxInstall.sh.tpl", {
#     Hello = var.templateVarHello,
#     Names = var.templateVar1
#   })
#   tags = {
#     Name = "${var.name}${var.aws_instance_count.count.index}"
#   }
# }
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

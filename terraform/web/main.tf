resource "aws_vpc" "web_vpc" {
  cidr_block           = "10.123.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "${var.name}-vpc"
  }
}

resource "aws_subnet" "web_subnet" {
  vpc_id                  = aws_vpc.web_vpc.id
  cidr_block              = "10.123.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"

  tags = {
    Name = "${var.name}-subnet"
  }
}

resource "aws_internet_gateway" "web_igw" {
  vpc_id = aws_vpc.web_vpc.id

  tags = {
    Name = "${var.name}-igw"
  }
}

resource "aws_route_table" "web_public_rt" {
  vpc_id = aws_vpc.web_vpc.id

  tags = {
    Name = "${var.name}-rt"
  }
}

resource "aws_route" "web_route" {
  route_table_id         = aws_route_table.web_public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.web_igw.id
}

resource "aws_route_table_association" "web_rta" {
  subnet_id      = aws_subnet.web_subnet.id
  route_table_id = aws_route_table.web_public_rt.id
}

resource "aws_security_group" "web_sg" {
  name        = "${var.name}_sg"
  description = "web SG"
  vpc_id      = aws_vpc.web_vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  ingress {
    description = "HTTPS"
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "web_auth" {
  key_name   = "web_auth"
  public_key = tls_private_key.rsa.public_key_openssh
}

# RSA key of size 4096 bits
resource "tls_private_key" "rsa" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "web_auth" {
    content  =  tls_private_key.rsa.private_key_pem
    filename = "web_auth"
}

resource "aws_instance" "web_ec2" {
  ami                    = data.aws_ami.web_ami.id
  instance_type          = "t2.micro"
  key_name               = "web_auth"
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  subnet_id              = aws_subnet.web_subnet.id

  tags = {
    Name = "${var.name}-node"
  }
}
resource "aws_vpc" "jenkins_vpc" {
  cidr_block           = "10.123.0.0/16"
  enable_dns_hostnames = true

  tags = {
    Name = "${var.name}-vpc"
  }
}

resource "aws_subnet" "jenkins_subnet" {
  vpc_id                  = aws_vpc.jenkins_vpc.id
  cidr_block              = "10.123.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"

  tags = {
    Name = "${var.name}-subnet"
  }
}

resource "aws_internet_gateway" "jenkins_igw" {
  vpc_id = aws_vpc.jenkins_vpc.id

  tags = {
    Name = "${var.name}-igw"
  }
}

resource "aws_route_table" "jenkins_public_rt" {
  vpc_id = aws_vpc.jenkins_vpc.id

  tags = {
    Name = "${var.name}-rt"
  }
}

resource "aws_route" "jenkins_route" {
  route_table_id         = aws_route_table.jenkins_public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.jenkins_igw.id
}

resource "aws_route_table_association" "jenkins_rta" {
  subnet_id      = aws_subnet.jenkins_subnet.id
  route_table_id = aws_route_table.jenkins_public_rt.id
}

resource "aws_security_group" "jenkins_sg" {
  name        = "${var.name}_sg"
  description = "Jenkins SG"
  vpc_id      = aws_vpc.jenkins_vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "jenkins_auth" {
  key_name   = "jenkins"
  public_key = file("~/.ssh/jenkins.pub")
}
resource "aws_instance" "jenkins_ec2" {
  ami                    = data.aws_ami.jenkins_ami.id
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.jenkins_auth.id
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]
  subnet_id              = aws_subnet.jenkins_subnet.id

  tags = {
    Name = "${var.name}-node"
  }
}
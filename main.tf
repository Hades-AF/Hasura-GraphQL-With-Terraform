#Configure the AWS Provider.
provider "aws" {
    region = "us-east-1"
    access_key = "AKIA3BGUT3D6WA5MLJE2"
    secret_key = "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"
}

#Amazon Virtual Private Cloud.
#Used to Host a Cloud Network for Instances.
resource "aws_vpc" "prod-vpc" {
  cidr_block = "10.0.0.0/16"

   tags = {
    Name = "production"
  }
}

#Amazon Internet Gateway.
#Used to Connect the VPC to the Public Internet.
resource "aws_internet_gateway" "prod-gw" {
  vpc_id = aws_vpc.prod-vpc.id
}

#A Route Table for our VPC.
#Controls Traffic and Rules for IGW.
resource "aws_route_table" "prod-route-table" {
  #VPC Associated with the Route Table.
  vpc_id = aws_vpc.prod-vpc.id

  #All IPV4 Outbound Traffic will go to the Production Gateway.
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.prod-gw.id
  }

  #All IPV6 Outbound Traffic will go to the Production Gateway.
  route {
    ipv6_cidr_block        = "::/0"
    gateway_id = aws_internet_gateway.prod-gw.id
  }

  tags = {
    Name = "production"
  }
}

#Variable for Subnet Details.
variable "subnet_cidr_block_data" {
    description = "cidr block data for prod-subnet-1"
    #default = "0.0.0.0/0"
    #type = string
}

#Subnet Used for Production Instances
resource "aws_subnet" "prod-subnet-1" {
  vpc_id     = aws_vpc.prod-vpc.id
  cidr_block = var.subnet_cidr_block_data.cidr_block
  availability_zone = "us-east-1a"

  tags = {
    Name = "production"
  }
}

#Route Table Association
#To Link our Route Table and our Subnet Together.
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.prod-subnet-1.id
  route_table_id = aws_route_table.prod-route-table.id
}

#Controls Rules for Inbound Traffic.
resource "aws_security_group" "allow_web" {
  name        = "allow_web_traffic"
  description = "Allow Web inbound traffic"
  vpc_id      = aws_vpc.prod-vpc.id

  ingress {
    description      = "HTTPS"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_web"
  }
}

resource "aws_network_interface" "web-server-nic" {
  subnet_id       = aws_subnet.prod-subnet-1.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_web.id]
}

#Amazon Elastic IP for Public IP use.
resource "aws_eip" "one" {
  domain                    = "vpc"
  network_interface         = aws_network_interface.web-server-nic.id
  associate_with_private_ip = "10.0.1.50"
  depends_on = [aws_internet_gateway.prod-gw]
}

#Setup of EC2 Instance.
resource "aws_instance" "web-server-instance" {
  ami = "ami-053b0d53c279acc90"
  instance_type = "t2.micro"
  availability_zone = "us-east-1a"
  key_name = "test-key"

  network_interface {
    device_index = 0
    network_interface_id = aws_network_interface.web-server-nic.id
  }

  user_data = "${file("user-data-apache.sh")}"

  tags = {
    Name = "web-server"
  }
}

# Provisioner to install Docker and run Docker Compose
resource "null_resource" "run_docker_compose" {
  connection {
    type        = "ssh"
    host        = aws_instance.web-server-instance.public_ip
    user        = "ubuntu" # or the appropriate SSH user for your AMI
    private_key = file("C:\\Users\\gbaly\\Downloads\\test-key.pem")
  }

  triggers = {
    instance_id = aws_instance.web-server-instance.id
  }

  provisioner "remote-exec" {
  inline = [
    "sudo apt-get update -y", # Update the package repository
    "sudo apt-get install -y docker.io", # Install Docker
    "sudo service docker start", # Start Docker service
    "sudo usermod -aG docker ubuntu", # Add the current user to the docker group (for non-root Docker use)
    "sudo apt-get install -y docker-compose", # Install Docker Compose
    "sudo mkdir -p /path/to/your/app", # Create a directory for your Docker Compose files and application
    "cd /path/to/your/app",
    "sudo wget -O docker-compose.yml https://raw.githubusercontent.com/Hades-AF/Hasura-Project/main/docker-compose.yml", # Download your Docker Compose file
    "sudo wget -O Caddy https://raw.githubusercontent.com/Hades-AF/Hasura-Project/main/Caddyfile", # Download your Caddy file
    "sudo docker-compose up -d" # Run Docker Compose in detached mode
    ]
  }
}
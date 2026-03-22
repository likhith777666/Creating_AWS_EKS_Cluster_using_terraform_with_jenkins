locals {
  cluster_name = var.cluster_name
}

resource "aws_vpc" "vpc" {
    cidr_block = "10.0.0.0/16"
    instance_tenancy = "default"
    enable_dns_hostnames = true
    enable_dns_support = true
    tags = {
        Name = "${local.cluster_name}-vpc"
        env = "dev"
    }
}

resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.vpc.id
    tags = {
        Name = "${local.cluster_name}-internet-gateway"
        env = "dev"
        "kubernetes.io/cluster/${local.cluster_name}" = "owned"
    }

    depends_on = [aws_vpc.vpc]
}

resource "aws_subnet" "public_subnet" {
    count =3
    vpc_id = aws_vpc.vpc.id
     cidr_block = cidrsubnet("10.0.0.0/16", 8, count.index)
    availability_zone = element(
    ["us-east-1a", "us-east-1b", "us-east-1c"],  
    count.index
  )
    map_public_ip_on_launch = true

    tags = {
    Name = "my-public-subnet-${count.index + 1}"
    Env  = "dev"
    "kubernetes.io/cluster/${local.cluster_name}" = "owned"
    "kubernetes.io/role/elb" = "1"
  }
}

resource "aws_subnet" "private_subnet" {
    count = 3
    vpc_id = aws_vpc.vpc.id
    cidr_block = cidrsubnet("10.0.0.0/16", 8, count.index + 10)
    availability_zone = element(["us-east-1a", "us-east-1b", "us-east-1c"], count.index)
    map_public_ip_on_launch = false
   
   tags = {
    Name = "my-private-subnet-${count.index + 1}"
    Env  = "dev"
    "kubernetes.io/cluster/${local.cluster_name}" = "owned"
    "kubernetes.io/role/internal-elb" = "1" 
  }
    
}

resource "aws_route_table" "aws_public_rt" {
    vpc_id = aws_vpc.vpc.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw.id
    }

    tags = {
        Name = "${local.cluster_name}-public-rt"
        env = "dev"
        "kubernetes.io/cluster/${local.cluster_name}" = "owned"
    }

    depends_on = [ aws_vpc.vpc ]
  
}

resource "aws_route_table_association" "aws_rta" {
       count = 3
       route_table_id = aws_route_table.aws_public_rt.id
       subnet_id = aws_subnet.public_subnet[count.index].id
}

resource "aws_eip" "epi" {
  domain = "vpc"

  tags = {
     Name = "${local.cluster_name}-eip-natgateway"
  }
  depends_on = [ aws_vpc.vpc ]
}

resource "aws_nat_gateway" "aws_ngw" {
    allocation_id = aws_eip.epi.id
    subnet_id = aws_subnet.public_subnet[0].id
    tags = {
        Name = "${local.cluster_name}-nat-gateway"

    }

    depends_on = [ aws_eip.epi,aws_vpc.vpc ]
}

resource "aws_route_table" "private_rt" {

  vpc_id = aws_vpc.vpc.id 
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.aws_ngw.id
  }
  tags = {
    Name = "${local.cluster_name}-private-rt"
    env = "dev"
  }
  depends_on = [ aws_vpc.vpc ]
}

resource "aws_route_table_association" "aws_rta_private" {
    count = 3
    route_table_id = aws_route_table.private_rt.id
    subnet_id = aws_subnet.private_subnet[count.index].id

    depends_on = [ aws_vpc.vpc, aws_subnet.private_subnet ]
  
}

resource "aws_security_group" "aws_sg" {
    name = "${local.cluster_name}-sg"
    description = "Allow 443 from the jump server only"
    vpc_id = aws_vpc.vpc.id
    ingress {
        from_port = 433
        to_port = 433
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]  # Replace it with jump server ip adress with /32
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

}
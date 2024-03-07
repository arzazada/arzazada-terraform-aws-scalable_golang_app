# Subnet cidr locals
locals {
  private_cidrs = [for i in range(1, 16, 2) : cidrsubnet(var.vpc_cidr, 8, i)]
  public_cidrs  = [for i in range(2, 16, 2) : cidrsubnet(var.vpc_cidr, 8, i)]
}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# IGW
resource "aws_internet_gateway" "sga_igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
  }

  lifecycle {
    create_before_destroy = true
  }

}

# Route Tables
resource "aws_default_route_table" "main_rt" {
  default_route_table_id = aws_vpc.main.default_route_table_id

  tags = {
    Name = "${var.project_name}-main-rt"
  }
}

resource "aws_route_table" "public_rt" {
  count  = var.az_count
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.sga_igw.id
  }

  tags = {
    Name = "${var.project_name}-public-rt-${local.az_names[count.index]}"
  }
}

resource "aws_route_table" "private_rt" {
  count  = var.az_count
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.sga_nat_gateways[count.index].id
  }
}

resource "aws_route_table_association" "public_rta" {
  count          = var.az_count
  subnet_id      = aws_subnet.public_subnet.*.id[count.index] #alternative aws_subnet.public_subnet[count.index].id
  route_table_id = aws_route_table.public_rt[count.index].id
}

resource "aws_route_table_association" "private_rta" {
  count          = var.az_count
  subnet_id      = aws_subnet.private_subnet.*.id[count.index]
  route_table_id = aws_route_table.private_rt[count.index].id
}

# Subnets
resource "aws_subnet" "private_subnet" {
  count                   = var.az_count
  vpc_id                  = aws_vpc.main.id
  cidr_block              = local.private_cidrs[count.index]
  map_public_ip_on_launch = false
  availability_zone       = local.az_names[count.index]
  tags = {
    Name = "${upper(substr(local.az_names[count.index], -1, 1))} private | ${var.project_name}-subnet"
  }
}

resource "aws_subnet" "public_subnet" {
  count                   = var.az_count
  vpc_id                  = aws_vpc.main.id
  cidr_block              = local.public_cidrs[count.index]
  map_public_ip_on_launch = true
  availability_zone       = local.az_names[count.index]
  tags = {
    Name = "${upper(substr(local.az_names[count.index], -1, 1))} public | ${var.project_name}-subnet"
  }
}

# Security groups
resource "aws_security_group" "private_sg" {
  name        = "${var.project_name}-private-sg"
  description = "Security group for private resources"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = [var.vpc_cidr]
  }


  ingress {
    from_port = 80
    to_port   = 80
    protocol  = "tcp"

    security_groups = [aws_security_group.sga_alb_public.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "sga_alb_public" {
  name        = "sga-alb-public"
  description = "Security group for public resources"
  vpc_id      = aws_vpc.main.id

  ingress {
    protocol         = "tcp"
    from_port        = 80
    to_port          = 80
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    protocol         = "tcp"
    from_port        = 443
    to_port          = 443
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
}


#EIP
resource "aws_eip" "sga_eips" {
  count = 2
}

# Create NAT Gateways
resource "aws_nat_gateway" "sga_nat_gateways" {
  count         = var.az_count
  allocation_id = aws_eip.sga_eips[count.index].id
  subnet_id     = aws_subnet.public_subnet[count.index].id
}

# Hosted Zones
resource "aws_route53_zone" "project_hosted_zone" {
  name = var.domain
  tags = local.default_tags
}

#DNS Records
resource "aws_route53_record" "project_dns_record" {
  zone_id = aws_route53_zone.project_hosted_zone.zone_id
  name    = "${var.project_name}.${var.domain}"
  type    = "A"
  alias {
    name                   = aws_lb.sga_alb.dns_name
    zone_id                = aws_lb.sga_alb.zone_id
    evaluate_target_health = true
  }
}

## ALB
resource "aws_lb" "sga_alb" {
  name               = "sga-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sga_alb_public.id]
  subnets            = [for subnet in aws_subnet.public_subnet : subnet.id]

}

resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.sga_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "https_listener" {
  load_balancer_arn = aws_lb.sga_alb.arn
  port              = 443
  protocol          = "HTTPS"

  ssl_policy      = "ELBSecurityPolicy-2016-08"
  certificate_arn = aws_acm_certificate.sga_acm.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.sga_target_group.arn
  }
}

resource "aws_lb_target_group" "sga_target_group" {
  name        = "sga-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = aws_vpc.main.id
}


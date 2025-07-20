# Calculate subnet allocation dynamically
locals {
  # Calculate subnet size based on VPC CIDR and number of AZs
  vpc_cidr_bits = tonumber(split("/", var.cidr_block)[1])
  # Ensure we have enough bits for subnets (minimum /24)
  subnet_bits = max(8, 32 - local.vpc_cidr_bits - ceil(log(length(var.availability_zones) * 4, 2)))

  # Validate subnet allocation
  max_subnets      = pow(2, 32 - local.vpc_cidr_bits - local.subnet_bits)
  required_subnets = length(var.availability_zones) * 2 # public + private
}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.cidr_block
  enable_dns_hostnames = var.enable_dns_hostnames
  enable_dns_support   = var.enable_dns_support

  tags = merge(var.tags, {
    Name = var.name
  })
}

# Validation for subnet allocation
resource "null_resource" "validate_subnet_allocation" {
  lifecycle {
    precondition {
      condition     = local.required_subnets <= local.max_subnets
      error_message = "VPC CIDR ${var.cidr_block} cannot accommodate ${local.required_subnets} subnets. Maximum possible: ${local.max_subnets}. Consider using a larger VPC CIDR block."
    }

    precondition {
      condition     = local.vpc_cidr_bits <= 20
      error_message = "VPC CIDR must be /20 or larger to accommodate multiple subnets. Current: /${local.vpc_cidr_bits}"
    }
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.tags, {
    Name = "${var.name}-igw"
  })
}

# Public Subnets
resource "aws_subnet" "public" {
  count = length(var.availability_zones)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.cidr_block, local.subnet_bits, count.index)
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = var.map_public_ip_on_launch

  tags = merge(var.tags, {
    Name                     = "${var.name}-public-${var.availability_zones[count.index]}"
    Type                     = "Public"
    "kubernetes.io/role/elb" = "1"
  })
}

# Private Subnets
resource "aws_subnet" "private" {
  count = length(var.availability_zones)

  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.cidr_block, local.subnet_bits, count.index + length(var.availability_zones))
  availability_zone = var.availability_zones[count.index]

  tags = merge(var.tags, {
    Name                              = "${var.name}-private-${var.availability_zones[count.index]}"
    Type                              = "Private"
    "kubernetes.io/role/internal-elb" = "1"
  })
}

# Elastic IPs for NAT Gateways
resource "aws_eip" "nat" {
  count = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.availability_zones)) : 0

  domain     = "vpc"
  depends_on = [aws_internet_gateway.main]

  tags = merge(var.tags, {
    Name = "${var.name}-nat-eip-${count.index + 1}"
  })
}

# NAT Gateways
resource "aws_nat_gateway" "main" {
  count = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.availability_zones)) : 0

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(var.tags, {
    Name = "${var.name}-nat-${count.index + 1}"
  })

  depends_on = [aws_internet_gateway.main]
}

# Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(var.tags, {
    Name = "${var.name}-public-rt"
    Type = "Public"
  })
}

# Private Route Tables
resource "aws_route_table" "private" {
  count = length(var.availability_zones)

  vpc_id = aws_vpc.main.id

  dynamic "route" {
    for_each = var.enable_nat_gateway ? [1] : []
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = var.single_nat_gateway ? aws_nat_gateway.main[0].id : aws_nat_gateway.main[count.index].id
    }
  }

  tags = merge(var.tags, {
    Name = "${var.name}-private-rt-${var.availability_zones[count.index]}"
    Type = "Private"
  })
}

# Public Route Table Associations
resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Private Route Table Associations
resource "aws_route_table_association" "private" {
  count = length(aws_subnet.private)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

# Network ACLs for additional security
resource "aws_network_acl" "private" {
  vpc_id     = aws_vpc.main.id
  subnet_ids = aws_subnet.private[*].id

  # Allow inbound traffic from VPC CIDR
  ingress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = var.cidr_block
    from_port  = 0
    to_port    = 0
  }

  # Allow outbound traffic
  egress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = merge(var.tags, {
    Name = "${var.name}-private-nacl"
    Type = "Private"
  })
}

# CloudWatch Alarms for NAT Gateway monitoring
resource "aws_cloudwatch_metric_alarm" "nat_gateway_connection_error_count" {
  count = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.availability_zones)) : 0

  alarm_name          = "${var.name}-nat-gateway-${count.index + 1}-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ErrorPortAllocation"
  namespace           = "AWS/NatGateway"
  period              = "300"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "This metric monitors NAT Gateway port allocation errors"
  alarm_actions       = var.alarm_actions

  dimensions = {
    NatGatewayId = aws_nat_gateway.main[count.index].id
  }

  tags = merge(var.tags, {
    Name = "${var.name}-nat-gateway-${count.index + 1}-error-alarm"
    Type = "Monitoring"
  })
}

resource "aws_cloudwatch_metric_alarm" "nat_gateway_packet_drop_count" {
  count = var.enable_nat_gateway ? (var.single_nat_gateway ? 1 : length(var.availability_zones)) : 0

  alarm_name          = "${var.name}-nat-gateway-${count.index + 1}-packet-drops"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "PacketDropCount"
  namespace           = "AWS/NatGateway"
  period              = "300"
  statistic           = "Sum"
  threshold           = "100"
  alarm_description   = "This metric monitors NAT Gateway packet drops"
  alarm_actions       = var.alarm_actions

  dimensions = {
    NatGatewayId = aws_nat_gateway.main[count.index].id
  }

  tags = merge(var.tags, {
    Name = "${var.name}-nat-gateway-${count.index + 1}-packet-drop-alarm"
    Type = "Monitoring"
  })
}

# CloudWatch Dashboard for NAT Gateway monitoring
resource "aws_cloudwatch_dashboard" "nat_gateway_dashboard" {
  count = var.enable_nat_gateway && var.create_monitoring_dashboard ? 1 : 0

  dashboard_name = "${var.name}-nat-gateway-monitoring"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            for i in range(var.single_nat_gateway ? 1 : length(var.availability_zones)) : [
              "AWS/NatGateway",
              "BytesInFromDestination",
              "NatGatewayId",
              aws_nat_gateway.main[i].id
            ]
          ]
          view    = "timeSeries"
          stacked = false
          region  = data.aws_region.current.name
          title   = "NAT Gateway Bytes In"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6

        properties = {
          metrics = [
            for i in range(var.single_nat_gateway ? 1 : length(var.availability_zones)) : [
              "AWS/NatGateway",
              "BytesOutToDestination",
              "NatGatewayId",
              aws_nat_gateway.main[i].id
            ]
          ]
          view    = "timeSeries"
          stacked = false
          region  = data.aws_region.current.name
          title   = "NAT Gateway Bytes Out"
          period  = 300
        }
      }
    ]
  })
}

# Data source for current region
data "aws_region" "current" {}

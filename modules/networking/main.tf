# VPC Peering Connection
resource "aws_vpc_peering_connection" "main" {
  vpc_id      = var.gateway_vpc_id
  peer_vpc_id = var.backend_vpc_id
  auto_accept = true

  accepter {
    allow_remote_vpc_dns_resolution = true
  }

  requester {
    allow_remote_vpc_dns_resolution = true
  }

  # Add lifecycle rule to ensure connection is active
  lifecycle {
    create_before_destroy = true
  }

  tags = merge(var.tags, {
    Name = "gateway-to-backend-peering"
  })
}

# Wait for peering connection to become active
resource "time_sleep" "wait_for_peering" {
  depends_on      = [aws_vpc_peering_connection.main]
  create_duration = "30s"
}

# Route from Gateway VPC to Backend VPC
resource "aws_route" "gateway_to_backend" {
  count = length(var.gateway_route_table_ids)

  route_table_id            = var.gateway_route_table_ids[count.index]
  destination_cidr_block    = var.backend_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.main.id

  # Ensure peering connection is active before creating routes
  depends_on = [
    aws_vpc_peering_connection.main,
    time_sleep.wait_for_peering
  ]

  timeouts {
    create = "5m"
    delete = "5m"
  }
}

# Route from Backend VPC to Gateway VPC
resource "aws_route" "backend_to_gateway" {
  count = length(var.backend_route_table_ids)

  route_table_id            = var.backend_route_table_ids[count.index]
  destination_cidr_block    = var.gateway_vpc_cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.main.id

  # Ensure peering connection is active before creating routes
  depends_on = [
    aws_vpc_peering_connection.main,
    time_sleep.wait_for_peering
  ]

  timeouts {
    create = "5m"
    delete = "5m"
  }
}

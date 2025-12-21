# =============================================================================
# VPC.TF - CliXX Enterprise VPC (12 Subnets)
# =============================================================================

# -----------------------------------------------------------------------------
# LOCALS - Maps new subnet names to what main.tf expects
# -----------------------------------------------------------------------------
locals {
  public_subnet_ids  = aws_subnet.public[*].id
  private_subnet_ids = aws_subnet.private_webapp[*].id
}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = { Name = "clixx-${var.environment}-vpc" }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "clixx-${var.environment}-igw" }
}

# -----------------------------------------------------------------------------
# PUBLIC SUBNETS (2) - 450 hosts each
# -----------------------------------------------------------------------------
resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = element(["10.0.0.0/23", "10.0.2.0/23"], count.index)
  availability_zone       = element(["us-east-1a", "us-east-1b"], count.index)
  map_public_ip_on_launch = true
  tags = { Name = "clixx-${var.environment}-public-${count.index + 1}" }
}

# -----------------------------------------------------------------------------
# PRIVATE SUBNETS - WEB APP (2) - 250 hosts each
# -----------------------------------------------------------------------------
resource "aws_subnet" "private_webapp" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = element(["10.0.4.0/24", "10.0.5.0/24"], count.index)
  availability_zone = element(["us-east-1a", "us-east-1b"], count.index)
  tags = { Name = "clixx-${var.environment}-private-webapp-${count.index + 1}" }
}

# -----------------------------------------------------------------------------
# PRIVATE SUBNETS - MYSQL RDS (2) - 680 hosts each
# -----------------------------------------------------------------------------
resource "aws_subnet" "private_mysql" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = element(["10.0.8.0/22", "10.0.12.0/22"], count.index)
  availability_zone = element(["us-east-1a", "us-east-1b"], count.index)
  tags = { Name = "clixx-${var.environment}-private-mysql-${count.index + 1}" }
}

# -----------------------------------------------------------------------------
# PRIVATE SUBNETS - ORACLE (2) - 254 hosts each
# -----------------------------------------------------------------------------
resource "aws_subnet" "private_oracle" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = element(["10.0.16.0/24", "10.0.17.0/24"], count.index)
  availability_zone = element(["us-east-1a", "us-east-1b"], count.index)
  tags = { Name = "clixx-${var.environment}-private-oracle-${count.index + 1}" }
}

# -----------------------------------------------------------------------------
# PRIVATE SUBNETS - JAVA DB (2) - 50 hosts each
# -----------------------------------------------------------------------------
resource "aws_subnet" "private_javadb" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = element(["10.0.18.0/26", "10.0.18.64/26"], count.index)
  availability_zone = element(["us-east-1a", "us-east-1b"], count.index)
  tags = { Name = "clixx-${var.environment}-private-javadb-${count.index + 1}" }
}

# -----------------------------------------------------------------------------
# PRIVATE SUBNETS - JAVA APP / TOMCAT (2) - 50 hosts each
# -----------------------------------------------------------------------------
resource "aws_subnet" "private_javaapp" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = element(["10.0.18.128/26", "10.0.18.192/26"], count.index)
  availability_zone = element(["us-east-1a", "us-east-1b"], count.index)
  tags = { Name = "clixx-${var.environment}-private-javaapp-${count.index + 1}" }
}

# -----------------------------------------------------------------------------
# NAT GATEWAYS (2 - one per AZ for HA)
# -----------------------------------------------------------------------------
resource "aws_eip" "nat" {
  count  = 2
  domain = "vpc"
  tags   = { Name = "clixx-${var.environment}-nat-eip-${count.index + 1}" }
  depends_on = [aws_internet_gateway.main]
}

resource "aws_nat_gateway" "main" {
  count         = 2
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  tags          = { Name = "clixx-${var.environment}-nat-gw-${count.index + 1}" }
  depends_on    = [aws_internet_gateway.main]
}

# -----------------------------------------------------------------------------
# ROUTE TABLES
# -----------------------------------------------------------------------------
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = { Name = "clixx-${var.environment}-public-rt" }
}

resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  count  = 2
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[count.index].id
  }
  tags = { Name = "clixx-${var.environment}-private-rt-${count.index + 1}" }
}

resource "aws_route_table_association" "private_webapp" {
  count          = 2
  subnet_id      = aws_subnet.private_webapp[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

resource "aws_route_table_association" "private_mysql" {
  count          = 2
  subnet_id      = aws_subnet.private_mysql[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

resource "aws_route_table_association" "private_oracle" {
  count          = 2
  subnet_id      = aws_subnet.private_oracle[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

resource "aws_route_table_association" "private_javadb" {
  count          = 2
  subnet_id      = aws_subnet.private_javadb[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

resource "aws_route_table_association" "private_javaapp" {
  count          = 2
  subnet_id      = aws_subnet.private_javaapp[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

# -----------------------------------------------------------------------------
# DB SUBNET GROUPS
# -----------------------------------------------------------------------------
resource "aws_db_subnet_group" "mysql" {
  name       = "clixx-${var.environment}-mysql-subnet-group"
  subnet_ids = aws_subnet.private_mysql[*].id
  tags       = { Name = "clixx-${var.environment}-mysql-subnet-group" }
}

resource "aws_db_subnet_group" "oracle" {
  name       = "clixx-${var.environment}-oracle-subnet-group"
  subnet_ids = aws_subnet.private_oracle[*].id
  tags       = { Name = "clixx-${var.environment}-oracle-subnet-group" }
}

resource "aws_db_subnet_group" "javadb" {
  name       = "clixx-${var.environment}-javadb-subnet-group"
  subnet_ids = aws_subnet.private_javadb[*].id
  tags       = { Name = "clixx-${var.environment}-javadb-subnet-group" }
}

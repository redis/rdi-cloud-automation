# Needed for subnet creation
data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  az_map = zipmap(data.aws_availability_zones.available.zone_ids, data.aws_availability_zones.available.names)
  azs    = [for az_id in var.azs : local.az_map[az_id]]
}

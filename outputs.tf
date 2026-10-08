output "primary_alb_url" {
  value = "http://${module.compute_primary.alb_dns_name}"
}

output "secondary_alb_url" {
  value = "http://${module.compute_secondary.alb_dns_name}"
}

output "primary_vpc_id" {
  value = module.vpc_primary.vpc_id
}

output "secondary_vpc_id" {
  value = module.vpc_secondary.vpc_id
}

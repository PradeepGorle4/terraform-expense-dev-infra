# output "azs_info" {
#     value = module.vpc.azs_info
# }

# output "subnet_info" {
#     value = module.vpc.subnet_info
# }

output "public_subnet_id" {
    value = module.vpc.public_subnet_id
}

output "private_subnet_id" {
    value = module.vpc.private_subnet_id
}

output "database_subnet_id" {
    value = module.vpc.database_subnet_id
}
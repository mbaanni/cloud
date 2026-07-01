output "public_ip" {
  value = aws_instance.lmachina[*].public_ip
}
output "public_dns" {
  value = aws_instance.lmachina[*].public_dns
}
output "availability_zone" {
  value = data.aws_availability_zones.available.names
}
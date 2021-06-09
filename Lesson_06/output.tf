// output into the console
output "webserver_instance_id" {
  value       = aws_instance.my_webserver.id
  description = "value"
}

output "webserver_public_ip_address" {
  value       = aws_eip.my_static_ip.public_ip
  description = "value"
}

output "webserver_sg_id" {
  value       = aws_security_group.my_webserver.id
  description = "value"
}

output "webserver_sg_arn" {
  value       = aws_security_group.my_webserver.arn
  description = "value"
}

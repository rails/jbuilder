output "output_Nginx" {
  value = {
    "public_ip"  = "https://${aws_instance.nginx.public_ip}/"
  }
}
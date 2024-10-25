resource "aws_instance" "nginx" {
  ami                    = "ami-0084a47cc718c111a" #Ubuntu 20.04
  instance_type          = "t2.micro"
  key_name               = "teimas"
  subnet_id              = aws_subnet.ps_teimas.id
  vpc_security_group_ids = [aws_security_group.sg_teimas.id]

  provisioner "remote-exec" {
    inline = [

      "echo 'Versión actual de nginx:' && nginx -v 2>&1 || echo 'nginx no está instalado'",

      "sudo cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bak",

      "sudo apt update -y nginx",

      "sudo nginx  -s reload", #! Recargar la configuración de nginx sin parar el servicio.
    ]
  }
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("~/.ssh/teimas.pem")
    host        = self.public_ip
  }

  tags = {
    Name = "nginx-teimas"
  }

}
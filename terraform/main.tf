# VULNERÁVEL DE PROPÓSITO: apenas para os scanners encontrarem problemas.
# Nunca rode terraform apply neste arquivo.

resource "aws_s3_bucket" "dados" {
  bucket = "exemplo-bucket-inseguro"
  acl    = "public-read"
}

resource "aws_security_group" "ssh_aberto" {
  name = "ssh-aberto"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

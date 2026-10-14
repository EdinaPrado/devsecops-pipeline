# Versão corrigida: os achados do Checkov foram tratados.
# Nunca rode terraform apply neste arquivo: ele existe só para ser escaneado.

data "aws_caller_identity" "current" {}

resource "aws_kms_key" "s3" {
  description             = "Chave KMS do bucket de dados"
  enable_key_rotation     = true
  deletion_window_in_days = 7

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "AdministracaoDaConta"
      Effect    = "Allow"
      Principal = { AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" }
      Action    = "kms:*"
      Resource  = "*"
    }]
  })
}

resource "aws_s3_bucket" "dados" {
  #checkov:skip=CKV_AWS_18:Log de acesso exigiria um bucket de logs dedicado, fora do escopo deste exemplo
  #checkov:skip=CKV_AWS_144:Replicacao entre regioes nao se aplica a este exemplo
  #checkov:skip=CKV2_AWS_62:Sem notificacoes de eventos neste exemplo
  bucket = "exemplo-bucket-seguro"
}

resource "aws_s3_bucket_public_access_block" "dados" {
  bucket                  = aws_s3_bucket.dados.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "dados" {
  bucket = aws_s3_bucket.dados.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "dados" {
  bucket = aws_s3_bucket.dados.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3.arn
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "dados" {
  bucket = aws_s3_bucket.dados.id

  rule {
    id     = "limpeza"
    status = "Enabled"

    filter {}

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}

resource "aws_security_group" "ssh_restrito" {
  #checkov:skip=CKV2_AWS_5:SG de exemplo, o anexo a uma instancia fica fora do escopo deste repositorio
  name        = "ssh-restrito"
  description = "SSH somente a partir da rede administrativa"

  ingress {
    description = "SSH da rede administrativa"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/24"]
  }
}
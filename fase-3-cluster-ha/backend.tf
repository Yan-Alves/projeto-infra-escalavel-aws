terraform {
  backend "s3" {
    bucket         = "<COLOQUE_AQUI_O_NOME_DO_SEU_BUCKET>"
    key            = "fase-3/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
  }
}
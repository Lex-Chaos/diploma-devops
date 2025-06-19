terraform {
  backend "s3" {
    endpoints = {
      s3 = "https://storage.yandexcloud.net"
    }
    bucket         = var.bucket
    key            = "terraform.tfstate"
    region         = "ru-central1"
    access_key     = var.access_key
    secret_key     = var.secret_key
    skip_region_validation      = true
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
  }
}
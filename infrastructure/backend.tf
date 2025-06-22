terraform {
  backend "s3" {
    endpoints = {
      s3 = "https://storage.yandexcloud.net"
    }
    bucket                      = "BUCKET_NAME"  # Replace with actual bucket name
    region                      = "ru-central1"
    key                         = "terraform.tfstate"
    access_key                  = "ACESS_KEY"   # Will be replaced
    secret_key                  = "SECRET_KEY"   # Will be replaced
    skip_region_validation      = true
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
    skip_metadata_api_check     = true
  }
}

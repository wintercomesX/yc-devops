terraform {
  backend "s3" {
    endpoints = {
      s3 = "https://storage.yandexcloud.net"
    }
    bucket                      = "terraform-state-f95e2cfe"  # Replace with actual bucket name
    region                      = "ru-central1"
    key                         = "terraform.tfstate"
    access_key                  = "YCAJEHAT8Qw6sL8jSOZ1-LNO3"   # Will be replaced
    secret_key                  = "YCPn3TxvMQr1Y9l6GJDC4YiAWt_uYeQ494t-kzot"   # Will be replaced
    skip_region_validation      = true
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
    skip_metadata_api_check     = true
  }
}

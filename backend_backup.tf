terraform {
  backend "s3" {
    endpoints = {
      s3 = "https://storage.yandexcloud.net"
    }
    bucket                      = "terraform-state-7f7ac65d"  # Replace with actual bucket name
    region                      = "ru-central1"
    key                         = "terraform.tfstate"
    access_key                  = "YCAJEV1sOru-4ltIydCI0p8sp"   # Will be replaced
    secret_key                  = "YCM6uxEnwZB4iWzOXBK9cl1gj7glJrntomaM99x_"   # Will be replaced
    skip_region_validation      = true
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
    skip_metadata_api_check     = true
  }
}

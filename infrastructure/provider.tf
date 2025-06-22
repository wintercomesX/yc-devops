terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "0.124.0"
    }
  }
  required_version = ">=1.8.4"
}

provider "yandex" {
  service_account_key_file     = file("/root/cloudhw/authorized_key.json")
  cloud_id  = "b1gok7td6eko66eb27qa"
  folder_id = "b1gghnpp51joeriep6bo"
  # Optional: specify the zone
  #zone      = "ru-central1-a"
}

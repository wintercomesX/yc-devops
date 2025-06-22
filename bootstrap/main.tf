#terraform {
#  required_providers {
#    yandex = {
#      source = "yandex-cloud/yandex"
#    }
#  }
#  required_version = ">= 0.13"
#}

#provider "yandex" {
  # Use YC_TOKEN environment variable or yc config
#  cloud_id  = var.cloud_id
#  folder_id = var.folder_id
#  zone      = var.default_zone
#}

# Create service account for Terraform
resource "yandex_iam_service_account" "terraform" {
  name        = "terraform-sa"
  description = "Service account for Terraform"
}

# Grant necessary permissions
resource "yandex_resourcemanager_folder_iam_member" "terraform_editor" {
  folder_id = var.folder_id
  role      = "editor"
  member    = "serviceAccount:${yandex_iam_service_account.terraform.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "terraform_storage_admin" {
  folder_id = var.folder_id
  role      = "storage.admin"
  member    = "serviceAccount:${yandex_iam_service_account.terraform.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "terraform_k8s_admin" {
  folder_id = var.folder_id
  role      = "k8s.admin"
  member    = "serviceAccount:${yandex_iam_service_account.terraform.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "terraform_kms_admin" {
  folder_id = var.folder_id
  role      = "kms.admin"
  member    = "serviceAccount:${yandex_iam_service_account.terraform.id}"
}

# Create service account key
resource "yandex_iam_service_account_static_access_key" "terraform_key" {
  service_account_id = yandex_iam_service_account.terraform.id
  description        = "Static access key for Terraform"
}

# Create KMS key for bucket encryption
resource "yandex_kms_symmetric_key" "terraform_key" {
  name              = "terraform-state-key"
  description       = "KMS key for Terraform state bucket encryption"
  default_algorithm = "AES_128"
  rotation_period   = "8760h" # 1 year
}

# Grant service account access to KMS key
resource "yandex_kms_symmetric_key_iam_binding" "terraform_key_binding" {
  symmetric_key_id = yandex_kms_symmetric_key.terraform_key.id
  role             = "kms.keys.encrypterDecrypter"
  members = [
    "serviceAccount:${yandex_iam_service_account.terraform.id}",
  ]
}

# Create S3 bucket for Terraform state
resource "yandex_storage_bucket" "terraform_state" {
  bucket        = "terraform-state-${random_id.bucket_suffix.hex}"
  access_key    = yandex_iam_service_account_static_access_key.terraform_key.access_key
  secret_key    = yandex_iam_service_account_static_access_key.terraform_key.secret_key
  force_destroy = true

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        kms_master_key_id = yandex_kms_symmetric_key.terraform_key.id
        sse_algorithm     = "aws:kms"
      }
    }
  }

  depends_on = [
    yandex_kms_symmetric_key_iam_binding.terraform_key_binding,
    yandex_resourcemanager_folder_iam_member.terraform_storage_admin
  ]
}

resource "random_id" "bucket_suffix" {
  byte_length = 4
}

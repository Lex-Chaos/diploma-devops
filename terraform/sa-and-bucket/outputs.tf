output "bucket_name" {
  value = yandex_storage_bucket.diploma-tfstate-bucket.bucket
}

output "sa_access_key" {
  value = yandex_iam_service_account_static_access_key.diploma-sa-key.access_key
  sensitive = true
}

output "sa_secret_key" {
  value = yandex_iam_service_account_static_access_key.diploma-sa-key.secret_key
  sensitive = true
}

# Формирование файла для бэкенда
resource "local_file" "backend_config" {
  filename = "${path.module}/../infrastruct/backend.tf"
  content = templatefile("${path.module}/backend.tftpl", {
    bucket_name   = yandex_storage_bucket.diploma-tfstate-bucket.bucket
    access_key    = yandex_iam_service_account_static_access_key.diploma-sa-key.access_key 
    secret_key    = yandex_iam_service_account_static_access_key.diploma-sa-key.secret_key
    state_path    = "terraform.tfstate"  # Путь к файлу состояния
  })

  lifecycle {
    replace_triggered_by = [
      yandex_storage_bucket.diploma-tfstate-bucket.bucket,
      yandex_iam_service_account_static_access_key.diploma-sa-key.access_key,
      yandex_iam_service_account_static_access_key.diploma-sa-key.secret_key
    ]
  }
}

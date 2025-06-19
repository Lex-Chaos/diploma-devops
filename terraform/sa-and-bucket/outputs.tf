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
  filename = "${path.module}/../infrastruct/bucket-auth.auto.tfvars"
  content = templatefile("${path.module}/backend.tftpl", {
    bucket_name   = yandex_storage_bucket.diploma-tfstate-bucket.bucket
    access_key    = yandex_iam_service_account_static_access_key.diploma-sa-key.access_key 
    secret_key    = yandex_iam_service_account_static_access_key.diploma-sa-key.secret_key
  })

  lifecycle {
    replace_triggered_by = [
      yandex_storage_bucket.diploma-tfstate-bucket.bucket,
      yandex_iam_service_account_static_access_key.diploma-sa-key.access_key,
      yandex_iam_service_account_static_access_key.diploma-sa-key.secret_key
    ]
  }
}

# Ресурс для автоматического запуска terraform init для инфраструктуры
resource "null_resource" "run_terraform_init" {
  triggers = {
    always_run = timestamp() # Запускать при каждом применении
  }

  provisioner "local-exec" {
    command = <<-EOT
      cd ${path.module}/../infrastruct && \
      terraform init -reconfigure \
        -backend-config="bucket=${yandex_storage_bucket.diploma-tfstate-bucket.bucket}" \
        -backend-config="access_key=${yandex_iam_service_account_static_access_key.diploma-sa-key.access_key}" \
        -backend-config="secret_key=${yandex_iam_service_account_static_access_key.diploma-sa-key.secret_key}"
    EOT
    
    interpreter = ["bash", "-c"]
  }

  depends_on = [
    yandex_storage_bucket.diploma-tfstate-bucket,
    yandex_iam_service_account_static_access_key.diploma-sa-key,
    local_file.backend_config
  ]
}
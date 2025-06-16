# Создание сервисного аккаунта
resource "yandex_iam_service_account" "diploma-sa" {
  name        = "sa-diploma"
  description = "Сервис-аккаунт"
}

# Назначение роли admin
resource "yandex_resourcemanager_folder_iam_binding" "diploma-sa-role" {
  folder_id = var.folder_id
  
  for_each  = toset([
    "editor",
    "storage.admin"
  ])

  role      = each.key
  members   = [
    "serviceAccount:${yandex_iam_service_account.diploma-sa.id}"
  ]
}

# Создание статического ключа
resource "yandex_iam_service_account_static_access_key" "diploma-sa-key" {
  service_account_id = yandex_iam_service_account.diploma-sa.id
}

# Создание бакета
resource "yandex_storage_bucket" "diploma-tfstate-bucket" {
  bucket = "tfstate-backet-borovikaa"
  
  acl = "private"
  access_key = yandex_iam_service_account_static_access_key.diploma-sa-key.access_key
  secret_key = yandex_iam_service_account_static_access_key.diploma-sa-key.secret_key

  depends_on = [
    yandex_resourcemanager_folder_iam_binding.diploma-sa-role
  ]
}


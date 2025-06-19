variable "github-actions" {
  description = "Триггер для работы с github actions"
  default = "true"
}
# Переменные для авторизации на yandex-cloud
variable "cloud_id" {
  description = "Yandex Cloud ID"
  type        = string
}

variable "folder_id" {
  description = "Yandex Folder ID"
  type        = string
}

variable "token" {
  description = "Yandex OAuth token"
  type        = string
  sensitive   = true
}
# ---------------------------

# Переменные для создания инстансов
variable "vm_web_family" {
  type        = string
  default     = "ubuntu-2004-lts"
  description = "Семейство"
}

variable "ssh_public_key" {
  description = "ssh-public-key"
  type = string
}
# Переменные для бэкэнда которые не применяются во время инициализации
variable "bucket" {
  description = "bucket name"
  type = string
}

variable "access_key" {
  description = "bucket access key"
  type = string
}

variable "secret_key" {
  description = "bucket secret key"
  type = string
}
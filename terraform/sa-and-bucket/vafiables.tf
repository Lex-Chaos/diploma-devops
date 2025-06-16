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
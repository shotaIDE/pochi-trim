variable "project_id_suffix" {
  description = "Google CloudのプロジェクトIDの接尾辞"
  type        = string
}

variable "project_display_name_suffix" {
  description = "Google Cloudのプロジェクト表示名の接尾辞"
  type        = string
}

variable "billing_account_id" {
  description = "請求先アカウントID"
  type        = string
}

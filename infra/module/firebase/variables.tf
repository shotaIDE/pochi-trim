variable "project_id_suffix" {
  type        = string
  description = "Google CloudのプロジェクトIDの接尾辞"
}

variable "project_display_name_suffix" {
  type        = string
  description = "Google Cloudのプロジェクト表示名の接尾辞"
}

variable "google_billing_account_id" {
  type        = string
  description = "Google Cloudの請求先アカウントID"
}

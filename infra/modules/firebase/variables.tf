variable "project_id" {
  description = "GCPプロジェクトID"
  type        = string
}

variable "project_display_name" {
  description = "GCPプロジェクト表示名"
  type        = string
}

variable "billing_account_id" {
  description = "請求先アカウントID"
  type        = string
}

variable "services" {
  description = "有効化するAPIサービスのリスト"
  type        = list(string)
  default     = [
    "cloudbilling.googleapis.com",
    "cloudbuild.googleapis.com",
    "cloudfunctions.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "cloudtasks.googleapis.com",
    "firebase.googleapis.com",
    "firebaserules.googleapis.com",
    "firebasestorage.googleapis.com",
    "firestore.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "identitytoolkit.googleapis.com",
    "serviceusage.googleapis.com",
    "sts.googleapis.com",
  ]
}

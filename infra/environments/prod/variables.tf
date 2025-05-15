variable "google_billing_account_id" {
  type        = string
  description = "請求先アカウントID"
}

variable "google_project_location" {
  type        = string
  description = "GCPプロジェクトのロケーション"
}

variable "ios_app_team_id" {
  type        = string
  description = "iOS開発者チームID"
}

variable "firebase_android_app_sha1_hashes" {
  type        = list(string)
  description = "AndroidアプリのSHA-1ハッシュリスト"
}

variable "project_id" {
  description = "GCPプロジェクトID"
  type        = string
}

variable "application_id" {
  description = "アプリケーションID"
  type        = string
}

variable "ios_app_team_id" {
  description = "iOS開発者チームID"
  type        = string
}

variable "android_app_sha1_hashes" {
  description = "AndroidアプリのSHA-1ハッシュリスト"
  type        = list(string)
}

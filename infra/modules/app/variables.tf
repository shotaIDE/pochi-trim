variable "project_id" {
  description = "Google CloudのプロジェクトID"
  type        = string
}

variable "application_id_suffix" {
  description = "iOS、AndroidアプリにおけるアプリケーションID等の接尾辞"
  type        = string
}

variable "ios_app_team_id" {
  description = "Apple開発者アカウントのチームID"
  type        = string
}

variable "android_app_sha1_hashes" {
  description = "AndroidアプリのSHA-1ハッシュリスト"
  type        = list(string)
}

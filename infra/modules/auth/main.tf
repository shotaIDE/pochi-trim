terraform {
  required_providers {
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "6.35.0"
      configuration_aliases = []
    }
  }
}

resource "google_identity_platform_config" "auth" {
  provider                   = google-beta
  project                    = var.project_id
  autodelete_anonymous_users = false

  sign_in {
    allow_duplicate_emails = false

    # 匿名認証の設定をハードコード
    anonymous {
      enabled = true
    }

    # メール認証の設定をハードコード
    email {
      enabled           = false
      password_required = false
    }

    phone_number {
      enabled            = false
      test_phone_numbers = {}
    }
  }

  multi_tenant {
    allow_tenants = false
  }
}

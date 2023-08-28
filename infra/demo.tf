/**
 * Copyright 2023 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

locals {
  apis = {
    run           = "run.googleapis.com"
    cloudbuild    = "cloudbuild.googleapis.com"
    sqladmin      = "sqladmin.googleapis.com"
    secretmanager = "secretmanager.googleapis.com"
    iam           = "iam.googleapis.com"
  }

  demo_application = "demo-application"
}

// Service accounts

resource "google_project_iam_member" "sql-client" {
  project = var.project
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.backend_sa.email}"
}

resource "google_project_service_identity" "build_sa" {
  provider = google-beta
  project  = var.project
  service  = "cloudbuild.googleapis.com"
}

resource "google_project_iam_member" "sql_client_build" {
  project = var.project
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_project_service_identity.build_sa.email}"
}

# APIs

resource "google_project_service" "apis" {
  project            = var.project
  for_each           = local.apis
  service            = each.value
  disable_on_destroy = false
}

# Cloud Run

resource "google_service_account" "backend_sa" {
  account_id   = local.demo_application
  display_name = "Demo Application"
  project      = var.project
}

data "google_iam_policy" "backend_policy" {
  binding {
    role = "roles/run.invoker"
    members = [
      "allUsers"
    ]
  }

  binding {
    role = "roles/run.admin"
    members = [
      "serviceAccount:${google_project_service_identity.build_sa.email}",
    ]
  }
}

resource "google_cloud_run_service_iam_policy" "backend" {
  location = google_cloud_run_v2_service.backend.location
  project  = google_cloud_run_v2_service.backend.project
  service  = google_cloud_run_v2_service.backend.name

  policy_data = data.google_iam_policy.backend_policy.policy_data
}

resource "google_cloud_run_v2_service" "backend" {
  depends_on = [
    google_project_service.apis["run"],
    google_service_account.backend_sa,
  ]

  name     = "${local.demo_application}-backend"
  project  = var.project
  location = var.region
  ingress  = "INGRESS_TRAFFIC_ALL"

  template {
    service_account = google_service_account.backend_sa.email

    scaling {
      max_instance_count = 2
    }

    volumes {
      name = "cloudsql"
      cloud_sql_instance {
        instances = [google_sql_database_instance.database.connection_name]
      }
    }

    containers {
      image = var.image

      env {
        name  = "DB_USER"
        value = google_sql_user.backend.name
      }

      env {
        name = "DB_PASS"
        value_source {
          secret_key_ref {
            secret  = google_secret_manager_secret_version.sql_password.secret
            version = google_secret_manager_secret_version.sql_password.version
          }
        }
      }

      env {
        name  = "INSTANCE_CONNECTION_NAME"
        value = google_sql_database_instance.database.connection_name
      }

      volume_mounts {
        name       = "cloudsql"
        mount_path = "/cloudsql"
      }
    }
  }

  traffic {
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
    percent = 100
  }
}

#
# Database
#

resource "random_password" "sql_password" {
  length      = 20
  min_lower   = 4
  min_numeric = 4
  min_special = 4
  min_upper   = 4
}

resource "google_secret_manager_secret" "sql_password" {
  depends_on = [
    google_project_service.apis["secretmanager"]
  ]
  secret_id = "${local.demo_application}-sql-password"
  project   = var.project

  replication {
    automatic = true
  }
}

resource "google_secret_manager_secret_iam_member" "sql_password" {
  project   = google_secret_manager_secret.sql_password.project
  secret_id = google_secret_manager_secret.sql_password.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.backend_sa.email}"
}

resource "google_secret_manager_secret_iam_member" "cloud_build_password" {
  project   = google_secret_manager_secret.sql_password.project
  secret_id = google_secret_manager_secret.sql_password.secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_project_service_identity.build_sa.email}"
}

resource "google_secret_manager_secret_version" "sql_password" {
  secret      = google_secret_manager_secret.sql_password.id
  enabled     = true
  secret_data = random_password.sql_password.result
}

resource "google_sql_database_instance" "database" {
  depends_on = [
    google_project_service.apis["sqladmin"],
  ]

  name                = "${local.demo_application}-database"
  project             = var.project
  region              = var.region
  database_version    = "MYSQL_8_0"
  deletion_protection = false

  settings {
    tier = "db-n1-standard-2"
  }
}

resource "google_sql_user" "backend" {
  name     = "backend"
  project  = var.project
  instance = google_sql_database_instance.database.id
  password = random_password.sql_password.result
}

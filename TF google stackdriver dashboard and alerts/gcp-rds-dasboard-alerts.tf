module "slack"{
 source = "./modules/stackdriver-monitoring"
}

data "template_file" "dashboard" {
  template = "${file("${path.module}/template_rds_dashboard.json")}"
  vars = {
    rds_name = "${var.rds_name}"
    gcp_project = "${var.gcp_project}"
  }
}

resource "local_file" "dash" {
    content     = data.template_file.dashboard.rendered
    filename = "${path.module}/rds_dashboard.json"   
}

resource "local_file" "gcp_sd_creds" {
  content = var.gcp_sd_creds
  filename = "${path.module}/gcp_sd_creds.json"
}

module "deploy_dashboard" {
  source = "./modules/deploy-dashboard-gcp"
  dashboard_name = "${var.rds_name}-AWSRDS"
  dashboard_json = local_file.dash.filename
  project_gcp = var.gcp_project
  key_file = local_file.gcp_sd_creds.filename
}

resource "google_monitoring_alert_policy" "AWS_RDS_CPU95" {
  display_name = "RDS-${var.rds_name}-CPU95"
  combiner     = "OR"

  conditions {
    display_name = "CPU 95"
    condition_threshold {
      threshold_value = 0.95
      filter     = "metric.type=\"aws.googleapis.com/RDS/CPUUtilization/Sum\" resource.type=\"aws_rds_database\" resource.label.\"name\"=\"${var.rds_name}\""
      duration   = "300s"
      comparison = "COMPARISON_GT"
      trigger {
          count = 1
      }
      aggregations {
        alignment_period = "60s"
        per_series_aligner = "ALIGN_RATE"
      }
    }
  }
  notification_channels = [module.slack.notification_channel]
}

resource "google_monitoring_alert_policy" "AWS_RDS_Disk95" {
  display_name = "RDS-${var.rds_name}-Disk95"
  combiner     = "OR"

  conditions {
    display_name = "Disk 95"
    condition_threshold {
      threshold_value = ((var.rds_disk_size / 100) * 95) * 1073741824
      filter = "metric.type=\"aws.googleapis.com/RDS/FreeStorageSpace/Minimum\" resource.type=\"aws_rds_database\" resource.label.\"name\"=\"${var.rds_name}\""
      duration   = "300s"
      comparison = "COMPARISON_GT"
      trigger{
          count = 1
      }
      aggregations {
        alignment_period = "60s"
        per_series_aligner = "ALIGN_MEAN"
      }
    }
  }
  notification_channels = [module.slack.notification_channel]
}

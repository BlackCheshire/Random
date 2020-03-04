resource "google_monitoring_notification_channel" "slack" {
  display_name = "Slack Notification Channel"
  type         = "slack"
  labels = {
    auth_token = ""
    channel_name = "#monitoring"
  }
}

resource "google_monitoring_alert_policy" "cpu" {
  display_name = "CPU Load"
  combiner     = "OR"

  conditions {
    display_name = "CPU Load"
    condition_threshold {
      threshold_value = 5
      filter     = "metric.type=\"agent.googleapis.com/cpu/utilization\" resource.type=\"${var.resource}\" metric.label.\"cpu_state\"=\"idle\""
      duration   = "900s"
      comparison = "COMPARISON_LT"

      aggregations {
          per_series_aligner = "ALIGN_MEAN"
          alignment_period = "60s"
          cross_series_reducer = "REDUCE_NONE"
      }
    }
  }
  notification_channels = [ google_monitoring_notification_channel.slack.id ]
}

resource "google_monitoring_alert_policy" "free_disk_space" {
  display_name = "Free disk space"
  combiner     = "OR"

  conditions {
    display_name = "Free disk space"
    condition_threshold {
      threshold_value = 10
      filter     = "metric.type=\"agent.googleapis.com/disk/percent_used\" resource.type=\"${var.resource}\" metric.label.\"device\"!=monitoring.regex.full_match(\"loop.*\") metric.label.\"device\"!=\"tmpfs\" metric.label.\"device\"!=\"udev\" metric.label.\"device\"!=\"shm\" metric.label.\"state\"=\"free\" metric.label.\"device\"!=\"overlay\""
      duration   = "60s"
      comparison = "COMPARISON_LT"

      aggregations {
          per_series_aligner = "ALIGN_MEAN"
          alignment_period = "60s"
          cross_series_reducer = "REDUCE_NONE"
      }
    }
  }
  notification_channels = [ google_monitoring_notification_channel.slack.id ]
}

output "notification_channel" {
    value = "${google_monitoring_notification_channel.slack.id}"    
} 
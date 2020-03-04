resource "null_resource" "deploy_dashboard" {
   
    provisioner "local-exec" {
        command = "gcloud auth activate-service-account --key-file=${var.key_file};"
    }
    provisioner "local-exec" {
      command = "gcloud alpha monitoring dashboards create --config-from-file=${var.dashboard_json} --project=${var.project_gcp}"
      on_failure = continue
    }
    provisioner "local-exec" {
      command = "./update.sh ${var.dashboard_name} ${var.project_gcp} ${var.dashboard_json};"
      on_failure = continue
    }
}
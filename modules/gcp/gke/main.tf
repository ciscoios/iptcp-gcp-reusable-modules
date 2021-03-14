resource "google_container_cluster" "primary" {
  name     = var.cluster_name
  # node_locations = [
  #   var.zone,
  # ]
  location = var.zone
  project    = var.project
  remove_default_node_pool = var.remove_default_node_pool
  initial_node_count       = 1
  min_master_version = var.cluster_version
  master_auth {
     username = ""
     password = ""

     client_certificate_config {
       issue_client_certificate = var.issue_client_certificate
     }
   }
  addons_config {
    horizontal_pod_autoscaling {
      disabled = true
    }
    http_load_balancing {
      disabled = true
    }
    network_policy_config {
      disabled = true
    }
  }

}

resource "google_container_node_pool" "primary_preemptible_nodes" {
  name       = "k8s-playground1"
  project    = var.project
  location   = var.zone
  cluster    = google_container_cluster.primary.name
  node_count = var.node_count
  version    = var.cluster_version

  management {
    auto_repair  = var.auto_repair
    auto_upgrade = var.auto_upgrade
  }
  node_config {
    preemptible  = var.preemptible 
    machine_type = var.machine_type 
    disk_size_gb = var.disk_size_gb

    metadata = {
      disable-legacy-endpoints = "true"
    }
     labels = { 
        "environment" = "test"
        "team"        = "devops"
      }

    oauth_scopes = [

      "https://www.googleapis.com/auth/cloud-platform"
      #"https://www.googleapis.com/auth/compute",
      #"https://www.googleapis.com/auth/devstorage.read_only",
      #"https://www.googleapis.com/auth/logging.write",
      #"https://www.googleapis.com/auth/monitoring"
    ]
  }
}

#Retrieve authentication token
data "google_client_config" "default" {
  name = google_container_node_pool.primary.name
}
data "google_container_cluster" "primary" {}

data "template_file" "kubeconfig" {
  template = file("${path.module}/kubeconfig-template.yaml.tpl")

  vars = {
    context                = data.google_container_cluster.primary.name
    cluster_ca_certificate = data.google_container_cluster.primary.master_auth
    endpoint               = data.google_container_cluster.primary.endpoint
    token                  = data.google_client_config.default.access_token
  }
}


resource "local_file" "kubeconfig" {
  content  = data.template_file.kubeconfig.rendered
  filename = "${path.module}/.kube/config"
}  
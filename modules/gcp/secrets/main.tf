
 resource "google_secret_manager_secret" "secret-basic" {
  depends_on = [var.local_file]
  secret_id = "tf-ansible-vars"
  
  labels = {
    label = "tf-ansible-vars"
  }

   replication {
    automatic = true
 #    automatic = false
 
  } 
}

resource "google_secret_manager_secret_version" "secret-version-basic" {
   depends_on = [var.local_file]
   secret = google_secret_manager_secret.secret-basic.id
   #secret_data = file(var.tf_ansible_vars_file)
   secret_data = base64encode(file("${path.root}/ansible/tf_ansible_vars_file.yml.tpl"))
}
 

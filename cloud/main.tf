variable "project_id" {
  type = string
  default = "temp-project-305816"
}

provider "google" {
  project = var.project_id
  region  = "us-central1"
  zone    = "us-central1-c"
  credentials = file("source_account.json")
}

// enable apis  
variable "project_services" {
  default = [
    "compute.googleapis.com",
    "iam.googleapis.com",
  ]
}

resource "google_project_service" "services" {
  count   = length(var.project_services)
  project     = var.project_id
  service    = var.project_services[count.index]
  disable_dependent_services = true
}

resource "google_compute_network" "vpc_network" {
  depends_on = [ 
    google_project_service.services
   ]
  name                    = "${var.project_id}-network"

  auto_create_subnetworks = "true"
}

resource "google_compute_instance" "api" {
  name         = "api"
  machine_type = "e2-small"

  tags = ["web-server"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-1804-bionic-v20210211"
    }
  }

  network_interface {
    network = google_compute_network.vpc_network.self_link
    access_config {
    }
  }
}

resource "google_compute_instance" "db-master" {
  name         = "db-master"
  machine_type = "e2-small"

  tags = ["db-server"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-1804-bionic-v20210211"
    }
  }

  network_interface {
    network = google_compute_network.vpc_network.self_link
    access_config {
    }
  }
}

resource "google_compute_instance" "db-slave" {
  name         = "db-slave"
  machine_type = "e2-small"

  tags = ["db-server"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-1804-bionic-v20210211"
    }
  }

  network_interface {
    network = google_compute_network.vpc_network.self_link
    access_config {
    }
  }
}

resource "google_compute_firewall" "allow-ssh" {
  name = "allow-ssh"
  network = google_compute_network.vpc_network.self_link
  //allow {
  //  protocol = "icmp"
  //}
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  // Allow traffic from everywhere 
  source_ranges = ["0.0.0.0/0"]

  //If no targetTags are specified, the firewall rule applies to all instances on the specified network.
  //target_tags   = ["http-server"]
}


resource "google_compute_firewall" "web-server" {
  name = "web-server"
  network = google_compute_network.vpc_network.self_link

  allow {
    protocol = "tcp"
    ports    = ["80","443"]
  }

  source_ranges = ["0.0.0.0/0"]

  target_tags   = ["web-server"]
}


resource "google_compute_firewall" "db-server" {
  name = "db-server"
  network = google_compute_network.vpc_network.self_link

  allow {
    protocol = "tcp"
    ports    = ["5432"]
  }

  source_ranges = ["0.0.0.0/0"]

  target_tags   = ["db-server"]
}

resource "google_compute_project_metadata" "ssh_keys" {
  depends_on = [ 
    google_project_service.services
  ]
  metadata = {
    ssh-keys = "root:${file("test.pub")}"
  }
}

output "vm_name" {
  value = google_compute_instance.api.name
}
output "public_ip" {
  value = google_compute_instance.api.network_interface[0].access_config[0].nat_ip
}
output "private_ip" {
  value = google_compute_instance.api.network_interface[0].network_ip
}

# generate inventory file for Ansible
resource "local_file" "inventory" {
  filename = "inventory"
  content = <<-EOT
    api ansible_host=${google_compute_instance.api.network_interface[0].access_config[0].nat_ip}
    db-master ansible_host=${google_compute_instance.db-master.network_interface[0].access_config[0].nat_ip}
    db-salve ansible_host=${google_compute_instance.db-slave.network_interface[0].access_config[0].nat_ip}
  EOT
}

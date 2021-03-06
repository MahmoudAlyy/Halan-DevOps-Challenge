variable "project_id" {
  type = string
  default = "COPY-YOUR-PROJECT-ID-HERE"
}

provider "google" {
  project = var.project_id
  region  = "us-central1"
  zone    = "us-central1-c"
  credentials = file("service_account.json")
}

// need to enable cloud resource manager first b4 enabling the other apis
resource "google_project_service" "service_resource_manager" {
  project     = var.project_id
  service    = "cloudresourcemanager.googleapis.com"
  disable_dependent_services = true
}
//

// enable apis  
variable "project_services" {
  default = [
    "compute.googleapis.com",
    "iam.googleapis.com",
    "sqladmin.googleapis.com",
    "servicenetworking.googleapis.com",
  ]
}

resource "google_project_service" "services" {
  depends_on = [ 
    google_project_service.service_resource_manager,
   ]
  count   = length(var.project_services)
  project     = var.project_id
  service    = var.project_services[count.index]
  disable_dependent_services = true
}
//

resource "google_compute_network" "vpc_network" {
  depends_on = [ 
    google_project_service.services
   ]
  name = "${var.project_id}-network"
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


resource "google_sql_database_instance" "master" {
  name  = "master-21"
  region  = "us-central1"

  database_version = "POSTGRES_11"

  depends_on = [ 
    google_project_service.services,
    google_service_networking_connection.private_vpc_connection,
  ]
  
  settings {
    tier              = "db-f1-micro"
    availability_type = "ZONAL"
    ip_configuration {
      // no public ip
      ipv4_enabled    = false
      private_network = google_compute_network.vpc_network.id
    }
    location_preference {
      zone    = "us-central1-c"
    }
  }
}

resource "google_sql_database_instance" "read_replica" {
  name                 = "replica-21"
  master_instance_name = google_sql_database_instance.master.name
  region  = "us-central1"
  database_version     = "POSTGRES_11"

  replica_configuration {
    failover_target = false
  }

  settings {
    tier              = "db-f1-micro"
    availability_type = "ZONAL"

    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.vpc_network.id
    }
    location_preference {
      zone    = "us-central1-c"
    }
  }
}

/// for db to work using private ip
resource "google_compute_global_address" "private_ip_address" {

   depends_on = [ 
    google_project_service.services,
  ]

  name          = "private-ip-address"
  purpose       = "VPC_PEERING"
  address_type  = "INTERNAL"
  prefix_length = 16
  network       = google_compute_network.vpc_network.id
}

resource "google_service_networking_connection" "private_vpc_connection" {
   depends_on = [ 
    google_project_service.services,
  ]

  network                 = google_compute_network.vpc_network.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_ip_address.name]
}
//

// user and password for db
resource "google_sql_user" "main" {
  depends_on = [
    google_sql_database_instance.master
  ]
  name     = "main"
  instance = google_sql_database_instance.master.name
  password = "password"
}
//

// the db inside the postgres instatnce
resource "google_sql_database" "main" {
  depends_on = [
    google_sql_user.main
  ]
  name     = "main"
  instance = google_sql_database_instance.master.name
}
//

// to allow ansible to ssh into our instance
resource "google_compute_firewall" "allow-ssh" {
  name = "allow-ssh"
  network = google_compute_network.vpc_network.self_link
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  // Allow traffic from everywhere 
  source_ranges = ["0.0.0.0/0"]

  //If no targetTags are specified, the firewall rule applies to all instances on the specified network.
  //target_tags   = ["allow-ssh"]
}
//

// allow http
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
//

// load our generated ssh key into metadata - used by ansible
resource "google_compute_project_metadata" "ssh_keys" {
  depends_on = [ 
    google_project_service.services
  ]
  metadata = {
    ssh-keys = "root:${file("root-ssh-key.pub")}"
  }
}
//

// generate inventory file for Ansible containing our instance public IP
resource "local_file" "inventory" {
  filename = "inventory"
  content = <<-EOT
    api ansible_host=${google_compute_instance.api.network_interface[0].access_config[0].nat_ip}  ansible_python_interpreter=auto
  EOT
}
//

// create environment variable for our instace to connect to db using internal IP
resource "local_file" "api-env" {
  filename = "./Dockerized_app/api.env"
  content = <<-EOT
    PGHOST=${google_sql_database_instance.master.private_ip_address}
    PGDATABASE=${google_sql_database.main.name}
    PGUSER=${google_sql_user.main.name}
    PGPASSWORD=${google_sql_user.main.password}
  EOT
}
//
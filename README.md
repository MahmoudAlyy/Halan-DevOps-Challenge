
# Halan-DevOps-Challenge
A Fully provisioned environment on **GCP** using **Terraform** & **Ansible** that deploys:
1. VM instance running a **Dockerized** flask application.
2. SQL instance (Postgres).
3. SQL read replica instance.

## Setup
#### 1- Create Project & Service Account
1. Create a new **GCP** project.
2. Select **IAM & Admin - Service Accounts** from navigation menu.
3. Create a new Service Account
4. Enter a service account name & click Create.
5. Grant **Owner** access & click **Done**.
6. Click **Actions** on the newly created Service Account and choose **Manage keys**.
7. Click **add key** & Create **new key**.
8. Choose type **json** and click Create.

A json file will automatically be downloaded.  

Rename this file to **service_account.json** and copy it to the repository directory.
#### 2- Get Project ID

Go to **GCP** Dashboard and copy the project ID and paste it in main.tf
```
variable  "project_id" {
type  =  string
default  =  "COPY-YOUR-PROJECT-ID-HERE"
}
```



#### 3- Install [Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli) and [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html) on your local host 
#### 4- Run the script
```
chmod +x script
./script
```
The script will output the Public IP for the Compute instance.



## Under the Hood
First the script creates an SSH (stored in the metadata by Terraform and used by Ansible to configure the Compute instance), then it runs Terraform & Ansible.

### Terraform:
- Enables the following APIs:
compute, iam, sqladmin, servicenetworking & cloudresourcemanager.
- Creates a new VPC for Compute instance.
- Creates Compute instance.
- Creates a master SQL instance running Postgres which is only accessible using an internal IP address.
- Creates a read replica for master SQL instance.
 - VPC peering between Compute instance and SQL instance.
- User, Password & Database for SQL instance.
- Firewall rule to allow SSH and HTTP into Compute instance.
- Load the generated SSH key into metadata.
- Generate inventory file for Ansible containing Compute instance public IP.
- Creates api.env which will be used as an environment variable for docker-compose. Contains required info to authenticate with Postgres.
### Ansible:
- Copy Dockerized_app into the instance.
- Install and run docker-compose.


## API
```
http://<host-ip>/ --> Halan ROCKS It
http://<host-ip>/?n=x --> n*n 
http://<host-ip>/ip --> IP address of the client
making the request and save that IP address on Postgres
http://<host-ip>/allips --> all of the saved IPs
```

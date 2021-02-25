# Halan-DevOps-Challenge
A Fully provisioned environment on **GCP** using **Terraform** & **Ansible** that deploys:
1. VM Instance running a **Dockerized** flask application.
2. SQL Instance (Postgres)
3. SQL Read replica

## Setup
#### 1- Create Project & Service Account
1. Create a new **GCP** project
2. Select **IAM & Admin - Service Accounts** from navigation menu
3. Enter a service account name
4. Grant **Owner** access & click **Done**
5. Click **Actions** on Service Account and choose **Manage keys**
6. Click **add key** & Create **new key**
7. Choose type **json** and Create

A json file will automatically be downloaded.
Rename this file to **service_account.json** and copy it to the repository directory.
#### 2- Get Project ID

Go to **GCP** Home and copy the project ID and paste it in main.tf
```
variable  "project_id" {
type  =  string
default  =  "COPY-YOUR-PROJECT-ID-HERE"
}
```
#### 3- Install Terraform and Ansible
#### 4- Run the script
```
chmod +x script
./script
```
The script will output the Public IP for the Compute instance.



## Under the Hood
First the script creates an SSH (stored in the metadata by Terraform and used by Ansible to configure compute instance), then it runs Terraform & Ansible.

### Terraform 
- Enables the following APIs:
compute, iam, sqladmin, servicenetworking & cloudresourcemanager.
- Creates a new VPC for Compute instance.
- Creates Compute instance.
- Creates a master SQL instance running Postgres which is only accessible using an internal IP address.
- A read replica.
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

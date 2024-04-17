# Customized the sample values below for your environment and either rename to terraform.tfvars or env.auto.tfvars

### Azure desktop VMs network 
deploy_location      = "northeurope"
rg_name              = "rg-avd-resources" # same rg for workspace/hostpool/dag/ws-dag
prefix               = "avdtf"
local_admin_username = "Avddesktop123adm"
local_admin_password = "Avddesktop123$"
vnet_range           = ["10.1.0.0/16"]
subnet_range         = ["10.1.1.0/24"]
storage_subnet_range = ["10.1.2.0/24"]
dns_servers          = ["10.68.0.58", "10.68.0.61"]
#  "10.0.1.4", "168.63.129.16"
#aad_group_name       = "Terraform-RPA"
#aad_group_name_avd   = "AVDUsers"
domain_name          = "A03-P1-DOM009.tka.local"
domain_user_upn      = "TESTCIFS"     # do not include domain name as this is appended
domain_password      = "tk2006"       # give dummy values here and pass by secret in spacelift stack. 
ou_path              = "OU=TK-Cloud,OU=Servers,DC=tka,DC=local"


# hub network AAD Domain controllers. 
ad_vnet              = "vnet-hub-noe-prod"
ad_rg                = "rg-hubvnet-noe-prod"
#avd_users = [
#  "robot.roger.robot.roger@trondheim.kommune.no",
#  "runtimeserver1@trondheim.kommune.no",
#  "appserver1@trondheim.kommune.no",
#  "imageserver1@trondheim.kommune.no",
#  "reportingserver1@trondheim.kommune.no"
#]

# "User": "${var.domain_user_upn}@${var.domain_name}",
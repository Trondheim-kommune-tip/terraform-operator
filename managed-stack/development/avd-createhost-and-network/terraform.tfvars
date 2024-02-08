# Customized the sample values below for your environment and either rename to terraform.tfvars or env.auto.tfvars

deploy_location      = "norway east"
rg_name              = "avd-resources-rg"
prefix               = "avdtf"
local_admin_username = "localadm"
local_admin_password = "ChangeMe123$"
vnet_range           = ["10.1.0.0/16"]
subnet_range         = ["10.1.0.0/24"]
dns_servers          = ["10.0.1.4", "168.63.129.16"]
#aad_group_name       = "Terraform-RPA"
#domain_name          = "trondheim.kommune.no"
domain_user_upn      = "adminrpa"     # do not include domain name as this is appended
domain_password      = "ChangeMe123!"
ad_vnet              = "infra-network"
ad_rg                = "infra-rg"
avd_users = [
  "Mikal.Rekdal@trondheim.kommune.no",
  "sarumathy.soosaipillai@trondheim.kommune.no",
  "Sebastian.S.Eide@trondheim.kommune.no",
  "alok.hom@trondheim.kommune.no",
  "robot.roger.robot.roger@trondheim.kommune.no",
  "caroline.skram.by@trondheim.kommune.no",
  "kitti.lai@trondheim.kommune.no"
]
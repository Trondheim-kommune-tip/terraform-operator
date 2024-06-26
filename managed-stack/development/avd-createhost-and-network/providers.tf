terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.90"
    }
    azuread = {
      source = "hashicorp/azuread"
      version = "~> 2.47.0"
    }
  }
}


# Configure the Azure Active Directory Provider then only domain join worked. above RM was there.
provider "azuread" {
  tenant_id     = "${var.arm_tenant_id}"           # 831195d3-b68b-433a-8687-4cdb1532958e
  alias = "rpa"
}



## AD domains
# it-con-01 AD domain controller access
# useful for the section data "azuread_domains" "avd_domain"
# Configure the Azure Active Directory Provider then only domain join worked. above RM was there.
provider "azuread" {
  client_id     = "${var.arm_client_id}"       # 7b0a46b0-b657-422a-9e03-fb6818021ff6
  client_secret = "${var.arm_client_secret}"   # see lastpass ends with qcnc
  tenant_id     = "${var.arm_tenant_id}"           # 831195d3-b68b-433a-8687-4cdb1532958e
}



#### peering 
#### read https://medium.com/microsoftazure/configure-azure-virtual-network-peerings-with-terraform-762b708a28d4
#####

# RPA subs
provider "azurerm" {
  features {}
  client_id     = "${var.arm_client_id}"         # 7b0a46b0-b657-422a-9e03-fb6818021ff6 This ID has contributor and network contributor role
  client_secret = "${var.arm_client_secret}"     # see lastpass ends with qcnc
  tenant_id     = "${var.arm_tenant_id}"         # 831195d3-b68b-433a-8687-4cdb1532958e TK tenant
  subscription_id = "${var.arm_subscription_id}" # 225e8bed-0445-4aa4-a9b7-a306aca77ad5 RPA subs
}


##### AD 
# it-con-01 AD domain controller access and role assignment using service principal
######
# Configure the Azure Active Directory Provider
# AD role assignment principal
# AD network resource provider for peering need app reg service principles
provider "azurerm" {
  features {}
  client_id     = "7842a4d0-d9d5-469d-9964-05ea505ef848" # app id for rpa-ad-hub-access app reg. This ID has been provided contributor and networkContributor roles
  client_secret = "${var.itcon01_rpa_adhub_secret}" # client secret for rpa-ad-hub-access app reg
  tenant_id     = "${var.arm_tenant_id}"            # 831195d3-b68b-433a-8687-4cdb1532958e
  subscription_id = "${var.ad_arm_subscription_id}" # 1fe8b9ee-48c3-4004-bc0a-d9eddc90d80f ad_arm_subscription_id
  alias = "siteAD"
  #skip_provider_registration = true
}
#######

# RPA network info
# subs id : 225e8bed-0445-4aa4-a9b7-a306aca77ad5
# tenant id: 831195d3-b68b-433a-8687-4cdb1532958e
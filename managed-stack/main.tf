# This resource here is to show you how plan policies work.

resource "random_password" "secret" {
  length  = 36
  special = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}
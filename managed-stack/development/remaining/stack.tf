# Parent stack
resource "spacelift_stack" "avd-rbac" {
  name       = "RPA rbc on azure"
  repository = "terraform-operator"
  branch       = "TKCL-376-challenges-faced-in-code-avd_configure-and-avd_create-host"
  project_root = "managed-stack/development/avd-rbac"
  administrative = true
  autodeploy = true
  labels     = ["avd-rbac", "development"]
  runner_image = "public.ecr.aws/spacelift/runner-terraform:latest"
}

# Child stack
resource "spacelift_stack" "avd-configure" {
  name        = "RPA configure on azure"
  description = "RPA configure stack"
  repository   = "terraform-operator"
  branch       = "TKCL-376-challenges-faced-in-code-avd_configure-and-avd_create-host"
  project_root = "managed-stack/development/avd-configure"
  administrative = true
  autodeploy = true
  labels     = ["avd-configure", "development"]
  runner_image = "public.ecr.aws/spacelift/runner-terraform:latest"
}

# Create the parent-child dependency for run execution ordering
resource "spacelift_stack_dependency" "configure-rbac" {
  stack_id            = spacelift_stack.avd-configure.id
  depends_on_stack_id = spacelift_stack.avd-rbac.id

  //depends_on = [
  //  spacelift_stack_destructor.avd-rbac,
  //  spacelift_stack_destructor.avd-configure
  //]
}

# Child stack
resource "spacelift_stack" "avd-createhost" {
  name       = "RPA host on azure"
  repository = "terraform-operator"
  branch       = "TKCL-376-challenges-faced-in-code-avd_configure-and-avd_create-host"
  project_root = "managed-stack/development/avd-createhost"
  administrative = true
  autodeploy = true
  labels     = ["avd-createhost", "development"]
  runner_image = "public.ecr.aws/spacelift/runner-terraform:latest"
}

# Create the parent-child dependency for run execution ordering
resource "spacelift_stack_dependency" "createhost-rbac" {
  stack_id            = spacelift_stack.avd-createhost.id
  depends_on_stack_id = spacelift_stack.avd-configure.id

  //depends_on = [
  //  spacelift_stack_destructor.avd-createhost,
  //  spacelift_stack_destructor.avd-configure
  //]
}



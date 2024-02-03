# Parent stack
resource "spacelift_stack" "avd-configure" {
  name        = "RPA configure on azure"
  description = "RPA configure stack"
  repository   = "terraform-operator"
  branch       = "master"
  project_root = "managed-stack/development/avd-configure"
  administrative = true
  autodeploy = true
  labels     = ["avd-configure", "development"]
  runner_image = "public.ecr.aws/spacelift/runner-terraform:latest"
}

# Child stack
resource "spacelift_stack" "avd-createhost" {
  name       = "RPA host on azure"
  repository = "terraform-operator"
  repository   = "terraform-operator"
  branch       = "master"
  project_root = "managed-stack/development/avd-createhost"
  administrative = true
  autodeploy = true
  labels     = ["avd-createhost", "development"]
  runner_image = "public.ecr.aws/spacelift/runner-terraform:latest"
}

# Create the parent-child dependency for run execution ordering
resource "spacelift_stack_dependency" "this" {
  stack_id            = spacelift_stack.avd-createhost.id
  depends_on_stack_id = spacelift_stack.avd-configure.id

  depends_on = [
    spacelift_stack_destructor.avd-createhost,
    spacelift_stack_destructor.avd-configure
  ]
}
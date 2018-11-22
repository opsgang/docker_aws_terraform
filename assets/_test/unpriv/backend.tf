# vim: et sr sw=2 ts=2 smartindent syntax=terraform:
terraform {
  backend "local" {
    path="/var/tmp/tfstate"
  }
}

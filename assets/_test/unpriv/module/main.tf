# vim: et sr sw=2 ts=2 smartindent syntax=terraform:
variable "foo" {}

resource "null_resource" "bar" {
  triggers {
    bar = "${var.foo}"
  }
}

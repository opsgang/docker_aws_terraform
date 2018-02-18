# vim: et sr sw=2 ts=2 smartindent:
variable "ts" {}

resource "null_resource" "foo" {
  triggers {
    bar = "${var.ts}"
  }
}

module "null" "bar" {
  source = "./module"
  foo    = "${var.ts}"
}

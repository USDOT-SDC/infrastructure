resource "aws_ssm_parameter" "utilities_bucket" {
  name  = "/common/secrets/utilities_bucket"
  type  = "String"
  value = "dev.sdc.dot.gov.platform.terraform"
}
resource "aws_s3_object" "linuxdiskalert-source-file"{
  bucket =  var.common.terraform_bucket #data.aws_ssm_parameter.utilities_bucket.value
  key = "utilities/scripts"
  source = "./linux-disk-alert.py"
}

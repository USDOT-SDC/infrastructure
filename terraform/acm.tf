# This cert is used for external facing resources; portal, api, etc.
# domain name: sdc-dev.dot.gov
# domains:  www.sdc-dev.dot.gov, portal.sdc-dev.dot.gov, portal-api.sdc-dev.dot.gov, 
#           api.sdc-dev.dot.gov, sftp.sdc-dev.dot.gov, sub1.sdc-dev.dot.gov, sub2.sdc-dev.dot.gov
resource "aws_acm_certificate" "external" {
  private_key       = file("${local.certificates_path}/Private.key")
  certificate_body  = file("${local.certificates_path}/ServerCertificate.crt")
  certificate_chain = file("${local.certificates_path}/Intermediate.crt")
}

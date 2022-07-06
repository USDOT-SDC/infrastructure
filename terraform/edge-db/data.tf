data "aws_subnet" "researchers" {
  filter {
    name   = "tag:Name"
    values = ["Researcher Workstations/GitLab"]
  }
}
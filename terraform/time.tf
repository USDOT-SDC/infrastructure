resource "time_rotating" "_8hours" {
  rotation_hours = 8
}

resource "time_rotating" "_12hours" {
  rotation_hours = 12
}

resource "time_rotating" "_24hours" {
  rotation_hours = 24
}

resource "time_rotating" "_7days" {
  rotation_days = 7
}

resource "time_rotating" "_30days" {
  rotation_days = 30
}

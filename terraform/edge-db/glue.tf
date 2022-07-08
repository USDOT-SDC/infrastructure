# === Data catalog -> Databases ===
resource "aws_glue_catalog_database" "internal_db" {
  name = "${var.repository}.glue.database.edge-db.internal"
}

resource "aws_glue_catalog_database" "edge_db" {
  name = "${var.repository}.glue.database.edge-db.edge"
}

# === Data catalog -> Databases -> Tables ===

# === Data catalog -> Databases -> Connections ===
resource "aws_glue_connection" "internal_connection" {
  name = "${var.repository}.glue.connection.edge-db.internal"
  connection_properties = {
    JDBC_CONNECTION_URL = "jdbc:postgresql://${local.edge_db_internal_server}:${local.edge_db_internal_port};databaseName=postgres"
    USERNAME            = local.edge_db_internal_user
    PASSWORD            = local.edge_db_internal_password
  }
  physical_connection_requirements {
    availability_zone      = "us-east-1a"
    security_group_id_list = [aws_security_group.glue_aurora]
    subnet_id              = data.aws_subnet.support.id
  }
  tags = local.tags
}

resource "aws_glue_connection" "edge_connection" {
  name = "${var.repository}.glue.connection.edge-db.edge"
  connection_properties = {
    JDBC_CONNECTION_URL = "jdbc:postgresql://${local.edge_db_edge_server}:${local.edge_db_edge_port};databaseName=postgres"
    USERNAME            = local.edge_db_edge_user
    PASSWORD            = local.edge_db_edge_password
  }
  physical_connection_requirements {
    availability_zone      = "us-east-1a"
    security_group_id_list = [aws_security_group.glue_aurora]
    subnet_id              = data.aws_subnet.support.id
  }
  tags = local.tags
}

# === Data catalog -> Crawlers ===
resource "aws_glue_crawler" "edge_db_internal" {
  name          = "${var.repository}.glue.crawler.${local.module}.internal"
  database_name = aws_glue_catalog_database.internal_db
  role          = iam.aws_iam_role.glue.name
  jdbc_target {
    connection_name = aws_glue_connection.internal_connection.name
    path            = "sdc-support/%"
  }
  tags = local.tags
}

resource "aws_glue_crawler" "edge_db_edge" {
  name          = "${var.repository}.glue.crawler.${local.module}.edge"
  database_name = aws_glue_catalog_database.edge_db
  role          = iam.aws_iam_role.glue.name
  jdbc_target {
    connection_name = aws_glue_connection.edge_connection.name
    path            = "sdc-support/%"
  }
  tags = local.tags
}

# === Data catalog -> Crawlers -> Classifiers ===

# === Data catalog -> Schema registries ===

# === Data catalog -> Schema registries -> Schemas ===

# === Data catalog -> Settings ===

# === ETL -> Blueprints ===

# === ETL -> Workflows ===
resource "aws_glue_workflow" "nightly_load" {
  name = "${var.repository}.glue.job.${local.module}.nightly_load"
}

resource "aws_glue_workflow" "new_table" {
  name = "${var.repository}.glue.job.${local.module}.new_table"
}

# === ETL -> Jobs ===
resource "aws_glue_job" "nightly_load" {
  name        = "${var.repository}.glue.job.${local.module}.nightly_load"
  role_arn    = var.aws_iam_role.glue.arn
  connections = [aws_glue_connection.internal_connection.name, aws_glue_connection.edge_connection.name]
  default_arguments = {
    "--enable-glue-datacatalog"          = "false"
    "--job-bookmark-option"              = "job-bookmark-disable"
    "--enable-metrics"                   = "true"
    "--enable-continuous-cloudwatch-log" = "true"
    "--enable-continuous-log-filter"     = "true"
  }
  glue_version = "3.0"
  timeout           = 60
  worker_type       = "Standard"
  number_of_workers = 1
  command {
    script_location = "s3://${var.terraform_bucket}/${local.nightly_load_key}"
  }
  tags = local.tags
}

resource "aws_glue_job" "populate_schema" {
  name        = "${var.repository}.glue.job.${local.module}.populate_schema"
  role_arn    = var.aws_iam_role.glue.arn
  connections = [aws_glue_connection.internal_connection.name, aws_glue_connection.edge_connection.name]
  default_arguments = {
    "--enable-glue-datacatalog"          = "false"
    "--job-bookmark-option"              = "job-bookmark-disable"
    "--enable-metrics"                   = "true"
    "--enable-continuous-cloudwatch-log" = "true"
    "--enable-continuous-log-filter"     = "true"
  }
  glue_version = "3.0"
  timeout           = 60
  worker_type       = "Standard"
  number_of_workers = 1
  command {
    script_location = "s3://${var.terraform_bucket}/${local.populate_schema_key}"
  }
  tags = local.tags
}
# === ETL -> Jobs -> Script Files ===
locals {
  nightly_load_script = "glue.edge_db_nightly_load.py"
  nightly_load_key    = "${var.repository}/glue/${local.module}/${local.nightly_load_script}"
  populate_schema_script = "glue.edge_db_populate_schema.py"
  populate_schema_key    = "${var.repository}/glue/${local.module}/${local.populate_schema_script}"
}
resource "aws_s3_bucket_object" "nightly_load" {
  bucket      = var.terraform_bucket
  key         = local.nightly_load_key
  source      = "${local.module}/${local.nightly_load_script}"
  source_hash = filemd5("${local.module}/${local.nightly_load_script}")
  tags        = local.tags
}
resource "aws_s3_bucket_object" "populate_schema" {
  bucket      = var.terraform_bucket
  key         = local.populate_schema_key
  source      = "${local.module}/${local.populate_schema_script}"
  source_hash = filemd5("${local.module}/${local.populate_schema_script}")
  tags        = local.tags
}

# === ETL -> Jobs -> ML Transforms ===

# === ETL -> Triggers ===
resource "aws_glue_trigger" "nightly_load-start" {
  name          = "${var.repository}.glue.trigger.${local.module}.nightly_load"
  schedule = "cron(0 3 * * ? *)"
  type     = "SCHEDULED"
  workflow_name = aws_glue_workflow.nightly_load.name

  actions {
    crawler_name = aws_glue_crawler.edge_db_internal.name
  }
}

resource "aws_glue_trigger" "nightly_load_job" {
  name    = "${var.repository}.glue.trigger.${local.module}.nightly_load_job"
  type    = "CONDITIONAL"
  workflow_name = aws_glue_workflow.nightly_load.name

  predicate {
    conditions {
      crawler_name = aws_glue_crawler.edge_db_internal.name
      crawl_state    = "SUCCEEDED"
    }
  }

  actions {
    job_name = aws_glue_job.nightly_load.name
  }
}

resource "aws_glue_trigger" "edge_crawler" {
  name    = "${var.repository}.glue.trigger.${local.module}.nightly_load"
  type    = "CONDITIONAL"
  workflow_name = aws_glue_workflow.nightly_load.name

  predicate {
    conditions {
      job_name = aws_glue_job.nightly_load.name
      state  = "SUCCEEDED"
    }
  }

  actions {
    crawler_name = aws_glue_crawler.edge_db_edge.name
  }
}

resource "aws_glue_trigger" "new_table_start" {
  name          = "${var.repository}.glue.trigger.${local.module}.new_table"
  type     = "ON-DEMAND"
  workflow_name = aws_glue_workflow.new_table.name

  actions {
    crawler_name = aws_glue_crawler.edge_db_internal.name
  }
}

resource "aws_glue_trigger" "poplate_schema_job" {
  name    = "${var.repository}.glue.trigger.${local.module}.populate_schema_job"
  type    = "CONDITIONAL"
  workflow_name = aws_glue_workflow.new_table.name

  predicate {
    conditions {
      crawler_name = aws_glue_crawler.edge_db_internal.name
      crawl_state    = "SUCCEEDED"
    }
  }

  actions {
    job_name = aws_glue_job.populate_schema.name
  }
}

# === ETL -> Dev endpoints ===

# === ETL -> Dev endpoints -> Notebooks ===

# === Security -> Security configurations ===

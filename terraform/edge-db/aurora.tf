resource "aws_rds_cluster" "internal_cluster" {
  cluster_identifier      = "aurora-dataexport-internal-cluster"
  engine                  = "aurora-postgresql"
  engine_mode             = "serverless"
  availability_zones      = ["us-east-1a", "us-east-1b"]  
  database_name           = data.aws_ssm_parameter.edge_db_internal_dbname 
  enable_http_endpoint    = true
  master_username         = data.aws_ssm_parameter.edge_db_internal_admin
  master_password         = data.aws_ssm_parameter.edge_db_internal_password
  backup_retention_period = 1
  storage_encrypted = true
  skip_final_snapshot     = true
  vpc_security_group_ids = [data.aws_ssm_parameter.edge_db_internal_sg_id]
  port = data.aws_ssm_parameter.edge_db_internal_port

  scaling_configuration {
    auto_pause               = true
    min_capacity             = 1    
    max_capacity             = 3
    seconds_until_auto_pause = 300
    timeout_action           = "ForceApplyCapacityChange"
  }
  lifecycle {
    ignore_changes = [
      value,
    ]
  }  
}

resource "aws_rds_cluster" "edge_cluster" {
  cluster_identifier      = "aurora-dataexport-edge-cluster"
  engine                  = "aurora-postgresql"  
  engine_mode             = "serverless"
  availability_zones      = ["us-east-1a", "us-east-1b"]  
  database_name           = data.aws_ssm_parameter.edge_db_edge_dbname
  enable_http_endpoint    = true
  master_username         = data.aws_ssm_parameter.edge_db_edge_admin
  master_password         = data.aws_ssm_parameter.edge_db_edge_password
  backup_retention_period = 1
  storage_encrypted = true
  skip_final_snapshot     = true
  vpc_security_group_ids = [data.aws_ssm_parameter.edge_db_edge_sg_id]
  port = data.aws_ssm_parameter.edge_db_edge_port

  scaling_configuration {
    auto_pause               = true
    min_capacity             = 1    
    max_capacity             = 3
    seconds_until_auto_pause = 300
    timeout_action           = "ForceApplyCapacityChange"
  }
  lifecycle {
    ignore_changes = [
      value,
    ]
  }  
}


resource "aws_rds_cluster_instance" "internal_reader" {
  identifier         = "aurora-dataexport-internal-cluster-reader"
  cluster_identifier = aws_rds_cluster.internal_cluster.id
  instance_class     = "db.r6g.large"
  engine             = aws_rds_cluster.internal_cluster.engine
  engine_version     = aws_rds_cluster.internal_cluster.engine_version
}

resource "aws_rds_cluster_instance" "internal_writer" {
  count              = 2
  identifier         = "aurora-dataexport-internal-cluster-writer"
  cluster_identifier = aws_rds_cluster.internal_cluster.id
  instance_class     = "db.r6g.large"
  engine             = aws_rds_cluster.internal_cluster.engine
  engine_version     = aws_rds_cluster.internal_cluster.engine_version
}


resource "aws_rds_cluster_instance" "edge_reader" {
  identifier         = "aurora-dataexport-edge-cluster-reader"
  cluster_identifier = aws_rds_cluster.edge_cluster.id
  instance_class     = "db.r6g.large"
  engine             = aws_rds_cluster.edge_cluster.engine
  engine_version     = aws_rds_cluster.edge_cluster.engine_version
}

resource "aws_rds_cluster_instance" "edge_writer" {
  count              = 2
  identifier         = "aurora-dataexport-edge-cluster-writer"
  cluster_identifier = aws_rds_cluster.edge_cluster.id
  instance_class     = "db.r6g.large"
  engine             = aws_rds_cluster.edge_cluster.engine
  engine_version     = aws_rds_cluster.edge_cluster.engine_version
}
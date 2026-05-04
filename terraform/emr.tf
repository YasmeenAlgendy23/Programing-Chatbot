resource "aws_emr_cluster" "spark" {
  count         = var.enable_emr ? 1 : 0
  name          = "${var.netid}-emr-spark"
  release_label = "emr-7.0.0"
  applications  = ["Spark"]
  service_role  = aws_iam_role.emr_service_role.arn

  ec2_attributes {
    instance_profile                  = aws_iam_instance_profile.emr_ec2.arn
    key_name                          = aws_key_pair.main.key_name
    subnet_id                         = aws_subnet.public_1.id
    emr_managed_master_security_group = aws_security_group.emr_master.id
    emr_managed_slave_security_group  = aws_security_group.emr_core.id
  }

  master_instance_group {
    instance_type  = "m5.xlarge"
    instance_count = 1
    name           = "${var.netid}-emr-master"
  }

  core_instance_group {
    instance_type  = "m5.xlarge"
    instance_count = 2
    name           = "${var.netid}-emr-core"
  }

  auto_termination_policy {
    idle_timeout = 3600
  }

  configurations_json = jsonencode([{
    Classification = "spark-defaults"
    Properties = {
      "spark.driver.memory"          = "8g"
      "spark.executor.memory"        = "8g"
      "spark.sql.shuffle.partitions" = "20"
    }
  }])

  log_uri = "s3://${aws_s3_bucket.data.id}/emr-logs/"

  tags = { Name = "${var.netid}-emr-spark" }
}
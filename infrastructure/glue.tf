resource "aws_glue_catalog_database" "mydb" {
  name = "examplegluedb"
}

resource "aws_glue_crawler" "test_crawler" {
  name          = aws_glue_catalog_database.mydb.name
  database_name = "test_crawler"
  role          = aws_iam_role.test_role.arn

  s3_target {
    path = "s3://${var.datalake_s3_bucket_name}/${var.datalake_data_prefix}/"
  }
}
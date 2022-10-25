resource "aws_s3_bucket" "datalake-bucket" {
  bucket        = var.datalake_s3_bucket_name
  acl           = "private"
  force_destroy = true
}

resource "aws_s3_bucket_object" "initial_data" {
  count  = length(local.initial_data)
  bucket = aws_s3_bucket.datalake-bucket.id
  key    = "${var.datalake_data_prefix}/month=${local.initial_data[count.index].month}/data.csv"

  source = "data/${local.initial_data[count.index].filename}"
  etag   = filemd5("data/${local.initial_data[count.index].filename}")
}

resource "aws_s3_bucket" "athena-results" {
  bucket        = var.query_results_s3_bucket-name
  acl           = "private"
  force_destroy = true
}
variable "datalake_s3_bucket_name" {
  type    = string
  default = "datalake-kosta-data"
}

variable "query_results_s3_bucket-name" {
  type    = string
  default = "datalake-kosta-query-results"
}

variable "datalake_data_prefix" {
  type    = string
  default = "weather_data"
}
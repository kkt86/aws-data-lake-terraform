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

variable "open_weather_prefix" {
  type    = string
  default = "open-weather"
}

variable "rapid_api_key" {
  type        = string
  description = "Rapid API key for accessing weather data"
  sensitive   = true
}
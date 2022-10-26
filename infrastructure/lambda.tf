variable "lambda_root" {
  type        = string
  description = "The relative path to the source of the lambda"
  default     = "./lambda"
}

resource "null_resource" "install_dependencies" {
  provisioner "local-exec" {
    command = "pip install -r ${var.lambda_root}/requirements.txt -t ${var.lambda_root}"
  }

  triggers = {
    dependencies_versions = filemd5("${var.lambda_root}/requirements.txt")
    source_versions       = filemd5("${var.lambda_root}/function.py")
  }
}

resource "random_uuid" "lambda_src_hash" {
  keepers = {
    for filename in setunion(
      fileset(var.lambda_root, "function.py"),
      fileset(var.lambda_root, "requirements.txt")
    ) :
    filename => filemd5("${var.lambda_root}/${filename}")
  }
}

data "archive_file" "lambda_source" {
  depends_on  = [null_resource.install_dependencies]
  excludes    = ["__pycache__", "venv", ]
  source_dir  = var.lambda_root
  output_path = "${random_uuid.lambda_src_hash.result}.zip"
  type        = "zip"
}

resource "aws_lambda_function" "lambda" {
  function_name    = "weather_data_ingest"
  role             = aws_iam_role.lambda_exec_role.arn
  filename         = data.archive_file.lambda_source.output_path
  source_code_hash = data.archive_file.lambda_source.output_base64sha256

  handler = "function.handler"
  runtime = "python3.8"

  memory_size = 128
  timeout     = 300

  environment {
    variables = {
      RAPID_API_KEY = var.rapid_api_key
      BUCKET_NAME   = aws_s3_bucket.datalake-bucket.bucket
    }
  }

  depends_on = [null_resource.install_dependencies]
}

resource "aws_iam_role" "lambda_exec_role" {
  name               = "lambda_exec_role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      }
    }
  ]
}
EOF
}

data "aws_iam_policy_document" "lambda_policy_doc" {
  statement {
    sid    = "AllowInvokingLambdas"
    effect = "Allow"

    resources = [
      "arn:aws:lambda:*:*:function:*"
    ]

    actions = [
      "lambda:InvokeFunction"
    ]
  }

  statement {
    sid    = "AllowCreatingLogGroups"
    effect = "Allow"

    resources = [
      "arn:aws:logs:*:*:*"
    ]

    actions = [
      "logs:CreateLogGroup"
    ]
  }

  statement {
    sid    = "AllowWritingLogs"
    effect = "Allow"

    resources = [
      "arn:aws:logs:*:*:log-group:/aws/lambda/*:*"
    ]

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
  }

  statement {
    sid    = "Stmt1468366974000"
    effect = "Allow"
    resources = [
      "arn:aws:s3:::${aws_s3_bucket.datalake-bucket.bucket}/*"
    ]
    actions = ["s3:*"]
  }
}

resource "aws_iam_policy" "lambda_iam_policy" {
  name   = "lambda_iam_policy"
  policy = data.aws_iam_policy_document.lambda_policy_doc.json
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  policy_arn = aws_iam_policy.lambda_iam_policy.arn
  role       = aws_iam_role.lambda_exec_role.name
}

resource "aws_cloudwatch_event_rule" "schedule" {
  name                = "schedule"
  description         = "Schedule lof Lambda Function"
  schedule_expression = "cron(0/1 * ? * * *)"
}

resource "aws_cloudwatch_event_target" "schedule_lambda" {
  rule      = aws_cloudwatch_event_rule.schedule.name
  target_id = "processing_lambda"
  arn       = aws_lambda_function.lambda.arn
}

resource "aws_lambda_permission" "allow_event_bridge_to_run_lambda" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "events.amazonaws.com"
}
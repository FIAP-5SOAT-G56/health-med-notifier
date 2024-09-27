resource "aws_security_group" "lambda_appointment_cancelled" {
  name        = "${data.terraform_remote_state.infra.outputs.resource_prefix}-security-group-lambda-appointment-cancelled"
  description = "inbound: all + outbound: all"
  vpc_id      = data.terraform_remote_state.infra.outputs.aws_vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${data.terraform_remote_state.infra.outputs.resource_prefix}-security-group-lambda-appointment-cancelled"
  }
}

resource "aws_iam_role" "lambda_appointment_cancelled" {
  name               = "${data.terraform_remote_state.infra.outputs.resource_prefix}-lambda-appointment-cancelled"
  assume_role_policy = data.aws_iam_policy_document.assume_role_lambda.json

  tags = {
    Name = "${data.terraform_remote_state.infra.outputs.resource_prefix}-lambda-appointment-cancelled"
  }

  depends_on = [
    data.aws_iam_policy_document.assume_role_lambda
  ]
}

resource "aws_iam_role_policy_attachment" "AWSLambdaVPCAccessExecutionRole_appointment_cancelled" {
  role       = aws_iam_role.lambda_appointment_cancelled.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"

  depends_on = [
    aws_iam_role.lambda_appointment_created
  ]
}

resource "aws_iam_role_policy_attachment" "AWSLambdaBasicExecutionRole_appointment_cancelled" {
  role       = aws_iam_role.lambda_appointment_cancelled.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"

  depends_on = [
    aws_iam_role.lambda_appointment_cancelled
  ]
}

resource "aws_iam_role_policy_attachment" "AmazonSQSFullAccess_appointment_cancelled" {
  role       = aws_iam_role.lambda_appointment_cancelled.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSQSFullAccess"

  depends_on = [
    aws_iam_role.lambda_appointment_cancelled
  ]
}

data "archive_file" "lambda_appointment_cancelled_artefact" {
  type        = "zip"
  source_dir  = "${path.module}/../src/appointment-cancelled"
  output_path = "files/lambda_appointment_cancelled_payload.zip"
}

resource "aws_lambda_function" "appointment_cancelled" {
  function_name    = "${data.terraform_remote_state.infra.outputs.resource_prefix}-lambda-appointment-cancelled"
  filename         = "files/lambda_appointment_cancelled_payload.zip"
  role             = aws_iam_role.lambda_appointment_cancelled.arn
  runtime          = var.lambda_appointment_cancelled_runtime
  source_code_hash = data.archive_file.lambda_appointment_cancelled_artefact.output_base64sha256
  handler          = "index.handler"
  timeout          = 15
  memory_size      = 128

  vpc_config {
    subnet_ids = [
      data.terraform_remote_state.infra.outputs.subnet_private_a_id,
      data.terraform_remote_state.infra.outputs.subnet_private_b_id
    ]
    security_group_ids = [aws_security_group.lambda_appointment_cancelled.id]
  }

  environment {
    variables = {
      SENDGRID_API_KEY                           = "${var.SENDGRID_API_KEY}",
      SENDGRID_EMAIL                             = "${var.SENDGRID_EMAIL}",
      SENDGRID_APPOINTMENT_CANCELLED_TEMPLATE_ID = "${var.SENDGRID_APPOINTMENT_CANCELLED_TEMPLATE_ID}",
    }
  }

  dead_letter_config {
    target_arn = data.terraform_remote_state.infra.outputs.sqs_api_appointment_cancelled_dlq_arn
  }

  tags = {
    Name = "${data.terraform_remote_state.infra.outputs.resource_prefix}-lambda-appointment-cancelled"
  }

  depends_on = [
    aws_security_group.lambda_appointment_cancelled,
    aws_iam_role_policy_attachment.AWSLambdaBasicExecutionRole_appointment_cancelled,
    aws_iam_role_policy_attachment.AmazonSQSFullAccess_appointment_cancelled,
    data.archive_file.lambda_appointment_cancelled_artefact
  ]
}

resource "aws_lambda_event_source_mapping" "appointment_cancelled" {
  event_source_arn = data.terraform_remote_state.infra.outputs.sqs_api_appointment_cancelled_arn
  function_name    = aws_lambda_function.appointment_cancelled.arn
  batch_size       = 1

  depends_on = [
    aws_lambda_function.appointment_cancelled
  ]
}

resource "aws_cloudwatch_log_group" "lambda_appointment_cancelled" {
  name              = "/aws/lambda/${aws_lambda_function.appointment_cancelled.function_name}"
  retention_in_days = 30

  tags = {
    Name = "${data.terraform_remote_state.infra.outputs.resource_prefix}-lambda-appointment-cancelled"
  }

  depends_on = [
    aws_lambda_function.appointment_cancelled
  ]
}

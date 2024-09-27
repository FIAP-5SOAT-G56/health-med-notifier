resource "aws_security_group" "lambda_appointment_created" {
  name        = "${data.terraform_remote_state.infra.outputs.resource_prefix}-security-group-lambda-appointment-created"
  description = "inbound: all + outbound: all"
  vpc_id      = data.terraform_remote_state.infra.outputs.aws_vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${data.terraform_remote_state.infra.outputs.resource_prefix}-security-group-lambda-appointment-created"
  }
}

resource "aws_iam_role" "lambda_appointment_created" {
  name               = "${data.terraform_remote_state.infra.outputs.resource_prefix}-lambda-appointment-created"
  assume_role_policy = data.aws_iam_policy_document.assume_role_lambda.json

  tags = {
    Name = "${data.terraform_remote_state.infra.outputs.resource_prefix}-lambda-appointment-created"
  }

  depends_on = [
    data.aws_iam_policy_document.assume_role_lambda
  ]
}

resource "aws_iam_role_policy_attachment" "AWSLambdaVPCAccessExecutionRole_appointment_created" {
  role       = aws_iam_role.lambda_appointment_created.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"

  depends_on = [
    aws_iam_role.lambda_appointment_created
  ]
}

resource "aws_iam_role_policy_attachment" "AWSLambdaBasicExecutionRole_appointment_created" {
  role       = aws_iam_role.lambda_appointment_created.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"

  depends_on = [
    aws_iam_role.lambda_appointment_created
  ]
}

resource "aws_iam_role_policy_attachment" "AmazonSQSFullAccess_appointment_created" {
  role       = aws_iam_role.lambda_appointment_created.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSQSFullAccess"

  depends_on = [
    aws_iam_role.lambda_appointment_created
  ]
}

data "archive_file" "lambda_appointment_created_artefact" {
  type        = "zip"
  source_dir  = "${path.module}/../src/appointment-created"
  output_path = "files/lambda_appointment_created_payload.zip"
}

resource "aws_lambda_function" "appointment_created" {
  function_name    = "${data.terraform_remote_state.infra.outputs.resource_prefix}-lambda-appointment-created"
  filename         = "files/lambda_appointment_created_payload.zip"
  role             = aws_iam_role.lambda_appointment_created.arn
  runtime          = var.lambda_appointment_created_runtime
  source_code_hash = data.archive_file.lambda_appointment_created_artefact.output_base64sha256
  handler          = "index.handler"
  timeout          = 15
  memory_size      = 128

  vpc_config {
    subnet_ids = [
      data.terraform_remote_state.infra.outputs.subnet_private_a_id,
      data.terraform_remote_state.infra.outputs.subnet_private_b_id
    ]
    security_group_ids = [aws_security_group.lambda_appointment_created.id]
  }

  environment {
    variables = {
      SENDGRID_API_KEY                         = "${var.SENDGRID_API_KEY}",
      SENDGRID_EMAIL                           = "${var.SENDGRID_EMAIL}",
      SENDGRID_APPOINTMENT_CREATED_TEMPLATE_ID = "${var.SENDGRID_APPOINTMENT_CREATED_TEMPLATE_ID}",
    }
  }

  dead_letter_config {
    target_arn = data.terraform_remote_state.infra.outputs.sqs_api_appointment_created_dlq_arn
  }

  tags = {
    Name = "${data.terraform_remote_state.infra.outputs.resource_prefix}-lambda-appointment-created"
  }

  depends_on = [
    aws_security_group.lambda_appointment_created,
    aws_iam_role_policy_attachment.AWSLambdaBasicExecutionRole_appointment_created,
    aws_iam_role_policy_attachment.AmazonSQSFullAccess_appointment_created,
    data.archive_file.lambda_appointment_created_artefact
  ]
}

resource "aws_lambda_event_source_mapping" "appointment_created" {
  event_source_arn = data.terraform_remote_state.infra.outputs.sqs_api_appointment_created_arn
  function_name    = aws_lambda_function.appointment_created.arn
  batch_size       = 1

  depends_on = [
    aws_lambda_function.appointment_created
  ]
}

resource "aws_cloudwatch_log_group" "lambda_appointment_created" {
  name              = "/aws/lambda/${aws_lambda_function.appointment_created.function_name}"
  retention_in_days = 30

  tags = {
    Name = "${data.terraform_remote_state.infra.outputs.resource_prefix}-lambda-appointment-created"
  }

  depends_on = [
    aws_lambda_function.appointment_created
  ]
}

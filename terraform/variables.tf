# Naming
variable "lambda_appointment_created_runtime" {
  default = "nodejs20.x"
}

variable "lambda_appointment_cancelled_runtime" {
  default = "nodejs20.x"
}

# Secrets
variable "SENDGRID_API_KEY" {
  type = string
}

variable "SENDGRID_EMAIL" {
  type = string
}

variable "SENDGRID_APPOINTMENT_CREATED_TEMPLATE_ID" {
  type = string
}

variable "SENDGRID_APPOINTMENT_CANCELLED_TEMPLATE_ID" {
  type = string
}


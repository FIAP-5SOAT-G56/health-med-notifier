# Health Med Notifier
![aws](https://img.shields.io/badge/Amazon_AWS-FF9900?style=for-the-badge&logo=amazonwebservices&logoColor=white)
![lambda](https://img.shields.io/badge/AWS_Lambda-FF9900?style=for-the-badge&logo=awslambda&logoColor=white)
![sqs](https://img.shields.io/badge/AWS_SQS-FF9900?style=for-the-badge&logo=amazonsqs&logoColor=white)
![sendgrid](https://img.shields.io/badge/SendGrid-blue?style=for-the-badge&logo=maildotru&logoColor=white)
![terraform](https://img.shields.io/badge/Terraform-7B42BC?style=for-the-badge&logo=terraform&logoColor=white)

Repository for the Health Med Notifier project. This project will send notifications to a user's email when an appointment is booked or cancelled. This project use Lambda Functions to receive messages from an SQS queue and send emails using SendGrid Email API.
#Declaring Input Variables

variable "region" {
  type    = string
  default = "us-east-1"

}

variable "aws_dynamodb_table" {
  default = "tf-remote-state-lock"

}

variable "key_name" {
  description = "Key to access the EC2 instance"
  type        = string
  default     = "key_pair"
}


variable "my_sg" {
  type    = string
  default = "my_sg"
}

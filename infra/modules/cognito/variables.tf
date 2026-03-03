variable "test_user_email" {
  description = "Email address for the test user"
  type        = string
  sensitive   = true
}

variable "test_user_repo" {
  description = "Repo for the test user"
  type        = string
}

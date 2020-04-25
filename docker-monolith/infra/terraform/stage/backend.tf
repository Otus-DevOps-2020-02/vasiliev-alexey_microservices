terraform {
  backend "gcs" {
    bucket  = "sb-otus-devops-av"
    prefix  = "terraform/stage"
  }
}

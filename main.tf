terraform {
  cloud {
    organization = "KostaLab"

    workspaces {
      name = "aws-data-lake"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

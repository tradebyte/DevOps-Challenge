terraform {

  required_providers {
    aws = {
      
      source  = "hashicorp/aws"
      version = "~> 5.0.0"
    }
  }

}

provider "aws" {
  shared_config_files = [ "~/.aws/config" ]
  shared_credentials_files = [ "~/.aws/credentials" ]
  profile = "default"
  region = "us-east-1"
}

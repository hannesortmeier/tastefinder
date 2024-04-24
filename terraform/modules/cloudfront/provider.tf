provider "aws" {
  region = "eu-central-1"
  profile = "hannesortmeier"
}

provider "aws" {
  region = "us-east-1"
  alias = "us-east-1"
}

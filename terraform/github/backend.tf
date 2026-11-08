terraform {
  backend "s3" {
    bucket    = "tofu-state"
    key       = "github/terraform.tfstate"
    region    = "ru-central-1"
    endpoints = { s3 = "https://s3.cloud.ru" }

    use_path_style              = true
    use_lockfile                = true
    skip_credentials_validation = true
    skip_region_validation      = true
    skip_requesting_account_id  = true
    skip_metadata_api_check     = true
  }
}

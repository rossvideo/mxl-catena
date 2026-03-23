terraform {
  # backend "http" { #shipped to NAB
  #   address        = "https://srvottgitlab02.rossvideo.com/api/v4/projects/525/terraform/state/demo2"
  #   lock_address   = "https://srvottgitlab02.rossvideo.com/api/v4/projects/525/terraform/state/demo2/lock"
  #   unlock_address = "https://srvottgitlab02.rossvideo.com/api/v4/projects/525/terraform/state/demo2/lock"
  #   lock_method    = "POST"
  #   unlock_method  = "DELETE"
  #   retry_wait_min = 5
  # }  
  backend "http" {
    address        = "https://srvottgitlab02.rossvideo.com/api/v4/projects/525/terraform/state/demo1"
    lock_address   = "https://srvottgitlab02.rossvideo.com/api/v4/projects/525/terraform/state/demo1/lock"
    unlock_address = "https://srvottgitlab02.rossvideo.com/api/v4/projects/525/terraform/state/demo1/lock"
    lock_method    = "POST"
    unlock_method  = "DELETE"
    retry_wait_min = 5
  }
}

terraform {
  required_version = ">= 1.7"
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {
  # When Terraform is executed **inside WSL 2** the default Unix socket works.
  host = "unix:///var/run/docker.sock"

  # If you run Terraform from PowerShell (outside WSL 2) change to:
  # host = "npipe:////./pipe/docker_engine"
}

resource "docker_image" "nginx" {
  name         = "nginx:latest"
  keep_locally = true
}

resource "docker_container" "web" {
  name  = "tf-demo-nginx"
  image = docker_image.nginx.latest
  ports {
    internal = 80
    external = 8080
  }
}

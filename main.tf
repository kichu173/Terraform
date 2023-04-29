# write configuration that will allow terraform to connect to our AWS account.
# Don't hard-code credentials directly in the configuration file
# In proramming language terms, privder = import library.
# resource/data = function call of library.
# arguments = parameter of a function.
provider "aws" {
    region = "ap-south-1"
    # aws secret and key are stored in aws configure with aws cli.
}

variable "subnet_cidr_block" {
    description= "subnet cidr block"
}

# variable = input variables, used for reusability
variable "vpc_cidr_block" {
    description = "vpc cidr block"
    default = "10.0.0.1.16/"
    type = string
}

variable "environment" {
    description = "deploymet environment"
}

# create new resource in the aws is using "resource" keyword. resource <provider>_<resourceType> "varialename - name we can define".
resource "aws_vpc" "development-vpc" {
    # going to be a private IP address range for that specific VPC (https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc)
    cidr_block = var.vpc_cidr_block
    tags = {
        Name: var.environment
    }
}

resource "aws_subnet" "dev-subnet-1" {
    vpc_id = aws_vpc.development-vpc.id
    cidr_block = var.subnet_cidr_block
    availability_zone = "ap-south-1a"
    tags = {
        Name: "subnet-1-dev"
    }
}

# "data" allows you to query existing resources and components from aws, while "resources" let you create new resources. 
# Result of query is exported under your given name. ex: ""existing_vpc""
# arguments = filter your query
data "aws_vpc" "existing_vpc" {
    default = true
}

# name must be unique for each resource
# Here we are trying to create a subnet under default vpc.
resource "aws_subnet" "dev-subnet-2" {
    vpc_id = data.aws_vpc.existing_vpc.id
    cidr_block = "172.31.48.0/20"
    availability_zone = "ap-south-1a"
    tags = {
        Name: "subnet-1-default"
    }
}

# output values: are like function return values.
output "dev-vpc-id" {
    value = aws_vpc.development-vpc.id
}

output "dev-subnet-id" {
    value = aws_subnet.dev-subnet-2.id
}
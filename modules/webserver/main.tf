resource "aws_security_group" "myapp-sg" { # if we are planning to use default security group - resource "aws_default_security_group", so one resource is removed and this one will be available
  name = "myapp-sg"
  vpc_id = var.vpc_id

  # firewall rules of security group
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [var.my_ip] # list of IP addresses or site blocks that are allowed to access port defined here
  }

  # for port 8080
  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # any one can access.
  }

  # allow any traffic to allow to leave the VPC and the server itself
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    prefix_list_ids = []
  }

  tags = {
    Name: "${var.env_prefix}-sg"
  }
}

# configuration for creating ec2 instance
resource "aws_instance" "myapp-server" {
  ami = "ami-0c768662cc797cd75" # operating system that the server will start
  instance_type = var.instance_type

  # below configuration is optional for ec2 instance, if we are not using below values it uses default one's. since we have created our own subnet, security group we are using it below.
  subnet_id = var.subnet_id
  vpc_security_group_ids = [aws_security_group.myapp-sg.id]
  availability_zone = var.avail_zone

  associate_public_ip_address = true
  #    key_name = "server-key-pair" # manually went to console and created a key-value pair and stored in users/admin/.ssh -> private pem file(contains required info to ssh into server).
  key_name = aws_key_pair.ssh-key.key_name # automated, created out own public key in .ssh

  # configure EC2 server to run entry script and run a docker container
  # user_data is like an entry point script that gets executed on whenever the ec2 server is instantiated
  # add user into docker group, make it possible to run docker cmds on the server without sudo

  #user_data = file("entry-script.sh")

  # "remote-exec" invokes script on remote server after it is created. Any cmd that you want to execute you can do it using remote exec provisioner.
  # connection - tells terraform to connect to remote server using ssh connection in order to execute remote exec provisioner. Connection is shared by both below file and remote exec provisioner.
  connection {
    type = "ssh"
    host = self.public_ip
    user = "ec2-user"
    private_key = file(var.private_key_location)
  }

  # file provisioner is used to copy files or directories from local to remote server.
  provisioner "file" {
    source = "entry-script.sh"
    destination = "/home/ec2-user/entry-script.sh"
  }

  provisioner "remote-exec" {
    #        inline = [
    #            "export ENV=dev",
    #            "mkdir newdir",
    #        ]
    script = file("entry-script.sh") # remote exec runs on remote server, to execute script file, this file should already present in remote server, to do this we have "file" provisioner.
  }

  # local exec invokes a local executable after a resource is created. cmd's executed locally in our laptop. alternative best choice is provider "local_file" use this one
  provisioner "local-exec" {
    command = "echo ${self.public_ip} > output.txt"
  }

  tags = {
    Name = "${var.env_prefix}-server"
  }
}

# automating the creation of key-pair to do ssh
resource "aws_key_pair" "ssh-key" {
  key_name = "server-key"
  public_key = file(var.public_key_location) # file = to read value from a file.
}
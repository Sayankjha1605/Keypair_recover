# create an security group

resource "aws_security_group" "sayanksg" {
  name        = "sayanksg"
  description = "Enable SSH access on Port 22"

  dynamic "ingress" {
    for_each = [22, 80, 8080, 443, 9090, 9000]
    iterator = port
    content {
      description = "TLS from VPC"
      from_port   = port.value
      to_port     = port.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# creating and send key pair
resource "aws_key_pair" "sayank" {
  key_name   = "sayank"
  public_key = file("${path.module}/sayank.pub")
}

# create a volume
resource "aws_ebs_volume" "extra_volume" {
  availability_zone = var.availability_zone
  size              = 15

  tags = {
    Name = "extra-volume"
  }
}

# attach a volume
resource "aws_volume_attachment" "volume_attach" {
  device_name = "/dev/xvdf"
  volume_id   = aws_ebs_volume.extra_volume.id
  instance_id = aws_instance.sayankec2.id
}


# Create EC2 Instance
resource "aws_instance" "sayankec2" {
  ami                         = "ami-0d50e5e845c552faf"
  instance_type               = "t2.micro"
  key_name                    = "sayank"
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.sayanksg.id]
  availability_zone           = var.availability_zone
  tags = {
    Name = "sayankec2"
  }

  # Command run in ec2
  user_data = <<-EOF
          #!bin/bash
          sudo su
          apt update
          apt install nginx -y
          fdisk -l
          fdisk /dev/xvdf
          n
          p
          1
          2048
          31457279
          w
          mkfs -t ext4 /dev/xvdf
          y
          mount /dev/xvdf /var/www/html
  EOF

  # Connection Login to Ec2
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("./sayank")
    host        = self.public_ip
  }
}

# Create S3 Bucket
resource "aws_s3_bucket" "sayankbucket" {
  bucket = "sayankbucket"
  tags = {
    name = "sayankbucket"
  }
}


# A Bucket ACL enable
resource "aws_s3_bucket_acl" "acl" {
  bucket = aws_s3_bucket.sayankbucket.id
  acl    = "private"
}


# S3 Bucket Public access Block
resource "aws_s3_bucket_public_access_block" "sayankbucket" {
  bucket = aws_s3_bucket.sayankbucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# create folder in s3 bucket 

resource "aws_s3_bucket_object" "file_upload" {
  bucket = "sayannkbucket"
  key    = "sayannkfile"
  source = "sayankfile/images.jpeg"
   acl = "public-read"
  
  #etag   = "${filemd5("${path.module}/my_files.zip")}"
}



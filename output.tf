output "sayankec2" {
  value = aws_instance.sayankec2.public_ip
    # sensitive   = true
  description = "this variable for ec2 insatance public ip store"
    # depends_on  = []
}

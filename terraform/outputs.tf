output "vpc_id" {
  value = aws_vpc.main.id
}
output "s3_bucket_name" {
  value = aws_s3_bucket.data.id
}
output "ssh_key_file" {
  value = local_file.private_key.filename
}
output "emr_master_dns" {
  value = var.enable_emr ? aws_emr_cluster.spark[0].master_public_dns : "EMR not enabled"
}
output "ec2_public_ip" {
  value = var.enable_ec2 ? aws_instance.deployment[0].public_ip : "EC2 not enabled"
}
output "ec2_ssh_command" {
  value = var.enable_ec2 ? "ssh -i ${local_file.private_key.filename} ec2-user@${aws_instance.deployment[0].public_ip}" : "EC2 not enabled"
}
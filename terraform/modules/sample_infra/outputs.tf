output "bucket_name" {
  description = "Name of the managed S3 bucket."
  value       = aws_s3_bucket.artifact_bucket.bucket
}

output "bucket_arn" {
  description = "ARN of the managed S3 bucket."
  value       = aws_s3_bucket.artifact_bucket.arn
}

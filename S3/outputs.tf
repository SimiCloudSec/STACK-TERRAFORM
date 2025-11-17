output "source_bucket_name" {
  value = aws_s3_bucket.source_bucket.bucket
}

output "destination_bucket_name" {
  value = aws_s3_bucket.dest_bucket.bucket
}

output "source_website_endpoint" {
  value = aws_s3_bucket_website_configuration.source_website.website_endpoint
}


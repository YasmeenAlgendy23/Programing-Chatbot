resource "aws_s3_bucket" "data" {
  bucket = "${var.netid}-cisc886-data"
  tags = { Name = "${var.netid}-cisc886-data" }
}

resource "aws_s3_bucket_versioning" "data" {
  bucket = aws_s3_bucket.data.id
  versioning_configuration {
    status = "Disabled"
  }
}

resource "aws_s3_object" "raw_folder" {
  bucket = aws_s3_bucket.data.id
  key    = "raw-data/"
}

resource "aws_s3_object" "processed_folder" {
  bucket = aws_s3_bucket.data.id
  key    = "processed-data/"
}

resource "aws_s3_object" "model_folder" {
  bucket = aws_s3_bucket.data.id
  key    = "model/"
}

resource "aws_s3_object" "scripts_folder" {
  bucket = aws_s3_bucket.data.id
  key    = "scripts/"
}
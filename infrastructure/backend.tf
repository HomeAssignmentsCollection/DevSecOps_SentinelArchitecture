# S3 bucket для Terraform state
resource "aws_s3_bucket" "terraform_state" {
  bucket = "sentinel-terraform-state-bucket-${random_id.bucket_suffix.hex}"

  tags = {
    Name        = "Sentinel Terraform State"
    Environment = var.environment
    Purpose     = "TerraformState"
  }
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# DynamoDB таблица для блокировки state
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "sentinel-terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "Sentinel Terraform Locks"
    Environment = var.environment
    Purpose     = "TerraformLocking"
  }
}

# ПРИМЕЧАНИЕ: Правило prevent_destroy закомментировано для полной очистки ресурсов
# во время тестового задания. В продакшене раскомментируйте для защиты критических state ресурсов.
# lifecycle {
#   prevent_destroy = true
# }

# Случайный ID для уникального именования bucket
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

#--------------------------------------------------------------
# Threat IP list
#--------------------------------------------------------------

resource "aws_guardduty_threatintelset" "sample" {
  activate    = true
  detector_id = aws_guardduty_detector.sample.id
  format      = "TXT"
  location    = "https://s3.amazonaws.com/${aws_s3_bucket_object.threat_ip_list.bucket}/${aws_s3_bucket_object.threat_ip_list.key}"
  name        = "sample-threat"
}

#--------------------------------------------------------------
# S3 where to set list
#--------------------------------------------------------------

resource "aws_s3_bucket" "threat_ip_list" {
  bucket = "terraform-example-guardduty-threat-list-${data.aws_caller_identity.current.account_id}"

  acl = "private"

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_s3_bucket_public_access_block" "threat_ip_list" {
  bucket = aws_s3_bucket.threat_ip_list.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_object" "threat_ip_list" {
  content = "10.0.1.0/24\n"
  bucket  = aws_s3_bucket.threat_ip_list.id
  key     = "ThreatIPList.txt"
}


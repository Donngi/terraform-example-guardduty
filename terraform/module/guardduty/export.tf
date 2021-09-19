#--------------------------------------------------------------
# Destination setting
#--------------------------------------------------------------

resource "aws_guardduty_publishing_destination" "sample" {
  detector_id     = aws_guardduty_detector.sample.id
  destination_arn = aws_s3_bucket.export.arn
  kms_key_arn     = aws_kms_key.export.arn
}

#--------------------------------------------------------------
# S3 where to set list
#--------------------------------------------------------------

resource "aws_s3_bucket" "export" {
  bucket = "terraform-example-guardduty-export-${data.aws_caller_identity.current.account_id}"

  acl = "private"

  versioning {
    enabled = true
  }

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm     = "aws:kms"
        kms_master_key_id = aws_kms_key.export.arn
      }
    }
  }
}

resource "aws_s3_bucket_public_access_block" "export" {
  bucket = aws_s3_bucket.export.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "export" {
  bucket = aws_s3_bucket.export.id
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "Allow GuardDuty to use the getBucketLocation operation",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "guardduty.amazonaws.com"
        },
        "Action" : "s3:GetBucketLocation",
        "Resource" : aws_s3_bucket.export.arn
      },
      {
        "Sid" : "Allow GuardDuty to upload objects to the bucket",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "guardduty.amazonaws.com"
        },
        "Action" : "s3:PutObject",
        "Resource" : "${aws_s3_bucket.export.arn}/*"
      },
      {
        "Sid" : "Deny unencrypted object uploads. This is optional",
        "Effect" : "Deny",
        "Principal" : {
          "Service" : "guardduty.amazonaws.com"
        },
        "Action" : "s3:PutObject",
        "Resource" : "${aws_s3_bucket.export.arn}/*",
        "Condition" : {
          "StringNotEquals" : {
            "s3:x-amz-server-side-encryption" : "aws:kms"
          }
        }
      },
      # TODO: Somewhat this statement prevents creating GuardDuty exporting setting (raises BadRequestException).
      #   {
      #     "Sid" : "Deny incorrect encryption header. This is optional",
      #     "Effect" : "Deny",
      #     "Principal" : {
      #       "Service" : "guardduty.amazonaws.com"
      #     },
      #     "Action" : "s3:PutObject",
      #     "Resource" : "${aws_s3_bucket.export.arn}/*",
      #     "Condition" : {
      #       "StringNotEquals" : {
      #         "s3:x-amz-server-side-encryption-aws-kms-key-id" : "arn:aws:kms:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:key/*"
      #       }
      #     }
      #   },
      {
        "Sid" : "Deny non-HTTPS access",
        "Effect" : "Deny",
        "Principal" : "*",
        "Action" : "s3:*",
        "Resource" : "${aws_s3_bucket.export.arn}/*",
        "Condition" : {
          "Bool" : {
            "aws:SecureTransport" : "false"
          }
        }
      }
  ] })
}

#--------------------------------------------------------------
# KMS
#--------------------------------------------------------------

resource "aws_kms_key" "export" {
  description = "KMS key for guardduty exporting"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "*"
        Resource = "*"
      },
      {
        "Sid" : "Allow GuardDuty to use the key",
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "guardduty.amazonaws.com"
        },
        "Action" : "kms:GenerateDataKey",
        "Resource" : "arn:aws:kms:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:key/*"
      }
    ]
  })
}

resource "aws_kms_alias" "export" {
  name          = "alias/GuardDutyExport"
  target_key_id = aws_kms_key.export.key_id
}

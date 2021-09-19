resource "aws_guardduty_detector" "sample" {
  enable = true

  # The frequency of notifications sent for subsequent finding occurrences
  finding_publishing_frequency = "SIX_HOURS"

  # GuardDuty automatically checks
  # - CloudTrail 
  # - VPC flow logs
  # - DNS logs
  # by default. 
  # If you want to check s3 data events (like etObject, ListObjects, DeleteObject and PutObject) additionally,
  # please turn on this option.
  datasources {
    s3_logs {
      enable = true
    }
  }
}
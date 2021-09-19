#--------------------------------------------------------------
# Suppression rules
#--------------------------------------------------------------

resource "aws_guardduty_filter" "suppress_low_level_findings" {
  name        = "SuppressAllLowLevelFindings"
  action      = "ARCHIVE" # When you set suppression rules, use 'ARCHIVE'
  detector_id = aws_guardduty_detector.sample.id
  rank        = 2

  finding_criteria {
    criterion {
      field     = "severity"
      less_than = "4"
    }
  }
}

#--------------------------------------------------------------
# Filters
#--------------------------------------------------------------

resource "aws_guardduty_filter" "filter_low_level_findings" {
  name        = "FilterAllLowLevelFindings"
  action      = "NOOP" # When you set fileter (not suppression rules), use 'NOOP'
  detector_id = aws_guardduty_detector.sample.id
  rank        = 1

  finding_criteria {
    criterion {
      field     = "severity"
      less_than = "4"
    }
  }
}

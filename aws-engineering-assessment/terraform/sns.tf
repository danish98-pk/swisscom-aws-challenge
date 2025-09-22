resource "aws_sns_topic" "alerts" {
  name = "security-alerts"
}

resource "aws_sns_topic_subscription" "email_sub" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = "awssecops123@gmail.com"

}

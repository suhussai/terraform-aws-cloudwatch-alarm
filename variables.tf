variable "cloudwatch_alarms" {
  type        = map(map(string))
  description = "Definitions of CloudWatch alarms to create."
}

variable "notification_arns" {
  type        = list(string)
  description = "List of ARNs that will receive ALARM and OK notifications. Example: `[\"arn:aws:sns:us-east-1:123456789:test-topic\"]`"
}

variable "treat_missing_data" {
  type        = string
  description = "If `Breaching`, then missing datapoints will be treated as if the metric value is over the threshold for the missing period"
  default     = "notBreaching"
}

variable "insufficient_data_actions" {
  type        = list(string)
  description = "The actions to execute when the alarm is in the INSUFFICIENT_DATA state."
  default     = []
}

variable "common_tags" {
  type        = map(string)
  description = "List of common tags to apply to resources."
  default     = {}
}
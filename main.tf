locals {
  common_tags = var.common_tags
}

resource "aws_cloudwatch_metric_alarm" "cloudwatch_alarms" {
  for_each = var.cloudwatch_alarms

  # common attributes for static and anomaly detection alarms
  alarm_name                = "${each.value.dimensions_value}-${each.key}"
  alarm_description         = each.value.alarm_description
  comparison_operator       = each.value.comparison_operator
  evaluation_periods        = lookup(each.value, "evaluation_periods", "1")
  datapoints_to_alarm       = lookup(each.value, "datapoints_to_alarm", "1")
  alarm_actions             = var.notification_arns
  ok_actions                = var.notification_arns
  insufficient_data_actions = var.insufficient_data_actions
  treat_missing_data        = var.treat_missing_data
  tags                      = local.common_tags

  # static-alarm-only attributes
  namespace          = contains(keys(each.value), "anomaly_threshold") ? null : each.value.namespace
  metric_name        = contains(keys(each.value), "anomaly_threshold") ? null : each.value.metric_name
  period             = contains(keys(each.value), "anomaly_threshold") ? null : each.value.period
  dimensions         = contains(keys(each.value), "anomaly_threshold") ? null : { (each.value.dimensions_key) = (each.value.dimensions_value) }
  statistic          = lookup(each.value, "statistic", null)
  extended_statistic = lookup(each.value, "extended_statistic", null)
  threshold          = lookup(each.value, "threshold", null)

  # anomaly-detection-alarm-only attributes
  threshold_metric_id = contains(keys(each.value), "anomaly_threshold") ? "e1" : null

  dynamic "metric_query" {
    # conditionally create block 'metric_query'
    # if 'anomaly_threshold' is defined, we create a block for each item in
    # the list. Since we only want to do this once and we don't really need
    # anything from the list, the list is set to [1]. If 'anomaly_threshold'
    # is not defined, the list we iterate over is [], which means we skip
    # creating this block. This is necessary in the case where we are creating
    # a static alarms since static alarms do not require a 'metric_query' block.
    for_each = contains(keys(each.value), "anomaly_threshold") ? [1] : []
    content {
      id          = "e1"
      expression  = "ANOMALY_DETECTION_BAND(m1, ${each.value.anomaly_threshold})"
      label       = "${each.value.metric_name} (Expected)"
      return_data = "true"
    }
  }

  dynamic "metric_query" {
    # conditionally create block 'metric_query'
    # if 'anomaly_threshold' is defined, we create a block for each item in
    # the list. Since we only want to do this once and we don't really need
    # anything from the list, the list is set to [1]. If 'anomaly_threshold'
    # is not defined, the list we iterate over is [], which means we skip
    # creating this block. This is necessary in the case where we are creating
    # a static alarms since static alarms do not require a 'metric_query' block.
    for_each = contains(keys(each.value), "anomaly_threshold") ? [1] : []
    content {
      id          = "m1"
      return_data = "true"
      metric {
        namespace   = each.value.namespace
        metric_name = each.value.metric_name
        period      = each.value.period
        stat        = each.value.stat

        dimensions = { (each.value.dimensions_key) = (each.value.dimensions_value) }
      }
    }
  }
}

# AWS CloudWatch Alarm Terraform Module

Terraform module which creates AWS CloudWatch Alarms. This module can be used to create alarms that alert on both static thresholds and on anomaly detection.

## Usage

```hcl
provider "aws" {
  region = "us-east-1"
}

module "terraform_aws_cloudwatch_alarm" {
  source            = "./terraform-aws-cloudwatch-alarm"
  notification_arns = [aws_sns_topic.alarm_notifications.arn]

  cloudwatch_alarms = {
    "anomalous-ec2-cpu-utilization" : {
      alarm_description   = "Track CPU Utilization on the EC2 instance."
      evaluation_periods  = "2" # defaults to 1, if not provided
      datapoints_to_alarm = "2" # defaults to 1, if not provided
      comparison_operator = "LessThanLowerOrGreaterThanUpperThreshold"
      anomaly_threshold   = "2"
      metric_name         = "CPUUtilization"
      period              = "60"
      stat                = "Average"
      namespace           = "AWS/EC2"
      dimensions_key      = "InstanceId"
      dimensions_value    = aws_instance.web.id
    },
    "anomalous-rds-cpu-utilization" : {
      alarm_description   = "Track CPU Utilization on the RDS instance."
      evaluation_periods  = "2" # defaults to 1, if not provided
      datapoints_to_alarm = "2" # defaults to 1, if not provided
      comparison_operator = "LessThanLowerOrGreaterThanUpperThreshold"
      anomaly_threshold   = "2"
      metric_name         = "CPUUtilization"
      period              = "60"
      stat                = "Average"
      namespace           = "AWS/RDS"
      dimensions_key      = "DBInstanceIdentifier"
      dimensions_value    = aws_db_instance.database.identifier
    },
    "high-write-latency" : {
      alarm_description   = "Track time required for a write operation."
      comparison_operator = "GreaterThanThreshold"
      threshold           = "0.002"
      metric_name         = "WriteLatency"
      period              = "300"
      extended_statistic  = "p94"
      namespace           = "AWS/RDS"
      dimensions_key      = "DBInstanceIdentifier"
      dimensions_value    = aws_db_instance.database.identifier
    },
    "high-disk-queue-depth" : {
      alarm_description   = "Track of number of IO operations that are waiting to be executed against the disk."
      comparison_operator = "GreaterThanThreshold"
      threshold           = "1"
      metric_name         = "DiskQueueDepth"
      period              = "60"
      statistic           = "Sum"
      namespace           = "AWS/RDS"
      dimensions_key      = "DBInstanceIdentifier"
      dimensions_value    = aws_db_instance.database.identifier
    },
  }

  common_tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

resource "aws_sns_topic" "alarm_notifications" {
  name = "alarm_notifications"
}

resource "aws_db_instance" "database" {
  allocated_storage    = 10
  engine               = "mysql"
  engine_version       = "5.7"
  instance_class       = "db.t3.micro"
  name                 = "mydb"
  username             = "foo"
  password             = "foobarbaz"
  parameter_group_name = "default.mysql5.7"
  skip_final_snapshot  = true
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
}
```

## How it works

This resource iterates over a map of alarm configurations. It can create both static and anomaly-detection alarms. It relies on the presence of the attribute "anomaly_threshold" to indicate whether or not an alarm configuration represents an anomaly detection alarm or a static alarm. The pertinent bits of config that vary between alarms are configurable.

### Static Alarm

A config for a static alarm might look like this:

```hcl
cloudwatch_alarms = {
  "unique-alarm-name" : {
    alarm_description   = "alarm-description"
    comparison_operator = "GreaterThanThreshold"
    evaluation_periods  = "2" # defaults to 1, if not provided
    datapoints_to_alarm = "2" # defaults to 1, if not provided
    threshold           = "0.002"
    metric_name         = "ReadLatency"
    period              = "300"
    extended_statistic  = "p90"
  },
}
```

### Anomaly Detection Alarm

A config for an anomaly detection alarm might look like this:

```hcl
cloudwatch_alarms = {
  "unique-alarm-name" : {
    alarm_description   = "alarm-description"
    comparison_operator = "LessThanLowerOrGreaterThanUpperThreshold"
    evaluation_periods  = "3" # defaults to 1, if not provided
    datapoints_to_alarm = "3" # defaults to 1, if not provided
    anomaly_threshold   = "2"
    metric_name         = "CPUUtilization"
    period              = "60"
    stat                = "Average"
  },
}
```

terraform {
  backend "s3" {}
}

provider "aws" {
  region  = "${var.aws_region}"
  version = "~> 2.0"
}


data "terraform_remote_state" "training_kafka" {
  backend = "s3"
  config {
    key    = "training_kafka.tfstate"
    bucket = "tw-dataeng-${var.cohort}-tfstate"
    region = "${var.aws_region}"
  }
}

data "terraform_remote_state" "training_emr_cluster" {
  backend = "s3"
  config {
    key    = "training_emr_cluster.tfstate"
    bucket = "tw-dataeng-${var.cohort}-tfstate"
    region = "${var.aws_region}"
  }
}

data "terraform_remote_state" "ingester" {
  backend = "s3"
  config {
    key    = "ingester.tfstate"
    bucket = "tw-dataeng-${var.cohort}-tfstate"
    region = "${var.aws_region}"
  }
}

resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "2wheelers"
  dashboard_body = <<EOF
{
    "widgets": [
        {
            "type": "metric",
            "x": 0,
            "y": 0,
            "width": 12,
            "height": 3,
            "properties": {
                "metrics": [
                    [ "System/Linux", "MemoryUtilization", "InstanceId", "i-0c8ac9ba08afb5956", { "label": "MemoryUtilization" } ],
                    [ ".", "DiskSpaceUtilization", "MountPath", "/", "InstanceId", "i-0c8ac9ba08afb5956", "Filesystem", "/dev/xvda1" ]
                ],
                "view": "singleValue",
                "region": "eu-central-1",
                "title": "Kafka",
                "period": 300
            }
        },
        {
            "type": "metric",
            "x": 12,
            "y": 9,
            "width": 12,
            "height": 9,
            "properties": {
                "metrics": [
                    [ "AWS/ElasticMapReduce", "HDFSUtilization", "JobFlowId", "j-3AZII9CYEZMWB" ],
                    [ ".", "AppsRunning", ".", "." ],
                    [ ".", "AppsPending", ".", "." ],
                    [ ".", "YARNMemoryAvailablePercentage", ".", "." ]
                ],
                "view": "singleValue",
                "stacked": false,
                "region": "eu-central-1",
                "period": 300,
                "title": "EMR HDFS"
            }
        },
        {
            "type": "metric",
            "x": 0,
            "y": 3,
            "width": 12,
            "height": 6,
            "properties": {
                "metrics": [
                    [ { "expression": "m2+m3", "label": "MemoryUsed", "id": "e1", "color": "#d62728" } ],
                    [ "AWS/ElasticMapReduce", "MemoryTotalMB", "JobFlowId", "j-3AZII9CYEZMWB", { "id": "m1", "color": "#1f77b4" } ],
                    [ ".", "MemoryReservedMB", ".", ".", { "id": "m2", "color": "#bcbd22" } ],
                    [ ".", "MemoryAllocatedMB", ".", ".", { "id": "m3", "color": "#ff7f0e" } ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "eu-central-1",
                "period": 300,
                "title": "EMR Cluster Memory Usage"
            }
        },
        {
            "type": "metric",
            "x": 12,
            "y": 6,
            "width": 12,
            "height": 3,
            "properties": {
                "metrics": [
                    [ "System/Linux", "DiskSpaceUtilization", "MountPath", "/", "InstanceId", "i-0c8ac9ba08afb5956", "Filesystem", "/dev/xvda1", { "label": "DiskSpaceUtilization" } ],
                    [ ".", "MemoryUtilization", "InstanceId", "i-0c8ac9ba08afb5956" ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "eu-central-1",
                "title": "Kafka Status",
                "period": 300,
                "yAxis": {
                    "left": {
                        "max": 100,
                        "min": 0
                    }
                }
            }
        },
        {
            "type": "metric",
            "x": 0,
            "y": 9,
            "width": 12,
            "height": 6,
            "properties": {
                "metrics": [
                    [ { "expression": "(RATE(m4) + RATE(m5)) * 100", "label": "Apps Killed Or Failed", "id": "e1", "color": "#d62728", "region": "eu-central-1" } ],
                    [ "AWS/ElasticMapReduce", "AppsRunning", "JobFlowId", "j-3AZII9CYEZMWB", { "id": "m1", "color": "#2ca02c" } ],
                    [ ".", "AppsFailed", ".", ".", { "id": "m4", "visible": false, "color": "#9467bd" } ],
                    [ ".", "AppsKilled", ".", ".", { "id": "m5", "visible": false, "color": "#c5b0d5" } ]
                ],
                "view": "timeSeries",
                "stacked": false,
                "region": "eu-central-1",
                "period": 300,
                "title": "Running Apps / Killed Or Failed",
                "stat": "Average"
            }
        },
        {
            "type": "metric",
            "x": 0,
            "y": 15,
            "width": 12,
            "height": 3,
            "properties": {
                "view": "timeSeries",
                "stacked": false,
                "metrics": [
                    [ "System/Linux", "MemoryUtilization", "InstanceId", "i-02e2f041e1a53a56f" ]
                ],
                "region": "eu-central-1",
                "title": "Ingester Memory Usage",
                "period": 300,
                "yAxis": {
                    "left": {
                        "min": 0,
                        "max": 100
                    }
                }
            }
        },
        {
            "type": "metric",
            "x": 12,
            "y": 0,
            "width": 6,
            "height": 6,
            "properties": {
                "title": "KafkaDiskSpaceExceeded",
                "annotations": {
                    "alarms": [
                        "arn:aws:cloudwatch:eu-central-1:640172962304:alarm:KafkaDiskSpaceExceeded"
                    ]
                },
                "view": "timeSeries",
                "stacked": false
            }
        },
        {
            "type": "alarm",
            "x": 18,
            "y": 0,
            "width": 6,
            "height": 3,
            "properties": {
                "title": "",
                "alarms": [
                    "arn:aws:cloudwatch:eu-central-1:640172962304:alarm:AppsKilledOrFailed",
                    "arn:aws:cloudwatch:eu-central-1:640172962304:alarm:HdfsFilesTooOld",
                    "arn:aws:cloudwatch:eu-central-1:640172962304:alarm:KafkaDiskSpaceExceeded"
                ]
            }
        }
    ]
}
 EOF
}

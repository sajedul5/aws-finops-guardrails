import os
import sys

import boto3
import pytest
from moto import mock_aws

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "modules", "offhours-scheduler", "lambda"))

REGION = "us-east-1"


@pytest.fixture(autouse=True)
def aws_env(monkeypatch):
    """Fake credentials and default scheduler settings for every test."""
    monkeypatch.setenv("AWS_ACCESS_KEY_ID", "testing")
    monkeypatch.setenv("AWS_SECRET_ACCESS_KEY", "testing")
    monkeypatch.setenv("AWS_DEFAULT_REGION", REGION)
    monkeypatch.setenv("TAG_KEY", "Schedule")
    monkeypatch.setenv("TAG_VALUE", "office-hours")
    monkeypatch.setenv("DRY_RUN", "false")


@pytest.fixture
def aws():
    with mock_aws():
        yield {"ec2": boto3.client("ec2", region_name=REGION), "rds": boto3.client("rds", region_name=REGION)}

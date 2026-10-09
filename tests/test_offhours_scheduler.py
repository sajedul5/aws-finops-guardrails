import pytest

import handler

SCHEDULED = [{"Key": "Schedule", "Value": "office-hours"}]


def run_instance(ec2, tags=None):
    kwargs = {"ImageId": "ami-12345678", "MinCount": 1, "MaxCount": 1, "InstanceType": "t3.micro"}
    if tags:
        kwargs["TagSpecifications"] = [{"ResourceType": "instance", "Tags": tags}]
    return ec2.run_instances(**kwargs)["Instances"][0]["InstanceId"]


def ec2_state(ec2, iid):
    return ec2.describe_instances(InstanceIds=[iid])["Reservations"][0]["Instances"][0]["State"]["Name"]


def create_db(rds, dbid, tags):
    rds.create_db_instance(
        DBInstanceIdentifier=dbid,
        DBInstanceClass="db.t3.micro",
        Engine="postgres",
        MasterUsername="admin",
        MasterUserPassword="password123",
        AllocatedStorage=20,
        Tags=tags,
    )


def db_status(rds, dbid):
    return rds.describe_db_instances(DBInstanceIdentifier=dbid)["DBInstances"][0]["DBInstanceStatus"]


# --- EC2 ---------------------------------------------------------------------


def test_stop_only_touches_tagged_instances(aws):
    tagged = run_instance(aws["ec2"], SCHEDULED)
    untagged = run_instance(aws["ec2"])
    other_value = run_instance(aws["ec2"], [{"Key": "Schedule", "Value": "always-on"}])

    result = handler.handler({"action": "stop"}, None)

    assert result["ec2"]["changed"] == [tagged]
    assert ec2_state(aws["ec2"], tagged) == "stopped"
    assert ec2_state(aws["ec2"], untagged) == "running"
    assert ec2_state(aws["ec2"], other_value) == "running"


def test_start_brings_stopped_instances_back(aws):
    iid = run_instance(aws["ec2"], SCHEDULED)
    aws["ec2"].stop_instances(InstanceIds=[iid])

    result = handler.handler({"action": "start"}, None)

    assert result["ec2"]["changed"] == [iid]
    assert ec2_state(aws["ec2"], iid) == "running"


def test_auto_scaling_members_are_skipped(aws):
    iid = run_instance(aws["ec2"], SCHEDULED + [{"Key": "aws:autoscaling:groupName", "Value": "web-asg"}])

    result = handler.handler({"action": "stop"}, None)

    assert result["ec2"]["changed"] == []
    assert result["ec2"]["skipped"] == [{"id": iid, "reason": "Auto Scaling group member"}]
    assert ec2_state(aws["ec2"], iid) == "running"


def test_dry_run_reports_but_changes_nothing(aws, monkeypatch):
    monkeypatch.setenv("DRY_RUN", "true")
    iid = run_instance(aws["ec2"], SCHEDULED)

    result = handler.handler({"action": "stop"}, None)

    assert result["dry_run"] is True
    assert result["ec2"]["changed"] == [iid]
    assert ec2_state(aws["ec2"], iid) == "running"


def test_stop_is_idempotent(aws):
    run_instance(aws["ec2"], SCHEDULED)
    handler.handler({"action": "stop"}, None)

    second = handler.handler({"action": "stop"}, None)

    assert second["ec2"]["changed"] == []


# --- RDS ---------------------------------------------------------------------


def test_stop_and_start_tagged_rds_instance(aws):
    create_db(aws["rds"], "dev-db", SCHEDULED)
    create_db(aws["rds"], "prod-db", [{"Key": "Environment", "Value": "prod"}])

    stopped = handler.handler({"action": "stop"}, None)
    assert stopped["rds_instances"]["changed"] == ["dev-db"]
    assert db_status(aws["rds"], "dev-db") == "stopped"
    assert db_status(aws["rds"], "prod-db") == "available"

    started = handler.handler({"action": "start"}, None)
    assert started["rds_instances"]["changed"] == ["dev-db"]
    assert db_status(aws["rds"], "dev-db") == "available"


def test_rds_can_be_excluded(aws, monkeypatch):
    monkeypatch.setenv("INCLUDE_RDS", "false")
    create_db(aws["rds"], "dev-db", SCHEDULED)

    result = handler.handler({"action": "stop"}, None)

    assert "rds_instances" not in result
    assert db_status(aws["rds"], "dev-db") == "available"


# --- Input and failures ------------------------------------------------------


@pytest.mark.parametrize("event", [{}, {"action": "reboot"}, None])
def test_invalid_action_is_rejected(aws, event):
    with pytest.raises(ValueError):
        handler.handler(event, None)


def test_failures_fail_the_invocation(aws, monkeypatch):
    run_instance(aws["ec2"], SCHEDULED)

    def boom(**_):
        from botocore.exceptions import ClientError

        raise ClientError({"Error": {"Code": "UnauthorizedOperation", "Message": "denied"}}, "StopInstances")

    real_client = handler.boto3.client

    def client(name, **kwargs):
        c = real_client(name, **kwargs)
        if name == "ec2":
            c.stop_instances = boom
        return c

    monkeypatch.setattr(handler.boto3, "client", client)

    with pytest.raises(RuntimeError, match="1 resource"):
        handler.handler({"action": "stop"}, None)


def test_stop_tagged_aurora_cluster(aws):
    aws["rds"].create_db_cluster(
        DBClusterIdentifier="dev-aurora",
        Engine="aurora-postgresql",
        MasterUsername="admin",
        MasterUserPassword="password123",
        Tags=SCHEDULED,
    )

    result = handler.handler({"action": "stop"}, None)

    assert result["rds_clusters"]["changed"] == ["dev-aurora"]
    status = aws["rds"].describe_db_clusters(DBClusterIdentifier="dev-aurora")["DBClusters"][0]["Status"]
    assert status == "stopped"

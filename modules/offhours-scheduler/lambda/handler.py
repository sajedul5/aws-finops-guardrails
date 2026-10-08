"""Stop or start EC2 instances, RDS instances and Aurora clusters that carry a schedule tag.

Invoked by EventBridge Scheduler with {"action": "stop"} or {"action": "start"}.
Only resources tagged TAG_KEY=TAG_VALUE are touched. Resources AWS can't safely
stop (Auto Scaling members, Spot instances, RDS read replicas) are skipped and logged.
"""

import json
import logging
import os

import boto3
from botocore.exceptions import ClientError

logger = logging.getLogger()
logger.setLevel(logging.INFO)

EC2_BATCH_SIZE = 50

# Resource state the action applies to, per service.
EC2_STATE = {"stop": "running", "start": "stopped"}
RDS_STATE = {"stop": "available", "start": "stopped"}


def _env_bool(name, default):
    return os.environ.get(name, str(default)).strip().lower() in ("1", "true", "yes")


def _config():
    return {
        "tag_key": os.environ.get("TAG_KEY", "Schedule"),
        "tag_value": os.environ.get("TAG_VALUE", "office-hours"),
        "dry_run": _env_bool("DRY_RUN", False),
        "include_ec2": _env_bool("INCLUDE_EC2", True),
        "include_rds": _env_bool("INCLUDE_RDS", True),
    }


def _has_tag(tag_list, key, value):
    return any(t.get("Key") == key and t.get("Value") == value for t in tag_list or [])


def _new_report():
    return {"changed": [], "skipped": [], "failed": []}


def process_ec2(ec2, action, cfg):
    report = _new_report()
    filters = [
        {"Name": f"tag:{cfg['tag_key']}", "Values": [cfg["tag_value"]]},
        {"Name": "instance-state-name", "Values": [EC2_STATE[action]]},
    ]

    targets = []
    for page in ec2.get_paginator("describe_instances").paginate(Filters=filters):
        for reservation in page["Reservations"]:
            for inst in reservation["Instances"]:
                iid = inst["InstanceId"]
                tag_keys = {t["Key"] for t in inst.get("Tags", [])}
                if "aws:autoscaling:groupName" in tag_keys:
                    report["skipped"].append({"id": iid, "reason": "Auto Scaling group member"})
                elif inst.get("InstanceLifecycle") == "spot":
                    report["skipped"].append({"id": iid, "reason": "Spot instance"})
                else:
                    targets.append(iid)

    call = ec2.stop_instances if action == "stop" else ec2.start_instances
    for i in range(0, len(targets), EC2_BATCH_SIZE):
        batch = targets[i : i + EC2_BATCH_SIZE]
        if cfg["dry_run"]:
            report["changed"].extend(batch)
            continue
        try:
            call(InstanceIds=batch)
            report["changed"].extend(batch)
        except ClientError as err:
            report["failed"].extend({"id": iid, "error": str(err)} for iid in batch)

    return report


def process_rds_instances(rds, action, cfg):
    report = _new_report()

    for page in rds.get_paginator("describe_db_instances").paginate():
        for db in page["DBInstances"]:
            dbid = db["DBInstanceIdentifier"]
            if not _has_tag(db.get("TagList"), cfg["tag_key"], cfg["tag_value"]):
                continue
            if db.get("DBClusterIdentifier"):
                continue  # Aurora members are handled at cluster level.
            if db.get("DBInstanceStatus") != RDS_STATE[action]:
                continue
            if db.get("ReadReplicaSourceDBInstanceIdentifier") or db.get("ReadReplicaDBInstanceIdentifiers"):
                report["skipped"].append({"id": dbid, "reason": "read replica or has replicas"})
                continue

            if cfg["dry_run"]:
                report["changed"].append(dbid)
                continue
            try:
                if action == "stop":
                    rds.stop_db_instance(DBInstanceIdentifier=dbid)
                else:
                    rds.start_db_instance(DBInstanceIdentifier=dbid)
                report["changed"].append(dbid)
            except ClientError as err:
                report["failed"].append({"id": dbid, "error": str(err)})

    return report


def process_rds_clusters(rds, action, cfg):
    report = _new_report()

    for page in rds.get_paginator("describe_db_clusters").paginate():
        for cluster in page["DBClusters"]:
            cid = cluster["DBClusterIdentifier"]
            if not _has_tag(cluster.get("TagList"), cfg["tag_key"], cfg["tag_value"]):
                continue
            if cluster.get("Status") != RDS_STATE[action]:
                continue
            if cluster.get("EngineMode") == "serverless":
                report["skipped"].append({"id": cid, "reason": "Aurora Serverless v1 can't be stopped"})
                continue

            if cfg["dry_run"]:
                report["changed"].append(cid)
                continue
            try:
                if action == "stop":
                    rds.stop_db_cluster(DBClusterIdentifier=cid)
                else:
                    rds.start_db_cluster(DBClusterIdentifier=cid)
                report["changed"].append(cid)
            except ClientError as err:
                report["failed"].append({"id": cid, "error": str(err)})

    return report


def handler(event, context):
    action = (event or {}).get("action")
    if action not in ("stop", "start"):
        raise ValueError(f'event.action must be "stop" or "start", got {action!r}')

    cfg = _config()
    result = {"action": action, "dry_run": cfg["dry_run"]}

    if cfg["include_ec2"]:
        result["ec2"] = process_ec2(boto3.client("ec2"), action, cfg)
    if cfg["include_rds"]:
        rds = boto3.client("rds")
        result["rds_instances"] = process_rds_instances(rds, action, cfg)
        result["rds_clusters"] = process_rds_clusters(rds, action, cfg)

    logger.info(json.dumps(result))

    # Fail the invocation so the Lambda Errors metric (and Scheduler retries) surface problems.
    # Retrying is safe: resources already in the target state are filtered out.
    failures = [f for key in ("ec2", "rds_instances", "rds_clusters") for f in result.get(key, {}).get("failed", [])]
    if failures:
        raise RuntimeError(f"{len(failures)} resource(s) failed to {action}: {json.dumps(failures)}")

    return result

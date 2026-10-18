"""Demo: run the real off-hours scheduler Lambda against a FAKE AWS account (moto).

No AWS account or credentials needed; nothing real is touched.
Run it with:  make demo
"""
import json
import os
import sys

for k, v in {"AWS_ACCESS_KEY_ID": "demo", "AWS_SECRET_ACCESS_KEY": "demo", "AWS_DEFAULT_REGION": "us-east-1",
             "TAG_KEY": "Schedule", "TAG_VALUE": "office-hours"}.items():
    os.environ[k] = v
for k in ("AWS_PROFILE", "AWS_SESSION_TOKEN"):
    os.environ.pop(k, None)
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "modules", "offhours-scheduler", "lambda"))

import boto3  # noqa: E402
from moto import mock_aws  # noqa: E402

import handler  # noqa: E402

OPT_IN = {"Key": "Schedule", "Value": "office-hours"}
PRICE = {"t3.large": 0.0832, "m5.xlarge": 0.192}  # us-east-1 on-demand $/hour (list price)


def launch(ec2, name, itype, tags):
    tags = [{"Key": "Name", "Value": name}] + tags
    r = ec2.run_instances(ImageId="ami-12345678", InstanceType=itype, MinCount=1, MaxCount=1,
                          TagSpecifications=[{"ResourceType": "instance", "Tags": tags}])
    return r["Instances"][0]["InstanceId"]


def show(ec2, rds, title):
    print(f"\n--- {title} ---")
    for res in ec2.describe_instances()["Reservations"]:
        for i in res["Instances"]:
            tags = {t["Key"]: t["Value"] for t in i.get("Tags", [])}
            mark = "🟢" if i["State"]["Name"] == "running" else "🔴"
            print(f"  {mark} EC2 {tags['Name']:<16} {i['InstanceType']:<10} {i['State']['Name']:<8} "
                  f"Schedule={tags.get('Schedule', '-')}")
    for db in rds.describe_db_instances()["DBInstances"]:
        mark = "🟢" if db["DBInstanceStatus"] == "available" else "🔴"
        tags = {t["Key"]: t["Value"] for t in db.get("TagList", [])}
        print(f"  {mark} RDS {db['DBInstanceIdentifier']:<16} {db['DBInstanceClass']:<10} "
              f"{db['DBInstanceStatus']:<8} Schedule={tags.get('Schedule', '-')}")


def run(action, dry_run):
    os.environ["DRY_RUN"] = str(dry_run).lower()
    print(f"\n⏰ EventBridge Scheduler → Lambda {{\"action\": \"{action}\"}}  (DRY_RUN={dry_run})")
    result = handler.handler({"action": action}, None)
    print("  Lambda report (what CloudWatch Logs shows):")
    print("  " + json.dumps(result, indent=2).replace("\n", "\n  "))


with mock_aws():
    ec2 = boto3.client("ec2")
    rds = boto3.client("rds")

    launch(ec2, "dev-api", "t3.large", [OPT_IN])
    launch(ec2, "test-worker", "m5.xlarge", [OPT_IN])
    launch(ec2, "prod-api", "m5.xlarge", [{"Key": "Environment", "Value": "prod"}])
    launch(ec2, "dev-asg-node", "t3.large", [OPT_IN, {"Key": "aws:autoscaling:groupName", "Value": "dev-asg"}])
    rds.create_db_instance(DBInstanceIdentifier="dev-db", DBInstanceClass="db.t3.medium", Engine="postgres",
                           MasterUsername="demo", MasterUserPassword="demo-password-123", AllocatedStorage=20,
                           Tags=[OPT_IN])

    show(ec2, rds, "Morning: everything is running")

    print("\n================ WEEK 1: DRY RUN (safe test) ================")
    run("stop", dry_run=True)
    show(ec2, rds, "After the dry run: nothing changed, it only logged")

    print("\n================ WEEK 2: LIVE ================")
    run("stop", dry_run=False)
    show(ec2, rds, "8 PM: tagged dev/test resources are stopped")

    run("start", dry_run=False)
    show(ec2, rds, "8 AM next day: started again for work")

    on, week = 12 * 5, 168
    saved = (PRICE["t3.large"] + PRICE["m5.xlarge"]) * (week - on) * 52 / 12
    print(f"\n💰 Estimate: dev-api + test-worker run {on} of {week} h/week → "
          f"{100 * (week - on) / week:.0f}% fewer hours ≈ ${saved:,.0f}/month saved on EC2 compute "
          f"(us-east-1 list prices; typical estimate).")

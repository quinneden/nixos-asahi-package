import boto3
import re
import os

access_key_id = os.environ["ACCESS_KEY_ID"]
secret_access_key = os.environ["SECRET_ACCESS_KEY"]

session = boto3.Session(
    aws_access_key_id=access_key_id,
    aws_secret_access_key=secret_access_key,
)

s3 = session.resource(
    "s3",
    endpoint_url="https://fb446c3eff8c78b8982e070223d32048.r2.cloudflarestorage.com",
    region_name="auto",
)

my_bucket = s3.Bucket("nixos-asahi")

substring = "os"

for obj in my_bucket.objects.all():
    if re.search(substring, obj.key):
        if obj.key.endswith("json"):
            print(obj.key)

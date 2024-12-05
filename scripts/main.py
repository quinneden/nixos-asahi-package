import boto3
import os
import sys
from botocore.config import Config

aws_access_key_id = os.environ["ACCESS_KEY_ID"]
aws_secret_access_key = os.environ["SECRET_ACCESS_KEY"]
r2_endpoint = os.environ["ENDPOINT_URL"]

bucket_name = os.environ["BUCKET"]

tmp_dir = os.environ["TMP"]
pkg = os.environ["PKG"]

if len(sys.argv) > 1:
    if sys.argv[1] == "pkg":
        file_path = os.path.join(tmp_dir, pkg)
        object_key = os.path.join("os", pkg)
    if sys.argv[1] == "data":
        file_path = "data/installer_data.json"
        object_key = file_path

s3 = boto3.client(
    "s3",
    region_name="auto",
    config=Config(signature_version="s3v4"),
    aws_access_key_id=aws_access_key_id,
    aws_secret_access_key=aws_secret_access_key,
    endpoint_url=r2_endpoint,
)

transfer_config = boto3.s3.transfer.TransferConfig(
    multipart_threshold=8 * 1024 * 1024,  # 8 MB
    multipart_chunksize=8 * 1024 * 1024,  # 8 MB
)

with open(file_path, "rb") as f:
    s3.upload_fileobj(
        Fileobj=f,
        Bucket=bucket_name,
        Key=object_key,
        Config=transfer_config,
    )

print(f"{file_path} uploaded successfully to {bucket_name}.")
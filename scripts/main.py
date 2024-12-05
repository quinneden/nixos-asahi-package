import boto3
import os

aws_access_key_id = os.environ["ACCESS_KEY_ID"]
aws_secret_access_key = os.environ["SECRET_ACCESS_KEY"]

bucket_name = os.environ["BUCKET"]

tmp_dir = os.environ["TMP"]
pkg = os.environ["PKG"]

file_path = os.path.join(tmp_dir, pkg)

s3 = boto3.client(
    "s3",
    aws_access_key_id=aws_access_key_id,
    aws_secret_access_key=aws_secret_access_key,
)

transfer_config = boto3.s3.transfer.TransferConfig(
    multipart_threshold=8 * 1024 * 1024,  # 8 MB
    multipart_chunksize=8 * 1024 * 1024,  # 8 MB
)

with open(file_path, "rb") as f:
    s3.upload_fileobj(
        Fileobj=f,
        Bucket=bucket_name,
        Key=pkg,
        Config=transfer_config,
    )

print(f"{file_path} uploaded successfully to {bucket_name} using TransferConfig.")

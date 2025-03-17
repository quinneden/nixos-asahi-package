import boto3
import os
from botocore.config import Config

pkg_zip = os.getenv("pkgZip")
pkg_data = "installer_data.json"

obj_list = [pkg_zip, pkg_data]

s3 = boto3.client(
    "s3",
    region_name="auto",
    config=Config(signature_version="s3v4"),
    aws_access_key_id=os.getenv("ACCESS_KEY_ID"),
    aws_secret_access_key=os.getenv("SECRET_ACCESS_KEY"),
    endpoint_url=os.getenv("ENDPOINT_URL"),
)

transfer_config = boto3.s3.transfer.TransferConfig(
    multipart_threshold=8 * 1024 * 1024,
    multipart_chunksize=8 * 1024 * 1024,
)


def upload_to_r2(file):
    content_type = (
        "text/plain" if file.endswith(
            ".json") else "application/octet-stream"
    )
    prefix = "data" if file.endswith(".json") else "os"
    with open(file, "rb") as fb:
        s3.upload_fileobj(
            fb,
            ExtraArgs={"ContentType": content_type},
            Bucket=os.getenv("BUCKET_NAME"),
            Key=os.path.join(prefix, file),
            Config=transfer_config,
        )


for obj in obj_list:
    upload_to_r2(obj)

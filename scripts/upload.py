import os
import boto3
from botocore.config import Config

bucket_name = os.getenv("BUCKET_NAME")
pkg_zip = os.getenv("pkgZip")
pkg_data = "installer_data.json"

object_type_set = {pkg_data: "text/plain", pkg_zip: "application/octet-stream"}

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


def upload_to_r2(file, content_type):
    prefix = "data" if file.endswith(".json") else "os"
    with open(file, "rb") as fb:
        s3.upload_fileobj(
            fb,
            ExtraArgs={"ContentType": content_type},
            Bucket=bucket_name,
            Key=os.path.join(prefix, file),
            Config=transfer_config,
        )


for obj, ctype in object_type_set.items():
    upload_to_r2(obj, ctype)

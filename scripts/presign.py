import boto3, os
from botocore.config import Config

access_key_id = str(os.environ.get("ACCESS_KEY_ID", None))
secret_access_key = str(os.environ.get("SECRET_ACCESS_KEY", None))
r2_endpoint_url = str(os.environ.get("ENDPOINT_URL", None))

s3 = boto3.client(
    "s3",
    region_name="auto",
    config=Config(signature_version="s3v4"),
    aws_access_key_id=access_key_id,
    aws_secret_access_key=secret_access_key,
    endpoint_url=r2_endpoint_url,
)

bucket = str(os.environ.get("BUCKET", None))
filename = str(os.environ.get("PKG", None))

presigned_url = s3.generate_presigned_url(
    ClientMethod="put_object",
    Params={
        "Bucket": bucket,
        "Key": filename,
    },
    ExpiresIn=3600,
    HttpMethod="PUT",
)

print(presigned_url)

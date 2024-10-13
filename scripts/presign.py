import boto3, os

s3 = boto3.client("s3")

s3 = boto3.client(
    "s3",
    aws_access_key_id=os.environ.get("ACCESS_KEY_ID", None),
    aws_secret_access_key=os.environ.get("SECRET_ACCESS_KEY", None),
)

bucket = str("temp0")
filename = str(os.environ.get("PKG", None))

presigned_url = s3.generate_presigned_url(
    "put_object",
    Params={"Bucket": bucket, "Key": filename, },
    ExpiresIn=3600,
    HttpMethod="PUT",
)

print(presigned_url)

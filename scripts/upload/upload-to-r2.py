#!/usr/bin/env python3
# -*- coding: ASCII -*-
import json
import os
import requests
import tempfile
from pathlib import Path

import boto3
from botocore.config import Config
from tqdm import tqdm


def append_installer_data(idata, url=None):
    response = requests.get(url)
    os_list = response.json() if response.status_code == 200 else {"os_list": []}
    with open(idata, "r") as data:
        new_data = json.load(data)
    try:
        os_list["os_list"].append(new_data)
        return os_list
    except TypeError as e:
        print(f"Error appending installer data: {str(e)}")


def upload_to_r2(file: str, content_type: str):
    s3_client = boto3.client(
        "s3",
        aws_access_key_id=os.getenv("ACCESS_KEY_ID"),
        aws_secret_access_key=os.getenv("SECRET_ACCESS_KEY"),
        config=Config(signature_version="s3v4"),
        endpoint_url=os.getenv("ENDPOINT_URL"),
        region_name="auto",
    )

    file_name = Path(file).name
    file_size = Path(file).stat().st_size
    object_prefix = "data" if file_name.endswith(".json") else "os"
    object_key = f"{object_prefix}/{file_name}"

    with tqdm(total=file_size, desc=file_name, unit="B", unit_scale=True) as progress:
        with open(file, "rb") as file_bytes:
            s3_client.upload_fileobj(
                file_bytes,
                Bucket=os.getenv("BUCKET_NAME"),
                Callback=progress.update,
                ExtraArgs={"ContentType": content_type},
                Key=object_key,
            )


if __name__ == "__main__":
    pkg_zip = os.getenv("PKG_ZIP")
    pkg_data = os.getenv("PKG_DATA")
    merged_data = append_installer_data(
        pkg_data, url="https://cdn.qeden.dev/data/installer_data.json"
    )

    with tempfile.TemporaryDirectory() as temp_dir:
        os.chdir(temp_dir)

        with open("installer_data.json", "w") as file:
            json.dump(merged_data, file)

        upload_to_r2("installer_data.json", "text/plain")
        upload_to_r2(pkg_zip, "application/octet-stream")

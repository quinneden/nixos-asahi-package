import os, sys
import boto3
from tqdm import tqdm
from colorthon import Colors as Fore

# def get_user_input(prompt, example=''):
#     user_input = input(f"{Fore.GREEN}{prompt}{Fore.RESET} [{Fore.GREY}e.x: {example}{Fore.RESET}]: ").strip()
#     return user_input
#
def validate_input(input_value, expected_length, message):
    if not input_value or len(input_value) != expected_length:
        print(f"\n{Fore.RED}{message} Exiting...{Fore.RESET}")
        exit(1)

def upload_to_r2_cloudflare(endpoint_url, access_key_id, secret_key, region_name, remote_folder, local_file):
    s3 = boto3.client('s3', endpoint_url=endpoint_url, aws_access_key_id=access_key_id,
                      aws_secret_access_key=secret_key, region_name=region_name)

    file_name = os.path.basename(local_file)
    file_size = os.path.getsize(local_file)
    print(f"File Name: {Fore.GREY}{file_name}{Fore.RESET}")
    print(f"File Size: {Fore.MAGENTA}{round(file_size / 1024 / 1024, 2)} MB{Fore.RESET}")

    with tqdm(total=file_size, unit='B', unit_scale=True, desc=f'Uploading {file_name} to R2', ascii=True) as pbar:
        with open(local_file, 'rb') as f:
            s3.upload_fileobj(f, remote_folder, file_name, Callback=lambda x: pbar.update(x))

def main():
    account_id = str(os.environ[f"ACCOUNT_ID"])
    access_key = str(os.environ[f"ACCESS_KEY"])
    secret_key = str(os.environ[f"SECRET_KEY"])
    reg_name = str(os.environ[f"REGION"])


    validate_input(account_id, 32, 'Missing or invalid Account ID')
    validate_input(access_key, 32, 'Missing or invalid Access Key ID')
    validate_input(secret_key, 64, 'Missing or invalid Secret Key')

    endpoint_url = f'https://{account_id}.r2.cloudflarestorage.com'
    remote_folder = str(os.environ[f"BUCKET"])
    file_path = str(os.environ[f"TMP"] + '/' + os.environ[f"PKG"])

    print(f"{Fore.GREEN}Folder Path:{Fore.RESET} {Fore.YELLOW}{remote_folder}{Fore.RESET}")

    upload_to_r2_cloudflare(endpoint_url, access_key, secret_key, reg_name, remote_folder, file_path)

if __name__ == "__main__":
    main()

import os
from huggingface_hub import login, HfApi

# -------------------------------------------------------------------------
# INSTRUCTIONS:
# 1. Get a Hugging Face token with "write" permission from:
#    https://huggingface.co/settings/tokens
# 2. Replace "YOUR_HF_WRITE_TOKEN_HERE" below with your token.
# 3. Run: py upload_space.py
# -------------------------------------------------------------------------

import sys

HF_TOKEN = os.environ.get("HF_TOKEN") or "YOUR_HF_WRITE_TOKEN_HERE"
SPACE_ID = "Vijayadhith7/AURA-Backend"

# Check if token is passed via command-line argument
if len(sys.argv) > 1 and sys.argv[1] != "":
    HF_TOKEN = sys.argv[1]

if HF_TOKEN == "YOUR_HF_WRITE_TOKEN_HERE" or not HF_TOKEN:
    print("ERROR: Please provide your actual Hugging Face Write Token.")
    print("Usage: py upload_space.py <HF_WRITE_TOKEN> or set HF_TOKEN environment variable.")
    exit(1)

# Login to Hugging Face
print("Logging in to Hugging Face...")
login(token=HF_TOKEN)

# Initialize HfApi
api = HfApi()

# Upload the contents of the python_backend directory directly to the Space root
backend_dir = os.path.abspath("python_backend")
print(f"Uploading files from: {backend_dir} to Hugging Face Space: {SPACE_ID}")
print("Uploading... This might take a few minutes depending on your internet connection.")

api.upload_folder(
    folder_path=backend_dir,
    repo_id=SPACE_ID,
    repo_type="space"
)

print("\n🚀 SUCCESS: Your Space files are uploaded! Monitor the build logs at:")
print(f"https://huggingface.co/spaces/{SPACE_ID}")

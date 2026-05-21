import os
from huggingface_hub import login, HfApi

# -------------------------------------------------------------------------
# INSTRUCTIONS:
# 1. Get a Hugging Face token with "write" permission from:
#    https://huggingface.co/settings/tokens
# 2. Replace "YOUR_HF_WRITE_TOKEN_HERE" below with your token.
# 3. Run: py upload_space.py
# -------------------------------------------------------------------------

HF_TOKEN = "YOUR_HF_WRITE_TOKEN_HERE"
SPACE_ID = "Vijayadhith7/AURA-Backend"

if HF_TOKEN == "YOUR_HF_WRITE_TOKEN_HERE":
    print("ERROR: Please replace 'YOUR_HF_WRITE_TOKEN_HERE' with your actual Hugging Face Write Token in the script.")
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

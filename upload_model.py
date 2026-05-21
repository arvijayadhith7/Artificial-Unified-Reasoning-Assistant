import os
from huggingface_hub import login, HfApi

# -------------------------------------------------------------------------
# INSTRUCTIONS:
# 1. Get a Hugging Face token with "write" permission from:
#    https://huggingface.co/settings/tokens
# 2. Replace "YOUR_HF_WRITE_TOKEN_HERE" below with your token.
# 3. Replace "your-username/aura-qwen-0.5b" with your HF username and desired repo name.
# 4. Run: py upload_model.py
# -------------------------------------------------------------------------

HF_TOKEN = "YOUR_HF_WRITE_TOKEN_HERE"
REPO_ID = "your-username/aura-qwen-0.5b"

if HF_TOKEN == "YOUR_HF_WRITE_TOKEN_HERE":
    print("ERROR: Please replace 'YOUR_HF_WRITE_TOKEN_HERE' with your actual Hugging Face Write Token in the script.")
    exit(1)

if REPO_ID == "your-username/aura-qwen-0.5b":
    print("ERROR: Please replace 'your-username/aura-qwen-0.5b' with your Hugging Face username and repository name.")
    exit(1)

# Login to Hugging Face
print("Logging in to Hugging Face...")
login(token=HF_TOKEN)

# Initialize HfApi
api = HfApi()

# Create the repo if it does not exist
print(f"Ensuring repository '{REPO_ID}' exists...")
api.create_repo(repo_id=REPO_ID, exist_ok=True)

# Upload the custom_model directory
model_dir = os.path.abspath("models/custom_model")
print(f"Uploading files from: {model_dir}")
print("Uploading... This might take a few minutes depending on your internet connection.")

api.upload_folder(
    folder_path=model_dir,
    repo_id=REPO_ID,
    repo_type="model"
)

print("\n🚀 SUCCESS: Your custom model is now live at:")
print(f"https://huggingface.co/{REPO_ID}")

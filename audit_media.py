import os
from PIL import Image

brain_dir = 'C:/Users/ASUS/.gemini/antigravity-ide/brain/f7a92b6b-4d7c-49d7-a85b-debddb2cac19'
for filename in os.listdir(brain_dir):
    if filename.startswith('media__') and filename.endswith(('.png', '.jpg', '.jpeg')):
        path = os.path.join(brain_dir, filename)
        img = Image.open(path)
        print(f"File: {filename}, Size: {img.size}, Format: {img.format}, SizeBytes: {os.path.getsize(path)}")

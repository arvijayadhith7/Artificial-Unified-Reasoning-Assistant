import os
import json
import logging
from typing import Iterator, Dict, Any

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("UIControlDataset")

try:
    import tensorflow as tf
    from huggingface_hub import snapshot_download
except ImportError:
    logger.warning("TensorFlow or HuggingFace Hub is not installed. To run this dataset parser, install them using: pip install tensorflow huggingface_hub")

class UIControlDatasetManager:
    """
    Manager to download, stream, and parse the Google Android UI Control Dataset from Hugging Face.
    Used to train and fine-tune Aura Assist's screen automation and context parsing engines.
    
    Paper Reference: "On the Effects of Data Scale on UI Control Agents" (Wei Li et al., 2024)
    """
    def __init__(self, cache_dir: str = "./memory/datasets/android_control"):
        self.cache_dir = cache_dir
        os.makedirs(self.cache_dir, exist_ok=True)

    def download_dataset(self, repo_id: str = "google/android_control") -> str:
        """
        Downloads the dataset files securely from Hugging Face Hub using snapshot_download.
        Returns the absolute path to the downloaded directory containing TFRecords.
        """
        logger.info(f"Downloading Android UI Control Dataset from HF repo: '{repo_id}'...")
        try:
            download_path = snapshot_download(
                repo_id=repo_id,
                repo_type="dataset",
                cache_dir=self.cache_dir,
                allow_patterns=["android_control*"]
            )
            logger.info(f"Dataset downloaded successfully to: {download_path}")
            return download_path
        except Exception as e:
            logger.error(f"Failed downloading from Hugging Face Hub: {e}")
            # Fallback to returning local directory path
            return self.cache_dir

    def _parse_tfrecord_example(self, serialized_example: bytes) -> Dict[str, Any]:
        """
        Parses a single serialized TFRecord example from the Android Control Dataset structure.
        Extracts tasks, screen dimensions, visual layout view hierarchies, bounding boxes, and action targets.
        """
        # Description of features in the TFRecord schema for Android UI Control Agents
        feature_description = {
            'task_instruction': tf.io.FixedLenFeature([], tf.string),
            'screenshot_png': tf.io.FixedLenFeature([], tf.string, default_value=''),
            'ui_hierarchy_json': tf.io.FixedLenFeature([], tf.string, default_value=''),
            'action_type': tf.io.FixedLenFeature([], tf.string),
            'action_touch_x': tf.io.FixedLenFeature([], tf.float32, default_value=0.0),
            'action_touch_y': tf.io.FixedLenFeature([], tf.float32, default_value=0.0),
            'app_package': tf.io.FixedLenFeature([], tf.string, default_value=''),
        }
        
        parsed = tf.io.parse_single_example(serialized_example, feature_description)
        
        # Decode strings safely
        task_instruction = parsed['task_instruction'].numpy().decode('utf-8')
        ui_hierarchy = parsed['ui_hierarchy_json'].numpy().decode('utf-8')
        action_type = parsed['action_type'].numpy().decode('utf-8')
        app_package = parsed['app_package'].numpy().decode('utf-8')
        
        # Try parsing JSON hierarchy
        hierarchy_dict = {}
        if ui_hierarchy:
            try:
                hierarchy_dict = json.loads(ui_hierarchy)
            except json.JSONDecodeError:
                hierarchy_dict = {"raw": ui_hierarchy}

        return {
            "task": task_instruction,
            "app_package": app_package,
            "action": {
                "type": action_type,
                "x": float(parsed['action_touch_x'].numpy()),
                "y": float(parsed['action_touch_y'].numpy()),
            },
            "ui_hierarchy": hierarchy_dict
        }

    def stream_records(self, dataset_dir: str) -> Iterator[Dict[str, Any]]:
        """
        Locates the GZIP compressed TFRecord files and streams parsed structured screen-action pairs.
        Can be fed directly into a fine-tuning dataset creator or Aura Assist's testing layers.
        """
        # Resolve path
        glob_pattern = os.path.join(dataset_dir, "android_control*")
        filenames = tf.io.gfile.glob(glob_pattern)
        
        if not filenames:
            logger.warning(f"No compressed TFRecord files matching 'android_control*' found in {dataset_dir}")
            return
        
        logger.info(f"Streaming {len(filenames)} GZIP compressed TFRecord segments...")
        
        # Create standard TFRecord dataset
        raw_dataset = tf.data.TFRecordDataset(filenames, compression_type='GZIP')
        
        for raw_record in raw_dataset:
            try:
                # Process example using eager execution
                yield self._parse_tfrecord_example(raw_record.numpy())
            except Exception as e:
                logger.error(f"Skipping corrupt record example: {e}")
                continue

# Quick test execution scaffold
if __name__ == "__main__":
    manager = UIControlDatasetManager()
    logger.info("Initializing UI Control Dataset Manager...")
    print("Dataset Manager Ready. Ready to train AURA on app navigation paths!")

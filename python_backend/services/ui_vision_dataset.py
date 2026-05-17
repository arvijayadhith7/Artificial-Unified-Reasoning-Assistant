import os
import logging
from typing import Iterator, Dict, Any, Optional

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("UIVisionDataset")

try:
    from datasets import load_dataset
except ImportError:
    logger.warning("Hugging Face 'datasets' package is not installed. To run this loader, install it using: pip install datasets")

class UIVisionDatasetManager:
    """
    Manager to load, stream, and parse ServiceNow's UI-Vision dataset from Hugging Face.
    Used to train Aura Assist's visual computer-use agents, multi-step workflow planning, and automation intelligence.
    
    Dataset Reference: "ServiceNow/ui-vision"
    """
    def __init__(self, cache_dir: str = "./memory/datasets/ui_vision"):
        self.cache_dir = cache_dir
        os.makedirs(self.cache_dir, exist_ok=True)

    def load_ui_vision_dataset(self, token: Optional[str] = None) -> Any:
        """
        Loads the ServiceNow/ui-vision dataset using Hugging Face datasets.
        Requires Hugging Face auth token if the dataset is gated or requires agreement.
        """
        logger.info("Loading ServiceNow/ui-vision dataset from Hugging Face Hub...")
        try:
            # Load dataset utilizing Hugging Face token if supplied
            dataset = load_dataset(
                "ServiceNow/ui-vision",
                cache_dir=self.cache_dir,
                token=token
            )
            logger.info("UI-Vision dataset loaded successfully!")
            return dataset
        except Exception as e:
            logger.error(f"Error loading ServiceNow/ui-vision dataset: {e}")
            logger.warning("Ensure you have run `huggingface-cli login` or provided a valid 'token' parameter.")
            return None

    def _parse_dataset_row(self, row: Dict[str, Any]) -> Dict[str, Any]:
        """
        Formats a raw row from the UI-Vision dataset into a structured schema
        compatible with Aura Assist's step-by-step action reasoning models.
        """
        # Extract screenshot image (can be PIL Image object or path)
        image = row.get("image")
        
        # Extract instruction / action plan
        instruction = row.get("instruction", "")
        if not instruction:
            instruction = row.get("task", "")
            
        # Extract target actions and screen bounding boxes
        actions = row.get("actions", [])
        bbox = row.get("bbox", [])
        
        return {
            "instruction": instruction,
            "screenshot": image,
            "actions": actions,
            "bounding_boxes": bbox,
            "metadata": {
                "source": "ServiceNow/ui-vision",
                "difficulty": row.get("difficulty", "medium"),
                "domain": row.get("domain", "web_app")
            }
        }

    def stream_split(self, split: str = "train", token: Optional[str] = None) -> Iterator[Dict[str, Any]]:
        """
        Streams structured screen-action-vision sequences from a specific dataset split (train, validation, or test).
        Can be piped directly to fine-tune local reasoning layers.
        """
        dataset = self.load_ui_vision_dataset(token=token)
        if not dataset:
            logger.warning("No active dataset loaded. Aborting stream.")
            return

        if split not in dataset:
            logger.error(f"Requested split '{split}' not found in UI-Vision dataset. Available: {list(dataset.keys())}")
            return

        logger.info(f"Streaming UI-Vision dataset records from split: '{split}'...")
        for row in dataset[split]:
            try:
                yield self._parse_dataset_row(row)
            except Exception as e:
                logger.error(f"Skipping corrupt UI-Vision row: {e}")
                continue

# Quick test execution scaffold
if __name__ == "__main__":
    manager = UIVisionDatasetManager()
    logger.info("ServiceNow UI-Vision Dataset Manager Scaffolding initialized.")
    print("UI-Vision Dataset Ready for visual computer-use agent training!")

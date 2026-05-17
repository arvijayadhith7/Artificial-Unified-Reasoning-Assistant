import os
import json
import shutil
import logging
import subprocess
from typing import Iterator, Dict, Any, List

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("ScreenAnnotationDataset")

class ScreenAnnotationDatasetManager:
    """
    Manager to clone, load, and parse Google Research's Screen Annotation Dataset.
    Used to train Aura Assist's UI element detection, icon labeling, and layout contextual reasoning.
    
    Repository Reference: https://github.com/google-research-datasets/screen_annotation
    """
    def __init__(self, workspace_dir: str = "./memory/datasets/screen_annotation"):
        self.workspace_dir = workspace_dir
        self.repo_dir = os.path.join(self.workspace_dir, "repo")
        self.annotations_dir = os.path.join(self.repo_dir, "annotations")
        os.makedirs(self.workspace_dir, exist_ok=True)

    def clone_repository(self, repo_url: str = "https://github.com/google-research-datasets/screen_annotation.git") -> str:
        """
        Clones the Google Screen Annotation git repository if not already present.
        Returns the absolute path to the cloned repository.
        """
        if os.path.exists(self.repo_dir):
            logger.info("Screen Annotation repository already exists. Pulling latest updates...")
            try:
                subprocess.run(["git", "pull"], cwd=self.repo_dir, check=True, capture_output=True)
                return self.repo_dir
            except Exception as e:
                logger.warning(f"Git pull failed, using cached files: {e}")
                return self.repo_dir

        logger.info(f"Cloning Screen Annotation dataset repository from {repo_url}...")
        try:
            subprocess.run(["git", "clone", repo_url, self.repo_dir], check=True, capture_output=True)
            logger.info("Repository cloned successfully!")
            return self.repo_dir
        except Exception as e:
            logger.error(f"Failed to clone Screen Annotation repository: {e}")
            raise RuntimeError(f"Cloning failed: {e}")

    def _parse_annotation_file(self, file_path: str) -> Dict[str, Any]:
        """
        Parses a single JSON screen annotation file.
        Extracts bounding boxes, element types (button, icon, text, checkbox), and text values.
        """
        with open(file_path, "r", encoding="utf-8") as f:
            data = json.load(f)

        screen_id = data.get("screen_id", os.path.basename(file_path).split(".")[0])
        elements = []

        # Parse annotation list (coordinates and semantics)
        for item in data.get("annotations", []):
            bounds = item.get("bounds", [0, 0, 0, 0]) # [left, top, right, bottom]
            label = item.get("label", "unknown")
            text = item.get("text", "")
            
            elements.append({
                "type": label,
                "text": text,
                "bounds": {
                    "left": bounds[0],
                    "top": bounds[1],
                    "right": bounds[2],
                    "bottom": bounds[3]
                }
            })

        return {
            "screen_id": screen_id,
            "app_name": data.get("app_name", "Unknown"),
            "elements": elements
        }

    def load_annotations(self) -> Iterator[Dict[str, Any]]:
        """
        Loads and yields parsed screen annotations from the annotations directory.
        These are formatted directly into layouts compatible with Aura Assist.
        """
        if not os.path.exists(self.annotations_dir):
            # Fallback check if directories are nested differently
            logger.warning(f"Annotations path {self.annotations_dir} does not exist. Scanning repository root...")
            search_path = self.repo_dir
        else:
            search_path = self.annotations_dir

        found_files = []
        for root, _, files in os.walk(search_path):
            for file in files:
                if file.endswith(".json"):
                    found_files.append(os.path.join(root, file))

        if not found_files:
            logger.warning(f"No JSON annotation files found in {search_path}")
            return

        logger.info(f"Loading {len(found_files)} JSON screen annotations...")
        for file_path in found_files:
            try:
                yield self._parse_annotation_file(file_path)
            except Exception as e:
                logger.error(f"Error parsing annotation file {file_path}: {e}")
                continue

    def clear_cache(self):
        """Removes the cloned dataset repo to free up local disk space."""
        if os.path.exists(self.workspace_dir):
            shutil.rmtree(self.workspace_dir)
            logger.info("Screen Annotation cache cleared.")

# Quick test execution scaffold
if __name__ == "__main__":
    manager = ScreenAnnotationDatasetManager()
    logger.info("Screen Annotation Dataset Parser Scaffolding initialized.")
    print("Screen Annotation Dataset Ready for element-level layout training!")

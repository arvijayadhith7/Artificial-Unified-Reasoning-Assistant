import os
import json
import shutil
import logging
import subprocess
from typing import Iterator, Dict, Any, List

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("LlamaTouchDataset")

class LlamaTouchDatasetManager:
    """
    Manager to clone, load, and parse the LlamaTouch dataset.
    Used to train Aura Assist's mobile workflow automation, task completion planning, and action prediction engines.
    
    Repository Reference: https://github.com/LlamaTouch/LlamaTouch
    """
    def __init__(self, workspace_dir: str = "./memory/datasets/llama_touch"):
        self.workspace_dir = workspace_dir
        self.repo_dir = os.path.join(self.workspace_dir, "repo")
        self.dataset_dir = os.path.join(self.repo_dir, "dataset") # LlamaTouch dataset location
        os.makedirs(self.workspace_dir, exist_ok=True)

    def clone_repository(self, repo_url: str = "https://github.com/LlamaTouch/LlamaTouch.git") -> str:
        """
        Clones the LlamaTouch git repository if not already present.
        Returns the absolute path to the cloned repository.
        """
        if os.path.exists(self.repo_dir):
            logger.info("LlamaTouch repository already exists. Pulling latest updates...")
            try:
                subprocess.run(["git", "pull"], cwd=self.repo_dir, check=True, capture_output=True)
                return self.repo_dir
            except Exception as e:
                logger.warning(f"Git pull failed, using cached files: {e}")
                return self.repo_dir

        logger.info(f"Cloning LlamaTouch dataset repository from {repo_url}...")
        try:
            subprocess.run(["git", "clone", repo_url, self.repo_dir], check=True, capture_output=True)
            logger.info("Repository cloned successfully!")
            return self.repo_dir
        except Exception as e:
            logger.error(f"Failed to clone LlamaTouch repository: {e}")
            raise RuntimeError(f"Cloning failed: {e}")

    def _parse_task_json(self, file_path: str) -> List[Dict[str, Any]]:
        """
        Parses a single LlamaTouch task trace file.
        Extracts tasks, sequential steps, UI elements, action categories (tap, type, scroll), coordinates, and expectations.
        """
        with open(file_path, "r", encoding="utf-8") as f:
            data = json.load(f)

        parsed_steps = []
        
        # LlamaTouch files typically contain list of multi-step task traces
        traces = data if isinstance(data, list) else [data]
        for trace in traces:
            task_desc = trace.get("task_description", trace.get("goal", ""))
            app_name = trace.get("app_name", "Android App")
            steps = []
            
            for step in trace.get("steps", trace.get("actions", [])):
                action_type = step.get("action_type", step.get("type", "tap"))
                touch_coords = step.get("coordinates", step.get("coords", [0, 0]))
                typed_text = step.get("text", "")
                
                steps.append({
                    "action": action_type,
                    "target_coordinates": {
                        "x": touch_coords[0] if len(touch_coords) > 0 else 0,
                        "y": touch_coords[1] if len(touch_coords) > 1 else 0
                    },
                    "input_text": typed_text,
                    "target_element": step.get("element_label", "")
                })
                
            parsed_steps.append({
                "task_description": task_desc,
                "app": app_name,
                "steps": steps,
                "metadata": {
                    "package": trace.get("package_name", ""),
                    "category": trace.get("category", "utility")
                }
            })
            
        return parsed_steps

    def load_traces(self) -> Iterator[Dict[str, Any]]:
        """
        Loads and yields parsed task-action sequences from the dataset folder.
        Formatted directly into workflow sequences compatible with Aura Assist.
        """
        search_path = self.dataset_dir if os.path.exists(self.dataset_dir) else self.repo_dir
        
        found_files = []
        for root, _, files in os.walk(search_path):
            for file in files:
                if file.endswith(".json") and not file.startswith("."):
                    found_files.append(os.path.join(root, file))

        if not found_files:
            logger.warning(f"No task trace files (.json) found in {search_path}")
            return

        logger.info(f"Loading {len(found_files)} LlamaTouch task trace files...")
        for file_path in found_files:
            try:
                parsed_list = self._parse_task_json(file_path)
                for task in parsed_list:
                    yield task
            except Exception as e:
                logger.error(f"Error parsing task trace file {file_path}: {e}")
                continue

    def clear_cache(self):
        """Removes the cloned dataset repo to free up local disk space."""
        if os.path.exists(self.workspace_dir):
            shutil.rmtree(self.workspace_dir)
            logger.info("LlamaTouch cache cleared.")

# Quick test execution scaffold
if __name__ == "__main__":
    manager = LlamaTouchDatasetManager()
    logger.info("LlamaTouch Dataset Manager Scaffolding initialized.")
    print("LlamaTouch Dataset Ready for mobile workflow action prediction training!")

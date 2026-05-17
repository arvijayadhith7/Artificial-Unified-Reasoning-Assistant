import os
import logging
from typing import Iterator, Dict, Any, Optional

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("WaveUIDataset")

try:
    import fiftyone as fo
    from fiftyone.utils.huggingface import load_from_hub
except ImportError:
    logger.warning("FiftyOne or HuggingFace module is not installed. To run this dataset loader, install them using: pip install fiftyone")

class WaveUIDatasetManager:
    """
    Manager to load, stream, and parse Voxel51's WaveUI-25K dataset.
    Used to train Aura Assist's UI component visual understanding, layout detection, and visual agent reasoning.
    
    Dataset Reference: "Voxel51/WaveUI-25k"
    """
    def __init__(self, dataset_name: str = "WaveUI-25k"):
        self.dataset_name = dataset_name

    def load_waveui_dataset(self, max_samples: Optional[int] = None) -> Any:
        """
        Loads the Voxel51/WaveUI-25k dataset directly from the Hugging Face hub using FiftyOne.
        Optionally limits the sample size using max_samples.
        """
        logger.info(f"Loading Voxel51/WaveUI-25k dataset (Max Samples: {max_samples or 'All'})...")
        try:
            dataset = load_from_hub(
                "Voxel51/WaveUI-25k",
                max_samples=max_samples
            )
            logger.info("WaveUI-25k dataset loaded successfully into FiftyOne!")
            return dataset
        except Exception as e:
            logger.error(f"Error loading Voxel51/WaveUI-25k dataset: {e}")
            return None

    def launch_explorer_session(self, max_samples: Optional[int] = 100) -> Any:
        """
        Launches the interactive FiftyOne desktop app session to explore UI bounding boxes visually.
        """
        dataset = self.load_waveui_dataset(max_samples=max_samples)
        if dataset:
            logger.info("Launching FiftyOne Interactive Dashboard App...")
            session = fo.launch_app(dataset)
            return session
        return None

    def _parse_sample_features(self, sample: Any) -> Dict[str, Any]:
        """
        Parses a single FiftyOne sample into standard JSON format with coordinates, bounding boxes,
        and labels suitable for Aura Assist element detection pipelines.
        """
        filepath = sample.filepath
        tags = sample.tags
        elements = []

        # Typically, FiftyOne object detection datasets store bounding boxes in standard fields like 'ground_truth' or 'detections'
        detections_field = sample.get_field("ground_truth") or sample.get_field("detections")
        
        if detections_field and hasattr(detections_field, "detections"):
            for detection in detections_field.detections:
                label = detection.label
                bbox = detection.bounding_box # FiftyOne format: [top-left-x, top-left-y, width, height] (normalized 0-1)
                
                elements.append({
                    "label": label,
                    "confidence": getattr(detection, "confidence", 1.0),
                    "box_normalized": {
                        "x": bbox[0],
                        "y": bbox[1],
                        "width": bbox[2],
                        "height": bbox[3]
                    }
                })

        return {
            "image_path": filepath,
            "tags": tags,
            "elements": elements,
            "metadata": {
                "source": "Voxel51/WaveUI-25k",
                "width": sample.metadata.width if sample.metadata else None,
                "height": sample.metadata.height if sample.metadata else None
            }
        }

    def stream_samples(self, max_samples: Optional[int] = None) -> Iterator[Dict[str, Any]]:
        """
        Streams structured FiftyOne samples with layout component detections sequentially.
        """
        dataset = self.load_waveui_dataset(max_samples=max_samples)
        if not dataset:
            logger.warning("No active dataset loaded. Aborting stream.")
            return

        logger.info("Streaming WaveUI-25k samples...")
        for sample in dataset:
            try:
                yield self._parse_sample_features(sample)
            except Exception as e:
                logger.error(f"Skipping corrupt WaveUI-25k sample: {e}")
                continue

# Quick test execution scaffold
if __name__ == "__main__":
    manager = WaveUIDatasetManager()
    logger.info("WaveUI-25k Dataset Manager Scaffolding initialized.")
    print("WaveUI-25k Dataset Ready for visual component training!")

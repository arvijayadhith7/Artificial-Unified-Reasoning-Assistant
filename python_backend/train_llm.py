import os
import sys
import argparse

# Force UTF-8 mode for Windows compatibility
os.environ['PYTHONUTF8'] = '1'
# Also set it for the current process
if sys.platform == 'win32':
    import io
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')

import torch
from datasets import load_dataset
from transformers import AutoModelForCausalLM, AutoTokenizer, BitsAndBytesConfig, TrainingArguments
from peft import LoraConfig, get_peft_model, prepare_model_for_kbit_training
from trl import SFTTrainer

# 1. Command Line Arguments
parser = argparse.ArgumentParser(description="Fine-tune Qwen2.5 on Prompt Engineering datasets")
parser.add_argument("--dataset", type=str, default="awesome-chatgpt-prompts",
                    choices=["awesome-chatgpt-prompts", "system-prompts", "code-alpaca", "open-orca"],
                    help="Prompt engineering dataset to use for fine-tuning")
parser.add_argument("--steps", type=int, default=10, help="Number of training steps")
args = parser.parse_args()

# 2. Configuration
model_path = r'D:\ANTIGRAVITY\llm APP\models\custom_model'
output_dir = r'D:\ANTIGRAVITY\llm APP\models\trained_adapters'

# Check training device (i3 CPU fallback support)
device = "cuda" if torch.cuda.is_available() else "cpu"
print(f"🖥️ Using training device: {device.upper()}")

# 3. Load Selected Dataset
if args.dataset == "awesome-chatgpt-prompts":
    dataset_name = "fka/awesome-chatgpt-prompts"
    print(f"🚀 Loading awesome-chatgpt-prompts from: {dataset_name}...")
    dataset = load_dataset(dataset_name, split="train")
    
    def formatting_func(example):
        act = example.get("act", "Assistant")
        prompt = example.get("prompt", "")
        return f"<|im_start|>system\nYou are a professional prompt engineer.\n<|im_end|>\n<|im_start|>user\nWrite a system prompt template for acting as a {act}.\n<|im_end|>\n<|im_start|>assistant\n{prompt}\n<|im_end|>"

elif args.dataset == "system-prompts":
    dataset_name = "danielrosehill/system_prompts"
    print(f"🚀 Loading system_prompts from: {dataset_name}...")
    dataset = load_dataset(dataset_name, split="train")
    
    def formatting_func(example):
        prompt = example.get("prompt") or example.get("system_prompt") or example.get("text") or ""
        desc = example.get("description") or example.get("title") or "specialized agent task"
        return f"<|im_start|>system\nYou are a professional prompt engineer.\n<|im_end|>\n<|im_start|>user\nWrite a system prompt for a {desc}.\n<|im_end|>\n<|im_start|>assistant\n{prompt}\n<|im_end|>"

elif args.dataset == "code-alpaca":
    dataset_name = "sahil2801/CodeAlpaca-20k"
    print(f"🚀 Loading CodeAlpaca from: {dataset_name}...")
    dataset = load_dataset(dataset_name, split="train")
    
    def formatting_func(example):
        inst = example.get("instruction", "")
        inp = example.get("input", "")
        out = example.get("output", "")
        user_query = f"{inst}\n{inp}".strip()
        return f"<|im_start|>system\nYou are an expert programmer. Follow the instructions and write correct code.\n<|im_end|>\n<|im_start|>user\n{user_query}\n<|im_end|>\n<|im_start|>assistant\n{out}\n<|im_end|>"

else: # open-orca
    dataset_name = "Open-Orca/OpenOrca"
    print(f"🚀 Loading OpenOrca from: {dataset_name}...")
    dataset = load_dataset(dataset_name, split="train", streaming=True)
    dataset = dataset.take(5000)
    
    def formatting_func(example):
        system = example.get('system_prompt', "You are a helpful assistant.")
        question = example.get('question', "")
        response = example.get('response', "")
        return f"<|im_start|>system\n{system}\n<|im_end|>\n<|im_start|>user\n{question}\n<|im_end|>\n<|im_start|>assistant\n{response}\n<|im_end|>"

# 4. Model Loading with Quantization (only supported on CUDA GPU)
if device == "cuda":
    quant_config = BitsAndBytesConfig(
        load_in_4bit=True,
        bnb_4bit_quant_type="nf4",
        bnb_4bit_compute_dtype=torch.float16,
        bnb_4bit_use_double_quant=True,
    )
else:
    quant_config = None
    print("⚠️ CUDA GPU not found. Loading model in full precision on CPU (this will be slow).")

print(f"📂 Loading base model from: {model_path}...")
tokenizer = AutoTokenizer.from_pretrained(model_path, local_files_only=True)
tokenizer.pad_token = tokenizer.eos_token

model = AutoModelForCausalLM.from_pretrained(
    model_path,
    quantization_config=quant_config,
    device_map="auto" if device == "cuda" else None,
    local_files_only=True,
    trust_remote_code=False
)

# 5. Prepare for PEFT (LoRA)
if device == "cuda":
    model = prepare_model_for_kbit_training(model)

lora_config = LoraConfig(
    r=16,
    lora_alpha=32,
    target_modules=["q_proj", "v_proj"],
    lora_dropout=0.05,
    bias="none",
    task_type="CAUSAL_LM"
)
model = get_peft_model(model, lora_config)

# 6. Training Arguments
training_args = TrainingArguments(
    output_dir=output_dir,
    per_device_train_batch_size=2 if device == "cuda" else 1,
    gradient_accumulation_steps=4,
    learning_rate=2e-4,
    logging_steps=1,
    max_steps=args.steps,
    fp16=(device == "cuda"),
    use_cpu=(device == "cpu"),
    save_strategy="steps",
    save_steps=50,
    optim="paged_adamw_32bit" if device == "cuda" else "adamw_torch"
)

# 7. Initialize SFTTrainer
trainer = SFTTrainer(
    model=model,
    train_dataset=dataset,
    args=training_args,
    processing_class=tokenizer,
    formatting_func=formatting_func,
)

print("🧠 Starting Fine-Tuning (LoRA)...")
trainer.train()

# 8. Save the trained adapters
trainer.save_model(output_dir)
print(f"✅ Training complete! Adapters saved to: {output_dir}")

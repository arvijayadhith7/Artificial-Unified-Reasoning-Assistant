import os
import sys

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

# 1. Configuration
model_path = r'D:\ANTIGRAVITY\llm APP\models\custom_model'
output_dir = r'D:\ANTIGRAVITY\llm APP\models\trained_adapters'
dataset_name = "Open-Orca/OpenOrca"

print(f"🚀 Connecting to OpenOrca Stream: {dataset_name}...")
# OpenOrca is large. We use streaming=True to pull data on-demand.
dataset = load_dataset(dataset_name, split="train", streaming=True)
dataset = dataset.take(5000) # Take a manageable subset for fine-tuning

# 2. Model Loading with 4-bit Quantization (QLoRA)
quant_config = BitsAndBytesConfig(
    load_in_4bit=True,
    bnb_4bit_quant_type="nf4",
    bnb_4bit_compute_dtype=torch.float16,
    bnb_4bit_use_double_quant=True,
)

print(f"📂 Loading base model from: {model_path}...")
tokenizer = AutoTokenizer.from_pretrained(model_path, local_files_only=True)
tokenizer.pad_token = tokenizer.eos_token

model = AutoModelForCausalLM.from_pretrained(
    model_path,
    quantization_config=quant_config,
    device_map="auto",
    local_files_only=True,
    trust_remote_code=False
)

# 3. Prepare for PEFT (LoRA)
model = prepare_model_for_kbit_training(model)
lora_config = LoraConfig(
    r=16,
    lora_alpha=32,
    target_modules=["q_proj", "v_proj"], # Common for Llama/Phi
    lora_dropout=0.05,
    bias="none",
    task_type="CAUSAL_LM"
)
model = get_peft_model(model, lora_config)

# 4. Training Arguments
training_args = TrainingArguments(
    output_dir=output_dir,
    per_device_train_batch_size=4,
    gradient_accumulation_steps=4,
    learning_rate=2e-4,
    logging_steps=10,
    max_steps=100, # Short run for demonstration
    fp16=True,
    save_strategy="steps",
    save_steps=50,
    optim="paged_adamw_32bit"
)

# 5. Initialize SFTTrainer
def formatting_func(example):
    # OpenOrca structure: system_prompt, question, response
    system = example.get('system_prompt', "You are a helpful assistant.")
    question = example.get('question', "")
    response = example.get('response', "")
    
    # Format into a chat-like structure for the causal model
    text = f"### System: {system}\n### Question: {question}\n### Response: {response}"
    return text

trainer = SFTTrainer(
    model=model,
    train_dataset=dataset,
    args=training_args,
    processing_class=tokenizer,
    formatting_func=formatting_func,
)

print("🧠 Starting Fine-Tuning (QLoRA)...")
trainer.train()

# 6. Save the trained adapters
trainer.save_model(output_dir)
print(f"✅ Training complete! Adapters saved to: {output_dir}")

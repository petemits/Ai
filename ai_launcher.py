# ai_launcher.py - Fixed version
import os
import sys
import time
from llama_cpp import Llama
from duckduckgo_search import DDGS

print("="*60)
print("AI ASSISTANT - READY")
print("="*60)

# Use existing model
model_path = "models/qwen_0.5b.gguf"
if not os.path.exists(model_path):
    import glob
    gguf_files = glob.glob("models/*.gguf")
    if gguf_files:
        model_path = gguf_files[0]
        print(f"Using: {model_path}")
    else:
        print("No model found in 'models' folder")
        sys.exit(1)

print(f"Loading: {os.path.basename(model_path)}")

# Load model
llm = Llama(
    model_path=model_path,
    n_ctx=512,
    n_threads=2,
    n_gpu_layers=0,
    verbose=False
)

print("Model loaded!")

# Search function
def quick_search(query):
    try:
        with DDGS() as ddgs:
            for r in ddgs.text(query, max_results=1):
                return r.get('body', '')[:100] + '...'
    except:
        return None

print("\nCHAT MODE - Type 'exit' to quit")
print("="*60)

while True:
    try:
        user = input("\nYou: ").strip()
        if user.lower() in ['exit', 'quit', 'bye']:
            print("\nGoodbye!")
            break
        if not user:
            continue
        
        # Check if needs search
        needs_search = any(word in user.lower() for word in ['weather', 'news', 'what', 'who', 'how', 'search'])
        
        search_context = ""
        if needs_search:
            print("Checking web...")
            search_result = quick_search(user)
            if search_result:
                search_context = f"\n[Web info: {search_result}]"
        
        # Generate response
        print("Thinking...")
        start = time.time()
        
        prompt = f"User: {user}{search_context}\nAssistant:"
        response = llm(prompt, max_tokens=200, temperature=0.7, stop=["\n"])
        
        if 'choices' in response and response['choices']:
            answer = response['choices'][0]['text'].strip()
            elapsed = time.time() - start
            # FIXED f-string formatting
            print(f"\nAssistant ({elapsed:.1f}s): {answer}")
        else:
            print("No response")
            
    except KeyboardInterrupt:
        print("\n\nGoodbye!")
        break
    except Exception as e:
        print(f"Error: {e}")

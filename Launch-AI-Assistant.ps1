# Fix-AI-Setup.ps1
# Fixes incompatible model issue

Write-Host "Fixing AI setup..." -ForegroundColor Cyan

# Check current llama-cpp-python version
$version = pip show llama-cpp-python 2>&1 | Select-String -Pattern "Version"
Write-Host "Current version: $version" -ForegroundColor Yellow

# Option A: Download compatible model (easiest)
Write-Host "`nOption A: Downloading compatible model..." -ForegroundColor Green

# Remove incompatible model
if (Test-Path "models\qwen2.5-0.5b-instruct-q4_k_m.gguf") {
    Remove-Item "models\qwen2.5-0.5b-instruct-q4_k_m.gguf" -Force
}

# Download Qwen2 (not Qwen2.5) - compatible with your version
$modelUrl = "https://huggingface.co/TheBloke/Qwen2-0.5B-Instruct-GGUF/resolve/main/qwen2-0_5b-instruct-q4_k_m.gguf"

Write-Host "Downloading compatible Qwen2 model..." -ForegroundColor Yellow
try {
    Invoke-WebRequest -Uri $modelUrl -OutFile "models\qwen_0.5b.gguf"
    
    if (Test-Path "models\qwen_0.5b.gguf") {
        $size = [Math]::Round((Get-Item "models\qwen_0.5b.gguf").Length / 1MB, 1)
        Write-Host "Downloaded: $size MB" -ForegroundColor Green
        
        # Test the new model
        Write-Host "`nTesting new model..." -ForegroundColor Cyan
        python -c "from llama_cpp import Llama; llm=Llama('models/qwen_0.5b.gguf', n_ctx=256, n_threads=2, n_gpu_layers=0); print('Model loads successfully!')"
    }
} catch {
    Write-Host "Download failed: $_" -ForegroundColor Red
}

# Create simple test script
Write-Host "`nCreating simple launcher..." -ForegroundColor Yellow

$simpleCode = @'
import os, time
from llama_cpp import Llama

print("Testing AI setup...")

# Try to find any working model
model_files = []
for f in os.listdir("models"):
    if f.endswith(".gguf"):
        model_files.append(f"models/{f}")

if not model_files:
    print("No GGUF models found")
    exit(1)

# Try each model
for model_path in model_files:
    try:
        print(f"Trying: {model_path}")
        llm = Llama(
            model_path=model_path,
            n_ctx=256,
            n_threads=2,
            n_gpu_layers=0,
            verbose=False
        )
        
        # Quick test
        test = llm("Hello", max_tokens=10)
        if 'choices' in test and test['choices']:
            print(f"SUCCESS with: {os.path.basename(model_path)}")
            print(f"Response: {test['choices'][0]['text']}")
            
            # Save working model path
            with open("working_model.txt", "w") as f:
                f.write(model_path)
            break
            
    except Exception as e:
        print(f"Failed: {e}")
'@

$simpleCode | Out-File "test_models.py" -Encoding UTF8
python test_models.py
Remove-Item "test_models.py" -ErrorAction SilentlyContinue

# Create final launcher
Write-Host "`nCreating final launcher..." -ForegroundColor Green

$finalLauncher = @'
import os, time
from llama_cpp import Llama
from duckduckgo_search import DDGS

print("🤖 AI Assistant")
print("="*50)

# Find working model
model_path = "models/qwen_0.5b.gguf"
if not os.path.exists(model_path):
    # Look for any GGUF
    import glob
    models = glob.glob("models/*.gguf")
    if models:
        model_path = models[0]
    else:
        print("No model found")
        exit(1)

print(f"Using: {os.path.basename(model_path)}")

# Load model
try:
    llm = Llama(
        model_path=model_path,
        n_ctx=512,
        n_threads=2,
        n_gpu_layers=0,
        verbose=False
    )
    print("Model loaded!")
except Exception as e:
    print(f"Load error: {e}")
    exit(1)

# Simple search
def search(query):
    try:
        with DDGS() as ddgs:
            for r in ddgs.text(query, max_results=1):
                return r.get('body', '')[:80]
    except:
        return None

print("\nChat ready! Type 'exit' to quit.")
print("="*50)

while True:
    try:
        user = input("\nYou: ").strip()
        if user.lower() == 'exit':
            print("Goodbye!")
            break
            
        print("Thinking...")
        start = time.time()
        
        # Check if search needed
        if any(w in user.lower() for w in ['weather', 'news', 'what', 'who', 'how']):
            result = search(user)
            if result:
                prompt = f"User: {user} (Info: {result})\nAssistant:"
            else:
                prompt = f"User: {user}\nAssistant:"
        else:
            prompt = f"User: {user}\nAssistant:"
        
        response = llm(prompt, max_tokens=150, temperature=0.7, stop=["\n"])
        
        if response and 'choices' in response:
            answer = response['choices'][0]['text'].strip()
            elapsed = time.time() - start
            print(f"Assistant ({elapsed:.1f}s): {answer}")
            
    except KeyboardInterrupt:
        print("\nGoodbye!")
        break
    except Exception as e:
        print(f"Error: {e}")
'@

$finalLauncher | Out-File "ai_chat.py" -Encoding UTF8

Write-Host "`n🎯 READY! Start with:" -ForegroundColor Cyan
Write-Host "python ai_chat.py" -ForegroundColor Green
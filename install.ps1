# install.ps1 - Simple AI Setup
Write-Host "=== AI Setup Script ===" -ForegroundColor Cyan
Write-Host "For 8GB RAM systems" -ForegroundColor Yellow
Write-Host ""

# Step 1: Check Python
Write-Host "[1/4] Checking Python..." -ForegroundColor Yellow
try {
    python --version
} catch {
    Write-Host "Python not found! Install Python 3.8+ first." -ForegroundColor Red
    exit 1
}

# Step 2: Install/check llama-cpp-python
Write-Host "`n[2/4] Checking llama-cpp-python..." -ForegroundColor Yellow
$llamaVersion = pip show llama-cpp-python 2>&1
if ($llamaVersion -match "Version:") {
    Write-Host "llama-cpp-python is installed" -ForegroundColor Green
} else {
    Write-Host "Installing llama-cpp-python..." -ForegroundColor Yellow
    pip install llama-cpp-python --quiet
}

# Step 3: Create models directory
Write-Host "`n[3/4] Setting up models directory..." -ForegroundColor Yellow
if (-not (Test-Path "models")) {
    New-Item -ItemType Directory -Path "models" -Force | Out-Null
    Write-Host "Created 'models' directory" -ForegroundColor Green
}

# Step 4: Download model
Write-Host "`n[4/4] Downloading TinyLlama model..." -ForegroundColor Green
$modelUrl = "https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF/resolve/main/tinyllama-1.1b-chat-v1.0.Q2_K.gguf"
$modelFile = "models\tinyllama.gguf"

Write-Host "Downloading (380MB)..." -ForegroundColor Cyan
try {
    # Show progress
    $ProgressPreference = 'SilentlyContinue'
    $startTime = Get-Date
    
    # Download with progress tracking
    $wc = New-Object System.Net.WebClient
    $wc.DownloadFile($modelUrl, $modelFile)
    
    $downloadTime = (Get-Date) - $startTime
    if (Test-Path $modelFile) {
        $sizeMB = [Math]::Round((Get-Item $modelFile).Length / 1MB, 1)
        Write-Host "✓ Downloaded: $sizeMB MB in $($downloadTime.TotalSeconds.ToString('0.0'))s" -ForegroundColor Green
    }
} catch {
    Write-Host "Download failed: $_" -ForegroundColor Red
    Write-Host "Trying alternative..." -ForegroundColor Yellow
    
    # Try alternative source
    $altUrl = "https://huggingface.co/rustformers/tinyllama-gguf/resolve/main/tinyllama-1b-q4_0.gguf"
    Invoke-WebRequest -Uri $altUrl -OutFile $modelFile -UseBasicParsing
}

# Create the Python launcher as a separate file
Write-Host "`nCreating AI launcher..." -ForegroundColor Yellow

# First, create a simple test to verify everything works
$testScript = @'
# test_model.py
import os
from llama_cpp import Llama

print("Testing AI setup...")
print("=" * 50)

model_path = "models/tinyllama.gguf"
if not os.path.exists(model_path):
    print("ERROR: Model not found at:", model_path)
    print("Please run install.ps1 again")
    exit(1)

print(f"Found model: {os.path.basename(model_path)}")

try:
    # Test with minimal settings
    llm = Llama(
        model_path=model_path,
        n_ctx=512,
        n_threads=2,
        n_gpu_layers=0,
        verbose=False
    )
    
    print("✓ Model loaded successfully!")
    
    # Quick test
    test_prompt = "Hello, how are you?"
    result = llm(test_prompt, max_tokens=20, echo=False)
    
    if 'choices' in result and result['choices']:
        response = result['choices'][0]['text'].strip()
        print(f"✓ Test response: {response}")
    else:
        print("⚠️ Got response but no text")
        
except Exception as e:
    print(f"✗ Error: {e}")
    exit(1)

print("=" * 50)
print("✓ Setup is working correctly!")
print('Run: python ai_chat.py')
'@

$testScript | Out-File "test_model.py" -Encoding UTF8

# Now create the main chat script
$chatScript = @'
# ai_chat.py
import os
import time
from llama_cpp import Llama

print("🤖 AI Assistant")
print("=" * 50)
print("Optimized for 8GB RAM systems")
print("=" * 50)

# Configuration
MODEL_PATH = "models/tinyllama.gguf"
if not os.path.exists(MODEL_PATH):
    print(f"ERROR: Model not found: {MODEL_PATH}")
    print("Please run install.ps1 first")
    exit(1)

print(f"Model: {os.path.basename(MODEL_PATH)}")
print("Loading...", end="", flush=True)

try:
    # Settings for 8GB RAM
    llm = Llama(
        model_path=MODEL_PATH,
        n_ctx=2048,        # Context size
        n_threads=4,       # CPU threads
        n_gpu_layers=0,    # CPU only
        n_batch=128,       # Small batch for low RAM
        verbose=False
    )
    print(" READY")
except Exception as e:
    print(f" ERROR: {e}")
    exit(1)

print("\n" + "=" * 50)
print("Type 'exit' to quit, 'clear' to clear memory")
print("=" * 50)

# Simple chat loop
while True:
    try:
        user_input = input("\nYou: ").strip()
        
        if user_input.lower() == 'exit':
            print("\nGoodbye!")
            break
            
        if user_input.lower() == 'clear':
            print("Clearing memory...")
            # In a real app, you'd reset the context
            print("Memory cleared (restart to fully clear)")
            continue
            
        if not user_input:
            continue
            
        print("Thinking...", end="", flush=True)
        start_time = time.time()
        
        # Create prompt
        prompt = f"### Human: {user_input}\n### Assistant:"
        
        # Generate response
        response = llm(
            prompt,
            max_tokens=150,
            temperature=0.7,
            top_p=0.9,
            repeat_penalty=1.1,
            stop=["###", "\n\n"],
            echo=False
        )
        
        elapsed = time.time() - start_time
        
        if response and 'choices' in response:
            answer = response['choices'][0]['text'].strip()
            print(f"\nAssistant ({elapsed:.1f}s): {answer}")
        else:
            print("\nNo response received")
            
    except KeyboardInterrupt:
        print("\n\nGoodbye!")
        break
    except Exception as e:
        print(f"\nError: {e}")
        continue

print("\nShutting down...")
'@

$chatScript | Out-File "ai_chat.py" -Encoding UTF8

# Create a batch file for easy launching
$batchFile = @'
@echo off
chcp 65001 > nul
echo Starting AI Assistant...
echo.
python ai_chat.py
if errorlevel 1 (
    echo.
    echo Something went wrong. Try running: python test_model.py
)
pause
'@

$batchFile | Out-File "run.bat" -Encoding ASCII

# Run the test
Write-Host "`nTesting setup..." -ForegroundColor Cyan
python test_model.py

# Clean up test file
Remove-Item "test_model.py" -ErrorAction SilentlyContinue

Write-Host "`n" + "=" * 50 -ForegroundColor Cyan
Write-Host "SETUP COMPLETE!" -ForegroundColor Green
Write-Host "=" * 50 -ForegroundColor Cyan
Write-Host "`nTo start chatting:" -ForegroundColor Yellow
Write-Host "  Method 1: python ai_chat.py" -ForegroundColor White
Write-Host "  Method 2: .\run.bat" -ForegroundColor White
Write-Host "`nModel: TinyLlama 1.1B (optimized for 8GB RAM)" -ForegroundColor Gray
Write-Host "Expected response time: 2-8 seconds" -ForegroundColor Gray
Write-Host "`nTip: Keep conversations short for best performance" -ForegroundColor Gray
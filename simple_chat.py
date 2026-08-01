# simple_chat.py - A plug-and-play chat program for your Qwen2.5 model
import os
import sys
import time
import traceback

def main():
    print("=" * 50)
    print("🤖 Simple InfoChat (Qwen2.5)")
    print("=" * 50)

    # --- CONFIGURATION: Point to your model file ---
    # The program first checks for your exact file name.
    # If it's not found, it will look for any .gguf file.
    POSSIBLE_PATHS = [
        "qwen2.5-0.5b-instruct-q4_k_m.gguf",  # Your original file
        "models/qwen2.5-0.5b-instruct-q4_k_m.gguf",
        "models/qwen2.5.gguf"
    ]

    model_path = None
    for path in POSSIBLE_PATHS:
        if os.path.exists(path):
            model_path = path
            print(f"✅ Found model: {model_path}")
            break

    # If no specific file is found, search for any GGUF file
    if not model_path:
        print("⚠️  Specific model not found. Searching for any .gguf file...")
        for root, dirs, files in os.walk("."):
            for file in files:
                if file.endswith(".gguf"):
                    model_path = os.path.join(root, file)
                    print(f"✅ Using: {model_path}")
                    break
            if model_path:
                break

    if not model_path:
        print("\n❌ ERROR: No GGUF model file found.")
        print("Please make sure 'qwen2.5-0.5b-instruct-q4_k_m.gguf' is in this folder.")
        print("The program will now create a 'models' folder and wait for you to place the file there.")
        os.makedirs("models", exist_ok=True)
        input("\nPress Enter after you have copied your model file into the 'models' folder...")
        # Check again after user input
        for file in os.listdir("models"):
            if file.endswith(".gguf"):
                model_path = os.path.join("models", file)
                break
        if not model_path:
            print("Still no model found. Exiting.")
            sys.exit(1)

    # --- STEP 1: Check and Install Required Package ---
    print("\n[1/3] Checking for 'llama-cpp-python' package...")
    try:
        from llama_cpp import Llama
        print("✅ Package already installed.")
    except ImportError:
        print("❌ Package not found. Installing...")
        try:
            import subprocess
            import sys
            # Use pip to install the package
            subprocess.check_call([sys.executable, "-m", "pip", "install", "llama-cpp-python"])
            print("✅ Installation successful. Restarting script...")
            # Re-run the script to use the newly installed package
            os.execv(sys.executable, [sys.executable] + sys.argv)
        except Exception as e:
            print(f"⚠️  Installation failed: {e}")
            print("\nPlease install it manually by running:")
            print("   pip install llama-cpp-python")
            input("\nPress Enter after manual installation, or Ctrl+C to exit...")
            # Try importing again after manual install
            try:
                from llama_cpp import Llama
            except ImportError:
                print("Package still not available. Exiting.")
                sys.exit(1)

    # --- STEP 2: Load the Model ---
    print("\n[2/3] Loading AI model... (This may take a moment)")
    try:
        # These settings are optimized for 8GB RAM systems
        llm = Llama(
            model_path=model_path,
            n_ctx=1024,      # Context size (keep smaller to save RAM)
            n_threads=2,     # CPU threads to use
            n_gpu_layers=0,  # CPU only - set to 1 or more if you have a GPU
            verbose=False    # Turn off detailed logs
        )
        print("✅ Model loaded successfully!")
    except Exception as e:
        print(f"❌ Failed to load model: {e}")
        print("\nTroubleshooting tips:")
        print("1. Your 'llama-cpp-python' might be too old for Qwen2.5.")
        print("   Update it: pip install --upgrade llama-cpp-python")
        print("2. The model file might be corrupted.")
        print("3. Try a simpler model like TinyLlama if issues persist.")
        sys.exit(1)

    # --- STEP 3: Start the Chat ---
    print("\n[3/3] Chat ready!")
    print("\n" + "=" * 50)
    print("💬 Ask anything. Type '/exit' to quit.")
    print("💡 Example: 'Explain quantum computing' or 'Who invented the telephone?'")
    print("=" * 50)

    while True:
        try:
            # Get user input
            user_input = input("\nYou: ").strip()

            # Check for exit command
            if user_input.lower() in ['/exit', '/quit', 'exit', 'quit']:
                print("\n👋 Goodbye!")
                break

            # Skip empty input
            if not user_input:
                continue

            # Show "thinking" indicator
            print("🤔 Thinking...", end="", flush=True)
            start_time = time.time()

            # Create a simple prompt. You can adjust this format.
            prompt = f"### Instruction: Provide a clear, informative answer to the following.\n### Question: {user_input}\n### Answer:"

            # Generate response from the model
            response = llm(
                prompt,
                max_tokens=256,       # Length of response
                temperature=0.7,      # Creativity (0 = precise, 1 = creative)
                stop=["###", "\n\n"], # Stop sequences
                echo=False
            )

            elapsed_time = time.time() - start_time

            # Display the response
            if 'choices' in response and response['choices']:
                answer = response['choices'][0]['text'].strip()
                print(f"\n🤖 Assistant ({elapsed_time:.1f}s): {answer}")
            else:
                print("\n⚠️  No clear response generated.")

        except KeyboardInterrupt:
            print("\n\n🛑 Interrupted. Type '/exit' to quit.")
        except Exception as e:
            print(f"\n⚠️  An error occurred: {e}")

if __name__ == "__main__":
    main()
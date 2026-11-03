repos=(
    "huggingface_hub"
    "datasets"
    "transformers"
    "diffusers"
    "accelerate"
    "peft"
    "optimum"
)

for repo in "${repos[@]}"; do
    pip install -e "./$repo"
done
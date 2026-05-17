#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRATCH="$REPO_ROOT/scratch"
VENV="$SCRATCH/.venv"

mkdir -p "$SCRATCH"
cd "$SCRATCH"

# System dependencies (requires sudo)
# sudo apt-get update
# sudo apt install -y dvipng

# Create and activate venv
python3 -m venv "$VENV"
source "$VENV/bin/activate"

# Install plastex (gerby branch)
if [ ! -d plastex ]; then
  git clone https://github.com/pbelmans/plastex.git
fi
cd plastex
git checkout gerby
pip install .
cd "$SCRATCH"

# Clone stacks-project
if [ ! -d stacks-project ]; then
  git clone https://github.com/stacks/stacks-project.git
fi

# Install patched pybtex at specific commit
if [ ! -d pybtex ]; then
  git clone https://github.com/live-clones/pybtex.git
  wget -O no-protected-in-math-mode.patch \
    'https://bitbucket.org/pybtex-devs/pybtex/issues/attachments/110/pybtex-devs/pybtex/1514284299.07/110/no-protected-in-math-mode.patch'
  cd pybtex
  git checkout e5bc10bc55442704705a97de83424df04deb63a5
  git apply ../no-protected-in-math-mode.patch
  pip install .
  cd "$SCRATCH"
fi

# Set up static assets inside the local gerby-website checkout
STATIC="$REPO_ROOT/gerby/static"
if [ ! -d "$STATIC/XyJax" ]; then
  git clone https://github.com/sonoisa/XyJax.git "$STATIC/XyJax"
  sed -i -e 's@\[MathJax\]@/static/XyJax@' "$STATIC/XyJax/extensions/TeX/xypic.js"
fi
if [ ! -d "$STATIC/jquery-bonsai" ]; then
  git clone https://github.com/aexmachina/jquery-bonsai "$STATIC/jquery-bonsai"
  cp "$STATIC/jquery-bonsai/jquery.bonsai.css" "$STATIC/css/"
fi

# Install gerby-website (local checkout)
pip install "$REPO_ROOT"

# Build stacks-project
mkdir -p "$SCRATCH/WEB"
cd "$SCRATCH/stacks-project"
echo yes | python2 scripts/add_tags.py
make web
cp -r "$SCRATCH/stacks-project/WEB/." "$SCRATCH/WEB/"

# Run plastex
cd "$SCRATCH/WEB"
plastex --renderer=Gerby book.tex

# Run gerby update
# TOOLS="$REPO_ROOT/gerby/tools"
# ln -sf "$SCRATCH/WEB/book"      "$TOOLS/stacks"
# ln -sf "$SCRATCH/WEB/book.paux" "$TOOLS/stacks.paux"
# ln -sf "$SCRATCH/WEB/tags"      "$TOOLS/stacks.tags"

# cd "$TOOLS"
# python update.py --noSearch --noTagStats

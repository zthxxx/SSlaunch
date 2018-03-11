#!/usr/bin/env bash
# Integrity Verifier

PROJECT_NAME="SSlaunch"
HASH_FILE="sslaunch.md5"
SOURCE_URL="https://github.com/zthxxx/SSlaunch/raw/master/"

download(){
  file="$1"
  curl -sL "${SOURCE_URL}${file}" -o "$file"
}

exist_check(){
  file="$1"
  if [ ! -r "$file" ]; then
    download "$file"
  fi
}

integrity_verifier(){
  exist_check "$HASH_FILE"
  if ! md5sum --quiet -c "$HASH_FILE"; then 
    exit 1
  fi
}

download_files(){
  exist_check "$HASH_FILE"
  files=(`awk '{print $2}' "$HASH_FILE"`)

  for file in "${files[@]}"; do
    exist_check "$file"
  done

  integrity_verifier
}

verify(){
  if command -v git >/dev/null; then 
    git clone "https://github.com/zthxxx/${PROJECT_NAME}.git"
    cd "$PROJECT_NAME"
  else
    mkdir "$PROJECT_NAME"
    cd "$PROJECT_NAME"
    download_files
  fi
}

verify
chmod +x sslaunch.sh

. ./bbr.sh
. ./sslaunch.sh

bbr
pre_install
launch

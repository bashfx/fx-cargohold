#!/usr/bin/env bash
# cargohold.sh — crates.io namespace + repo-aware stub (with --dir + confirm + --yes)
# NOTE: Do not spam crates.io with empty repos you dont intend on building!
# Bash 3.2+ compatible

set -euo pipefail

# ==================== USER DEFAULTS ==================== #
DEFAULT_GITHUB_NAME="YourGitHubUsernameOrOrg"     # override with --name
DEFAULT_SSH_IDENTITY="${SSH_IDENTITY:-github.com}"# e.g., github or github.com
DEFAULT_DESC="Reserved name stub crate. No functionality is provided."
DEFAULT_KEYWORDS="stub,reserved"
DEFAULT_CRATE_TYPE="lib"        # lib|bin
DEFAULT_LICENSE="MIT OR Apache-2.0"
DEFAULT_VERSION="0.0.1"
# ======================================================= #

die(){ echo "ERR: $*" >&2; exit 1; }

valid_crate_name(){
  case "$1" in
    *[A-Z]*|*[^a-z0-9_-]*|"") return 1;;
  esac
  [ ${#1} -le 64 ] || return 1
  [[ "$1" =~ ^[a-z0-9][a-z0-9_-]*$ ]] || return 1
  [[ "$1" =~ [a-z] ]] || return 1
  return 0
}

keywords_literal(){
  printf '%s' "$1" | awk -F',' '{
    out=""; for (i=1;i<=NF;i++){ gsub(/^ +| +$/,"",$i);
      if($i!=""){ if(out!=""){ out=out", "}; out=out"\""$i"\"" }
    } print out
  }'
}

truncate80(){
  local s="$1"; local n=${#s}
  if [ $n -le 80 ]; then printf "%s" "$s"; else printf "%s…" "$(printf "%s" "$s" | cut -c1-80)"; fi
}

# --------- defaults ---------
CRATE_NAME=""
WORKDIR=""
CRATE_TYPE="$DEFAULT_CRATE_TYPE"
VERSION="$DEFAULT_VERSION"
DESC="$DEFAULT_DESC"
KEYWORDS="$DEFAULT_KEYWORDS"
NAME="$DEFAULT_GITHUB_NAME"
REPO_NAME=""
SSH_ID="$DEFAULT_SSH_IDENTITY"
HOMEPAGE=""
PUBLISH="yes"
AUTO_YES="no"

usage(){
  cat <<USAGE
Usage: $0 <crate-name>
       [--dir DIRNAME]
       [--lib|--bin]
       [--version X.Y.Z]
       [--desc TEXT]
       [--keywords "a,b"]
       [--name GITHUB_USER_OR_ORG]
       [--repo REPO_NAME_ONLY]
       [--ssh SSH_HOST_ALIAS_OR_DOMAIN]
       [--homepage URL]
       [--no-publish]
       [--yes]
USAGE
  exit 1
}

# --------- parse ---------
[ $# -ge 1 ] || usage
CRATE_NAME="$1"; shift

while [ $# -gt 0 ]; do
  case "$1" in
    --dir) WORKDIR="${2:?}"; shift 2;;
    --lib) CRATE_TYPE="lib"; shift;;
    --bin) CRATE_TYPE="bin"; shift;;
    --version) VERSION="${2:?}"; shift 2;;
    --desc) DESC="${2:?}"; shift 2;;
    --keywords) KEYWORDS="${2:?}"; shift 2;;
    --name) NAME="${2:?}"; shift 2;;
    --repo) REPO_NAME="${2:?}"; shift 2;;
    --ssh) SSH_ID="${2:?}"; shift 2;;
    --homepage) HOMEPAGE="${2:?}"; shift 2;;
    --no-publish) PUBLISH="no"; shift;;
    --yes) AUTO_YES="yes"; shift;;
    -h|--help) usage;;
    *) die "Unknown arg: $1";;
  esac
done

# --------- validations ---------
command -v cargo >/dev/null 2>&1 || die "cargo not found"
valid_crate_name "$CRATE_NAME" || die "invalid crate name '$CRATE_NAME'"
[ -n "$NAME" ] || die "--name required or set DEFAULT_GITHUB_NAME"
[ "$NAME" != "YourGitHubUsernameOrOrg" ] || die "set --name or DEFAULT_GITHUB_NAME"

if [ -n "$REPO_NAME" ]; then
  case "$REPO_NAME" in *[\\/:]*|"") die "invalid --repo" ;; esac
fi

[ -n "$WORKDIR" ] || WORKDIR="$CRATE_NAME"
[ ! -e "$WORKDIR" ] || die "directory '$WORKDIR' already exists"

# Build URLs if repo provided
REPO_HTTPS=""; REMOTE_SSH=""
if [ -n "$REPO_NAME" ]; then
  REPO_HTTPS="https://github.com/${NAME}/${REPO_NAME}"
  REMOTE_SSH="git@${SSH_ID}:${NAME}/${REPO_NAME}.git"
fi

# --------- pre-flight summary ---------
echo "Plan:"
printf "  Crate:        %s\n" "$CRATE_NAME"
printf "  Directory:    %s\n" "$WORKDIR"
printf "  Type:         %s\n" "$CRATE_TYPE"
printf "  Version:      %s\n" "$VERSION"
printf "  Description:  %s\n" "$(truncate80 "$DESC")"
printf "  Keywords:     %s\n" "$KEYWORDS"
printf "  GitHub Name:  %s\n" "$NAME"
if [ -n "$REPO_NAME" ]; then
  printf "  Repo Name:    %s\n" "$REPO_NAME"
  printf "  Repo HTTPS:   %s\n" "$REPO_HTTPS"
  printf "  Remote SSH:   %s\n" "$REMOTE_SSH"
else
  printf "  Repo:         (none)\n"
fi
printf "  Homepage:     %s\n" "${HOMEPAGE:-(none)}"
printf "  Publish:      %s\n" "$PUBLISH"
echo

# --------- confirmation ---------
if [ "$AUTO_YES" != "yes" ]; then
  printf "Proceed with creation? [y/N]: "
  read ans || true
  ans=$(printf '%s' "${ans:-}" | tr '[:upper:]' '[:lower:]')
  if [ "$ans" != "y" ] && [ "$ans" != "yes" ]; then
    echo "Aborted."
    exit 0
  fi
fi

# --------- scaffold ---------
cargo init "$WORKDIR" ${CRATE_TYPE:+--$CRATE_TYPE} >/dev/null
cd "$WORKDIR"

KEYS_LITERAL="$(keywords_literal "$KEYWORDS")"

# Cargo.toml
{
  echo "[package]"
  echo "name = \"${CRATE_NAME}\""
  echo "version = \"${VERSION}\""
  echo "edition = \"2021\""
  printf 'description = "%s"\n' "$DESC"
  echo "readme = \"README.md\""
  echo "license = \"${DEFAULT_LICENSE}\""
  echo "keywords = [${KEYS_LITERAL}]"
  [ -n "$REPO_HTTPS" ] && echo "repository = \"${REPO_HTTPS}\""
  [ -n "$HOMEPAGE" ] && echo "homepage = \"${HOMEPAGE}\""
  if [ "$CRATE_TYPE" = "lib" ]; then
    echo
    echo "[lib]"
    echo "path = \"src/lib.rs\""
  fi
} > Cargo.toml

# README
{
  echo "# ${CRATE_NAME}"
  echo
  echo "**Reserved Name Stub** — This crate intentionally contains no functionality."
  [ -n "$REPO_HTTPS" ] && echo "- Repository: ${REPO_HTTPS}"
} > README.md

# licenses
cat > LICENSE-MIT <<'EOF'
MIT License
Copyright (c)
Permission is hereby granted...
EOF
cat > LICENSE-APACHE <<'EOF'
Apache License 2.0 — http://www.apache.org/licenses/LICENSE-2.0
EOF

# src
mkdir -p src
if [ "$CRATE_TYPE" = "lib" ]; then
  cat > src/lib.rs <<'EOF'
#![doc = include_str!("../README.md")]
#![forbid(unsafe_code)]
#![deny(warnings)]
#![allow(dead_code)]

#[deprecated(note = "This crate name is reserved. It intentionally provides no functionality.")]
pub const _RESERVED_STUB: &str = env!("CARGO_PKG_NAME");
EOF
else
  cat > src/main.rs <<'EOF'
fn main() {
    eprintln!("This crate name is reserved. No functionality is provided.");
}
EOF
fi

# git
cat > .gitignore <<'EOF'
/target
Cargo.lock
EOF
git init -q
git add .
git commit -q -m "chore: reserve crate stub ${CRATE_NAME}"

if [ -n "$REMOTE_SSH" ]; then
  if git remote get-url origin >/dev/null 2>&1; then
    git remote set-url origin "$REMOTE_SSH"
  else
    git remote add origin "$REMOTE_SSH"
  fi
  if git ls-remote --exit-code "$REMOTE_SSH" >/dev/null 2>&1; then
    echo "Remote exists: $REMOTE_SSH"
  else
    echo "Remote NOT found: $REMOTE_SSH"
    echo "Create it remotely, then push:"
    echo "  git push -u origin HEAD"
  fi
else
  echo "No --repo provided; skipped remote setup."
fi

# publish
if [ "$PUBLISH" = "yes" ]; then
  cargo package >/dev/null
  cargo publish
  echo "Published ${CRATE_NAME} ${VERSION} to crates.io"
else
  echo "Publishing disabled (--no-publish used)."
fi

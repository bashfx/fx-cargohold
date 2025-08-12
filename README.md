# 🛳️ cargohold — Reserve Your Crate Namespace on crates.io

**cargohold** is a small but mighty Bash script to **secure a crate name** on [crates.io](https://crates.io) before someone else grabs it.

It creates a **minimal stub crate** with:
- A simple `lib.rs` or `main.rs`
- `Cargo.toml` metadata
- README + MIT & Apache licenses
- Optional GitHub repo linking
- Optional auto-publish to crates.io

---

## 🧩 Why use cargohold?
- You’ve got a 🔥 idea but aren’t ready to release the full crate yet.
- You want your namespace secured before publishing a real release.
- You want to automate all the boring setup steps.

---

## ⚠️ **Important Warning**
crates.io is a shared resource — **do not spam** it with dozens of useless crates you never plan to build.  
If you reserve a name, either:
1. Build something real, **or**
2. Clearly mark it as available for transfer.

Publishing random junk wastes everyone’s time (and may get you flagged).

---

## 🛠️ Usage

```bash
./cargohold <crate-name> [flags...]
```

### 🏴 Flags
| Flag | Description |
|------|-------------|
| `--dir DIRNAME`      | Local directory name (default = crate name) |
| `--lib`              | Create a library crate (default) |
| `--bin`              | Create a binary crate |
| `--version X.Y.Z`    | Set initial version (default `0.0.1`) |
| `--desc TEXT`        | Crate description |
| `--keywords "a,b"`   | Comma-separated list of keywords |
| `--name USER_OR_ORG` | Your GitHub username/org for repo linking |
| `--repo REPO_NAME`   | Remote repo name (no slashes) |
| `--ssh HOST_ALIAS`   | SSH alias or domain (default: `github.com`) |
| `--homepage URL`     | Homepage URL in crate metadata |
| `--no-publish`       | Don’t publish to crates.io (default is **publish**) |
| `--yes`              | Skip confirmation prompt |

---

## 📦 Example Commands

Reserve a library crate with GitHub repo setup:
```bash
./cargohold coolcrate \
  --name mygithub \
  --repo coolcrate \
  --keywords "cli,tools" \
  --desc "A crate to do cool things" \
  --yes
```

Reserve a binary crate with custom directory name:
```bash
./cargohold coolcli \
  --bin \
  --dir temp-coolcli \
  --name mygithub \
  --repo coolcli \
  --no-publish
```

---

## 📜 Example Output
```
Plan:
  Crate:        coolcrate
  Directory:    coolcrate
  Type:         lib
  Version:      0.0.1
  Description:  A crate to do cool things
  Keywords:     cli,tools
  GitHub Name:  mygithub
  Repo Name:    coolcrate
  Repo HTTPS:   https://github.com/mygithub/coolcrate
  Remote SSH:   git@github.com:mygithub/coolcrate.git
  Homepage:     (none)
  Publish:      yes

Proceed with creation? [y/N]: y
Created stub crate: /path/to/coolcrate
Remote NOT found: git@github.com:mygithub/coolcrate.git
Create it remotely, then push:
  git push -u origin HEAD
Published coolcrate 0.0.1 to crates.io
```

---

## 🛡️ License
Dual-licensed under **MIT** or **Apache-2.0**.  
Choose whichever license suits your needs.

---

## 🔍 See Also
- [crates.io policies](https://doc.rust-lang.org/cargo/reference/publishing.html)
- [GitHub CLI](https://cli.github.com/) for automatic repo creation

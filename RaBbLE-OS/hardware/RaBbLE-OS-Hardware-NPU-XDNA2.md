# RaBbLE-OS-Hardware-NPU-XDNA2.md — AMD NPU / XDNA2 Local Inference Stack

```
spark ~ grimoire/RaBbLE-OS/hardware >> NPU research captured; XRT+FLM+Lemonade ansible live // %NPU_RESEARCH%
```

**Researched:** 2026-06-18 · **Updated:** 2026-06-20 (xdna-driver XRT pin is same version — shim replaces source build as fix for add(run&&))  
**Kernel verified on:** `7.0.12-100.fc43.x86_64`  
**Hardware:** AMD Ryzen AI 9 HX 370 (Strix Point, XDNA2) — ASUS ProArt P16

> This is a moving surface. Kernel, firmware, and userspace packages are all improving rapidly.
> Always check the date stamp above and the known issues before acting on this doc.

---

## What Is This Stack?

The AMD NPU (Neural Processing Unit) in Ryzen AI 300-series chips (Strix Point / Krackan / Strix Halo) is an **XDNA2** accelerator capable of 50 TOPS. As of June 2026, it can run LLM inference on Linux via:

```
kernel driver (amdxdna)
      ↓
XRT userspace runtime (libxrt)
      ↓
FastFlowLM (LLM inference engine)
      ↓
Lemonade Server (Ollama/OpenAI-compat API on :8000)
      ↓
sCoRE (local_fast / local_npu provider chain)
```

The NPU handles **prompt processing**; the AMD iGPU handles **token generation**. Both participate in inference, making this a hybrid NPU+GPU path.

---

## Hardware Compatibility

| Family | PCI Device | Supported? |
|--------|-----------|------------|
| XDNA2 — Ryzen AI 300 (Strix Point, Krackan) | `17f0:10`, `17f0:11` | ✅ Fully supported |
| XDNA2 — Ryzen AI Max 300 (Strix Halo) | `1502:00` | ✅ Fully supported |
| XDNA2 — Ryzen AI 400 (Gorgon Point) | — | ✅ Supported |
| XDNA1 — Ryzen AI 7000/8000/200-series | — | ❌ Not supported by FLM |

> **Our hardware:** PCI `66:00.1`, device `17f0` rev `10` = Strix Point XDNA2. ✅

---

## Driver Layer — Status as of 2026-06-18

| Layer | State | Version / Path |
|-------|-------|----------------|
| Kernel | ✅ **In-tree since Linux 7.0** | `7.0.12-100.fc43.x86_64` |
| `amdxdna` module | ✅ Loaded | `0.6.0` (intree, no DKMS needed) |
| Device node | ✅ Present | `/dev/accel/accel0` |
| NPU firmware | ✅ Present | `amdnpu/17f0_10/npu.sbin.1.1.2.64.xz`, `17f0_11/npu.sbin.1.1.2.65.xz` |
| XRT userspace | ❌ Not installed | Needs COPR or source build |
| FastFlowLM | ❌ Not installed | Needs source build |
| Lemonade Server | ❌ Not installed | Needs COPR or upstream |

**The driver layer is complete.** Kernel 7.0 ships `amdxdna` in-tree — no DKMS, no out-of-tree patches, no backport kernels required. Everything below /dev/accel/ is working. What's missing is the userspace stack above it.

---

## The Linux 7.0 Unlock

Before kernel 7.0, enabling the NPU on Fedora required either:
- A DKMS package (`amdxdna-dkms`) from a COPR
- Building and patching the kernel from the `drm-misc-fixes` branch

**As of Linux 7.0** (released ~April 2026), `amdxdna` is upstream in the kernel tree. Fedora 43 with kernel 7.0+ gets it for free — it just loads at boot. This is the inflection point that makes NPU inference practical on Fedora without exotic kernel management.

**Linux 7.1** (in development at time of writing) expands further: new ioctls, better resource management, additional hardware PCI aliases, and improved firmware handling. Nothing in 7.1 is required to run the current stack.

---

## What AMD Says vs. What Actually Works

AMD's official Ryzen AI SDK documentation points to:
- ONNX Runtime with the VitisAI Execution Provider for NPU inference
- `ryzenai.docs.amd.com` — Windows-centric, Vitis AI SDK, large install

**This does not work reliably on Linux.** Vitis AI's ONNX Runtime EP has no stable Linux path as of June 2026.

**What actually works:**
- **XRT** (Xilinx/AMD Runtime) for the NPU device interface
- **FastFlowLM** for LLM inference (Ollama-like UX, XDNA2-compiled models)
- **Lemonade Server** for the API layer (OpenAI-compat + multimodal: LLM + Whisper + TTS)

FastFlowLM is AMD-backed but separate from their "official" SDK. It emerged in **March 2026** (v0.9.35) as the first practical Linux NPU LLM runtime. Performance: ~18 tok/s for a 20B model on XDNA2 hardware.

---

## Firmware Notes

Firmware files live at `/usr/lib/firmware/amdnpu/` and are shipped via the `linux-firmware` package. As of kernel 7.0 + linux-firmware 20260221+:

```
/usr/lib/firmware/amdnpu/17f0_10/   ← Strix Point (our hardware)
  npu_7.sbin.xz                     ← kernel 7 format (primary)
  npu.sbin.1.1.2.64.xz              ← versioned blob
  npu.sbin.xz                       ← symlink target

/usr/lib/firmware/amdnpu/17f0_11/   ← Krackan Point
  npu_7.sbin.xz
  npu.sbin.1.1.2.65.xz
  npu.sbin.xz
```

FastFlowLM requires firmware **1.1.0.0 or later**. Both `1.1.2.64` and `1.1.2.65` meet this requirement. Note: newer firmware may report version as `255.0.11.69` instead of the `1.1.x.x` format — this is a version encoding change, not a regression. Both formats work.

The old format `1.0.0.63` (shipped with older linux-firmware) is **incompatible** with FastFlowLM.

---

## Installation: COPR Path (Preferred)

The `xanderlent/amd-npu-driver` COPR provides binary RPMs for Fedora. As of June 2026, it includes:

| Package | Contents |
|---------|----------|
| `xrt` | XRT core runtime libraries |
| `xrt-devel` | Development headers |
| `xdna-driver` | XDNA kernel plugin (userspace side) |
| `fastflowlm` | LLM inference engine for XDNA2 |

This COPR is marked **Experimental** and is volunteer-maintained. Known caveat: packages may lag behind the upstream XRT release. The F43 packages may not be compatible with Fedora 44 due to Boost library version changes.

### Managed by Ansible

```bash
# Apply the runtime layer (XRT + FastFlowLM + Lemonade)
ansible-playbook -i ansible/inventory/hosts.yml ansible/site.yml -K --tags runtime,xrt
ansible-playbook -i ansible/inventory/hosts.yml ansible/site.yml -K --tags runtime,fastflowlm
ansible-playbook -i ansible/inventory/hosts.yml ansible/site.yml -K --tags runtime,lemonade

# Or all at once
ansible-playbook -i ansible/inventory/hosts.yml ansible/site.yml -K --tags runtime
```

### Manual COPR steps (if needed outside Ansible)

```bash
sudo dnf copr enable xanderlent/amd-npu-driver

# XRT + XDNA driver (--allowerasing resolves OpenCL ICD conflict)
sudo dnf install --allowerasing xrt xdna-driver

# Symlink fix — XRT lands in /usr/xrt, FastFlowLM expects /opt/xilinx
sudo mkdir -p /opt/xilinx
sudo ln -sf /usr/xrt /opt/xilinx/xrt
# /usr/xrt/lib is a real dir (only xdna plugin) — symlink individual core libs into it
for f in /usr/xrt/lib64/libxrt*.so* /usr/xrt/lib64/libxilinx*.so*; do
  [ -e "$f" ] && sudo ln -sf "$f" "/usr/xrt/lib/$(basename $f)"
done

# FastFlowLM (may be in COPR or needs source build — see below)
sudo dnf install fastflowlm   # try COPR first
```

---

## Installation: Source Build Path (Fallback)

### XRT from source

Use this when `flm validate` reports firmware incompatibility (XRT version too old for the installed firmware). **Not needed for the `add(xrt::run&&)` linker error — see Shim section below.**

```bash
# Dependencies
sudo dnf install cmake cmake-extra-modules ninja-build boost-devel \
  ocl-icd-devel python3-devel libdrm-devel elfutils-devel \
  libffi-devel rapidjson-devel git tcsh

# Clone (xdna-driver bundles XRT as a submodule)
git clone --recursive https://github.com/amd/xdna-driver.git
cd xdna-driver

# Build XRT userspace (npu profile, optimized, skip tests)
cd xrt/build && ./build.sh -npu -opt -noctest -j$(nproc)

# Build XDNA kernel plugin
cd ../../build && ./build.sh -release -j$(nproc)

# Install both RPMs (allowerasing for OpenCL ICD conflict)
sudo dnf install --allowerasing \
  xrt/build/Release/*.rpm \
  build/Release/xrt_plugin*.rpm
```

> **Note:** As of June 2026, `xdna-driver`'s XRT submodule is pinned to the same April 2025 build as COPR (version 2.19.0). Building from `xdna-driver` source produces the same XRT and does **not** resolve the missing `add(xrt::run&&)` symbol. That requires the shim below, not a source rebuild.

To trigger source build from Ansible (only for firmware mismatch, not symbol issues):
```bash
ansible-playbook -i ansible/inventory/hosts.yml ansible/site.yml -K \
  --tags runtime,xrt -e xrt_force_rebuild=true
```

---

## XRT Compatibility Shim — `runlist::add(xrt::run&&)`

### The problem

COPR XRT 2.19.0 (built April 2025) is missing one C++ overload:

```
xrt::runlist::add(xrt::run&&)   ← rvalue/move overload — MISSING from 2.19.0
xrt::runlist::add(xrt::run const&)  ← const-lvalue overload — present
```

FastFlowLM's prebuilt closed-source NPU libraries (`src/lib/libllama_npu.so`, etc.) were compiled against a newer XRT that has both overloads. The final `flm` link step fails:

```
ld: /opt/src/FastFlowLM/src/lib/libllama_npu.so: undefined reference to 'xrt::runlist::add(xrt::run&&)'
```

C++ name mangling:
- `_ZN3xrt7runlist3addEONS_3runE` = `add(xrt::run&&)` — the `O` = rvalue reference qualifier
- `_ZN3xrt7runlist3addERKNS_3runE` = `add(xrt::run const&)` — the `RK` = const lvalue reference

Check whether the symbol is present in your installed XRT:
```bash
nm -D /usr/xrt/lib64/libxrt_coreutil.so | grep '_ZN3xrt7runlist3addEONS_3runE'
# No output = symbol missing = shim required
```

### Why `xdna-driver` source build doesn't help

`xdna-driver` pins its XRT submodule to the same April 2025 commit. Building from source produces the same `libxrt_coreutil.so` with the same missing overload. The shim is the only practical fix until COPR or xdna-driver updates their XRT pin to a post-April 2025 release.

### The shim

The fix is a plain C shared library that provides the missing symbol by redirecting to the existing const-lvalue overload at the raw symbol level. **A C++ member function definition cannot be used** — C++ only allows out-of-line definitions for members already declared in the class, and XRT 2.19.0 headers don't declare `add(run&&)`. The compiler would reject it silently (with `failed_when: false`, this caused silent failure in early attempts).

```c
/* xrt_runlist_shim.c — no headers needed, raw mangled symbol names */
/* x86-64 ABI: both add(run const&) and add(run&&) pass this=rdi, run*=rsi */
void _ZN3xrt7runlist3addERKNS_3runE(void*, void*);  /* add(run const&) — in libxrt_coreutil */

void _ZN3xrt7runlist3addEONS_3runE(void* self, void* run_ref) {  /* add(run&&) — MISSING */
    _ZN3xrt7runlist3addERKNS_3runE(self, run_ref);
}
```

**Why this works:** On x86-64 System V ABI, references and rvalue references are both passed as pointers — both `add(run const&)` and `add(run&&)` receive `this` in `rdi` and a pointer to the run object in `rsi`. The binary calling convention is identical, so the redirect is correct. `xrt::run` is a ref-counted pimpl handle; copy and move semantics are equivalent at the handle level.

### Compile and use the shim manually

```bash
# Compile the shim (plain gcc, no XRT headers needed)
sudo mkdir -p /opt/src/xrt_shim
sudo tee /opt/src/xrt_shim/xrt_runlist_shim.c <<'EOF'
void _ZN3xrt7runlist3addERKNS_3runE(void*, void*);
void _ZN3xrt7runlist3addEONS_3runE(void* self, void* run_ref) {
    _ZN3xrt7runlist3addERKNS_3runE(self, run_ref);
}
EOF
sudo gcc -shared -fPIC -O2 \
    -o /opt/src/xrt_shim/libxrt_runlist_shim.so \
    /opt/src/xrt_shim/xrt_runlist_shim.c

# Copy shim into FastFlowLM's lib dir (already in linker search path)
sudo cp /opt/src/xrt_shim/libxrt_runlist_shim.so /opt/src/FastFlowLM/src/lib/

# Configure FLM with the shim flag injected
cd /opt/src/FastFlowLM/src
rm -rf build   # remove any stale CMakeCache.txt
cmake --preset linux-default \
  -DXRT_LIB_DIR=/opt/xilinx/xrt/lib64 \
  -DCMAKE_EXE_LINKER_FLAGS=-lxrt_runlist_shim
cmake --build --preset linux-default -j$(nproc)
sudo cmake --install --preset linux-default

# Deploy shim to runtime lib path
sudo cp /opt/src/xrt_shim/libxrt_runlist_shim.so /opt/fastflowlm/lib/
sudo ldconfig
```

### Ansible automation

`xrt.yml` runs the nm check and compiles the shim automatically:
- `nm` check detects missing symbol → writes shim source → compiles `libxrt_runlist_shim.so`
- `fastflowlm.yml` copies shim to `src/lib/`, passes `-DCMAKE_EXE_LINKER_FLAGS=-lxrt_runlist_shim` to cmake, copies shim to `/opt/fastflowlm/lib/` post-install

When COPR or xdna-driver eventually updates XRT to include the rvalue overload, the nm check will return success and the shim path is skipped automatically.

### FastFlowLM from source

```bash
# Additional deps
sudo dnf install ninja-build ffmpeg-free-devel fftw-devel rust cargo

# cmake3 alias may be needed on Fedora
[ -f /usr/bin/cmake3 ] || sudo ln -s /usr/bin/cmake /usr/bin/cmake3

git clone --recursive https://github.com/FastFlowLM/FastFlowLM.git
cd FastFlowLM/src

# Build shim first (see above), copy to src/lib/, then configure + build
cmake --preset linux-default \
  -DXRT_LIB_DIR=/opt/xilinx/xrt/lib64 \
  -DCMAKE_EXE_LINKER_FLAGS=-lxrt_runlist_shim
cmake --build --preset linux-default -j$(nproc)
sudo cmake --install --preset linux-default
```

---

## Post-Install Configuration

These steps apply regardless of COPR vs. source path. **Ansible manages these automatically.**

### 1. memlock limits (REQUIRED — non-obvious failure mode)

Missing memlock limits cause `mmap(...) failed (err=-11): Resource temporarily unavailable` — misleadingly blamed on XRT library errors, not permissions.

```bash
# PAM limits (for login shells)
sudo tee /etc/security/limits.d/99-amdxdna.conf <<'EOF'
* soft memlock unlimited
* hard memlock unlimited
EOF

# systemd default (for services and other units)
sudo mkdir -p /etc/systemd/system.conf.d
sudo tee /etc/systemd/system.conf.d/99-amdxdna.conf <<'EOF'
[Manager]
DefaultLimitMEMLOCK=infinity
EOF
```

**Requires reboot** — existing shells keep old limits.

### 2. Dynamic linker paths

```bash
sudo tee /etc/ld.so.conf.d/xrt.conf <<'EOF'
/opt/fastflowlm/lib
/opt/xilinx/xrt/lib64
EOF
sudo ldconfig
```

### 3. udev permissions for /dev/accel

```bash
sudo tee /etc/udev/rules.d/99-amdxdna.rules <<'EOF'
SUBSYSTEM=="accel", KERNEL=="accel*", GROUP="render", MODE="0660"
EOF
sudo udevadm control --reload-rules && sudo udevadm trigger
```

### 4. User groups

```bash
sudo usermod -aG render,video $USER
```

### 5. Runtime environment wrapper

`flm` requires environment variables that aren't in PATH by default when XRT installs to `/usr/xrt`:

```bash
sudo tee /usr/local/bin/flm <<'EOF'
#!/usr/bin/env bash
export LD_LIBRARY_PATH="/opt/fastflowlm/lib:/opt/xilinx/xrt/lib64:${LD_LIBRARY_PATH}"
export FLM_CONFIG_PATH="/opt/fastflowlm/share/flm/model_list.json"
exec /opt/fastflowlm/bin/flm "$@"
EOF
sudo chmod +x /usr/local/bin/flm
```

---

## Lemonade Server

Lemonade wraps FastFlowLM (and optionally llama.cpp for GPU) with an Ollama/OpenAI-compatible HTTP API on `:8000`. It also provides:
- Stable Diffusion image generation
- Whisper speech-to-text
- Kokoro TTS

### Install (COPR or upstream)

```bash
# Try xanderlent COPR or lemonade upstream COPR
sudo dnf install lemonade-server   # may need copr first

# Lemonade GUI (AppImage — electron dep not always resolved by RPM)
# Download AppImage from: https://github.com/lemonade-sdk/lemonade/releases
```

### Systemd service override (critical — FLM needs memlock + env)

```bash
sudo mkdir -p /etc/systemd/system/lemonade-server.service.d
sudo tee /etc/systemd/system/lemonade-server.service.d/10-flm.conf <<'EOF'
[Service]
LimitMEMLOCK=infinity
Environment=LD_LIBRARY_PATH=/opt/fastflowlm/lib:/opt/xilinx/xrt/lib64
Environment=FLM_CONFIG_PATH=/opt/fastflowlm/share/flm/model_list.json
EOF
sudo systemctl daemon-reload
sudo systemctl enable --now lemonade-server
```

---

## Validation

```bash
# 1. Kernel driver loaded
lsmod | grep amdxdna          # amdxdna 217088 0

# 2. Device node present
ls /dev/accel/                # accel0

# 3. XRT sees the device
xrt-smi examine               # shows NPU info + firmware version

# 4. FLM full stack check
flm validate
# Expected output:
#   kernel: 7.0.x ✅
#   device: /dev/accel/accel0 ✅
#   firmware: 1.1.x.x ✅
#   memlock: unlimited ✅

# 5. Lemonade API
curl http://127.0.0.1:8000/api/v1/health

# 6. Pull and run a model
flm pull <model-name>         # see fastflowlm.com/docs/models
flm run <model-name>
```

---

## sCoRE Integration

Once Lemonade is running on `:8000`, add to sCoRE's provider chain in `~/.config/rabble/sCoRE.env` or via the provider registry:

```
local_npu: http://localhost:8000/v1/chat/completions
```

Lemonade serves an OpenAI-compatible API, so sCoRE's existing LLM chain mechanism works with no code changes. The `local_npu` tier should be positioned after `local_fast` (Groq) in the chain for latency reasons — NPU inference at ~18 tok/s is slower than cloud fast-tier but free, private, and offline-capable.

---

## Known Issues (as of 2026-06-18)

| Issue | Status | Workaround |
|-------|--------|------------|
| COPR XRT puts core libs in `lib64/`, not `lib/` — cmake `XRT_LIB_DIR` defaults to `lib` and fails to link `libxrt_coreutil` | Active | Pass `-DXRT_LIB_DIR=/opt/xilinx/xrt/lib64` to cmake; also delete stale `CMakeCache.txt` from any prior failed configure. Ansible role does both automatically |
| Stale `CMakeCache.txt` from a failed cmake configure bakes the wrong `XRT_LIB_DIR` path, persisting across re-runs even with the correct flag | Active | Delete `src/build/` before re-configuring. Ansible role does this automatically |
| COPR XRT 2.19.0 (April 2025) missing `xrt::runlist::add(xrt::run&&)` — prebuilt FLM NPU libs need this rvalue overload | Active | Compile C++ compatibility shim (`libxrt_runlist_shim.so`) and inject at link time via `-DCMAKE_EXE_LINKER_FLAGS=-lxrt_runlist_shim`. Ansible does this automatically. See XRT Compatibility Shim section. Source build from `xdna-driver` does NOT fix this — same XRT version |
| `xdna-driver` XRT submodule pinned to same April 2025 build as COPR — source build produces identical XRT | Active | Shim approach is the correct fix. Monitor xdna-driver for XRT submodule update |
| F43 → F44 Boost library mismatch in COPR RPMs | Active | Source build on F44 |
| OpenCL ICD conflict (`OpenCL-ICD-Loader` vs `ocl-icd`) | Active | `dnf install --allowerasing` |
| `lemonade-server recipes` shows "Requires Windows" for NPU | Known bug | Ignore — NPU inference works despite this label |
| Lemonade GUI AppImage missing `electron` dep | Active | Use CLI or raw AppImage |
| memlock failures show as XRT library errors | Misleading | Check limits first before diagnosing XRT |
| `amd_iommu=off` in kernel cmdline kills NPU | Don't do this | Remove from `rabble_grub_extra_cmdline` if present |
| IOMMU must remain enabled | Requirement | Verify with `dmesg \| grep iommu` |
| Firmware version format: `255.0.11.69` vs `1.1.x.x` | Not a bug | Both are valid; doc examples lag firmware format change |
| XDNA1 (7000/8000/200-series) not supported | Hard limit | FastFlowLM only supports XDNA2 on Linux |

---

## Roadmap / Improving Surface

This is a fast-moving area. Expected improvements:

- **Linux 7.1** (merge window open at time of writing): new NPU ioctls, expanded hardware aliases, better resource management. Will not break existing stack.
- **Fedora official packages**: ML/AI SIG tracking NPU support. COPR may eventually graduate to official repos.
- **FastFlowLM model library**: Growing. Conversion tools for custom GGUF → XDNA2 in development.
- **XDNA1 Linux support**: No public timeline from AMD. May never happen; XDNA2 is the supported path.
- **Lemonade multimodal**: Stable Diffusion + Whisper + Kokoro on the same server. NPU handles text; GPU handles image/audio.

---

## References

- [FastFlowLM Linux Install Guide](https://fastflowlm.com/docs/install_lin/)
- [Lemonade NPU Linux Guide](https://lemonade-server.ai/flm_npu_linux.html)
- [AMD xdna-driver GitHub](https://github.com/amd/xdna-driver)
- [FastFlowLM GitHub](https://github.com/FastFlowLM/FastFlowLM)
- [AMD NPU Kernel Docs](https://docs.kernel.org/accel/amdxdna/amdnpu.html)
- [Fedora Discussion: F44 AMD XDNA and FastFlowLM](https://discussion.fedoraproject.org/t/f44-amd-xdna-and-fastflowlm/192556)
- [xanderlent/amd-npu-driver COPR](https://copr.fedorainfracloud.org/coprs/xanderlent/amd-npu-driver/)
- [Guide: AMD Ryzen AI NPU on Fedora 43 (dev.to)](https://dev.to/ankk98/guide-to-setting-up-amd-ryzen-ai-npu-drivers-on-fedora-43-477i)
- [Framework Community: XDNA2 + Arch + FastFlowLM](https://community.frame.work/t/guide-use-npu-xdna2-with-arch-linux-and-fastflowlm/80879)
- [Phoronix: AMD Ryzen AI NPUs Finally Useful Under Linux](https://www.phoronix.com/news/AMD-Ryzen-AI-NPUs-Linux-LLMs)
- [Lemonade issue #1315: Fedora 43 XDNA2 FLM beta working](https://github.com/lemonade-sdk/lemonade/issues/1315)
- [Reddit r/StrixHalo: AMD says vs what actually works](https://www.reddit.com/r/StrixHalo/comments/1syy7rx/install_what_amd_says_vs_what_actually_works/)

---

→ `hardware/RaBbLE-OS-Hardware-ProArtP16.md` — hardware profile and kernel module table  
→ `layers/RaBbLE-OS-Layers.md` — runtime layer structure  
→ `RaBbLE-OS/ansible/roles/runtime/tasks/xrt.yml` — Ansible implementation  
→ `RaBbLE-OS/ansible/roles/runtime/tasks/fastflowlm.yml` — FastFlowLM Ansible  
→ `RaBbLE-OS/ansible/roles/runtime/tasks/lemonade.yml` — Lemonade Ansible

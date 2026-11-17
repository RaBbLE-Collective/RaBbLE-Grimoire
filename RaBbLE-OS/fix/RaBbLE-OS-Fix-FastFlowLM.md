# RaBbLE-OS-Fix-FastFlowLM.md — FastFlowLM Source Build Debug History

**Documented:** 2026-06-20  
**Sessions:** S122–S125  
**Hardware:** AMD Ryzen AI 9 HX 370 (Strix Point XDNA2), Fedora 43, kernel 7.0.12

> This doc records the full debug journey for getting FastFlowLM to build from source on Fedora 43 with COPR XRT 2.19.0. Each bug and fix is captured so future agents don't repeat the debugging.

---

## Background

FastFlowLM (`flm`) is the primary Linux LLM inference engine for AMD XDNA2 NPUs. Its COPR binary RPM (from `xanderlent/amd-npu-driver`) was not available for Fedora 43 at time of writing, so the source build path was required. The source build links against COPR XRT 2.19.0 userspace libs and FastFlowLM's prebuilt closed-source NPU kernel libraries in `src/lib/`.

This turned out to require three distinct fixes across multiple sessions.

---

## Bug 1 — `ld: cannot find -lxrt_coreutil` (S122/S123)

### Symptom

cmake configure succeeded. cmake build failed at the link step:

```
ld: cannot find -lxrt_coreutil: No such file or directory
```

### Root Cause

Two compounding issues:

**1a. COPR XRT lib64/lib split.**  
COPR installs XRT core libraries to `/usr/xrt/lib64/`. However, the FastFlowLM cmake `linux-default` preset sets:

```cmake
XRT_LIB_DIR = ${XILINX_XRT}/lib
```

With `XILINX_XRT=/opt/xilinx/xrt` (itself a symlink to `/usr/xrt`), this resolves to `/usr/xrt/lib`. That directory exists but only contains the XDNA kernel plugin (`libxrt_plugin_vitis.so`). Core libs like `libxrt_coreutil.so` live in `/usr/xrt/lib64/` only.

**1b. Stale `CMakeCache.txt`.**  
An earlier failed configure attempt had baked `/opt/xilinx/xrt/lib` (wrong path) into `src/build/CMakeCache.txt`. Subsequent runs re-read the cache before applying command-line overrides, so even passing the correct `-DXRT_LIB_DIR` flag was silently ignored. The fix for 1a was invisible until 1b was also fixed.

### Fix

In `fastflowlm.yml`:

1. Delete `src/build/` before configure:
   ```yaml
   - name: Remove stale FastFlowLM build directory
     ansible.builtin.file:
       path: "{{ fastflowlm.src_dir }}/src/build"
       state: absent
   ```

2. Pass the corrected lib dir explicitly:
   ```yaml
   cmake --preset linux-default -DXRT_LIB_DIR=/opt/xilinx/xrt/lib64
   ```

### Side Bug — Ansible `state: link` on existing directory

The initial `xrt.yml` tried to make `/usr/xrt/lib` a symlink to `/usr/xrt/lib64` using:
```yaml
ansible.builtin.file:
  src: /usr/xrt/lib64
  dest: /usr/xrt/lib
  state: link
  force: true
```

Ansible's `file` module with `state: link` and `force: true` can replace an existing **symlink**, but **not an existing real directory**. The task silently failed.

Fix: replace the symlink task with a per-library `ln -sf` loop:
```yaml
- name: Symlink XRT core libs into /usr/xrt/lib
  ansible.builtin.shell: |
    for f in /usr/xrt/lib64/libxrt*.so* /usr/xrt/lib64/libxilinx*.so*; do
      [ -e "$f" ] && ln -sf "$f" "/usr/xrt/lib/$(basename $f)"
    done
```

---

## Bug 2 — `undefined reference to 'xrt::runlist::add(xrt::run&&)'` (S124)

### Symptom

With Bug 1 fixed, cmake configure and build both succeeded through 90/91 compilation units. The final link step (step 91: `Linking CXX executable flm`) failed:

```
/usr/sbin/ld: /opt/src/FastFlowLM/src/lib/libllama_npu.so: undefined reference to 'xrt::runlist::add(xrt::run&&)'
collect2: error: ld returned 1 exit status
```

### Root Cause

The FastFlowLM prebuilt NPU libraries (`src/lib/libllama_npu.so` and others) were compiled against a newer XRT that includes both overloads of `runlist::add`:

| Symbol (mangled) | Demangled | In COPR 2.19.0? |
|------------------|-----------|-----------------|
| `_ZN3xrt7runlist3addERKNS_3runE` | `add(xrt::run const&)` | ✅ Yes |
| `_ZN3xrt7runlist3addEONS_3runE` | `add(xrt::run&&)` | ❌ **No** |

The `O` in the mangled rvalue form is the Itanium C++ ABI encoding for rvalue reference (`&&`). `RK` encodes const lvalue reference (`const&`). COPR XRT 2.19.0 was built from an April 2025 snapshot of `xdna-driver` that predates the addition of the rvalue overload.

**How to verify:**
```bash
nm -D /usr/xrt/lib64/libxrt_coreutil.so | grep '_ZN3xrt7runlist3addEONS_3runE'
# Empty output = symbol missing
```

### First attempted fix: XRT source build from `xdna-driver` (S124)

Added Ansible tasks to clone `xdna-driver`, build XRT userspace with `./build.sh -npu -opt -noctest`, install resulting RPMs. The logic: newer XRT from upstream HEAD should have the rvalue overload.

---

## Bug 2b — xdna-driver XRT pin is the same version (S125)

### Discovery

After adding the source build pipeline in S124, the next Ansible run confirmed that the source build completed but:

```bash
cat /opt/src/xdna-driver/xrt/build/Release/xrt_202520.2.19.0_*.rpm  # same version
nm -D /usr/xrt/lib64/libxrt_coreutil.so | grep '_ZN3xrt7runlist3addEONS_3runE'
# Still empty — symbol still missing
```

`xdna-driver`'s XRT submodule (`xdna-driver/xrt/`) is a pinned reference to the same April 2025 commit that produced COPR 2.19.0. Building from `xdna-driver` HEAD produces the **same XRT** as the COPR binary. The source build path is futile for this specific issue.

### Fix: C++ Compatibility Shim

Since we cannot easily get a newer XRT (COPR is frozen, xdna-driver is also frozen, upstream XRT is a large repo to build independently), the correct fix is to provide the missing symbol ourselves.

**The shim — first attempt (C++, silently failed):**

The initial approach was a C++ member function definition:
```cpp
#include "xrt/xrt_kernel.h"
namespace xrt {
  void runlist::add(run&& r) { add(static_cast<const run&>(r)); }
}
```
This compiled with `g++` and XRT includes. It was correct in reasoning but failed in practice: C++ requires an out-of-line member function definition to match an existing declaration in the class. XRT 2.19.0 headers don't declare `add(run&&)`, so the compiler rejects the definition. With `failed_when: false`, this failed silently — the `.so` was never created, the copy task silently failed, the cmake conditional was never triggered, and the link failed identically.

**The shim — correct approach (C, raw symbols):**

```c
/* xrt_runlist_shim.c — no headers, raw mangled symbol names */
void _ZN3xrt7runlist3addERKNS_3runE(void*, void*);  /* add(run const&) — exists in 2.19.0 */
void _ZN3xrt7runlist3addEONS_3runE(void* self, void* run_ref) {  /* add(run&&) — MISSING */
    _ZN3xrt7runlist3addERKNS_3runE(self, run_ref);
}
```

Compiled as a shared library (plain `gcc`, no XRT headers needed):
```bash
gcc -shared -fPIC -O2 \
    -o libxrt_runlist_shim.so \
    xrt_runlist_shim.c
```

**Why this works:** On x86-64 System V ABI, both `add(run const&)` and `add(run&&)` have identical binary calling convention — `this` in `rdi`, a pointer to `run` in `rsi`. The C shim provides the missing mangled symbol and redirects to the existing one. No class declaration required, no XRT headers needed. `xrt::run` is a ref-counted pimpl handle; copy and move are semantically equivalent at the handle level.

**Injection into the FLM build:**

1. Copy `libxrt_runlist_shim.so` to `FastFlowLM/src/lib/` — this directory is already in the linker's `-L` search path
2. Pass `-DCMAKE_EXE_LINKER_FLAGS=-lxrt_runlist_shim` to cmake configure
3. The linker finds the shim's definition for `add(run&&)`, satisfying the undefined reference from `libllama_npu.so`

**Runtime deployment:**
- Copy shim to `/opt/fastflowlm/lib/` (already in `ld.so.conf` and `flm` wrapper `LD_LIBRARY_PATH`)
- At runtime: `libllama_npu.so` → calls `add(run&&)` → resolves to shim → shim calls `add(run const&)` in `libxrt_coreutil.so`

---

## Ansible Implementation Summary

| Task file | What changed | Session |
|-----------|-------------|---------|
| `fastflowlm.yml` | Add stale build dir removal step | S123 |
| `fastflowlm.yml` | Switch configure to `shell:`, inject `-DCMAKE_EXE_LINKER_FLAGS` conditionally | S125 |
| `fastflowlm.yml` | Copy shim to `src/lib/` pre-configure, `/opt/fastflowlm/lib/` post-install | S125 |
| `xrt.yml` | Replace broken `state: link` with per-lib `ln -sf` loop | S123 |
| `xrt.yml` | Add `nm` symbol check for `add(run&&)` | S124 |
| `xrt.yml` | Add shim source write + compile tasks (triggered by nm check) | S125 |
| `xrt.yml` | Gate source build behind `xrt_force_rebuild` var (not auto-triggered) | S125 |

The `xrt_force_rebuild` variable is available for cases where `flm validate` reports firmware incompatibility (a different class of problem). Run:
```bash
ansible-playbook -i ansible/inventory/hosts.yml ansible/site.yml -K \
  --tags runtime,xrt -e xrt_force_rebuild=true
```

---

## When Will This Resolve Naturally?

The shim is a workaround for a frozen upstream package. It will become unnecessary when any of these happen:
- **COPR updates**: `xanderlent/amd-npu-driver` rebuilds XRT from a post-April 2025 upstream commit
- **xdna-driver updates its XRT submodule**: the submodule pointer advances past the commit that added `add(run&&)`
- **FastFlowLM COPR RPM becomes available for F43**: no source build needed at all

The Ansible nm check (`_ZN3xrt7runlist3addEONS_3runE`) handles the transition automatically — when the symbol appears in the installed XRT, the shim path is skipped with no manual intervention.

---

→ `hardware/RaBbLE-OS-Hardware-NPU-XDNA2.md` — full NPU stack doc with Shim and Known Issues sections  
→ `RaBbLE-OS/ansible/roles/runtime/tasks/xrt.yml` — nm check + shim compile  
→ `RaBbLE-OS/ansible/roles/runtime/tasks/fastflowlm.yml` — shim injection + cmake configure

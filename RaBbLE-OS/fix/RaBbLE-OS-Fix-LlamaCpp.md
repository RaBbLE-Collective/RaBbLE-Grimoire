# RaBbLE-OS — llama.cpp Build Debug

Multi-session debug log for the llama.cpp source build (Vulkan backend) on Fedora 43 / ProArt P16.

Role: `ansible/roles/runtime/tasks/llama-cpp.yml`
Defaults: `ansible/roles/runtime/defaults/main.yml` → `llama_cpp.backend: "vulkan"`, version `b4600`

---

## Fix 1 — Wrong Fedora package name for GLSL compiler (S130)

**Error:**
```
CMake Error: Could NOT find Vulkan (missing: glslc) (found version "1.4.341")
```

**Root cause:** cmake's `FindVulkan` module requires the `glslc` binary (GLSL→SPIR-V compiler from Google's shaderc project). The Ansible task listed `shaderc` as the Fedora package name — that package doesn't exist in Fedora repos.

**Fix:** Changed package name from `shaderc` → `glslc`.

```
dnf provides '*/glslc'
# → glslc-2026.1-1.fc43.x86_64 (available in Fedora 43 updates repo)
```

The correct Vulkan build deps on Fedora 43:
```yaml
- vulkan-headers
- vulkan-loader-devel
- glslang       # provides glslangValidator
- glslc         # provides /usr/bin/glslc (shaderc SPIR-V compiler)
```

**Status after fix:** S130 ends before the next playbook run. cmake configure should now pass.

---

## Fix 2 — CUDA packages not in Fedora repos (S129)

**Error:**
```
No package cuda-toolkit available.
No package cuda-devel available.
```

**Root cause:** Role was originally written for a CUDA-only machine. ProArt P16 has RTX 3060 but
it is currently suspended (`gpu_mode: integrated`). NVIDIA CUDA RPMs aren't in standard Fedora repos.

**Fix:** Rewrote role to support dual backends:
- `backend: "vulkan"` — Fedora-native packages, works with AMD Radeon iGPU and any Vulkan GPU
- `backend: "cuda"` — requires NVIDIA CUDA repo to be configured first

Default is `vulkan`. CUDA path preserved for when RTX is active. Both are Vulkan-capable devices
so Vulkan-only covers both GPUs without needing the CUDA repo.

---

## Fix 3 — Ansible dict replace gotcha (S129)

**Error:**
```
'dict object' has no attribute 'repo'
```

**Root cause:** Added `llama_cpp: { enabled: true, backend: "vulkan" }` to group_vars. Ansible
dict vars *replace*, not merge — the partial override wiped `repo`, `src_dir`, `build_dir`, `version`.

**Fix:** Removed `llama_cpp` block from group_vars entirely. Defaults already have the correct
values (vulkan, enabled). Comment left in group_vars documenting the CUDA procedure and the
must-repeat-ALL-keys constraint.

---

## Fix 3 — GCC 15 missing `<cstdint>` in llama-mmap.h (S131)

**Error:**
```
/opt/llama.cpp/src/llama-mmap.h:26:5: error: 'uint32_t' does not name a type
note: 'uint32_t' is defined in header '<cstdint>'; fixable by adding '#include <cstdint>'
```

**Root cause:** GCC 15 (ships with Fedora 43) removed the transitive inclusion of `<cstdint>` through `<vector>`. The llama.cpp b4600 source doesn't explicitly include it in `llama-mmap.h`. This was fixed upstream in later versions.

**Fix:** Added an Ansible `lineinfile` patch task in `llama-cpp.yml` (after "Clone llama.cpp source", before CMake configure) that inserts `#include <cstdint>` after `#include <vector>` in `llama-mmap.h`:

```yaml
- name: Patch llama-mmap.h for GCC 15 (missing <cstdint> include)
  ansible.builtin.lineinfile:
    path: "{{ llama_cpp.src_dir }}/src/llama-mmap.h"
    insertafter: '#include <vector>'
    line: '#include <cstdint>'
    state: present
  when: _llama_rebuild_needed
```

Idempotent — `lineinfile` skips if the line is already present. No version bump needed.

---

## Current state (end of S131)

- S130: `glslc` package fix committed (cmake configure now passes)
- S131: GCC 15 `<cstdint>` patch committed (`lineinfile` in llama-cpp.yml)
- Build not yet re-run since S131 patch

**To continue:**
```bash
cd ~/RaBbLE-Collective/RaBbLE-OS
ansible-playbook RaBbLE-OS-Bootstrap.sh --tags llama-cpp
```

Expected flow: clone no-op (b4600 already checked out) → patch llama-mmap.h → configure no-op (cache valid) → build (~5-15 min) → install → verify.

If build still fails, check for other files missing `<cstdint>`:
```bash
grep -rn 'uint[0-9]*_t' /opt/llama.cpp/src/*.h | grep -v cstdint | grep -v stdint
```

**Verify after success:**
```bash
llama-server --version
vulkaninfo --summary 2>/dev/null | grep -E "GPU|deviceName"
```

The second command shows whether both AMD iGPU and RTX 3060 are enumerable as Vulkan devices.
If both show up, the single Vulkan build covers both GPUs.

---

## GPU context (ProArt P16)

| Device | Current state | Notes |
|--------|---------------|-------|
| AMD Radeon 890M (iGPU) | Active | Primary display, Vulkan-capable |
| NVIDIA RTX 3060 (dGPU) | Suspended (`gpu_mode: integrated`) | Also Vulkan-capable; CUDA = needs NVIDIA repo |
| AMD XDNA2 NPU | Live (validated S129) | FastFlowLM + lemonade path |

To check RTX visibility: `lspci | grep -i nvidia` and `vulkaninfo --summary`.
To activate RTX: change `gpu_mode` in group_vars and run the power-stack role.

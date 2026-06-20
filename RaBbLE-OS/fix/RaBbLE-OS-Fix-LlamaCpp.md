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

## Current state (end of S130)

- `glslc` package fix committed
- cmake configure has NOT been re-run since the fix
- Expected next run outcome: configure passes → ~5-15 min Ninja build → install

**To continue:**
```bash
cd ~/RaBbLE-Collective/RaBbLE-OS
ansible-playbook RaBbLE-OS-Bootstrap.sh --tags llama-cpp
```

If configure passes but build fails, look for:
- Missing headers at compile time (check `cmake -LA` output for detected features)
- Linker errors for Vulkan symbols (check `vulkan-loader-devel` is present)
- Build runs async (poll: 30s, timeout: 1200s) — watch for the "Build llama.cpp" task

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

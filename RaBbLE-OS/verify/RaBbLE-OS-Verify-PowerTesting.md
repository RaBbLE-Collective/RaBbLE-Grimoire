# RaBbLE-OS-Verify-PowerTesting.md — Power Testing Protocol

Run on battery, wifi connected but idle, display at 50% brightness.
**Goal:** `<10W` at idle. Primary suspect: NVIDIA GPU not reaching D3cold.

> `spells/power-profile-capture.sh` (RaBbLE-OS) now wraps this manual protocol into one
> repeatable, read-only capture — text report + machine-readable JSON snapshot, written to
> `RaBbLE-BaBbLE/tmp/` so numbers survive the reboots this protocol requires. Run it before
> and after a change and diff the JSON instead of re-typing commands by hand each time.

## Measurements

```bash
# Battery discharge rate (most accurate)
upower -d | grep -A3 "BAT" | grep "energy-rate"

# Sysfs
awk '{printf "%.1f W\n", $1/1000000}' /sys/class/power_supply/BAT0/power_now

# NVIDIA state
nvidia-smi --query-gpu=name,power.draw,pstate --format=csv,noheader 2>/dev/null
cat /sys/bus/pci/devices/0000:01:00.0/power_state   # target: D3cold

# CPU package power
turbostat --show PkgWatt,CorWatt,RAMWatt --interval 5 --num_iterations 3
```

## Stages

| Stage | When | Target |
|-------|------|--------|
| S0: TTY | Fresh boot, no GUI | ~8–12 W |
| S1: SDDM | Greeter only | ~10–14 W |
| S2: Hyprland idle | AMD only, nothing open | ~10–15 W |
| S3: Light workload | Firefox + terminal | ~12–18 W |
| S4: NVIDIA loaded | After fix/proart-nvidia | measure |
| S5: NVIDIA D3cold | After D3cold fix | ≈ S2 |

Record readings in `fix/RaBbLE-OS-KnownIssues.md`.

→ `fix/RaBbLE-OS-Fix-Nvidia.md` — D3cold fix procedure
→ `verify/RaBbLE-OS-Verify-Checklist.md` — session verification (run first)

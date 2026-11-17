# RaBbLE-OS Ansible audit (NiBbLE, 2026-11-06)

Tree: RaBbLE-OS/ansible, branch new-horizons, HEAD cce5e69 plus uncommitted edits. Paths are relative to RaBbLE-OS/.
Read: every task, handler, var and default file in every role, site.yml, inventories, Bootstrap, layerctl, RaBbLE-OS.ks. apps/plans (archived, unreachable) only skimmed.

## Method and limits
- No playbook was executed. Only `--syntax-check` and `--list-tasks`.
- Ansible behaviour claims were checked against the installed source (ansible-core 2.20.7): playbook/task.py:534-545, playbook/block.py:249-254, modules/systemd_service.py:476,509, plugins/become/sudo.py:48.
- Live evidence comes from this machine (ProArt P16 H7606WV, Fedora 44). It was read-only.
- Fresh-install outcomes are derived from code plus that evidence. No fresh install was run. Mark them as reasoned, not observed.
- Not checked: COPR availability for F44 beyond the repos enabled here; which `sddm-greeter-displayserver` provider dnf picks; whether PipeWire arrives transitively on a KS install; exit code of gsettings on a dead bus.
- Package availability came from `dnf5 repoquery --cacheonly`, so cached metadata only.

Two suspected findings were dropped after testing: `After=X` + `WantedBy=X` on powertop.service and rabble-engine.service is NOT an ordering cycle. systemd skips the implicit After when the unit already orders after the target (`systemctl show multi-user.target -p After` has no powertop; powertop ran at boot; `systemd-analyze verify` is silent).

## Counts
Critical 1 · High 10 · Medium 15 · Low 11

---

## CRITICAL

### C1. Generic x86_64 with an NVIDIA GPU: fresh install aborts before boot chain and desktop
`ansible/roles/hardware/x64/generic/tasks/nvidia.yml:40-52`, reached from `RaBbLE-OS.ks:263`.
- Nothing enables RPM Fusion: no task, no KS line, nothing in Install.sh or Bootstrap. `grep -i rpmfusion` hits only this check and manifest `source:` labels.
- KS runs `--tags base,boot,desktop,gnome`. The nvidia include is tagged `boot` (`--list-tasks` on vm.hosts shows it in play #4) and so are the inner detection and fail tasks.
- Scenario: stock desktop with any NVIDIA card. `_has_nvidia` true, `rpm -q rpmfusion-nonfree-release` fails, `ansible.builtin.fail` fires in Layer 1. The host drops out of every later play: no GRUB theme, Plymouth, SDDM, Hyprland, GNOME.
- Bootstrap exits non-zero, `.setup-complete` is never written, and `rabble-os-setup.service` repeats the same failure on every boot. The user gets a TTY with dotfiles for a desktop that is not installed.
- The fail message says "Enable it (layerctl base / manifest)". layerctl base does not do that.
- Fix: add a repo task (rpmfusion free + nonfree release RPMs for the running releasever, Fedora-signed keys) ahead of Layer 1, driven by manifest `source:`. Until then degrade to a warning and skip the driver so the desktop still lands on nouveau.

---

## HIGH

### H1. `ignore_errors` on the ai-harness includes does nothing, and aider uses `uv` before anything installs it
`ansible/roles/ai-harnesses/tasks/main.yml:15,23,31,39,47,55,63,71,79`, `ansible/roles/ai-harnesses/tasks/aider.yml:32-39`.
- Dynamic-include keywords do not reach included tasks: task.py:536-539 and block.py:251-254 skip a non-static parent. `apply:` only carries `tags: always`.
- Order is claude-code, codex, opencode, aider, ... free-claude-code. `uv` is installed only in claude-code.yml:81 (only if sCoRE sits at ~/RaBbLE-Collective) and free-claude-code.yml:13 (after aider). No dnf task or manifest entry installs it (the uv RPM on this box was not requested by anything in this tree).
- Scenario: any KS install, then `layerctl apply all`. aider.yml:33 fails with no such file, the host dies, and gemini-cli, ollama, free-claude-code and playwright never run. The design intent, "one harness failing does not stop the others", does not hold.
- Fix: put `ignore_errors: true` in `apply:`, or wrap each file in block/rescue. Move a single uv install ahead of all harnesses, or add `uv` to core packages and the manifest.

### H2. `~/RaBbLE-Collective` hardcoded while the KS installs to `~/RaBbLE`
`ansible/roles/ai-harnesses/tasks/free-claude-code.yml:63,197`; `claude-code.yml:42,62,78,100,110,147,148` (147-148 in flight). KS root: `RaBbLE-OS.ks:163`.
- free-claude-code.yml:197 has no failure guard: `bash ~/RaBbLE-Collective/RaBbLE-Grimoire/spells/fcc-ctl.sh sync` exits 127 on KS installs, so the host fails and the fcc service is never enabled.
- The fcc-ctl wrapper on line 63 is dead on arrival there.
- claude-code.yml stats quietly return false: no `rabble` launcher, no UI venv, no engine unit, and no message.
- Fix: derive from `rabble_repo_root | dirname`, the same way `aether_repo_root` does (all.yml:18). For the unit file, template the absolute path.

### H3. `user_id`, `user_uid` and `env.HOME` are root's inside `become: true` plays
- `ansible/roles/virtualization/tasks/service.yml:20,27`
- `ansible/roles/runtime/tasks/xrt.yml:359,367`
- `ansible/roles/apps/tasks/qt-gtk-theme.yml:214,223,232,241,250`
- `ansible/roles/apps/tasks/file_manager.yml:6,14`

Fact gathering inherits play become, and sudo runs with `-H` (sudo.py:48). Live proof on this machine, after real runs: `render:x:105:root,ollama`, `video:x:39:root,ollama`. The user is missing and root was added. kvm and libvirt also list root.
- Scenario 1: the ProArt user never gets /dev/accel access through this role; the rabble user is in neither group.
- Scenario 2: gsettings targets `/run/user/0/bus`, so the five theme settings never reach the user session (`changed_when: false` hides it).
- Scenario 3: the yazi config lands in /root/.config/yazi (derived; /root not read).
- Fix: use `rabble_user`, `rabble_home`, and a uid looked up with `getent`.

### H4. `layerctl remove` reinstalls the layer; `--packages` and `--config` do not filter
`RaBbLE-OS-layerctl.sh:268,271,313`; same false claim at `ansible/site.yml:34-38`.
- Ansible `--tags a,b` is OR. Only layer/gnome has any `remove` task.
- Scenario: `layerctl remove bottles` passes `--tags bottles,remove` and sets `rabble_enable_wine_bottles=true`. `--list-tasks` confirms it selects "install Bottles" and the UP Studio set-up. The layer is installed, and state is recorded as `removed`.
- `remove desktop` re-applies desktop and records `removed`.
- `remove gnome` installs and themes GNOME, then uninstalls it.
- `apply hardware --packages` runs the whole hardware layer plus every `packages`-tagged task in plays whose include is selected.
- Fix: refuse `remove` for layers with no remove tasks. For filtering use `--tags X --skip-tags ...` or per-layer tags such as `hardware-packages`.

### H5. Prebuilt llama.cpp install is broken on a fresh host and litters /usr/local/bin
`ansible/roles/runtime/tasks/llama-cpp.yml:326-349`, default on every host (`roles/runtime/defaults/main.yml:49-51`).
- `find patterns: llama-*` misses every `lib*.so`. `llama-server` is a 17 KB stub: `NEEDED libllama-server-impl.so`, `RUNPATH $ORIGIN`. It works here only because /usr/local/lib64 still holds an old source build (June file dates, stale against a November stub).
- Scenario: fresh host, `error while loading shared libraries`. `failed_when: false` at line 386 hides it and the stamp at line 361 stops any retry.
- The pattern also matches the archive itself. Live: 7 `llama-b*.tar.gz` files in /usr/local/bin, mode 0755, 218 MB, the newest from tonight.
- Fix: install lib*.so to `{{ install_prefix }}/lib64` and notify ldconfig, exclude `*.tar.gz`, and fail the task if `llama-server --version` fails before stamping.

### H6. Runtime handler uses `&&` under `command`
`ansible/roles/runtime/handlers/main.yml:4`
`ansible.builtin.command: udevadm control --reload-rules && udevadm trigger` passes `&&` as an argument, with no shell. Notified by xrt.yml:351 on first deploy. llama-cpp.yml:379 flushes handlers inside the same play.
- Scenario: first `apply runtime` or `apply all` on a ProArt. The handler errors (extraneous argument; udevadm error text not reproduced, needs root) and the host fails, stopping every later play. Latent on Mark's box because the rule is already deployed.
- Fix: two commands, or `ansible.builtin.shell`.

### H7. KS on the ProArt: both hardware groups, and a dead greeter
`RaBbLE-OS.ks:242`, `ansible/inventory/vm.hosts.yml:16-22`, `ansible/roles/hardware/x64/asus_proart_p16/tasks/nvidia.yml:87-105,134-169`.
- KS always uses vm.hosts.yml, whose header says it is for machines that are NOT the ProArt. localhost is statically generic_x64 and group_by adds asus_proart_p16, so both hardware plays run. generic_x64 sorts later, so it wins group_vars (console font, hardware_vendor).
- `--tags boot` deploys the wrapper and `CompositorCommand` (tagged boot) but not the udev alias rule (untagged, play tags are hardware). The wrapper then uses `/dev/dri/rabble-amdgpu-card`, which does not exist.
- It also calls `/usr/libexec/sddm-compositor-sway`, owned by sddm-wayland-sway. No task or manifest entry requests that package.
- Scenario: reinstall the ProArt from the ISO. The greeter fails and the box boots to black. This is the inverse of B-15.
- Fix: KS uses hosts.yml (DMI detection already handles generic). Tag the udev tasks `boot`. Add sddm-wayland-sway.

### H8. ProArt repos are never configured
`ansible/roles/hardware/x64/asus_proart_p16/tasks/asusctl.yml:10-15`, `supergfx.yml:5-10`, `nvidia.yml:172-183`.
- No task enables copr lukenukem/asus-linux; the comment at asusctl.yml:4-5 says the manifest declares it, but the manifest drives nothing (M1). akmod-nvidia also needs RPM Fusion, and unlike the generic role there is no check.
- Scenario: rebuild the ProArt with `apply hardware`. "No package asusctl available" stops the play. The ProArt state exists only because the repos were added by hand (`/etc/yum.repos.d` has them).
- Fix: `community.general.copr` for asus-linux, plus the C1 repo task.

### H9. Permanent passwordless root for the install user
`RaBbLE-OS.ks:142-146`
`${RABBLE_USER} ALL=(ALL) NOPASSWD: ALL` is never removed; the comment admits it. A grep of roles and scripts finds no cleanup.
- Scenario: any process running as the user (a browser exploit, a malicious npm postinstall from the unpinned AI harnesses, an agent session) gets root silently. This compounds the emergency-mode no-password decision at `core/tasks/recovery.yml`.
- Fix: delete the file at the end of a successful firstboot (the ExecStartPost that touches `.setup-complete`, and the KS success branch).

### H10. Root `curl | sh`, on by default
`ansible/roles/ai-harnesses/tasks/ollama.yml:11-15`
Unpinned install script run as root on every `apply all`, no pipefail. `ai_harnesses_ollama_enabled` defaults true.
- Scenario 1: a compromised or hijacked script owns root on every host.
- Scenario 2: curl fails mid-transfer, sh runs a truncated script, and the failure passes as success. The next task has `failed_when: false`.
- Also uses the old host ollama.ai.
- Fix: pinned release plus sha256 via `get_url`, as a manifest entry; make it opt-in on hardware without a GPU.

---

## MEDIUM

### M1. manifest.yml is not the source of truth
No role reads it (no include_vars, no reference outside comments). Consumers are only spells/generate-kickstart.py and spells/edition-audit.sh. Every package list in tasks is a hand copy.
- 51 packages are installed by tasks and absent from the manifest (virtualization, monitoring and runtime almost entirely; full list in the appendix).
- 22 manifest entries are installed by no task (M2).
- Also two entries with wrong names: `pipewire-jack` and `pipewire-pulse` have no provider in cached F44 repos. They are harmless today only because nothing consumes them.
- Fix: generate per-layer lists from the manifest (`include_vars` + `selectattr('layer', ...)`), then delete task lists. Gate in CI with the check in the appendix.

### M2. Manifest packages that users are promised and never get
- `firefox`: no task installs it, though apps/tasks/browsers.yml themes it. B-15's "install ends without Firefox" has this second cause. Fresh systems have no browser unless a dependency pulls one (none found).
- `terminus-fonts-console`: `manifest.yml:328-330` says setfont fails at boot without it. `grub2/tasks/packages.yml:8` installs only `terminus-fonts`, which does not require it, yet `vconsole.conf` sets `ter-v22b`/`ter-v32b` (owned by -console, confirmed with `rpm -qf`).
- `codium`/`code`: vscode.yml's header says install; nothing installs or adds the repo. Fresh hosts skip all theming silently. `layerctl verify apps` tests `code`.
- `ndiscover-exo-2-fonts`, though gsettings and dconf set `Exo 2`.
- `pipewire`, `wireplumber`: no task; only transitive at best, not verified.
- `tuned-gtk`, bluetooth, nightmode: declared, no play (acknowledged at site.yml:342 for layers).

### M3. Unsigned, unpinned RPM installed as root
`ansible/roles/layer/esp-idf/tasks/main.yml:68-82`
`releases/latest` to a fixed `/tmp` path, `disable_gpg_check: true`, no checksum, `force: true` re-downloads every run. Opt-in layer.
- Scenario: a compromised release or anything that can write that /tmp path between the two tasks runs RPM scriptlets as root.
- Fix: pin a version and sha256, and use a private temp dir.

### M4. Zero checksums in the whole tree
`grep checksum:` over roles returns nothing across 5 `get_url` sites.
- Worst case: `papirus-folders` from `master` into /usr/local/bin, then run as root (`layer/gnome/tasks/theme.yml:54-60,74-78`). That path runs on every KS install, and `force: false` freezes whatever was fetched first.
- `layer/bottles/tasks/upstudio.yml:101-105`: pinned URL, no checksum, then executed in Wine.
- `arduino-cli/tasks/main.yml:23-32`: `curl | sh` from master. It does `set -e` but no pipefail.
- Fix: pin a tag and sha256; papirus-folders could be a vendored file.

### M5. Unpinned third-party proxy holding provider keys
`ansible/roles/ai-harnesses/tasks/free-claude-code.yml:28-41`
Tracks `main`, runs `uv sync`, runs as a service with every key in fcc.env and sees all prompts.
- Scenario: one upstream push reaches the key file on the next apply. Also, updated code is not restarted, so the running version and the checkout drift. Same class, lower stakes: powerlevel10k (`shell/zsh/tasks/packages.yml:10-15`), sourced into every shell, and yazi plugins (`file_manager.yml:23-29`).
- Fix: pin commit SHAs, and restart on change.

### M6. /etc/default/grub is replaced whole
`ansible/roles/boot/grub2/templates/grub.j2:26-33`
Anaconda-written kernel arguments are dropped: `resume=`, `rd.luks.*`, `rd.lvm.*`, anything typed at install. Live `/etc/kernel/cmdline` shows the regenerated line is `root=... ro` + exactly the template's args.
- Scenario: bare metal with a swap partition loses `resume=`, so hibernate fails silently. An encrypted install loses `rd.luks.uuid`; hostonly initrd probably still unlocks, not verified.
- Fix: `lineinfile`/managed block for the keys RaBbLE owns, or capture the existing GRUB_CMDLINE_LINUX and merge.

### M7. Every boot-tag run rebuilds every initramfs
`ansible/roles/boot/plymouth/tasks/config.yml:103-107`
Unconditional `dracut --force --regenerate-all`, `changed_when: true`, and the `rebuild initrd` handler runs it again when anything changed.
- Scenario: `apply all` takes minutes longer, always reports changed, and rewrites boot-critical files with no change. A failure or full /boot during a pointless rebuild hurts all kernels at once.
- Fix: delete the task and rely on the handler (plus one flush).

### M8. `dracut --force` targets the running kernel
`ansible/roles/hardware/x64/generic/handlers/main.yml:3`, `asus_proart_p16/handlers/main.yml:11`
The plymouth role documents the problem at handlers/main.yml:7, yet these two still do it.
- Scenario 1: in the KS chroot, `uname -r` is the installer kernel, so the handler fails once C1 is fixed.
- Scenario 2: after a pending kernel update, the nouveau blacklist goes into the old kernel's initrd only and nouveau loads on next boot.
- Fix: `--regenerate-all` in both.

### M9. Fonts land after the initrd is built
`plymouth/tasks/config.yml:76` lists JetBrains Mono in `install_items`; `site.yml` runs Fonts after Plymouth; jetbrains-mono is not in the plymouth package task.
dracut treats it as non-fatal (`/usr/bin/dracut:2159`, no `-o`), and fonts do not notify a rebuild.
- Scenario: first-boot initrd has no JetBrains Mono, so `Image.Text` text on the splash (`rabble-aether.script:117-119,202,250-252`) falls back or is lost until a later boot-tag run.
- Fix: add jetbrains-mono-fonts to plymouth packages.

### M10. asusctl runs before asusd is started
`asus_proart_p16/tasks/main.yml:6` vs `:10`. All asusctl calls are `failed_when: false`.
- Scenario: first run, daemon possibly not up: profile and AC/battery pins silently do nothing, and asusd keeps AC=Performance, the exact S245 heat problem.
- `asusd.yml:33-45` `replace` on `/etc/asusd/asusd.ron` fails outright if asusd has not written it yet, which aborts the role.
- Fix: order asusd first, wait for the file with `wait_for`.

### M11. The PPD guard crashes when it fires
`arbitration.yml:43-51`
After line 36 removes the package, this task runs on stale `package_facts`. `found` is computed before masking and `enabled:` calls `fail_if_missing` (systemd_service.py:476,509).
- Scenario: ProArt with power-profiles-daemon present: "Could not find the requested service", hardware play aborts.
- Fix: drop `enabled` and `state`, keep `masked: true`.

### M12. Offline runs die in Runtime (local-first rule)
`llama-cpp.yml:50-57`
Unconditional GitHub API call with no failure handling, on every run with default `version: latest`, even if the stamp is current. Unauthenticated, so 60 requests/hour.
- Scenario: laptop offline, `apply all`: host fails at the Runtime play, before boot and desktop. An empty match also fails at line 65 (`first` of nothing).
- Fix: `failed_when: false`, then skip if a stamp exists.

### M13. `powertop --auto-tune` on all bare metal
`ansible/roles/monitoring/tasks/powertop.yml:9-39`
The file's own comment says it "disrupts USB/audio". Enabled unconditionally; ran on this boot (journal).
- Scenario: generic desktop: USB keyboard or mouse gets autosuspended, with input lag and dropouts on USB audio. On the ProArt it is a second power writer beside asusd (USB/PCI runtime PM only, so no EPP clash).
- Fix: gate on `form_factor == 'laptop'` (the var exists, currently unused), and exclude input devices.

### M14. XRT failure handling is inert
`ansible/roles/runtime/tasks/xrt.yml:61,67,84,95,108`
`failed_when: false` makes `.failed` always false, so the report always says "succeeded" and the `not _xrt_install.failed` gates are always true. `ansible_facts.stat` at line 96 never exists.
- Scenario: COPR broken on F44: "XRT install: succeeded", shim and FastFlowLM source build then run against nothing.
- Fix: gate on `.rc`.

### M15. In-flight: fastfetch tasks reference untracked files (AND in-flight engine unit)
`ansible/roles/desktop/fastfetch/tasks/config.yml:35-51` (in flight)
`config.compact.jsonc`, `rabble-portals.compact.txt`, `config.micro.jsonc`, `rabble-portals.micro.txt` and `spells/rabble-fetch` are all `??` in git.
- Scenario: the tasks get committed without them: the KS clone hits "could not find src" under the `desktop` tag, and the install fails. Commit together. `.zshrc` falls back safely.

`claude-code.yml:124-174` (in flight): see H2 for paths. `ignore_errors` at line 174 hides every failure of the engine start, not only the socket-lock case it names. Fix: `failed_when` on a specific message. The packages.yml gitleaks edit (in flight) is fine: package exists in F44 and the manifest entry matches. `edition: dev` in `layer: core` installs on all editions, which contradicts its label.

---

## LOW

- L1 `apps/tasks/qt-gtk-theme.yml:198-202`: papirus-folders with `become: false` does `exec sudo` (script line 402) without a tty. Fails where NOPASSWD is absent, so fixing H9 will surface it. The gnome copy uses `become: true`. Fix: same.
- L2 `opencode.yml:14-30`: verify has no PATH env, unlike claude and aider, then `fail`. Any run without ~/.local/bin in PATH aborts the rest (see H1). Same PATH gap in codex.yml:15, gemini-cli.yml:15 (those only misreport).
- L3 `RaBbLE-OS-layerctl.sh:110-119`: `hardware` verify is `asusctl profile -l && supergfxctl --status`. It always fails on generic, and uses the old flag on ProArt (asusctl.yml:17-20). `dotfiles` tests `hyprland.conf`, which no longer exists (config/hypr/hyprland.lua). `desktop` and `ai-harnesses` end in `|| true`, so they cannot fail. `snapper` tests a tool no task installs.
- L4 `RaBbLE-OS-vmctl.sh:968-970`: greps `LABEL=RaBbLE-VM` but writes `/dev/disk/by-label/...`, so each pass through this branch appends a duplicate line. Both lines carry nofail, so no boot risk. The same form-mismatch applies to `fstab-safety.yml:7`: a hand-written `LABEL=` or `UUID=` entry is not protected.
- L5 `layer/gnome/tasks/theme.yml:117-124`: masks `tracker-miner-fs-3`; F44 ships localsearch (`localsearch-3.11.2`), so the mask does nothing. Name unverified against the unit list; check `localsearch-3.service`.
- L6 `monitoring/tasks/sensors.yml:26-30`: `creates: /etc/sysconfig/lm_sensors` is owned by the RPM (`rpm -ql`), so sensors-detect never runs. Dead task.
- L7 `generic/tasks/nvidia.yml:111-113`: machine.lua block lacks the `boot` tag, so a KS install on a sole-NVIDIA box never writes it (behind C1).
- L8 `session_manager/tasks/config.yml:66-85`: tagged `plymouth`, but the include carries only `[boot, sddm, config]`, so `--tags plymouth` cannot reach it.
- L9 Plymouth `add_drivers+=" amdgpu "` (`config.yml:80`) and ProArt-derived comments apply on all hosts. Initrd bloat on Intel/NVIDIA machines. Separately, `core/tasks/config.yml:4-13` replaces the /etc/os-release symlink with a regular file (live: regular file), so it goes stale after a system-upgrade until the next apply.
- L10 `RaBbLE-OS-Bootstrap.sh:123-128`: under `set -e` + pipefail the pipeline exits first, so the `error` line with the log path is unreachable. Exit status is still correct.
- L11 Idempotence, always `changed` or re-run each time:
  `asusctl profile set` asusctl.yml:24-26; fan curves arbitration.yml:88-90,109-111 (9 commands);
  `xrt.yml:109,205,272`; `free-claude-code.yml:38` (`uv sync`, no changed_when);
  `upstudio.yml:53` (flatpak override, no changed_when); `creator-apps/tasks/main.yml:53`;
  `arduino-cli/tasks/main.yml:57,71`; `ollama.yml:43` (`ollama pull` every run, multi-GB check);
  `esp-idf/tasks/main.yml:73` (re-download every run). Layer-breaking ones are M7 and these only inflate the recap.

---

## STRUCTURE
1. Generate package lists from the manifest (M1): removes the largest source of drift and most of the 24 `packages.yml` files.
2. One repo task (RPM Fusion, COPRs, VSCodium) before Layer 0 ends, driven by manifest `source:`. It removes C1 and H8 together.
3. `gathering = smart` in ansible.cfg. It is unset, and site.yml has 39 plays that each re-gather facts.
4. Merge desktop micro-plays: 14 plays, most of them a single `dnf` list. One `desktop` role with a data-driven list keeps the tags.
5. Delete dead weight:
   - `*_tasks_only` vars at site.yml Dotfiles play (5, consumed nowhere, so that play re-runs whole roles and all `dnf` tasks; dotfile tasks are stubs and dotctl does the real work). layerctl's "re-link" help is false.
   - Stubs: quickshell, terminal/config, waybar/config+dotfiles, notifications, shell/*, snapper (layerctl presents it as a real layer), hardware config/audio/firmware/amd_gfx.
   - Unused: `core/templates/xdg-environment.conf.j2` (+`rabble_hidpi_scale`, undefined anywhere), `asus_proart_p16/files/supergfxd.conf`, `eim_config.toml` (hardcoded /home/rabble, stray tool output), `apps/plans` (archived), hyprland vars (`hypr_config_files` etc., pointing at deleted conf files), `yazi_packages`, `xrt_rollback`, `plans_enabled`, `monitoring/vars/main.yml:2` (self-referencing), `rabble_color_*` in all.yml, unused handlers (`restart sddm` x2, `reload systemd` in asus).
   - Vars that look like controls and are not: `rabble_default_shell` (zsh is hardcoded at shell/zsh/tasks/packages.yml:21), `power_stack_profile` (group_vars comment says change it to switch experiments; nothing reads it), `gpu_mode`, `hardware_vendor`, `form_factor`.
6. `collective` is reachable only through `apply all`: no layerctl layer name. `cmd_menu` points at a `bootstrap/menus/` that does not exist.
7. Inconsistent style: FQCN vs short names in asus nvidia.yml and handlers; include_tasks vs import_tasks. Tag semantics differ: S227 was this bug, and H7 and L7/L8 are the same bug repeating. Moving to `import_tasks` (static, tags inherit) in role mains removes the class.

---

## CLEAN
- B-15 detection: site.yml:52-69 is correct under hosts.yml (anchored match on `ProArt P16`, override works, live product name matches). Nothing ProArt-only reaches a generic host through that inventory. The reverse exists (H7). Still not verified on the desktop itself; B-15's `--check` step remains Mark's.
- Tuned split matches the rule: ProArt masks tuned (group_vars:21, tuned.yml:21-47), generic keeps tuned + tuned-ppd. Note KS tags omit `hardware`, so generic gets tuned only on first `apply hardware`.
- VM partition: nofail present in vmctl writer, fstab-safety and live /etc/fstab; no boot dependency found (see L4 for the narrow gap).
- KS drift: `generate-kickstart.py` output matches `%packages` exactly (7 of 7, plus @core, @hardware-support).
- Secrets: `gitleaks dir` over ansible/ found none; regex pass clean; fcc.env 0600, config dir 0700.
- Username: no task assumes `rabble`, only eim_config.toml (unused). `group: {{ rabble_user }}` assumes group=user, fine on Fedora.
- Third-party dnf repos: docker gpgcheck true with HTTPS key; COPR defaults signed.
- Handlers: every notify resolves to a defined handler.
- Syntax: `--syntax-check` passes on both inventories. yamllint errors are cosmetic (6 errors, whitespace and EOF; 137 warnings).
- Layer gating: all opt-in roles are gated by `when` on a static role, so `apply all` leaves them out. Runtime NPU gating is sound.
- Package names used by tasks all resolve in F44 by name or Provides (nodejs, p7zip, wget, libusbx via provides). Not checked: xrt, xdna-driver, fastflowlm, lemonade-server, cuda-*, all behind fallbacks or repos.

## APPENDIX: task-installed, not in manifest (51)
boost-devel cargo cuda-toolkit edk2-ovmf elfutils-devel fastflowlm ffmpeg-free-devel fftw-devel gcc glslang glslc grub2-tools htop kernel-tools lemonade-server libcurl-devel libdrm-devel libuuid-devel libvirt libvirt-client libvirt-daemon-kvm lm_sensors lm_sensors-devel lorax make mesa-dri-drivers mesa-libGL ncurses-devel nvtop ocl-icd-devel opencl-headers powerstat powertop python3-devel python3-dnf qemu-img qemu-kvm rapidjson-devel rpm-build rust spirv-headers-devel spirv-tools-devel systemd-devel tcsh virt-install virt-manager virt-viewer vulkan-headers vulkan-loader-devel xdna-driver xrt (plus /tmp/eim-cli-linux-x64.rpm, recorded as eim-cli)
Non-dnf installs also outside the manifest: npm (claude-code, codex, opencode, gemini-cli, playwright, wrangler, pnpm), pip (lemonade-server, vllm), uv (aider), curl|sh (ollama, uv, arduino-cli), git clones (powerlevel10k, yazi plugins, fcc, FastFlowLM, xdna-driver, llama.cpp).

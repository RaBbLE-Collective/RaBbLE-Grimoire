# RaBbLE-Pocket-Getting-Started.md

```
transcribe ~ pocket >> build one, then live with it // %POCKET_GETTING_STARTED%
```

How to build a RaBbLE Pocket™ and what to do with it once it is on your desk. Written 2026-10-25 against Pocket `new-horizons` (3b2c358). Every command below is copied from the repo's scripts and firmware, not paraphrased.

**Honest status.** The Pocket is a DIY build today, on a Waveshare dev board. There is no kit, no phone app, no wake word and no Bluetooth: you talk by holding a button. Talking to the hosted sCoRE needs a device token from the Collective, and Episode 1 access is invite-only. You can also run your own sCoRE (Part 1, step 7). Anything not built is labelled "on the roadmap" in `RaBbLE-Pocket-Roadmap.md`.

Background docs: [Hardware](RaBbLE-Pocket-Hardware.md) · [Beam Protocol](RaBbLE-Pocket-Beam-Protocol.md) · [Gadget Port](RaBbLE-Pocket-Gadget-Port.md) · [Orbit Transition](RaBbLE-Pocket-Orbit-Transition.md) · [Capture Plan](RaBbLE-Pocket-Capture-Plan.md) · [Backplate CAD](RaBbLE-Pocket-Backplate-CAD.md)

---

# Part 1: Build your own

## 1. Parts

| Part | What | Notes |
|---|---|---|
| Board | Waveshare ESP32-S3-Touch-AMOLED-1.75-B (the protective-case variant, about $34) | ESP32-S3R8, 8 MB PSRAM, 16 MB flash, 466x466 round AMOLED, capacitive touch, 6-axis IMU, RTC, PMIC, mic array, speaker. Vendor docs: https://docs.waveshare.com/ESP32-S3-Touch-AMOLED-1.75 |
| Battery | EEMB 402535, 3.7 V 320 mAh LiPo, MX1.25 2-pin, built-in protection circuit | 25 x 35 x 4.3 mm |
| Cable | USB-C data cable | The board enumerates as native USB Serial/JTAG (`303a:1001`), usually `/dev/ttyACM0`. No UART adapter needed. |
| Backplate (optional) | Printed battery-bay backplate, v4.2, PETG, M2 screws, 51 mm case | Designed and rendered; **not yet printed or verified on a real board.** Files and build notes: `RaBbLE-Pocket/hardware/cad/` and [Backplate CAD](RaBbLE-Pocket-Backplate-CAD.md). Until then the battery sits loose. |

**Battery polarity warning.** The battery connector can arrive with the red and black wires swapped inside the housing, even when the plug physically fits. The first RaBbLE Pocket battery was exactly that: the fix was to release the two pins from the connector and reseat them in the right order. Check the wire colours against the board's battery header markings before you plug it in. A reversed battery does not charge and risks the board. Source: [Hardware](RaBbLE-Pocket-Hardware.md), Battery.

The board also runs from USB alone for the first bring-up.

## 2. Get the code

```sh
git clone https://github.com/RaBbLE-Collective/RaBbLE-Pocket.git
cd RaBbLE-Pocket
git checkout new-horizons
```

The firmware lives in `firmware/`. The ESP-IDF version it needs is pinned in `firmware/.esp-idf-version`: **v6.0.1**. The Waveshare vendor tree is under `third_party/ESP32-S3-Touch-AMOLED-1.75`.

## 3. Toolchain

### Path A: RaBbLE-OS (the tested path)

On RaBbLE-OS the toolchain is an opt-in layer, provisioned with Espressif's own EIM installer:

```sh
bash RaBbLE-OS-layerctl.sh apply esp-idf      # from RaBbLE-OS: installs EIM + ESP-IDF under ~/esp/esp-idf-eim/
cd RaBbLE-Pocket
source ops/esp-idf-select.sh                  # once per shell: defines pocket-idf
pocket-idf                                    # reads firmware/.esp-idf-version and activates it
```

Do not pipe `pocket-idf` into anything: a pipe forks a subshell and the activation dies with it.

### Path B: generic ESP-IDF v6.0.1 (any Linux or macOS)

Install ESP-IDF **v6.0.1** with Espressif's own install guide for your OS (https://docs.espressif.com/projects/esp-idf/), then activate it in the shell you will build from (`. ./export.sh` inside the ESP-IDF checkout). This path is not scripted or tested by the Collective; `ops/build-flash.sh` below expects the RaBbLE-OS/EIM layout, so on Path B run the `idf.py` steps directly (next section).

## 4. Build and flash

Plug the board in over USB-C. First build needs network: it pulls managed components.

**Path A** (one command, from the repo root):

```sh
ops/build-flash.sh firmware                  # build + flash, port auto-detected
ops/build-flash.sh firmware -m               # ...and read the serial log afterwards
ops/build-flash.sh firmware -B               # build only, no flash
ops/build-flash.sh firmware -p /dev/ttyACM0 -t esp32s3
```

Flags: `-p/--port`, `-t/--target` (default `esp32s3`), `-B/--build-only`, `-m/--monitor`, `-s/--seconds N` (length of the headless serial read, default 15). It auto-detects the port only if exactly one `/dev/ttyACM*` or `/dev/ttyUSB*` exists; otherwise pass `-p`. It is run, not sourced, and its output must not be piped.

**Path B** (what the script runs underneath, with ESP-IDF already activated):

```sh
cd firmware
idf.py set-target esp32s3        # only if there is no sdkconfig yet
idf.py build
idf.py -p /dev/ttyACM0 flash
```

When it boots you should see the face (two oval eyes, cyan and magenta, with a gradient ring) and, after a moment, the idle animation.

## 5. Console

The Pocket has a serial console on the same USB cable. Every command starts with `>` and ends with a newline. Use any serial terminal at 115200 8N1 on the board's port, for example `picocom -b 115200 /dev/ttyACM0` (use whichever terminal you prefer; `idf.py -p /dev/ttyACM0 monitor` also works from a real terminal).

Port reset gotcha: with some tools, opening the port resets the board (the native USB Serial/JTAG toggles reset on DTR/RTS). If the face reboots the moment you connect, that is why: let it boot, then continue. If the board vanishes from `lsusb | grep -i esp` between operations, re-seat the cable.

Replies come back as lines like `@setup wifi.ssid: ok`. Secrets (`wifi.pass`, `beam.token`) are never echoed to the log.

## 6. Wi-Fi

Two ways. Touch: **Settings > Wi-Fi > Networks** and use the on-screen keypad (it works; it is clunky). Console:

```
>wifi.ssid=YourNetwork
>wifi.pass=YourPassword
>wifi.connect
```

Settings persist across reboots (NVS). Also: `>wifi.on=1` / `>wifi.on=0` (radio), `>wifi.forget` or `>wifi.forget=YourNetwork`. Setting a new `wifi.ssid` clears any pending password, so send `wifi.pass` after it.

## 7. Connect to sCoRE

The Pocket talks to sCoRE over a WebSocket ("the beam"). The firmware default is:

```
wss://rabble-score-x7qq.onrender.com/api/v1/beam
```

sCoRE refuses the connection without a token, even in demo mode. Hosted tokens are issued by the Collective (Episode 1 is invite-only; there is no public signup yet). If you have one:

```
>beam.token=YOUR_TOKEN
>beam.test
```

A long token can be sent in pieces: `>beam.token=FIRST_PART` then `>beam.token+=NEXT_PART`. Or use **Settings > sCoRE** on the device (Test, Reset URL).

**Self-hosting.** Run your own sCoRE with a `BEAM_DEVICE_TOKEN` set (see the sCoRE repo and the [Beam Protocol](RaBbLE-Pocket-Beam-Protocol.md)) and point the Pocket at it:

```
>beam.url=ws://YOUR-HOST:8000/api/v1/beam
>beam.token=THE_SAME_TOKEN
>beam.test
```

A URL saved on the device overrides the compiled-in default.

## 8. First conversation

1. Flash, join Wi-Fi, set the token, `>beam.test` answers OK.
2. **Hold the BOOT button** (the lower of the two side buttons). The face listens.
3. Say something. **Let go.** The face thinks, then sCoRE's voice comes back through the speaker.
4. No token or no speaker yet? Type the turn instead: `>chat=hello there`. Speech and text go through the same path.

Voice choices: `>voice=daniel`, `>voice=austin` or `>voice=troy` (or **Settings > Sound > Voice**).

## 9. Troubleshooting

| Symptom | Likely cause and fix |
|---|---|
| First turn is very slow (tens of seconds), then fast | The hosted sCoRE runs on a free tier that sleeps after about 15 minutes idle. The first turn wakes it. Run `>beam.test` first to warm it. |
| `>beam.test` fails or the turn errors | Wrong or missing token, no Wi-Fi, or the URL is off. Check `>status`, re-send `>beam.token=`, confirm the URL (Settings > sCoRE or `>beam.url=`). |
| No serial reply to commands | The `>` must be the first character of the line and the line must end in a newline. Or the port reset the board when you opened it: wait for boot and retry. |
| `idf.py monitor` refuses to start | It needs a real interactive terminal. In a headless shell use `ops/build-flash.sh firmware -m` (raw serial fallback) or `stty -F /dev/ttyACM0 115200 raw -echo; timeout 10 cat /dev/ttyACM0`. |
| `Could not open /dev/ttyACM0` / port busy | The board dropped off USB. `lsusb \| grep -i esp`, re-seat the cable, and close any other program holding the port. |
| Battery does not charge | Check connector polarity first (see Parts). |
| Build fails on first run | Needs network for managed components. Confirm the activated ESP-IDF is v6.0.1. |
| Face is sideways or the tilt feels off | Settings > Level, or `>imu.cal` (see the console reference). The level flow still needs a pass. |

---

# Part 2: Living with it

## Gestures

| Gesture | What it does |
|---|---|
| Hold BOOT (lower button) | Push-to-talk. Release to send. |
| Click PWR (upper button) | Sleep the screen. Click again to wake. |
| Hold PWR 1.5 s | Power off (a hint appears first). |
| Tap the idle face | Pet it. The face is happy. |
| Shake | The face wobbles, dizzy. |
| Raise the device | Wakes it (on by default; `>raise_wake=0` turns it off). The gyro also keeps the face upright and follows turns. |
| Long-press the time on the face | Set the clock (also Settings > Clock). |
| Swipe down | Converse mode |
| Swipe up | Capture mode |
| Tap the mode icon under the clock | Toggle Converse / Capture |
| Swipe left | Orbit: Settings (magenta side) |
| Swipe right | Orbit: Applets (cyan side) |

The swipe to the Orbit is one continuous thumb gesture: the face's mesh gathers into orbs and becomes the dial. Details: [Orbit Transition](RaBbLE-Pocket-Orbit-Transition.md).

## Converse and Capture

**Converse** is the default: hold BOOT, talk, get a spoken reply.

**Capture** is for notes. Hold BOOT and talk (or type `>capture=TEXT`) and sCoRE shapes what you said into a markdown note with Summary, Notes and Transcript sections. The note comes back to the Pocket and is stored on its flash (LittleFS) under `/pocket/notes/YYYY/MM/<id>.md`. The mode survives a reboot.

A turn you speak while out of Wi-Fi range is kept on the device (as compressed audio on flash) and sent when sCoRE is reachable again.

Console: `>mode=capture`, `>mode=converse`.

## Getting notes off the device

There is no host sync script yet (on the roadmap). Today you pull notes through the console:

```
>notes                    list notes (one @notes JSON line each, then a summary line)
>notes.get=ID             stream one note as base64 parts, ending with a sha256
>notes.done=ID            mark a note as offloaded
>notes.rm=ID              delete a note (only works on notes marked offloaded)
```

`>notes.get=ID` prints `@note`, then `@note.part {"seq":N,"b64":"..."}` lines, then `@note.end {"id":..,"bytes":..,"sha256":..,"ok":true}`. Save the terminal output to a file and decode it:

```sh
python3 - note.log > note.md <<'PY'
import sys, json, base64
parts = []
for line in open(sys.argv[1]):
    i = line.find('@note.part ')
    if i >= 0:
        parts.append(base64.b64decode(json.loads(line[i + 11:])['b64']))
sys.stdout.buffer.write(b''.join(parts))
PY
sha256sum note.md          # compare with the sha256 in @note.end
```

Only after the checksum matches: `>notes.done=ID`, then `>notes.rm=ID` to free the space.

## Settings Orbit

Swipe left. The dial holds: Volume, Brightness, Speaker, Wi-Fi, sCoRE, Sleep, Level, Power off, More. Tap an orb to open it, turn or slide to change a value. "< Face" takes you back.

## Pomodoro

Swipe right to Applets, then open Pomodoro. The page offers Focus, Break, Long break, Start and Reset. Defaults: focus 25 min, break 5, long break 15, with four rounds before a long break. Choices: focus 15, 20, 25, 30, 45 or 50; break 3, 5 or 10; long break 10, 15 or 20.

Hold the Start orb to start, to pause, to resume. Hold Reset to reset. While it runs, a ring on the face drains: violet during focus, green during a break; paused, it blinks slowly. During focus the mesh runs quieter and the eyes narrow. The round dots show the four rounds.

Console: `>pomo=start`, `>pomo=pause`, `>pomo=reset`, `>pomo=skip`, `>pomo=state`.

Not built: fidget detection and check-in nudges during focus are TODOs in the code.

## Sleep and power

- Screen sleeps after the Sleep setting (`>sleep=SECONDS`, 0 to 3600). PWR click sleeps it at once.
- Deep power cut follows after `>power_off=SECONDS` (0 to 3600).
- Hold PWR 1.5 s to power off.
- The face renders at 60 fps idle on the 466x466 panel.

## Console reference

Every command begins with `>`. Integer commands reject out-of-range values.

**Talking**

| Command | Does |
|---|---|
| `>chat=TEXT` | A typed Converse turn |
| `>chat+=TEXT` | Append to a long typed turn (send the last piece with `>chat=`) |
| `>chat.cancel` | Drop a pending typed turn |
| `>capture=TEXT` | A typed Capture note |
| `>mode=capture` / `>mode=converse` | Switch mode |
| `>voice=daniel\|austin\|troy` | Reply voice |

**Network and sCoRE**

| Command | Does |
|---|---|
| `>wifi.ssid=X` then `>wifi.pass=Y` then `>wifi.connect` | Join a network |
| `>wifi.on=0\|1` | Radio off / on |
| `>wifi.forget` / `>wifi.forget=SSID` | Forget networks |
| `>beam.url=URL` | sCoRE WebSocket URL |
| `>beam.token=TOKEN` / `>beam.token+=MORE` | Device token (secret; `+=` appends) |
| `>beam.test` | Test the connection |

**Settings**

| Command | Range |
|---|---|
| `>volume=N` | 0 to 100 |
| `>speaker=N` | 0 or 1 |
| `>mic_gain=N` | 0 up to the firmware max |
| `>brightness=N` | 10 to 100 |
| `>sleep=SECONDS` | 0 to 3600 |
| `>power_off=SECONDS` | 0 to 3600 |
| `>raise_wake=N` | 0 or 1 |

**Notes** (see above): `>notes`, `>notes.get=ID`, `>notes.done=ID`, `>notes.rm=ID`, `>outbox` (undelivered voice turns).

**Status and motion**

| Command | Does |
|---|---|
| `>status` | Device status |
| `>power`, `>power.reset` | Battery readout; reset its estimate |
| `>nap` | Sleep as if on battery |
| `>face=boot\|idle\|listening\|thinking\|speaking\|error\|off\|happy` | Force a face state |
| `>imu`, `>imu.cal`, `>imu.cal.reset`, `>imu.turn`, `>imu.bias=x,y` | Motion and level calibration (bias in g, each within 0.3) |
| `>pomo=start\|pause\|reset\|state\|skip` | Pomodoro |
| `>orbit=open\|applets\|close\|back\|tap\|hold\|turn:N\|value:N\|type:TEXT\|state` | Drive the Orbit from the console |
| `>perf`, `>perf=on\|off` | Frame-rate diagnostics |

**Bare serial keys** (no `>`): `d` and `u` press and release push-to-talk, `c` chirp, `z` sleep, `w` wake.

---

## What is not here yet (on the roadmap)

Wake word, Bluetooth and a phone setup path, a host script to sync notes, long voice capture, account sync, and the aluminium 1.75C board. None of these exist in the firmware today.

---

*RaBbLE, RaBbLE Pocket and the RaBbLE entity are trademarks of The RaBbLE Collective. Code is source-available under the RaBbLE Sovereign Accord.*

```
transcribe ~ pocket >> the door to building one is open // %POCKET_GETTING_STARTED%
```

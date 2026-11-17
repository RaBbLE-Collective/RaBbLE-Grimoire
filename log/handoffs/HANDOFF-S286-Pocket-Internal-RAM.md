# HANDOFF-S286: Pocket internal-RAM recovery (task M1)

> Owner: Mark (he said he will do the hunt; an agent may run the measurements). Written 2026-10-28, session S286 (pocket-release). Companion plan: `log/plans/Pocket-Release-Entities-Companion-Plan.md` §2.4c.

## Why

Internal RAM is the binding constraint on the whole Pocket roadmap. About 12.3 KB of internal heap is free at ready (12,351 B at `52f72b9`; S278 12,367 B). It already costs voice notes (B-22), it forces the Open SDK to ship a lean profile, and every new feature (entity interpreter, general disk layer, 1.75C board) is gated on "internal heap delta 0". Flash is not the problem: the app is 2,058,064 B in 3.5 MB OTA slots, `storage` is about 8.9 MiB.

Mark's wording was "IRAM". On the ESP32-S3 one internal SRAM is split between instruction RAM (IRAM) and data RAM (DRAM/heap), so everything moved out of IRAM or trimmed from stacks, static buffers and BSS can come back as heap.

## Starting facts (read from `firmware/sdkconfig` on S286, NOT yet measured against the map; treat as leads)

- Code and rodata already run from PSRAM: `SPIRAM_XIP_FROM_PSRAM`, `SPIRAM_FETCH_INSTRUCTIONS`, `SPIRAM_RODATA`.
- About 20 `*_IN_IRAM` options are on: `GDMA_*`, `GPTIMER_ISR`, `I2C_MASTER_ISR`, `MCPWM_ISR`, `RMT_*`, `SPI_MASTER_ISR_IN_IRAM`, `SPI_SLAVE_ISR_IN_IRAM`, `ESP_EVENT_POST_FROM_IRAM_ISR`, `ESP_HW_SUPPORT_FUNC_IN_IRAM`, `RTC_*_FUNC_IN_IRAM`, `ESP_PERIPH_CTRL_FUNC_IN_IRAM`, `ESP_REGI2C_CTRL_FUNC_IN_IRAM`, `ESP_SPI_BUS_LOCK_ISR_FUNCS_IN_IRAM`, `ESP_INTR_IN_IRAM`, `LIBC_MISC_IN_IRAM`, `LIBC_LOCKS_PLACE_IN_IRAM`, `ESP_PHY_IRAM_OPT`. Some exist so ISRs survive flash-cache-off windows (LittleFS writes to flash), so each needs a reason check before it is dropped.
- Wi-Fi: `ESP_WIFI_STATIC_RX_BUFFER_NUM=8`, `ESP_WIFI_DYNAMIC_RX_BUFFER_NUM=32`, `ESP_WIFI_DYNAMIC_TX_BUFFER_NUM` and TX type 0 (static buffers are internal RAM; size per buffer is an estimate of about 1.6 KB, unmeasured).
- `SPIRAM_MALLOC_ALWAYSINTERNAL=4096`: every allocation under 4 KiB stays in internal RAM (a lower value, e.g. 512 to 1024, pushes more to PSRAM at a speed cost; DMA buffers must stay internal).
- Stacks: `ESP_MAIN_TASK_STACK_SIZE=8192`, `LWIP_TCPIP_TASK_STACK_SIZE=3072`, `ESP_SYSTEM_EVENT_TASK_STACK_SIZE=2304`, `FREERTOS_TIMER_TASK_STACK_DEPTH=2048`; plus the app's own tasks (beam, voice, UI) which are set in code.
- Known rules: UI-only statics go `EXT_RAM_BSS_ATTR`; `.bss` creep breaks beam task creation (S267), so check beam connect after every flash; `LWIP_MAX_SOCKETS=10`.

## Steps

1. **Baseline.** Build, flash, boot 3 times, record the `ready: free heap` line and the largest free internal block (`heap_caps_get_largest_free_block`). Keep the numbers in this file.
2. **Where it goes.** `idf.py size` / `size-components` / `size-files` against `build/rabble_pocket.map` for the IRAM vs DRAM split (static `.data`/`.bss`, IRAM text). List the top 20 contributors in internal RAM by file.
3. **Stacks.** Log `uxTaskGetStackHighWaterMark` for every task after a full session (boot, Orbit, a voice turn, Capture, Wi-Fi scan, sleep/wake). New size = measured peak + 25 %.
4. **One change at a time.** For each candidate (an `*_IN_IRAM` option, a Wi-Fi buffer count, `ALWAYSINTERNAL`, a stack, a static moved to PSRAM): change, build, flash, 3-boot heap A/B, beam connect, 60 fps idle check, a flash write under load (notes save while the face animates, to catch cache-disabled ISR hazards). Revert anything that costs fps or stability. One commit per accepted change with its measured gain.
5. **Report.** Reached heap number, what was safe, what was not and why. Update B-22 (voice notes) and the Open profile heap budget in the plan.

## Gates and rules

- Behaviour identical; any gain bigger than 512 B gets its own commit `harmonize ~ pocket/mem >> …`.
- `firmware/test/run.sh` exits 0 before each commit; no `third_party` or clean-room files touched.
- The Pocket repo may have another session in it (another session holds the SDK plan claims); check `bash spells/agent-register.sh status` and claim `RaBbLE-Pocket:firmware/sdkconfig*` first.

## Done when

Free internal heap at ready is meaningfully above 12.3 KB (Mark sets the target), B-22 voice notes can be re-enabled or a firm number says they cannot, and the Open profile has a measured budget for the entity interpreter and the general disk layer.

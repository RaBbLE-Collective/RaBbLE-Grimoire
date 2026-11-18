/* Copyright (c) 2026 The RaBbLE Collective. RaBbLE Sovereign Accord. */
/* Host harness: renders nebula_lite in bands, times it, writes PPM. No SDL needed.
 * usage: host_render out.ppm [state] [t] [level] [roll_deg] [happy] [activity]
 *   state: 0 idle, 1 listen, 2 think, 3 speak, 4 error */
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include "nebula_lite.h"
#include "nl_scene.h"

static double now_ms(void) { struct timespec t; clock_gettime(CLOCK_MONOTONIC, &t); return t.tv_sec * 1e3 + t.tv_nsec / 1e6; }

/* A stand-in UI screen: violet rows of "text" blocks on black, a grid, a cyan frame at x 0. */
static uint16_t s_ui[NL_W * NL_H];
static uint32_t s_ui_ver[(NL_H + NL_BAND_ROWS - 1) / NL_BAND_ROWS];
static void make_ui(void)
{
    for (int y = 0; y < NL_H; y++)
        for (int x = 0; x < NL_W; x++) {
            uint16_t p = 0x0801;   /* near black */
            if ((y % 48) > 30 && (y % 48) < 44 && x > 70 && x < 400 && (x / 9) % 3) p = 0xbafe;   /* "text" */
            if (x % 58 == 0 || y % 58 == 0) p = 0x31a6;
            if (x < 4) p = 0x07bf;   /* the left edge: shows where the slide boundary is */
            s_ui[y * NL_W + x] = p;
        }
    for (int k = 0; k < (int)(sizeof s_ui_ver / 4); k++) s_ui_ver[k] = 1;
}

/* A stand-in sprite: a filled rounded block, so layout and turning can be checked. */
static uint8_t s_blk[24 * 90];

int main(int argc, char **argv)
{
    static uint16_t fb[NL_W * NL_H], band[NL_W * NL_BAND_ROWS + NL_BAND_SLACK_BYTES / 2] __attribute__((aligned(16)));
    int state = argc > 2 ? atoi(argv[2]) : 0;
    float t_end = argc > 3 ? (float)atof(argv[3]) : 6.0f, level = argc > 4 ? (float)atof(argv[4]) : 0.5f;
    float roll = (argc > 5 ? (float)atof(argv[5]) : 0) * 3.14159265f / 180, happy = argc > 6 ? (float)atof(argv[6]) : 0;
    float act = argc > 7 ? (float)atof(argv[7]) : -1;
    for (int y = 0; y < 24; y++) for (int x = 0; x < 90; x++) s_blk[y * 90 + x] = (x > 2 && x < 87 && y > 2 && y < 21) ? 255 : 90;
    nl_init(NULL);
    nl_inputs_t in = { .roll = roll, .state = (uint8_t)state, .mic_deg = { 211, 145 }, .boot = 10, .happy = happy, .activity = { 0.3f, 0.6f } };
    if (act >= 0) in.activity[0] = in.activity[1] = act;
    /* UI_SLIDE=px UI_ROLL=deg: the UI screen over the scene. */
    if (getenv("UI_SLIDE")) {
        make_ui();
        in.ui = (nl_ui_t){ s_ui, s_ui_ver, (float)atof(getenv("UI_ROLL") ? getenv("UI_ROLL") : "0") * 3.14159265f / 180, (int16_t)atoi(getenv("UI_SLIDE")) };
        if (getenv("UI_ROLL") && atof(getenv("UI_ROLL")) == 90) in.ui.roll = 1.5707964f;
    }
    in.sprites[0] = (nl_sprite_t){ s_blk, 90, 24, 90, 233, 76, 0xe8e6f0, 255, 1 };          /* clock */
    in.sprites[1] = (nl_sprite_t){ s_blk, 90, 24, 90, 233, 420, 0x6b6880, 255, 1 };         /* status */
    in.sprites[2] = (nl_sprite_t){ s_blk, 24, 24, 90, 393, 339, 0xff2d78, 255, 2 };         /* talk hint */
    in.n_sprites = 3;
    in.badges[0] = (nl_badge_t){ 393, 339, 17, 0xff2d78, 255, 0 };
    in.badges[1] = (nl_badge_t){ 393, 127, 17, 0x00f5ff, 255, 0 };
    in.n_badges = 2;
    /* Run the scene up to t_end at 60 fps so easing and the level history fill in. */
    double sim_ms = 0, ren_ms = 0; int frames = 0, prims = 0;
    for (float t = 0; t <= t_end; t += 1 / 60.0f) {
        in.t = t; if (getenv("FLIP")) in.flip = (float)atof(getenv("FLIP")); if (getenv("BOOT")) in.boot = (float)atof(getenv("BOOT"));
        in.level = level * (0.5f + 0.5f * sinf(t * 7) * sinf(t * 2.3f));
        double t0 = now_ms();
        nl_simulate(&in);
        double t1 = now_ms();
        if (t + 1 / 60.0f > t_end || frames % 30 == 0) {
            for (int y = 0; y < NL_H; y += NL_BAND_ROWS) {
                int rows = y + NL_BAND_ROWS > NL_H ? NL_H - y : NL_BAND_ROWS, x0, x1;
                nl_band_window(y, rows, &x0, &x1);
                nl_render_band(band, y, rows, x0, x1);
                for (int r = 0; r < rows; r++) memcpy(fb + (y + r) * NL_W + x0, band + r * (x1 - x0), (x1 - x0) * 2);
            }
            ren_ms = now_ms() - t1;
        }
        sim_ms = t1 - t0;
        prims = nl_prim_count();
        frames++;
    }
    /* Damage: the next frame, and which bands would be drawn. */
    in.t += 0; /* golden: hold */
    nl_simulate(&in);
    int same = 0;
    for (int y = 0; y < NL_H; y += NL_BAND_ROWS) same += nl_band_same(y);
    fprintf(stderr, "repeat frame: %d of %d bands same\n", same, (NL_H + NL_BAND_ROWS - 1) / NL_BAND_ROWS);
    fprintf(stderr, "last frame (host): simulate %.2f ms, render %.2f ms, %d prims\n", sim_ms, ren_ms, prims);
    FILE *f = fopen(argc > 1 ? argv[1] : "out.ppm", "wb");
    fprintf(f, "P6\n%d %d\n255\n", NL_W, NL_H);
    for (int i = 0; i < NL_W * NL_H; i++) {
        uint16_t p = fb[i];
        p = (uint16_t)((p << 8) | (p >> 8));   /* bands come out in panel byte order */
        float dx = i % NL_W + 0.5f - NL_W * 0.5f, dy = i / NL_W + 0.5f - NL_H * 0.5f;
        if (dx * dx + dy * dy > (NL_W * 0.5f) * (NL_W * 0.5f)) p = 0;   /* off the round panel */
        unsigned char rgb[3] = { (p >> 11) << 3 | (p >> 13), ((p >> 5) & 63) << 2 | ((p >> 9) & 3), (p & 31) << 3 | ((p >> 2) & 7) };
        fwrite(rgb, 1, 3, f);
    }
    fclose(f);
    return 0;
}

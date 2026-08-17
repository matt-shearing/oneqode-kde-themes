#include "oq_heat.h"

#include <string.h>

#include "color.h"
#include <lib/lib8tion/lib8tion.h>
#include "timer.h"

// Heatmap only — no splash rings. Pressed key heats most; neighbours
// pick up a short falloff so zones form without flooding the board.
#ifndef OQ_HEAT_INCREASE
#    define OQ_HEAT_INCREASE 36
#endif
#ifndef OQ_HEAT_SPREAD
#    define OQ_HEAT_SPREAD 28
#endif
#ifndef OQ_HEAT_AREA_LIMIT
#    define OQ_HEAT_AREA_LIMIT 14
#endif
#ifndef OQ_HEAT_DECREASE_MS
#    define OQ_HEAT_DECREASE_MS 50
#endif

static uint8_t  heat[RGB_MATRIX_LED_COUNT];
static uint16_t decrease_timer;
static bool     decrease_now;

static RGB rgb(uint8_t r, uint8_t g, uint8_t b) {
    RGB out;
    out.r = r;
    out.g = g;
    out.b = b;
    return out;
}

static RGB scale_rgb(RGB in, uint8_t value) {
    return rgb(scale8(in.r, value), scale8(in.g, value), scale8(in.b, value));
}

static RGB mix_rgb(RGB a, RGB b, uint8_t t) {
    return rgb((uint8_t)(a.r + ((int16_t)b.r - a.r) * t / 255), (uint8_t)(a.g + ((int16_t)b.g - a.g) * t / 255), (uint8_t)(a.b + ((int16_t)b.b - a.b) * t / 255));
}

// Night Ride: pink idle → magenta → cyan.
// Light Glass: ice idle → bright blue → OneQode blue.
static RGB heat_color(uint8_t amount) {
    RGB     idle = hsv_to_rgb(rgb_matrix_config.hsv);
    uint8_t v    = rgb_matrix_config.hsv.v;
    RGB     warm;
    RGB     peak;

    if (rgb_matrix_config.hsv.h >= 190) {
        warm = scale_rgb(rgb(0xFF, 0x50, 0xA0), v); // #ff50a0
        peak = scale_rgb(rgb(0x00, 0xC8, 0xFF), v); // #00c8ff
    } else {
        warm = scale_rgb(rgb(0x3D, 0x8E, 0xEC), v); // #3d8eec
        peak = scale_rgb(rgb(0x17, 0x74, 0xE0), v); // #1774e0
    }

    if (amount == 0) {
        return idle;
    }
    if (amount < 70) {
        return mix_rgb(idle, warm, (uint8_t)(amount * 255 / 70));
    }
    return mix_rgb(warm, peak, (uint8_t)((amount - 70) * 255 / 185));
}

void oq_heat_process(uint8_t row, uint8_t col) {
    uint8_t origin = g_led_config.matrix_co[row][col];
    if (origin == NO_LED || origin >= RGB_MATRIX_LED_COUNT) {
        return;
    }

    uint8_t ox = g_led_config.point[origin].x;
    uint8_t oy = g_led_config.point[origin].y;

    for (uint8_t i = 0; i < RGB_MATRIX_LED_COUNT; i++) {
        int16_t  dx   = (int16_t)g_led_config.point[i].x - (int16_t)ox;
        int16_t  dy   = (int16_t)g_led_config.point[i].y - (int16_t)oy;
        uint8_t  dist = sqrt16((uint16_t)(dx * dx + dy * dy));
        uint8_t  add;
        if (i == origin) {
            add = OQ_HEAT_INCREASE;
        } else if (dist <= OQ_HEAT_SPREAD) {
            add = qsub8(OQ_HEAT_SPREAD, dist);
            if (add > OQ_HEAT_AREA_LIMIT) {
                add = OQ_HEAT_AREA_LIMIT;
            }
        } else {
            continue;
        }
        heat[i] = qadd8(heat[i], add);
    }
}

bool oq_heat_render(effect_params_t *params) {
    RGB_MATRIX_USE_LIMITS(led_min, led_max);

    if (params->init) {
        memset(heat, 0, sizeof(heat));
    }

    if (params->iter == 0) {
        decrease_now = timer_elapsed(decrease_timer) >= OQ_HEAT_DECREASE_MS;
        if (decrease_now) {
            decrease_timer = timer_read();
        }
    }

    for (uint8_t i = led_min; i < led_max; i++) {
        RGB_MATRIX_TEST_LED_FLAGS();

        uint8_t val = heat[i];
        RGB     out = heat_color(val);
        rgb_matrix_set_color(i, out.r, out.g, out.b);

        if (decrease_now) {
            heat[i] = qsub8(val, 1);
        }
    }

    return rgb_matrix_check_finished_leds(led_max);
}

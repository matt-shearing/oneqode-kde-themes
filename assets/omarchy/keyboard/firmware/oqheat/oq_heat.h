#pragma once

#include <stdbool.h>
#include <stdint.h>

#include "rgb_matrix.h"

void oq_heat_process(uint8_t row, uint8_t col);
bool oq_heat_render(effect_params_t *params);

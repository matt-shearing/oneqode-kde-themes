RGB_MATRIX_EFFECT(OQ_HEAT)
#ifdef RGB_MATRIX_CUSTOM_EFFECT_IMPLS

#include "oq_heat.h"

bool OQ_HEAT(effect_params_t *params) {
    return oq_heat_render(params);
}

#endif

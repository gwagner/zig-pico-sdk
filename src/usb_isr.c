
#include "tusb_config.h"
void isr_usbctrl(void) {
  tud_int_handler(0);
}

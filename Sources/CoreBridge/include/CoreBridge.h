#ifndef PG_CORE_BRIDGE_H
#define PG_CORE_BRIDGE_H
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
// One active core; all calls must be serialized on the host's emulation thread.
bool pg_open(const char *core_path, const char *rom_path, const char *save_dir);
void pg_close(void);
const char *pg_error(void);
void pg_run(void);
void pg_reset(void);
void pg_set_input(unsigned player, uint16_t mask);
const uint8_t *pg_video(void);
unsigned pg_width(void);
unsigned pg_height(void);
double pg_fps(void);
double pg_sample_rate(void);
const int16_t *pg_audio(void);
size_t pg_audio_frames(void);
#endif

#include "../../vendor/nestopia/libretro/libretro-common/include/libretro.h"
// Fixed-core failure contract: allocations made by load require unload even on rejection.
static int unloads;
int test_unloads(void){return unloads;}
void retro_init(void){} void retro_deinit(void){} void retro_run(void){} void retro_reset(void){}
void retro_unload_game(void){unloads++;}
bool retro_load_game(const struct retro_game_info*g){(void)g;return false;}
void retro_get_system_av_info(struct retro_system_av_info*i){(void)i;}
void retro_set_environment(retro_environment_t c){(void)c;}
void retro_set_video_refresh(retro_video_refresh_t c){(void)c;}
void retro_set_audio_sample(retro_audio_sample_t c){(void)c;}
void retro_set_audio_sample_batch(retro_audio_sample_batch_t c){(void)c;}
void retro_set_input_poll(retro_input_poll_t c){(void)c;}
void retro_set_input_state(retro_input_state_t c){(void)c;}
void retro_set_controller_port_device(unsigned a,unsigned b){(void)a;(void)b;}

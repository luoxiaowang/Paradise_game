#include "CoreBridge.h"
#include "../../vendor/nestopia/libretro/libretro-common/include/libretro.h"
#include <dlfcn.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static void *library;
static bool initialized, loaded, load_attempted;
static char error_text[512], directory[4096];
static uint8_t *rom;
static uint8_t pixels[1024*512*4];
static int16_t samples[8192*2];
static size_t sample_count;
static unsigned width, height, pixel_format;
static uint16_t inputs[2];
static struct retro_system_av_info av;
static char option_keys[160][128], option_values[160][128];
static unsigned option_count;
static void (*core_init)(void), (*core_deinit)(void), (*core_run)(void), (*core_reset)(void), (*core_unload)(void);
static bool (*core_load)(const struct retro_game_info*);
static void (*core_av)(struct retro_system_av_info*);
static void (*set_environment)(retro_environment_t);
static void (*set_video)(retro_video_refresh_t);
static void (*set_audio)(retro_audio_sample_t);
static void (*set_batch)(retro_audio_sample_batch_t);
static void (*set_poll)(retro_input_poll_t);
static void (*set_state)(retro_input_state_t);
static void (*set_controller)(unsigned,unsigned);

static bool environment(unsigned cmd, void *data) {
    switch(cmd) {
    case RETRO_ENVIRONMENT_GET_CAN_DUPE: *(bool*)data=true; return true;
    case RETRO_ENVIRONMENT_SET_PIXEL_FORMAT:
        pixel_format=*(unsigned*)data; return pixel_format<=2;
    case RETRO_ENVIRONMENT_GET_SYSTEM_DIRECTORY:
    case RETRO_ENVIRONMENT_GET_SAVE_DIRECTORY:
    case RETRO_ENVIRONMENT_GET_CORE_ASSETS_DIRECTORY: *(const char**)data=directory; return true;
    case RETRO_ENVIRONMENT_GET_CORE_OPTIONS_VERSION: *(unsigned*)data=0; return true;
    case RETRO_ENVIRONMENT_GET_LANGUAGE: *(unsigned*)data=RETRO_LANGUAGE_ENGLISH; return true;
    case RETRO_ENVIRONMENT_SET_VARIABLES: {
        const struct retro_variable *v=data; option_count=0;
        for(;v && v->key && option_count<160;v++) {
            const char *start=strchr(v->value,';'); if(!start)continue;
            start++; while(*start==' ')start++;
            size_t len=strcspn(start,"|"); if(len>127)len=127;
            snprintf(option_keys[option_count],128,"%s",v->key);
            memcpy(option_values[option_count],start,len); option_values[option_count][len]=0; option_count++;
        } return true;
    }
    case RETRO_ENVIRONMENT_GET_VARIABLE: {
        struct retro_variable *v=data;
        // Preserve all PPU pixels and disable optional visual/audio gameplay changes.
        if(strstr(v->key,"nestopia_overscan_")) { v->value="0"; return true; }
        if(!strcmp(v->key,"nestopia_blargg_ntsc_filter")) {v->value="disabled";return true;}
        if(!strcmp(v->key,"nestopia_favored_system")) {v->value="famicom";return true;}
        if(!strcmp(v->key,"nestopia_aspect")) {v->value="uncorrected";return true;}
        for(unsigned i=0;i<option_count;i++) if(!strcmp(v->key,option_keys[i])) {v->value=option_values[i];return true;}
        v->value=NULL; return false;
    }
    case RETRO_ENVIRONMENT_GET_VARIABLE_UPDATE: *(bool*)data=false; return true;
    case RETRO_ENVIRONMENT_SET_SYSTEM_AV_INFO: av=*(struct retro_system_av_info*)data;return true;
    case RETRO_ENVIRONMENT_SET_GEOMETRY: av.geometry=*(struct retro_game_geometry*)data;return true;
    case RETRO_ENVIRONMENT_SET_INPUT_DESCRIPTORS:
    case RETRO_ENVIRONMENT_SET_CONTROLLER_INFO:
    case RETRO_ENVIRONMENT_SET_SUPPORT_NO_GAME:
    case RETRO_ENVIRONMENT_SET_CORE_OPTIONS_DISPLAY:
    case RETRO_ENVIRONMENT_SET_PERFORMANCE_LEVEL: return true;
    default: return false;
    }
}
static void video(const void *data,unsigned w,unsigned h,size_t pitch) {
    if(!data || w>1024 || h>512)return;
    width=w;height=h;
    for(unsigned y=0;y<h;y++)for(unsigned x=0;x<w;x++) {
        const uint8_t *row=(const uint8_t*)data+y*pitch;
        uint8_t *p=pixels+(y*w+x)*4;
        if(pixel_format==RETRO_PIXEL_FORMAT_XRGB8888) {
            uint32_t c;memcpy(&c,row+x*4,4);p[0]=c>>16;p[1]=c>>8;p[2]=c;
        } else {
            uint16_t c;memcpy(&c,row+x*2,2);
            unsigned r,g,b;
            if(pixel_format==RETRO_PIXEL_FORMAT_RGB565) {r=(c>>11)&31;g=(c>>5)&63;b=c&31;p[1]=(g<<2)|(g>>4);}
            else {r=(c>>10)&31;g=(c>>5)&31;b=c&31;p[1]=(g<<3)|(g>>2);}
            p[0]=(r<<3)|(r>>2);p[2]=(b<<3)|(b>>2);
        } p[3]=255;
    }
}
static size_t audio_batch(const int16_t *data,size_t frames) {
    size_t copy=frames; if(copy>8192-sample_count)copy=8192-sample_count;
    memcpy(samples+sample_count*2,data,copy*2*sizeof(int16_t));sample_count+=copy;return frames;
}
static void audio_sample(int16_t l,int16_t r) { int16_t s[2]={l,r};audio_batch(s,1); }
static void poll(void) {}
static int16_t state(unsigned port,unsigned device,unsigned index,unsigned id) {
    if(port>=2 || device!=RETRO_DEVICE_JOYPAD || index!=0)return 0;
    if(id==RETRO_DEVICE_ID_JOYPAD_MASK)return (int16_t)inputs[port];
    return id<16 && (inputs[port]&(1u<<id)) ? 1:0;
}
void pg_close(void) {
    if(load_attempted && core_unload)core_unload();loaded=false;load_attempted=false;
    if(initialized && core_deinit)core_deinit();initialized=false;
    if(library)dlclose(library);library=NULL;
    free(rom);rom=NULL;inputs[0]=inputs[1]=0;sample_count=0;width=height=0;
}
#define SYMBOL(target,name) do { *(void **)(&target)=dlsym(library,name); if(!target) {snprintf(error_text,sizeof(error_text),"模拟核心缺少接口：%s",name);goto fail;} }while(0)
bool pg_open(const char *core_path,const char *rom_path,const char *save_dir) {
    pg_close();error_text[0]=0;option_count=0;pixel_format=0;memset(&av,0,sizeof(av));
    snprintf(directory,sizeof(directory),"%s",save_dir);
    FILE *f=fopen(rom_path,"rb");
    if(!f){snprintf(error_text,sizeof(error_text),"无法读取游戏文件");return false;}
    fseek(f,0,SEEK_END);long size=ftell(f);rewind(f);
    if(size<16 || size>32*1024*1024){fclose(f);snprintf(error_text,sizeof(error_text),"游戏文件大小无效");return false;}
    rom=malloc((size_t)size);
    if(!rom){fclose(f);snprintf(error_text,sizeof(error_text),"内存不足");return false;}
    size_t read=fread(rom,1,(size_t)size,f);fclose(f);
    size_t required=16+(rom[6]&4?512:0)+(size_t)rom[4]*16384+(size_t)rom[5]*8192;
    if(read!=(size_t)size || memcmp(rom,"NES\x1a",4) || !rom[4] || (rom[7]&12)==8 || required!=(size_t)size) {snprintf(error_text,sizeof(error_text),"不是完整的 iNES 游戏文件");goto fail;}
    library=dlopen(core_path,RTLD_NOW|RTLD_LOCAL);
    if(!library){snprintf(error_text,sizeof(error_text),"无法加载模拟核心：%.350s",dlerror());goto fail;}
    SYMBOL(core_init,"retro_init");SYMBOL(core_deinit,"retro_deinit");SYMBOL(core_run,"retro_run");SYMBOL(core_reset,"retro_reset");
    SYMBOL(core_load,"retro_load_game");SYMBOL(core_unload,"retro_unload_game");SYMBOL(core_av,"retro_get_system_av_info");
    SYMBOL(set_environment,"retro_set_environment");SYMBOL(set_video,"retro_set_video_refresh");
    SYMBOL(set_audio,"retro_set_audio_sample");SYMBOL(set_batch,"retro_set_audio_sample_batch");
    SYMBOL(set_poll,"retro_set_input_poll");SYMBOL(set_state,"retro_set_input_state");SYMBOL(set_controller,"retro_set_controller_port_device");
    set_environment(environment);set_video(video);set_audio(audio_sample);set_batch(audio_batch);set_poll(poll);set_state(state);
    core_init();initialized=true;
    struct retro_game_info info={rom_path,rom,(size_t)size,NULL};
    load_attempted=true; // Nestopia allocates before validating the mapper.
    if(!core_load(&info)){snprintf(error_text,sizeof(error_text),"模拟核心无法运行此游戏");goto fail;}
    loaded=true;set_controller(0,RETRO_DEVICE_JOYPAD);set_controller(1,RETRO_DEVICE_JOYPAD);core_av(&av);
    if(av.timing.fps<1 || av.timing.fps>240 || av.timing.sample_rate<8000 || av.timing.sample_rate>192000) {snprintf(error_text,sizeof(error_text),"核心返回了无效的音视频时序");goto fail;}
    return true;
fail: pg_close();return false;
}
const char *pg_error(void){return error_text;}
void pg_run(void){sample_count=0;if(loaded)core_run();}
void pg_reset(void){inputs[0]=inputs[1]=0;sample_count=0;if(loaded)core_reset();}
void pg_set_input(unsigned player,uint16_t mask){if(player<2)inputs[player]=mask;}
const uint8_t *pg_video(void){return pixels;}
unsigned pg_width(void){return width;}
unsigned pg_height(void){return height;}
double pg_fps(void){return av.timing.fps;}
double pg_sample_rate(void){return av.timing.sample_rate;}
const int16_t *pg_audio(void){return samples;}
size_t pg_audio_frames(void){return sample_count;}

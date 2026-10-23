#include "CoreBridge.h"
#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
static void wait_frames(int n){for(int i=0;i<n;i++)pg_run();}
static void press(unsigned player,unsigned mask){pg_set_input(player,mask);wait_frames(1);pg_set_input(player,0);wait_frames(12);}
static void frame(const char *path) {
    FILE *f=fopen(path,"wb"); assert(f);
    fprintf(f,"P6\n%u %u\n255\n",pg_width(),pg_height());
    const unsigned char *p=pg_video();
    for(unsigned i=0;i<pg_width()*pg_height();i++) fwrite(p+i*4,1,3,f);
    fclose(f);
}
static void start_game(int players){
    wait_frames(600); // original mode menu
    press(0,1<<3);wait_frames(600); // title entrance animation
    if(players==2)press(0,1<<2); // original SELECT changes player count
    frame(players==2?"artifacts/two-player-title.ppm":"artifacts/one-player-title.ppm");
    press(0,1<<3);wait_frames(300); // stage selector
    press(0,1<<3); // confirm stage
}
int main(int argc,char**argv) {
    assert(argc==4);
    assert(!pg_open("/missing",argv[2],argv[3])); pg_close(); pg_close();
    assert(!pg_open(argv[1],"/missing",argv[3]));
    assert(pg_open(argv[1],argv[2],argv[3]));
    assert(pg_fps()>59 && pg_fps()<61); assert(pg_sample_rate()==48000);
    wait_frames(600); assert(pg_width()==256 && pg_height()==240); frame("artifacts/title.ppm");
    pg_close();assert(pg_open(argv[1],argv[2],argv[3]));start_game(1);
    long nonzero=0;FILE *audio=fopen("artifacts/game-audio.s16le","wb");
    for(int i=0;i<180;i++) { pg_run();size_t n=pg_audio_frames();const short*p=pg_audio();for(size_t j=0;j<n*2;j++)nonzero+=(p[j]!=0);fwrite(p,sizeof(short),n*2,audio); }
    fclose(audio);frame("artifacts/single-player.ppm");
    assert(nonzero>100);
    pg_close();assert(pg_open(argv[1],argv[2],argv[3]));start_game(2);wait_frames(180);frame("artifacts/two-player.ppm");
    pg_set_input(0,(1<<4)|(1<<8));pg_set_input(1,(1<<7)|(1<<8));wait_frames(120);frame("artifacts/two-player-moving.ppm");
    pg_close();pg_close();assert(pg_open(argv[1],argv[2],argv[3]));pg_run();pg_close();
    printf("PASS: failures, video 256x240, audio 48 kHz (nonzero samples=%ld), single/two-player input sequences, reopen\n",nonzero);
}

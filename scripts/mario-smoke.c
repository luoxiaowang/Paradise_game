#include "CoreBridge.h"
#include <assert.h>
#include <stdio.h>
static void run(int n){while(n--)pg_run();}
static void press(int mask){pg_set_input(0,mask);run(2);pg_set_input(0,0);run(10);}
static void frame(const char *name){FILE*f=fopen(name,"wb");assert(f);fprintf(f,"P6\n%u %u\n255\n",pg_width(),pg_height());const unsigned char*p=pg_video();for(unsigned i=0;i<pg_width()*pg_height();i++)fwrite(p+i*4,1,3,f);fclose(f);}
int main(int argc,char**argv){assert(argc==5);
 assert(pg_open(argv[1],argv[2],argv[4]));run(180);frame("artifacts/mario-title.ppm");assert(pg_width()==256&&pg_height()==240);assert(pg_fps()>59&&pg_fps()<61);
 press(1<<3);run(160);frame("artifacts/mario-level.ppm");
 long nonzero=0;for(int i=0;i<120;i++){pg_run();for(size_t j=0;j<pg_audio_frames()*2;j++)nonzero+=pg_audio()[j]!=0;}assert(nonzero>100);
 pg_set_input(0,(1<<7)|(1<<8)|1);run(20);frame("artifacts/mario-jump.ppm");pg_set_input(0,0);
 pg_close();assert(pg_open(argv[1],argv[2],argv[4]));run(180);press(1<<2);frame("artifacts/mario-two-menu.ppm");press(1<<3);run(160);pg_set_input(0,1<<7);run(220);pg_set_input(0,0);run(480);frame("artifacts/mario-luigi.ppm");
 pg_set_input(1,(1<<7)|(1<<8));run(20);frame("artifacts/mario-luigi-jump.ppm");pg_close();
 assert(pg_open(argv[1],argv[3],argv[4]));run(180);pg_close();assert(pg_open(argv[1],argv[2],argv[4]));run(180);pg_close();
 printf("PASS: Mario NTSC video/audio (%ld nonzero samples), input and two-player sequences, Mario/Tank/Mario reload\n",nonzero);
}

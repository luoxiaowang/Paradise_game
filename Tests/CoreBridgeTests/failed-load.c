#include "CoreBridge.h"
#include <dlfcn.h>
#include <assert.h>
#include <stdio.h>
int main(int c,char**v){
    assert(c==3);void*h=dlopen(v[1],RTLD_NOW|RTLD_LOCAL);assert(h);
    int(*unloads)(void)=dlsym(h,"test_unloads");assert(unloads);
    assert(!pg_open(v[1],v[2],"/tmp"));
    assert(unloads()==1);pg_close();assert(unloads()==1);
    dlclose(h);puts("PASS: rejected load cleans partially initialized core exactly once");
}

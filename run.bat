@echo off

copy io.sys %temp%

qemu-system-x86_64 -drive format=raw,file=%temp%\io.sys


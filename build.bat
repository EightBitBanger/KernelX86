@echo off

echo Compiling assembly...

nasm -f bin src\boot.asm -o obj\boot.bin
nasm -f bin src\kernel.asm -o obj\kernel.bin

echo.
echo Linking...
echo.

copy /b obj\boot.bin + obj\kernel.bin io.sys


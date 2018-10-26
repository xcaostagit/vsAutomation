@echo off
if "%ANDROID_NDK%"=="" goto :eof
set T64=%ANDROID_NDK%\toolchains\aarch64-linux-android-4.9\prebuilt\windows-x86_64\aarch64-linux-android\bin
set T32=%ANDROID_NDK%\toolchains\arm-linux-androideabi-4.9\prebuilt\windows-x86_64\arm-linux-androideabi\bin

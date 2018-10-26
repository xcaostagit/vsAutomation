@echo off
REM https://ibotpeaches.github.io/Apktool/documentation/#framework-files

setlocal

if "%1"=="" CALL :syntax %0
if NOT EXIST "%1" CALL :fatal Missing file %1

if not "%2"=="" GOTO :start
if not exist candidates\NUL CALL :fatal Nothing to be done

:start

if "%ANDROID_HOME%"=="" CALL :fatal ANDROID_HOME must be set to the android SDK root folder!
if "%JAVA_HOME%"   =="" CALL :fatal JAVA_HOME mus tbe set to the JDK and JRE root folder (ensure JAVA version ^>= 8)

call :getToolVersion
if "%vers%"=="" CALL :fatal build tools missing!

set PATH=%~dp0\bin;%ANDROID_HOME%\build-tools\%vers%;%JAVA_HOME%\bin;C:\Windows\System32;%PATH%
rem echo PATH set to %PATH%

if exist tmp\NUL rd /s/q tmp
md tmp

if exist generated\NUL rd /s/q generated
md generated

if "%2"=="" GOTO :dm_done
if NOT EXIST "%2" CALL :fatal Missing file %2

call unzip -d tmp\dm %2 *.so

FOR /F "tokens=*" %%g IN ('dir/s/b/a-d *.so^| findstr armeabi   ^| sed "s#/#\\#g#"') do (SET so32=%%g)
FOR /F "tokens=*" %%g IN ('dir/s/b/a-d *.so^| findstr arm64-v8a ^| sed "s#/#\\#g#"') do (SET so64=%%g)
if NOT EXIST %so32% CALL :fatal File %so32% does not exist
if NOT EXIST %so64% CALL :fatal File %so64% does not exist

call xcopy /Y %so32% candidates\lib\armeabi-v7a\
call xcopy /Y %so64% candidates\lib\arm64-v8a\

:dm_done
if exist "%UserProfile%\AppData\Local\apktool\NUL" rd /s/q %UserProfile%\AppData\Local\apktool

FOR /F "tokens=*" %%g IN ('echo %1^| sed "s#/#\\#g" ^| sed "s#.*\\##g"') do (SET outname=%%g)
rem echo outname is "%outname%"

call apktool if %1
rem call apktool d -o tmp\vs %1
call apktool d -r -s -o tmp\vs %1

REM ---------------------------------------------------------------------------------------------
REM now update VS lib folder with the latest DM library files, or replace anything inside tmp\vs
REM ---------------------------------------------------------------------------------------------
if exist candidates\NUL call xcopy /s/e/Y candidates\* tmp\vs\

for %%f in (CERT.RSA CERT.SF MANIFEST.MF) do if exist tmp\vs\original\META-INF\%%f del tmp\vs\original\META-INF\%%f
if exist tmp\vs\original\META-INF\NUL move tmp\vs\original\META-INF tmp\vs\

call apktool b -o tmp\%outname% tmp\vs
call zipalign -v 4 tmp\%outname% tmp\aligned-%outname%

rem keytool -genkey -v -keystore mps-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias CERT
rem PASSWORD=samsung

echo ********************************* calling apksigner *********************************
echo WARNING ************ WARNING ************ WARNING ************ WARNING ************
echo If the following line gets stuck for a long time it may be because the find_java.bat file, which is
echo called by apksigner.bat, is stuck at the "reg query" command. (Samsung IT blocks "reg query" )
echo In this case simply change the lines inside apksigner to not call find_java.bat but directly set
echo java_exe to java.exe.
echo WARNING ************ WARNING ************ WARNING ************ WARNING ************
echo apksigner sign --ks mps-release-key.jks --out generated\signed-%outname% tmp\aligned-%outname%
echo When prompted, enter the password 'samsung' (without quotes).
call  %ANDROID_HOME%\build-tools\%vers%\apksigner.bat sign --ks mps-release-key.jks --out generated\signed-%outname% tmp\aligned-%outname%

GOTO :eof

:getToolVersion
set vers=
for /L %%a in (20,1,30) do for /L %%b in (0,1,20) do for /L %%c in (0,1,50) do if exist %ANDROID_HOME%\build-tools\%%a.%%b.%%c\NUL set vers=%%a.%%b.%%c
echo build tool version is %vers%
GOTO :eof

:: function syntax
:syntax
echo syntax: %* ^<VS-Apk-File^> ^<DM-Zip-File^>
GOTO :end

:fatal
echo Fatal error: %*
GOTO :end

:end
rem Creates a syntax error, stops immediately
 (GOTO) 2>nul & endlocal & exit /b %ERRORLEVEL%
GOTO :eof

@echo off
setlocal

set ROOT=%~dp0..
pushd "%ROOT%"

echo === Compiling main process (main.debug.hxml) ===
haxe main.debug.hxml
if errorlevel 1 (
    echo Main process compile failed.
    popd
    exit /b 1
)

echo === Compiling renderer (renderer.debug.hxml) ===
haxe renderer.debug.hxml
if errorlevel 1 (
    echo Renderer compile failed.
    popd
    exit /b 1
)

popd

echo === Starting LDtk ===
cd /d "%~dp0"
call npm run start

endlocal

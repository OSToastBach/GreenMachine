@echo off
set file=fieldscroller

echo Assembling...
asm6809.exe -D %file%.asm -o DGNTRO.BIN
if errorlevel 1 goto end
echo Creating Disk Image...
dragondos.exe delete fieldfx.vdk DGNTRO.BIN
dragondos.exe write fieldfx.vdk DGNTRO.BIN
echo Booting Emulator...
xroar.exe -vo sdl -default-machine dragon32 -extbas D:\CODEDEV\Dragon-32\xroar-0.36.2-w64\D32.rom -nodos -kbd-translate -run DGNTRO.BIN
:end
@echo off
set file=sideb

echo Assembling...
asm6809.exe -D %file%.asm -o sideb.BIN
if errorlevel 1 goto en
echo Creating Disk Image...
dragondos.exe delete sideb.vdk sideb.BIN
dragondos.exe write sideb.vdk sideb.BIN
echo Booting Emulator...
xroar.exe -vo sdl -default-machine dragon32 -extbas D:\CODEDEV\Dragon-32\xroar-0.36.2-w64\D32.rom -nodos -kbd-translate -run sideb.BIN
:end
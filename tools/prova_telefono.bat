@echo off
rem Prova CHEAP come se fosse un telefono, sul PC: finestra 20:9, comandi touch, il mouse fa da dito.
set GODOT=C:\Users\linda\Documents\app\godot2\Godot_v4.6.3-stable_win64.exe\Godot_v4.6.3-stable_win64.exe
start "" "%GODOT%" --path "%~dp0.." --resolution 1200x540 -- --touch

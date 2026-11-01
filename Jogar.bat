@echo off
rem Abre o Focus Town RPG direto, sem abrir o editor do Godot (Windows).
rem Troque o caminho abaixo pelo do seu Godot.exe.
cd /d "%~dp0"
"C:\Godot\Godot.exe" --path .

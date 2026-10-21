@echo off
REM Verificacao completa do projecto GymRank no Windows (sem Xcode).
REM Compilar e correr no simulador e feito no CI (GitHub Actions).
cd /d "%~dp0"
echo === 1/3 standards -> Swift ===
python Tools\gen_standards_swift.py
if errorlevel 1 goto erro
echo.
echo === 2/3 project.pbxproj (regenera a partir dos ficheiros no disco) ===
python Tools\gen_pbxproj.py
if errorlevel 1 goto erro
echo.
echo === 3/3 verificacoes estruturais ===
python Tools\verify_project.py
if errorlevel 1 goto erro
echo.
echo TUDO VERIFICADO. Para compilar/testar no simulador: git push e ver o workflow no GitHub Actions.
goto fim
:erro
echo.
echo FALHOU uma das etapas acima.
:fim
pause

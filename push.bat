@echo off
echo ============================================================
echo   Pushing ONE Simulator to GitHub (branch: main)
echo   Target: https://github.com/RaushanShrivastwa/DTN_Simulation.git
echo ============================================================
echo.
git push -u origin main
echo.
echo ============================================================
if %ERRORLEVEL% equ 0 (
    echo Push succeeded!
) else (
    echo Push encountered an error. Check authentication above.
)
echo ============================================================
pause

@echo off
echo ========================================================
echo       HOPAL - Building Web Version for Netlify
echo ========================================================
echo.
echo Step 1: Building the app (this might take a minute)...
call flutter build web

echo.
echo Step 2: Zipping the files for Netlify...
if exist MedicApp_Web.zip del MedicApp_Web.zip
cd build\web
tar -a -c -f ..\..\MedicApp_Web.zip *
cd ..\..

echo.
echo ========================================================
echo SUCCESS! 
echo The file 'MedicApp_Web.zip' has been created/updated.
echo.
echo All you need to do now is:
echo 1. Go to netlify.com and log in.
echo 2. Go to your site's "Deploys" tab.
echo 3. Drag and drop the 'MedicApp_Web.zip' file there.
echo.
echo Your phone and all other medics will update automatically!
echo ========================================================
pause

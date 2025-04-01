@echo off
if "%1"=="-help" goto print_help
if "%1"=="--help" goto print_help
if "%1"=="" goto print_help
goto normal_start

:print_help
echo Parameter one is environment (dev ^| prod)
echo Parameter two sets an alternate AWS profile (e.g., default)
echo Example: tfinit dev
echo Example: tfinit prod
echo Example: tfinit dev default
goto end

:normal_start
cls
set env=%1
if "%2"=="" set AWS_PROFILE=%env%
if not "%2"=="" set AWS_PROFILE=%2
echo Your active AWS profile is: %AWS_PROFILE%
set bucket=%env%.sdc.dot.gov.platform.terraform
if "%env%"=="dev" (set options=-upgrade -reconfigure) else (set options=-reconfigure)
set command=terraform init -backend-config "bucket=%bucket%" %options%
echo.
echo %command%
echo.
echo Would you like to execute the above command to initialize Terraform?
echo Press Y for Yes, or C to Cancel.
CHOICE /N /C YC /T 15 /D C
if "%ERRORLEVEL%"=="1" goto execute
if "%ERRORLEVEL%"=="2" goto no_execute
goto end

:execute
pushd ..\terraform
%command%
echo.
echo Terraform will now validate the configuration:
terraform validate
popd ..\scripts
goto end

:no_execute
echo Initialization of Terraform has been canceled.
goto end

:end

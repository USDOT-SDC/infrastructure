@echo off
if "%1"=="-help" goto print_help
if "%1"=="--help" goto print_help
goto normal_start

:print_help
echo Terraform must be initialized (tfinit.cmd) before running tfplan.cmd
goto end

:normal_start
cls
set /P config_version=< ..\terraform\config_version.txt
set plan_id_file=..\terraform\tfplans\%config_version%_%env%_.txt
if exist "%plan_id_file%" (
    set /p plan_id=< "%plan_id_file%"
) else (
    set plan_id=0
)
set /a plan_id+=1
set plan_file="tfplans/%config_version%_%env%_%plan_id%"
set command=terraform plan -var=config_version="%config_version%" -var-file="env_vars/%env%.tfvars" -out=%plan_file%
echo Your active AWS profile is: %AWS_PROFILE%
echo.
echo %command%
echo.
echo Would you like to execute the above command to create a Terraform execution plan?
echo Press Y for Yes, or C to Cancel.
CHOICE /N /C YC /T 15 /D C
if "%ERRORLEVEL%"=="1" goto execute
if "%ERRORLEVEL%"=="2" goto no_execute
goto end

:execute
pushd ..\terraform
if not exist "tfplans" mkdir tfplans
%command%
popd ..\scripts
(echo %plan_id%) > %plan_id_file%
goto end

:no_execute
echo Execution of %command% has been canceled.
goto end

:end

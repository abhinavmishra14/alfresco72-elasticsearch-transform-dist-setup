@echo off

ECHO ################ Stopping ACS, DB, Transformation Service and Elastic Search Services ##############
ECHO.

SET ALF_INSTALL_PATH=%1
SET ALF_SE_INSTALL_PATH=%2
SET POSTGRES_INSTALL_PATH=%3
SET ELASTIC_INSTALL_PATH=%4

:init
	IF "%~1" == "" (
	   SET ALF_INSTALL_PATH=C:\\alfresco72-enterprise
	)
	
	IF "%~2" == "" (
		SET ALF_SE_INSTALL_PATH=C:\\alfresco-elastic-search-services
	)
	
	IF "%~3" == "" (
		SET POSTGRES_INSTALL_PATH=C:\\PostgreSQL\\13
	)
	
	IF "%~4" == "" (
		SET ELASTIC_INSTALL_PATH=C:\\elasticsearch-7.10.1
	)
	
	goto stopTrServ

:stopTrServ
    echo.
	echo Stopping transformation service ...
	taskkill /fi "WINDOWTITLE eq sfsController"
	taskkill /fi "WINDOWTITLE eq transformationService"
	taskkill /fi "WINDOWTITLE eq trRouter"
	if errorlevel 1 (goto end) else (goto stopACS)
	
:stopACS
	echo.
	echo Stopping ACS from %ALF_INSTALL_PATH% ...
	SET CATALINA_HOME=%ALF_INSTALL_PATH%\tomcat
	start /MIN /WAIT cmd /c %ALF_INSTALL_PATH%\tomcat\bin\catalina.bat stop
	taskkill /fi "WINDOWTITLE eq Tomcat"
	taskkill /F /IM soffice.bin
	if errorlevel 1 (goto end) else (goto stopDB)

:stopDB
	echo.
	echo Stopping DB from %POSTGRES_INSTALL_PATH% ...
	:: Using the windows service to stop the db.
	:: net stop postgresql-x64-13
	REM You can also use this command, if there is any issue with permission elevation on windows
	%POSTGRES_INSTALL_PATH%\bin\pg_ctl.exe stop -D "%POSTGRES_INSTALL_PATH%\data"
	if errorlevel 1 (goto end) else (goto stopElasticConnectorApps)
	
:stopElasticConnectorApps
	echo.
	echo Stopping alfresco re-indexing and live indexing apps...
	taskkill /fi "WINDOWTITLE eq reindexingService"
	taskkill /fi "WINDOWTITLE eq liveIdexingService"
	if errorlevel 1 (goto end) else (goto stopAMQLocal)

:stopAMQLocal
    echo.
	echo Stopping Active MQ service ...
	taskkill /F /IM wrapper.exe
	taskkill /fi "WINDOWTITLE eq ActiveMQ"
    if errorlevel 1 (goto end) else (goto stopElasticServer)
	
:stopElasticServer
	echo.
	taskkill /fi "WINDOWTITLE eq ElasticServer"
	if errorlevel 1 (goto end)
	
:end
	echo.
    echo Exiting..
	timeout 10
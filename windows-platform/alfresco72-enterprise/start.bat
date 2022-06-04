@echo off

ECHO ################ Starting ACS, DB, Transformation Service and Elastic Search Services ##############
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

	goto startAMQLocal

:startAMQLocal
    echo.
	echo Starting Active MQ service...
	
	start "ActiveMQ" /MIN cmd /c %ALF_INSTALL_PATH%\activemq\bin\win64\activemq.bat start
	timeout 10
    if errorlevel 1 (goto end) else (goto startTrServ)
	
	
:startTrServ
    echo.
	echo Starting core transformation service...

	start "transformationService" java -DPDFRENDERER_EXE="%ALF_INSTALL_PATH%\\alfresco-pdf-renderer\\alfresco-pdf-renderer.exe"^
		-DLIBREOFFICE_HOME="%ALF_INSTALL_PATH%\\libreoffice"^
		-DIMAGEMAGICK_ROOT="%ALF_INSTALL_PATH%\\imagemagick"^
		-DIMAGEMAGICK_DYN="%ALF_INSTALL_PATH%\\imagemagick\\lib"^
		-DIMAGEMAGICK_CODERS="%ALF_INSTALL_PATH%\\imagemagick\\modules\\coders"^
		-DIMAGEMAGICK_CONFIG="%ALF_INSTALL_PATH%\\imagemagick"^
		-DIMAGEMAGICK_EXE="%ALF_INSTALL_PATH%\\imagemagick\\convert.exe"^
		-DACTIVEMQ_URL=tcp://localhost:61616^
		-jar %ALF_INSTALL_PATH%\\bin\\alfresco-transform-core-aio-boot-2.6.0.jar
		
	timeout 50
    if errorlevel 1 (goto end) else (goto startTrRouter)
	
:startTrRouter
	echo.
	echo Starting transform router service...
	
    start "trRouter" java -DCORE_AIO_URL=http://localhost:8090 ^
		-DCORE_AIO_QUEUE=org.alfresco.transform.engine.aio.acs ^
		-DACTIVEMQ_URL=tcp://localhost:61616 ^
		-DFILE_STORE_URL=http://localhost:8099/alfresco/api/-default-/private/sfs/versions/1/file ^
		-jar %ALF_INSTALL_PATH%\\bin\\alfresco-transform-router-1.5.3.jar
		
	timeout 50
    if errorlevel 1 (goto end) else (goto startSharedFileStore)
	
:startSharedFileStore
	echo.
	echo Starting shared file store controller service...
	
	start "sfsController" java -DfileStorePath=%ALF_INSTALL_PATH%\shared-file-store ^
		  -Dscheduler.contract.path=%ALF_INSTALL_PATH%\shared-file-store-scheduler-location\scheduler.json ^
		  -jar %ALF_INSTALL_PATH%\bin\alfresco-shared-file-store-controller-1.5.3.jar
		  
	timeout 10
    if errorlevel 1 (goto end) else (goto startDB)
	
:startDB
	echo.
	echo Starting DB...
	:: Using the windows service to start the db.
	:: net start postgresql-x64-13
	REM You can also use this command, if there is any issue with permission elevation on windows
	%POSTGRES_INSTALL_PATH%\bin\pg_ctl.exe restart -D "%POSTGRES_INSTALL_PATH%\data"
	timeout 20
	if errorlevel 1 (goto end) else (goto startElasticServer)
	
:startElasticServer
	echo.
	echo Starting elastic search server...
	
	start "ElasticServer" /MIN cmd /c %ELASTIC_INSTALL_PATH%\bin\elasticsearch.bat
	timeout 60
	if errorlevel 1 (goto end) else (goto startACS)

:startACS
	echo.
	echo Starting ACS...
	
	SET CATALINA_HOME=%ALF_INSTALL_PATH%\tomcat
	start "Tomcat" /MIN /WAIT cmd /c %ALF_INSTALL_PATH%\tomcat\bin\catalina.bat start 
	timeout 250
	if errorlevel 1 (goto end) else (goto startElasticliveIndexingApp)
	
:startElasticliveIndexingApp
	echo.
	echo Starting alfresco live indexing app...
	
	start "liveIdexingService" java -jar %ALF_SE_INSTALL_PATH%\\alfresco-elasticsearch-live-indexing-3.1.1-app.jar ^
		--server.port=8083 ^
		--spring.activemq.broker-url=nio://localhost:61616 ^
		--spring.elasticsearch.rest.uris=http://localhost:9200 ^
		--alfresco.sharedFileStore.baseUrl=http://localhost:8099/alfresco/api/-default-/private/sfs/versions/1/file/ ^
		--alfresco.acceptedContentMediaTypesCache.baseurl=http://localhost:8090/transform/config ^
		--elasticsearch.indexName=alfresco
		
	timeout 60	
	if errorlevel 1 (goto end) else (goto startElasticReindexingApp)
	
:startElasticReindexingApp
	echo.
	echo Starting alfresco re-indexing app...
	
	start "reindexingService" java -jar %ALF_SE_INSTALL_PATH%\\alfresco-elasticsearch-reindexing-3.1.1-app.jar ^
		--alfresco.reindex.jobName=reindexByIds ^
		--spring.elasticsearch.rest.uris=http://localhost:9200 ^
		--spring.datasource.url=jdbc:postgresql://localhost:5432/alfresco ^
		--spring.datasource.username=alfresco ^
		--spring.datasource.password=alfresco ^
		--spring.activemq.broker-url=tcp://localhost:61616?jms.useAsyncSend=true ^
		--alfresco.reindex.prefixes-file=file:%ALF_SE_INSTALL_PATH%\\reindex.prefixes-file.json
		
	timeout 10
	if errorlevel 1 (goto end)

:end
	echo.
    echo Exiting..
	timeout 10
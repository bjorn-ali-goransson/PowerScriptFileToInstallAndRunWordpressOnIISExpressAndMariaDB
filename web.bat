cd /D "%~dp0"

SET IIS_DIR=C:\Program Files (x86)\IIS Express
SET PHP_DIR=%cd%\php

if not exist "%cd%\applicationHost.config" (
    copy "%IIS_DIR%\AppServer\applicationHost.config" "applicationHost.config"
    "%IIS_DIR%\appcmd" set config /section:system.webServer/fastCGI /+[fullPath='%PHP_DIR%\php-cgi.exe'] /apphostconfig:"%cd%\applicationHost.config"
    "%IIS_DIR%\appcmd" set config /section:system.webServer/handlers /+[name='PHP_via_FastCGI',path='*.php',verb='*',modules='FastCgiModule',scriptProcessor='%PHP_DIR%\php-cgi.exe',resourceType='Unspecified'] /apphostconfig:"%cd%\applicationHost.config"
    rem "%IIS_DIR%\appcmd" list site /text:name <-- use this on the following line to delete the default site!
    "%IIS_DIR%\appcmd" delete site "Development Web Site" /apphostconfig:"%cd%\applicationHost.config"
    "%IIS_DIR%\appcmd" add site /name:"Website" /physicalPath:"%cd%\web" /bindings:http/:8080:localhost /apphostconfig:"%cd%\applicationHost.config"

    "%IIS_DIR%\appcmd" set config -section:system.webServer/rewrite/rules /+"[name='Wordpress_Rewrite',stopProcessing='True']" /apphostconfig:"%cd%\applicationHost.config"
    "%IIS_DIR%\appcmd" set config -section:system.webServer/rewrite/rules /[name='Wordpress_Rewrite'].match.url:"(.*)" /apphostconfig:"%cd%\applicationHost.config"
    "%IIS_DIR%\appcmd" set config -section:system.webServer/rewrite/rules /[name='Wordpress_Rewrite'].conditions.logicalGrouping:"MatchAll" /apphostconfig:"%cd%\applicationHost.config"
    "%IIS_DIR%\appcmd" set config -section:system.webServer/rewrite/rules /+[name='Wordpress_Rewrite'].conditions.[input='{REQUEST_FILENAME}',matchType='IsFile',negate='true'] /apphostconfig:"%cd%\applicationHost.config"
    "%IIS_DIR%\appcmd" set config -section:system.webServer/rewrite/rules /+[name='Wordpress_Rewrite'].conditions.[input='{REQUEST_FILENAME}',matchType='IsDirectory',negate='true'] /apphostconfig:"%cd%\applicationHost.config"
    "%IIS_DIR%\appcmd" set config -section:system.webServer/rewrite/rules /[name='Wordpress_Rewrite'].action.type:"Rewrite" /apphostconfig:"%cd%\applicationHost.config"
    "%IIS_DIR%\appcmd" set config -section:system.webServer/rewrite/rules /[name='Wordpress_Rewrite'].action.url:"index.php" /apphostconfig:"%cd%\applicationHost.config"
)

start "Web server" "%IIS_DIR%\iisexpress.exe" /config:"%cd%\applicationHost.config"

start "" http://localhost:8080/test.php
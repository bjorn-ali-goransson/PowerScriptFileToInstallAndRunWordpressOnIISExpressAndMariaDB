$cd = $PSScriptRoot

$iisdir = "C:\Program Files (x86)\IIS Express"
$phpdir = "$cd\php"

$appcmd = "$iisdir\appcmd.exe"

if (!(Test-Path "$cd\applicationHost.config")) {
    Copy "$iisdir\AppServer\applicationHost.config" "applicationHost.config"

    & $appcmd "set" "config" "/section:system.webServer/fastCGI" "/+[fullPath='$phpdir\php-cgi.exe']" "/apphostconfig:""$cd\applicationHost.config"""
    & $appcmd "set" "config" "/section:system.webServer/handlers" "/+[name='PHP_via_FastCGI',path='*.php',verb='*',modules='FastCgiModule',scriptProcessor='$phpdir\php-cgi.exe',resourceType='Unspecified']" "/apphostconfig:""$cd\applicationHost.config"""

    $sites = & $appcmd "list" "site" "/text:name" "/apphostconfig:""$cd\applicationHost.config"""

    foreach( $line in $sites ){
        $sitename = $line.Trim()
        & $appcmd "delete" "site" $sitename "/apphostconfig:""$cd\applicationHost.config"""
    }

    & $appcmd "add" "site" "/name:""Website""" "/physicalPath:""$cd\web""" "/bindings:http/:8080:localhost" "/apphostconfig:""$cd\applicationHost.config"""
    
    & $appcmd "set" "config" "-section:system.webServer/rewrite/rules" "/+""[name='Wordpress_Rewrite',stopProcessing='True']""" "/apphostconfig:""$cd\applicationHost.config"""
    & $appcmd "set" "config" "-section:system.webServer/rewrite/rules" "/[name='Wordpress_Rewrite'].match.url:""(.*)""" "/apphostconfig:""$cd\applicationHost.config"""
    & $appcmd "set" "config" "-section:system.webServer/rewrite/rules" "/[name='Wordpress_Rewrite'].conditions.logicalGrouping:""MatchAll""" "/apphostconfig:""$cd\applicationHost.config"""
    & $appcmd "set" "config" "-section:system.webServer/rewrite/rules" "/+[name='Wordpress_Rewrite'].conditions.[input='{REQUEST_FILENAME}',matchType='IsFile',negate='true']" "/apphostconfig:""$cd\applicationHost.config"""
    & $appcmd "set" "config" "-section:system.webServer/rewrite/rules" "/+[name='Wordpress_Rewrite'].conditions.[input='{REQUEST_FILENAME}',matchType='IsDirectory',negate='true']" "/apphostconfig:""$cd\applicationHost.config"""
    & $appcmd "set" "config" "-section:system.webServer/rewrite/rules" "/[name='Wordpress_Rewrite'].action.type:""Rewrite""" "/apphostconfig:""$cd\applicationHost.config"""
    & $appcmd "set" "config" "-section:system.webServer/rewrite/rules" "/[name='Wordpress_Rewrite'].action.url:""index.php""" "/apphostconfig:""$cd\applicationHost.config"""
}

# start "Web server" "$iisdir\iisexpress.exe" /config:"%cd%\applicationHost.config"
# start "" http://localhost:8080/test.php
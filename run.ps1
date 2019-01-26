$cd = $PSScriptRoot

# TODO: Install IIS Express, URL Rewrite

$phpdir = "$cd\php"

if (!(Test-Path "$cd\php.ini")) {
    "extension_dir = ""ext""" | Set-Content "$cd\php.ini"

    "extension=mysqli" | Add-Content "$cd\php.ini"
    "extension=mbstring" | Add-Content "$cd\php.ini"
    "extension=mcrypt" | Add-Content "$cd\php.ini"
    
    "" | Add-Content "$cd\php.ini"

    Get-Content "$phpdir\php.ini-development" | Add-Content "$cd\php.ini"
}

# Follow recommendations here
# Install wincache ? https://www.saotn.org/php-wincache-on-iis/
# https://docs.microsoft.com/en-us/iis/application-frameworks/install-and-configure-php-on-iis/install-and-configure-mysql-for-php-applications-on-iis-7-and-above#configure-php-to-access-mysql

$dbdir = "$cd\mariadb"

# TODO: Create DB
# $conn = new mysqli('localhost', 'root', ''); if (mysqli_connect_errno()) { exit('Connect failed: '. mysqli_connect_error()); } $sql = 'CREATE DATABASE `wptest` DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci'; if ($conn->query($sql) === TRUE) { echo 'Database created successfully'; } else { echo 'Error creating database: ' . $conn->error; } $conn->close();

$iisdir = "C:\Program Files (x86)\IIS Express"
$appcmd = "$iisdir\appcmd.exe"

#if (!(Test-Path "$cd\applicationHost.config")) {
    Copy "$iisdir\AppServer\applicationHost.config" "applicationHost.config"

    & $appcmd "set" "config" "/section:system.webServer/fastCGI" "/+[fullPath='$phpdir\php-cgi.exe',arguments='-c %u0022$cd\php.ini%u0022']" "/apphostconfig:""$cd\applicationHost.config"""
    # TODO : Restart on php.ini changes
    & $appcmd "set" "config" "/section:system.webServer/fastCGI" "/[fullPath='$phpdir\php-cgi.exe',arguments='-c %u0022$cd\php.ini%u0022'].monitorChangesTo:""$cd\php.ini""" "/apphostconfig:""$cd\applicationHost.config"""
    # TODO : other settings

    & $appcmd "set" "config" "/section:system.webServer/handlers" "/+[name='PHP_via_FastCGI',path='*.php',verb='*',modules='FastCgiModule',scriptProcessor='$phpdir\php-cgi.exe|-c %u0022$cd\php.ini%u0022',resourceType='Unspecified']" "/apphostconfig:""$cd\applicationHost.config"""

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

    & $appcmd "set" "config" "/section:defaultDocument" "/+files.[value='index.php']" "/apphostconfig:""$cd\applicationHost.config"""
#}


#$Process = [Diagnostics.Process]::Start("$db\bin\mysqld --console --skip-grant-tables")
#$id = $Process.Id
#try {
#    Stop-Process -Id $id -ErrorAction stop
#    Write-Host "Successfully killed the process with ID: $ID"
#} catch {
#    Write-Host "Failed to kill the process"
#}


Start-Process "http://localhost:8080/test.php"
& "$iisdir\iisexpress.exe" "/config:""$cd\applicationHost.config"""
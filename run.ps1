$cd = $PSScriptRoot
$packagesdir = [System.IO.Path]::GetFullPath("$($env:USERPROFILE)\.wpnib\packages")

if (!(Test-Path $packagesdir)) {
    New-Item -Path $packagesdir -ItemType "directory"
}

$webdir = "$cd\web"

if (!(Test-Path $webdir)) {
    New-Item -Path $webdir -ItemType "directory"
}



###############################
### INSTALLATION OF MARIADB ###
###############################

$mariadbname = "mariadb-10.3.17"
$mariadbzipname = "$mariadbname-winx64.zip"
$mariadbzippath = "$packagesdir\$mariadbzipname"
$mariadbzipurl = "https://downloads.mariadb.org/f/$mariadbname/winx64-packages/$mariadbname-winx64.zip?serve"
$mariadbdir = "$cd\$mariadbname-winx64"
$mariadbpath = "$mariadbdir\bin\mysqld.exe"
$mariadbportpath = "$cd\mariadb.port"

if(!(Test-Path $mariadbportpath)){
    Get-Random -Minimum 61000 -Maximum 62000 | Set-Content $mariadbportpath
}

$mariadbport = [int](Get-Content $mariadbportpath)

if (!(Test-Path $mariadbdir)) {
    Write-Output "MariaDB ($mariadbname) not installed"

    if ((Test-Path $mariadbzippath)) {
        Write-Output "Already downloaded MariaDB to $mariadbzippath"
    } else {
        Write-Output "Downloading MariaDB from $mariadbzipurl"
        Invoke-WebRequest -Uri $mariadbzipurl -OutFile $mariadbzippath
    }

    Write-Output "Installing MariaDB to $mariadbdir"
    Expand-Archive $mariadbzippath -DestinationPath $cd
}



###########################
### INSTALLATION OF PHP ###
###########################

$phpname = "php-7.3.9"
$phpzipname = "$phpname-nts-Win32-VC15-x64.zip"
$phpzippath = "$packagesdir\$phpzipname"
$phpzipurl = "https://windows.php.net/downloads/releases/$phpzipname"
$phpdir = "$cd\$phpname"
$phppath = "$phpdir\php-cgi.exe"
$php = "$phpdir\php.exe"
$phpinipath = "$cd\php.ini"

if (!(Test-Path $phpdir)) {
    Write-Output "PHP ($phpname) not installed"

    if ((Test-Path $phpzippath)) {
        Write-Output "Already downloaded PHP to $phpzippath"
    } else {
        Write-Output "Downloading PHP from $phpzipurl"

        try {
            Invoke-WebRequest -Uri $phpzipurl -OutFile $phpzippath
        }
        catch {
            Write-Output "ERROR: Could not download $phpzipurl`nPlease download it manually and put it here: $phpzippath"
            exit
        }
    }

    Write-Output "Installing PHP to $phpdir"
    Expand-Archive $phpzippath -DestinationPath $phpdir
}

if (!(Test-Path $phpinipath)) {
    "extension_dir = ""ext""" | Set-Content $phpinipath

    "extension=mysqli" | Add-Content $phpinipath
    "extension=mbstring" | Add-Content $phpinipath
    "extension=openssl" | Add-Content $phpinipath

    # TODO: Fix error_reporting = E_COMPILE_ERROR|E_RECOVERABLE_ERROR|E_ERROR|E_CORE_ERROR
    
    "" | Add-Content $phpinipath

    Get-Content "$phpdir\php.ini-development" | Add-Content $phpinipath
}

# Follow recommendations here
# Install wincache ? https://www.saotn.org/php-wincache-on-iis/
# https://docs.microsoft.com/en-us/iis/application-frameworks/install-and-configure-php-on-iis/install-and-configure-mysql-for-php-applications-on-iis-7-and-above#configure-php-to-access-mysql



#########################
### INSTALL WORDPRESS ###
#########################

$wordpresspath = "$webdir\wordpress"
$wordpresszipurl = "https://wordpress.org/latest.zip"
$wordpresszippath = "$packagesdir\wordpress.zip"

if (!(Test-Path "$webdir\wp-admin")) {
    Write-Output "Wordpress not installed"
    Write-Output "Downloading Wordpress from $wordpresszipurl"

    try {
        Invoke-WebRequest -Uri $wordpresszipurl -OutFile $wordpresszippath
    }
    catch {
        Write-Output "ERROR: Could not download $wordpresszipurl"
        exit
    }

    Write-Output "Installing Wordpress to $wordpresspath"
    Expand-Archive $wordpresszippath -DestinationPath $webdir

    Get-ChildItem -Path $wordpresspath | Move-Item -Destination $webdir
    Remove-Item -Path $wordpresspath
}

if(!(Test-Path "$webdir\wp-config.php")) {
    $wpconfig = Get-Content "$webdir\wp-config-sample.php"

    $wpconfig = $wpconfig -replace "database_name_here", "wordpress"
    $wpconfig = $wpconfig -replace "username_here", ""
    $wpconfig = $wpconfig -replace "password_here", ""
    $wpconfig = $wpconfig -replace "localhost", "127.0.0.1:$mariadbport"

    $wpconfig | Set-Content "$webdir\wp-config.php"
}



###############################
### INSTALLATION OF ADMINER ###
###############################

$unsecurepath = "$webdir\unsecure"

if (!(Test-Path $unsecurepath)) {
    New-Item -Path $unsecurepath -ItemType "directory"
}

$adminerpath = "$unsecurepath\adminer.php"
$adminerurl = "https://www.adminer.org/latest.php"

if (!(Test-Path $adminerpath)) {
    Write-Output "Adminer not installed"
    Write-Output "Downloading Adminer from $adminerurl"

    try {
        Invoke-WebRequest -Uri $adminerurl -OutFile $adminerpath
    }
    catch {
        Write-Output "ERROR: Could not download $adminerurl"
        exit
    }
}

$adminerwppath = "$unsecurepath\adminer-wp.php"
$adminerwpurl = "https://gist.githubusercontent.com/bjorn-ali-goransson/51d141f48accefcb45fbc7bb058e18bc/raw/e2f8f3178ae291c2138858ce85ae8e497e269beb/adminer-wp.php"

if (!(Test-Path $adminerwppath)) {
    Write-Output "Adminer-WP not installed"
    Write-Output "Downloading Adminer-WP from $adminerwpurl"

    try {
        Invoke-WebRequest -Uri $adminerwpurl -OutFile $adminerwppath
    }
    catch {
        Write-Output "ERROR: Could not download $adminerwpurl"
        exit
    }
}



#########################################
### INSTALLATION OF SEARCH REPLACE DB ###
#########################################

$searchreplacedbversion = "3.1"
$searchreplacedbpath = "$unsecurepath\Search-Replace-DB-$searchreplacedbversion"
$searchreplacedbzipurl = "https://github.com/interconnectit/Search-Replace-DB/archive/$searchreplacedbversion.zip"
$searchreplacedbzippath = "$packagesdir\Search-Replace-DB-$searchreplacedbversion.zip"

if (!(Test-Path $searchreplacedbpath)) {
    Write-Output "Search Replace DB not installed"
    Write-Output "Downloading Search Replace DB from $searchreplacedbzipurl"

    try {
        Invoke-WebRequest -Uri $searchreplacedbzipurl -OutFile $searchreplacedbzippath
    }
    catch {
        Write-Output "ERROR: Could not download $searchreplacedbzipurl"
        exit
    }

    Write-Output "Installing Search Replace DB to $searchreplacedbpath"
    Expand-Archive $searchreplacedbzippath -DestinationPath $unsecurepath
}



###################################
### INSTALLATION OF IIS EXPRESS ###
###################################

# TODO: Install IIS Express, URL Rewrite

$iisdir = "C:\Program Files (x86)\IIS Express"
$iispath = "$iisdir\iisexpress.exe"
$appcmd = "$iisdir\appcmd.exe"
$applicationhostpath = "$cd\applicationHost.config"
$iisportpath = "$cd\iis.port"

if(!(Test-Path $iisportpath)){
    Get-Random -Minimum 62000 -Maximum 63000 | Set-Content $iisportpath
}

$iisport = [int](Get-Content $iisportpath)

if (!(Test-Path $applicationhostpath)) {
    Copy-Item "$iisdir\AppServer\applicationHost.config" $applicationhostpath

    & $appcmd "set" "config" "/section:system.webServer/fastCGI" "/+[fullPath='$phppath',arguments='-c %u0022$phpinipath%u0022']" "/apphostconfig:""$applicationhostpath"""
    & $appcmd "set" "config" "/section:system.webServer/fastCGI" "/[fullPath='$phppath',arguments='-c %u0022$phpinipath%u0022'].monitorChangesTo:""$phpinipath""" "/apphostconfig:""$applicationhostpath"""

    & $appcmd "set" "config" "/section:system.webServer/handlers" "/+[name='PHP_via_FastCGI',path='*.php',verb='*',modules='FastCgiModule',scriptProcessor='$phppath|-c %u0022$phpinipath%u0022',resourceType='Unspecified']" "/apphostconfig:""$applicationhostpath"""

    & $appcmd "list" "site" "/text:name" "/apphostconfig:""$applicationhostpath""" | ForEach-Object { & $appcmd "delete" "site" $_ "/apphostconfig:""$applicationhostpath""" }
    & $appcmd "add" "site" "/name:""Website""" "/physicalPath:""$webdir""" "/bindings:http/:$iisport`:localhost" "/apphostconfig:""$applicationhostpath"""

    & $appcmd "set" "config" "-section:system.webServer/rewrite/rules" "/+""[name='Wordpress_Rewrite',stopProcessing='True']""" "/apphostconfig:""$applicationhostpath"""
    & $appcmd "set" "config" "-section:system.webServer/rewrite/rules" "/[name='Wordpress_Rewrite'].match.url:""(.*)""" "/apphostconfig:""$applicationhostpath"""
    & $appcmd "set" "config" "-section:system.webServer/rewrite/rules" "/[name='Wordpress_Rewrite'].conditions.logicalGrouping:""MatchAll""" "/apphostconfig:""$applicationhostpath"""
    & $appcmd "set" "config" "-section:system.webServer/rewrite/rules" "/+[name='Wordpress_Rewrite'].conditions.[input='{REQUEST_FILENAME}',matchType='IsFile',negate='true']" "/apphostconfig:""$applicationhostpath"""
    & $appcmd "set" "config" "-section:system.webServer/rewrite/rules" "/+[name='Wordpress_Rewrite'].conditions.[input='{REQUEST_FILENAME}',matchType='IsDirectory',negate='true']" "/apphostconfig:""$applicationhostpath"""
    & $appcmd "set" "config" "-section:system.webServer/rewrite/rules" "/[name='Wordpress_Rewrite'].action.type:""Rewrite""" "/apphostconfig:""$applicationhostpath"""
    & $appcmd "set" "config" "-section:system.webServer/rewrite/rules" "/[name='Wordpress_Rewrite'].action.url:""index.php""" "/apphostconfig:""$applicationhostpath"""

    & $appcmd "set" "config" "/section:defaultDocument" "/+files.[value='index.php']" "/apphostconfig:""$applicationhostpath"""
}



#########################
### START THE WEBSITE ###
#########################

Get-Process | Where-Object { $_.Path -eq $mariadbpath } | Stop-Process

Start-Process $mariadbpath -NoNewWindow -ArgumentList "--console --skip-grant-tables --port=$mariadbport"

while($true){
    $output = & $php "-c=""$phpinipath""" "-r `$conn = mysqli_connect('127.0.0.1:$mariadbport', '', ''); if (`$conn->connect_error) { echo `$conn->connect_error; exit; } echo 'OK';"

    if($output -eq "OK"){
        break
    }

    Start-Sleep 1
}

& $php "-c=""$phpinipath""" "-r `$conn = mysqli_connect('127.0.0.1:$mariadbport', '', ''); `$conn->query('CREATE DATABASE IF NOT EXISTS wordpress');"

#Get-WmiObject Win32_Process -Filter "name = 'iisexpress.exe'" | Where-Object { $_.CommandLine -eq """$iispath"" /config:""$applicationhostpath""" } | ForEach-Object { $e.terminate() }

Start-Process "http://localhost:$iisport/"
Start-Process $iispath -NoNewWindow "/config:""$applicationhostpath"""

Read-Host "`nPress ENTER to kill`n`n" | Out-Null

Write-Output "Killing DB / IIS ...`n"

Get-Process | Where-Object { $_.Path -eq $mariadbpath } | Stop-Process
Get-Process | Where-Object { $_.Path -eq $iispath } | Stop-Process

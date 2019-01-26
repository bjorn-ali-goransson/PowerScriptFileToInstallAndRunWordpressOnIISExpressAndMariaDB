$cd = $PSScriptRoot

$packagesdir = [System.IO.Path]::GetFullPath("$cd\..\packages")

if (!(Test-Path $packagesdir)) {
    New-Item -Path $packagesdir -ItemType "directory"
}



###########################
### INSTALLATION OF PHP ###
###########################

$phpname = "php-7.3.1"
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
    
    "" | Add-Content $phpinipath

    Get-Content "$phpdir\php.ini-development" | Add-Content $phpinipath
}

# Follow recommendations here
# Install wincache ? https://www.saotn.org/php-wincache-on-iis/
# https://docs.microsoft.com/en-us/iis/application-frameworks/install-and-configure-php-on-iis/install-and-configure-mysql-for-php-applications-on-iis-7-and-above#configure-php-to-access-mysql



###############################
### INSTALLATION OF MARIADB ###
###############################

$mariadbname = "mariadb-10.3.12"
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



###################################
### INSTALLATION OF IIS EXPRESS ###
###################################

# TODO: Install IIS Express, URL Rewrite
# TODO: Create DB
# $conn = new mysqli('localhost', 'root', ''); if (mysqli_connect_errno()) { exit('Connect failed: '. mysqli_connect_error()); } $sql = 'CREATE DATABASE `wptest` DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci'; if ($conn->query($sql) === TRUE) { Write-Output 'Database created successfully'; } else { Write-Output 'Error creating database: ' . $conn->error; } $conn->close();

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

    & $appcmd "set" "config" "/section:system.webServer/fastCGI" "/+[fullPath='$phppath',arguments='-c %u0022$cd\php.ini%u0022']" "/apphostconfig:""$applicationhostpath"""
    & $appcmd "set" "config" "/section:system.webServer/fastCGI" "/[fullPath='$phppath',arguments='-c %u0022$cd\php.ini%u0022'].monitorChangesTo:"$phpinipath"" "/apphostconfig:""$applicationhostpath"""
    # TODO : other settings

    & $appcmd "set" "config" "/section:system.webServer/handlers" "/+[name='PHP_via_FastCGI',path='*.php',verb='*',modules='FastCgiModule',scriptProcessor='$phppath|-c %u0022$cd\php.ini%u0022',resourceType='Unspecified']" "/apphostconfig:""$applicationhostpath"""

    $sites = & $appcmd "list" "site" "/text:name" "/apphostconfig:""$applicationhostpath"""

    foreach( $line in $sites ){
        $sitename = $line.Trim()
        & $appcmd "delete" "site" $sitename "/apphostconfig:""$applicationhostpath"""
    }

    & $appcmd "add" "site" "/name:""Website""" "/physicalPath:""$cd\web""" "/bindings:http/:$iisport`:localhost" "/apphostconfig:""$applicationhostpath"""

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
### INSTALL WORDPRESS ###
#########################

$webdir = "$cd\web"

if (!(Test-Path "$webdir")) {
    Write-Output "Wordpress not installed"

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



#########################
### START THE WEBSITE ###
#########################

$runningmariadbprocesses = Get-Process | Where-Object { $_.Path -eq $mariadbpath }

if($runningmariadbprocesses.Count -gt 0){
    Write-Output "MariaDB is already running"

    $runningmariadbprocesses | Stop-Process
}

Start-Process $mariadbpath -NoNewWindow -ArgumentList "--console --skip-grant-tables --port=$mariadbport"

while($true){
    $output = & $php "-c=""$phpinipath""" "-r `$conn = mysqli_connect('127.0.0.1:$mariadbport', '', ''); if (`$conn->connect_error) { Write-Output `$conn->connect_error; exit; } `$conn->query('CREATE DATABASE IF NOT EXISTS wordpress'); Write-Output 'OK';"

    if($output -eq "OK"){
        break
    }

    Start-Sleep 1
}

& $php "-c=""$phpinipath""" "-r `$conn = mysqli_connect('127.0.0.1:$mariadbport', '', ''); `$conn->query('CREATE DATABASE IF NOT EXISTS wordpress');"

Start-Process "http://localhost:$iisport/"
Start-Process $iispath -NoNewWindow "/config:""$applicationhostpath"""

Read-Host "`nPress ENTER to kill`n`n" | Out-Null

Write-Output "Killing DB / IIS ...`n"

Get-Process | Where-Object { $_.Path -eq $mariadbpath } | Stop-Process
Get-Process | Where-Object { $_.Path -eq $iispath } | Stop-Process
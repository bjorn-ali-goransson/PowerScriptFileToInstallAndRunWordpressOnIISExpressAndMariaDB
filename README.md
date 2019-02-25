Installs MariaDB, PHP and Wordpress to a new IIS Express site.

Does not modify the computers configuration - everything is installed locally in the projects root folder.

Create a projects root folder somewhere (like C:\Dev\wp) and then a project folder (like C:\Dev\wp\fabrikam). Paste the run.ps1 script in there and go `ps run.ps1` from the command prompt.

    projects-root
    `--packages
    `--project1
    `--project2

The only thing shared between projects are downloaded zip files.

You can later start the site by running `"C:\Program Files (x86)\IIS Express\iisexpress.exe" -NoNewWindow "/config:"C:\Dev\wp\fabrikam\applicationHost.config"`
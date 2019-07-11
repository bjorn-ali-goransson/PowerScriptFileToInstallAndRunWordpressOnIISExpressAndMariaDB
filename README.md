Installs MariaDB, PHP and Wordpress to a new IIS Express site.

Does not modify the computers configuration - everything is installed locally in the projects root folder.

Create a projects folder somewhere. Packages are downloaded to your home folder, under `.wpnib`.

Paste the run.ps1 script in there and go `ps run.ps1` from the command prompt.

    projects-root
    `--packages    # Cached download files
    `--fabrikam
       `--mariadb  # Your portable MariaDB installation
       `--php      # Your portable PHP installation
       `--web      # Your web files (including wordpress)
       `--...      other stuff

The only thing shared between projects are some cached downloaded zip files.

Press enter to kill everything. Run `ps run.ps1` to start again.

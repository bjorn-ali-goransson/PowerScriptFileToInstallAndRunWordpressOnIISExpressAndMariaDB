Installs MariaDB, PHP and Wordpress (and Adminer, and Search Replace DB) to a new IIS Express site.

Does not modify the computers configuration - everything is installed locally in the projects root folder.

Create a project folder somewhere. Packages are downloaded to your home folder, under `.wpnib`.

Paste the run.ps1 script in there and go `./run.ps1` from a powershell-enabled console (run `powershell` from the command prompt).

    projects-root
     `--mariadb  # Your portable MariaDB installation
     `--php      # Your portable PHP installation
     `--web      # Your web files (including wordpress)
     `--...      other stuff

The only thing shared between projects are some cached downloaded zip files.

Press enter to kill everything. Run `ps run.ps1` to start again.

To start adminer (the phpMyAdmin clone), navigate to `/unsecure/adminer-wp.php` to log in automatically.

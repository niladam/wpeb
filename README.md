<p align="center">
<a href='https://ko-fi.com/A204JA0' target='_blank'><img height='28' style='border:0px;height:28px;' src='https://az743702.vo.msecnd.net/cdn/kofi4.png?v=f' border='0' alt='Buy Me a Coffee at ko-fi.com' /></a>&nbsp;&nbsp;<a href="https://travis-ci.org/niladam/wpeb"><img height="28" src="https://travis-ci.org/niladam/wpeb.svg?branch=master"></a>
</p>

## WPEB (WordPress Easy Backup): A simple (pre-update) wordpress backup script.
#### (c) 2017 Madalin Tache
#### http://github.com/niladam/wpeb

A simple bash script that takes a snapshot of the current WordPress
directory and database. The archive will contain a database dump, and
an entire archive of the current WordPress installation.
Optionally, it can *INCLUDE* the uploads folder but this might result
in a a huge archive file on large sites.

WPEB (WordPress Easy Backup) is free software: you can redistribute it
and/or modify it under the terms of the GNU General Public License
as published by the Free Software Foundation, either version 2
of the License, or (optionally) any later version.

# Breakdown

Currently the plugin is depending on [wp-cli](http://wp-cli.org)
By default the plugin does the following:

* Checks if wp-cli exists in `/usr/local/bin/wp`
* Check is the current cwd is a WordPress install (currently prone to errors, needs fixing)
* Automatically runs a *repair* and *optimize* on the database
* Dumps the database using [wp-cli](http://wp-cli.org) (the file is usually `DBNAME`.sql)
* Compresses the exported database using `bzip2`
* Compresses everything in the `cwd` (in the future an exclude option will be provided) (in a `tar` archive)
* ***Ignores the uploads folder in wp-content (to prevent *large databases*)*** (This is a pre-update backup script, right ?)
* `gzip`s everything with the best compression level.

# Installing

Install with:

```bash
curl -sSL https://wpeb-installer.includes.io | bash
```

# Updating

If you want to update the script you can use two options. Either run the same command as the install (will auto-update if needed), or use the built-in updater

```bash
wpeb --up
```

or

```bash
wpeb --self-update
```

# Using

***For now, the plugin will only function if called from the *main WordPress* folder.***

Use with:

```bash
cd /home/someuser/public_html
wpeb
```

# Command Options

```bash

    [FLAGS]
        --su=, --skip-uploads=      yes/no (Defaults to yes, skipping uploads folder)
                                    yes: include uploads
                                    no:  skip uploads

        --ro=, --repair-optimize=   yes/no (Defaults to yes, repair and optimize db)
                                    yes: repair and optimize db
                                    no:  skip repairing and optimizing

        --co=, --compression=       1-9 (Defaults to 9, compression rate)
                                    1 - fastest (compression, largest file)
                                    9 - best (compression, smallest file)

        --of=, --output-folder=     Defaults to the site's root directory.
                                    Absolute folder path
                                    EG: /srv/backups/
                                    Folder will be created if it doesn't exist.

        --up, --self-update         Self update this script to the latest version.
                                    Uses curl if available and fallsback to wget,
                                    if curl is missing.

        --h, --help                 This help screen.
```

# TODO

Have a look at the [TODO](TODO.md) list.

# License

WPEB (WordPress Easy Backup) is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 2 of the License, or (optionally) any later version.
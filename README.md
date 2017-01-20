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

```
curl -O https://raw.githubusercontent.com/niladam/wpeb/master/wpeb.sh
chmod +x wpeb.sh
mv wpeb.sh /usr/local/bin/wpeb
```

Or in a one quick command that you can paste:

`curl -O https://raw.githubusercontent.com/niladam/wpeb/master/wpeb.sh ; chmod +x wpeb.sh ; mv wpeb.sh /usr/local/bin/wpeb`


# Using

***For now, the plugin will only function if called from the *main WordPress* folder.***

Use with:

```
cd /home/someuser/public_html
wpeb
```

# TODO

Have a look at the [TODO](TODO.md) list.

# License

WPEB (WordPress Easy Backup) is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 2 of the License, or (optionally) any later version.
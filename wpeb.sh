#!/usr/bin/env bash

#
# WPEB (WordPress Easy Backup): A simple (pre-update) wordpress backup script.
# v1.0b (released 20th January 2017)
# (c) 2017 Madalin Tache
# http://github.com/niladam/wpeb
#
# A simple bash script that takes a snapshot of the current WordPress
# directory and database. The archive will contain a database dump, and
# an entire archive of the current WordPress installation.
# Optionally, it can *INCLUDE* the uploads folder but this might result
# in a a huge archive file on large sites.
#
# WPEB (WordPress Easy Backup) is free software: you can redistribute it
# and/or modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation, either version 2
# of the License, or (optionally) any later version.
#

# Some configuration options
# WP-CLI
# Your wp-cli path location
WPEB_WPCLIPATH="/usr/local/bin/wp"
# BACKUP FOLDER
# Backup folder path, unless changed defaults to current working directory.
WPEB_BFP=""
# UPLOADS
# By default, the uploads folder is ignored, but if you need it, you can
# enable it here.
# yes = includes uploads
# no  = skip uploads.
WPEB_UPLOADS="no"
# DATABASE
# By default, i need a backup on the database, but you can disable
# this if you know you don't usually need it.
# yes = backup the database before creating the entire archive
# no  = skip backing up the database (this also skips the database repair
# and optimization)
WPEB_BACKUP_DB="yes"
# REPAIR AND OPTIMIZE
# Apply a repair and optimize on the database before backing up ?
# By default, this is enabled. Nobody wants a bad sql dump, but you can
# disable this if you want to.
# yes = will run a repair and optimize before attempting to export.
# no  = the database won't be touched before exporting.
WPEB_REPOPTIM="yes"
# COMPRESSION
# By default the compression is set to 9 (MAXIMUM), but you can change this
# to anything between 1-9, where 1 is the fastest and 9 is the best
# compression.
WPEB_COMPRESSION="9"
# CPANEL -- NOT IN USE. TODO: Provide possibility to run this on a per-user,
# basis instead of needing to be IN THE WordPress root.
# If this is a cPanel server, calling this script in the form of
# wpeb --user=username
# Will change directory to username's MAIN DOMAIN root, and run the backup
# on that site (if it's WordPress)
# yes = cd into username's main document root and backup that.
# no  = not a cPanel server and this script will die, unless it's called
# WPEB_CPANEL="yes"

# Some basic constants, usually there's no need to edit these.
# But feel free to change the date format to something else.
# Based on this, the archive name will be: example.org.2017-01-19-2302.tar.gz
WPEB_NOW=$(date +"%Y-%m-%d-%H%M")
WPEB_CWD=$(pwd)
WPEB_TAR="/usr/bin/tar"

################################################################################
#
# You can stop editing after this line.
#
################################################################################


# Let's make sure that we can run wp-cli as root. Unsafe, but useful most
# of the time.
function wp() {
  "$WPEB_WPCLIPATH" "$@" --allow-root
}
function check_for_wp_cli() {
	if [ -z "$WPEB_WPCLIPATH" ]; then
		echo "WP-CLI path variable is empty, aborting.."
		exit 1
	fi
	if ! type "$WPEB_WPCLIPATH" > /dev/null; then
		echo "WP-CLI variable is set, but the program doesn't exist, aborting.."
		exit 1
		# Install WP-CLI here in the future ?
	fi
	# In the future, we might need to also check for WP-CLI's version,
	# so i'll just leave this here commented for now.
	# $WPEB_WPCLI_VER=`wp --info | tail -n1 | cut -d : -f2 | tr -d " \t"`
}
function check_for_wordpress() {
	# This needs some fixing as apparently there's a bug in WP-CLI
	# issue: https://github.com/wp-cli/wp-cli/issues/3752
	# if ! $(wp core is-installed); then
	#     # WordPress appears to be missing, let's abort.
	#     echo "This isn't a WordPress site, aborting.."
	#     exit 1
	# else
	# 	echo "Yep, this looks like it's a WordPress site.."
	# fi
	if [ ! -f "$WPEB_CWD/wp-includes/version.php" ]; then
	    # nope, not WordPress, let's abort..
	    echo "This script needs to be executed in the main WordPress folder that you're trying to backup. Aborting..."
	    exit 1
	fi
}
function backup_db() {
	WPEB_EXPORTED_DB=$(wp db export --porcelain)
	bzip2 "$WPEB_EXPORTED_DB"
}
function repair_and_optimize() {
	if [ "$WPEB_BACKUP_DB" == "yes" ]; then
		if [ "$WPEB_REPOPTIM" == "yes" ]; then
		echo "Running repair and optimization on the current database.."
		wp db repair
		wp db optimize
		fi
		backup_db
	fi

}
function backup_wordpress() {
	# Let's first get the siteurl and make sure we use the domain/subdomain
	# in the archive name.
	WPEB_SITEURL=`wp option get siteurl | cut -d'/' -f3`
	if [ -z "$WPEB_BFP" ]; then
		WPEB_BFP=$WPEB_CWD
	fi
	if [ "$WPEB_UPLOADS" == "yes" ]; then
		tar -cf "$WPEB_BFP/$WPEB_SITEURL.$WPEB_NOW.tar" --exclude='error_log' *
		gzip -9 "$WPEB_BFP/$WPEB_SITEURL.$WPEB_NOW.tar"
	else
		tar -cf "$WPEB_BFP/$WPEB_SITEURL.$WPEB_NOW.tar" --exclude='wp-content/uploads/*' --exclude='error_log' *
		gzip -9 "$WPEB_BFP/$WPEB_SITEURL.$WPEB_NOW.tar"
	fi
}
# function go_where() {
# 	# In the future, the script will be able to handle username, and run commands
# 	# based on the user's main document root.
# }
# function cleanup() {

# }
function run_backup() {
	# go_where
	check_for_wp_cli
	check_for_wordpress
	repair_and_optimize
	# backup_db
	backup_wordpress
	# cleanup
}

# We should have everything, let's run the backup :)
run_backup
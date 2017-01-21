#!/usr/bin/env bash

#
# WPEB (WordPress Easy Backup): A simple (pre-update) wordpress backup script.
# v1.2 (released 20th January 2017)
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

# Version declaration, to be used in script update checks.
WPEB_VER="1.1b"

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
# DEBUGGING
# By default, the script will show some output messages as it executes, but
# you can disable that.
# yes  = yes, show the script's output messages.
# no   = no, hide everything, but write to wpeb_debug.log
WPEB_DEBUG="yes"
# DEBUG LOG
# You can name your debug log here. It defaults to wpeb_debug.log
# Care should be taken as this could write to some other log files.
WPEB_DEBUG_LOG="wpeb_debug.log"

# Some basic constants, usually there's no need to edit these.
# But feel free to change the date format to something else.
# Based on this, the archive name will be: example.org.2017-01-19-2302.tar.gz
WPEB_NOW=$(date +"%Y-%m-%d-%H%M")
WPEB_CWD=$(pwd)
WPEB_TAR="/usr/bin/tar"
R=`tput setaf 1`        # red
V=`tput setaf 2`        # green
G=`tput setaf 3`		# yellow
N=`tput sgr0`           # normal
B=`tput bold`           # bold..

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
# Let's use a function to return based on success/error
# ok	= Message shown in green
# notok	= Message shown in red
# *		= Anything else is by default a warning, and shown in yellow.
function show_message() {
	if [ "$WPEB_DEBUG" == "yes" ]; then
		# Debugging enabled, showing messages and not writing a log.
		case "$2" in
				"ok")
					echo -e "${V}[*]" "$1" "${N}"
					;;
				"notok")
					echo -e "${R}[*]" "$1" "${N}"
					;;
				*)
					echo -e "${G}[*]" "$1" "${N}"
					;;
		esac
	else
		# Debugging disabled, we should write to debug log.
		if [ -z "$WPEB_DEBUG_LOG" ]; then
			WPEB_DEBUG_LOG="wpeb_debug.log"
		fi
			case "$2" in
				"ok")
					echo "SUCCESS:" "$1" >> "$WPEB_DEBUG_LOG"
					;;
				"notok")
					echo "ERROR:" "$1" >> "$WPEB_DEBUG_LOG"
					;;
				*)
					echo "INFO:" "$1" >> "$WPEB_DEBUG_LOG"
					;;
			esac
	fi

}
# Checking for WP-CLI and returning a message if not found.
function check_for_wp_cli() {
	if [ -z "$WPEB_WPCLIPATH" ]; then
		show_message "WP-CLI path variable is empty, aborting.." notok
		exit 1
	fi
	if ! type "$WPEB_WPCLIPATH" > /dev/null; then
		show_message "WP-CLI variable is set, but the program doesn't exist, aborting.." notok
		exit 1
		# Install WP-CLI here in the future ?
	fi
	# In the future, we might need to also check for WP-CLI's version,
	# so i'll just leave this here commented for now.
	# $WPEB_WPCLI_VER=`wp --info | tail -n1 | cut -d : -f2 | tr -d " \t"`
}
# Let's check this is actually a WordPress site
function check_for_wordpress() {
	# First we check for wp-includes/versio.php
	if [ ! -f "$WPEB_CWD/wp-includes/version.php" ]; then
	    # nope, not WordPress, let's warn and check tables using wp-cli
	    show_message "The file version.php is missing in wp-includes, checking for tables.."
	    # exit 1
	    # # This needs some fixing as apparently there's a bug in WP-CLI
	    # # issue: https://github.com/wp-cli/wp-cli/issues/3752
	    wp core is-installed &>/dev/null
	    INSTALLED_CODE=$?
	    if [ $INSTALLED_CODE -eq 0 ]; then
	    	# WordPress appears to be missing, let's abort.
	    	show_message "WordPress tables are missing too, aborting.." notok
	    	exit 1
	    fi
	fi
}
# Let's export the database and archive it.
function backup_db() {
	# WPEB_EXPORTED_DB=$( (wp db export --porcelain --allow-root) 2>&1)
	WPEB_EXPORTED_DB=$(wp db export --porcelain 2>&1)
	bzip2 "$WPEB_EXPORTED_DB"
	if [ -f "$WPEB_EXPORTED_DB.bz2" ]; then
		show_message "Created $WPEB_ARCHIVED_DB" ok
	else
		show_message "Failed to archive the SQL dump, aborting." notok
		exit 1
	fi
}
# Let's repair and optimize if configured so
function repair_and_optimize() {
	if [ "$WPEB_BACKUP_DB" == "yes" ]; then
		if [ "$WPEB_REPOPTIM" == "yes" ]; then
		show_message "Running repair and optimization on the current database.." ok
		wp db repair &>/dev/null
		if [ $? -eq 0 ]; then
			show_message "DB repair failed.." notok
		fi
		wp db optimize
		if [ $? -eq 0 ]; then
			show_message "DB optimize failed.." notok
		fi
		fi
		backup_db
	fi

}
# Let's create our archive containing everything
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
function cleanup() {
	if [ -f "$WPEB_BFP/$WPEB_SITEURL.$WPEB_NOW.tar.gz" ]; then
		rm -rf "$WPEB_EXPORTED_DB.bz2"
		show_message "Removed $WPEB_EXPORTED_DB as the archive file exists containing it."
		show_message "Backup completed, the archive path is: $WPEB_BFP/$WPEB_SITEURL.$WPEB_NOW.tar.gz" ok
	else
		show_message "$WPEB_EXPORTED_DB not removed, as the archive file doesn't exist."
		show_message "Everything appears to have be running corectly, however the backup file doesn't exist" notok
	fi
}
# Main backup function, running all the functions in order
function run_backup() {
	# go_where
	check_for_wp_cli
	check_for_wordpress
	repair_and_optimize
	# backup_db
	backup_wordpress
	cleanup
}
# Self-update functionality
run_update() {
	WPEB_NOW_UPDATE=$(date +"%Y-%m-%d-%H%M")
	WPEB_MAIN="https://raw.githubusercontent.com/niladam/wpeb/master/wpeb.sh"
	WPEB_TEMP="/tmp/wpeb.$WPEB_NOW_UPDATE"
	WPEB_TARGET="/usr/local/bin/wpeb"
	WPEB_OLD_VERSION=$(grep WPEB_VER "$WPEB_TARGET" | head -1 | cut -d = -f2 | tr -d '"')
	WPEB_TEMP_DL=$(curl -sSL "$WPEB_MAIN" -o "$WPEB_TEMP")
	WPEB_DOWN_OK=$?
	if [ $WPEB_DOWN_OK -eq 0 ]; then
		# For some reason we couldn't download, let's bail.
		echo ""
		echo " *** For some reason, i couldn't download the latest version of WPEB"
		echo " *** Maybe you want to have a look at the docs and try a manual install ?"
		echo " *** https://niladam.github.io/wpeb  ***"
		echo ""
		rm -rf "$WPEB_TEMP"
		exit 1
	fi
	WPEB_NEW_VERSION=$(grep WPEB_VER "$WPEB_TEMP" | head -1 | cut -d = -f2 | tr -d '"')
	if echo $WPEB_NEW_VERSION $WPEB_OLD_VERSION | awk '{exit $1>$2?0:1}'
	then
		# echo WPEB_NEW_VERSION greater than WPEB_OLD_VERSION
		# Got newer version, move to target file.
		echo " *** New version found, $WPEB_NEW_VERSION. You have $WPEB_OLD_VERSION. Proceeding with install.."
	  	mv -f "$WPEB_TEMP" "$WPEB_TARGET"
	  	chmod +x "$WPEB_TARGET"
	  	echo ""
	  	echo " *** New version, $WPEB_NEW_VERSION was updated. Enjoy!"
	  	echo ""
	  	exit 0
	else
		# Now that should be impossible!:)
		echo " *** Apparently, the installed version is NEWER than the CURRENT version.."
		echo " *** This can happen if the file has been manually modified and/or altered.."
		echo " *** If you think this is a mistake, please open an issue at "
		echo " *** https://github.com/niladam/wpeb/issues *** "
		rm -rf "$WPEB_TEMP"
		exit 1
	fi
}

# Let's add arguments functionality
for i in "$@"
do
case $i in
    --su=*|--skip-uploads=*)
        if [[ "${i#*=}" != yes && "${i#*=}" != no ]]; then
            show_message "skip-uploads can only be yes or no.    Defaults to yes" notok
            exit 1
        fi
		if [ ! -z "${i#*=}" ]; then
            WPEB_UPLOADS="${i#*=}"
        fi
        shift
        ;;
    --ro=*|--repair-optimize=*)
        if [ ! -z "${i#*=}" ]; then
            if [[ "${i#*=}" != yes && "${i#*=}" != no ]]; then
                show_message "ro (repair/optimize) can only be yes or no.    Defaults to yes" notok
                exit 1
            fi
            WPEB_REPOPTIM="${i#*=}"
        fi
        shift
        ;;
    --co=*|--compression=*)
        if [ ! -z "${i#*=}" ]; then
            if [ ! "${i#*=}" -ge 1 -a "${i#*=}" -le 9 ]; then
                show_message "compression levels can be 1 to 9.    Defaults to 9." notok
                exit 1
            fi
            WPEB_COMPRESSION="${i#*=}"
        fi
        shift
        ;;
    --of=*|--output-folder=*)
        if [ ! -z "${i#*=}" ]; then
            WPEB_BFP="${i#*=}"
        fi
        shift
        ;;
    --q=*|--quiet=*)
        if [ ! -z "${i#*=}" ]; then
            if [[ "${i#*=}" != yes && "${i#*=}" != no ]]; then
                show_message "quiet can only be yes or no.    Defaults to no" notok
                exit 1
            fi
            WPEB_DEBUG="${i#*=}"
        fi
        shift
        ;;
    --up|--self-update)
		run_update

		;;
    -h|--h|--help)
        echo ${B}${V} ""
        echo "                        _          "
        echo "   __      ___ __   ___| |__       "
        echo "   \ \ /\ / / '_ \ / _ \ '_ \      "
        echo "    \ V  V /| |_) |  __/ |_) |     "
        echo "     \_/\_/ | .__/ \___|_.__/      "
        echo "            |_|                    "
        echo "                       v. $WPEB_VER"
        echo "  https://niladam.github.io/wpeb   "
        echo ${N} ""
        cat <<EOF
    WPEB (WordPress Easy Backup) is a simple bash script that
        takes a snapshot of the current WordPress folder. The script is built
        with speed in mind and thought as a pre-update backup of the current
        site, therefore some options might need to be used for an actual
        full backup. The backup excludes the uploads folder to prevent huge
        backups, and some files that are not required (like error_log files)

    Usage: wpeb [optional flags]

    [FLAGS]
        --su=, --skip-uploads=      ${B}${V}yes/no${N} (Defaults to yes, skipping uploads folder)
                                    yes: include uploads
                                    no:  skip uploads

        --ro=, --repair-optimize=   ${B}${V}yes/no${N} (Defaults to yes, repair and optimize db)
                                    yes: repair and optimize db
                                    no:  skip repairing and optimizing

        --co=, --compression=       ${B}${V}1-9${N} (Defaults to 9, compression rate)
                                    1 - fastest (compression, largest file)
                                    9 - best (compression, smallest file)

        --of=, --output-folder=     Defaults to the site's root directory.
                                    ${B}Absolute folder path${N}
                                    EG: /srv/backups/
                                    Folder will be created if it doesn't exist.

        --up, --self-update         Self update this script to the latest version.
                                    Uses ${B}curl${N} if available and fallsback to ${B}wget${N},
                                    if curl is missing.

        --h, --help                 This help screen.

    %% Enjoy WPEB.
EOF
exit 0
    ;;
esac
    shift
done
# Arguments end

# We should have everything, let's run the backup :)
run_backup

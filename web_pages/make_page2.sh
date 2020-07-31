#!/bin/bash

# make_page - A scripte to produce an HTML file

##### Constants

TITLE="System Information for $HOSTNAME"
RIGHT_NOW=$(date +"%x %r %Z")
TIME_STAMP="Updated on $RIGHT_NOW by $USER"

##### Functions

function system_info
{
	echo "<h2>System release info</h2>"
	echo "<p>Function not yet implemented</p>"
}

function show_uptime
{
	echo "<h2>System uptime</h2>"
	echo "<pre>"
	#uptime
	echo "</pre>"
}

function drive_space
{
    echo "<h2>Filesystem space</h2>"
    echo "<pre>"
#    df
    echo "</pre>"
}

function home_page
{
    echo "<h2>Home directory space by user</h2>"
    echo "<pre>"
    echo "Bytes Directory"
    du -s /home/* | sort -nr
    echo "</pre>"
}

##### main

cat <<- _EOF_
	<HTML>
	<HEAD>
		<TITLE>
		$TITLE	
		</TITLE>
	</HEAD>

	<BODY>
	<H1>$TITLE</H1> 
	<p>$TIME_STAMP</p>
	$(system_info)
	$(show_uptime)
	$(drive_space)
	$(home_page)
	</BODY>
	</HTML>
_EOF_

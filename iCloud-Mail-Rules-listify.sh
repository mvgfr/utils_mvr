#!/bin/bash

# intended as a BBEdit Text Filter
# to filter HTML copied from iCloud Mail web UI
# into a list of human-readable Rules
# (why? for: backup, debugging, migration, …)

# requires:
# single line of HTML, pulled from iCloud Mail Rules
#     (ex: right-click in the Rules pane, not on a Rule, and "Inspect Element")
# pandoc (ex: via brew)
# a bit of patience; this hacky method takes a few moments

# basic logic flow:
# grep to strip blank lines in input
# divide the single line of input, into one line per Rule
# process each line separately:
#    (since pandoc will likely output multiple lines; yes, this is slower)
#    pandoc - from HTML to plain text
#    strip blank lines
#    to keep single line, convert newlines, to spaces
#    strip trailing spaces
#    remove any extraneous ' []'
#    if all this results in a non-blank line, output it

# history:
# 20240210 mvr incep

egrep -v '^[[:blank:]]*$' |  \
    sed 's/<div role="button"/\'$'\n''&/g' |  \
        while read theLine; do
            potOut=$(echo "$theLine" |  \
                pandoc --from html --to plain |  \
                egrep -v '^[[:blank:]]*$' |  \
                tr '\n' " " |  \
                sed 's/ *$//' |  \
                sed 's/ \[\]//g')
            if [ -n "$potOut" ] ; then
                echo "$potOut"
            fi
        done

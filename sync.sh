
set -e
set -x

rsync -a ~/Projects/rbot snowball@vps.snowball.lv:~/ \
--exclude "ignore.json"         \
--exclude "misspellings.json"   \
--exclude "unknown.json"        \
--delete

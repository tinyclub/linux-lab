#!/bin/bash
#
# list.sh -- list all articles published
#

# list how many articles
number=$1
# cat: old first or tac: new first
order=$2

[ -z "$number" ] && number=50
[ -z "$order" ] && order=tac

ls _posts/ | xargs -i grep -ul -v '^draft:.*true' _posts/{} | \
tail -$number | $order | \
xargs -i egrep -H "^title:|^permalink:|^author" {} | \
sed -e "s%_posts/%%g;s%\([0-9]*-[0-9]*-[0-9]*-[0-9]*-[0-9]*-[0-9]*\)-\(.*\):author:\(.*\)%\1 \3\n                     _posts/\2%g;s%.*:permalink: \(.*\)%                     http://tinylab.org\1\n%g;s%.*:title: \(.*\)%                     \1%g;" | \
tr -d '"' | tr -d "'"

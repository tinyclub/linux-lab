
#!/bin/bash
#
# Build contributors
#

TOP_DIR=$(cd $(dirname $0) && pwd)

filter="*$1*"

grep "^author*:" -ur $TOP_DIR/../_posts/$filter | cut -d':' -f3 | sed -e "s/^ '*//g" | sed -e "s/'$//g" | sort | uniq -c | sort -k1 -g -r

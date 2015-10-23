
#!/bin/bash
#
# Build contributors
#

TOP_DIR=$(dirname `readlink -f $0`)

grep "^author*:" -ur $TOP_DIR/../_posts/ | cut -d':' -f3 | sed -e "s/^ '*//g" | sed -e "s/'$//g" | sort | uniq -c | sort -k1 -g -r

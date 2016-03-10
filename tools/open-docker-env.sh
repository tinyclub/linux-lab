# open the web lab via a browser

browser=chromium-browser
port=6080
url=http://localhost:$port/vnc.html
pwd=ubuntu

which $browser 2>&1>/dev/null \
    && ($browser $url 2>&1>/dev/null &) \
    && echo "Please login with password: $pwd" && exit 0

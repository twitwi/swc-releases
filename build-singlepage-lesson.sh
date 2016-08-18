#!/bin/bash

W=$(dirname $(readlink -f $0))

__build-site() {
    make site
}

__gen-single-page-md() {
    cat <<EOF > single-page.md
---
title: Complete Lesson
layout: base
---

{% assign __ind__ = site.pages | where: 'url', '/' %}
{% for ind in __ind__ %}
{% assign __SAVE_PAGE__ = page %}
{% assign page = ind %}

<a id="{{page.url}}"></a>
{% include main_title.html %}
{{ind.content}}
{% include syllabus.html %}

{% assign page = __SAVE_PAGE__ %}
{% endfor %}





{% for ep in site.episodes %}
{% assign __SAVE_PAGE__ = page %}
{% assign page = ep %}

<a id="{{page.url}}"></a>
{% include episode_title.html %}
{% include episode_overview.html %}
{{ep.content}}
{% include episode_keypoints.html %}

{% assign page = __SAVE_PAGE__ %}
{% endfor %}
EOF
}

__gen-pandoc-svg() {
    cat <<EOF > _site/pandoc-svg.py
#! /usr/bin/env python
"""
Pandoc filter to convert svg files to pdf as suggested at:
https://github.com/jgm/pandoc/issues/265#issuecomment-27317316
"""

__author__ = "Jerome Robert"

import mimetypes
import subprocess
import os
import sys
from pandocfilters import toJSONFilter, Str, Para, Image

fmt_to_option = {
    "latex": ("--export-pdf","pdf"),
    "beamer": ("--export-pdf","pdf"),
    #use PNG because EMF and WMF break transparency
    "docx": ("--export-png", "png"),
    #because of IE
    "html": ("--export-png", "png")
}

def svg_to_any(key, value, fmt, meta):
    if key == 'Image':
       if len(value) == 2:
           # before pandoc 1.16
           alt, [src, title] = value
           attrs = None
       else:
           attrs, alt, [src, title] = value
       mimet,_ = mimetypes.guess_type(src)
       option = fmt_to_option.get(fmt)
       if mimet == 'image/svg+xml' and option:
           base_name,_ = os.path.splitext(src)
           eps_name = base_name + "." + option[1]
           try:
               mtime = os.path.getmtime(eps_name)
           except OSError:
               mtime = -1
           if mtime < os.path.getmtime(src):
               cmd_line = ['inkscape', option[0], eps_name, src]
               sys.stderr.write("Running %s\n" % " ".join(cmd_line))
               subprocess.call(cmd_line, stdout=sys.stderr.fileno())
           if attrs:
               return Image(attrs, alt, [eps_name, title])
           else:
               return Image(alt, [eps_name, title])

if __name__ == "__main__":
  toJSONFilter(svg_to_any)
EOF
}


__patch-generated() {
    sed -i \
        -e 's@a href="/@a href="#/@g' \
        -e 's@="/assets@="assets@g' \
        _site/single-page.html
}

__python-preview() {
    (sleep 1 ; firefox http://localhost:8000/single-page.html) &
    (cd _site && python3 -m http.server)
}

__html-to-epub() {
    (cd _site && pandoc -o single-page.epub single-page.html)
}

__html-to-pdf() {
    (cd _site && pandoc --filter=pandoc-svg.py --standalone -o single-page.tex single-page.html)
    sed -i \
        -e 's@\\subsection@\\textbf@g' \
        _site/single-page.tex
    (cd _site && pdflatex single-page.tex)
}

__html-to-pdf-webkit() {
    local SV=http://localhost:18000/
    cd _site
    python3 -m http.server 18000 &
    local toKill=$!
    cd -
    echo "Should: kill $toKill"
    #--title 
    wkhtmltopdf -s A5 --user-style-sheet css/custom-hide.css ${SV}/single-page.html _site/single-page-browser.pdf
    # ./pdf--smaller.sh single-page-browser.pdf single-page-browser-smaller.pdf
    echo "now stopping the python web server: $toKill"
    kill $toKill
}

__reporting() {
    echo "The following might be of interest:"
    shopt -s nullglob # ignore wildcard that don't work below
    ls -1l _*site/single-page{,-browser}.{html,epub,pdf}
    shopt -u nullglob
}

go() {
    echo "DOING: $@" | sed 's/./−/g'
    echo "DOING: $@"
    echo "DOING: $@" | sed 's/./-/g'
    local cmd=__$1
    shift
    "$cmd" "$@"
}


set -e
echo "Checking for _episodes in the current directory."
test -d _episodes


if [[ $# -gt 0 ]] ; then
    for i in "$@"; do
        go $i
    done
else
    ### generate single-page html 
    go gen-single-page-md
    go build-site
    go patch-generated
    ##go python-preview   # [dev] see the generated page
    
    ### generate single-page epub
    go html-to-epub
    
    ### generate single-page pdf
    go gen-pandoc-svg
    go html-to-pdf
    
    ### generate single-page pdf with a browser
    go html-to-pdf-webkit
    
    ### reporting
    go reporting
fi

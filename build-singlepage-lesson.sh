#!/bin/bash

W=$(dirname $(readlink -f $0))

__build-site() {
    make site
}

__single-page-md() {
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


__patch-generated() {
    sed -i \
        -e 's@a href="/@a href="#/@g' \
        _site/single-page.html
}

__python-preview() {
    (sleep 1 ; firefox http://localhost:8000/single-page.html) &
    (cd _site && python3 -m http.server)
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

go single-page-md
go build-site
#\cp /tmp/single-page.html _site/ # use a cached version
go patch-generated
go python-preview

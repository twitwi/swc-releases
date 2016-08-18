
# Meant to be source'd

# same as in "make-or-update-release.sh" but for write access
resolve-lesson() {
    if [[ ${1:0:3} == 'dc:' ]] ; then
        printf %s "git@github.com:datacarpentry/${1:3}.git"
    else
        printf %s "git@github.com:swcarpentry/$1.git"
    fi
}

# slightly more modular than below
do-clone() {
    if test $# -lt 1 ; then
        echo "Expect <repo>"
        return
    fi
    as=$1
    repo=$(resolve-lesson $as)
    git clone $repo ,,$as --depth=1 --no-single-branch
}
do-checkout() {
    if test $# -lt 2 ; then
        echo "Expect <repo> <ref> [new-branch]"
        return
    fi
    as=$1
    ref=$2
    branchit=$3
    repo=$(resolve-lesson $as)
    MINUSB=-b
    if [[ "$FORCE" != "" ]] ; then
        MINUSB=-B
    fi
    (cd ,,$as && {
            git checkout $ref
            if [[ "$branchit" != "" ]] ; then
                git checkout $MINUSB $branchit
            fi
    })
}
do-singlepage-generation() {
    if test $# -lt 1 ; then
        echo "Expect <repo>"
        return
    fi
    as=$1
    (cd ,,$as && {
            ../build-singlepage-lesson.sh
    })
}
do-check-justmerged() {
    if test $# -lt 2 ; then
        echo "Expect <repo> <pr>"
        return
    fi
    as=$1
    pr=$2
    repo=$(resolve-lesson $as)
    (cd ,,$as && {
            git log --oneline  -1 | grep -q "$pr"
    })
}
do-add-csspandoc() {
    if test $# -lt 2 ; then
        echo "Expect <repo> <version>"
        return
    fi
    as=$1
    vers=$2
    repo=$(resolve-lesson $as)
    css=css/swc.css
    (cd ,,$as && {
            if grep -q 'version added automatically' $css ; then
                echo "INFO: seems already patched, removing the end of it"
                \cp $css ,,css
                cat ,,css | awk '/version added automatically/ {exit} {print}' > "$css"
            fi
            gen-css $vers banner >> $css
            git add $css
            git commit $MORECOMMIT -m "Added version ($vers) to all pages via CSS"
    })
}
do-rebuild-pandoc() { # old
    if test $# -lt 2 ; then
        echo "Expect <repo> <version>"
        return
    fi
    as=$1
    vers=$2
    repo=$(resolve-lesson $as)
    (cd ,,$as && {
            make clean preview
            git add *.html
            git commit -m "Rebuilt HTML files for release $vers"
    })
}
do-build-jekyll() {
    if test $# -lt 2 ; then
        echo "Expect <repo> <version>"
        return
    fi
    as=$1
    vers=$2
    repo=$(resolve-lesson $as)
    (cd ,,$as && {
            echo ""        >> _config.yml
            echo "github:" >> _config.yml
            echo "  url: '/swc-releases/$vers/$as'" >> _config.yml
            echo ""        >> _config.yml
            git add _config.yml

            make clean site
            cd _site
            find -maxdepth 1 -exec cp -rf {} ../ \; -exec git add ../{} \;
            git commit \
                -m "${PREFIXMESSAGE}Rebuilt HTML files for release $vers" \
                -m "jekyll version: $(jekyll --version)"
    })
}
do-add-css() {
    if test $# -lt 2 ; then
        echo "Expect <repo> <version>"
        return
    fi
    as=$1
    vers=$2
    repo=$(resolve-lesson $as)
    css=assets/css/lesson.css
    (cd ,,$as && {
            if grep -q 'version added automatically' $css ; then
                echo "INFO: seems already patched, removing the end of it"
                \cp $css ,,css
                cat ,,css | awk '/version added automatically/ {exit} {print}' > "$css"
                rm -f ,,css
            fi
            gen-css $vers navbar-header >> $css
            git add $css
            git commit $MORECOMMIT -m "${PREFIXMESSAGE}Added version ($vers) to all pages via CSS"
    })
}
do-diff-log() {
    if test $# -lt 1 ; then
        echo "Expect <repo>"
        return
    fi
    as=$1
    repo=$(resolve-lesson $as)
    (cd ,,$as && {
            git diff HEAD~
            git log
    })
}
do-push() {
    if test $# -lt 1 ; then
        echo "Expect <repo>"
        return
    fi
    as=$1
    repo=$(resolve-lesson $as)
    (cd ,,$as && {
            echo "Will git push unless you Ctrl+C (press enter to continue)"
            $READ read DUMMY
            $PUSH git push $MOREPUSH
    })
}
do-push-upstream() {
    if test $# -lt 2 ; then
        echo "Expect <repo> <version>"
        return
    fi
    as=$1
    vers=$2
    repo=$(resolve-lesson $as)
    (cd ,,$as && {
            echo "Will git push unless you Ctrl+C (press enter to continue)"
            $READ read DUMMY
            $PUSH git push $MOREPUSH --set-upstream origin $vers
    })
}

do-1() {
    for i in shell-novice git-novice hg-novice sql-novice-survey python-novice-inflammation r-novice-inflammation ; do

        v=2015.08
        #do-clone $i

        FORCE=1 do-checkout $i v5.3 $v
        do-add-csspandoc $i $v
        #do-diff-log $i

        #MOREPUSH=--force
        READ=echo do-push-upstream $i $v
    done
}

# this has not been used in the end
do-postBBQ() {
    for i in shell-novice git-novice hg-novice sql-novice-survey python-novice-inflammation r-novice-inflammation ; do

        v=2016.06-beta
        do-clone $i # if not cloned yet (else, comment it)

        do-checkout $i gh-pages $v # branch the latest version, as $v
        do-rebuild-pandoc # if need to rebuilt (need a recent PANDOC)
        do-add-csspandoc $i $v
        #do-diff-log $i  # to see what changed

        do-push-upstream $i $v
        #MOREPUSH=--force     do-push-upstream $i $v    # to force push
    done
    echo "If you pushed to all repositories, you can go on with:"
    echo "make 2016.06-beta"
    echo "git commit"
    echo "git push"
}




do-2() {
    for i in shell-novice git-novice hg-novice sql-novice-survey python-novice-inflammation r-novice-inflammation ; do
        v=2016.06-alpha
        do-clone $i
        do-checkout $i $v
        do-rebuild-pandoc $i $v
        do-diff-log $i
        do-push-upstream $i $v
    done
    # make update-submodules
}

# for "final" release 2016-06 (in July)
# changes in templates were just merged and there is a list to check
do-2016-06-from-gvwilson-list() {
    # git-novice -> accept 43ab1eb instead of pr 308
    local corelessonswithcheck="https://github.com/swcarpentry/git-novice,10.5281/zenodo.57467,https://github.com/swcarpentry/git-novice/pull/43ab1eb https://github.com/swcarpentry/hg-novice,10.5281/zenodo.57469,https://github.com/swcarpentry/hg-novice/pull/29 https://github.com/swcarpentry/make-novice,10.5281/zenodo.57473,https://github.com/swcarpentry/make-novice/pull/50 https://github.com/swcarpentry/matlab-novice-inflammation,10.5281/zenodo.57573,https://github.com/swcarpentry/matlab-novice-inflammation/pull/70 https://github.com/swcarpentry/python-novice-inflammation,10.5281/zenodo.57492,https://github.com/swcarpentry/python-novice-inflammation/pull/284 https://github.com/swcarpentry/r-novice-gapminder,10.5281/zenodo.57520,https://github.com/swcarpentry/r-novice-gapminder/pull/169 https://github.com/swcarpentry/r-novice-inflammation,10.5281/zenodo.57541,https://github.com/swcarpentry/r-novice-inflammation/pull/223 https://github.com/swcarpentry/shell-novice,10.5281/zenodo.57544,https://github.com/swcarpentry/shell-novice/pull/426 https://github.com/swcarpentry/sql-novice-survey,10.5281/zenodo.57551,https://github.com/swcarpentry/sql-novice-survey/pull/140 https://github.com/swcarpentry/lesson-example,10.5281/zenodo.58153 https://github.com/swcarpentry/instructor-training,10.5281/zenodo.57571 https://github.com/swcarpentry/workshop-template,10.5281/zenodo.58156"
    for tuple in $corelessonswithcheck ; do
        set -- $(echo $tuple | tr ',' ' ')
        local lesson=${1##https://github.com/swcarpentry/}
        local doi=${2}
        local pr=${3##*/}
        echo ------ $lesson --- $pr --- $doi

        v=2016.06
        test -d ,,$lesson || do-clone $lesson # lazy clone during tuning

        #do-check-justmerged $lesson "$pr" || {
        #    echo \"$pr\" not found in latest message
        #    return
        #}
        # branch the latest version, as $v, force it as there are old 2016.06 around
        FORCE=1 do-checkout $lesson gh-pages $v
        export PREFIXMESSAGE="[DOI: $doi] "
        do-build-jekyll $lesson $v
        do-add-css $lesson $v

        MOREPUSH=--force READ=echo 
        do-push-upstream $lesson $v

        echo "-------"
    done
}
# after addition of CITATION
# do-2016-06-remerge-ghpages() {
#     for lesson in git-novice hg-novice make-novice matlab-novice-inflammation python-novice-inflammation r-novice-gapminder r-novice-inflammation shell-novice sql-novice-survey lesson-example instructor-training workshop-template ; do
#         v=2016.06
#         test -d ,,$lesson || do-clone $lesson # lazy clone during tuning
#         do-checkout $lesson $v
#         as=$lesson
#         vers=$v
#         (cd ,,$as && {
#                 git fetch
#                 git merge 
#                 gen-css $vers navbar-header >> $css
#                 git add $css
#                 git commit $MORECOMMIT -m "${PREFIXMESSAGE}Added version ($vers) to all pages via CSS"
#                 })
#     done
# }
do-reset-,,-to-ghpages() {
    for da in ,,* ; do
        echo $da
        git -C $da/ checkout -B gh-pages origin/gh-pages
    done
}
do-preview-all-jekyll-in-turn() {
    for folder in ,,* ; do
        cd $folder
        echo "USE CRTL+C TO STOP JEKYLL AND GO TO THE NEXT LESSON"
        jekyll serve
        cd -
    done
}

gen-css() {
        cat <<EOF
/* version added automatically */
div.$2::before {
    content: "Version $1";
    font-size: 10px;
    font-family: monospace;
    font-weight: bold;
    line-height: 1;
    /* */
    position: fixed;
    right: 0;
    top: 0;
    z-index: 10;
    /* */
    color: white;
    background: rgb(43, 57, 144);
    padding: 3px;
    border: 1px solid white;
}
EOF
}







# this one may need to be updated once we use the new build system
clonelatest-branch-build-commit() {
    if test $# -lt 2 ; then
        echo "Expect <repo> <version>"
        return
    fi
    clone-branch-build-commit "$1" gh-pages "$2"
}

clone-branch-build-commit() {
    if test $# -lt 3 ; then
        echo "Expect <repo> <ref> <version>"
        return
    fi
    as=$1
    ref=$2
    vers=$3
    repo=$(resolve-lesson $as)
    git clone $repo ,,$as --depth=1 --no-single-branch && cd ,,$as && ({
        git checkout $ref
        git checkout -b $vers
        make clean preview
        git add *.html
        git commit -m "Rebuilt HTML files for release $vers" && git diff HEAD~
        git log
        echo Will git push unless you Ctrl+C
        $READ read DUMMY
        $PUSH git push --set-upstream origin $vers
        cd -
    } || cd -)
}







# this one was used to generate the alpha version, using the latest master at the time
custom1() {
    for i in shell-novice git-novice hg-novice sql-novice-survey python-novice-inflammation r-novice-inflammation ; do
        clonelatest-branch-build-commit $i 2016.06-alpha
    done
}

# this one to add (or readd with the parameters) the css patch to the alpha version
custom2() {
    for i in shell-novice git-novice hg-novice sql-novice-survey python-novice-inflammation r-novice-inflammation ; do
        echo '### ' $i
        MORECOMMIT=--amend MOREPUSH=--force patchcss-commit $i 2016.06-alpha
    done
}

# (1 shot), to create the 2015.08 from v5.3
custom4() {
    for i in shell-novice git-novice hg-novice sql-novice-survey python-novice-inflammation r-novice-inflammation ; do
        READ=echo PUSH=echo clone-branch-build-commit $i v5.3 2015.08
    done
}

# test generation of single pages, 2016.06
custom-singlepages-1() {
    WIPSKIP=echo
    local odir=swc-single-page/
    rm -rf "./$odir"
    mkdir -p $odir
    local o=$odir/index.html
    cat <<EOF > $o
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>SWC Lessons: Single Page Versions</title>
    <link rel="stylesheet" href="picnic.min.css">
  </head>
  <body style="margin: 0 2em;">
    <p>NB: <tt>-zoom</tt> versions are designed for ebook reading (4:3 aspect ratio).</p>
    <p>NB: <tt>-browser</tt> versions include all styling.</p>
    <p>NB: <tt>.epub</tt> versions are ebooks with almost no styling.</p>
EOF
    for i in git-novice hg-novice make-novice matlab-novice-inflammation python-novice-inflammation r-novice-gapminder r-novice-inflammation shell-novice sql-novice-survey lesson-example ; do

        v=gh-pages
        test -d ,,$i || do-clone $i # lazy clone during tuning

        $WIPSKIP do-checkout $i $v
        $WIPSKIP do-singlepage-generation $i

        echo "    <h3>$i</h3>" >> $o
        echo "    <ul>" >> $o
        local d=,,$i
        cp -r $d/_site $odir/$i
        (cd $odir/$i && {
                for j in single-page*.{pdf,epub,html} ; do
                    mv $j $i${j#single-page}
                    echo "      <li><a href='$i/$i${j#single-page}'>$i${j#single-page}</a></li>" >> ../../$o
                done
                cd -
            } || cd -)
        echo "    </ul>" >> $o
    done
    test -f stats.code && cat stats.code >> $o
    echo '  </body>' >> $o
    echo '</html>' >> $o

    if [[ "$DL" != "" ]] ; then
        wget https://raw.githubusercontent.com/picnicss/picnic/master/picnic.min.css -O $odir/picnic.min.css
        $WIPSKIP rsync -avzu $odir $DL/$odir
    fi
}


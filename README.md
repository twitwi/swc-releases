# swc-releases
Container for Software Carpentry lesson releases

- <http://swcarpentry.github.io/swc-releases/2016.06/>
- <http://swcarpentry.github.io/swc-releases/2015.08/> (5.3)

<!-- - <http://swcarpentry.github.io/swc-releases/2016.06-alpha/> (pre-bbq) -->



# Release Model: how the 2016.06 release was done

Generally, the complete release is a two step process:

- branch and build on each lesson, pushing the changes
- create a folder and submodules, on the swc-releases

Both steps are currently semi-automated.
Some more details on these two steps are given here.

## Preparing all lessons for the release

This step has been automated by a bash function defined in `tools-for-lesson-maintainers.sh` (swc-releases repository) and that has been run with:

    . tools-for-lesson-maintainers.sh
    do-2016-06-from-gvwilson-list

This function will do the following for each lesson, e.g., for git-novice with version 2016.06:

- clone the repository as ,,git-novice if not already present (warning: one might need to remove the folder if changes have been push to github since the checkout)
- create a new branch 2016.06 from the latest gh-pages version
- build the lesson, setting the Jekyll path to work on the swc-releases site
- copy the files that were just built and commit them
- patch the css to show the version number and commit it
- push the new branch

NB: the two commits are prefixed with the DOI of the lesson.

NB: one need push access rights to all repositories to do that. The alternative is to have individual lesson maintainers do these steps.

The function can be copied and adapted for another new release.


## Populating the swc-releases repository

This step has been automated and live in this repository, where the main entry point is the Makefile.
To make the release, the following commands has been run:

    make 2016.06
    git commit -m 'Release 2016.06'
    git push

To be able to run this, the following preparation has been necessary:

- modify the Makefile to add the 2016.06 entry, and creating `CORE_LESSONS_B` (necessary only when the list of lessons changed)

When run, `make 2016.06` will run `make-or-update-release.sh` that will do the following:

- create a `2016.06` folder
- adding in this folder, one submodule per lesson (that tracks the `2016.06` branch of the lesson repository)
- generating an (ugly) HTML page `2016.06/index.html`
- adding everything so it is ready to commit
- encouraging the user to git commit and push



# About lessons using R (and RMarkdown in .rmd files)

One need to install R and some packages to build the lessons.

Installing R is platform dependent, e.g., under some linux distributions you can use `apt-get install r-base`.

One can then install the necessary packages by starting R and running:

    install.packages("knitr")
    install.packages("tidyr")
    install.packages("dplyr")
    install.packages("plyr")
    install.packages("DiagrammeR")
    install.packages("ggplot2")
    install.packages("devtools")
    install.packages("roxygen2")
    install.packages("checkpoint")



# Troubleshooting and help when having to do a release multiple times

## help with preparing lessons

In case the preparation process needs to be re-run, for instance because the build process need to be tuned, one may use the following tools (some functions are defined in `tools-for-lesson-maintainers.sh`).

- `rm -rf ,,*` to remove all checked out lessons: this can be useful if some changes, that needs to be integrated has been pushed on github since the clone
- `do-reset-,,-to-ghpages` to switch all checked out lesson repositories to the gh-pages branch (in case we want to rerun the script and that the script checks the current state of the repo, as done by the commented-out `do-check-justmerged` in do-2016-06-from-gvwilson-list)

## help with populating swc-releases

- `make check-submodules` to check that the revisions that submodules reference still exist on github (an absence causes Jekyll build issues)
- `rm -rf 2016.06` and `make clean-failure` to remove the generated folder and submodules
- IMPORTANT: also `rm -rf .git/modules/2016.06` to remove the submodule cache, in case some content has been force pushed to the lessons
- `git rebase -i HEAD^^` and later `git push --force` to rewrite history with a new version
- `make update-submodules` after uncommenting the necessary line in the Makefile: to update the submodules if new commits have been added to the 2016.06 branches in any lesson repository (need to then add/commit/push)




<!-- old stuff, more detailed but not totally in line with the fact that we now use Jekyll -->

# (old, still somewhat meaningful) Tentative Instructions for post bbq release

These instructions should help doing the release.
An informed release maintainer can also look at `tools-for-lesson-maintainers.sh` that contains script snippets that aim at automating the process.

## Step 1: Lesson Maintainers

NB: the HTML pages can be built before (on the gh-pages branch) or after (only in the release branch).

IMPORTANT: your pandoc version may matter for building the pages, see this thread <http://lists.software-carpentry.org/pipermail/discuss/2016-June/004553.html> (1.12 seems to not be fine with some source files, even if you don't see any errors when building) (some code blocks don't have newlines, classes are missing, etc)

You should already be on the gh-pages branch, but, if not, switch to it:

    git checkout gh-pages

Once the lesson (it's main gh-pages branch) is in a state to be release, the first step is to create a new branch that will be named `2016.06-beta`.

    git checkout -b 2016.06-beta
    # (use -B if you need to start over and force the re-creation of the branch)

If the HTML pages were not built yet, do it now and commit with a relevant message, the commands might look like this:

    # example to build the HTML pages and commit
    make clean preview
    git add *.html
    git status
    git commit -m "Rebuilt HTML files for release 2016.06-beta"
    
Then we will patch the css, so that the version is displayed on all pages.
Open the `css/swc.css` file and add, at the end, the following block (including the comments):

```{css}
/* version added automatically */
div.banner::before {
    content: "Version 2016.06-beta";
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
```

Then commit this change with:

    git add css/swc.css
    git commit -m "Added version (2016.06-beta) to all pages via CSS"

Then push the branch:

    git push --set-upstream origin 2016.06-beta
    # use --force if you had already pushed the branch and started over

And you can switch back to the main branch:

    git checkout gh-pages


## Step 2: Release Maintainer

Once all maintainers have created their branches, the release can be initiated.

The Makefile has already been prepared (if curious, look for 2016.06-beta inside), so you need to run:

    make 2016.06-beta
    # (and wait some time for the submodules to be added)

Then you can briefly review and commit:

    git status
    git commit -m "Release 2016.06-beta (after Bug BBQ)"

And finally push:

    git push

After letting some time to github to rebuild the site, you should see the release at <http://swcarpentry.github.io/swc-releases/2016.06-beta/> and each lessons should "work" and have a small banner with the version.




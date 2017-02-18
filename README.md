# release.sh
A shell script for building and releasing go programs on Github

## Why

I wrote this because I kept doing the same things over and over when releasing
go programs to github, so I automated it and decided it could be used here for
everyone.

## How

First you'll want some environment variables setup:

`$GITHUB_API_TOKEN` 

is required as we use this to create the release on github,
if you leave this blank we just build the program for the architectures and
skip releasing on githu.

`$OWNER`

OWNER is the owner of the github repo (i.e. 
`https://github.com/:owner/:repo_name`) if you leave this blank we assume
`$USER` which can cause some weirdness obviously if you don't use your github
username as your unix username.





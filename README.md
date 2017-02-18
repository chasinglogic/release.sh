# release.sh
A shell script for building and releasing go programs on Github

## Why

I wrote this because I kept doing the same things over and over when releasing
go programs to github, so I automated it and decided it could be used here for
everyone.

## How

First you'll want some optional environment variables setup:

`$ARCHES` && `$PLATFORMS`

These are arrays of the platforms and architectures you want to build for, the
defaults are `("amd64" "386")` and `("linux" "darwin" "windows")` respectively

`$GITHUB_API_TOKEN` 

We use this to create the release on github, if you leave this unset we just 
build the program for the platforms/architectures provided and skip releasing 
on github.

`$OWNER`

This is the owner of the github repo (i.e. 
`https://github.com/:owner/:repo_name`) if you leave this unset we assume
`$USER` which can cause some weirdness obviously if you don't use your github
username as your unix username.

### Installation

The easiest way to get release.sh is via curl which you need to run the script
anyway:

`curl -OSL https://raw.githubusercontent.com/chasinglogic/release.sh/master/release.sh`

Then set the executable permission on the downloaded script

`chmod +x release.sh`

### Use

```
Usage: 
    ./release.sh tag_name name_of_release prelease_bool:optional

Examples:
    This would deploy to tag v0.0.1 naming the release MVP and specify it is a 
    prerelease

    ./release.sh v0.0.1 MVP true

    If the 3rd argument is omitted we assume it is a normal release

    ./release.sh v1.0.0 "Aces High"
```

**NOTE:** If you specify any third argument it is assumed you want a prelease.

You should run release.sh in the root of your project directory otherwise
strange things may happen and you'll end up in the upside down.

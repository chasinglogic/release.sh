#!/bin/bash
# 
# Author: Mathew Robinson <chasinglogic@gmail.com>
# 
# This script builds fnd and deploys it to Github
#

function parse_git_branch {
    ref=$(git symbolic-ref HEAD 2> /dev/null) || return
    echo "${ref#refs/heads/} "
}

BRANCH=$(parse_git_branch)

if [ $BRANCH != "master" ] && [ $BRANCH != "develop" ]; then
    echo "you aren't on master or develop, refusing to package a release"
    exit 1
fi

function check_if_success() {
    if [ $? -ne 0 ]; then
        echo "error running last command"
        exit $?
    fi
}

function print_help() {
    echo "Usage: 
    ./package.sh tag_name name_of_release prelease_bool:optional

Examples:
    This would deploy to tag v0.0.1 naming the release MVP and specify it is a 
    prerelease

    ./package.sh v0.0.1 MVP true

    This would deploy to tag v1.0.0 naming the release Aces High and specify it
    as not a prerelease

    ./package.sh v1.0.0 \"Aces High\" false

    Alternatively prelease_bool can be omitted (defaults: false)

    ./package.sh v1.0.0 \"Aces High\""
}

if [ "$1" == "--help" ] || [ "-h" == "$1" ]; then
    print_help
    exit 0
fi

if [ "$#" -ne 3 ] && [ "$#" -ne 2 ]; then
    echo "wrong number of arguments $#"
    print_help
    exit 1
fi

TAG_NAME=$1
RELEASE_NAME=$2
PRERELEASE=$3
STARTING_DIR=$(pwd)

if [ -z "$OWNER" ]; then
    OWNER=$USER
fi

if [ -z "$PROGRAM" ]; then
    PROGRAM=`pwd | awk -F\/ '{print $(NF)}'`
fi

if [ -z "$ARCHES" ]; then
    ARCHES=("amd64" "386")
fi

if [ -z "$PLATFORMS" ]; then
    PLATFORMS=("linux" "darwin" "windows")
fi

echo "Tag Name: $TAG_NAME"
echo "Release Name: $RELEASE_NAME"
echo "Prelease: $PRERELEASE"
echo "Program: $PROGRAM"
echo "Building for Arches: ${ARCHES[@]}"
echo "Building for Platforms: ${PLATFORMS[@]}"
echo "Repo Owner: $OWNER"

exit 0

echo "Checking for dependencies..."
if ! [ -x "$(command -v go)" ]; then
    echo "You need to install the go tool. https://golang.org/download"
    exit 1
fi

if [ -d "build" ]; then
    echo "cleaning build directory..."
    rm -rf build
fi

# create the final build directories
mkdir build/

# install deps 
echo "installing dependencies"
if [ -x "$(command -v glide)" ] || [ -f "glide.yaml" ]; then
    echo "glide detected using it to install dependencies..."
    glide install
else
    go get ./...
fi

PACKAGES=()

for platform in "${PLATFORMS[@]}"
do
    for arch in "${ARCHES[@]}"
    do
        echo "compiling the backend for $platform-$arch"
        mkdir build/$platform-$arch

        if [ "$platform" == "windows" ]; then
            GOOS=$platform GOARCH=$arch go build -o build/$GOOS-$GOARCH/$PROGRAM.exe >/dev/null
        else
            GOOS=$platform GOARCH=$arch go build -o build/$GOOS-$GOARCH/$PROGRAM >/dev/null
        fi

        # make sure builds worked
        check_if_success

        echo "building release tar"
        cd build/$platform-$arch

        PACKAGE_NAME="$PROGRAM-$TAG_NAME-$platform-$arch.tar.gz"
        if [ "$platform" == "windows" ]; then
            PACKAGE_NAME="$PROGRAM-$TAG_NAME-$platform-$arch.zip"
        fi

        echo $PACKAGE_NAME
        PACKAGES+=("$PACKAGE_NAME")

        if [ -f "$STARTING_DIR/$PACKAGE_NAME" ]; then
            echo "old package detected removing..."
            rm $STARTING_DIR/$PACKAGE_NAME
        fi

        if [ "$platform" == "windows" ]; then
            zip $STARTING_DIR/$PACKAGE_NAME *
        else
            tar czf $STARTING_DIR/$PACKAGE_NAME *
        fi

        cd $STARTING_DIR
    done
done

# create the tag
echo "tagging release..."
git tag -a $TAG_NAME -m $RELEASE_NAME

# push the tag
echo "Pushing tags..."
git push --follow-tags

if [ -z "$GITHUB_API_TOKEN" ]; then
    echo "no github token detected all done."
    exit 0
fi

GITHUB_URL="https://api.github.com/repos/$OWNER/$PROGRAM/releases?access_token=$GITHUB_API_TOKEN"
JSON="{ \"tag_name\": \"$TAG_NAME\", \"name\": \"$RELEASE_NAME\", \"body\": \"$PROGRAM release $RELEASE_NAME\", \"target_commitsh\": \"master\" }"

echo $JSON
echo $GITHUB_URL

RESP=$(curl -X POST --data "$JSON" $GITHUB_URL)
ASSETS_URL=$(echo "$RESP" | grep -oP '(?<="assets_url": ")(.*)(?=")')

for pkg in "${PACKAGES[@]}"
do
    echo "uploading $pkg"
    UPLOAD_URL="$ASSETS_URL?name=$PKG&access_token=$GITHUB_API_TOKEN"

    if [ -z "$(echo $pkg | grep -o ".zip")" ]; then
        HEADERS="Content-Type:application/zip"
    else
        HEADERS="Content-Type:application/gzip"
    fi

    curl -X POST --headers $HEADERS --data-binary $STARTING_DIR/$pkg $UPLOAD_URL
done

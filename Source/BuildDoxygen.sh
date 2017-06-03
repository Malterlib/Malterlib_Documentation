#!/bin/bash

trap 'rc=$?; echo "${BASH_SOURCE}:${LINENO}: error: Trapped error: $rc"; exit $rc' ERR

set -e

ScriptDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

OutputDirectory="$1"
MalterlibMainMalterlibRepo="$2"

unset MACOSX_DEPLOYMENT_TARGET
unset SDKROOT
unset PRODUCT_SPECIFIC_LDFLAGS
unset OTHER_CFLAGS_ONLY

if [ ! -e "$OutputDirectory" ]; then
	mkdir -p "$OutputDirectory"
	git clone -b malterlib --recursive https://github.com/Malterlib/doxygen.git "$OutputDirectory/doxygen"
fi

pushd "$OutputDirectory/doxygen" > /dev/null

VersionTimeFile="$ScriptDir/doxygen.versiontime"

ExpectedVersionTime=""
if [ -e "$VersionTimeFile" ]; then
	ExpectedVersionTime=`cat "$VersionTimeFile"`
fi

VersionTime=`git for-each-ref --format='%(committerdate:unix)' refs/heads/malterlib`

if [[ $ExpectedVersionTime != "" ]] && [[ $VersionTime < $ExpectedVersionTime ]]; then
	echo Fetching new llvm version
	git fetch origin malterlib
	git reset --hard origin/malterlib
	git pull
	VersionTime=`git for-each-ref --format='%(committerdate:unix)' refs/heads/malterlib`
fi

if [[ "$ExpectedVersionTime" == "" ]] || [[ $VersionTime > $ExpectedVersionTime ]]; then
	if [[ "$MalterlibMainMalterlibRepo" == "true" ]]; then
		echo $VersionTime > "$VersionTimeFile"
	fi
fi

BuildTimeFile="$OutputDirectory/build/buildversiontime"

BuildTime=""
if [ -e "$BuildTimeFile" ]; then
	BuildTime=`cat "$BuildTimeFile"`
fi

if [[ "$BuildTime" == "$VersionTime" ]]; then
	exit 0
fi

popd

pushd "$OutputDirectory"

mkdir -p build
pushd build
cmake ../doxygen
NCPUS=`sysctl -n hw.ncpu`
echo Number of CPUs: ${NCPUS}
make -j${NCPUS}
popd

echo $VersionTime > "$BuildTimeFile"

#!/usr/bin/env bash

set -e

patches=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
tree="$2"
targetted_project="$3"
excluded_project="$(grep '!' <<< "$targetted_project")"
[ "$excluded_project" = "" ] && targetted_project=""

echo "Applying ${tree} patches:"
[ -d "$patches/$tree" ] || { echo "  (no patches for tier '$tree', skipping)"; exit 0; }

for project in $(cd "$patches"/"$tree"; echo *); do
    echo "> ${project}"
    p="$(tr _ / <<<"$project" |sed -e 's;platform/;;g')"
    [ "$p" == build ] && p=build/make
    [ "$p" == testing ] && p=platform_testing
    [ "$p" == treble/app ] && p=treble_app
    [ "$p" == vendor/hardware/overlay ] && p=vendor/hardware_overlay
    [ "$p" == vendor/partner/gms ] && p=vendor/partner_gms

    [ "$targetted_project" != "" ] && [ "$p" != "$targetted_project" ] && continue;
    [ "$excluded_project" != "" ] && [ "$p" == "$(sed -nE "s/!(.+)/\1/p" <<< "$excluded_project")" ] && continue;

    pushd "$p"
    for patch in "$patches"/"$tree"/"$project"/*.patch; do
        echo ">> ${patch}"
        if test -d .git; then
            git am "$patch" || { git am --abort; [ "${IGNORE_BORKED_PATCHES:-false}" = "true" ] || exit 1; }
        else
            patch -p1 --no-backup-if-mismatch < "$patch" || { [ "${IGNORE_BORKED_PATCHES:-false}" = "true" ] || exit 1; }
        fi
    done
    popd
done

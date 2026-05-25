#!/usr/bin/env bash
set -e

export PROJECT_ROOT_FULL_PATH=$(pwd)
export ANDROID_HOME="${ANDROID_HOME:-$HOME/Library/Android/sdk}"

ANDROID_BUILD_DIR=local_eas_builds/android
IOS_BUILD_DIR=local_eas_builds/ios
ARTIFACTS_DIR=local_eas_builds/artifacts

mkdir -p "$PROJECT_ROOT_FULL_PATH/$ANDROID_BUILD_DIR"
mkdir -p "$PROJECT_ROOT_FULL_PATH/$IOS_BUILD_DIR"
mkdir -p "$PROJECT_ROOT_FULL_PATH/$ARTIFACTS_DIR"

print_usage() {
    echo "Usage: $0 [ios|android] [production|production-apk|staging|development-aab|development-apk|development|internal-adhoc]"
    echo "  -h  Display this help message."
}

while getopts ":h" option; do
    case "${option}" in
        h) print_usage; exit 0 ;;
        *) print_usage; exit 1 ;;
    esac
done
shift $((OPTIND-1))

if [ $# -ne 2 ]; then
    print_usage
    exit 1
fi

if [ "$1" != "ios" ] && [ "$1" != "android" ]; then
    echo "The first argument must be 'ios' or 'android'."
    exit 1
fi

if [ "$2" != "production" ] && [ "$2" != "production-apk" ] && [ "$2" != "staging" ] && [ "$2" != "development-aab" ] && [ "$2" != "development-apk" ] && [ "$2" != "development" ] && [ "$2" != "internal-adhoc" ]; then
    echo "The second argument must be 'production' or 'production-apk' or 'staging' or 'development-aab' or 'development-apk' or 'development' or 'internal-adhoc'."
    exit 1
fi

cd "$PROJECT_ROOT_FULL_PATH/apps/expo"

if [ "$1" == "ios" ]; then
    echo "Building ios $2"
    NODE_ENV=development \
    EAS_LOCAL_BUILD_SKIP_CLEANUP=0 \
    EAS_LOCAL_BUILD_WORKINGDIR=$PROJECT_ROOT_FULL_PATH/$IOS_BUILD_DIR \
    EAS_LOCAL_BUILD_ARTIFACTS_DIR=$PROJECT_ROOT_FULL_PATH/$ARTIFACTS_DIR \
    eas build --platform ios --profile $2 --local
elif [ "$1" == "android" ]; then
    echo "Building android $2"
    NODE_ENV=development \
    EAS_LOCAL_BUILD_SKIP_CLEANUP=0 \
    EAS_LOCAL_BUILD_WORKINGDIR=$PROJECT_ROOT_FULL_PATH/$ANDROID_BUILD_DIR \
    EAS_LOCAL_BUILD_ARTIFACTS_DIR=$PROJECT_ROOT_FULL_PATH/$ARTIFACTS_DIR \
    eas build --platform android --profile $2 --local
fi

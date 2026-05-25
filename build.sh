#!/usr/bin/env bash
set -e

export PROJECT_ROOT_FULL_PATH=$(pwd)

ANDROID_BUILD_DIR=local_eas_builds/android
IOS_BUILD_DIR=local_eas_builds/ios
ARTIFACTS_DIR=local_eas_builds/artifacts

mkdir -p "$PROJECT_ROOT_FULL_PATH/$ANDROID_BUILD_DIR"
mkdir -p "$PROJECT_ROOT_FULL_PATH/$IOS_BUILD_DIR"
mkdir -p "$PROJECT_ROOT_FULL_PATH/$ARTIFACTS_DIR"

print_usage() {
    echo "Usage: $0 [ios|android] [production|production-apk|staging|development-aab|development-apk|development|internal-adhoc] [--local]"
    echo "  --local    Build locally (requires Android SDK or Xcode)"
    echo "  (default)  Build remotely on EAS servers"
    echo "  -h         Display this help message."
}

REMOTE=true

while getopts ":hl-:" option; do
    case "${option}" in
        h) print_usage; exit 0 ;;
        -) case "${OPTARG}" in
               local) REMOTE=false ;;
               *) print_usage; exit 1 ;;
           esac ;;
        *) print_usage; exit 1 ;;
    esac
done
shift $((OPTIND-1))

# Check for --local in remaining args
for arg in "$@"; do
    if [ "$arg" == "--local" ]; then REMOTE=false; fi
done

# Filter out --local from args
ARGS=()
for arg in "$@"; do
    if [ "$arg" != "--local" ]; then ARGS+=("$arg"); fi
done

if [ ${#ARGS[@]} -ne 2 ]; then
    print_usage
    exit 1
fi

PLATFORM="${ARGS[0]}"
PROFILE="${ARGS[1]}"

if [ "$PLATFORM" != "ios" ] && [ "$PLATFORM" != "android" ]; then
    echo "The first argument must be 'ios' or 'android'."
    exit 1
fi

VALID_PROFILES="production production-apk staging development-aab development-apk development internal-adhoc"
if ! echo "$VALID_PROFILES" | grep -qw "$PROFILE"; then
    echo "The second argument must be one of: $VALID_PROFILES"
    exit 1
fi

cd "$PROJECT_ROOT_FULL_PATH/apps/expo"

if [ "$REMOTE" = true ]; then
    echo "Building $PLATFORM $PROFILE (remote)"
    eas build --platform "$PLATFORM" --profile "$PROFILE"
else
    echo "Building $PLATFORM $PROFILE (local)"
    export ANDROID_HOME="${ANDROID_HOME:-$HOME/Library/Android/sdk}"
    NODE_ENV=development \
    EAS_LOCAL_BUILD_SKIP_CLEANUP=0 \
    EAS_LOCAL_BUILD_WORKINGDIR="$PROJECT_ROOT_FULL_PATH/$([ "$PLATFORM" = "ios" ] && echo "$IOS_BUILD_DIR" || echo "$ANDROID_BUILD_DIR")" \
    EAS_LOCAL_BUILD_ARTIFACTS_DIR="$PROJECT_ROOT_FULL_PATH/$ARTIFACTS_DIR" \
    eas build --platform "$PLATFORM" --profile "$PROFILE" --local
fi

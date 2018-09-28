#!/bin/bash

# binDir="./build/pipeline"
curDir=$(pwd)
buildDir="./build"
binDir="${buildDir}/bin"
depDir="${buildDir}/deps"
deployDir="${buildDir}/deploy"
buildArch=("386" "amd64")
buildOS=("darwin" "linux")

parseArgs() {
    lastArg=${#@}
    if [[ $lastArg == 1 ]]; then
        lastArg=""
    fi

    for arg in "$@"; do
        case $arg in
            -u)
                unitTests
            ;;
            -b)
                buildBinaries
            ;;
            -g)
                gatherDeps
            ;;
            -a)
                gatherDeps
                unitTests
                buildBinaries
            ;;
            -d)
                buildDeploy
            ;;
            -c)
                cleanupBuild
            ;;
            -h)
                printHelp
            ;;
        esac
    done
}

header() {
    msg="${1}"
    padding=$(((80+${#msg})/2))
    div="================================================================================"
    printf "\n%s\n%${padding}s\n%s\n" "$div" "$msg" "$div"
}

printHelp() {
    echo "Usage: $(basename "$0") [-c|-t|-h] ([-u|-b|-a]... | [-p|-p PLUGIN] | [-d/-D|-d/-D PLUGIN])"
    echo "Options:"
    echo "-u    Run all unittests (BROKEN)"
    echo "-b    Build pipeline binaries (BROKEN)"
    echo "-g    Gather dependencies"
    echo "-a    Gather deps, run unittests, build binaries (BROKEN)"
    echo "-d    Build everything needed to deploy to a VM"
    echo "-c    Clean up the build directory"
    echo "-h    Show this help message"
    exit
}

# TODO: FIX THIS
#unitTests() {
#    testPipeline
#}

# TODO: FIX THIS
#testPipeline() {
#    header "Testing pipeline..."
#    go test -i "./"
#    go test -v "./..." || exit 2
#}

# parameters:
# - OS to build for
# - architecture to build for
# - directory of source code to build
# - name of binary to build
buildBinary() {
    targetOS=${1}
    targetArch=${2}
    targetDep=${3}
    targetBinary=${4}

    if [[ "$targetOS" == "darwin" ]] && [[ "$targetArch" == "386" ]]; then
        return
    fi

    header "Building ${targetBinary} for ${targetOS}-${targetArch}..."
    mkdir -p "${binDir}/${targetOS}/${targetArch}"
    # go get -v "."
    cd "${targetDep}"
    # go get -v "${targetDep}" || exit 1
    go get -v . || exit 1

    # TODO: FIX THIS HACKINESS
    cd "${curDir}"
    cd "${targetDep}"
    # env GOOS=${targetOS} GOARCH=${targetArch} go build -a -v -o "${binDir}/${targetOS}/${targetArch}/${targetBinary}" "${targetDep}" || exit 1
    env GOOS=${targetOS} GOARCH=${targetArch} go build -a -v -o "${curDir}/build/bin/${targetOS}/${targetArch}/${targetBinary}" . || exit 1
    cd "${curDir}"

    # env GOOS=${1} GOARCH=${2} go build -a -v -o "${binDir}/${1}/${2}/pipeline" . || exit 1
    # env GOOS=${targetOS} GOARCH=${targetArch} go build -a -v -o "${binDir}/${targetOS}/${targetArach}/pipeline" . || exit 1
    # env GOOS=${targetOS} GOARCH=${targetArch} go build -a -v -o "${binDir}/${targetOS}/${targetArch}/${targetBinary}" "${targetDep}" || exit 1

}

# parameters:
# - name of dependency
# - branch of dependency
# - URL of dependency
getRepoLatest() {
    depName=${1}
    depBranch=${2}
    depURL=${3}

    dst="${depDir}/${depName}"
    if [[ ! -a "$dst" ]]; then
        git clone "${depURL}" "$dst"
        git -C "$dst" checkout "${depBranch}"
        git -C "$dst" pull
    else
        git -C "$dst" checkout "${depBranch}"
        git -C "$dst" pull
    fi
}

gatherDeps() {
    header "Gathering deps..."
    getRepoLatest pipeline docker git@github.rackspace.com:char7232/pipeline.git
    getRepoLatest baseline master git@github.rackspace.com:SecurityEngineering/baseline.git
    getRepoLatest harden master git@github.rackspace.com:SecurityEngineering/harden.git
}

cleanupDeploy() {
    rm -rf ${deployDir}/*
}

buildDeploy() {
    cleanupDeploy
    gatherDeps
    buildBinary linux amd64 "${depDir}/pipeline" pipeline
    buildBinary linux amd64 "${depDir}/harden/cmd/warden" warden-linux

    header "Building pipeline..."
    mkdir -p "${deployDir}/pipeline"
    cp "${binDir}/linux/amd64/pipeline" "${deployDir}/pipeline/pipeline"
    cp ./Dockerfile-pipeline "${deployDir}/pipeline/Dockerfile"
    docker build -t pipeline "${deployDir}/pipeline" || exit 1

    header "Building baseline..."
    cp -r "${depDir}/baseline" "${deployDir}/baseline"
    cp ./Dockerfile-baseline "${deployDir}/baseline/Dockerfile"
    cp "${binDir}/linux/amd64/warden-linux" "${deployDir}/baseline/bin/warden-linux"
    docker build -t baseline "${deployDir}/baseline" || exit 1

    cp docker-compose.yml "${deployDir}"

    header "Packaging deploy.tar.gz..."
    tar -c --exclude ".git*" -zvf ./deploy.tar.gz "${deployDir}" 
}

cleanupBuild() {
    header "Cleaning up..."
    rm -rf "$binDir"
    mkdir -p "$binDir"
    rm -rf "$depDir"
    mkdir -p "$depDir"
}

main() {
    if [[ -z "$(which go)" ]]; then
        echo "Missing 'go' binary. Please ensure environment variables are set properly."
        exit 1
    fi

    goVersion=$(go version | awk {'print $3'})
    if [[ $goVersion != "go1.11" ]]; then
        echo "Go version 1.11 is required."
        exit 1
    fi

    if [[ -z "$(which git)" ]]; then
        echo "Missing 'git' binary."
        exit 1
    fi

    if [[ $# == 0 ]]; then
        echo "Missing command"
        printHelp
    fi
    parseArgs "$@"
}

main "$@"
exit 0

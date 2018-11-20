#!/bin/bash

curDir=$(pwd)
buildDir="./build"
binDir="${buildDir}/bin"
depDir="${buildDir}/deps"
includeDir="./include"
deployDir="${buildDir}/deploy"
buildArch=("386" "amd64")
buildOS=("darwin" "linux")

OPTIND=1
parseArgs() {
    lastArg=${#@}
    if [[ $lastArg == 1 ]]; then
        lastArg=""
    fi

    #for arg in "$@"; do
    while getopts "gdchl:" arg; do
        case ${arg} in
            c)
                cleanupBuild
            ;;
            d)
                buildDeploy
            ;;
            g)
                gatherDeps
            ;;
            h)
                printHelp
            ;;
            l)
                local+=("$OPTARG")
            ;;
        esac
    done
    shift $((OPTIND -1))
}

header() {
    msg="${1}"
    padding=$(((80+${#msg})/2))
    div="================================================================================"
    printf "\n%s\n%${padding}s\n%s\n" "$div" "$msg" "$div"
}

printHelp() {
    echo "Usage: $(basename "$0") [-c|-g|h] (-l [PATH]) [-d]"
    echo "Options:"
    echo "-c         Clean up the build directory"
    echo "-d         Build everything needed to deploy to a VM"
    echo "-g         Gather dependencies"
    echo "-h         Show this help message"
    echo "-l PATH    Local paths to each pipeline component e.g. ../syntribos-rax"
    exit
}

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
    env GOOS=${targetOS} GOARCH=${targetArch} go build -v -o "${curDir}/build/bin/${targetOS}/${targetArch}/${targetBinary}" . || exit 1
    cd "${curDir}"
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
    printf "\n\n"
}

gatherDeps() {
    header "Gathering deps..."
    for path in "${local[@]}"; do
        path="${path%/}/"
        bn=$(basename $path)
        echo "Copying ${path} to $depDir/${bn%'-rax'}"
        rsync -r --exclude-from="${path}/.gitignore" "$path" "$depDir/${bn%'-rax'}"
        printf "\n\n"
    done
    if [ ! -d "${depDir}/pipelib" ]; then
        getRepoLatest pipelib master git@github.rackspace.com:QESecurity/pipelib.git
    fi
    if [ ! -d "${depDir}/baseline" ]; then 
        getRepoLatest baseline master git@github.rackspace.com:QESecurity/baseline.git
    fi
    if [ ! -d "${depDir}/syntribos" ]; then 
        getRepoLatest syntribos master git@github.rackspace.com:QESecurity/syntribos-rax.git
    fi
    if [ ! -d "${depDir}/rax-templates" ]; then 
        getRepoLatest rax-templates master git@github.rackspace.com:QESecurity/syntribos-templates.git
    fi

    
}

cleanupDeploy() {
    rm -rf ${deployDir}/*
    mkdir -p "${deployDir}"
}

buildManifest() {
    header "Assembling manifest..."
    manifest=""
    for dep in ${depDir}/*; do
        sha=`git -C "${dep}" rev-parse "HEAD"`
        branch=`git -C "${dep}" rev-parse --abbrev-ref "HEAD"`
        line="${dep}: Branch ${branch} @ ${sha}"
        manifest="${manifest}\n${line}"
    done
    echo -e "${manifest}"
    echo -e "${manifest}" > "${deployDir}/manifest.txt"
}

buildDeploy() {
    cleanupDeploy
    gatherDeps
    buildManifest
    buildBinary linux amd64 "${depDir}/pipelib/orca" orca
    buildBinary linux amd64 "${depDir}/pipelib/harden/cmd/warden" warden-linux

    header "Building orca..."
    mkdir -p "${deployDir}/orca"
    cp "${binDir}/linux/amd64/orca" "${deployDir}/orca/orca"
    cp ${includeDir}/orca/* "${deployDir}/orca"
    docker build -t orca "${deployDir}/orca" || exit 1

    header "Building baseline..."
    cp -r "${depDir}/baseline" "${deployDir}/baseline"
    cp ${includeDir}/baseline/* "${deployDir}/baseline"
    cp "${binDir}/linux/amd64/warden-linux" "${deployDir}/baseline/bin/warden-linux"
    docker build -t baseline "${deployDir}/baseline" || exit 1

    header "Building syntribos..."
    cp -r "${depDir}/syntribos" "${deployDir}/syntribos"
    cp -r ${includeDir}/syntribos/* "${deployDir}/syntribos"
    cp -r "${depDir}/rax-templates" "${deployDir}/syntribos/rax-templates"
    docker build -t syntribos "${deployDir}/syntribos" || exit 1

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
    if [[ $goVersion != "go1.11"* ]]; then
        echo "Go version >= 1.11 is required."
        exit 1
    fi

    if [[ -z "$(which git)" ]]; then
        echo "Missing 'git' binary."
        exit 1
    fi

    if [ "$#" = 0 ] || { [[ "$#" < 3 && "$1" = "-l" ]]; }; then
        echo "Missing command"
        printHelp
    fi
    parseArgs "$@"
}

main "$@"
exit 0

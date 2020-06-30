#!/bin/bash
#
set -o xtrace 
#
[[ -z ${1} ]] && echo "No REPO_NAME to create" && exit
[[ -z ${2} ]] && echo "Repo type is not specified" && exit
#
REPO_NAME=${1}
TYPE=${2}

if [[ -z "${RHVERS}" ]]; then
    RHVERS="6 7 8"
fi
if [[ -z "${RH_ARCHES}" ]]; then
    RH_ARCHES="noarch x86_64"
fi
if [[ -z "${APT_DISTS}" ]]; then
    APT_DISTS="stretch buster bionic focal "
fi
if [[ -z "${APT_ARCHES}" ]]; then
    APT_ARCHES="source i386 amd64"
fi
if [[ -z "${LIMIT}" ]]; then
    LIMIT=5
fi
#

create_yum_repo() {
    COMPONENTS="release testing experimental laboratory"
    for _component in ${COMPONENTS}; do
        for _version in ${RHVERS}; do
            mkdir -p ${REPO_NAME}/yum/${_component}/${_version}/SRPMS
            createrepo --update ${REPO_NAME}/yum/${_component}/${_version}/SRPMS
            for _arch in ${RH_ARCHES}; do
                mkdir -p ${REPO_NAME}/yum/${_component}/${_version}/RPMS/${_arch}
                createrepo --update ${REPO_NAME}/yum/${_component}/${_version}/RPMS/${_arch}
            done
            pushd ${REPO_NAME}/yum/${_component}
                ln -s ${_version} "${_version}SERVER"
                if [[ "x${_version}" == "x6" ]]; then
                    ln -s ${_version} "latest"
                elif [[ "x${_version}" == "x7" ]]; then
                    ln -s ${_version} "2"
                fi
            popd
        done
    done
}

create_apt_repo(){
    COMPONENTS="main testing experimental laboratory"
    mkdir -p ${REPO_NAME}/apt/conf
    DIST_FILE=${REPO_NAME}/apt/conf/distributions
    rm -f ${DIST_FILE}
    for _dist in ${APT_DISTS}; do
        cat << EOF >> ${DIST_FILE}
Origin: Percona Development Team
Label: percona
Codename: ${_dist} 
Version: 1.0
Limit: ${LIMIT}
Architectures: ${APT_ARCHES}
Components: ${COMPONENTS}
SignWith: 8507EFA5
Suite: stable
Description: Percona repository

EOF
    done
}

#main
if [[ -d $REPO_NAME ]]; then
    if [[ -d "$REPO_NAME/${TYPE}" ]]; then
        echo "Repo with such name already exists!"
        exit 1
    fi
fi
if [[ "x${TYPE}" == "xyum" ]]; then
    create_yum_repo
elif [[ "x${TYPE}" == "xapt" ]]; then
    create_apt_repo
else
    echo "Unknow repo type"
    exit 1
fi

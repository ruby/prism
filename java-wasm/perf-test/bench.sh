#! /bin/bash
set -euxo pipefail

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

jbang --fresh --deps org.openjdk.jmh:jmh-generator-annprocess:1.36 --javaagent=ap-loader@jvm-profiling-tools/ap-loader=start,event=cpu,file=${SCRIPT_DIR}/profile.html ${SCRIPT_DIR}/test
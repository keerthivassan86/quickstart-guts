#!/bin/bash

# Change to /opt


# ////////////

OPT_DIR="/opt"

QUICKSTART_DIR="${OPT_DIR}/quickstart-guts"

sudo mkdir -p ${QUICKSTART_DIR} && sudo chown -R ${USER}:${USER} ${QUICKSTART_DIR}

# clone quickstart-guts if not present
if [ ! -d ${QUICKSTART_DIR}/.git ]; then
    git clone https://github.com/rajalokan/quickstart-guts.git ${QUICKSTART_DIR}
fi

eval $(printf "%q\n" "${QUICKSTART_DIR}/run.sh" "$1")

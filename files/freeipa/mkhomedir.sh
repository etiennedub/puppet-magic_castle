#!/bin/bash

USERNAMES=${@}

if [ -z "${USERNAMES}" ]; then
    echo "$0 username1 [username2 ...]"
    exit
fi

ALL_GROUPS=$(groups ${USERNAMES[@]} | tr " " "\n" | grep -o "def-.*" | sort | uniq)
for GROUP in $ALL_GROUPS; do
    GID=$(getent group $GROUP | cut -d: -f3)
    mkdir -p "/project/$GID"
    chown root:"$GROUP" "/project/$GID"
    chmod 770 "/project/$GID"
    ln -sfT "/project/$GID" "/project/$GROUP"
done

for USERNAME in ${USERNAMES}; do
    USER_HOME="/mnt/home/$USERNAME"
    if [[ ! -d "$USER_HOME" ]] ; then
        cp -r /etc/skel $USER_HOME
        chmod 700 $USER_HOME
        chown -R $USERNAME:$USERNAME $USER_HOME
        # Project space
        for GROUP in $(groups $USERNAME | tr " " "\n" | grep -o "def-.*"); do
            PRO_USER="/project/$GROUP/$USERNAME"
            mkdir -p $PRO_USER
            mkdir -p "$USER_HOME/projects"
            ln -sfT "/project/$GROUP" "$USER_HOME/projects/$GROUP"
            chown -R $USERNAME:$USERNAME "$USER_HOME/projects" $PRO_USER
            chmod 750 "$USER_HOME/projects" $PRO_USER
        done
        # Scratch space
        SCR_USER="/scratch/$USERNAME"
        mkdir -p $SCR_USER
        ln -sfT $SCR_USER "$USER_HOME/scratch"
        chown -h $USERNAME:$USERNAME $SCR_USER "$USER_HOME/scratch"
        chmod 750 $SCR_USER
    fi
done
restorecon -F -R /mnt/home
# restorecon -F -R /project
# restorecon -F -R /scratch
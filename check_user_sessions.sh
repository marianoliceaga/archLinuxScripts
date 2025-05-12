#!/bin/bash

# Get current user and UID
current_user=$(whoami)
USER_ID=$(id -u)

# Get the current TTY (e.g., pts/0 or tty2)
CURRENT_TTY=$(tty | cut -d/ -f3-)

# Get the current DISPLAY (e.g., :0)
CURRENT_DISPLAY=${DISPLAY:-":0"}

# --- Check for multiple user sessions ---
session_count=$(who | grep -w "$current_user" | wc -l)

if [ "$session_count" -gt 1 ]; then
    echo "Warning: Multiple sessions detected for user $current_user. Potential remote connection."
else
    echo "You are the only user connected."
fi

# --- Kill other Xorg sessions ---
ps -u "$USER_ID" -o pid=,args= | grep Xorg | while read -r PID CMD; do
    DISPLAY_ARG=$(echo "$CMD" | grep -oE ':[0-9]+')
    if [ "$DISPLAY_ARG" != "$CURRENT_DISPLAY" ]; then
        echo "Killing X session on $DISPLAY_ARG (PID $PID)"
        kill -9 "$PID"
    fi
done

# --- Kill other loginctl sessions ---
CURRENT_SESSION_ID=$(loginctl | grep "$current_user" | grep "$CURRENT_TTY" | awk '{print $1}')

loginctl list-sessions --no-legend | while read -r SESSION_ID USER TTY REST; do
    if [ "$USER" = "$current_user" ] && [ "$SESSION_ID" != "$CURRENT_SESSION_ID" ]; then
        echo "Terminating loginctl session $SESSION_ID on TTY $TTY"
        loginctl terminate-session "$SESSION_ID"
    fi
done

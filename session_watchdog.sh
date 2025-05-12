#!/bin/bash

LOG_FILE="$HOME/kill_other_sessions.log"
UNLOCK_FLAG="$HOME/unlock.flag"
INTERVAL=3

echo "[$(date)] Session watchdog started." >> "$LOG_FILE"

current_user=$(whoami)
USER_ID=$(id -u)

# Detect current X session info once (assumed persistent)
CURRENT_TTY=$(tty | cut -d/ -f3-)
CURRENT_DISPLAY=${DISPLAY:-":0"}
CURRENT_SESSION_ID=$(loginctl | grep "$current_user" | grep "$CURRENT_TTY" | awk '{print $1}')
CURRENT_SESSION_PIDS=$(loginctl show-session "$CURRENT_SESSION_ID" -p Leader -p Processes --value | tr ' ' '\n')

# Main monitoring loop
while true; do
    # Refresh active session PIDs in case new terminals are opened
    CURRENT_SESSION_PIDS=$(loginctl show-session "$CURRENT_SESSION_ID" -p Processes --value | tr ' ' '\n')

    loginctl list-sessions --no-legend | while read -r SESSION_ID USER TTY REST; do
        if [ "$USER" = "$current_user" ] && [ "$SESSION_ID" != "$CURRENT_SESSION_ID" ]; then
            SESSION_PIDS=$(loginctl show-session "$SESSION_ID" -p Processes --value | tr ' ' '\n')
            SHARED=$(comm -12 <(echo "$CURRENT_SESSION_PIDS" | sort) <(echo "$SESSION_PIDS" | sort))

            if [ -z "$SHARED" ]; then
                echo "[$(date)] Terminating rogue session $SESSION_ID (TTY $TTY)" >> "$LOG_FILE"
                notify-send "⚠️ Seguridad" "Terminando sesión no autorizada en $TTY"
                loginctl terminate-session "$SESSION_ID"
            fi
        fi
    done

    # Block shell if not already and unlock.flag not present
    if [ ! -e "$UNLOCK_FLAG" ]; then
        SHELL=$(getent passwd "$current_user" | cut -d: -f7)
        if [ "$SHELL" != "/usr/sbin/nologin" ]; then
            echo "[$(date)] Activando bloqueo de futuros accesos..." >> "$LOG_FILE"
            sudo chsh -s /usr/sbin/nologin "$current_user"
            notify-send "🔒 Shell bloqueado" "Cambiado a nologin"
        fi
    else
        echo "[$(date)] unlock.flag presente, no se bloquea login shell." >> "$LOG_FILE"
    fi

    sleep "$INTERVAL"
done

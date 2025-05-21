#!/bin/bash

while true; do
    LOG_FILE="$HOME/kill_other_sessions.log"
    echo "[$(date)] --- Starting session cleanup ---" >> "$LOG_FILE"

    current_user=$(whoami)
    USER_ID=$(id -u)
    CURRENT_TTY=$(tty | cut -d/ -f3-)
    CURRENT_DISPLAY=${DISPLAY:-":0"}
    UNLOCK_FLAG="$HOME/unlock.flag"

    CURRENT_SESSION_ID=$(loginctl | grep "$current_user" | grep "$CURRENT_TTY" | awk '{print $1}')
    CURRENT_SESSION_PIDS=$(loginctl show-session "$CURRENT_SESSION_ID" -p Leader -p Processes --value | tr ' ' '\n')

    # --- Kill other Xorg sessions ---
    ps -u "$USER_ID" -o pid=,args= | grep Xorg | while read -r PID CMD; do
        DISPLAY_ARG=$(echo "$CMD" | grep -oE ':[0-9]+')
        if [ "$DISPLAY_ARG" != "$CURRENT_DISPLAY" ]; then
            MESSAGE="Killing Xorg session on $DISPLAY_ARG (PID $PID)"
            echo "[$(date)] $MESSAGE" >> "$LOG_FILE"
            notify-send "Sesión X finalizada" "$MESSAGE"
            kill -9 "$PID"
        fi
    done

    # --- Kill other loginctl sessions ---
    loginctl list-sessions --no-legend | while read -r SESSION_ID USER TTY REST; do
        if [ "$USER" = "$current_user" ] && [ "$SESSION_ID" != "$CURRENT_SESSION_ID" ]; then
            SESSION_PIDS=$(loginctl show-session "$SESSION_ID" -p Processes --value | tr ' ' '\n')
            SHARED=$(comm -12 <(echo "$CURRENT_SESSION_PIDS" | sort) <(echo "$SESSION_PIDS" | sort))

            if [ -z "$SHARED" ]; then
                MESSAGE="Terminating session $SESSION_ID (TTY $TTY)"
                echo "[$(date)] $MESSAGE" >> "$LOG_FILE"
                notify-send "Sesión TTY finalizada" "$MESSAGE"
                loginctl terminate-session "$SESSION_ID"
            else
                echo "[$(date)] Conservando sesión $SESSION_ID (TTY $TTY), pertenece al entorno gráfico actual." >> "$LOG_FILE"
            fi
        fi
    done

    # --- Block future logins ---
    if [ -e "$UNLOCK_FLAG" ]; then
        echo "[$(date)] unlock.flag detected, login shell not modified." >> "$LOG_FILE"
        notify-send "Modo seguro" "unlock.flag detectado. No se bloquean accesos."
    else
        if [ -w "/etc/passwd" ]; then
            sudo chsh -s /usr/sbin/nologin "$current_user"
            MESSAGE="Bloqueo de futuros accesos activado (shell = nologin)"
            echo "[$(date)] $MESSAGE" >> "$LOG_FILE"
            notify-send "Seguridad" "$MESSAGE"
        fi
    fi

    echo "[$(date)] --- Cleanup completed ---" >> "$LOG_FILE"

    sleep 30  # Wait 30 seconds before running again
done

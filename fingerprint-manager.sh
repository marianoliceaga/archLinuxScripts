#!/bin/bash

ACTION=$(kdialog --title "Fingerprint Manager" --menu "Choose an action:" \
1 "Enroll new fingerprint" \
2 "List enrolled fingerprints" \
3 "Delete fingerprint")

case $ACTION in
  1)
    fprintd-enroll
    ;;
  2)
    fprintd-list $USER | kdialog --textbox -
    ;;
  3)
    fprintd-delete
    ;;
  *)
    kdialog --msgbox "No action selected."
    ;;
esac

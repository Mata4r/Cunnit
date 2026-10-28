# Cunnit login banner: logo in light green, a thick bar, then the prompt.
case $- in *i*) ;; *) return 0 ;; esac
[ -t 1 ] || return 0
[ -z "$CUNNIT_BANNER_SHOWN" ] || return 0
export CUNNIT_BANNER_SHOWN=1

clear
printf '\n\033[1;92m'
cat <<'LOGO'
  /$$$$$$                                /$$   /$$    
 /$$__  $$                              |__/  | $$    
| $$  \__/ /$$   /$$ /$$$$$$$  /$$$$$$$  /$$ /$$$$$$  
| $$      | $$  | $$| $$__  $$| $$__  $$| $$|_  $$_/  
| $$      | $$  | $$| $$  \ $$| $$  \ $$| $$  | $$    
| $$    $$| $$  | $$| $$  | $$| $$  | $$| $$  | $$ /$$
|  $$$$$$/|  $$$$$$/| $$  | $$| $$  | $$| $$  |  $$$$/
 \______/  \______/ |__/  |__/|__/  |__/|__/   \___/  
LOGO
# Thick line: a full-height row of light-green background, works on any console.
printf '\033[0m\n\033[102m%s\033[0m\n\n' '                                                      '

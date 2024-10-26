#!/bin/bash
# SPDX-FileCopyrightText: 2024 Shigehiro Fukase <shigehiro.fukase@gmail.com>
# SPDX-License-Identifier: MIT

# gloval variables (parameter)
#   INTERVAL_SEC:   sleep every loop
#   HIDE_CURSOR:    0:show !0:hide cursor

# [ -z "${INTERVAL}" ] && INTERVAL=0.1
[ -z "${INTERVAL}" ] && INTERVAL=1
[ -z "${HIDE_CURSOR}" ] && HIDE_CURSOR=1
[ -z "${INTERVAL_SEC}" ] && INTERVAL_SEC=${INTERVAL}

_retval=
retval() {
    _retval=($*)
}
time_diff() {
    local stime=$1;
    local etime=$2;
    let local dtime=(${etime} - ${stime});
    #echo ${dtime}
    retval ${dtime}
}
# $1: previous (backup) value
# $2: current value
calc_per() {
    let local diff=($2-$1)
    local total=$3
    let local int=( $(( $(( ${diff}*10000 )) /${total} )) /100 )
    let local dec=( $(( $(( ${diff}*10000 )) /${total} )) %100 )
    local per=""
    if [ ${dec} -eq 0 ]; then
        per="${int}.00"
    elif [ ${dec} -lt 10 ]; then
        per="${int}.0${dec}"
    else
        per="${int}.${dec}"
    fi
    #echo ${per}
    retval ${per}
}

CSIICH="\e[${Ps}@"      # Insert Ps (Blank) Character(s) (default = 1)
CSIICH="\e[${Ps} @"     # Shift left Ps columns(s) (default = 1) (SL), ECMA-48.
CSICUU="\e[${Ps}A"      # Cursor Up Ps Times (default = 1)
CSICUU="\e[${Ps} A"     # Shift right Ps columns(s) (default = 1) (SR), ECMA-48.
CSICUD="\e[${Ps}B"      # Cursor Down Ps Times (default = 1)
CSICUF="\e[${Ps}C"      # Cursor Forward Ps Times (default = 1)
CSICUB="\e[${Ps}D"      # Cursor Backward Ps Times (default = 1)
CSICNL="\e[${Ps}E"      # Cursor Next Line Ps Times (default = 1)
CSICPL="\e[${Ps}F"      # Cursor Preceding Line Ps Times (default = 1)
CSICHA="\e[${Ps}G"      # Cursor Character Absolute  [column] (default = [row,1])
CSICUP="\e[${Ps1};${Ps2}H" # Cursor Position [row;column] (default = [1,1])
CSICUPBL="\e[999;1H"    # set cursor pos bottom left of screen
CSICHT="\e[${Ps}I"      # move cursor up N line head
CSIED="\e[${Ps}J"       # erase screen
CSIED1="\e[1J"          # clear screen top to cursor
CSIED2="\e[2J"          # clear screen
CSIEL0="\e[0K"          # clear cursor pos to end of line
DECTCEMS="\e[?25h"      # DECSET DECTCEM show cursor
DECTCEMR="\e[?25l"      # DECRST DECTCEM hide cursor
DECALTSCRNS="\e[?47h"   # DECSET XT_ALTSCRN swap to alt screen buffer
DECALTSCRNR="\e[?47l"   # DECRST XT_ALTSCRN swap to normal screen buffer
DECALTS47S="\e[?1047h"  # DECSET XT_ALTS_47 swap to alt screen buffer
DECALTS47R="\e[?1047l"  # DECRST XT_ALTS_47 clear screen, swap to normal screen buffer
DECEXTSCRNS="\e[?1049h" # DECSET XT_EXTSCRN save cursor pos, swap to alt screen buffer, clear screen
DECEXTSCRNR="\e[?1049l" # DECRST XT_EXTSCRN clear screen, swap to normal screen buffer, restore cursor pos
NL="${CSIEL0}\n"        # new line

cpu_stat() {
    local datetime=$( date --rfc-3339='ns' )
    local linenum
    eval $(
         awk '{if($1 ~ /^cpu/) print "linenum="NR" "$1"=( "$2" "$3" "$4" "$5" "$6" "$7" "$8" )"}' /proc/stat
    )
    let local num_cpu=(${linenum}-1)
    Ps=$((${linenum}+2)) # CSICPL param
    local LABEL_ALL="ALL(${num_cpu})"
    local SCRBUF=""
    SCRBUF="${SCRBUF}${DECTCEMR}" # hide cursor

    for ((i=0; i < ${linenum}; i++)); do
        let local n=(${i} - 1)
        local -a cur_cpu
        local -a bak_cpu

        if [ ${i} -eq 0 ]; then
            cur_cpu=( ${cpu[@]} )
        else
            cur_cpu=( $(eval echo "\${cpu${n}[@]}") )
        fi
        bak_cpu=( $(eval echo "\${BAK_CPU${i}[@]}") )
        [ ${#bak_cpu[@]} -eq 0 ] && bak_cpu=( ${cur_cpu[@]} )
        #echo "bak_cpu[$i](${#bak_cpu[@]})=( ${bak_cpu[@]} )"
        #echo "cur_cpu[$i](${#cur_cpu[@]})=( ${cur_cpu[@]} )"

        time_diff ${bak_cpu[0]} ${cur_cpu[0]}; local diff_user=${_retval};
        time_diff ${bak_cpu[1]} ${cur_cpu[1]}; local diff_nice=${_retval};
        time_diff ${bak_cpu[2]} ${cur_cpu[2]}; local diff_sys=${_retval};
        time_diff ${bak_cpu[3]} ${cur_cpu[3]}; local diff_idle=${_retval};
        time_diff ${bak_cpu[4]} ${cur_cpu[4]}; local diff_iowait=${_retval};
        time_diff ${bak_cpu[5]} ${cur_cpu[5]}; local diff_irq=${_retval};
        time_diff ${bak_cpu[6]} ${cur_cpu[6]}; local diff_softirq=${_retval};
        let local total=$(( ${diff_user} + ${diff_nice} + ${diff_sys} + ${diff_idle} + ${diff_iowait} + ${diff_irq} + ${diff_softirq} ))

        if [ ${total} -ne 0 ]; then
            calc_per ${bak_cpu[0]} ${cur_cpu[0]} ${total} ; local user=${_retval}
            calc_per ${bak_cpu[1]} ${cur_cpu[1]} ${total} ; local nice=${_retval}
            calc_per ${bak_cpu[2]} ${cur_cpu[2]} ${total} ; local sys=${_retval}
            calc_per ${bak_cpu[3]} ${cur_cpu[3]} ${total} ; local idle=${_retval}
            calc_per ${bak_cpu[4]} ${cur_cpu[4]} ${total} ; local iowait=${_retval}
            calc_per ${bak_cpu[5]} ${cur_cpu[5]} ${total} ; local irq=${_retval}
            calc_per ${bak_cpu[6]} ${cur_cpu[6]} ${total} ; local softirq=${_retval}

            if [ ${i} -eq 0 ]; then
                # move cursor up N line head, clear screen top to cursor, show datetime
                SCRBUF="${SCRBUF}${CSICPL}${CSIED1}${datetime}${NL}$(
                    printf "CPU[#] %7s %7s %7s %7s %7s %7s %7s" "user" "nice" "sys" "idle" "iowait" "irq" "softirq"
                )${NL}$(
                    printf "${LABEL_ALL} %6s%%%% %6s%%%% %6s%%%% %6s%%%% %6s%%%% %6s%%%% %6s%%%%" ${user} ${nice} ${sys} ${idle} ${iowait} ${irq} ${softirq}
                )${NL}"
            else
                SCRBUF=${SCRBUF}$(printf "CPU[$n] %6s%%%% %6s%%%% %6s%%%% %6s%%%% %6s%%%% %6s%%%% %6s%%%%" ${user} ${nice} ${sys} ${idle} ${iowait} ${irq} ${softirq})${NL}
            fi
        fi

        eval "BAK_CPU${i}=( ${cur_cpu[@]} )"
    done
    [ ${HIDE_CURSOR} -ne 0 ] && SCRBUF="${SCRBUF}${CSIEL0}" || SCRBUF="${SCRBUF}${CSIEL0}${DECTCEMS}" # show cursor
    printf "${SCRBUF}" # update screen
    SCRBUF=""
}

altscrn_enter() {
    printf "${DECEXTSCRNS}" # swap to alt screen buffer, clear screen
}
altscrn_exit() {
    printf "${DECTCEMS}${DECEXTSCRNR}" # show cursor, swap to normal screen buffer
}
exit_handler() {
    altscrn_exit
    exit;
}

trap 'exit_handler' EXIT
trap 'exit_handler' INT TERM

altscrn_enter   # Enter to ALT screen
printf "${CSICUPBL}" # set cursor pos bottom left of screen

[ ${HIDE_CURSOR} -ne 0 ] && printf "${DECTCEMR}" # hide cursor
for ((count=0; ; count++));  do
    cpu_stat $count
    sleep ${INTERVAL_SEC}
done

exit_handler

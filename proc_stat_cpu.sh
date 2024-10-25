#!/bin/bash
# SPDX-FileCopyrightText: 2024 Shigehiro Fukase <shigehiro.fukase@gmail.com>
# SPDX-License-Identifier: MIT

# gloval variables
#   INTERVAL_SEC:   sleep every loop
#
#   BAK_CPU:    Previous data

[ -z "${INTERVAL_SEC}" ] && INTERVAL_SEC=1

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

CSICUU="\e[%uA"         # [esc] move cursor up N line
CSICPL="\e[%uF"         # [esc] move cursor up N line head
DECTCEMS="\e[?25h"      # [esc] DECSET DECTCEM show cursor
DECTCEMR="\e[?25l"      # [esc] DECRST DECTCEM hide cursor
CSIED1="\e[1J"          # [esc] clear screen top to cursor
CSIED2="\e[2J"          # [esc] clear screen
CSIEL0="\e[0K"          # [esc] clear cursor pos to end of line
NL="${CSIEL0}\n"        # new line

cpu_stat() {
    local datetime=$( date --rfc-3339='ns' )
    local linenum
    eval $(
         awk '{if($1 ~ /^cpu/) print "linenum="NR" "$1"=( "$2" "$3" "$4" "$5" "$6" "$7" "$8" )"}' /proc/stat
    )
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
                SCRBUF="${SCRBUF}$(printf "${CSICPL}" $((${linenum}+2)))" # [esc] move cursor up N line head
                SCRBUF="${SCRBUF}${CSIED1}" # clear screen top to cursor
                SCRBUF="${SCRBUF}${datetime}${NL}" # show datetime
                SCRBUF=${SCRBUF}$(printf "CPU[#] %7s %7s %7s %7s %7s %7s %7s" "user" "nice" "sys" "idle" "iowait" "irq" "softirq")${NL}
                let local num_cpu=(${linenum}-1)
                SCRBUF=${SCRBUF}$(printf "ALL(${num_cpu}) %6s%%%% %6s%%%% %6s%%%% %6s%%%% %6s%%%% %6s%%%% %6s%%%%" ${user} ${nice} ${sys} ${idle} ${iowait} ${irq} ${softirq})${NL}
            else
                SCRBUF=${SCRBUF}$(printf "CPU[$n] %6s%%%% %6s%%%% %6s%%%% %6s%%%% %6s%%%% %6s%%%% %6s%%%%" ${user} ${nice} ${sys} ${idle} ${iowait} ${irq} ${softirq})${NL}
            fi
        fi

        eval "BAK_CPU${i}=( ${cur_cpu[@]} )"
    done
    SCRBUF="${SCRBUF}${CSIEL0}"
    SCRBUF="${SCRBUF}${DECTCEMS}" # show cursor
    printf "${SCRBUF}"
}

# "\e[?47h"     DECSET XT_ALTSCRN swap to alt screen buffer
# "\e[?1047h"   DECSET XT_ALTS_47 swap to alt screen buffer
# "\e[?1049h"   DECSET XT_EXTSCRN save cursor pos, swap to alt screen buffer, clear screen
# "\e[2J"       clear screen
altscrn_enter() {
    printf "\e[?1049h" # swap to alt screen buffer, clear screen
}
# "\e[?25h"     DECTCEM show cursor
# "\e[?47l"     DECRST XT_ALTSCRN swap to normal screen buffer
# "\e[?1047l"   DECRST XT_ALTS_47 clear screen, swap to normal screen buffer
# "\e[?1049l"   DECRST XT_EXTSCRN clear screen, swap to normal screen buffer, restore cursor pos
altscrn_exit() {
    printf "\e[?25h\e[?1049l" # show cursor, swap to normal screen buffer
}
exit_handler() {
    altscrn_exit
    exit;
}

trap 'exit_handler' EXIT
trap 'exit_handler' INT TERM

altscrn_enter   # Enter to ALT screen

for ((count=0; ; count++));  do
    printf "\e[?25l" # [esc] DECRST DECTCEM hide cursor
    cpu_stat $count
    printf "\e[?25h" # [esc] DECSET DECTCEM show cursor
    sleep ${INTERVAL_SEC}
done

exit_handler

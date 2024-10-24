#!/bin/bash

# gloval variables
#   INTERVAL_SEC:   sleep every loop
#
#   BAK_CPU:    Previous data

[ -z "${INTERVAL_SEC}" ] && INTERVAL_SEC=1

cpu_stat() {
    local datetime=$( date --rfc-3339='ns' )
    local linenum
    eval $(
         awk '{if($1 ~ /^cpu/) print "linenum="NR" "$1"=( "$2" "$3" "$4" "$5" "$6" "$7" "$8" )"}' /proc/stat
    )
    let local num_cpu=(${linenum}-1)
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

        let local diff_user=(${cur_cpu[0]} - ${bak_cpu[0]})
        let local diff_nice=(${cur_cpu[1]} - ${bak_cpu[1]})
        let local diff_sys=(${cur_cpu[2]} - ${bak_cpu[2]})
        let local diff_idle=(${cur_cpu[3]} - ${bak_cpu[3]})
        let local diff_iowait=(${cur_cpu[4]} - ${bak_cpu[4]})
        let local diff_irq=(${cur_cpu[5]} - ${bak_cpu[5]})
        let local diff_softirq=(${cur_cpu[6]} - ${bak_cpu[6]})
        let local total=( ${diff_user} + ${diff_nice} + ${diff_sys} + ${diff_idle} + ${diff_iowait} + ${diff_irq} + ${diff_softirq} )
        if [ ${total} -ne 0 ]; then
            local user=$( echo "scale=2; ((${diff_user}*10000)/${total})/100" | bc | awk '{printf "%.2f", $0}' )
            local nice=$( echo "scale=2; ((${diff_nice}*10000)/${total})/100" | bc | awk '{printf "%.2f", $0}' )
            local sys=$( echo "scale=2; ((${diff_sys}*10000)/${total})/100" | bc | awk '{printf "%.2f", $0}' )
            local idle=$( echo "scale=2; ((${diff_idle}*10000)/${total})/100" | bc | awk '{printf "%.2f", $0}' )
            local iowait=$( echo "scale=2; ((${diff_iowait}*10000)/${total})/100" | bc | awk '{printf "%.2f", $0}' )
            local irq=$( echo "scale=2; ((${diff_irq}*10000)/${total})/100" | bc | awk '{printf "%.2f", $0}' )
            local softirq=$( echo "scale=2; ((${diff_softirq}*10000)/${total})/100" | bc | awk '{printf "%.2f", $0}' )

            if [ ${i} -eq 0 ]; then
                printf "\e[%uA${datetime}\n" $((${linenum}+2)) # [esc] move cursor line up + show datetime
                printf "CPU[#] %7s %7s %7s %7s %7s %7s %7s\n" "user" "nice" "sys" "idle" "iowait" "irq" "softirq"
                printf "ALL(${num_cpu}) %6s%% %6s%% %6s%% %6s%% %6s%% %6s%% %6s%%\n" ${user} ${nice} ${sys} ${idle} ${iowait} ${irq} ${softirq}
            else
                printf "CPU[$n] %6s%% %6s%% %6s%% %6s%% %6s%% %6s%% %6s%%\n" ${user} ${nice} ${sys} ${idle} ${iowait} ${irq} ${softirq}
            fi
        fi

        eval "BAK_CPU${i}=( ${cur_cpu[@]} )"
    done
}
exit_handler() {
    printf "\e[?25h\e[?1049l"; # show cursor, swap to normal screen buffer
    exit;
}

trap 'exit_handler' EXIT
trap 'exit_handler' INT TERM

printf "\e[?1049h" # [esc] DECSET XT_EXTSCRN swap to alt screen buffer
echo -e "\e[2J" # [esc] clear screen

for ((count=0; ; count++));  do
    printf "\e[?25l" # [esc] DECRST DECTCEM hide cursor
    cpu_stat $count
    printf "\e[?25h" # [esc] DECSET DECTCEM show cursor
    sleep ${INTERVAL_SEC}
done

exit_handler

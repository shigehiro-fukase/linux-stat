# gloval variables
#   INTERVAL_SEC:   sleep every loop
#
#   NUM_CPU:    Number of cpu lines
#   MAX_CPU:    Max cpu core
#   BAK_CPU:    Previous data

[ -z "${INTERVAL_SEC}" ] && INTERVAL_SEC=1

NUM_CPU=$( grep ^cpu /proc/stat | wc -l )
MAX_CPU=$(expr ${NUM_CPU} - 1)

cpu_stat() {
    local datetime=$( date --rfc-3339='ns' )
    eval $( grep ^cpu /proc/stat | \
            awk '{print $1"=( "$2" "$3" "$4" "$5" "$6" "$7" "$8" )"}'
          )
    for ((i=0; i < ${NUM_CPU}; i++)); do
        local n=0
        local -a cur_cpu
        local -a bak_cpu

        if [ ${i} -eq 0 ]; then
            cur_cpu=( ${cpu[@]} )
        else
            n=$(expr ${i} - 1)
            cur_cpu=( $(eval echo "\${cpu${n}[@]}") )
        fi
        bak_cpu=( $(eval echo "\${BAK_CPU${i}[@]}") )
        [ ${#bak_cpu[@]} -eq 0 ] && bak_cpu=( ${cur_cpu[@]} )

        #echo "bak_cpu[$i](${#bak_cpu[@]})=( ${bak_cpu[@]} )"
        #echo "cur_cpu[$i](${#cur_cpu[@]})=( ${cur_cpu[@]} )"
        local diff_user=$( expr ${cur_cpu[0]} - ${bak_cpu[0]} )
        local diff_nice=$( expr ${cur_cpu[1]} - ${bak_cpu[1]} )
        local diff_sys=$( expr ${cur_cpu[2]} - ${bak_cpu[2]} )
        local diff_idle=$( expr ${cur_cpu[3]} - ${bak_cpu[3]} )
        local diff_iowait=$( expr ${cur_cpu[4]} - ${bak_cpu[4]} )
        local diff_irq=$( expr ${cur_cpu[5]} - ${bak_cpu[5]} )
        local diff_softirq=$( expr ${cur_cpu[6]} - ${bak_cpu[6]} )
        local total=$( expr ${diff_user} + ${diff_nice} + ${diff_sys} + ${diff_idle} + ${diff_iowait} + ${diff_irq} + ${diff_softirq} );
        if [ ${total} -ne 0 ]; then
            local user=$( echo "scale=2; (((${diff_user})*10000)/${total})/100" | bc | sed 's/^\./0./' )
            local nice=$( echo "scale=2; (((${diff_nice})*10000)/${total})/100" | bc | sed 's/^\./0./' )
            local sys=$( echo "scale=2; (((${diff_sys})*10000)/${total})/100" | bc | sed 's/^\./0./' )
            local idle=$( echo "scale=2; (((${diff_idle})*10000)/${total})/100" | bc | sed 's/^\./0./' )
            local iowait=$( echo "scale=2; (((${diff_iowait})*10000)/${total})/100" | bc | sed 's/^\./0./' )
            local irq=$( echo "scale=2; (((${diff_irq})*10000)/${total})/100" | bc | sed 's/^\./0./' )
            local softirq=$( echo "scale=2; (((${diff_softirq})*10000)/${total})/100" | bc | sed 's/^\./0./' )

            if [ ${i} -eq 0 ]; then
                printf "CPU[#] %6s %6s %6s %6s %6s %6s %6s\n" "user" "nice" "sys" "idle" "iowait" "irq" "softirq"
                printf "ALL(${MAX_CPU}) %5s%% %5s%% %5s%% %5s%% %5s%% %5s%% %5s%%\n" ${user} ${nice} ${sys} ${idle} ${iowait} ${irq} ${softirq}
            else
                printf "CPU[$n] %5s%% %5s%% %5s%% %5s%% %5s%% %5s%% %5s%%\n" ${user} ${nice} ${sys} ${idle} ${iowait} ${irq} ${softirq}
            fi

        fi

        eval "BAK_CPU${i}=( ${cur_cpu[@]} )"
    done
}


for ((count=0; ; count++));  do
    cpu_stat $count
    sleep ${INTERVAL_SEC}
    echo
done

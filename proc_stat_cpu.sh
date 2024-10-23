# gloval variables
#   NUM_CPU:    Number of cpu lines
#   MAX_CPU:    Max cpu core
#   BAK_CPU:    Previous data
#   INTERVAL_SEC:   sleep every loop

# grep ^cpu /proc/stat

NUM_CPU=$( grep ^cpu /proc/stat | wc -l )
MAX_CPU=$(expr ${NUM_CPU} - 1)
[ -z "${INTERVAL_SEC}" ] && INTERVAL_SEC=1

func_test0() {
    eval $(
    grep ^cpu /proc/stat | \
    awk '{print ""$1"=( user="$2" nice="$3" sys="$4" idle="$5" iowait="$6" irq="$7" softirq="$8" )"}'
    )
    # eval $(
    # grep ^cpu /proc/stat | \
    # awk '{print $1"=( "$2" "$3" "$4" "$5" "$6" "$7" "$8" )"}'
    # )
    echo "cpu=( ${cpu[@]} )"
    echo "cpu0=( ${cpu0[@]} )"
    echo "cpu1=( ${cpu1[@]} )"
    echo "cpu2=( ${cpu2[@]} )"
    echo "cpu3=( ${cpu3[@]} )"
    echo "cpu4=( ${cpu4[@]} )"
    echo "cpu5=( ${cpu5[@]} )"
    echo "cpu6=( ${cpu6[@]} )"
    echo "cpu7=( ${cpu7[@]} )"
}

# set -x

cpu_stat() {
    local datetime=$( date --rfc-3339='ns' )
    eval $(
            grep ^cpu /proc/stat | \
            # awk '{print ""$1"=( user="$2" nice="$3" sys="$4" idle="$5" iowait="$6" irq="$7" softirq="$8" )"}'
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

        local bak_user=${bak_cpu[0]}
        local bak_nice=${bak_cpu[1]}
        local bak_sys=${bak_cpu[2]}
        local bak_idle=${bak_cpu[3]}
        local bak_iowait=${bak_cpu[4]}
        local bak_irq=${bak_cpu[5]}
        local bak_softirq=${bak_cpu[6]}

        local cur_user=${cur_cpu[0]}
        local cur_nice=${cur_cpu[1]}
        local cur_sys=${cur_cpu[2]}
        local cur_idle=${cur_cpu[3]}
        local cur_iowait=${cur_cpu[4]}
        local cur_irq=${cur_cpu[5]}
        local cur_softirq=${cur_cpu[6]}

        local diff_user=$( expr ${cur_user} - ${bak_user} )
        local diff_nice=$( expr ${cur_nice} - ${bak_nice} )
        local diff_sys=$( expr ${cur_sys} - ${bak_sys} )
        local diff_idle=$( expr ${cur_idle} - ${bak_idle} )
        local diff_iowait=$( expr ${cur_iowait} - ${bak_iowait} )
        local diff_irq=$( expr ${cur_irq} - ${bak_irq} )
        local diff_softirq=$( expr ${cur_softirq} - ${bak_softirq} )
        local total=$( expr ${diff_user} + ${diff_nice} + ${diff_sys} + ${diff_idle} + ${diff_iowait} + ${diff_irq} + ${diff_softirq} );
        if [ ${total} -ne 0 ]; then
            local user=$( echo "scale=2; (((${diff_user})*10000)/${total})/100" | bc | sed 's/^\./0./' )
            local nice=$( echo "scale=2; (((${diff_nice})*10000)/${total})/100" | bc | sed 's/^\./0./' )
            local sys=$( echo "scale=2; (((${diff_sys})*10000)/${total})/100" | bc | sed 's/^\./0./' )
            local idle=$( echo "scale=2; (((${diff_idle})*10000)/${total})/100" | bc | sed 's/^\./0./' )
            local iowait=$( echo "scale=2; (((${diff_iowait})*10000)/${total})/100" | bc | sed 's/^\./0./' )
            local irq=$( echo "scale=2; (((${diff_irq})*10000)/${total})/100" | bc | sed 's/^\./0./' )
            local softirq=$( echo "scale=2; (((${diff_softirq})*10000)/${total})/100" | bc | sed 's/^\./0./' )
            #echo "${total} ${user} ${nice} ${sys} ${idle} ${iowait} ${irq} ${softirq}"

            #echo "bak user=${bak_user} nice=${bak_nice} sys=${bak_sys} idle=${bak_idle} iowait=${bak_iowait} irq=${bak_irq} softirq=${bak_softirq}"
            #echo "cur user=${cur_user} nice=${cur_nice} sys=${cur_sys} idle=${cur_idle} iowait=${cur_iowait} irq=${cur_irq} softirq=${cur_softirq}"
            #echo "total=${total} user=${diff_user} nice=${diff_nice} sys=${diff_sys} idle=${diff_idle} iowait=${diff_iowait} irq=${diff_irq} softirq=${diff_softirq}"
            if [ ${i} -eq 0 ]; then
                printf "CPU[#] %6s %6s %6s %6s %6s %6s %6s\n" "user" "nice" "sys" "idle" "iowait" "irq" "softirq"
                printf "ALL(${MAX_CPU}) %5s%% %5s%% %5s%% %5s%% %5s%% %5s%% %5s%%\n" ${user} ${nice} ${sys} ${idle} ${iowait} ${irq} ${softirq}
            else
                printf "CPU[$n] %5s%% %5s%% %5s%% %5s%% %5s%% %5s%% %5s%%\n" ${user} ${nice} ${sys} ${idle} ${iowait} ${irq} ${softirq}
            fi

#           local int_user=$( echo "(((${cur_user} - ${bak_user})*10000)/${total})/100" | bc )
#           local int_nice=$( echo "(((${cur_nice} - ${bak_nice})*10000)/${total})/100" | bc )
#           local int_sys=$( echo "(((${cur_sys} - ${bak_sys})*10000)/${total})/100" | bc )
#           local int_idle=$( echo "(((${cur_idle} - ${bak_idle})*10000)/${total})/100" | bc )
#           local int_iowait=$( echo "(((${cur_iowait} - ${bak_iowait})*10000)/${total})/100" | bc )
#           local int_irq=$( echo "(((${cur_irq} - ${bak_irq})*10000)/${total})/100" | bc )
#           local int_softirq=$( echo "(((${cur_softirq} - ${bak_softirq})*10000)/${total})/100" | bc )
#           local dec_user=$( echo "(((${cur_user} - ${bak_user})*10000)/${total})%100" | bc )
#           local dec_nice=$( echo "(((${cur_nice} - ${bak_nice})*10000)/${total})%100" | bc )
#           local dec_sys=$( echo "(((${cur_sys} - ${bak_sys})*10000)/${total})%100" | bc )
#           local dec_idle=$( echo "(((${cur_idle} - ${bak_idle})*10000)/${total})%100" | bc )
#           local dec_iowait=$( echo "(((${cur_iowait} - ${bak_iowait})*10000)/${total})%100" | bc )
#           local dec_irq=$( echo "(((${cur_irq} - ${bak_irq})*10000)/${total})%100" | bc )
#           local dec_softirq=$( echo "(((${cur_softirq} - ${bak_softirq})*10000)/${total})%100" | bc )
#           echo "[$i] ${total} ${int_user}.${dec_user} ${int_nice}.${dec_nice} ${int_sys}.${dec_sys} ${int_idle}.${dec_idle} ${int_iowait}.${dec_iowait} ${int_irq}.${dec_irq} ${int_softirq}.${dec_softirq}"
        fi

        eval "BAK_CPU${i}=( ${cur_cpu[@]} )"
        #bak_cpu=( $(eval echo "\${BAK_CPU${i}[@]}") ); echo "BAK_CPU[$i]=( ${BAK_CPU[@]} )"

        unset cur_cpu
        unset bak_cpu
    done
}

# func_test0
#echo MAX_CPU=${MAX_CPU}

for ((count=0; ; count++));  do
    cpu_stat $count
    sleep ${INTERVAL_SEC}
    echo
done

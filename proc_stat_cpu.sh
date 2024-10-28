#!/bin/bash
# SPDX-FileCopyrightText: 2024 Shigehiro Fukase <shigehiro.fukase@gmail.com>
# SPDX-License-Identifier: MIT

# gloval variables (parameter)
#   INTERVAL_SEC:   sleep every loop
#   HIDE_CURSOR:    0:show !0:hide cursor
#   VIEW_POS:       0:top-left 1:bottom-left
#   USE_BC:         use `bc` command, calculate by float
#   DATETIME:       0:hide datetime 1:show datetime
#   CPU_STAT:       0:hide stat 1:show stat
#   CPU_GRAPH:      0:hide graph 1:show graph

# [ -z "${INTERVAL}" ] && INTERVAL=0.1
[ -z "${INTERVAL}" ] && INTERVAL=1
[ -z "${HIDE_CURSOR}" ] && HIDE_CURSOR=1
[ -z "${VIEW_POS}" ] && VIEW_POS=1
[ -z "${INTERVAL_SEC}" ] && INTERVAL_SEC=${INTERVAL}
[ -z "${USE_BC}" ] && USE_BC=0
[ -z "${DATETIME}" ] && DATETIME=1
[ -z "${CPU_STAT}" ] && CPU_STAT=1
[ -z "${CPU_GRAPH}" ] && CPU_GRAPH=1

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
    local per=""
    if [ ${USE_BC} -eq 0 ]; then
        let local int=( $(( $(( ${diff}*10000 )) /${total} )) /100 )
        let local dec=( $(( $(( ${diff}*10000 )) /${total} )) %100 )
        if [ ${dec} -eq 0 ]; then
            per="${int}.00"
        elif [ ${dec} -lt 10 ]; then
            per="${int}.0${dec}"
        else
            per="${int}.${dec}"
        fi
    else
        per=$( echo "scale=2; ((${diff}*10000)/${total})/100" | bc | awk '{printf "%.2f", $0}' )
    fi
    #echo ${per}
    retval ${per}
}

#CSIICH="\e[${Ps}@"		# Insert Ps (Blank) Character(s) (default = 1)
#CSISL="\e[${Ps} @"		# Shift left Ps columns(s) (default = 1) (SL), ECMA-48.
#CSICUU="\e[${Ps}A"		# Cursor Up Ps Times (default = 1)
#CSISR="\e[${Ps} A"		# Shift right Ps columns(s) (default = 1) (SR), ECMA-48.
#CSICUD="\e[${Ps}B"		# Cursor Down Ps Times (default = 1)
#CSICUF="\e[${Ps}C"		# Cursor Forward Ps Times (default = 1)
#CSICUB="\e[${Ps}D"		# Cursor Backward Ps Times (default = 1)
#CSICNL="\e[${Ps}E"		# Cursor Next Line Ps Times (default = 1)
CSICPL="\e[${Ps}F"		# Cursor Preceding Line Ps Times (default = 1)
#CSICHA="\e[${Ps}G"		# Cursor Character Absolute	[column] (default = [row,1])
#CSICUP="\e[${Ps1};${Ps2}H"	# Cursor Position [row;column] (default = [1,1])
CSICUPTL="\e[1;1H"		# set cursor pos top left of screen
CSICUPBL="\e[999;1H"		# set cursor pos bottom left of screen
#CSICHT="\e[${Ps}I"		# Cursor Forward Tabulation Ps tab stops (default = 1)
#CSIED="\e[${Ps}J"		# Erase in Display (ED)
#CSIED0="\e[0J"			# Ps=0 -> Erase Below (default).
CSIED1="\e[1J"			# Ps=1 -> Erase Above.
CSIED2="\e[2J"			# Ps=2 -> Erase All.
#CSIED3="\e[3J"			# Ps=3 -> Erase Saved Lines
CSIEL="\e[${Ps}K"		# Erase in Line (DECSEL)
CSIEL0="\e[0K"			# Ps=0 -> Selective Erase to Right (default).
#CSIEL1="\e[1K"			# Ps=1 -> Selective Erase to Left.
#CSIEL2="\e[2K"			# Ps=2 -> Selective Erase All.
#CSIIL="\e[${Ps}L"		# Insert Ps Line(s) (default = 1)
#CSIDL="\e[${Ps}M"		# Delete Ps Line(s) (default = 1)
#CSIDCH="\e[${Ps}P"		# Delete Ps Character(s) (default = 1)

# CSI ? Pm h DEC Private Mode Set (DECSET)
# CSI ? Pm l DEC Private Mode Reset (DECRST)
# Ps = 1  ->  Application Cursor Keys (DECCKM)
# Ps = 2  ->  Designate USASCII for character sets G0-G3 (DECANM)
# Ps = 3  ->  132 Column Mode (DECCOLM)
# Ps = 4  ->  Smooth (Slow) Scroll (DECSCLM)
# Ps = 5  ->  Reverse Video (DECSCNM)
# Ps = 6  ->  Origin Mode (DECOM)
# Ps = 7  ->  Auto-Wrap Mode (DECAWM)
# Ps = 8  ->  Auto-Repeat Keys (DECARM)
# Ps = 9  ->  Send Mouse X & Y on button press
# Ps = 10  ->  Show toolbar (rxvt)
# Ps = 12  ->  Start blinking cursor (AT&T 610)
# Ps = 13  ->  Start blinking cursor (set only via resource or menu)
# Ps = 14  ->  Enable XOR of blinking cursor control sequence and menu
# Ps = 18  ->  Print Form Feed (DECPFF)
# Ps = 19  ->  Set print extent to full screen (DECPEX)
# Ps = 25  ->  Show cursor (DECTCEM)
DECTCEMS="\e[?25h"		# DECSET DECTCEM show cursor
DECTCEMR="\e[?25l"		# DECRST DECTCEM hide cursor
# Ps = 30  ->  Show scrollbar (rxvt)
# Ps = 35  ->  Enable font-shifting functions (rxvt)
# Ps = 38  ->  Enter Tektronix mode (DECTEK)
# Ps = 40  ->  Allow 80 ⇒  132 mode
# Ps = 41  ->  more(1) fix (see curses resource)
# Ps = 42  ->  Enable National Replacement Character sets (DECNRCM)
# Ps = 43  ->  Enable Graphic Expanded Print Mode (DECGEPM)
# Ps = 44  ->  Turn on margin bell
# Ps = 44  ->  Enable Graphic Print Color Mode (DECGPCM)
# Ps = 45  ->  Reverse-wraparound mode (XTREVWRAP)
# Ps = 45  ->  Enable Graphic Print Color Syntax (DECGPCS)
# Ps = 46  ->  Start logging (XTLOGGING)
# Ps = 46  ->  Graphic Print Background Mode
# Ps = 47  ->  Use Alternate Screen Buffer
DECALTSCRNS="\e[?47h"		# DECSET XT_ALTSCRN swap to alt screen buffer
DECALTSCRNR="\e[?47l"		# DECRST XT_ALTSCRN swap to normal screen buffer
# Ps = 47  ->  Enable Graphic Rotated Print Mode (DECGRPM)
# Ps = 66  ->  Application keypad mode (DECNKM)
# Ps = 67  ->  Backarrow key sends backspace (DECBKM)
# Ps = 69  ->  Enable left and right margin mode (DECLRMM)
# Ps = 80  ->  Enable Sixel Display Mode (DECSDM)
# Ps = 95  ->  Do not clear screen when DECCOLM is set/reset (DECNCSM)
# Ps = 1000  ->  Send Mouse X & Y on button press and release
# Ps = 1001  ->  Use Hilite Mouse Tracking
# Ps = 1002  ->  Use Cell Motion Mouse Tracking
# Ps = 1003  ->  Use All Motion Mouse Tracking
# Ps = 1004  ->  Send FocusIn/FocusOut events
# Ps = 1006  ->  Enable SGR Mouse Mode
# Ps = 1007  ->  Enable Alternate Scroll Mode
# Ps = 1010  ->  Scroll to bottom on tty output (rxvt)
# Ps = 1011  ->  Scroll to bottom on key press (rxvt)
# Ps = 1014  ->  Enable fastScroll resource
# Ps = 1015  ->  Enable urxvt Mouse Mode
# Ps = 1016  ->  Enable SGR Mouse PixelMode
# Ps = 1034  ->  Interpret "meta" key, xter
# Ps = 1035  ->  Enable special modifiers for Alt and NumLock keys
# Ps = 1036  ->  Send ESC   when Meta modifies a key
# Ps = 1037  ->  Send DEL from the editing-keypad Delete key
# Ps = 1039  ->  Send ESC  when Alt modifies a key
# Ps = 1040  ->  Keep selection even if not highlighted
# Ps = 1041  ->  Use the CLIPBOARD selection
# Ps = 1042  ->  Enable Urgency window manager hint when Control-G is received
# Ps = 1043  ->  Enable raising of the window when Control-G is received
# Ps = 1044  ->  Reuse the most recent data copied to CLIPBOARD
# Ps = 1045  ->  Extended Reverse-wraparound mode (XTREVWRAP2)
# Ps = 1046  ->  Enable switching to/from Alternate Screen Buffer
# Ps = 1047  ->  Use Alternate Screen Buffer
DECALTS47S="\e[?1047h"		# DECSET XT_ALTS_47 swap to alt screen buffer
DECALTS47R="\e[?1047l"		# DECRST XT_ALTS_47 clear screen, swap to normal screen buffer
# Ps = 1048  ->  Save cursor as in DECSC
# Ps = 1049  ->  Save cursor as in DECSC
DECEXTSCRNS="\e[?1049h"		# DECSET XT_EXTSCRN save cursor pos, swap to alt screen buffer, clear screen
DECEXTSCRNR="\e[?1049l"		# DECRST XT_EXTSCRN clear screen, swap to normal screen buffer, restore cursor pos
# Ps = 1050  ->  Set terminfo/termcap function-key mode
# Ps = 1051  ->  Set Sun function-key mode
# Ps = 1052  ->  Set HP function-key mode
# Ps = 1053  ->  Set SCO function-key mode
# Ps = 1060  ->  Set legacy keyboard emulation
# Ps = 1061  ->  Set VT220 keyboard emulation
# Ps = 2001  ->  Enable readline mouse button-1
# Ps = 2002  ->  Enable readline mouse button-2
# Ps = 2003  ->  Enable readline mouse button-3
# Ps = 2004  ->  Set bracketed paste mode
# Ps = 2005  ->  Enable readline character-quoting
# Ps = 2006  ->  Enable readline newline pasting
NL="${CSIEL0}\n"		# new line

GRAPH_SCALE=(
"100│"
" 90│"
" 80│"
" 70│"
" 60│"
" 50│"
" 40│"
" 30│"
" 20│"
" 10│"
"  0│"
)

SCRBUF=""
linenum=0
cpu_stat() {
    local datetime=$( date --rfc-3339='ns' )
    eval $(
         awk '{if($1 ~ /^cpu/) print "linenum="NR" "$1"=( "$2" "$3" "$4" "$5" "$6" "$7" "$8" )"}' /proc/stat
    )
    let local num_cpu=(${linenum}-1)

    # CSICPL param
    Ps=0
    [ ${DATETIME} -ne 0 ] && Ps=$((${Ps}+1))
    [ ${CPU_STAT} -ne 0 ] && Ps=$((${Ps}+${linenum}+1))
    [ ${CPU_GRAPH} -ne 0 ] && Ps=$((${Ps}+${#GRAPH_SCALE[@]}+1))
    local LABEL_ALL="ALL(${num_cpu})"

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
            local used=$((100-${idle%%\.*}))
            eval "USED${i}=${used}"

            if [ ${i} -eq 0 ]; then
                if [ ${DATETIME} -ne 0 ]; then
                    SCRBUF="${SCRBUF}${datetime}${NL}" # show datetime
                fi
            fi
            if [ ${CPU_STAT} -ne 0 ]; then
                if [ ${i} -eq 0 ]; then
                    SCRBUF="${SCRBUF}$(
                        printf "CPU[#] %7s %7s %7s %7s %7s %7s %7s" "user" "nice" "sys" "idle" "iowait" "irq" "softirq"
                    )${NL}$(
                        printf "${LABEL_ALL} %6s%%%% %6s%%%% %6s%%%% %6s%%%% %6s%%%% %6s%%%% %6s%%%%" ${user} ${nice} ${sys} ${idle} ${iowait} ${irq} ${softirq}
                    )${NL}"
                else
                    SCRBUF=${SCRBUF}$(
                        printf "CPU[$n] %6s%%%% %6s%%%% %6s%%%% %6s%%%% %6s%%%% %6s%%%% %6s%%%%" ${user} ${nice} ${sys} ${idle} ${iowait} ${irq} ${softirq}
                    )${NL}
                fi
            fi
        fi

        eval "BAK_CPU${i}=( ${cur_cpu[@]} )"
    done
    retval ${total}
}
cpu_graph() {
    local total=$1
    [ ${CPU_GRAPH} -eq 0 ] && return 0;
    [ ${total} -eq 0 ] && return 0;
    local graph=()
    for ((i=0; i < ${#GRAPH_SCALE[@]}; i++)); do
        graph[$i]="${GRAPH_SCALE[$i]}"
        #printf "${graph[$i]}\n"
    done
    for ((i=0; i < ${linenum}; i++)); do
        local used=( $(eval echo "\${USED${i}}") )
        [ ${used} -gt 99 ] && used=99 # limit 99
        local quotient=$((${used}/10))
        local remainder=$((${used}%10))
        local rc=""
        if   [ ${remainder} -gt 8 ]; then rc="██│"
        elif [ ${remainder} -gt 7 ]; then rc="▇▇│"
        elif [ ${remainder} -gt 6 ]; then rc="▆▆│"
        elif [ ${remainder} -gt 5 ]; then rc="▅▅│"
        elif [ ${remainder} -gt 4 ]; then rc="▄▄│"
        elif [ ${remainder} -gt 3 ]; then rc="▃▃│"
        elif [ ${remainder} -gt 2 ]; then rc="▂▂│"
        elif [ ${remainder} -gt 0 ]; then rc="▁▁│"
        else rc="  │"
        fi
        [ ${i} -eq 0 ] && graph[10]="${graph[10]}AL│" || graph[10]="${graph[10]}C$((${i}-1))│"
        #printf "USED[$i]=${used}(${quotient},${remainder} rc=$rc)\n"
        for ((q=0; q < ${quotient}; q++)); do
            graph[$((9-${q}))]="${graph[$((9-${q}))]}██│"
        done
        if [ $q -lt 9 ]; then
            graph[$((9-${q}))]="${graph[$((9-${q}))]}${rc}"
            q=$(($q+1))
        fi
        for ((; q < 9; q++)); do
            graph[$((9-${q}))]="${graph[$((9-${q}))]}  │"
        done
        if [ ${used} -lt 10 ]; then
            graph[0]="${graph[0]} ${used}│"
        else
            graph[0]="${graph[0]}${used}│"
        fi
    done
    SCRBUF="${SCRBUF}\n"
    for ((i=0; i < ${#GRAPH_SCALE[@]}; i++)); do
        SCRBUF="${SCRBUF}${graph[$i]}\n"
    done
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
[ ${VIEW_POS} -eq 0 ] && printf "${CSICUPTL}" || printf "${CSICUPBL}" # set cursor pos

[ ${HIDE_CURSOR} -ne 0 ] && printf "${DECTCEMR}" # hide cursor
for ((count=0; ; count++));  do
    SCRBUF=""
    SCRBUF="${SCRBUF}${DECTCEMR}" # hide cursor
    if [ ${VIEW_POS} -eq 0 ]; then
        # move cursor top-left of screen, clear screen
        SCRBUF="${SCRBUF}${CSICUPTL}${CSIED2}"
    else
        # move cursor up N line head, clear screen top to cursor
        SCRBUF="${SCRBUF}${CSICPL}${CSIED1}"
    fi
    cpu_stat $count
    cpu_graph ${_retval} $count
    printf "${SCRBUF}" # update screen
    [ ${HIDE_CURSOR} -ne 0 ] && SCRBUF="${SCRBUF}${CSIEL0}" || SCRBUF="${SCRBUF}${CSIEL0}${DECTCEMS}" # show cursor
    sleep ${INTERVAL_SEC}
done

exit_handler

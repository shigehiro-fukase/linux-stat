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
#   GRAPH_NUMPOS:   0:top 1:above the bar
#   GRAPH_COLOR:    0:no color 1:use color

# [ -z "${INTERVAL}" ] && INTERVAL=0.1
[ -z "${INTERVAL}" ] && INTERVAL=1
[ -z "${HIDE_CURSOR}" ] && HIDE_CURSOR=1
[ -z "${VIEW_POS}" ] && VIEW_POS=1
[ -z "${INTERVAL_SEC}" ] && INTERVAL_SEC=${INTERVAL}
[ -z "${USE_BC}" ] && USE_BC=0
[ -z "${DATETIME}" ] && DATETIME=1
[ -z "${CPU_STAT}" ] && CPU_STAT=1
[ -z "${CPU_GRAPH}" ] && CPU_GRAPH=1
[ -z "${GRAPH_NUMPOS}" ] && GRAPH_NUMPOS=1
[ -z "${GRAPH_COLOR}" ] && GRAPH_COLOR=1

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

SGI_Default="\e[0m"		# Default
SGI_BoldBright="\e[1m"		# Bold/Bright
SGI_NoBoldBright="\e[22m"	# No bold/bright
SGI_Underline="\e[4m"		# Underline
SGI_NoUnderline="\e[24m"	# No underline
SGI_Negative="\e[7m"		# Negative
SGI_Positive="\e[27m"		# Positive (No negative)
SGI_FgBlack="\e[30m"		# Foreground Black
SGI_FgRed="\e[31m"		# Foreground Red
SGI_FgGreen="\e[32m"		# Foreground Green
SGI_FgYellow="\e[33m"		# Foreground Yellow
SGI_FgBlue="\e[34m"		# Foreground Blue
SGI_FgMagenta="\e[35m"		# Foreground Magenta
SGI_FgCyan="\e[36m"		# Foreground Cyan
SGI_FgWhite="\e[37m"		# Foreground White
SGI_FgExtended="\e[38m"		# Foreground Extended
SGI_FgExRGB="\e[38;2;${r};${g};${b}m" # Set foreground color to RGB value specified
SGI_FgExColor="\e[38;5;$Ps" 	# Set foreground color to <s> index in 88 or 256 color table
SGI_FgDefault="\e[39m"		# Foreground Default
SGI_BgBlack="\e[40m"		# Background Black
SGI_BgRed="\e[41m"		# Background Red
SGI_BgGreen="\e[42m"		# Background Green
SGI_BgYellow="\e[43m"		# Background Yellow
SGI_BgBlue="\e[44m"		# Background Blue
SGI_BgMagenta="\e[45m"		# Background Magenta
SGI_BgCyan="\e[46m"		# Background Cyan
SGI_BgWhite="\e[47m"		# Background White
SGI_BgExtended="\e[48m"		# Background Extended
SGI_BgExRGB="\e[48;2;${r};${g};${b}m" # Set background color to RGB value specified
SGI_BgExColor="\e[48;5;$Ps" 	# Set background color to <Ps> index in 88 or 256 color table
SGI_BgDefault="\e[49m"		# Background Default
SGI_BrightFgBlack="\e[90m"	# Bright Foreground Black
SGI_BrightFgRed="\e[91m"	# Bright Foreground Red
SGI_BrightFgGreen="\e[92m"	# Bright Foreground Green
SGI_BrightFgYellow="\e[93m"	# Bright Foreground Yellow
SGI_BrightFgBlue="\e[94m"	# Bright Foreground Blue
SGI_BrightFgMagenta="\e[95m"	# Bright Foreground Magenta
SGI_BrightFgCyan="\e[96m"	# Bright Foreground Cyan
SGI_BrightFgWhite="\e[97m"	# Bright Foreground White
SGI_BrightBgBlack="\e[100m"	# Bright Background Black
SGI_BrightBgRed="\e[101m"	# Bright Background Red
SGI_BrightBgGreen="\e[102m"	# Bright Background Green
SGI_BrightBgYellow="\e[103m"	# Bright Background Yellow
SGI_BrightBgBlue="\e[104m"	# Bright Background Blue
SGI_BrightBgMagenta="\e[105m"	# Bright Background Magenta
SGI_BrightBgCyan="\e[106m"	# Bright Background Cyan
SGI_BrightBgWhite="\e[107m"	# Bright Background White

Fg0=""
FgR=""
FgM=""
FgY=""
FgG=""
FgB=""
if [ ${GRAPH_COLOR} -ne 0 ]; then
    Fg0="${SGI_NoBoldBright}${SGI_FgDefault}"
    FgR="${SGI_BoldBright}${SGI_FgRed}"
    FgM="${SGI_BoldBright}${SGI_FgMagenta}"
    FgY="${SGI_BoldBright}${SGI_FgYellow}"
    FgG="${SGI_BoldBright}${SGI_FgGreen}"
    FgB="${SGI_BoldBright}${SGI_FgBlue}"
fi

GRAPH_SCALE=(
"100˾│"
" 90˾│"
" 80˾│"
" 70˾│"
" 60˾│"
" 50˾│"
" 40˾│"
" 30˾│"
" 20˾│"
" 10˾│"
"  0˾│"
"    │"
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
color_per() {
    local per=$1
    local color=""
    if [ ${GRAPH_COLOR} -ne 0 ]; then
          if [ ${per} -lt 20 ]; then color="${FgB}"
        elif [ ${per} -lt 40 ]; then color="${FgG}"
        elif [ ${per} -lt 60 ]; then color="${FgY}"
        elif [ ${per} -lt 80 ]; then color="${FgM}"
        else                         color="${FgR}"
        fi
    fi
    retval ${color}
}
cpu_graph() {
    local total=$1
    [ ${CPU_GRAPH} -eq 0 ] && return 0;
    [ ${total} -eq 0 ] && return 0;
    local color_fw=""
    local color_rwd=""
    local graph=()
    for ((i=0; i < ${#GRAPH_SCALE[@]}; i++)); do
        graph[$i]="${GRAPH_SCALE[$i]}"
        #printf "${graph[$i]}\n"
    done
    for ((i=0; i < ${linenum}; i++)); do
        local used=( $(eval echo "\${USED${i}}") )
        local used99=${used}
        [ ${used99} -gt 99 ] && used99=99 || used99=${used} # limit 99
        local quotient=$((${used99}/10))
        local remainder=$((${used99}%10))
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
        [ ${i} -eq 0 ] && graph[11]="${graph[11]}"$(printf "%2u" $((${linenum}-1)))"│" || graph[11]="${graph[11]}C"$(printf "%x" $((${i}-1)))"│"
        #printf "USED[$i]=${used99}(${quotient},${remainder} rc=$rc)\n"

        # Quotient part of the bar
        local pos
        for ((q=0; q < ${quotient}; q++)); do
            graph[$((10-${q}))]="${graph[$((10-${q}))]}██│"
        done
        # Remainder part of the bar
        [ ${used99} -eq 0 ] && rc="0%%│"
        if [ $q -lt 10 ]; then
            graph[$((10-${q}))]="${graph[$((10-${q}))]}${rc}"
            q=$(($q+1))
        fi
        if [ ${GRAPH_NUMPOS} -eq 0 ]; then
            for ((; q < 10; q++)); do
                graph[$((10-${q}))]="${graph[$((10-${q}))]}  │"
            done
            if [ ${used} -gt 99 ]; then
                graph[0]="${graph[0]}▁▁ "
            else
                color_per ${used99}; color_fw=${_retval}
                color_per $((${q}*10)); color_rwd=${_retval}
                if [ ${used99} -lt 10 ]; then
                    graph[0]="${graph[0]} ${color_fw}${used99}${color_rwd} "
                else
                    graph[0]="${graph[0]}${color_fw}${used99}${color_rwd} "
                fi
            fi
        else
            if [ ${used} -gt 99 ]; then
                graph[0]="${graph[0]}▁▁ "
            else
                pos=$((${#GRAPH_SCALE[@]}-2-${q}))
                local vl
                local hl
                if [ ${pos} -gt 0 ]; then
                    vl="│"
                    hl="⸏⸏ "
                else
                    vl=" "
                    hl=""
                fi
                color_per ${used99}; color_fw=${_retval}
                color_per $((${q}*10)); color_rwd=${_retval}
                if [ ${used99} -eq 0 ]; then
                    graph[${pos}]="${graph[${pos}]} ${color_fw} ${color_rwd}${vl}"
                elif [ ${used99} -lt 10 ]; then
                    graph[${pos}]="${graph[${pos}]}${color_fw}${used99}%%${color_rwd}${vl}"
                else
                    graph[${pos}]="${graph[${pos}]}${color_fw}${used99}${color_rwd}${vl}"
                fi
                q=$(($q+1))
                for ((; q < 10; q++)); do
                    pos=$((${#GRAPH_SCALE[@]}-2-${q}))
                    graph[${pos}]="${graph[${pos}]}  │"
                done
                graph[0]="${graph[0]}${hl}"
            fi
        fi
    done
    SCRBUF="${SCRBUF}\n"
    if [ ${GRAPH_COLOR} -eq 0 ]; then
        for ((i=0; i < ${#GRAPH_SCALE[@]}; i++)); do
            SCRBUF="${SCRBUF}${graph[$i]}\n"
        done
    else
        for ((i=0; i < ${#GRAPH_SCALE[@]}; i++)); do
            if [ $i -eq $((${#GRAPH_SCALE[@]}-1)) ]; then
                color_fw=${Fg0}
            else
                pos=$((${#GRAPH_SCALE[@]}-${i}-2))
                color_per $((${pos}*10)); color_fw=${_retval}
            fi
            SCRBUF="${SCRBUF}${color_fw}${graph[$i]}\n"
        done
    fi
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
    key=""
    read -n 1 -t 0.001 key >/dev/null 2>&1
    case "${key}" in
        q) echo "bye!"; exit 0; break;;
        *) ;;
    esac
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

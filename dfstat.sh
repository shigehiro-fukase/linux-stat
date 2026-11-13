#!/bin/bash

SHOW_SEP=0
SHOW_HEADER=0
USE_COLOR=0
EXCLUDE_TMPFS=0
INTERVAL=1
BLOCK_SIZE=""

# ヘルプ表示関数
usage() {
    cat <<EOF
Usage: $0 [OPTIONS]
  -s, --separator         1回のチェックで変化があった場合に末尾に区切り線を表示する
  -H, --header            1回のチェックで変化があった場合に先頭にヘッダーを表示する
  -c, --color             増減の数値を色付きで強調表示する（増加=赤/緑, 減少=緑/赤, 端末出力時のみ有効）
  -x, --exclude-tmpfs     tmpfs を監視対象から除外する（df -x tmpfs）
  -i, --interval SEC      監視間隔を秒単位で指定する（デフォルト: 1）
  -B, --block-size SIZE   表示ブロックサイズを指定する（例: 1K, 1M, 1G）
  -h, --help              このヘルプを表示する
EOF
    exit 0
}

# オプション解析
while [[ $# -gt 0 ]]; do
    case "$1" in
        -s|--separator)
            SHOW_SEP=1
            shift
            ;;
        -H|--header)
            SHOW_HEADER=1
            shift
            ;;
        -c|--color)
            USE_COLOR=1
            shift
            ;;
        -x|--exclude-tmpfs)
            EXCLUDE_TMPFS=1
            shift
            ;;
        -i|--interval)
            if [[ -z "$2" || ! "$2" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
                echo "エラー: -i には正の数値を指定してください。" >&2
                exit 1
            fi
            INTERVAL="$2"
            shift 2
            ;;
        -B|--block-size)
            if [[ -z "$2" || "$2" == -* ]]; then
                echo "エラー: -B にはブロックサイズ（例: 1M, 1G）を指定してください。" >&2
                exit 1
            fi
            BLOCK_SIZE="$2"
            shift 2
            ;;
        -B*)
            # "-B1M" のようにスペースなしで連結して指定された場合への対応
            BLOCK_SIZE="${1#-B}"
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "不明なオプション: $1" >&2
            echo "ヘルプを表示するには $0 -h を実行してください。" >&2
            exit 1
            ;;
    esac
done

# 標準出力が端末（TTY）でない場合はカラー出力を自動で無効化
if [[ "$USE_COLOR" -eq 1 && ! -t 1 ]]; then
    USE_COLOR=0
fi

# dfコマンドのオプション組み立て
DF_OPTS=(-P)
if [[ "$EXCLUDE_TMPFS" -eq 1 ]]; then
    DF_OPTS+=(-x tmpfs)
fi
if [[ -n "$BLOCK_SIZE" ]]; then
    DF_OPTS+=(-B "$BLOCK_SIZE")
fi

# ヘッダー用のブロック表記を設定（未指定時は 1024-blocks）
BLOCK_LABEL="${BLOCK_SIZE:-1024}-blocks"

while true; do
    df "${DF_OPTS[@]}"
    echo "---TICK---"
    sleep "$INTERVAL"
done | awk \
    -v show_sep="$SHOW_SEP" \
    -v show_header="$SHOW_HEADER" \
    -v use_color="$USE_COLOR" \
    -v block_label="$BLOCK_LABEL" '
BEGIN {
    first_run = 1
    changed_in_tick = 0

    # ANSIカラーコード定義
    if (use_color) {
        c_red   = "\033[31m"
        c_green = "\033[32m"
        c_bold  = "\033[1m"
        c_reset = "\033[0m"
    } else {
        c_red = c_green = c_bold = c_reset = ""
    }
}

# 1サイクルごとの区切り処理
$0 == "---TICK---" {
    if (show_sep && changed_in_tick) {
        print "--------------------------------------------------------------------------------------------------------"
    }
    changed_in_tick = 0

    for (k in prev_used) {
        if (!(k in seen)) {
            delete prev_used[k]
            delete prev_avail[k]
        }
    }
    delete seen
    first_run = 0
    fflush()
    next
}

/^Filesystem/ {
    next
}

NF >= 6 {
    # df -B 指定時に数値末尾に "M" 等の単位が付くため、+0 で純粋な数値として抽出
    key = $1 SUBSEP $2
    seen[key] = 1

    # 数値部分と単位部分（M, Gなど）を分離
    used = $3 + 0
    avail = $4 + 0
    unit_used = $3; sub(/^[0-9.]+/, "", unit_used)
    unit_avail = $4; sub(/^[0-9.]+/, "", unit_avail)

    # 第6カラム以降（マウントポイント）をスペースを含めてすべて結合
    mount_point = $6
    for (i = 7; i <= NF; i++) {
        mount_point = mount_point " " $i
    }

    if (!first_run && (key in prev_used)) {
        diff_used = used - prev_used[key]
        diff_avail = avail - prev_avail[key]

        if (diff_used != 0 || diff_avail != 0) {
            # この回の最初の変化行であればヘッダーを出力
            if (show_header && !changed_in_tick) {
                printf "%s%-10s %-20s %12s %22s %22s %6s %s%s\n",
                    c_bold, "[Time]", "Filesystem", block_label, "Used", "Available", "Cap%", "Mounted on", c_reset
            }

            # Used のフォーマット（増加=赤、減少=緑）
            if (diff_used > 0) {
                str_used = sprintf("%s (%s%+d%s%s)", $3, c_red, diff_used, unit_used, c_reset)
            } else if (diff_used < 0) {
                str_used = sprintf("%s (%s%+d%s%s)", $3, c_green, diff_used, unit_used, c_reset)
            } else {
                str_used = $3
            }

            # Available のフォーマット（増加=緑、減少=赤）
            if (diff_avail > 0) {
                str_avail = sprintf("%s (%s%+d%s%s)", $4, c_green, diff_avail, unit_avail, c_reset)
            } else if (diff_avail < 0) {
                str_avail = sprintf("%s (%s%+d%s%s)", $4, c_red, diff_avail, unit_avail, c_reset)
            } else {
                str_avail = $4
            }

            # カラーコードの制御文字分だけ幅指定(%22s)がずれるのを補正
            pad_used  = (diff_used != 0 && use_color)  ? 22 + length(c_red) + length(c_reset) : 22
            pad_avail = (diff_avail != 0 && use_color) ? 22 + length(c_red) + length(c_reset) : 22

            printf "[%s] %-20s %12s %*s %*s %6s %s\n",
                strftime("%H:%M:%S"), $1, $2, pad_used, str_used, pad_avail, str_avail, $5, mount_point

            changed_in_tick = 1
        }
    }

    prev_used[key] = used
    prev_avail[key] = avail
}
'


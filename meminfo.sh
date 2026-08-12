#!/bin/sh
cat /proc/meminfo |grep -E "MemTotal|MemFree|Buffers|^Cached"

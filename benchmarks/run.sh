#!/usr/bin/env bash
#
# Copyright (c) the go-ruby-complex/complex authors
# SPDX-License-Identifier: BSD-3-Clause
#
# Library-level cross-runtime benchmark runner.
#
# Runs the SAME workload through (a) the pure-Go go-ruby-complex/complex library
# (benchmarks/go) and (b) each available reference Ruby runtime
# (benchmarks/ruby/complex.rb), then prints one Markdown table per sub-benchmark:
# ns/op and the ratio vs MRI. Before any table is printed, every runtime's CHECK
# block (canonical Complex#to_s / fixed-precision float renders) is verified
# byte-identical to MRI's — a mismatch aborts, so no timing is ever trusted for a
# runtime that does not compute the same answer.
#
# Usage:  bash benchmarks/run.sh
# Env:    OUTER (timed passes, default 25), WARM (untimed passes, default 3),
#         RUBY / JRUBY / TRUFFLERUBY (override runtime binaries).
set -u
cd "$(dirname "$0")"

RUBY=${RUBY:-ruby}
JRUBY=${JRUBY:-jruby}
TRUFFLERUBY=${TRUFFLERUBY:-truffleruby}

RB=ruby/complex.rb
MOD=complex
TMP=$(mktemp)             # RESULT rows: <runtime>\t<label>\t<ns>
CHK=$(mktemp)             # CHECK rows:  <runtime>\t<label>\t<repr>
OUT=$(mktemp)
trap 'rm -f "$TMP" "$CHK" "$OUT"' EXIT

# capture <runtime-label> <cmd...> : run once, split RESULT and CHECK streams.
capture() {
  local label=$1; shift
  command -v "$1" >/dev/null 2>&1 || { echo "  ($label: $1 not found — skipped)" >&2; return; }
  echo "  $label ..." >&2
  "$@" 2>/dev/null >"$OUT"
  awk -v r="$label" '$1=="RESULT"{printf "%s\t%s\t%s\n", r, $2, $3}' "$OUT" >> "$TMP"
  awk -v r="$label" '$1=="CHECK" {printf "%s\t%s\t%s\n", r, $2, $3}' "$OUT" >> "$CHK"
}

echo "== go-ruby-$MOD library-level benchmark ==" >&2
echo "  go ..." >&2
( cd go && command -v go >/dev/null 2>&1 && go run . 2>/dev/null ) >"$OUT"
awk '$1=="RESULT"{printf "go\t%s\t%s\n", $2, $3}' "$OUT" >> "$TMP"
awk '$1=="CHECK" {printf "go\t%s\t%s\n", $2, $3}' "$OUT" >> "$CHK"

capture "mri"         "$RUBY"                "$RB"
capture "mri-yjit"    "$RUBY" --yjit         "$RB"
capture "jruby"       "$JRUBY"               "$RB"
capture "truffleruby" "$TRUFFLERUBY"         "$RB"

# --- correctness gate: every runtime's CHECK block must equal MRI's ---
echo >&2
mri_chk=$(awk -F'\t' '$1=="mri"{print $2"\t"$3}' "$CHK" | sort)
if [ -z "$mri_chk" ]; then
  echo "FATAL: MRI produced no CHECK output — cannot verify correctness." >&2
  exit 1
fi
fail=0
for rt in go mri-yjit jruby truffleruby; do
  rt_chk=$(awk -F'\t' -v r="$rt" '$1==r{print $2"\t"$3}' "$CHK" | sort)
  [ -z "$rt_chk" ] && continue    # runtime absent/skipped
  if [ "$rt_chk" != "$mri_chk" ]; then
    echo "FATAL: $rt disagrees with MRI on the canonical results:" >&2
    diff <(printf '%s\n' "$mri_chk") <(printf '%s\n' "$rt_chk") >&2
    fail=1
  else
    echo "  ok: $rt matches MRI" >&2
  fi
done
[ "$fail" -eq 0 ] || { echo "Aborting: correctness gate failed." >&2; exit 1; }
echo "  correctness gate passed — all runtimes agree with MRI." >&2
echo >&2

# Emit one Markdown table per sub-benchmark (label), runtimes as rows.
awk -F'\t' '
  { key=$2; rt=$1; ns=$3; labels[key]=1; val[rt SUBSEP key]=ns; rts[rt]=1 }
  END {
    order="go mri mri-yjit jruby truffleruby"
    n=split(order, ord, " ")
    ln=0; for (k in labels) lab[++ln]=k
    for (i=1;i<=ln;i++) for (j=i+1;j<=ln;j++) if (lab[j]<lab[i]){t=lab[i];lab[i]=lab[j];lab[j]=t}
    for (i=1;i<=ln;i++){
      k=lab[i]
      printf "\n#### %s\n\n", k
      print  "| Runtime | ns/op | vs MRI |"
      print  "| --- | ---: | ---: |"
      base=val["mri" SUBSEP k]
      for (o=1;o<=n;o++){
        rt=ord[o]; v=val[rt SUBSEP k]
        if (v=="") continue
        ratio=(base!=""&&base+0>0)? sprintf("%.2f×", v/base) : "—"
        name=rt
        if (rt=="go") name="**go-ruby (pure Go)**"
        else if (rt=="mri") name="MRI"
        else if (rt=="mri-yjit") name="MRI + YJIT"
        else if (rt=="jruby") name="JRuby"
        else if (rt=="truffleruby") name="TruffleRuby"
        printf "| %s | %s | %s |\n", name, v, ratio
      }
    }
  }
' "$TMP"

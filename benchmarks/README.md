<!-- SPDX-License-Identifier: BSD-3-Clause -->
# `go-ruby-complex` library-level benchmark harness

Reproducible, cross-runtime benchmark of the **pure-Go `go-ruby-complex/complex`
library** against the reference Ruby runtimes (MRI, MRI + YJIT, JRuby,
TruffleRuby). It measures the **library primitive** through its Go API, isolated
from the rbgo interpreter, so the numbers answer: *is the pure-Go implementation
as fast as the reference runtime's own `Complex`?*

## Layout

- `go/`            — self-contained Go driver; `go.mod` pins the published library
  by pseudo-version (no `replace`).
- `ruby/complex.rb`  — the equivalent workload; `ruby/_harness.rb` is the shared timer.
- `run.sh`         — runs every available runtime, verifies each agrees with MRI,
  and prints one Markdown table per sub-benchmark (ns/op + ratio vs MRI).

## Run

```sh
bash benchmarks/run.sh
```

Environment knobs: `OUTER` (timed passes, default 25), `WARM` (untimed warm-up
passes, default 3), and `RUBY`/`JRUBY`/`TRUFFLERUBY` to select runtime binaries.

## Ops

A representative mix of Ruby-visible `Complex` operations: `add`, `mul`, `abs`
(magnitude), `conjugate`, `rect-to-polar` (`Complex#polar`), `polar-to-rect`
(`Complex.polar`), and canonical `to_s`. Ruby's `Complex` is a core type (C
implementation); the pure-Go column is `go-ruby-complex/complex`, every other
column is that interpreter's own `Complex`.

## Method

Each process runs `WARM` untimed passes (to let the JVM/GraalVM JITs warm up),
then `OUTER` timed passes of a fixed inner loop, timed with a monotonic clock;
the **best** pass is reported as **ns/op**. Interpreter start-up is outside the
timed region. The Go driver and the Ruby script build **identical inputs** and
each print a `CHECK` line per op — the canonical `Complex#to_s` for value results
and a fixed-precision (`%.10f`) render for the float results (`abs`, the polar
pair). `run.sh` verifies every runtime's `CHECK` block **byte-identical to MRI**
and aborts on any mismatch, so a runtime is never timed unless it computes the
same answer. Results are published, dated, in `../docs/performance.md`.

# Performance

`go-ruby-complex/complex` is the pure-Go library that
[`rbgo`](https://github.com/go-embedded-ruby/ruby) binds for Ruby's `complex`. This
page records the **methodology** of the ecosystem-wide per-module parity suite —
how this module is benchmarked against the reference Ruby runtimes — without
quoting numbers here, so the figures never drift out of date.

## What is measured

The **same** Ruby script — an arithmetic + render workload over `Complex` values (constructors, exact `Mul` / `Pow`, `abs` / `arg`, and `inspect` / `to_s`) — is run under every runtime.
`rbgo`'s number reflects **this pure-Go library doing the work**; every other
column is that interpreter's own `complex` (or equivalent) implementation. So the
comparison is the **Ruby-visible operation**, apples-to-apples across
interpreters. The script prints a deterministic checksum and its output is
checked **byte-identical to MRI** before timing.

## Method

- **Best-of-N wall time** (best, not mean, to suppress scheduler noise);
  single-shot processes, no warm-up beyond the script's own loop.
- **Runtimes:** MRI (the oracle) and MRI + YJIT; JRuby (OpenJDK); TruffleRuby
  (GraalVM CE Native). JRuby and TruffleRuby are timed **cold, single-shot**, so
  they carry JVM / Graal startup on every run — read them as one-shot
  `ruby file.rb` costs, the same way `rbgo` and MRI are measured, not as
  steady-state JIT numbers.
- The benchmark script and harness live in rbgo's repo under
  [`bench/modules/`](https://github.com/go-embedded-ruby/ruby/tree/main/bench/modules)
  (`complex.rb` + `run.sh`). Reproduce:
  `RBGO=./rbgo TRUFFLE=truffleruby bash bench/modules/run.sh 5`.

!!! note "Honest framing"
    No headline numbers are reproduced on this page on purpose: the parity suite
    is the source of truth and is re-run per release. Rows that complete in well
    under a couple hundred milliseconds carry the most relative noise; treat
    their ratios as order-of-magnitude. The published figures are real measured
    numbers — nothing is cherry-picked.

## Library-level benchmark (Go API vs runtimes) — 2026-07-03

This section measures the **pure-Go library directly, through its Go API** — not
the `rbgo` interpreter path described above. It isolates the library primitive
from Ruby-interpreter dispatch, answering the parity question head-on: *is the
pure-Go implementation as fast as the reference runtime's own `Complex`?* The
**same workload, same inputs, same iteration counts** run through the Go library
(`go-ruby-complex/complex`, pinned by pseudo-version — no `replace`) and through
each reference runtime's core `Complex`; every runtime's output was verified
**byte-identical to MRI** before any timing (canonical `Complex#to_s` for value
results, a fixed-precision `%.10f` render for the float results).

- **Host:** Apple M4 Max (`Mac16,5`, arm64), macOS 26.5.1 — **date 2026-07-03**.
- **Runtimes:** Go 1.26.4 · MRI `ruby 4.0.5 +PRISM` · MRI + YJIT · JRuby 10.1.0.0
  (OpenJDK 25) · TruffleRuby 34.0.1 (GraalVM CE Native).
- **Method:** each process runs 3 untimed warm-up passes, then 25 timed passes of
  a fixed 5000-op inner loop, timed with a monotonic clock; the **best** pass is
  reported as **ns/op** (lower is better). `vs MRI` < 1.00× means *faster than
  MRI*. Interpreter start-up is outside the timed region, so these are operation
  costs, not `ruby file.rb` process costs.

### Results (best of 25, ns/op)

#### abs

| Runtime | ns/op | vs MRI |
| --- | ---: | ---: |
| **go-ruby (pure Go)** | 55.4 | 1.20× |
| MRI | 46.0 | 1.00× |
| MRI + YJIT | 20.0 | 0.43× |
| JRuby | 35.2 | 0.77× |
| TruffleRuby | 49.7 | 1.08× |

#### add

| Runtime | ns/op | vs MRI |
| --- | ---: | ---: |
| **go-ruby (pure Go)** | 370.8 | 6.46× |
| MRI | 57.4 | 1.00× |
| MRI + YJIT | 35.8 | 0.62× |
| JRuby | 16.7 | 0.29× |
| TruffleRuby | 55.6 | 0.97× |

#### conjugate

| Runtime | ns/op | vs MRI |
| --- | ---: | ---: |
| **go-ruby (pure Go)** | 29.6 | 0.69× |
| MRI | 43.2 | 1.00× |
| MRI + YJIT | 16.8 | 0.39× |
| JRuby | 18.3 | 0.42× |
| TruffleRuby | 36.5 | 0.84× |

#### mul

| Runtime | ns/op | vs MRI |
| --- | ---: | ---: |
| **go-ruby (pure Go)** | 980.5 | 9.84× |
| MRI | 99.6 | 1.00× |
| MRI + YJIT | 70.6 | 0.71× |
| JRuby | 20.6 | 0.21× |
| TruffleRuby | 36.4 | 0.37× |

#### polar-to-rect

| Runtime | ns/op | vs MRI |
| --- | ---: | ---: |
| **go-ruby (pure Go)** | 18.9 | 0.28× |
| MRI | 68.6 | 1.00× |
| MRI + YJIT | 45.8 | 0.67× |
| JRuby | 20.1 | 0.29× |
| TruffleRuby | 78.4 | 1.14× |

#### rect-to-polar

| Runtime | ns/op | vs MRI |
| --- | ---: | ---: |
| **go-ruby (pure Go)** | 111.3 | 1.41× |
| MRI | 79.0 | 1.00× |
| MRI + YJIT | 48.2 | 0.61× |
| JRuby | 57.1 | 0.72× |
| TruffleRuby | 51.1 | 0.65× |

#### to_s

| Runtime | ns/op | vs MRI |
| --- | ---: | ---: |
| **go-ruby (pure Go)** | 113.2 | 0.52× |
| MRI | 218.2 | 1.00× |
| MRI + YJIT | 198.8 | 0.91× |
| JRuby | 35.8 | 0.16× |
| TruffleRuby | 241.1 | 1.10× |

### Reading the results

Parity is **mixed, and honestly so**. The pure-Go library is **faster than MRI**
on `to_s` (0.52×), `conjugate` (0.69×) and dramatically on `polar-to-rect`
(0.28×, ~3.6× faster — MRI's `Complex.polar` builds through its numeric-coercion
machinery whereas the Go path is two `math.Cos`/`Sin` calls), and at **near
parity** on `abs` (1.20×) and `rect-to-polar` (1.41×, dominated by the shared
`hypot`/`atan2`).

The two clear gaps are **integer `add` (6.46×) and `mul` (9.84×)**. These are
**real and expected**: `go-ruby-complex/complex` models Ruby's exact numeric
tower with a `Num` backed by `math/big` (`big.Int`/`big.Rat`), so even for
machine-word integer parts each `+`/`*` allocates and runs arbitrary-precision
arithmetic, while MRI operates on tagged fixnums and JRuby/TruffleRuby JIT the
small-integer path to a handful of nanoseconds. This buys the library **exactness
that never overflows** (the reason `Complex(a,b)*Complex(c,d)` stays exact for
arbitrarily large integer/rational parts, matching MRI's Bignum/Rational
promotion) at a per-op allocation cost on the small-integer common case. A
`kindInt` machine-word fast path (`int64` add/mul with overflow check before
falling back to `big.Int`) is the obvious next optimization and would close most
of this gap without giving up exactness; it is left as a follow-up in the library
repo, not this docs PR.

!!! note "Reproduce"
    The harness is committed under
    [`benchmarks/`](https://github.com/go-ruby-complex/docs/tree/main/benchmarks):
    a self-contained Go driver (`go/`, pins the published library via `go.mod`),
    the equivalent `ruby/complex.rb` workload, and `run.sh`. Run
    `bash benchmarks/run.sh`; env `OUTER`/`WARM` tune the pass budget and
    `RUBY`/`JRUBY`/`TRUFFLERUBY` select the runtime binaries. `run.sh` re-verifies
    every runtime against MRI before timing and aborts on any disagreement.

!!! warning "Warm-up budget & noise — honest framing"
    Numbers reflect a **fixed warm-process budget** (3 warm-up + 25 timed passes
    in one process). The JVM/GraalVM JITs (JRuby, TruffleRuby) may need a larger
    warm-up to reach steady state, so their columns can shift between runs — most
    visibly TruffleRuby on the shortest loops. Every operation here settles in
    tens to hundreds of nanoseconds, so **all rows carry meaningful relative
    noise**; treat sub-100 ns ratios as order-of-magnitude and the direction of
    each gap (not its third digit) as the signal. Every number is a **real
    measured value** from the dated run above — nothing is fabricated, estimated,
    or cherry-picked. The go-ruby column is the pure-Go library; every other
    column is that interpreter's own core `Complex` doing the equivalent work.

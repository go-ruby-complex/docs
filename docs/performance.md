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
| **go-ruby (pure Go)** | 10.3 | 0.25× |
| MRI | 40.8 | 1.00× |
| MRI + YJIT | 19.6 | 0.48× |
| JRuby | 33.0 | 0.81× |
| TruffleRuby | 30.0 | 0.74× |

#### add

| Runtime | ns/op | vs MRI |
| --- | ---: | ---: |
| **go-ruby (pure Go)** | 26.4 | 0.47× |
| MRI | 56.0 | 1.00× |
| MRI + YJIT | 36.4 | 0.65× |
| JRuby | 42.6 | 0.76× |
| TruffleRuby | 64.6 | 1.15× |

#### conjugate

| Runtime | ns/op | vs MRI |
| --- | ---: | ---: |
| **go-ruby (pure Go)** | 16.8 | 0.39× |
| MRI | 43.6 | 1.00× |
| MRI + YJIT | 16.2 | 0.37× |
| JRuby | 23.1 | 0.53× |
| TruffleRuby | 76.9 | 1.76× |

#### mul

| Runtime | ns/op | vs MRI |
| --- | ---: | ---: |
| **go-ruby (pure Go)** | 57.6 | 0.65× |
| MRI | 88.8 | 1.00× |
| MRI + YJIT | 63.4 | 0.71× |
| JRuby | 21.4 | 0.24× |
| TruffleRuby | 36.9 | 0.42× |

#### polar-to-rect

| Runtime | ns/op | vs MRI |
| --- | ---: | ---: |
| **go-ruby (pure Go)** | 22.0 | 0.33× |
| MRI | 66.2 | 1.00× |
| MRI + YJIT | 46.6 | 0.70× |
| JRuby | 20.4 | 0.31× |
| TruffleRuby | 98.7 | 1.49× |

#### rect-to-polar

| Runtime | ns/op | vs MRI |
| --- | ---: | ---: |
| **go-ruby (pure Go)** | 27.0 | 0.37× |
| MRI | 73.8 | 1.00× |
| MRI + YJIT | 47.6 | 0.64× |
| JRuby | 56.6 | 0.77× |
| TruffleRuby | 51.6 | 0.70× |

#### to_s

| Runtime | ns/op | vs MRI |
| --- | ---: | ---: |
| **go-ruby (pure Go)** | 116.8 | 0.54× |
| MRI | 216.8 | 1.00× |
| MRI + YJIT | 201.4 | 0.93× |
| JRuby | 37.3 | 0.17× |
| TruffleRuby | 253.8 | 1.17× |

### Reading the results

The pure-Go library is now **at or below MRI on every operation** — a clean
parity result. It is faster than MRI on `to_s` (0.54×), `conjugate` (0.39×),
`abs` (0.25×, ~4× faster), `polar-to-rect` (0.33×) and `rect-to-polar` (0.37×),
and — the headline of this run — **faster than MRI on integer `add` (0.47×) and
`mul` (0.65×)** as well.

Those last two used to be the library's only real gaps. In the previous run
integer `add` was **6.46×** and `mul` **9.84×** slower than MRI, because
`go-ruby-complex/complex` models Ruby's exact numeric tower with a `Num` backed by
`math/big` (`big.Int`/`big.Rat`), so even for machine-word integer parts every
`+`/`*` allocated and ran arbitrary-precision arithmetic while MRI operated on
tagged fixnums. That gap is now closed by an **`int64` fast path**: an Integer
component whose value fits a machine word is stored inline (allocation-free), and
`add`/`sub`/`mul` on two such components run as plain `int64` arithmetic with
overflow detection via `math/bits` (`Add64`/`Sub64`/`Mul64`). This is exactly
MRI's Fixnum fast path.

Crucially, **exactness is preserved, not traded away**: on the rare overflow the
operation *promotes* to `big.Int` and produces the same arbitrarily-large exact
result as before (verified byte-identical to MRI's Bignum arithmetic at the
`int64` boundary, e.g. `Complex(9223372036854775807,0)+Complex(1,0)` and
`Complex(3037000500,1)²`), never a wrapped value. Rational and Float parts keep
the original exact tower path untouched. The same inline representation also feeds
`Float64`, which is why `abs`/`rect-to-polar` — which convert integer parts to
float — sped up several-fold in the same change. The result: the small-integer
common case runs ~14× (add) and ~17× (mul) faster than the old `math/big`-only
path, with **identical MRI-exact semantics** across the whole numeric tower.

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

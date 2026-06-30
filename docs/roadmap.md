# Roadmap

`go-ruby-complex/complex` is grown **test-first**, each capability differential-tested against
MRI rather than built in isolation. Ruby's Complex — the deterministic,
interpreter-independent slice extracted from rbgo's internals — is **complete**.

| Stage | What | Status |
| --- | --- | --- |
| Numeric tower | A `Num` union of Integer (`*big.Int`), Rational (`*big.Rat`) and Float (`float64`), so each part of the `Complex` is preserved exactly as MRI keeps it on the numeric tower. | **Done** |
| Exact-preserving arithmetic | `Add` / `Sub` / `Mul` / `Div` / `Pow` / `Neg` keep Integer and Rational parts exact; integer powers stay exact, non-integer / Float exponents use the floating polar form. | **Done** |
| Magnitude & phase | `Abs`, the exact `Abs2`, `Arg` / `Angle` / `Phase`, `Conjugate`, `Rectangular`, `PolarParts` — `Hypot` and `Atan2` matching MRI. | **Done** |
| Constructors & parsing | `New` / `Rect`, `Polar`, and `Parse` for the full `Complex(string)` grammar including polar `@`, the `j` unit and `_` digit separators. | **Done** |
| Conversions & rendering | `ToF` / `ToI` / `ToR` / `ToC`, `Numerator` / `Denominator`, and MRI-exact `Inspect` / `ToS`. | **Done** |
| Differential oracle & coverage | A wide corpus dumped through this library and the system `ruby` / `Complex`, compared byte-for-byte; 100% coverage, gofmt + go vet clean, green across all six 64-bit Go arches and three OSes. | **Done** |

## Documented out-of-scope boundaries

These are **deliberate**, recorded so the module's surface is unambiguous:

- **No interpreter.** The library implements the deterministic numeric algorithm; it never runs arbitrary Ruby. Anything that needs a live binding or coercion against other Ruby numerics is the consumer's job — that is why `rbgo` binds this module rather than the reverse.
- **Reference is reference Ruby (MRI).** Byte-for-byte conformance targets MRI's `Complex`. The handful of intrinsically-floating results (`Polar`, polar `Parse`, non-integer `Pow`) can differ by a ULP because Go's pure-Go `math` is not the platform `libm` MRI links; those cases are verified under a tolerance.
- **Standalone & reusable.** The module has no dependency on the Ruby runtime; the dependency runs the other way.

See [Usage & API](api.md) for the surface and [Why pure Go](why.md) for the
deterministic/interpreter split.

# go-ruby-complex documentation

**Ruby's Complex number in pure Go — exact on the numeric tower, MRI byte-exact, no cgo.**

`go-ruby-complex/complex` is a faithful, pure-Go (zero cgo) reimplementation of Ruby's
[`Complex`](https://docs.ruby-lang.org/en/master/Complex.html), matching reference Ruby (MRI) byte-for-byte. The module
path is `github.com/go-ruby-complex/complex`.

It was **extracted from rbgo's internals into a reusable standalone library**:
the module is standalone and importable by any Go program, and it is the backend
bound into [go-embedded-ruby](https://github.com/go-embedded-ruby/ruby) by `rbgo`
as a native module — a sibling of [go-ruby-rational](https://github.com/go-ruby-rational/rational) and [go-ruby-regexp](https://github.com/go-ruby-regexp/regexp). The dependency runs the other
way: this library has **no dependency on the Ruby runtime**.

!!! success "Status: complete — MRI byte-exact"
    A wide corpus of constructors, arithmetic, conversions and string parses built here and compared byte-for-byte against the system `ruby`'s `inspect` / `to_s`; 100% coverage, gofmt + go vet clean, green across all six 64-bit Go arches and three OSes.

## Quick taste

```go
a := complex.New(complex.IntFromInt64(1), complex.IntFromInt64(2))
b := complex.New(complex.IntFromInt64(3), complex.IntFromInt64(4))

fmt.Println(a.Inspect())        // (1+2i)
fmt.Println(a.Mul(a).Inspect()) // (-3+4i)  — exact
fmt.Println(b.Abs())            // 5

// Exact Rational parts.
r := complex.New(complex.RatFromInt64(1, 2), complex.RatFromInt64(3, 4))
fmt.Println(r.Inspect())        // ((1/2)+(3/4)*i)

// Parse MRI's Complex(string) forms.
c, _ := complex.Parse("1+2i")
fmt.Println(c.Inspect())        // (1+2i)
```

## Repositories

| Repo | What it is |
| --- | --- |
| [`complex`](https://github.com/go-ruby-complex/complex) | the library — Ruby's Complex in pure Go |
| [`docs`](https://github.com/go-ruby-complex/docs) | this documentation site (MkDocs Material, versioned with mike) |
| [`go-ruby-complex.github.io`](https://github.com/go-ruby-complex/go-ruby-complex.github.io) | the organization landing page (Hugo) |
| [`brand`](https://github.com/go-ruby-complex/brand) | logo and brand assets |

## Principles

- **Pure Go, `CGO_ENABLED=0`** — trivial cross-compilation, a single static
  binary, no C toolchain.
- **MRI byte-exact.** Output matches reference Ruby exactly, not approximately,
  validated by a differential oracle against the `ruby` binary.
- **Standalone & reusable.** Extracted from rbgo's internals; no dependency on
  the Ruby runtime — the dependency runs the other way.
- **100% test coverage** is the target, enforced as a CI gate.

## Where to go next

- [Why pure Go](why.md) — why this slice of Ruby is deterministic enough to live
  as a standalone, interpreter-independent Go library.
- [Usage & API](api.md) — the public surface and worked examples.
- [Roadmap](roadmap.md) — what is done and what is downstream by design.

Source lives at [github.com/go-ruby-complex/complex](https://github.com/go-ruby-complex/complex).

# Usage & API

The public API lives at the module root (`github.com/go-ruby-complex/complex`). It is **Ruby-shaped but Go-idiomatic**: the methods mirror Ruby's `Complex` (`inspect`, `to_s`, `abs`, `arg`, `conjugate`, …) while the surface follows Go conventions — value types, explicit `error`, no global state.

!!! success "Status: implemented"
    The library is built and importable as `github.com/go-ruby-complex/complex`, bound into
    `rbgo` as a native module; see [Roadmap](roadmap.md).

## Install

```sh
go get github.com/go-ruby-complex/complex
```

## Worked example

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

## Shape

```go
// Construction
func New(re, im Num) *Complex            // Complex.rect
func Rect(re, im Num) *Complex           // alias
func Polar(abs, arg Num) *Complex        // Complex.polar (Float parts)
func Parse(s string) (*Complex, error)   // Complex(string)

// Arithmetic (exact-preserving)
func (c *Complex) Add(o *Complex) *Complex
func (c *Complex) Sub(o *Complex) *Complex
func (c *Complex) Mul(o *Complex) *Complex
func (c *Complex) Div(o *Complex) *Complex
func (c *Complex) Pow(exp Num) *Complex
func (c *Complex) Neg() *Complex
func (c *Complex) Conjugate() *Complex   // conjugate / conj

// Magnitude & phase
func (c *Complex) Abs() float64          // abs / magnitude
func (c *Complex) Abs2() Num             // abs2 (exact)
func (c *Complex) Arg() float64          // arg / angle / phase
func (c *Complex) Rectangular() (Num, Num)
func (c *Complex) PolarParts() (float64, float64)

// Parts, equality, predicates
func (c *Complex) Real() Num
func (c *Complex) Imaginary() Num
func (c *Complex) Eql(o *Complex) bool   // eql?
func (c *Complex) Equal(o *Complex) bool // ==
func (c *Complex) FiniteQ() bool         // finite?
func (c *Complex) InfiniteQ() (int, bool)// infinite?

// Conversions & rendering
func (c *Complex) ToF() (float64, error) // to_f (RangeError if imag != 0)
func (c *Complex) ToI() (*big.Int, error)// to_i
func (c *Complex) ToR() (Num, error)     // to_r
func (c *Complex) ToC() *Complex         // to_c
func (c *Complex) Numerator() *Complex
func (c *Complex) Denominator() Num
func (c *Complex) Inspect() string       // "(1+2i)"
func (c *Complex) ToS() string           // "1+2i"
```

## MRI conformance

Correctness is defined by reference Ruby. A **differential oracle** runs a wide
corpus through both the system `ruby` and this library and compares the results
**byte-for-byte** — not approximated from memory. The oracle tests skip
themselves where `ruby` is not on `PATH` (e.g. the qemu arch lanes), so the
cross-arch builds still validate the library.

## Relationship to Ruby

`go-ruby-complex/complex` is **standalone and reusable**, and is the backend bound into
[go-embedded-ruby](https://github.com/go-embedded-ruby/ruby) by `rbgo` as a
native module — the same way [go-ruby-rational](https://github.com/go-ruby-rational/rational) and [go-ruby-regexp](https://github.com/go-ruby-regexp/regexp) are bound. The dependency runs the
other way: this library has no dependency on the Ruby runtime.

// Copyright (c) the go-ruby-complex/complex authors
// SPDX-License-Identifier: BSD-3-Clause
//
// Library-level workload for go-ruby-complex/complex: a representative mix of
// Ruby-visible Complex operations — construct, add, multiply, magnitude (abs),
// conjugate, rectangular<->polar conversion, and canonical to_s rendering. The
// equivalent Ruby program lives in ../ruby/complex.rb; both build identical
// inputs and print identical CHECK strings, verified byte-identical to MRI
// before any timing (see run.sh).
package main

import (
	"fmt"
	"math"

	"github.com/go-ruby-complex/complex"
)

// theta is atan2(4, 3): the phase of 3+4i. Computed the same way in Ruby
// (Math.atan2(4, 3)) so the polar<->rectangular workloads share identical bits.
var theta = math.Atan2(4, 3)

func f10(x float64) string { return fmt.Sprintf("%.10f", x) }

func main() {
	// Canonical operands, exact integer parts: 3+4i and 1+2i.
	a := complex.New(complex.IntFromInt64(3), complex.IntFromInt64(4))
	b := complex.New(complex.IntFromInt64(1), complex.IntFromInt64(2))

	// --- add: (3+4i)+(1+2i) = 4+6i ---
	check("add", a.Add(b).ToS())
	bench("add", 5000, func() { sink = a.Add(b) })

	// --- mul: (3+4i)*(1+2i) = -5+10i ---
	check("mul", a.Mul(b).ToS())
	bench("mul", 5000, func() { sink = a.Mul(b) })

	// --- abs (magnitude): |3+4i| = 5.0 ---
	check("abs", f10(a.Abs()))
	bench("abs", 5000, func() { sink = a.Abs() })

	// --- conjugate: conj(3+4i) = 3-4i ---
	check("conjugate", a.Conjugate().ToS())
	bench("conjugate", 5000, func() { sink = a.Conjugate() })

	// --- rect->polar: (3+4i).polar = [5.0, atan2(4,3)] ---
	abs, arg := a.PolarParts()
	check("rect-to-polar", f10(abs)+"/"+f10(arg))
	bench("rect-to-polar", 5000, func() {
		r, t := a.PolarParts()
		sink = r + t
	})

	// --- polar->rect: Complex.polar(5, atan2(4,3)) ~= 3+4i ---
	pr := complex.Polar(complex.Float(5), complex.Float(theta))
	re, im := pr.Rectangular()
	check("polar-to-rect", f10(re.Float64())+"/"+f10(im.Float64()))
	bench("polar-to-rect", 5000, func() {
		sink = complex.Polar(complex.Float(5), complex.Float(theta))
	})

	// --- to_s: (3+4i).to_s = "3+4i" ---
	check("to_s", a.ToS())
	bench("to_s", 5000, func() { sink = a.ToS() })
}

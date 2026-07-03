# frozen_string_literal: true
# SPDX-License-Identifier: BSD-3-Clause
#
# Reference workload for go-ruby-complex/complex, mirroring ../go/main.go op for
# op. Complex is core in Ruby (no require needed); every column but the pure-Go
# library uses that interpreter's own Complex. Inputs and CHECK strings are
# identical to the Go driver so run.sh can confirm parity before timing.
require_relative "_harness"

THETA = Math.atan2(4, 3) # phase of 3+4i, same bits as Go's math.Atan2(4, 3)

def f10(x) = format("%.10f", x)

# Canonical operands, exact integer parts: 3+4i and 1+2i.
a = Complex(3, 4)
b = Complex(1, 2)

# --- add: (3+4i)+(1+2i) = 4+6i ---
check("add", (a + b).to_s)
bench("add", 5000) { a + b }

# --- mul: (3+4i)*(1+2i) = -5+10i ---
check("mul", (a * b).to_s)
bench("mul", 5000) { a * b }

# --- abs (magnitude): |3+4i| = 5.0 ---
check("abs", f10(a.abs))
bench("abs", 5000) { a.abs }

# --- conjugate: conj(3+4i) = 3-4i ---
check("conjugate", a.conjugate.to_s)
bench("conjugate", 5000) { a.conjugate }

# --- rect->polar: (3+4i).polar = [5.0, atan2(4,3)] ---
r, t = a.polar
check("rect-to-polar", "#{f10(r)}/#{f10(t)}")
bench("rect-to-polar", 5000) { a.polar }

# --- polar->rect: Complex.polar(5, atan2(4,3)) ~= 3+4i ---
pr = Complex.polar(5, THETA)
check("polar-to-rect", "#{f10(pr.real)}/#{f10(pr.imaginary)}")
bench("polar-to-rect", 5000) { Complex.polar(5, THETA) }

# --- to_s: (3+4i).to_s = "3+4i" ---
check("to_s", a.to_s)
bench("to_s", 5000) { a.to_s }

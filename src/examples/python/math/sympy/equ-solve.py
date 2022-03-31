#!/usr/bin/env python3
#
# equ-solve.py -- solve math equations
#
# 1. x^2 + (y-5)^2 = 5^2
# 2. y = x
#

from sympy.plotting import plot_implicit
from sympy.abc import x, y
from sympy import Eq, solve

# solve it directly
result = solve([Eq(x**2 + (y-5)**2, 5**2), Eq(y, x)])
print("result: ", result)

# solve it with plotting
p1 = plot_implicit(Eq(x**2 + (y-5)**2, 5**2), (x, -15, 15), (y, -15, 15), line_color='red', depth = 1, show = False, margin = 10)
p2 = plot_implicit(Eq(y, x), (x, -10, 10), (y, -10, 10), depth = 1, line_color='blue', show = False)
p1.extend(p2)

p1.title = "\n\nEquations: 1. x^2 + (y-5)^2 = 5^2; 2. y = x\n\n"
p1.size = (12, 12)
p1.show()
p1.save("equ-solve.jpg")

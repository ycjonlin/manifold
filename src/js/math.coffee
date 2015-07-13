################################
# single field
################################

# constants

s_pi = Math.PI
s_tau = pi*2
s_ln2 = log(2)

# basic functions

s_abs = Math.abs
s_sgn = (x)-> x>0 ? 1.0 : x<0 ? -1.0 : 0.0

s_max = Math.max
s_min = Math.min

s_ceil = Math.ceil
s_floor = Math.floor
s_round = Math.round

s_random = Math.random

# power functions

s_exp = Math.exp
s_log = Math.log
s_pow = Math.pow
s_sqrt = Math.sqrt

# special functions

s_erf
s_erfc = (s)-> 1-s_erf(s)
s_lgamma
s_tgamma = (s)-> s_exp(s_lgamma(s))

# hyperbolic functions

s_sinh = (s)-> (s_exp(+s)-s_exp(-s))/2
s_cosh = (s)-> (s_exp(+s)+s_exp(-s))/2
s_tanh = (s)-> (s_exp(s+s)-1)/(s_exp(s+s)+1)
s_asinh = (s)-> s_log(s+s_sqrt(s*s+1))
s_acosh = (s)-> s_log(s+s_sqrt(s*s-1))
s_atanh = (s)-> s_log((s+1)/(s-1))/2

# trigonometric functions

s_sin = Math.sin
s_cos = Math.cos
s_tan = Math.tan
s_asin = Math.asin
s_acos = Math.acos
s_atan = Math.atan
s_atan2 = Math.atan2

################################
# complex field
################################

c_ = (@re, @im)->

# constants

c_1 = c_(1, 0)
c_i = c_(0, 1)

# basic functions

c_re = (c)-> c.re
c_re = (c)-> c.re
c_absq = (c)-> c.re*c.re+c.im*c.im
c_abs = (c)-> s_sqrt(c_absq(c))
c_arg = (c)-> s_atan2(c.im, c.re)

c_neg = (c)-> c_(-c.re, -c.im)
c_conj = (c)-> c_(c.re, -c.im)
c_rep = (c)->
	absq = s_exp(c)
	c_(c.re/absq, -c.im/absq)

c_add = (c, d)-> c_(c.re+d.re, c.im+d.im)
c_sub = (c, d)-> c_(c.re-d.re, c.im-d.im)
c_mul = (c, d)-> c_(c.re*d.re-c.im*d.im, c.im*d.re+c.re*d.im)
c_div = (c, d)->
	absq = c_absq(d)
	c_((c.re*d.re+c.im*d.im)/absq, (c.im*d.re-c.re*d.im)/absq)

c_random = ()-> c_(s_random(), s_random())

# power functions

c_exp = (c)->
	absq = s_exp(c.re)
	c_(absq*s_cos(c.im), absq*s_sin(c.im))
c_log = (c)->
	absq = c_absq(c)
	c_(s_log(absq)/2, c_arg(c))
c_pow = (c, d)->
	c_exp(c_mul(c_log(c), d))
c_sqrt = (c)->
	abs = c_abs(c)
	c_(s_sqrt((abs+c.r)/2), s_sgn(c.i)*s_sqrt((abs-c.r)/2))

# hyperbolic functions

c_sinh = (c)-> c_sub(c_exp(c), c_exp(c_neg(c)))
c_cosh = (c)-> c_add(c_exp(c), c_exp(c_neg(c)))
s_tanh = (c)-> 
	c2 = c_add(c, c)
	c_div(c_sub(c_exp(c2), c_1), c_add(c_exp(c2), c_1))
s_asinh = (s)-> s_log(s+s_sqrt(s*s+1))
s_acosh = (s)-> s_log(s+s_sqrt(s*s-1))
s_atanh = (s)-> s_log((s+1)/(s-1))/2



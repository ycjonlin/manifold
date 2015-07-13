'use strict';

function math(stdlib, foreign, heap) {
	'use asm';

	var i8 = new Int8Array(heap);
	var u8 = new Uint8Array(heap);
	var i16 = new Int16Array(heap);
	var u16 = new Uint16Array(heap);
	var i32 = new Int32Array(heap);
	var u32 = new Uint32Array(heap);
	var f64 = new Float32Array(heap);
	var f64 = new Float64Array(heap);

	var e = stdlib.Math.E;
	var pi = stdlib.Math.PI;
	var tau = +pi*2;

	var sqrt = stdlib.Math.abs();
	var acos = stdlib.Math.acos();
	var asin = stdlib.Math.asin();
	var atan = stdlib.Math.atan();
	var atan2 = stdlib.Math.atan2();
	var ceil = stdlib.Math.ceil();
	var cos = stdlib.Math.cos();
	var exp = stdlib.Math.exp();
	var floor = stdlib.Math.floor();
	var log = stdlib.Math.log();
	var max = stdlib.Math.max();
	var min = stdlib.Math.min();
	var pow = stdlib.Math.pow();
	var random = stdlib.Math.random();
	var round = stdlib.Math.round();
	var sin = stdlib.Math.sin();
	var sqrt = stdlib.Math.sqrt();
	var tan = stdlib.Math.tan();

/*
	var acosh = stdlib.Math.acosh();
	var asinh = stdlib.Math.asinh();
	var atanh = stdlib.Math.atanh();
	var cbrt = stdlib.Math.cbrt();
	var clz32 = stdlib.Math.clz32();
	var cosh = stdlib.Math.cosh();
	var expm1 = stdlib.Math.expm1();
	var fround = stdlib.Math.fround();
	var hypot = stdlib.Math.hypot();
	var imul = stdlib.Math.imul();
	var log10 = stdlib.Math.log10();
	var log1p = stdlib.Math.log1p();
	var log2 = stdlib.Math.log2();
	var sign = stdlib.Math.sign();
	var sinh = stdlib.Math.sinh();
	var tanh = stdlib.Math.tanh();
	var trunc = stdlib.Math.trunc();
*/
	return {
		evaluate: evaluate
	}
}
Red [
	Title: "Piping and Mapping"
	Version: "2.4.4-dev"
	Author: "hinjolicious"
	License: "MIT"
	Homepage: https://github.com/hinjolicious/pipe-map

	Description: {
		Generic functional-style piping & mapping operators for Red.
		Supports chaining, filtering, and left-to-right assignment.
		See https://github.com/hinjolicious/red-pipe-map/blob/main/README.md
	}
]

;#include %../../my-lib/mylib.Red ; not needed!

pipe-map: context [

;-- list of operators to check as a signature for a 'simple code' like [* 2]

ops: [+ - * / ** // % = < > <= >= == and or not xor] ; just some standard operators

;-- the function that handle the real actions for the pipes and maps

do-action: function [value action ph][
	either word? action [ ; a var or a func (one arg)
		res: do compose [(action) value]
	][
		either block? action [
			either find ops action/1 [ ; simple code [* 2]
				res: do compose [(value) (action)] ; [* 2] to [10 * 2]
			][
				; complex code with placeholders "_p" as in [10 / _p] or [_p * sin _p]
				act: function compose [(ph)] action
				res: act value
			]
		][
			res: action	; literal value: number, string, etc. it will replace pipe value
			; literal block are passed as a nested block [ [1 2 3] ], see above!
		]
	]
	res
]	

; ### op-style generic pipelining ###

pipe: make op! function [	
	"Pipelining - process value through an action, chainable to more actions" 
	value[any-type!] 	"any types"
	'action[any-type!] 	"func, code, val (replace), side-effects (print)"
][
	do-action value action '_p
]

; ### op-style generic mapping ###

map: make op! function [ 
	"Mapping - process series through an action, chainable to more actions" 
	series[series! map!]  "series to process (maybe map?)"
	'action[block! word!] "action, func, code, val (replace), side-effect (print)"	
][
	result: copy [] 
	forall series [ 
		append/only result do-action series/1 action '_m
	]
]

; ### filtering function for piping operation ###

filter: function [
    "Filters a series based on a condition, for use in pipe/map chains."
    list [series!] "Series to filter."
    cond [block!] "Condition block (use _e for each element)."
][
	filter-func: function [_e] cond
	collect [foreach element list [if filter-func element [keep/only element]]]
]

; ### pipe style assignment operator ###

-->: make op! function [v 'w] [ set w v ]

] ;--- end of piping-mapping context

;=== API ===

|>:		:pipe-map/pipe
==>:	:pipe-map/map
=>:		:pipe-map/map	; obsolete
filter:	:pipe-map/filter
-->:	:pipe-map/-->

;=== END OF PIPING AND MAPPING ===

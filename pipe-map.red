Red [
	Title: "Piping and Mapping"
	Version: 2.4.3
	Author: "hinjolicious"
	Feature: {
		- Powerful generic piping/pipelining: value |> action1 |> action2 ...
		- Powerful generic chainable mapping: value ==> action1 ==> action2 ...
		- Pipelining style (left to right) assignment: value --> var
		- Filtering function that works in both piping and mapping: value |> [filter _p [_e > 5]]
		- Mixing of piping and mapping seamlessly
	}
	Changes: {
		- piping op => is changed to ==> to avoid confusion with >= op
		- added --> as a pipe-style assignment op
		- added filtering func that works in both piping and mapping
		- side-effect is now explicit, i.e. if you're trying to print or do any side-effects, you must
		  explicitly pass the value to the pipe/map to not cause it error.
	}
	Usage: {
		- include this file in your code: #include %pipe-map.red
		- to run the test: comment the "halt", so it will continue executing the test codes
		- Piping/Pipelining: 
			init |> action1 |> action2 |> ...
		- Mapping:
			init ==> action1 ==> action2 ==> ...
		- Mixed piping/Mapping:
			init |> action1 ==> action2 ...
		- Initial value can be anything: literal, variable, function
		- Actions can be function, code block, variable, literal, etc.
		- Code blocks are in the form: 
			- [+ val]			- implicit placeholder
			- [_p * (sin _p)]	- explicit placeholders
		- Placeholders:
			- _p		pipe value
			- _m		mapping element
			- _e		filter element
		- Filter: filter is a helper function to filter things from the pipe/map:
			- [filter _p [_e > 5]]
			- [filter _m [(length? _e) > 5]]
		- Left-to-right assignment:
			value --> var 		assign value to variable var
	}
]

;#include %mylib.Red ; not needed!

pipe-map: context [

; ### helper funcs ###

;-- find a word in block/paren recursively

find-deep: function [ block[block! paren!] word[word!] ][
	forall block [
		either word? item: first block [
			if item = word [ return true ]
		][
			if any [block? item paren? item] 
				[ if find-deep item word [return true] ]
		]
	]
	false
]

;-- replace all words with a value in a block/paren recursively

replace-deep: function [ block[block! paren!] word[word!] value[any-type!] ] [
	forall block [
		either word? item: first block [
			if item = word [
				change/only block value ; must use /only!!!
			]
		][
			if any [block? item paren? item] 
				[ replace-deep item word value ]
		]
	] 
	block
]

;-- the real function that handle actions for the pipe and map

do-action: function [value action ph] [
	either word? action [ 
		; value or a function with one arg only
		res: do compose [(action) value]
	][
		either block? action [ ; normal code, simple code, or just a block
			act: copy/deep action ; use a copy, because it will be changed!
			either find-deep act ph [ 
				; normal code with placeholders "_p" as in [10 / _p] or [_p * sin _p]
				replace-deep act ph value ; replace all placeholders with actual value
				res: do act
			][
				; simple code is using an implicit placeholder like [* 2], meaning [_p * 2]
				; to pass a block in the middle of the pipe, use nested block like [[1 2 3]]
				; a normal block will assign the value of the last element only! 
				; [1 2 3] will assign 3
				insert act value ; insert the actual value
				res: do act
			]
		][
			; just a literal value, it will replace pipe's value
			res: action	
		]
	]
	res
]	

; ### op-style generic pipelining ###

pipe: make op! func [	
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

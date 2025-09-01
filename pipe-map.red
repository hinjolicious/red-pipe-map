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

;=== TEST === 

comment { 

;-- 1. Simple pipe

probe "Red is rocking!" |> [split _p " "]		; split it into three part
; ["Red" "is" "rocking!"]

probe "Red is rocking!" |> uppercase |> [split _p " "]		; uppercase then split
; ["RED" "IS" "ROCKING!"]

probe "Red is rocking!" |> [find/last _p "king!"]		; check if it ended in "king!"
; "king!"

;-- 2. More complex pipe

convert-json: func [json][	; a data transformation function using pipe
	json
	|> [replace/all _p "{" ""  replace/all _p "}" ""] 
	|> [replace/all _p "," " " replace/all _p ":" " "] 
	|> [to-block _p]
	|> [to-map _p]		; output is a map
]

my-json: {{"id":123,"node_id":"abc","name":"Dude","full_name":"CoolDude/CoolStuff"}}
my-json: convert-json my-json	; calling it

probe my-json	; the resut
; #[
;    "id" 123
;    "node_id" "abc"
;    "name" "Dude"
;    "full_name" "CoolDude/CoolStuff"
; ]

print ["my name:" my-json/"name"]
; my name: Dude

print ["full name:" my-json/"full_name"]
; full name: CoolDude/CoolStuff

;-- 3. More tests

numbers: [1 2 3 4 5 6 7 8 9 10]

numbers		; using a variable as initial value
	==> [* 2] ==> [+ 3]		; using a simple code block--double it then plus 3. notice this is a chained mapping
	==> [_m * _m] 			; using complex code block, with explicit _m placeholders for mapping element
	==> to-string 			; using a simple function call
	|> to-block 			; continue it seamlessly with piping
	|> [s: copy "0" foreach e _p [append s rejoin [" + " e]]]	; long complex code
	|> [do load _p] 		; load the result and execute it
	--> result				; left to right assignment
print result
; 2290

; this start using literal value, piping and mapping 
; using a side-effect, like print, must exlicitly pass the a value so it won't cause an error!
; using --> for left to right assignment

"Red is rocking hard!" |> [split _p " "] ==> uppercase ==> [print ["***" _m "***"] _m] --> result
probe result 
; *** RED ***
; *** IS ***
; *** ROCKING ***
; *** HARD! ***

;-- 4. Using filtering function

probe [1 2 3 4 5 6 7 8 9 10] |> [filter _p [_e > 5]] 
; [6 7 8 9 10]

probe [ [1] [1 2] [1 2 3] [1 2 3 4] [1 2 3 4 5] ] |> [filter _p [(length? _e) > 3]]		; filtering in pipe
; [[1 2 3 4] [1 2 3 4 5]]

probe [ [1] [1 2] [1 2 3] [1 2 3 4] [1 2 3 4 5] ] ==> [filter _m [(_e % 2) = 1]]		; filtering in map
; [[1] [1] [1 3] [1 3] [1 3 5]]

;-- More test

number-gen: function [min max num][
	;random/seed now/time/precise
	collect [loop num [keep min + random (max - min)]]
]

variance: function [x[series!] /sample /sm m0[number!]] [
; /sample : sample mean, instead of population
; /sm : set mean to m0
	m: either sm [m0] [average x]
	;( sx: 0  foreach xi x [ sx: sx + ((xi - m) ** 2)] ) / ( (length? x) - either sample [1][0] )
	x ==> [(_m - m) ** 2] |> sum |>[/ ( (length? x) - either sample [1][0] )]
]

stddev: function [x[series!] /sample /sm m0[number!]] [
; /sample : sample mean, instead of population
; /sm : set mean to m0
	m: either sm [m0] [average x]
	sqrt variance/sm/:sample x m
]

pop-kurtosis: function [x[series!] /sm m0[number!]][
; Kurtosis for population (from calculatorsoup)
; common in stats, platykurtic, lighter tails 
    n: length? x
	m: either sm [m0] [average x]
    sd: stddev/sm x m
    if sd = 0 [return 0.0]
    ;(s: 0  foreach xi x [s: s + ((xi - m) ** 4)]) / (n * (sd ** 4))
	;x ==> [(_m - m) ** 4] |> sum |> [/ (n * (sd ** 4))]
	; simplified to:
	;(1 / n) * ( s: 0  foreach xi x [ s: s + (((xi - m) / sd) ** 4) ] )
	x ==> [((_m - m) / sd) ** 4] |> sum |> [/ n]
]

random/seed 1
(number-gen 100 1000 100) --> nums
print ["count:" nums |> length?]
print ["mean:" nums  |> average]
print ["variance" nums |> variance]
print ["stddev" nums |> stddev]
print ["kurtosis" nums |> pop-kurtosis]
; count: 100
; mean: 570.5
; variance 66697.69
; stddev 258.2589591863175
; kurtosis 1.812035856029364

; [2 4 4 4 5 5 7 9] 
; count: 8
; mean: 5
; variance 4
; stddev 2.0
; kurtosis 2.78125

}
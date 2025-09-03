Red[]

#include %../pipe-map.red
;#include %pipe-map-mini.red
;#include %pipe-map-opt.red
;#include %pipe-map-minified.red

;=== TEST === 

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

; === Example with Nested-Block and Nested-Mapping===

print "Nested-block, nested-mapping, complex code:"
[ [1 2 3] [10 20 30] ] 		; nested-block
	==> [ _m ==> [* 2] ] 	; map it and map it the inner block each!
	|> probe				; check the output 
	|> [s: copy [] 			; this is quie a complex code block in this pipe
		x: _p 				; to access the element by path, we need to assign it to a var first
		a: x/1 				; maybe i'll fix this, so we can use path directly
		b: x/2 
		collect [			; gather it and produce one list only!
			repeat i 3 [			; maybe we'll add list-comprehension to make things interesting!
				keep a/:i + b/:i
			]
		]	
	] 
	|> probe
	--> my-list		; assign it for later
		
; [[2 4 6] [20 40 60]]
; [22 44 66]

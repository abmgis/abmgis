; networks in netlogo
;
; demo of various social networks in NetLogo
;
; steve scott
; sscotta@gmu.edu
; George Mason University
; Computational Social Science Program
; Fairfax VA
;
; Fall 2014
; -----------------------------------------------------------------------------------
extensions [nw]
breed [nodes node]
undirected-link-breed [edges edge]

globals [ path
  average_betweenness
  average_closeness
  average_eigen
  std_betweenness
  std_closeness
  std_eigen
  max_betweenness
  max_closeness
  max_eigen
  max_friends
  average_friends
  std_friends
  node-list]

nodes-own [closeness betweenness eigen friends degrees]
to setup
  clear-all
  setup-patches
  setup-network
  layout-network
  render-plot
  stats

  reset-ticks
end

to setup-patches
  ask patches [
    set pcolor black
  ]
end

; erdos-renyi
;
; random network w/ probability prob-link of making a link
;
to setup-erdos-renyii
  nw:generate-random nodes edges N p
nw:save-matrix (word "er.txt")
end


; barabasi-albert
;
; sets up network with preferential attraction
;
to setup-barabasi-albert[ num-nodes prob-link max-links ]
  create-nodes num-nodes [
    set color red
    set size 1.0
    set shape "circle"
    let spot one-of patches with[not any? nodes-here]
    ifelse (spot != nobody) [
      move-to spot
    ]
    [setxy random-pxcor random-pycor]
  ]

  ask nodes [
    let  my-node self
    set degrees max-n-of max-links nodes [count link-neighbors]
    foreach sort degrees [ [?1] ->
      let chance random-float 1.0
      if (chance < prob-link) and (?1 != my-node) [
        ask my-node [
          create-link-with ?1
        ]
      ]
    ]
  ]

nw:save-matrix (word "pa.txt")
end

; watts-strogatz
;
; build a "small world" network
to setup-watts-strogatz[ num-nodes num-links prob-rewire ]

create-nodes num-nodes [
    set color red
    set size 1.0
    set shape "circle"
    let spot one-of patches with[not any? nodes-here]
    ifelse (spot != nobody) [
      move-to spot
    ]
    [setxy random-pxcor random-pycor]
  ]

  set node-list sort nodes
  let i 0
  foreach node-list [ [?1] ->
    let j ?1
    let k 1
    let link-nodes []
    while [ k <= num-links ]
    [
      let ptr (i + k + (length node-list)) mod (length node-list)
      set link-nodes lput (item ptr node-list) link-nodes
      set k (k + 1)
    ]
    foreach link-nodes [ [??1] ->
      set k ??1
      ask j [ create-link-with k]
    ]
    set i (i + 1)
  ]


  ;
  ; make some long jump links
  ;
  foreach sort nodes [ [?1] ->
    ask ?1 [
      let temp sort link-neighbors
      foreach temp [ [??1] ->
        if random-float 1.0 < prob-rewire [
          let x one-of other nodes with [ abs (who - [who] of myself) > 2 ]
          if is-node? x
          [
            ask link-with ??1 [ die ]
            create-link-with x
          ]
        ]
      ]
    ]
  ]

    nw:save-matrix (word "sw.txt")
end

; uniform
;
; each node has num-links links
;
to setup-uniform[ num-nodes num-links ]
  create-nodes num-nodes [
    set color red
    set size 1.0
    set shape "circle"
    let spot one-of patches with[not any? nodes-here]
    ifelse (spot != nobody) [
      move-to spot
    ]
    [setxy random-pxcor random-pycor]
  ]

  set node-list sort nodes
  let i 0
  foreach node-list [ [?1] ->
    let j ?1
    let k 1
    let link-nodes []
    while [ k <= num-links ]
    [
      let ptr (i + k + (length node-list)) mod (length node-list)
      set link-nodes lput (item ptr node-list) link-nodes
      set k (k + 1)
    ]
    foreach link-nodes [ [??1] ->
      set k ??1
      ask j [ create-link-with k]
    ]
    set i (i + 1)
  ]
end

to setup-network
  if network-type = "erdos-renyi" [ setup-erdos-renyii ]
  if network-type = "barabasi-albert" [ setup-barabasi-albert N p M]
  if network-type = "watts-strogatz" [ setup-watts-strogatz N M p ]
  if network-type = "uniform" [ setup-uniform N M ]
end

;
; example of a layout generator
;
; causes nodes to jiggle around rather aimlessly
;
to layout-equidistant [ num-loops ]
  repeat num-loops [
    ask nodes [

      ;
      ; scan area in conics range units out, width degrees wide
      ;
      let scan-angles [0 30 60 90 120 150 180 210 240 270 300 330]
      let _range 10
      let width 30
      let zone-count []
      foreach scan-angles [ [?1] ->
        set heading ?1
        let num count nodes-on patches in-cone _range width
        set zone-count (lput num zone-count)
      ]

      ;
      ; find least populated zone(s)
      ;
      let min-zone min zone-count
      let i 0
      let ptr []
      foreach zone-count [ [?1] ->
        if ?1 = min-zone [
          set ptr lput (item i scan-angles) ptr
        ]
        set i (i + 1)
      ]

      ;
      ; now move in most vacant direction
      ;
      set heading one-of ptr
      forward 0.5

      ;; type "debug: node " type self type " has zone count " type zone-count type " moving in direction " type ptr print " "
    ]
  ]
end

to layout-centroid [ d ]
  ask nodes [
    let nearby nodes in-radius d
    if (count nearby > 1) [
      let mid-x mean [pxcor] of nearby
      let mid-y mean [pycor] of nearby
      facexy mid-x mid-y
      set heading 180 + heading
      forward 1
    ]
  ]
end

to layout-random
  ask nodes [
    let spot one-of patches with [not any? nodes-here]
    if (spot != nobody) [ move-to spot ]
  ]
end

to layout-network
  if layout-type = "random" [ layout-random ]
  if layout-type = "spring" [ layout-spring nodes edges 1 3 2]
  if layout-type = "circle" [ layout-circle sort turtles max-pxcor * 0.9 ]
  if layout-type = "radial" [ layout-radial nodes edges node 1 ]
  if layout-type = "equidistant" [ layout-equidistant 50 ]
  if layout-type = "centroid" [ repeat 20 [ layout-centroid 2 ] ]
end

to step
  render-plot
end

to go
  step
  tick
end

; render-plot
;
; manually generate plots to show centrality info
;
to render-plot
  ;
  ; get the centrality data
  ;
  let degree-centrality-list sort [count link-neighbors] of nodes

  ;
  ; plot the degree distribution
  ;
  set-current-plot "Degree Centrality"
  clear-plot
  set-current-plot-pen "degree centrality"
  set-plot-pen-mode 0
  set-plot-x-range 0 (max (list degree-centrality-list 1.0))

  let i 0
  foreach degree-centrality-list [ [?1] ->
    plot-pen-down
    plotxy i ?1
    set i (i + 1)
    plot-pen-up
  ]

  ;
  ; histogram of degree distributions
  ;
  set-current-plot "Degree Distribution"
  clear-plot
  set-current-plot-pen "degree distribution"
  set-plot-pen-mode 1
  set-plot-x-range 0 (max degree-centrality-list) + 1
  set-histogram-num-bars 10
  histogram [count link-neighbors] of nodes
end

to stats
 ask nodes [
  set closeness  nw:closeness-centrality
   set betweenness nw:betweenness-centrality
   set eigen nw:eigenvector-centrality
   set friends count link-neighbors
  ]


  set average_betweenness mean [betweenness] of nodes
  set average_closeness mean [closeness] of nodes
  set std_betweenness standard-deviation [betweenness] of nodes
  set std_closeness standard-deviation [closeness] of nodes
  set max_betweenness max [betweenness] of nodes
  set max_closeness max [closeness] of nodes
  set max_friends max [friends] of nodes
  set std_friends standard-deviation [friends] of nodes
  set average_friends mean [friends] of nodes

  if [eigen] of node 0 != false [
   set average_eigen mean [eigen] of nodes
    set std_eigen standard-deviation [eigen] of nodes
    set max_eigen max [eigen] of nodes
  ]

end
@#$#@#$#@
GRAPHICS-WINDOW
215
10
633
429
-1
-1
10.0
1
10
1
1
1
0
0
0
1
-20
20
-20
20
0
0
1
ticks
30.0

BUTTON
6
75
69
108
setup
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
73
74
136
107
step
step
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
140
74
203
107
go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
13
24
163
68
Social Networks in NetLogo
18
0.0
1

CHOOSER
7
129
199
174
network-type
network-type
"erdos-renyi" "barabasi-albert" "watts-strogatz" "uniform"
1

SLIDER
9
323
181
356
p
p
0.0
1.0
0.2
0.0001
1
NIL
HORIZONTAL

SLIDER
11
257
183
290
N
N
0
2500
25.0
25
1
NIL
HORIZONTAL

CHOOSER
7
181
194
226
layout-type
layout-type
"random" "spring" "circle" "radial" "centroid" "equidistant"
2

PLOT
641
10
841
160
Degree Centrality
Cumulative Frequency
Degree
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"degree centrality" 1.0 0 -16777216 true "" ""

PLOT
642
166
842
316
Degree Distribution
Degree
No. of Nodes
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"degree distribution" 1.0 1 -16777216 true "" ""

MONITOR
665
325
722
370
N
count nodes
0
1
11

MONITOR
725
324
782
369
edges
count links
0
1
11

SLIDER
10
393
182
426
M
M
0
50
3.0
1
1
NIL
HORIZONTAL

BUTTON
61
436
127
469
layout
layout-network
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
14
239
164
257
N = num nodes
11
0.0
1

TEXTBOX
15
304
204
332
P = probability of link (ER, BA, WS)
11
0.0
1

TEXTBOX
15
373
165
391
M = max links (BA)
11
0.0
1

MONITOR
665
384
742
429
no friends
count nodes with [friends = 0]
17
1
11

MONITOR
743
384
800
429
max
max [friends] of nodes
17
1
11

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
0
Rectangle -7500403 true true 151 225 180 285
Rectangle -7500403 true true 47 225 75 285
Rectangle -7500403 true true 15 75 210 225
Circle -7500403 true true 135 75 150
Circle -16777216 true false 165 76 116

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -7500403 true true 135 285 195 285 270 90 30 90 105 285
Polygon -7500403 true true 270 90 225 15 180 90
Polygon -7500403 true true 30 90 75 15 120 90
Circle -1 true false 183 138 24
Circle -1 true false 93 138 24

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.0.2
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@

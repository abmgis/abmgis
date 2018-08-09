; ************************************************
; **********     Agent definition     ************
; ************************************************

; Create 2 breeds of store agent
breed [ supermarkets supermarket ]
breed [ convenience-stores convenience-store ]

;Create 7 different types of consumer agents
breed [consumer-as consumer-a]
breed [consumer-bs consumer-b]
breed [consumer-cs consumer-c]
breed [consumer-ds consumer-d]
breed [consumer-es consumer-e]
breed [consumer-fs consumer-f]
breed [consumer-gs consumer-g]

; Create supermarket variables
supermarkets-own [
  attractiveness ; Records the stores attractivess score
  customers ; Records the who number of each consumer agent that visits the store
  spend-at-store ; Keeps track of the spend at the store
]

; Create convenience-store variables
convenience-stores-own [
  attractiveness ; Records the stores attractivess score
  customers ; Records the who number of each consumer agent that visits the store
  spend-at-store ; Keeps track of the spend at the store
]

; Create consumer variables
consumer-as-own [
  home-location ; Stores the home location of consumer
  destination ; Keeps track of the consumers current destination
  probability ; Keeps track of the consumers current probability of going to a store
  visits ; Keeps track of the number of visits the consumer makes to a store
  distance-travelled ; Keeps track of the distance travelled by the consumer
]

consumer-bs-own [
  home-location
  destination
  probability
  visits
  distance-travelled
]

consumer-cs-own [
  home-location
  destination
  probability
  visits
  distance-travelled
]

consumer-ds-own [
  home-location
  destination
  probability
  visits
  distance-travelled
]

consumer-es-own [
  home-location
  destination
  probability
  visits
  distance-travelled
]

consumer-fs-own [
  home-location
  destination
  probability
  visits
  distance-travelled
]

consumer-gs-own [
  home-location
  destination
  probability
  visits
  distance-travelled
]

; Create patch variables
patches-own [
  area-type ; Records the geo-demographic type of the patch
]

; ************************************************
; ************     Go procedures      ************
; ************************************************

; Procedure called every time the model iterates
to go

  ask consumer-as [
    set probability 0 ; Set the initial probability of going to a store
    if member? ticks [ 2 5 8 11 14 17 20 ] [
      set probability 75 ; Update the probability based on the time counter
    ]
    if random 100 < probability [ ; Compare the probability to a randomly generate number
      shop ; Tell the consumer to go to a store (call the 'shop' procedure)
      set destination one-of supermarkets ; Reset the consumers destination
    ]
  ]

  ask consumer-bs [
    set probability 0
    if member? ticks [ 0 1 3 4 6 7 9 10 12 13 ] [
      set probability 50
    ]
    if random 100 < probability [
      shop
      set destination min-one-of supermarkets [ distance myself ]
    ]
  ]

  ask consumer-cs [
    set probability 20
    if member? ticks [ 2 5 8 11 14 ] [
      set probability 75
    ]
    if random 100 < probability [
      shop
      set destination min-one-of convenience-stores [ distance myself ]
    ]
  ]

  ask consumer-ds [
    set probability 0
    if member? ticks [ 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 ] [
      set probability 90
    ]
    if random 100 < probability [
      shop
      set destination one-of turtles with [ breed = supermarkets or breed = convenience-stores and pcolor = yellow ]
    ]
  ]

  ask consumer-es [
    set probability 50
    if random 100 < probability [
      shop
      set destination one-of turtles with [ breed = supermarkets or breed = convenience-stores ]
    ]
  ]

  ask consumer-fs [
    set probability 0
    if member? ticks [ 15 16 18 19 ] [
      set probability 50
    ]
    if random 100 < probability [
      shop
      set destination one-of supermarkets
    ]
  ]

  ask consumer-gs [
    set probability 0
    if member? ticks [ 2 5 8 11 14 ] [
      set probability 40
    ]
    if random 100 < probability [
      shop
      set destination one-of turtles with [ breed = supermarkets or breed = convenience-stores ]
    ]
  ]

  ifelse ticks < 20
    [ tick ] ; Increment time counter
    [ reset-ticks ] ; Reset time counter after 21 ticks

end


; Procedure to simulate a shopping trip
to shop

  ; This code attempts to replicate a spatial interaction model

  ; Approach 1
  ; Create a variable to hold a list of stores in a local neighbourhood around the consumer
  ; let candidate-stores turtles with [ breed = supermarkets or breed = convenience-stores ] in-radius 10
  ; Create a variable to store the store with the highest attractiveness store
  ; let best-candidate max-one-of candidate-stores [ attractiveness ]
  ; Set the consumers 'destination' variable
  ; set destination best-candidate

  ;Approach 2
  ; Create a variable to hold a list of stores in a local neighbourhood around the consumer
  ; let candidate-stores turtles with [ breed = supermarkets or breed = convenience-stores ] in-radius 10
  ; Create variables to hold a list of the candidate stores size, distance to store and attractiveness score
  ; let sizelist []
  ; let distlist []
  ; let attractlist []
  ; For each canditate store add store size and distance to lists and apply spatial interaction equation to calculate flows to stores
  ; ask candidate-stores [
    ; set sizelist lput store-size sizelist
    ; set distlist lput distance myself distlist
    ; set attractlist (map [ (?1 * exp (-0.5 * ?2) ) ] sizelist distlist)
  ;]

  ; Create a variable to store the consumers current x and y coordinates
  let old-xcor xcor
  let old-ycor ycor

  move-to destination ; Move consumer agent to their destination

  set distance-travelled distance-travelled + distancexy old-xcor old-ycor ; Record distance from home location to store
  set visits visits + 1 ; Increment the consumers 'visits' variable by one

  ask supermarkets-here [
    log-consumers ; Tell store to record customers (call 'log-consumers' procedure)
    log-supermarket-spend ; Tell store to record spend (call 'log-supermarket-spend' procedure)
  ]

  ask convenience-stores-here [
    log-consumers ; Tell store to record customers (call 'log-consumers' procedure)
    log-convenience-spend ; Tell store to record spend (call 'log-convenience-spend' procedure)
  ]

  ; Reset x and y coordinates to consumers current location
  set old-xcor xcor
  set old-ycor ycor

  move-to home-location ; Return consumer agent to home location

  set distance-travelled distance-travelled + distancexy old-xcor old-ycor ; Record distance from store to home location
end


; Procedure to log the who number of consumer agents that visit a store
to log-consumers
  if any? consumer-as-here [
    set customers lput [who] of consumer-as-here customers
  ]
  if any? consumer-bs-here [
    set customers lput [who] of consumer-bs-here customers
  ]
  if any? consumer-cs-here [
    set customers lput [who] of consumer-cs-here customers
  ]
  if any? consumer-ds-here [
    set customers lput [who] of consumer-ds-here customers
  ]
  if any? consumer-es-here [
    set customers lput [who] of consumer-es-here customers
  ]
  if any? consumer-fs-here [
    set customers lput [who] of consumer-fs-here customers
  ]
  if any? consumer-gs-here [
    set customers lput [who] of consumer-gs-here customers
  ]
end

; Procedure to log the spend at supermarket stores
to log-supermarket-spend
  ifelse any? consumer-as-here [ ; Increase spend if consumer is of type a (high-value customer)
    set spend-at-store spend-at-store + 120 ][
    set spend-at-store spend-at-store + 100
  ]
end

; Procedure to log the spend at convenience stores
to log-convenience-spend
  set spend-at-store spend-at-store + 20
end

; ************************************************
; ************    Setup procedures    ************
; ************************************************

; Procedure to set up the model
to setup
  clear-all
  reset-ticks
  setup-patches
  setup-supermarkets
  setup-convenience-stores
  setup-consumer-as
  setup-consumer-bs
  setup-consumer-cs
  setup-consumer-ds
  setup-consumer-es
  setup-consumer-fs
  setup-consumer-gs
end

; Procedure to configure patches
to setup-patches

  ask patches [
    set pcolor white
  ]

  ask patches with [ pxcor >= 9 and pxcor < 12 and pycor >= 0 and pycor < 3 ] [
    set pcolor yellow
  ]

  ask patches with [ pxcor >= 3 and pxcor < 6 and pycor >= 3 and pycor < 6 ] [
    set pcolor orange
  ]

  ask patches with [ pxcor >= 6 and pxcor < 9 and pycor >= 6 and pycor < 9 ] [
    set pcolor yellow
  ]

  ask patches with [ pxcor >= 6 and pxcor < 9 and pycor >= 3 and pycor < 6 ] [
    set pcolor yellow
  ]

  ask patches with [ pxcor >= 12 and pxcor < 15 and pycor >= 3 and pycor < 6 ] [
    set pcolor blue
  ]

  ask patches with [ pxcor >= 15 and pxcor < 18 and pycor >= 6 and pycor < 9 ] [
    set pcolor blue
  ]

  ask patches with [ pxcor >= 18 and pxcor < 21 and pycor >= 6 and pycor < 9 ] [
    set pcolor orange
  ]

  ask patches with [ pxcor >= 3 and pxcor < 6 and pycor >= 12 and pycor < 15 ] [
    set pcolor pink
  ]

  ask patches with [ pxcor >= 15 and pxcor < 18 and pycor >= 12 and pycor < 15 ] [
    set pcolor pink
  ]

  ask patches with [ pxcor >= 12 and pxcor < 15 and pycor >= 9 and pycor < 12 ] [
    set pcolor pink
  ]

  ask patches with [ pxcor >= 18 and pxcor < 21 and pycor >= 15 and pycor < 18 ] [
    set pcolor green
  ]

  ask patches with [ pxcor >= 6 and pxcor < 9 and pycor >= 15 and pycor < 18 ] [
    set pcolor green
  ]

  ask patches with [ pxcor >= 0 and pxcor < 3 and pycor >= 18 and pycor < 21 ] [
    set pcolor green
  ]

end

; Procedure to set up supermarket agents
to setup-supermarkets
  ; Create a supermarket agent at each of the x,y cordinates in the list
  let coordinates [ [10 1] [7 7] [12 14] ]
  foreach coordinates [ ?1 ->
    create-supermarkets 1 [
      setxy item 0 ?1 item 1 ?1
      set shape "square" ; Set the shape of the supermarket agent to square
      set size 1.5 ; Set the size of the supermarket agent to 1.5
      set color red ; Set the colour of the supermarket agent to red
      set customers (list) ; Set up the supermarkets 'customers' variables as a list
      set spend-at-store 0 ; Set initial spend value to zero
    ]
  ]

end

; Procedure to set up convenience store agents
to setup-convenience-stores
  ; Create a supermarket agent at each of the x,y cordinates in the list
  let coordinates [ [9 0] [9 2] [11 0] [11 2] [7 4] [6 6] [12 10] [14 12] [16 13] ]
  foreach coordinates [ ?1 ->
    create-convenience-stores 1 [
      setxy item 0 ?1 item 1 ?1
      set shape "square" ; Set the shape of the convenience store agent to square
      set color red ; Set the colour of the convenience store agent to red
      set customers (list) ; Set up the covenience store 'customers' variables as a list
      set spend-at-store 0 ; Set initial spend value to zero
    ]
  ]

end

; Procedures to set up consumer agents
to setup-consumer-as
  create-consumer-as number-of-consumer-as [
    move-to one-of patches with [ pcolor = green ] ; Set starting position
    set home-location patch-here ; Set the consumers 'home location' variable
    set shape "person" ; Set the shape of the consumer to a person
    set color black ; Set the color of the consumer to black
    set destination one-of supermarkets ; Set the consumers 'destination' variable
  ]
end

to setup-consumer-bs
    create-consumer-bs number-of-consumer-bs [
    move-to one-of patches with [ pcolor = orange ]
    set home-location patch-here
    set shape "person"
    set color black
    set destination min-one-of supermarkets [ distance myself ]
  ]
end

to setup-consumer-cs
    create-consumer-cs number-of-consumer-cs [
    move-to one-of patches with [ pcolor = blue ]
    set home-location patch-here
    set shape "person"
    set color black
    set destination min-one-of convenience-stores [ distance myself ]
  ]
end

to setup-consumer-ds
    create-consumer-ds number-of-consumer-ds [
    move-to one-of patches with [ pcolor = yellow ]
    set home-location patch-here
    set shape "person"
    set color black
    set destination one-of turtles with [ breed = supermarkets or breed = convenience-stores and pcolor = yellow ]
  ]
end

to setup-consumer-es
    create-consumer-es number-of-consumer-es [
    move-to one-of patches with [ pcolor = pink ]
    set home-location patch-here
    set shape "person"
    set color black
    set destination one-of turtles with [ breed = supermarkets or breed = convenience-stores ]
  ]
end

to setup-consumer-fs
    create-consumer-fs number-of-consumer-fs [
    move-to one-of patches with [ pcolor = pink ]
    set home-location patch-here
    set shape "person"
    set color black
    set destination one-of supermarkets
  ]
end

to setup-consumer-gs
    create-consumer-gs number-of-consumer-gs [
    move-to one-of patches with [ pcolor = blue ]
    set home-location patch-here
    set shape "person"
    set color black
    set destination one-of turtles with [ breed = supermarkets or breed = convenience-stores ]
    ]
end
@#$#@#$#@
GRAPHICS-WINDOW
280
12
663
396
-1
-1
17.9
1
10
1
1
1
0
0
0
1
0
20
0
20
0
0
1
ticks
30.0

BUTTON
17
18
115
51
setup model
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

SLIDER
18
288
200
321
number-of-consumer-as
number-of-consumer-as
0
10
1.0
1
1
NIL
HORIZONTAL

SLIDER
18
235
238
268
number-of-convenience-stores
number-of-convenience-stores
0
10
9.0
1
1
NIL
HORIZONTAL

SLIDER
18
181
205
214
number-of-supermarkets
number-of-supermarkets
0
10
3.0
1
1
NIL
HORIZONTAL

SWITCH
18
126
140
159
online-shopping
online-shopping
1
1
-1000

SLIDER
19
341
201
374
number-of-consumer-bs
number-of-consumer-bs
0
10
1.0
1
1
NIL
HORIZONTAL

SLIDER
19
394
200
427
number-of-consumer-cs
number-of-consumer-cs
0
10
1.0
1
1
NIL
HORIZONTAL

SLIDER
19
447
201
480
number-of-consumer-ds
number-of-consumer-ds
0
10
1.0
1
1
NIL
HORIZONTAL

SLIDER
20
500
202
533
number-of-consumer-es
number-of-consumer-es
0
10
1.0
1
1
NIL
HORIZONTAL

SLIDER
20
553
200
586
number-of-consumer-fs
number-of-consumer-fs
0
10
1.0
1
1
NIL
HORIZONTAL

SLIDER
20
604
202
637
number-of-consumer-gs
number-of-consumer-gs
0
10
1.0
1
1
NIL
HORIZONTAL

MONITOR
21
657
112
702
consumer a visits
mean [visits] of consumer-as
2
1
11

MONITOR
127
657
219
702
consumer b visits
mean [visits] of consumer-bs
17
1
11

MONITOR
235
657
325
702
consumer c visits
mean [visits] of consumer-cs
2
1
11

MONITOR
341
657
431
702
consumer d visits
mean [visits] of consumer-ds
2
1
11

MONITOR
445
657
535
702
consumer e visits
mean [visits] of consumer-es
2
1
11

MONITOR
550
656
639
701
consumer f visits
mean [visits] of consumer-fs
2
1
11

MONITOR
653
656
744
701
consumer g visits
mean [visits] of consumer-gs
2
1
11

BUTTON
134
72
253
105
run 21 iterations
let counter 0\nwhile [ counter < 21 ] [\n go\n set counter ( counter + 1)\n]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
21
721
126
766
consumer a distance
(sum [distance-travelled] of consumer-as) / (sum [visits] of consumer-as)
2
1
11

MONITOR
142
721
247
766
consumer b distance
(sum [distance-travelled] of consumer-bs) / (sum [visits] of consumer-bs)
2
1
11

MONITOR
264
721
369
766
consumer c distance
(sum [distance-travelled] of consumer-cs) / (sum [visits] of consumer-cs)
2
1
11

MONITOR
385
720
491
765
consumer d distance
(sum [distance-travelled] of consumer-ds) / (sum [visits] of consumer-ds)
2
1
11

MONITOR
508
720
615
765
consumer e distance
(sum [distance-travelled] of consumer-es) / (sum [visits] of consumer-es)
2
1
11

MONITOR
633
720
738
765
consumer f distance
(sum [distance-travelled] of consumer-fs) / (sum [visits] of consumer-fs)
2
1
11

MONITOR
755
721
860
766
consumer g distance
(sum [distance-travelled] of consumer-gs) / (sum [visits] of consumer-gs)
2
1
11

BUTTON
18
72
104
105
run model
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

@#$#@#$#@
## WHAT IS IT?

This model simulates the store choice behaviour of different consumer agent types in a city environment.

## HOW IT WORKS

Each time step in the model represents a day part over a weekly time period. The shopping behaviour of the consumer agents depends on the time of day and day of week. Store choice depends on their location and their likelihood to shop at supermarkets or convenience stores.

## HOW TO USE IT

The number of consumer agents can be adjusted using the sliders on the graphical user interface


## CREDITS AND REFERENCES

This work is licensed under a Creative Commons Attribution-ShareAlike 4.0 International License.
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
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

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
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

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
<experiments>
  <experiment name="convenience" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="21"/>
    <metric>sum [visits] of consumer-as</metric>
    <metric>sum [visits] of consumer-bs</metric>
    <metric>sum [visits] of consumer-cs</metric>
    <metric>sum [visits] of consumer-ds</metric>
    <metric>sum [visits] of consumer-es</metric>
    <metric>sum [visits] of consumer-fs</metric>
    <metric>sum [visits] of consumer-gs</metric>
    <metric>sum [distance-travelled] of consumer-as</metric>
    <metric>sum [distance-travelled] of consumer-bs</metric>
    <metric>sum [distance-travelled] of consumer-cs</metric>
    <metric>sum [distance-travelled] of consumer-ds</metric>
    <metric>sum [distance-travelled] of consumer-es</metric>
    <metric>sum [distance-travelled] of consumer-fs</metric>
    <metric>sum [distance-travelled] of consumer-gs</metric>
    <enumeratedValueSet variable="number-of-consumer-gs">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-supermarkets">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-consumer-fs">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-convenience-stores">
      <value value="3"/>
      <value value="4"/>
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="draw-paths">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-consumer-cs">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-consumer-bs">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="online-shopping">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-consumer-ds">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-consumer-es">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-consumer-as">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="21"/>
    <metric>sum [visits] of consumer-as</metric>
    <metric>sum [visits] of consumer-bs</metric>
    <metric>sum [visits] of consumer-cs</metric>
    <metric>sum [visits] of consumer-ds</metric>
    <metric>sum [visits] of consumer-es</metric>
    <metric>sum [visits] of consumer-fs</metric>
    <metric>sum [visits] of consumer-gs</metric>
    <metric>sum [distance-travelled] of consumer-as</metric>
    <metric>sum [distance-travelled] of consumer-bs</metric>
    <metric>sum [distance-travelled] of consumer-cs</metric>
    <metric>sum [distance-travelled] of consumer-ds</metric>
    <metric>sum [distance-travelled] of consumer-es</metric>
    <metric>sum [distance-travelled] of consumer-fs</metric>
    <metric>sum [distance-travelled] of consumer-gs</metric>
    <enumeratedValueSet variable="number-of-consumer-gs">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-supermarkets">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-consumer-fs">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-convenience-stores">
      <value value="9"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="draw-paths">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-consumer-cs">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-consumer-bs">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="online-shopping">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-consumer-ds">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-consumer-es">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-consumer-as">
      <value value="1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="consumers" repetitions="100" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="21"/>
    <metric>sum [visits] of consumer-as</metric>
    <metric>sum [visits] of consumer-bs</metric>
    <metric>sum [visits] of consumer-cs</metric>
    <metric>sum [visits] of consumer-ds</metric>
    <metric>sum [visits] of consumer-es</metric>
    <metric>sum [visits] of consumer-fs</metric>
    <metric>sum [visits] of consumer-gs</metric>
    <metric>sum [distance-travelled] of consumer-as</metric>
    <metric>sum [distance-travelled] of consumer-bs</metric>
    <metric>sum [distance-travelled] of consumer-cs</metric>
    <metric>sum [distance-travelled] of consumer-ds</metric>
    <metric>sum [distance-travelled] of consumer-es</metric>
    <metric>sum [distance-travelled] of consumer-fs</metric>
    <metric>sum [distance-travelled] of consumer-gs</metric>
    <enumeratedValueSet variable="number-of-consumer-gs">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-supermarkets">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-consumer-fs">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-convenience-stores">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="draw-paths">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-consumer-cs">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-consumer-bs">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="online-shopping">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-consumer-ds">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-consumer-es">
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-consumer-as">
      <value value="3"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
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

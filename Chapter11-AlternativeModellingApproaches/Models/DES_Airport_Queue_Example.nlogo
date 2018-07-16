;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;Model retrieved from: http://beyondbitsandatomsblog.stanford.edu/spring2012/assignments/assignment-4-creating-netlogo-models/airport-security-line-simulation-netlogo-abm/
;;
;;Full Referecne:
;;
;;Bybee, G. and Eng, L.A. (2012), Airport Security Line Simulation,
;;Available at http://beyondbitsandatomsblog.stanford.edu/spring2012/assignments/assignment-4-creating-netlogo-models/airport-security-line-simulation-netlogo-abm/
;;[Accessed on April, 10th, 2017].
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; SET UP, VARIABLES, ETC ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Turtles-own

[
  in-line?          ;; if true, waiting to be processed
  finished?         ;; if true, they are finished
  queue-position    ;; what is his position in queue?
  wait-time         ;; how long has he been waiting?
]


globals
[
  ;; for graph
  total_finished
  avg_wait
  max_wait
  total_wait
  queue_size
  processed
  arrivals
  POLICE_X
  POLICE_Y
  POLICE_SIZE
  AIRPLANE_X
  AIRPLANE_Y
  AIRPLANE_SIZE
  MAX_QUEUE_SIZE
  MAX_FINISHED
  queue_y
  test

]


to setup
  clear-all
  ;;update-global-variables
  reset-ticks
  set total_finished 0
  set total_wait 0
  set queue_size 0
  set POLICE_X 15
  set POLICE_Y -1
  set POLICE_SIZE 2
  set AIRPLANE_SIZE 2
  set AIRPLANE_X POLICE_X + 4
  set AIRPLANE_Y POLICE_Y + 2
  set MAX_QUEUE_SIZE ( POLICE_X - min-pxcor)
  set MAX_FINISHED (max-pxcor - AIRPLANE_X - 1)
  set queue_y 0

  ;; CREATE THE COP
  create-turtles 1 [
    set in-line? FALSE
    set finished? FALSE
    set queue-position -10
    set wait-time 0
    setxy (POLICE_X + 1) POLICE_Y
    set size POLICE_SIZE
    set shape "person police"
  ]

  ;; CREATE THE AIRPLANE
  create-turtles 1 [
    set in-line? FALSE
    set finished? FALSE
    set queue-position -10
    set wait-time 0
    setxy AIRPLANE_X AIRPLANE_Y
    set size AIRPLANE_SIZE
    set shape "airplane"
  ]


end


;;;;;;;;;;;;;;;;;;;;;;;
;; RUN() or MAIN  () ;;
;;;;;;;;;;;;;;;;;;;;;;;

to go
  arrive
  process
  update_variables
  tick
end


;;;;;;;;;;;;;;;;;;;;;;;;;;
;; HIGH LEVEL FUNCTIONS ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;



to process

  ;set processed 1 ;checking that the code works

  ; instread of just processing one or two agents it takes into consideration some global variables (i.e. queues)
  set processed (min (list (queue_size) (max( list (0) (random-normal process_mean process_stdev) ))))

  repeat processed [
    process_turtle
    decrease_turtle_position
    set queue_size (queue_size - 1)
  ]

end


to arrive

  set arrivals (random-poisson arrival_mean)

  repeat arrivals [
    create_turtle
    set queue_size (queue_size + 1)
  ]
end



to update_variables

  ;; update wait time for all turtles
  increase_wait_time

  ;; update average wait time
  ifelse (total_finished != 0) [
    set avg_wait (total_wait / total_finished)
  ][
  set avg_wait 0
  ]

end



;;;;;;;;;;;;;;;;;;;;;;
;; HELPER FUNCTIONS ;;
;;;;;;;;;;;;;;;;;;;;;;


to create_turtle

  create-turtles 1  [
    set in-line? TRUE
    set finished? FALSE
    set queue-position (queue_size + 1)
    set wait-time 0
    ; set color 65
  set shape "person"
    ifelse (queue_size > MAX_QUEUE_SIZE) [hide-turtle] [

      setxy  (POLICE_X - queue_size) (POLICE_Y + 1)
    ]
  ]

end


to process_turtle


  ask turtles with [queue-position = 1] [                     ;; only for in-line turtles
    set queue-position (queue-position - 1)        ;; decreasing queue-position
    set finished? TRUE
    set in-line? FALSE
    set total_wait (total_wait + wait-time)
    if (wait-time > max_wait) [set max_wait wait-time]
    setxy  (AIRPLANE_X + (total_finished mod MAX_FINISHED)) (AIRPLANE_Y - 1)   ;;min (list (total_finished) (MAX_FINISHED))
  ]

  set total_finished (total_finished + 1)

end



to decrease_turtle_position


  ask turtles with [queue-position = (MAX_QUEUE_SIZE + 1) ] [
    show-turtle
    setxy  (POLICE_X - MAX_QUEUE_SIZE) (POLICE_Y + 1)
  ]
    foreach sort-on [queue-position] turtles with [in-line?] [ ?1 ->           ;; sorting turtles by ascending queue size and asking each of them
    ask  ?1 [                     ;; only for in-line turtles
      set queue-position (queue-position - 1)
      setxy (xcor + 1) ycor
    ]
  ]



end

to increase_wait_time

  ask turtles with [in-line?][
    set wait-time (wait-time + 1)
  ]

end
@#$#@#$#@
GRAPHICS-WINDOW
13
483
839
612
-1
-1
13.41
1
10
1
1
1
0
1
1
1
-30
30
-4
4
1
1
1
Ticks
30.0

BUTTON
25
53
194
87
Start Simulation
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

BUTTON
24
95
194
129
Initialize Model
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
20
139
192
172
arrival_mean
arrival_mean
0
20
4.0
1
1
NIL
HORIZONTAL

SLIDER
20
179
192
212
Process_Mean
Process_Mean
0
20
4.0
1
1
NIL
HORIZONTAL

MONITOR
229
188
346
233
Number in Queue
queue_size
17
1
11

PLOT
17
259
362
475
Queue Size
Time
Count
0.0
5.0
0.0
5.0
true
true
"" ""
PENS
"Total Processed" 1.0 0 -2674135 true "" "plot total_finished"
"Queue Size" 1.0 0 -955883 true "" "plot queue_size"

MONITOR
229
100
346
145
Processed
total_finished
17
1
11

MONITOR
229
144
346
189
Average Wait
avg_wait
2
1
11

MONITOR
229
56
346
101
Longest Wait
max_wait
17
1
11

PLOT
373
260
841
475
Wait Times
Ticks
Wait Time
0.0
2.0
0.0
2.0
true
true
"" ""
PENS
"Avg Wait" 1.0 0 -2674135 true "" "plot avg_wait"
"Max Wait" 1.0 0 -7500403 true "" "plot max_wait"

PLOT
371
57
841
251
Arrival and Processing
NIL
NIL
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Arrivals" 1.0 1 -10899396 true "" "plot arrivals"
"Processed" 1.0 1 -13345367 true "" "plot processed"

SLIDER
20
221
193
254
Process_StDev
Process_StDev
0
20
2.0
1
1
NIL
HORIZONTAL

TEXTBOX
679
583
804
612
Gate Area\n(Finished Check)
11
9.9
1

TEXTBOX
561
585
646
603
Security Line
11
9.9
1

TEXTBOX
303
9
628
38
Airport Security Line Simulator
18
103.0
1

@#$#@#$#@
## WHAT IS IT?

A simple queueing model based on an airport security line.  The model tracks the wait time of the passengers as they wait to go through the security check point.

## AUTHORS

- Greg Bybee
- Laura Anne Eng
- Aneeqa Ishaq


## HOW IT WORKS

There are two states of the world - in line (queue) or finished (at the airplane).  Individuals arrive in the security line following a poisson arrival process. The mean arrival time is set using the slider on the GUI.

Individuals are processed by the security guard who is able to check X people per tick, where x is normally distributed, with mean and standard deviation set by the user (sliders on GUI).

As passengers are checked by the security guard, their status changes to finished and they walk to the gate (represented by the plane).  After each individual is processed, all others currently in the line move up one space.  Then the process repeats.

The charts track three things:
1. The number of individuals who arrive and are processed (checked) each period (tick).
2. The current size of the queue, and the number of individuals who have been checked.
3. The average wait time (over time) and the maximum individual wait at each tick.

## HOW TO USE IT

1. Set the three arrival and process variables:
-- Arrival mean is the mean number of passengers who arrive in line each tick (poisson distributed so standard deviation equals the mean, and hence the coefficient of variation, CV, is one)
-- Process_Mean is the mean number of passengers the security guard can check each period (normally distributed)
-- Process_StDev is the standard deviation of the number of passengers the guard can check each period.

2. Click "Initialize Model" to create the environment and initialize all variables.

3. Click "Start Simulation" to begin the simulation.  The simulation will run indefinitely.

4. Enjoy!

5. Press "Start Simulation" again to stop the simulation.


## THINGS TO NOTICE

Play with different processing and arrival means.  Notice that even if the mean process rate equals the mean arrival rate, the queue will grow infinitely long.  (As the mean arrival rate approaches the mean processing rate, the queue will grow towards infinity.)

## EXTENDING THE MODEL

We don't recommend it.  It's a lot of work.  Trust us.

But f you really insist, here are a few ideas:
-- Add a chooser to enable the user to select the distributions for processing or arrival rate
-- Enable the line to snake around the screen, or enable the gate area to grow indefinitely.
-- Add the capability to increase the number of checkers, or to increase the number of lines.

## CREDITS AND REFERENCES

Special thanks to OIT 262 for teaching us the basics of queueing theory.
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

person police
false
0
Polygon -1 true false 124 91 150 165 178 91
Polygon -13345367 true false 134 91 149 106 134 181 149 196 164 181 149 106 164 91
Polygon -13345367 true false 180 195 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285
Polygon -13345367 true false 120 90 105 90 60 195 90 210 116 158 120 195 180 195 184 158 210 210 240 195 195 90 180 90 165 105 150 165 135 105 120 90
Rectangle -7500403 true true 123 76 176 92
Circle -7500403 true true 110 5 80
Polygon -13345367 true false 150 26 110 41 97 29 137 -1 158 6 185 0 201 6 196 23 204 34 180 33
Line -13345367 false 121 90 194 90
Line -16777216 false 148 143 150 196
Rectangle -16777216 true false 116 186 182 198
Rectangle -16777216 true false 109 183 124 227
Rectangle -16777216 true false 176 183 195 205
Circle -1 true false 152 143 9
Circle -1 true false 152 166 9
Polygon -1184463 true false 172 112 191 112 185 133 179 133
Polygon -1184463 true false 175 6 194 6 189 21 180 21
Line -1184463 false 149 24 197 24
Rectangle -16777216 true false 101 177 122 187
Rectangle -16777216 true false 179 164 183 186

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

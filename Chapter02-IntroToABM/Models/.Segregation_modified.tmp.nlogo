globals
[
  percent-similar              ;; avg. percent of a turtle's neighbors that are the same color
  percent-unhappy              ;; percent of the turtles that are unhappy
]

turtles-own
[
  nearby                       ;; agentset of patches that are within a turtle's specified Moore neighborhood

  happy?                       ;; indicates if at least %-similar-wanted of neighbors are the same color
  similar-nearby               ;; how many neighboring patches have another turtle with the same color
  other-nearby                 ;; how many neighboring patches have another turtle with another color
  total-nearby                 ;; sum of previous two variables
]

;/**
;* Sets up the model environment and instantiates the agent population.
;**/
to setup
  clear-all                                ;; reset the world

  ;; create turtles on random patches.
  ask patches
  [
    if random 100 < density                ;; set the occupancy density
    [
      sprout 1
      [
        set color one-of [red green]       ;; assumes uniformly random chance for red or green assignment
      ]
    ]
  ]

  update-variables                         ;; update turtle's perceptions of their neighbors and other global metrics

  reset-ticks                              ;; reset the clock
end

;/**
;* Main.
;*/
to go

  if all? turtles [ happy? ] [ stop ]      ;; loops the main block until the entire population is happy

  move-unhappy-turtles                     ;; runs method to move all unhappy turtles to a new location

  update-variables                         ;; update turtle's perceptions of their neighbors and other global metrics

  tick                                     ;; advance simulation clock one unit
end

;/**
;* Method to move agents and have them try a new location if they are unhappy.
;*/
to move-unhappy-turtles
  ask turtles with [ not happy? ]          ;; only ask unhappy turtles to attempt a move
  [
    ifelse (move-logic = "random")
    [
      find-new-spot                        ;; call method for using random move logic
    ]
    [
      find-new-spot-corrected              ;; call method for moving to nearest suitable location (as per Schelling's paper)
    ]
  ]
end

;/**
;* Method for random movement of agents to try a new location if they are unhappy; move until an unoccupied location is found.
;*/
to find-new-spot
  rt random-float 360                             ;; face a random direction
  fd random-float 10                              ;; move forward more than zero but less than 10 patches

  if any? other turtles-here [ find-new-spot ]    ;; recursive loop until the agent finds an unoccupied patch
  move-to patch-here                              ;; move to center of patch
end

;/**
;* Method for moving to the nearest suitable location directly if they are unhappy; as per the 1971 Schelling paper.
;*/
to find-new-spot-corrected

  ;; move directly to the nearest patch to the agent's current location, that is vacant
  move-to min-one-of patches with [ not any? turtles-here ] [ distance myself ]

end

;/**
;* Returns an agent set of patches in a Moore neighborhood from the Moore and Von Neumann example by Uri Wilensky. To
;* be used by the agent for determining how many nearby residential locations should be considered when evaluating
;* their own level of happiness.
;*/
to-report moore-offsets [n]
  let result [list pxcor pycor] of patches with [abs pxcor <= n and abs pycor <= n]
  report result
end

;/**
;* Update the agent's happiness values and other global metrics for tracking system performance.
;*/
to update-variables
  update-turtles
  update-globals
end

;/**
;* Updates the turtle parameter values and agent metrics for assessing their happiness level with their neighborhood.
;*/
to update-turtles
  ask turtles [

    ifelse (happiness-logic = "surrounding-eight")
    [
      ;; for considering the immediate neighborhood

      ;; count number of other similar agents that are within the 8 patches surrounding the current patch
      set similar-nearby count (turtles-on neighbors) with [ color = [ color ] of myself ]

      ;; count number of other agents that are not similar and within the 8 patches surrounding the current patch
      set other-nearby count (turtles-on neighbors) with [ color != [ color ] of myself ]
    ]
    [
      ;; for considering a 'larger' neighborhood

      set nearby moore-offsets Moore-neighborhood-radius     ;; specifies extent of the agent's neighborhood

      ;; count number of other similar agents that are within the Moore neighborhood
      set similar-nearby count (turtles-on patches at-points nearby) with [ color = [ color ] of myself ]

      ;; count number of other agents that are not similar and within the Moore neighborhood
      set other-nearby count (turtles-on patches at-points nearby) with [ color != [ color ] of myself ]
    ]

    ;; in next two lines, we use "neighbors" to test the eight patches
    ;; surrounding the current patch

    set total-nearby similar-nearby + other-nearby
    set happy? similar-nearby >= (%-similar-wanted * total-nearby / 100)

    ;; use the 'old' version for visualizing the system.
    if visualization = "old"
    [
      set shape "default"
    ]

    ;; use an updated version for visualizing the system, where unhappy agents are marked with an 'x'.
    if visualization = "square-x"
    [
      ifelse happy?
      [
        set shape "square"
      ]
      [
        set shape "square-x"
      ]
    ]
  ]
end

;/**
;* Updates the global metrics for tracking the state of the system.
;/*
to update-globals
  ;; local variable for how many nearby similar turtles
  let similar-neighbors sum [ similar-nearby ] of turtles

  ;; local variable for how many total neighbors
  let total-neighbors sum [ total-nearby ] of turtles

  ;; percent of similar neighbors
  set percent-similar (similar-neighbors / total-neighbors) * 100

  ;; percent of unhappy agents
  set percent-unhappy (count turtles with [ not happy? ]) / (count turtles) * 100
end


; Copyright 1997 Uri Wilensky.
; Modified 2015 by Brant Horio.
; See Info tab for full copyright and license.
@#$#@#$#@
GRAPHICS-WINDOW
288
10
704
427
-1
-1
8.0
1
10
1
1
1
0
0
0
1
-25
25
-25
25
1
1
1
ticks
30.0

MONITOR
810
387
885
432
% unhappy
percent-unhappy
1
1
11

MONITOR
807
155
882
200
% similar
percent-similar
1
1
11

PLOT
720
10
969
153
Percent Similar
time
%
0.0
5.0
0.0
100.0
true
false
"" ""
PENS
"percent" 1.0 0 -2674135 true "" "plot percent-similar"

SLIDER
8
75
257
108
%-similar-wanted
%-similar-wanted
0
100
60.0
1
1
%
HORIZONTAL

BUTTON
11
296
91
330
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
193
297
273
331
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

BUTTON
102
296
182
330
go once
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

CHOOSER
11
337
177
382
visualization
visualization
"old" "square-x"
1

SLIDER
8
36
256
69
density
density
0
99
70.0
1
1
NIL
HORIZONTAL

PLOT
720
233
969
383
Number-unhappy
NIL
NIL
0.0
10.0
0.0
100.0
true
false
"" ""
PENS
"default" 1.0 0 -14439633 true "" "plot count turtles with [not happy?]"

MONITOR
729
386
804
431
# unhappy
count turtles with [not happy?]
1
1
11

MONITOR
726
155
801
200
# agents
count turtles
1
1
11

TEXTBOX
12
12
272
32
Schelling's Segregation Model
16
0.0
1

CHOOSER
10
226
176
271
move-logic
move-logic
"random" "nearest-vacancy"
0

SLIDER
10
174
258
207
Moore-neighborhood-radius
Moore-neighborhood-radius
0
5
2.0
1
1
NIL
HORIZONTAL

CHOOSER
10
126
174
171
happiness-logic
happiness-logic
"surrounding-eight" "Moore-neighborhood"
0

@#$#@#$#@
## WHAT IS IT?

This model is based off of the model proposed by Thomas C. Schelling in his paper, "Dynamic Models of Segregation," published in 1971 in the Journal of Mathematical Sociology. It implements a virtual world in which two types of agents seek to find a suitable residential location to live. Suitability of a particular location is based on  some acceptability threshold being met with respect to the composition ratio of an agent's surrounding neighbors being the same color as them. The model represents this through instantiation of red and green agents, where each follows some rule for deciding to move and find a new location if the composition ratio of its neighbors do not meet their threshold for desired similarity.

This is an abstract study of how individual choice and even small degrees of preference for living with similar neighbors can result in collective patterns of segregation. Given two diverse agent types that may not mind living next to each other (and might even prefer integration), Schelling posits that total segregation is inevitable if each group does not want to be a minority in the neighborhood; "Except for a mixture at exactly 50:50, no mixture will then be self-sustaining because there is none without a minority, and if the minority evacuates, complete segregation occurs" (Schelling 1971). This model provides one way to explore these dynamics and Schelling's theories.

## HOW TO USE IT

Click the SETUP button to set up the agents. There are approximately equal numbers of red and green agents. The agents are set up so no patch has more than one agent.  Click GO to start the simulation. If agents don't have enough same-color neighbors, they move to a nearby patch. (The topology is wrapping, so that patches on the bottom edge are neighbors with patches on the top and similar for left and right).

The DENSITY slider controls the occupancy density of the neighborhood (and thus the total number of agents). (It takes effect the next time you click SETUP.)  The %-SIMILAR-WANTED slider controls the percentage of same-color agents that each agent wants among its neighbors. For example, if the slider is set at 30, each green agent wants at least 30% of its neighbors to be green agents.

The % SIMILAR monitor shows the average percentage of same-color neighbors for each agent. It starts at about 50%, since each agent starts (on average) with an equal number of red and green agents as neighbors. The NUM-UNHAPPY monitor shows the number of unhappy agents, and the % UNHAPPY monitor shows the percent of agents that have fewer same-color neighbors than they want (and thus want to move). The % SIMILAR and the NUM-UNHAPPY monitors are also plotted.

The VISUALIZATION chooser gives two options for visualizing the agents. The OLD option uses the visualization that was used by the segregation model in the past. The SQUARE-X option visualizes the agents as squares. The agents have X's in them if they are unhappy. 

## THINGS TO NOTICE

When you execute SETUP, the red and green agents are randomly distributed throughout the neighborhood. But many agents are "unhappy" since they don't have enough same-color neighbors. The unhappy agents move to new locations in the vicinity. But in the new locations, they might tip the balance of the local population, prompting other agents to leave. If a few red agents move into an area, the local green agents might leave. But when the green agents move to a new area, they might prompt red agents to leave that area.

Over time, the number of unhappy agents decreases. But the neighborhood becomes more segregated, with clusters of red agents and clusters of green agents.

In the case where each agent wants at least 30% same-color neighbors, the agents end up with (on average) 70% same-color neighbors. So relatively small individual preferences can lead to significant overall segregation.

This model is in most respects a direct implementation of the Schelling paper however the move logic for the agents is different. The NetLogo model implements a move logic that turns the turtle in a random heading and moves forward for a random distance up to 10 patches. This continues until the agent finds a suitable new location that is unoccupied. The Schelling paper implements the move logic differently, finding and moving directly to the nearest suitable patch, measured by the distance from the agent's current location; there is no random search.

Another inconsistency with the model from the Schelling paper, is that the NetLogo implementation has world wrapping activated. This makes the agents interact on a toroidal world where agents on an edge of the graphically represented world on the  Interface tab, may consider agents on opposite end of the world as its direct neighbor. The Schelling paper model had their agents on the edge of the world be limited to the bounds of the world and not consider world-wrapping (e.g. agents in the corner could only consider up to 3 other agents as their neighbor). 

## THINGS TO TRY

Try different values for %-SIMILAR-WANTED. How does the overall degree of segregation change?

If each agent wants at least 40% same-color neighbors, what percentage (on average) do they end up with?

Try different values of DENSITY. How does the initial occupancy density affect the percentage of unhappy agents? How does it affect the time it takes for the model to finish? 

Can you set sliders so that the model never finishes running, and agents keep looking for new locations?

## EXTENDING THE MODEL

The base model has been extended to better align with the Schelling paper by using these drop-down options on the interface to further explore the dynamics of this system.

- Use the HAPPINESS-LOGIC drop-down to choose how the agents determine their happiness for their current location. If HAPPINESS-LOGIC is selected to be 'surrounding-eight', the agent only evaluates the 8 neighboring patches to determine their happiness level (the original NetLogo implementation). If HAPPINESS-LOGIC is selected to be 'Moore-neighborhood' (closer to the Schelling paper implementation), the agent evaluates a larger neighborhood space that is of a size specified by the MOORE-NEIGHBORHOOD-RADIUS slider.

- Use the slider for MOORE-NEIGHBORHOOD-RADIUS to change how far agents look around them if HAPPINESS-LOGIC is set to 'Moore-neighborhood'. A value of 1 is the baseline and is no different than the 'surrounding-eight' logic; an agent only considers the 8 neighboring patches around them. A value of 2 has an agent consider what Schelling suggested as a 'larger' neighborhood in his paper; the neighborhood is extended to a 5x5 patch square allowing an agent to consider their surrounding 24 neighbors. Values greater than 2 are allowed.

- Use the MOVE-LOGIC drop-down menu to choose between "random" or "nearest vacancy." Selecting "random" will have the agents move locally until they find a suitable location. Selecting "nearest vacancy" is more representative of Schelling's proposed model where the agents locate the nearest suitable vacancy and moves there directly.

Using Schelling's nearest vacancy move logic, the resulting emergent state typically has a lower percent-similar outcome than with the random move logic, however the overall patterns of segregation still emerge and are comparable between models over a wide range of starting conditions.


## NETLOGO FEATURES

`sprout` is used to create agents while ensuring no patch has more than one agent on it.

When an agent moves, `move-to` is used to move the agent to the center of the patch it eventually finds.

Note two different methods that can be used for find-new-spot, one of them (the one we use) is recursive.

## CREDITS AND REFERENCES

Schelling, T. (1978). Micromotives and Macrobehavior. New York: Norton.
 
See also a recent Atlantic article:   Rauch, J. (2002). Seeing Around Corners; The Atlantic Monthly; April 2002;Volume 289, No. 4; 35-48. http://www.theatlantic.com/issues/2002/04/rauch.htm


## HOW TO CITE

If you mention this model in a publication, we ask that you include these citations for the model itself and for the NetLogo software:

* Wilensky, U. (1997).  NetLogo Segregation model.  http://ccl.northwestern.edu/netlogo/models/Segregation.  Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

* Wilensky, U. (1999). NetLogo. http://ccl.northwestern.edu/netlogo/. Center for Connected Learning and Computer-Based Modeling, Northwestern University, Evanston, IL.

## COPYRIGHT AND LICENSE

Copyright 1997 Uri Wilensky.

![CC BY-NC-SA 3.0](http://ccl.northwestern.edu/images/creativecommons/byncsa.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

Commercial licenses are also available. To inquire about commercial licenses, please contact Uri Wilensky at uri@northwestern.edu.

This model was created as part of the project: CONNECTED MATHEMATICS: MAKING SENSE OF COMPLEX PHENOMENA THROUGH BUILDING OBJECT-BASED PARALLEL MODELS (OBPML).  The project gratefully acknowledges the support of the National Science Foundation (Applications of Advanced Technologies Program) -- grant numbers RED #9552950 and REC #9632612.

This model was converted to NetLogo as part of the projects: PARTICIPATORY SIMULATIONS: NETWORK-BASED DESIGN FOR SYSTEMS LEARNING IN CLASSROOMS and/or INTEGRATED SIMULATION AND MODELING ENVIRONMENT. The project gratefully acknowledges the support of the National Science Foundation (REPP & ROLE programs) -- grant numbers REC #9814682 and REC-0126227. Converted from StarLogoT to NetLogo, 2001.
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

face-happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face-sad
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

person2
false
0
Circle -7500403 true true 105 0 90
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 285 180 255 210 165 105
Polygon -7500403 true true 105 90 15 180 60 195 135 105

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

square
false
0
Rectangle -7500403 true true 30 30 270 270

square - happy
false
0
Rectangle -7500403 true true 30 30 270 270
Polygon -16777216 false false 75 195 105 240 180 240 210 195 75 195

square - unhappy
false
0
Rectangle -7500403 true true 30 30 270 270
Polygon -16777216 false false 60 225 105 180 195 180 240 225 75 225

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

square-small
false
0
Rectangle -7500403 true true 45 45 255 255

square-x
false
0
Rectangle -7500403 true true 30 30 270 270
Line -16777216 false 75 90 210 210
Line -16777216 false 210 90 75 210

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

triangle2
false
0
Polygon -7500403 true true 150 0 0 300 300 300

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

extensions[gis]

breed [vertices vertex]     ;; The nodes (i.e. what is needed for navigation)

breed [commuters commuter]  ;; People


globals [
  gmu-buildings
  gmu-roads
  gmu-walkway
  gmu-lakes
  gmu-rivers
  gmu-drive
  got_to_destination    ;;count the total number of arrivals
  ]

patches-own[
  centroid? ;; is it the centroid of a building?
  id        ;; if it is a centroid of a building, it has a building ID
  entrance  ;; nearest vertex on road. only for centroids.
]

commuters-own [
   mynode                ;; a vertex. where the agent begins its trip
   destination           ;; the destination that it wants to arrive at
   destination-entrance  ;; the entrance of the destination on the road
   mypath                ;; an agentset containing nodes to visit in the shortest path
   step-in-path          ;; the number of steps taken in the walk
   last-stop             ;; final destination
   ]

vertices-own [
  myneighbors  ;; agentset of neighboring vertices
  entrance?    ;; if it is an entrance to a building
  test         ;; used to delete in test

  ;; The follwoing variables are used and renewed in each path-selection
  dist      ;; distance from original point to here
  done      ;; 1 if has calculated the shortest path through this point, 0 otherwise
  lastnode  ;; last node to this point in shortest path
  ]


to setup
  ca
  reset-ticks

  ;;loading GIS files here

  set gmu-buildings gis:load-dataset "data/Campus_data/Mason_bld.shp"

  set gmu-walkway gis:load-dataset "data/Campus_data/Mason_walkway_line.shp"

  gis:set-world-envelope gis:envelope-of gmu-walkway

  if show_water? [

    set gmu-lakes gis:load-dataset "data/Campus_data/hydrop.shp"

    set gmu-rivers gis:load-dataset "data/Campus_data/hydrol.shp"

    gis:set-drawing-color 87  gis:fill gmu-lakes 1.0
    gis:set-drawing-color 87  gis:draw gmu-rivers 0.5

  ]

  if show_roads? [
    set gmu-drive gis:load-dataset "data/Campus_data/Mason_Rds.shp"
    gis:set-drawing-color 36  gis:fill gmu-drive 1.0
  ]

  gis:set-drawing-color 5  gis:fill gmu-buildings 1.0

  ;identify centroids and assign IDs to centroids
  foreach gis:feature-list-of gmu-buildings [
    ?1 ->
    let center-point gis:location-of gis:centroid-of ?1
    ask patch item 0 center-point item 1 center-point [
      set centroid? true
      set id gis:property-value ?1 "Id"
    ]
  ]


  ;; Create turtles representing the nodes. Create links to conect them.

  ;; Iterate over every road in the walkways data
  foreach gis:feature-list-of gmu-walkway[
    road-feature ->

    ;; for the road feature, iterate over the vertices that make it up
    foreach gis:vertex-lists-of road-feature [
      v ->

      let previous-node-pt nobody ;; The previous node; used to link nodes together

      ;; for each vertex, iterate over its individual points (nodes)
      foreach v [
        node ->
        ;; Find the location of the node and create a new 'vertex' agent there
        let location gis:location-of node
        if not empty? location [
          create-vertices 1 [
            set myneighbors n-of 0 turtles ;;empty
            set xcor item 0 location
            set ycor item 1 location
            set size 0.2
            set shape "circle"
            set color brown
            set hidden? true

            ;; create a link to previous node
            ifelse previous-node-pt = nobody [
              ; first vertex in feature, so do nothing
            ] [
              create-link-with previous-node-pt ; create link to previous node
            ]
            ;; remember *this* node so that the next one can link back to it
            set previous-node-pt self
          ]
        ]
      ]
    ]
  ]


  ;; delete duplicate vertices (there may be more than one vertice on the same patch due
  ;; to reducing size of the map). Therefore, this map is simplified from the original map.
  delete-duplicates

  ;;delete some nodes not connected to the network
  ask vertices [set myneighbors link-neighbors]
  delete-not-connected
  ask vertices [set myneighbors link-neighbors]


  ;; find nearest node to become entrance
  ask patches with [centroid? = true][
    set entrance min-one-of vertices in-radius 50 [distance myself]
    ask entrance [set entrance? true]
    if show_nodes? [ask vertices [set hidden? false]]
    if show_entrances? [ask entrance [set hidden? false set shape "star" set size 0.5]]
  ]

  ;; create the commuter agents
  create-commuters number-of-commuters [
    set color white
    set size 0.5
    set shape "person"
    set destination nobody
    set last-stop nobody
    set mynode one-of vertices move-to mynode
  ]

  set got_to_destination 0

  ask links [set thickness 0.1 set color orange]

end



to move
  ;; Stage 1. For all agents who do not have a destination yet, they need to
  ;; pick one and plan a route there
  ask commuters [
    if destination = nobody [
      ;; This commuted does not have a destination.
      ;; Find a patch that represents a building centroid and make this the destination
      set destination one-of patches with [centroid? = true]
      ;; Also find the closest entrance to the building
      set destination-entrance [entrance] of destination
      ;; (but make sure the destination isn't the same as the agent's current position)
      while [destination-entrance = mynode] [
        set destination one-of patches with [centroid? = true]
        set destination-entrance [entrance] of destination
      ]
      ;; Now calculate the shortest path to the destination
      path-select
    ]
  ]

  ;; Stage 2. Move commuters along the path selected
  ask commuters [
    ;; See if the agents is at their destination
    ifelse xcor != [xcor] of destination-entrance or ycor != [ycor] of destination-entrance [
      ;; They are not at the destination. Move along the path.
      move-to item step-in-path mypath
      set step-in-path step-in-path + 1
    ] [
      ;; They are at the destination. Get ready for the next model iteration.
      set last-stop destination
      set destination nobody
      set mynode destination-entrance
      set got_to_destination got_to_destination + 1
    ]
  ]
  tick
end


;;;;;;;;;;;;;;;;;helper functions;;;;;;;;;;;;;;;;;;;;;;;;;;


to delete-duplicates
  ask vertices [
    if count vertices-here > 1[
      ask other vertices-here [
        ask myself [
          create-links-with other [link-neighbors] of myself
        ]
        die
      ]
    ]
  ]

end

to delete-not-connected
  ask vertices [set test 0]
  ask one-of vertices [set test 1]
  repeat 500 [
    ask vertices with [test = 1] [
      ask myneighbors [
        set test 1
      ]
    ]
  ]
  ask vertices with [test = 0][die]
end





to path-select ;; Use the A-star algorithm to find the shortest path for a given turtle

  set mypath []      ;; A list to store the vertices
  set step-in-path 0 ;; Keep track of where we are in the list

  ask vertices [ ;; Reset the relevant vertex variables, ready for a new path
    set dist 99999  set done 0  set lastnode nobody   set color brown
  ]

  ask mynode [ set dist 0 ] ;; Set the distance to the current node to 0

  ;; The main loop! This loops over all of the vertices, marking them as
  ;; 'done' once they have been visitted.
  while [count vertices with [done = 0] > 0] [
    ;; Find vertices that have not been visited:
    ask vertices with [dist < 99999 and done = 0][
      ask myneighbors [
        ;; Renew the shorstest distance to this point if it is smaller
        let dist0 distance myself + [dist] of myself
        if dist > dist0 [ ;; This distance is shorter
          set dist dist0
          set done 0 ;; (so that it will renew the dist of its neighbors)
          set lastnode myself  ;; save the last node to reach here in the shortest path
        ]
      ]
      set done 1  ;; set done 1 when it has renewed it neighbors
    ]
  ]
  ;; At this point, all of the nodes have been visited, and the vertices that
  ;; are part of the shortest path have stored the previous node in the path in
  ;; their 'lastnode' variable. The last thing to do is to put the nodes in
  ;; shortest path into a list called 'mypath'
  let x destination-entrance
  while [x != mynode] [
    if show_path? [ ask x [set color yellow] ] ;;highlight the shortest path
    set mypath fput x mypath
    set x [lastnode] of x
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
267
10
817
561
-1
-1
25.81
1
10
1
1
1
0
0
0
1
-10
10
-10
10
0
0
1
ticks
30.0

BUTTON
37
10
100
43
NIL
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
32
94
204
127
number-of-commuters
number-of-commuters
1
100
51.0
1
1
NIL
HORIZONTAL

BUTTON
37
52
100
85
NIL
move
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
111
53
174
86
NIL
move
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
32
180
202
213
show_entrances?
show_entrances?
0
1
-1000

SWITCH
32
136
201
169
show_nodes?
show_nodes?
0
1
-1000

TEXTBOX
36
224
186
252
Entrances will be shown as a star shape.
11
0.0
1

MONITOR
28
509
203
554
Number of arrivals
got_to_destination
1
1
11

SWITCH
32
269
203
302
show_path?
show_path?
0
1
-1000

TEXTBOX
39
317
189
401
Only one path will be shown in yellow.\nFor verification, create only one commuter, turn this on, and move step by step to observe his movement.
11
0.0
1

SWITCH
33
411
206
444
show_water?
show_water?
1
1
-1000

SWITCH
34
456
205
489
show_roads?
show_roads?
0
1
-1000

@#$#@#$#@
## WHAT IS IT?

This is a simple path-finding model using an A-star algorithm to find the shortest path between two points. The models uses a map of George Mason University, including the buildings, walkways, drive-ways, and waterways. In this model, agents randomly select a building as destination, they then find and follow the shortest path to reach their goal.

The following is the original map this model uses which is from http://infoguides.gmu.edu/geospatial. In order for it to run efficiently, the network data has been simplified in the model for faster computation.

![Picture not found](file:data/Mason.jpg)

## HOW IT WORKS

In the beginning, each agent (commuter) randomly selects a destination and then identify the shortest path to the destination. The A-star algorithm is used to find the shortest path in terms of distance. The commuters move one node in a tick. When they reach the destination, they stay there for one tick, and then find the next destination and move again.

## HOW TO USE IT

1. Create a certain number of commuters using the slider.
2. Adjust the settings (switches) as needed.
2. Press mvoe to run the program.
3. For verification, turn "show_path?" on, and create only one commuter. Press move one at a time and observe his movement step by step.

## THINGS TO NOTICE

You may want to turn off some layers for a clearer display.

If occasionally you get no raods after setup, please simply setup again.

## THINGS TO TRY

Change the switches for different dispalys. Try different number of coimmuters. Try the verification.

## EXTENDING THE MODEL

What if the commuters move with a speed (some distance per tick) instead of one node per tick?

## NETLOGO FEATURES

For faster compuation, this model simplifies the original data by reducing the number of nodes. To do that, the walkway data is loaded to the 20 x 20 grid in Netlogo, which is small, and therefore, many nodes fall on the same patch. In each patch, we only want to keep one node, and duplicate nodes are removed, while their neighbors are connected to the one node left.

Also, links are created in this model to represent roads. This is so far the best way we can find to deal with road related problems in NetLogo. However, because the way we create the links is to link nodes one by one (see code for more details), so some roads are likely to be left behind (i.e. not connected to others). But again there we could find no better way. To some extent this is similar to many modeling issues, there might be many ways of braking an egg and we chose one that works for use. Therefore, we also used a loop in setup to delete nodes that are not connected to the whole network.

## RELATED MODELS

Reston commuters model by Melanie Swartz

## CREDITS AND REFERENCES

The way of creating the road network by using links is inpired by the Reston commuters model by Melanie Swartz.

Model created by Yang Zhou under the guidance of Andrew Crooks. 
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

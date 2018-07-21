extensions [gis]

breed [raindrops raindrop]
breed [waters water]

globals [
  elevation-dataset
  border          ;; keep the patches around the edge in a global
                  ;; so we don't ever have to ask patches in go
  min-e           ;;minimum elevation
  max-e           ;;maximum elevation
  the-row         ;;used in export-data. it is the row being written
  list_of_rain_amount
]

patches-own [
  elevation
  initial_elevation
  elevation_change
  amount_rain   ;;how many drops of rain here
]

turtles-own[
  soil        ;;how much soil a raindrop is carrying
  ]

to setup
  ca

  if MapType = "CraterLake" [

  resize-world -142 142 -71 71

  set elevation-dataset gis:load-dataset "data/elevation.asc"

  gis:set-world-envelope gis:envelope-of elevation-dataset

  gis:apply-raster elevation-dataset elevation

  gis:apply-raster elevation-dataset initial_elevation

  show_elevation]


  if MapType = "Flat" [
    resize-world -71 71 -71 71
    ask patches [set elevation 0]
  ]


  if Maptype = "Cone"[
    resize-world -71 71 -71 71
    ask patches [set elevation round distance patch 0 0 ]
    show_elevation
  ]

  if Maptype = "Hill"[
    resize-world -71 71 -71 71
    ask patches [set elevation 300 - round distance patch 0 0   ]
    show_elevation
  ]

  set-default-shape turtles "circle"


  set border patches with [ count neighbors != 8 ]

  set list_of_rain_amount []

    reset-ticks
end

to show_elevation
  if MapType = "CraterLake"
    [set min-e gis:minimum-of elevation-dataset
    set max-e gis:maximum-of elevation-dataset
    ask patches [set pcolor scale-color black elevation min-e max-e]
    ]

  if Maptype = "Cone" or Maptype = "Hill"[
      set min-e [elevation] of min-one-of patches [elevation]
      set max-e [elevation] of max-one-of patches [elevation]
      ask patches [set pcolor scale-color black elevation min-e max-e]]

  if Maptype = "Flat" [ask patches [set pcolor black] ]


end

to go
  ;;this part uses codes from the library model Grand Cayon, with some modifications
  create-raindrops rain-rate
  [ ifelse show_water_amount? or show_elevation_change? [hide-turtle set color blue][set color blue]
    set size 2
    set soil 0
    move-to one-of patches
   ]

  ifelse draw?
    [ ask turtles [ pd ] ]
    [ clear-drawing
      ask turtles [ pu ] ]

  ask raindrops [ ifelse erosion? [flow_with_erosion][flow] ]

  ask border
  [
    ask turtles-here [ die ]
  ]

  ;;codes from Grand Cayon end here

  ifelse show_water_amount?
    [show_amount_of_water]
    [ifelse show_elevation_change? and erosion?[show_elevation_change ]
      [  ask turtles [show-turtle]
         show_elevation]]

  tick

end

to flow
  ;;this part uses codes from the library model Grand Cayon, with some modifications

  let target min-one-of neighbors [ elevation + ( count turtles-here * water-height) ]

  ifelse [elevation + (count turtles-here * water-height)] of target
     < (elevation + ((count turtles-here - 0) * water-height))
    [ face target
      move-to target ]
    [ set breed waters ]
  ;;codes from Grand Cayon end here
end

to flow_with_erosion
  ;;this part uses codes from the library model Grand Cayon, with some modifications

  let target min-one-of neighbors [ elevation + ( count turtles-here * water-height) ]

  ifelse [elevation + (count turtles-here * water-height)] of target
     < (elevation + ((count turtles-here - 0) * water-height))
    [ ;;consider erosion effects
      ask patch-here [set elevation elevation - 1]
      set soil soil + 1
      face target
      move-to target
    ]
    [ set breed waters
      ask patch-here [set elevation elevation + [soil] of myself]
      set soil 0]
  ;;codes from Grand Cayon end here
end


to show_amount_of_water

  ;;To show by qurtiles
  ;set list_of_rain_amount []
  ;ask patches [set amount_rain count turtles-here  ]
  ;ask patches with [amount_rain > 0][set list_of_rain_amount lput amount_rain list_of_rain_amount]

     ;set list_of_rain_amount sort list_of_rain_amount
     ;let total count  patches with [amount_rain > 0]
     ;let num int (total / 4)

     ;let q1 item num list_of_rain_amount
     ;let q2 item (2 * num) list_of_rain_amount
     ;let q3 item (3 * num) list_of_rain_amount

    ; ask patches with [amount_rain = 0 ][set pcolor black]
    ; ask patches with [amount_rain <= q1 and amount_rain > 0] [set pcolor green]
    ; ask patches with [amount_rain <= q2 and amount_rain > q1 ][set pcolor blue]
    ; ask patches with [amount_rain <= q3 and amount_rain > q2 ][set pcolor yellow]
    ; ask patches with [amount_rain > q3][ set pcolor red]


   ;To show by scaled color. However, becuase the variation is small, it may be hard to see the difference.
    ask patches [set amount_rain count turtles-here  ]
      set max-e [amount_rain] of max-one-of patches [amount_rain]
      ask patches with [amount_rain > 0 ][set pcolor scale-color blue amount_rain (max-e + 1) 0 ]
      ask patches with [amount_rain = 0 ][set pcolor white]
      ask turtles [hide-turtle]

end


to show_elevation_change

  ask patches [set elevation_change elevation - initial_elevation]
  ask turtles [hide-turtle]

  ask patches with [elevation_change > 0][set pcolor green ];;increased

  ask patches with [elevation_change < 0][set pcolor red ];;decreased

  ask patches with [elevation_change = 0][set pcolor black]

end

to export_data

  file-close
  file-delete "data/result.asc"
  file-open "data/result.asc"
  file-print "ncols         285   \r\n"
  file-print "nrows         143   \r\n"
  file-print "xllcorner     -122.26638888878   \r\n"
  file-print "yllcorner     42.855833333   \r\n"
  file-print  "cellsize      0.0011111111111859   \r\n"
  file-print  "NODATA_value  -9999   \r\n"


  let i 71
  while [i > -72]
    [ set the-row []
      set the-row patches with [pycor = i]
        foreach sort-on [pxcor] the-row [ x -> ask x [file-write  elevation ] ]
     file-print "   \r\n"
     set i i - 1]

end
@#$#@#$#@
GRAPHICS-WINDOW
282
29
616
364
-1
-1
2.28
1
10
1
1
1
0
0
0
1
-71
71
-71
71
0
0
1
ticks
30.0

BUTTON
33
34
96
67
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

BUTTON
110
34
173
67
NIL
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

SLIDER
34
183
206
216
rain-rate
rain-rate
0
20
20.0
1
1
NIL
HORIZONTAL

SWITCH
32
315
202
348
draw?
draw?
1
1
-1000

BUTTON
184
35
247
68
NIL
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
34
93
204
138
MapType
MapType
"CraterLake" "Flat" "Cone" "Hill"
1

SLIDER
30
249
202
282
water-height
water-height
1
5
5.0
1
1
NIL
HORIZONTAL

PLOT
960
40
1160
190
Total Amount of Water
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot count turtles"

SWITCH
290
433
460
466
show_water_amount?
show_water_amount?
1
1
-1000

SWITCH
29
385
199
418
erosion?
erosion?
1
1
-1000

BUTTON
966
259
1067
292
NIL
export_data
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
36
150
186
178
How many raindrops created in one tick?
11
0.0
1

TEXTBOX
36
227
186
245
Height of one drop of rain:
11
0.0
1

TEXTBOX
36
296
186
314
Draw the trace of water:
11
0.0
1

TEXTBOX
297
482
447
566
Show a map with scaled color based on the amount of water on patches.
11
0.0
1

TEXTBOX
35
365
185
383
Erosion effect?
11
0.0
1

TEXTBOX
969
307
1119
363
This comment will export the current elevation map into the result.asc file in the data folder.
11
0.0
1

SWITCH
477
434
655
467
show_elevation_change?
show_elevation_change?
1
1
-1000

TEXTBOX
491
482
641
594
Show a map with scaled color based on elevation change.\nGreen: increased\nRed: decreased\nNote that this function only works when erosion is on.
11
0.0
1

TEXTBOX
286
406
487
434
Turn only one on at the same time:
11
0.0
1

@#$#@#$#@
## WHAT IS IT?

This is a model of Rainfall and water runoff. It simulates the runoff of the rain and its erosion. This model is inspired by the Grand Canyon Model.

The map being used is the crater lake national park in Oregon. See below for an elevation map.

![Picture not found](file:data/map.jpg)

## HOW IT WORKS

Rain drops are created randomly on the map based on the rain rate parameter. Rain drops will run to the neighboring patch with the lowest elevation. Besides, if there are already water in a patch, the height of water will also be added to its elevation, when raindrops are selecting the patch to run to. If a raindrop can not find a neighboring patch with lower elevation, it will stay where it is and become water. When erosion is turned on, the rain drops will take away one unit of soil when it runs through a patch. Then, the soil will be deposited at the patch where the rain drop stops. When raindrops run to the edge of the map, they are removed from this model.

## HOW TO USE IT

setup: setup the map and elevation according to the Map type input.

go: create raindrops and ask them to run one patch per tick.

rain-rate: how many raindrops created in one tick.

water-height: the height of one drop of water.

draw?: when this switch is on, draw the pathes of raindrops.

show_water_amount?: when this switch is on, hide the map and show the amount of water using a scaled color. Darker means more water there.

MapType: choose the type of map to setup. Note that the last three are for varification purpose.

## THINGS TO NOTICE

In this model, the lake does collect raindrops falling into it. However, it does not collect raindrops from the surrounding area, since the edge of the lake is higher. Therefore, we can see that the valleys instead of the lake have higher amount of water.

## THINGS TO TRY

Change the rain rate, water height as needed. Try to turn on show_water_amount? to observe the amount of water. Click on elevation change to get a general view of how the elevation has changed due to erosion. Load another map to run the simulation for other places.

## EXTENDING THE MODEL

You may add base water level in the beginning, for example, the lake is filled, and simulate the situation in a heavy rain.

## NETLOGO FEATURES

Note that the raindrops will look for the lowerest one of 8 neighbors, not 4.

## RELATED MODELS

Grand Canyon Model

## CREDITS AND REFERENCES

Grand Canyon Model
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

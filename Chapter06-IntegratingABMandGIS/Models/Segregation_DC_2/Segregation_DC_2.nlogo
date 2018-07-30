extensions [gis]

globals [
  dc-dataset
  mean-pctred ;;mean percentage red
  list-weight ;;weight matrix in a list
  MoransI
  segregationidex
]


patches-own [
  ID     ;;patch ID is identical with polygon ID_ID
  centroid? ;;if it is the centroid of a polygon

  ;;4 variables for centroids only
  myneighbors  ;;neighboring polygons' centroid patches
  popu          ;;population from data
  redt   ;;number of red turtles on polygon
  bluet  ;;number of blue turtles on polygon
  pctred  ;;percentage red. 0.5 if unoccupied

  mycolor      ;;its color
  occupied?    ;;if it is occupied by a turtle
  u ;;a variable used in calclating Moran's I. binary. 1 if adjacent
  ]

turtles-own[
  tID ;;turtle ID is identical with polygon ID_ID that it is located in
  tcolor

  happy?   ;;happy if neighboring same color agents >= 50%

  tneighbors   ;;an agentset of its neighbor turtles
  rneighbors   ;;number of red neighbors
  bneighbors   ;;number of blue neighbors

  tneighborpolygons  ;;neighboring polygons' centroid patches
  bneighborpolygons  ;;number of red neighboring polygons
  rneighborpolygons  ;;number of blue neighboring polygons

  blueratio ;; percentage blue
  blueratio-polygons ;; percentage blue in neighboring polygons
  redratio ;; percentage red
  redratio-polygons ;; percentage red in neighboring polygons
]


to setup
  ca
  reset-ticks

  set dc-dataset gis:load-dataset "data/DC.shp"       ;;loading the vector data of DC
  gis:set-world-envelope gis:envelope-of dc-dataset

  ;;copy the color information to patches (converting vector to raster)
  gis:apply-coverage dc-dataset "SOC" mycolor
  gis:apply-coverage dc-dataset "ID_ID" ID


  ;; each polygon identifies a patch at its centroid, which records the color
  ;; and population here
  let n 1
  foreach gis:feature-list-of dc-dataset [
    feature ->
    let center-point gis:location-of gis:centroid-of feature
    ask patch item 0 center-point item 1 center-point [
      set centroid? true
      set popu gis:property-value feature "POPU"
    ]
    set n n + 1
  ]


  ;; Find neighbors using a txt file produced by ArcGIS Polygon Neighbors.
  ;; Please read NETLOGO FEATURES in info tab for more information.

  ask patches with [centroid? = true] [
    set myneighbors n-of 0 patches ;;empty agentset
  ]

  file-close
  file-open "data/neighbors.txt"

  while [not file-at-end?] [
    let x file-read let y file-read
    ask patches with [ centroid? = true and ID = x ] [
      set myneighbors (patch-set myneighbors patches with [centroid? = true and ID = y ])
    ]
  ]
  file-close

  ask patches with [centroid? = true] [
    if count myneighbors = 0 [print "ERROR"]
  ]

  ;;use this line to verify if we get the right neighbors
  ;ask one-of patches with [centroid? = true] [print myneighbors   ask myneighbors [sprout 1]]

  ;;fill in the color on themap
  foreach gis:feature-list-of dc-dataset [
    feature ->
    if gis:property-value feature "SOC" = "RED" [
      gis:set-drawing-color 17  gis:fill feature 2.0
    ]
    if gis:property-value feature "SOC" = "BLUE" [
      gis:set-drawing-color 97  gis:fill feature 2.0
    ]
    if gis:property-value feature "SOC" = "UNOCCUPIED" [
      gis:set-drawing-color 7  gis:fill feature 2.0
    ]
  ]

  ;; Draw boundary
  gis:set-drawing-color white
  gis:draw dc-dataset 1

  ;; Creating households
  ask patches with [ID > 0] [set occupied? false]

  let y 1
  while [y <= 188] [

    ;; Find the population and initial colour of all of the patches inside this polygon
    let popu1 [popu] of patches with [centroid? = true and ID = y]
    let color1 [mycolor] of patches with [centroid? = true and ID = y]

    if color1 = ["RED"] [
      ;; This is a red polygon. Make 60% of the turtles red and the remaining 40% blue.
      ask n-of (0.6 *(item 0 popu1 / 10)) patches with [ID = y and occupied? = false] [
        sprout 1 [
          set tID y
          set tcolor "RED"
          set color red
          set size 2
          ask patch-here [ set occupied? true ]
        ]
      ]
      ask n-of (0.4 *(item 0 popu1 / 10)) patches with [ID = y and occupied? = false] [
        sprout 1 [
          set tID y
          set tcolor "BLUE"
          set color blue
          set size 2
          ask patch-here [ set occupied? true ]
        ]
      ]
    ]
    if color1 = ["BLUE"] [
      ;; Same code as above, but this time make 60% blue and 40% red
      ask n-of (0.6 *(item 0 popu1 / 10)) patches with [ID = y and occupied? = false] [sprout 1 [set tID y set tcolor "BLUE" set color blue set size 2 ask patch-here[set occupied? true]]]
      ask n-of (0.4 *(item 0 popu1 / 10)) patches with [ID = y and occupied? = false] [sprout 1 [set tID y set tcolor "RED"  set color red  set size 2 ask patch-here[set occupied? true]]]
    ]

    set y y + 1
  ]

end


to go
  check-if-happy
  move
  update-colors
  tick
  if all? turtles [ happy? ] [ stop ]
  if UpdateMoransI = true [get-moransI]
  if UpdateIndex = true [GetSegregationIndex]
end



to check-if-happy
  ;;turtles will look at two judgements to decide if they are happy or not.
  ;;to be happy, a turtle need the percentage of different color turtles in neighborhoods to be lower than a certain number(in slider)
  ;;each turtle looks at two neighborhoods, one is its 8-connected neighborhood, the other is its neighboring polygons.

  ;;count the number of red or blue turtles in 8-connected neigborhoods and neighboring polygons
  ask turtles [
    ask patches with [centroid? = true and ID = [tID] of myself] [
      ask myself [
        set tneighborpolygons [myneighbors] of myself
      ]
    ]
    let tneighborpolygons1 count tneighborpolygons
    ifelse color = red [
      set blueratio-polygons count tneighborpolygons with [mycolor = "BLUE"] / tneighborpolygons1
    ] [
      set redratio-polygons count tneighborpolygons with [mycolor = "RED"] / tneighborpolygons1
    ]
  ]

  ask turtles [
    let neighbors1 count turtles-on neighbors
    ifelse neighbors1 > 0 [
      ifelse color = red [
        set blueratio count (turtles-on neighbors) with [color = blue] / neighbors1
      ] [
        set redratio count (turtles-on neighbors) with [color = red] / neighbors1]
    ] [set redratio 0 set blueratio 0]
  ]

  ;;decide if they are happy
  ask turtles with [color = red] [
    ifelse blueratio < Percentage-different-to-be-unhappy / 100 and blueratio-polygons < Percentage-different-to-be-unhappy / 100 [
      set happy? true
    ][
      set happy? false
    ]
  ]

  ask turtles with [color = blue] [
    ifelse redratio < Percentage-different-to-be-unhappy / 100 and redratio-polygons < Percentage-different-to-be-unhappy / 100 [
      set happy? true
    ][
      set happy? false
    ]
  ]

end

to move

  ;;move to an unoccupied patch if not happy. change the color here.
  ask turtles [
    if happy? = false [
      ask patch-here [set occupied? false]
      move-to one-of patches with [occupied? = false and (mycolor = [tcolor] of myself or mycolor = "UNOCCUPIED")]
      ask patch-here [set occupied? true ]
      set tID [ID] of patch-here
    ]
  ]

end


to update-colors   ;;update polygon colors

 ask patches with [centroid? = true][

   let total-here turtles with [ tID = [ID] of myself]

   ifelse count total-here > 0 [
      ifelse count total-here with [color = red] > (0.5 * count total-here) [
        set mycolor "RED"
      ][
        set mycolor "BLUE"
      ]
    ][
      set mycolor "UNOCCUPIED"
    ]


   if mycolor = "RED" [
      gis:set-drawing-color 17  gis:fill  item (ID - 1) gis:feature-list-of dc-dataset 2.0
    ]
   if mycolor = "BLUE" [
      gis:set-drawing-color 97  gis:fill  item (ID - 1) gis:feature-list-of dc-dataset 2.0
    ]
   if mycolor = "UNOCCUPIED" [
      gis:set-drawing-color 7  gis:fill  item (ID - 1) gis:feature-list-of dc-dataset 2.0
    ]
   ]
  gis:set-drawing-color white
  gis:draw dc-dataset 1
end


to export

  get-pctred

  ;;this function creates a text file for the color information of the current map.
  file-close
  if file-exists? "data/finalmap.csv" [file-delete "data/finalmap.csv"]
  file-open "data/finalmap.csv"
  file-print "ID_ID,PctRed,SOC"   ;;writing the header here. Headers include ID, polygon color, the number of red and blue agents

  let i 1
  while [i <= 188] [    ;;there are 188 polygons
     file-type i      ;;writing ID
      file-type ","    ;; to seperate ID and the next column, namely polygon color
      ask patches with [centroid? = true and ID = i] [file-type pctred file-type "," file-print mycolor ]    ;;ask the corresponding patch to write down information
      set i i + 1
  ]
  file-close

end


;;calculate the Morans'I

to get-moransI

  get-pctred

  ;;calculate MoransI
  ;;see figure in Info/How it works for the formula and classification of value1-3
  let value1 0
  let counting 0

  ask patches with [ID > 0 and centroid? = true] [
    let xi pctred
    ask myneighbors [
      let xj pctred
      set value1 value1 + (xi - mean-pctred) * (xj - mean-pctred )
      set counting counting + 1
    ]
  ]
  if counting != 1130 [print "ERROR"] ;;verification

  let value2 1130  ;;this value does not change, it is equal to the number of 1s in the weight matrix
  ;;use the following code to verify it's equal to 1130
  ;set value2 0
  ;ask patches with [centroid? = true][set value2 value2 + count myneighbors]
  ;print value2


  let value3 0
  let counting2 0

  ask patches with [centroid? = true] [
    let xi pctred
    set value3 value3 + (xi - mean-pctred) ^ 2
    set counting2 counting2 + 1
  ]
  if counting2 != 188 [print "ERROR"] ;;verification

  set MoransI 188 * value1 / value2 / value3

end

to get-pctred
  ;;calculate percentage of red turtles
  ask patches with [centroid? = true] [
    let tonp turtles-on patches with [ID = [ID] of myself]
    set redt count tonp with [color = red]
    set bluet count tonp with [color = blue]
  ]

  let list-of-pctred []

  ask patches with [centroid? = true] [
    ifelse mycolor = "UNOCCUPIED" [
      set pctred 0.5
    ][
      set pctred redt / (redt + bluet)
    ]
    set list-of-pctred lput pctred list-of-pctred
  ]

  set mean-pctred mean list-of-pctred

end

to GetSegregationIndex

  let sum1 0

  ;let totalred count turtles with [color = red]
  ;let totalblue count turtles with [color = blue]

   ask patches with [centroid? = true][
    let tonp turtles-on patches with [ID = [ID] of myself]
    set redt count tonp with [color = red]
    set bluet count tonp with [color = blue]
    set sum1 sum1 + (redt / 660 - bluet / 660)
  ]

  set segregationidex 0.5 * sum1

end
@#$#@#$#@
GRAPHICS-WINDOW
315
22
768
476
-1
-1
2.764
1
10
1
1
1
0
0
0
1
-80
80
-80
80
0
0
1
ticks
30.0

BUTTON
40
31
103
64
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
186
31
249
64
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

BUTTON
114
31
177
64
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

MONITOR
36
120
119
165
NIL
count turtles
17
1
11

MONITOR
37
172
118
217
polygons
count patches with [centroid? = true]
17
1
11

MONITOR
38
225
118
270
unoccupied
count patches with [centroid? = true and mycolor = \"UNOCCUPIED\"]
17
1
11

MONITOR
38
278
118
323
Red polygons
count patches with [centroid? = true and mycolor = \"RED\"]
17
1
11

MONITOR
40
329
119
374
Blue polygons
count patches with [centroid? = true and mycolor = \"BLUE\"]
17
1
11

SLIDER
34
75
246
108
Percentage-different-to-be-unhappy
Percentage-different-to-be-unhappy
1
100
75.0
1
1
NIL
HORIZONTAL

PLOT
793
16
993
166
Number of Happy Agents
Time
Number
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot count turtles with [happy? = true]"

BUTTON
140
120
209
153
NIL
export
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
141
165
291
310
Export current map to finalmap.csv in data folder. Information will include color, number of red and blue turtles for each polygon. To analyze it in ArcGIS, open the csv file in ArcGIS, and export data as a dbf file to replace the oringinal DC.dbf file.
11
0.0
1

PLOT
793
168
993
318
Percentage happy
Time
Percentge
0.0
10.0
0.0
1.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "if count turtles > 0 [plot count turtles with [happy? = true] / count turtles]"

MONITOR
795
323
901
368
Percentage happy
count turtles with [happy? = true] / count turtles
4
1
11

TEXTBOX
630
504
780
522
1 patch = 113 meters
11
0.0
1

TEXTBOX
545
51
763
88
 0                            2.5                          5.0\n |---------------|---------------| km\n
11
0.0
0

BUTTON
38
422
143
455
Get Moran's I
get-moransI
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
41
461
149
506
Morans I
MoransI
11
1
11

SWITCH
38
382
179
415
UpdateMoransI
UpdateMoransI
0
1
-1000

TEXTBOX
184
387
306
432
* Note the model runs slow when this is turned on.
11
0.0
1

BUTTON
796
412
960
445
Get Segregation Index
GetSegregationIndex
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
798
456
963
501
Segregation Index
segregationidex
8
1
11

MONITOR
138
329
211
374
red agents
count turtles with [color = red]
17
1
11

MONITOR
215
329
293
374
blue agents
count turtles with [color = blue]
17
1
11

SWITCH
796
376
924
409
UpdateIndex
UpdateIndex
0
1
-1000

@#$#@#$#@
## WHAT IS IT?
This is a segregation model built using the map of Wahington DC. The form of data is vector data. This model is inspired by the Schelling segregation model.

Each turtle here represents a houshold that is either blue or red. All turtles want to have neighboors with the same color. The simple rule is that they move to unoccupied patches untill they are happy with their neighbors.

Here is a map I am using in this model.

![Picture not found](file:data/DCmap2.jpg)


## HOW IT WORKS

In the beginning, 10 to 80 turtles are created in each polygon, depending on the population data. Turtles are either blue or red. Red polygons have 60% red and 40% blue. Blue polygons have 60% blue and 40% red. 

In each tick, turtles look at two kinds of neighborhoods to decide whether they are happy or not. One is their geometrical neighboring polygons; the other is the 8-connected neighbors. If either neighborhood has different neighbors more than the specified percentage to be unhappy, turtle will move to an unoccupied patch in a polygon that is unoccupied or has the same color with it. The colors of the polygons are decided by the majority of turtles living in each of them, and the colors change every tick.

There are functions to export the map to GIS, and to calculate the Moran's I. 

Moran's I is a measure of spatial correlation. Values range from −1 (indicating perfect dispersion) to +1 (perfect correlation). If the different items are randomly distributed, Moran's I is 0.

The three parts are calculated seperately in the code. See below for the formula.

![Picture not found](file:data/moransi.jpg)

## HOW TO USE IT

1. Adjust "Percentage-different-to-be-unhappy" slider to set this value.
2. Press Setup to display the map and locate agents.
3. Press Go to ask agents to move for once.
4. Or Go forever to ask agents to move until all are happy.
5. Export the final map to ArcGIS.
6. Calculate the Moran's I. 

## THINGS TO NOTICE

Some patches-own variables are only for pathes that are centroids of polygons. This kind of varibales include popu, myneighbors, redt, bluet.

I changed POPU of polygon 91 and 105 to 400. I did that to have more turtles generated in them, because these two are large polygons and has small population. DC- copy.dbf is a copy of the oringinal file.

## THINGS TO TRY

Try different levels of percentage-different needed to be unhappy. Is there a level below which they can't reach static situation?

Export the final map to a csv file and open it in ArcGIS to save as .dbf file. Replace the DC.dbf with this file and open DC.shp in ArcGIS.

## EXTENDING THE MODEL

You may add more behavioral rules to the agents. 

You may increase the size of the map and create more turtles, however, that will require greater computational power of the computer.

Can you add more idex to measure spatial correlation?

## NETLOGO FEATURES

It is tricky to find the geometrical neighbors of each polygon, since Netlogo does not have this function. How I did it was to use the Polygon Neighbors function in ArcGIS 10.2 to create a text file which maps each polygon to its neighbors. Then, I deleted unecessary information like headers and ask Netlogo to read the information.


## RELATED MODELS

Segregation model in the library.

## CREDITS AND REFERENCES

The model was created by Yang Zhou (http://geospatialcss.blogspot.com/) under the guidance of Andrew Crooks.

Schelling, Thomas C. "Models of segregation." The American Economic Review (1969): 488-493.

Moran, Patrick AP. "Notes on continuous stochastic phenomena." Biometrika (1950): 17-23.
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

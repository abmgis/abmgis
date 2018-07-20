extensions [gis]


globals [
  themap
  urban-dataset
  slope-dataset
  road-dataset
  excluded-dataset
  landuse-dataset
  dispersion_value  ;;used in spontaneous growth
  rg_value  ;;road gravity value, used to calculate max_search
  max_search  ;;used in road influenced growth
  prob_to_build ;;a lookup table of the probability to urbanize based on slope
  max_slope
  the-row   ;;used in export-data. it is the row being written


]

patches-own[
  urban   ;;binary, if it is urbanized or not
  new_urbanized  ;;binary, if it is newly urbanized or not
  road  ;;binary, if there is a road or not
  road1 ;;includes information on road types from 1 to 4
  spread_center ;;binary

  road_found  ;;binary
  road_pixel  ;;the road poxel that an urbanized cell finds in road influenced growth

  slope
  excluded    ;;binary, 0 if excluded. The excluded image defines all locations that are resistant to urbanization.
  suitable   ;;binary, if it is suitable for urbanization

  landuse

  run_value ;;the maximum number of steps traveled along the road network by an urban pixel
  washere ;;binary, marks the patches that have been stepped on in road infulence

  selected ;;1 if a road patch is selected to be the next step in a road trip

]

turtles-own[
]


to setup
  ca
  reset-ticks

  load_data

  set dispersion_value (dispersion_coefficient * 0.005) * (world-width ^ 2 + world-height ^ 2) ^ 0.5
  set rg_value (rg_coefficient / max_coefficient * ((world-width + world-height) / 16.0 ))
  set max_search 4 * (rg_value * (1 + rg_value))

  check_suitability
  check_road

  ask patches with [road = 1][set run_value road1 / 4 * dispersion_coefficient]
  ask patches [set road_found 0 set road_pixel nobody]

  if show_roads [ask patches with [road = 1] [set pcolor black]]
end

to go
  spontaneous_growth
  print "spontaneous_growth finished"
  new_spreading_center_growth
  print "new_spreading_center_growth finished"
  edge_growth
  print "edge_growth finished"
  if road_influence [print "running road_influenced_growth..."
    road_influenced_growth] ;;this process could be very slow
  print "road_influenced_growth finished"
  ;not the old urban area will be kept Blue

  ifelse show_roads [
    ask patches with [new_urbanized = 1 and urban = 1 and road = 0] [set pcolor red]
    ask patches with [new_urbanized = 0 and urban = 0 and road = 0] [set pcolor grey]
    ask patches with [road = 1] [set pcolor black]]
  [
    ask patches with [new_urbanized = 1 and urban = 1] [set pcolor red]
    ask patches with [new_urbanized = 0 and urban = 0] [set pcolor grey]]
  tick
end


to load_data
  ;;gis:load-coordinate-system "data/WGS_84_Geographic.prj"
  set urban-dataset gis:load-dataset "data/urban_santafe.asc"

  set slope-dataset gis:load-dataset "data/slope_santafe.asc"

  set road-dataset gis:load-dataset "data/road1_santafe.asc"

  set excluded-dataset gis:load-dataset "data/excluded_santafe.asc"

  set landuse-dataset gis:load-dataset "data/landuse_santafe.asc"

  gis:set-world-envelope gis:envelope-of urban-dataset

  gis:apply-raster urban-dataset urban
  ask patches [ifelse urban = 2 [set urban 1 set pcolor blue][set urban 0 set pcolor gray]  ]

  gis:apply-raster slope-dataset slope

  gis:apply-raster road-dataset road1

  gis:apply-raster excluded-dataset excluded

  gis:apply-raster landuse-dataset landuse


end


to spontaneous_growth
  let i 0
  while [i < dispersion_value]
    [ let w random world-width
      let h random world-height
      ask patch w h [
        if urban = 0 and suitable = 1 [set urban 1 set new_urbanized 1]
      ]
      set i i + 1
    ]
end

to new_spreading_center_growth
  let i 0
  ask patches with [new_urbanized = 1]
    [ let x random max_coefficient
      if x < breed_coefficient [
        ask n-of 2 neighbors [
          if urban = 0 and suitable = 1
            [set urban 1 set new_urbanized 1]]

      ]
      set new_urbanized 0
    ]
end

to edge_growth
  ask patches with [urban = 1]
    [let x random max_coefficient
      if ( x < spread_coefficient) and ( count neighbors with [urban = 1] > 1 ) and (count neighbors with [urban = 0] > 0)
        [ask n-of 1 neighbors with [urban = 0]
          [if suitable = 1 [set urban 1 set new_urbanized 1] ]
        ]]
end

to road_influenced_growth
  ask patches with [urban = 1]
    [let x random max_coefficient
      if  x < breed_coefficient
        [ road_seeking
          if road_found = 1 [
            let i 1
            while [i < run_value][
              ask road_pixel [
                set washere 1
                if count neighbors4 with [road = 1 and washere = 0] > 0 [
                  ask one-of neighbors4 with [road = 1 and washere = 0][
                    ifelse count neighbors with [urban = 0 and suitable = 1] > 0
                      [ask one-of neighbors with [urban = 0 and suitable = 1][set urban 1 set new_urbanized 1 set pcolor red
                        set i run_value]]
                      [set selected 1]]]]
              if count patches with [selected = 1] > 1 [print "ERROR"]
              ask patches with [selected = 1] [ask myself [set road_pixel myself]]
              ask road_pixel [set selected 0]
              set i i + 1]
          ]]]
end

to road_seeking
  set road_pixel nobody
  set road_found 0
  set road_pixel one-of patches with [road = 1] in-radius max_search
  ifelse road_pixel = nobody [set road_found 0][set road_found 1]
end



to check_suitability
  ;;create lookup table
  set max_slope max [slope] of patches
  set prob_to_build []
  let i 0
  while [i <= critical_slope][
    let val (critical_slope - i) / critical_slope
    set prob_to_build lput (val ^ (slope_coefficient / 200)) prob_to_build
    set i i + 1]
  let j 1
  while [j <= (max_slope - critical_slope) ][
    set prob_to_build lput 0 prob_to_build  ;if slope > critical slope, the probability to urbanize is 0
    set j j + 1]

  ask patches [
    let x random-float 1
    ifelse x < item (slope) prob_to_build
      [set suitable 1][set suitable 0]
    if excluded = 0 [set suitable 0]]
end

to check_road
  ask patches [
    ifelse road1 > 0 [set road 1][set road 0]]
end


to show_slope
  let min-slope gis:minimum-of slope-dataset
  let max-slope gis:maximum-of slope-dataset

  ask patches [if (slope <= 0) or (slope >= 0)
    [set pcolor scale-color black slope min-slope max-slope]]
end
;shows what land is exculedd from develeopment
to show_suitable

  ask patches with [suitable = 1] ; can build on
    [set pcolor white]
  ask patches with [suitable = 0] ;Excluded land i.e. can't build on it
    [set pcolor black]
end

to show_map
  ifelse show_roads [
    ask patches with [urban = 1 and road = 0] [set pcolor red]
    ask patches with [urban = 0 and road = 0] [set pcolor grey]
    ask patches with [road = 1] [set pcolor black]]
  [ask patches with [urban = 1] [set pcolor red]
    ask patches with [urban = 0] [set pcolor grey]]
end

to show_landuse

  ask patches with [landuse = 1] [set pcolor 5]
  ask patches with [landuse = 2] [set pcolor 15]
  ask patches with [landuse = 3] [set pcolor 25]
  ask patches with [landuse = 4] [set pcolor 35]

end

to export_data
  file-close
  file-delete "data/result.asc"
  file-open "data/result.asc"
  file-print "ncols         531   \r\n"
  file-print "nrows         394   \r\n"
  file-print "xllcorner     -901575   \r\n"
  file-print "yllcorner     1442925   \r\n"
  file-print  "cellsize      30   \r\n"
  file-print  "NODATA_value  -9999   \r\n"


  let i 393
  while [i > -1]
    [ set the-row []
      set the-row patches with [pycor = i]
      foreach sort-on [pxcor] the-row [ ?1 -> ask ?1 [ifelse urban = 1 [file-write 1] [file-write 0]] ]
      file-print "   \r\n"
      set i i - 1]


  file-close

end
@#$#@#$#@
GRAPHICS-WINDOW
358
10
1061
535
-1
-1
1.31
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
530
0
393
0
0
1
ticks
30.0

BUTTON
19
15
159
48
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

INPUTBOX
173
53
344
113
max_coefficient
100.0
1
0
Number

BUTTON
20
54
158
87
step
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

BUTTON
21
92
158
125
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
20
233
157
266
Show slope
show_slope
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SWITCH
20
149
159
182
show_roads
show_roads
0
1
-1000

SWITCH
18
189
158
222
road_influence
road_influence
1
1
-1000

BUTTON
19
277
156
310
Show suitability
show_suitable
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
1080
205
1218
250
Pecentage urbanized
(count patches with [urban = 1]) / (count patches) * 100
2
1
11

SLIDER
172
336
344
369
slope_coefficient
slope_coefficient
0
100
50.0
1
1
NIL
HORIZONTAL

SLIDER
175
388
347
421
critical_slope
critical_slope
0
100
25.0
1
1
NIL
HORIZONTAL

SLIDER
173
132
345
165
dispersion_coefficient
dispersion_coefficient
0
100
20.0
1
1
NIL
HORIZONTAL

SLIDER
172
180
344
213
spread_coefficient
spread_coefficient
0
100
27.0
1
1
NIL
HORIZONTAL

SLIDER
172
285
344
318
rg_coefficient
rg_coefficient
0
100
10.0
1
1
NIL
HORIZONTAL

SLIDER
173
233
345
266
breed_coefficient
breed_coefficient
0
100
5.0
1
1
NIL
HORIZONTAL

PLOT
1079
21
1313
189
Percentage Urbanized
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
"default" 1.0 0 -16777216 true "" "plot (count patches with [urban = 1]) / (count patches) * 100"

BUTTON
21
368
158
401
Show map
Show_map
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
1083
284
1184
317
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

BUTTON
20
322
157
355
Show landuse
show_landuse
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
184
24
334
42
Set the coefficients here:
11
0.0
1

TEXTBOX
1085
324
1235
380
This button will export the current map into the result.asc file in the data folder.
11
0.0
1

@#$#@#$#@
## WHAT IS IT?

This model is a reimplementation of the Urban Growth Model that was developed by Clarke, Hoppen and Gaydos. This model explores urban growth and urbanization process.

The region of study in model is Santa Fe city. The map and data are obtained from The National Map.

This model could be helpful for people interested in exploring urbanizaton, urban structure, urban dynamics, etc. It is also helpful for people who wants to learn Netlogo.

## HOW IT WORKS

The urban growth dynamic implemented in the Urban Growth Model (UGM) contains four types of growth, namely:

(i) Spontaneous Growth - defines the occurrence of random urbanization of land.

(ii) New Spreading Centers - determines whether any of the new, spontaneously urbanized cells will become new urban spreading centers.

(iii) Edge Growth - defines the part of the growth that stems from existing spreading centers.

(iv) Road-Influenced Growth - agents take a road trip along a transportation infrastructure and look for suitable space for urbanization.

Note: Self Modification is not included in this model.

## HOW TO USE IT

1. Choose whether to show roads on the map or not.
2. Choose whether to include Road-influenced growth or not.
3. Set up the coefficients*.
4. Press Setup to load the map and data.
5. Press go to simulate urban growth.
6. Optional: Press Show slope to check a map of slope. Press "Show suitable" to show suitable palces for urbanizations (black = not suitable). Press "Show landuse" to show different types of landuse. Press "Show map" to show the urbanized/unurbanized map.

Coefficients:

dispersion_coefficient - controls the number of times a pixel will be randomly selected for possible urbanization

breed_coefficient - determines the probability of a spontaneous growth pixel becoming a new spreading center

spread_coefficient - determines the probability that any pixel that is part of a spreading center will generate an additional urban pixel in its neighborhood

slope_coefficient - acts as a multiplier to the actual slope

rg_coefficient - road gravity coefficient. used to calculate the maximum search distance for a road from a pixel selected for a road trip

The image below shows the oringinal map and the map after 10 ticks.


![Example](file:results.jpg)


The image below shows the road types and landuse types in the area studied.


![Example](file:results2.jpg)
## THINGS TO NOTICE

The process of Road-influenced Growth could be very slow, so there is an option to turn it off. The graph is more true to the original data when the Map-height is set to be higher, and therefore, there are more patches in the map. However, more patches will result in more complicated calculation and slower process.

Export_data comment will delete the result file and create a new output file, so remember to save the previous result before exporting new data.

## THINGS TO TRY

Try different coefficients according to your theory.

## EXTENDING THE MODEL

Try to add Self Modification. (Explained here: http://www.ncgia.ucsb.edu/projects/gig/About/gwSelfMod.htm)

More features can be added to the model to better simulate urban growth.

You may also try to use map and data for another city.

## RELATED MODELS

Look at the SLEUTH Model.

## CREDITS AND REFERENCES

1996. Clarke, K. C., Hoppen, S., and Gaydos, L. J., Methods And Techniques for Rigorous Calibration of a Cellular Automaton Model of Urban Growth, Third International Conference/Workshop on Integrating GIS and Environmental Modeling; 1996 Jan 21-25; Santa Fe, New Mexico.

1997. Clarke, K. C, Gaydos, L., and Hoppen, S., A self-modifying cellular automaton model of historical urbanization in the San Francisco Bay area. Environment and Planning B 24: 247-261

Urban Growth Model website: http://www.ncgia.ucsb.edu/projects/gig/

## Created by

Model created by Yang Zhou (http://geospatialcss.blogspot.com/) under the guidance of Andrew Crooks.
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

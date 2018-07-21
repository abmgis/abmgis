extensions[gis]

globals[
  entrance-data  ;;the locations of entrances
  exit-data      ;;the locations of exits
  obstacle-data  ;;the locations of obstacles
  empirical-data ;;empirical data of the frequency of each path being walked on

  the-row   ;;a list variable used in exporting the data
  walkingSpeed ;;average walking speed of all agents
  pick  ;;a variable used when assigning entrances to agents
  gradients   ;; a list of the empirical gradient maps

  list-of-heat-diff ;; a list of the diff between simulation results and empirical data
  no-duplicates-heat-diff-list  ;;the list above with duplicates removed
  frequency-list  ;;a list of the frequencies of each item in the list above
  log-freq ;;logitherm of the list above
]

patches-own[
  entrance  ;; entrance number if it is an entrance. 0 if it is not.
  exit      ;; exit number if it is an entrance. 0 if it is not.
  obstacle  ;;obstacle umber if it is an entrance. 0 if it is not.
  wall      ;;1 if it is the boundaries of the map. agents will not walk on boundaries.
  recorder  ;;1 or 0. for entrances that record how many agents have chosen this entrance.
  recorder2  ;;1 or 0. for exit that record how many agents have chosen this exit.
  chosenAsEntrance ;;for recorders only. times chosen as an entrance.
  chosenAsExit  ;;;;for recorders only. times chosen as an exit.
  probs-list  ;;a list of the probability to select each exit
  mygradient  ;;the gradient of this patch. It could be calculated based on distance or distance + empirical heat map, depending on the scenario.
  path        ;; how many times being walked on.
  empirical-heat   ;; the empirical heat map.
  heat  ;;heat = path normalized, heat = path / sum-path, ranges from 0 to 1
  heat-diff  ;; the difference between simulated heat and the data on the empirical heat map

]

turtles-own[
 destination ;;where it is going (number)
 mydestination ;;patch
 myentrance ;;where it was created (number)
 moved?  ;; ture if it has moved in this period
 my-heat-map  ;;the empirical heat map of itself, which depends on its entrance and exit
 target  ;; the patch it is moving towards. target may not be its final destination when the sight towards its destination is blocked.
]

to setup
  ca
  reset-ticks
  load_data  ;;load entrances/exits/obstacles data

  if Scenario = 3 or Scenario = 4 [read-gradients-data]  ;;load the empirical heat map.Use if statement to reduce setup time
  ;;read-gradients-data

  ;;;;;assign recorders for plotting entrance and exit frequency
  let i 1 let j 1
  while [i <= 16] [
    ask one-of patches with [entrance = i][set recorder 1]
    set i i + 1]

  while [j <= 18] [
    ask one-of patches with [exit = j][set recorder2 1]
    set j j + 1]

end


to load_data

    set entrance-data gis:load-dataset "data/entrance-data.asc"
    set exit-data gis:load-dataset "data/exit-data.asc"
    set obstacle-data gis:load-dataset "data/obstacles.asc"

    gis:apply-raster entrance-data entrance
    gis:apply-raster exit-data exit
    gis:apply-raster obstacle-data obstacle

    ask patches[ if obstacle >= 10000 [set pcolor grey]]

    ask patches with [pycor = 0 or pycor = 33 or pxcor = 0 or pxcor = 44] [set pcolor 2 set wall 1 set mygradient 9999]  ;;these are the boundaries

    ;ask patches[ if exit > 0 [set pcolor red]] ;;for verification


    ;;list of probabilies for different exits

    ask patches with [entrance = 1][set probs-list [0 0 1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0]]

    ask patches with [entrance = 2][set probs-list [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0]]

    ask patches with [entrance = 3][set probs-list [1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0]]

    ask patches with [entrance = 4][set probs-list [0.25 0 0 0 0 0 0 0 0 0 0 0.5 0 0 0 0.25 0 0]]

    ask patches with [entrance = 5][set probs-list [0 0 0 0 0 0 0 0.075 0.03 0 0 0.194 0 0.209 0.015 0.448 0.015 0.015]]

    ask patches with [entrance = 6][set probs-list [0 0 0 0.067 0 0.4 0 0 0.133 0 0 0 0 0.067 0 0.2 0 0.133]]

    ask patches with [entrance = 7][set probs-list [0.019 0 0 0 0 0.093 0.037 0.037 0.037 0.037 0.037 0.204 0 0.037 0 0.148 0.167 0.148]]

    ask patches with [entrance = 8][set probs-list [0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0]]

    ask patches with [entrance = 9][set probs-list [0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0]]

    ask patches with [entrance = 10][set probs-list [0 0 0 0 0 0 0 0 1 0 0 0 0 0 0 0 0 0]]

    ask patches with [entrance = 11][set probs-list [0 0 0 0 0 0.361 0 0.028 0.167 0 0 0.028 0 0.028 0.028 0.333 0.028 0]]

    ask patches with [entrance = 12][set probs-list [0 0 0 0 0 0.167 0 0.167 0 0 0 0 0 0 0 0.5 0.167 0]]

    ask patches with [entrance = 13][set probs-list [0 0 0 0 0.031 0.469 0 0.063 0 0 0 0.375 0 0 0 0 0.063 0]]

    ask patches with [entrance = 14][set probs-list [0 0 0 0 0.014 0.46 0 0.005 0.098 0 0 0.163 0.07 0.181 0 0.009 0 0]]

    ask patches with [entrance = 15][set probs-list [0.083 0 0 0 0 0.083 0 0 0.25 0.083 0 0.25 0 0.25 0 0 0 0]]

    ask patches with [entrance = 16][set probs-list [0 0 0 0 0 0.588 0 0.118 0.118 0 0 0 0 0.059 0 0.118 0 0]]


  end



to go
    if ticks = total_periods_to_run [stop]   ;;stop at total_periods_to_run ticks

    ask turtles [st set moved? False]    ;;agents have not moved in this period yet

    if auto-create? [repeat number-to-create [create-new-agent]]  ;;automatically create agents

    move  ;;agents move

    ask turtles [if [exit] of patch-here = destination or distance mydestination < 1 [die]]  ;;arriving destination

    ;if count turtles > 0 [set walkingSpeed count turtles with [moved? = true] / count turtles]

    if UpdateCompareChart? [compare-chart]

    tick

    ask turtles [if count turtles-here > 1[print "Error: more than 1 agent on one patch"]]  ;;verify that there is no more than one turtle on each patch
  end



  to create-new-agent  ;;create agent and select entrance and exit

    ;;pick an entrance based on probability if Scenario = 2 or 4. randomly select if Scenario = 1 or 3.
    ifelse Scenario = 2 or Scenario = 4 [set pick 1 + randindex [0.002 0 0.002 0.008 0.141 0.032 0.114 0 0.006 0.004 0.076 0.013 0.068 0.454 0.0253 0.0359] ][set pick 1 + random 15]

    ifelse count patches with [entrance = pick and count turtles-here = 0] != 0 [
       ask one-of patches with [entrance = pick and count turtles-here = 0] [sprout 1 [
          set color yellow set myentrance [entrance] of patch-here select-destination
          ifelse Scenario = 3 or Scenario = 4 [set my-heat-map heatmap myentrance destination][get-gradient-no-heat]]]
       ask one-of patches with [recorder = 1 and entrance = pick][set chosenAsEntrance chosenAsEntrance + 1]] ;;record how many times chosen as entrance
    [create-new-agent]  ;;if all patches with the selected number have one turtle on it, select another entrance

  end




to select-destination

    ;;pick an exit based on probability if Scenario = 2 or 4. randomly select if Scenario = 1 or 3.
    ifelse Scenario = 2 or Scenario = 4 [set destination 1 + randindex [probs-list] of patch-here set mydestination one-of patches with [exit = [destination] of myself]]
                                        [set destination 1 + random 17 set mydestination one-of patches with [exit = [destination] of myself]]
    ;;record how many times chosen as exit
    ask one-of patches with [recorder2 = 1 and exit = [destination] of myself][set chosenAsExit chosenAsExit + 1]
end


to move

   ask turtles[ find-lowest-gradient-in-vision   move-forward]

end


to find-lowest-gradient-in-vision  ;;find the patch with lowest gradient in vision

update-gradients  ;;gradient map is different for each agent. agents use this function to ask patches update gradients in its turn to move

let patches-in-vision patches in-radius view_distance  ;;all patches in a circle with radius = vision, including those behind obstacles

set patches-in-vision  sort-by [ [?1 ?2] -> [mygradient] of ?1 < [mygradient] of ?2 ] patches-in-vision ;;sort them according gradient


;;find the first patch in the list that is not blocked
let i 0

repeat 9999999[

face item i patches-in-vision

ifelse check-obstacle-both view_distance = false [set target item i patches-in-vision move-forward stop][set i i + 1]] ;;move towards a visible target with lowest gradient

end

to move-forward

    face target

    fd 1 set moved? true ask patch-here [set path path + 1] ;;path records how many times this path has been walked on

end

;;this function is used to select a destination based on the probability list [probs]
to-report randindex [probs]
  let probsums map [ ?1 -> sum sublist probs 0 ?1 ] n-values length probs [ ?1 -> ?1 + 1 ]
  let randnum random-float 1
  let probhelper filter [ ?1 -> ?1 > randnum ] probsums
  report (length probs) - (length probhelper)
end


to show_path   ;;draw the simulated path frequency using scaled color
  ask turtles [ht]
  let sum-path sum [path] of patches

  ask patches [set heat path / sum-path]

  let min-h min [heat] of patches
  let max-h max [heat] of patches

  ask patches [set pcolor scale-color blue heat max-h min-h ]
end



to add-obstacle  ;;add an obstacle in the middle. for testing.

  ask patches with [pxcor >= 13 and pxcor <= 17 and pycor >= 13 and pycor <= 17][set obstacle 10000 set pcolor grey]

end

to-report check-obstacle [view_distance1] ;;check if there is any obstacle ahead. return 0 if not. return the obstacle number if there is any.

  let i 1
  let obs-ahead 0

  while [i <= view_distance1 and obs-ahead = 0][
     if patch-left-and-ahead 0 i != nobody[
     ask patch-left-and-ahead 0 i [
       if obstacle > 0 [set obs-ahead obstacle]
       ]]
     set i i + 1]

  report obs-ahead
  ;ifelse obs-ahead = 0 [report false][report true]  ;;to return ture or false instead
end

to-report check-obstacle-agents [view_distance2] ;;check if there is any agent ahead. return false if not. return ture if there is any.
  let i 1
  let obs-ahead 0

  while [i <= view_distance2][
     if patch-left-and-ahead 0 i != nobody[
     ask patch-left-and-ahead 0 i [
       if count turtles-here > 0 [set obs-ahead obs-ahead + 1]

       ]]
     set i i + 1]

  ifelse obs-ahead = 0 [report false][report true]
end

to-report check-obstacle-both [view_distance3] ;;;;check if there is any obstacles or agent ahead. return false if not. return ture if there is any.
  let i 1
  let obs-ahead 0

  while [i <= view_distance3][
     if patch-left-and-ahead 0 i != nobody[
     ask patch-left-and-ahead 0 i [
       if count turtles-here > 0 or obstacle > 0[set obs-ahead obs-ahead + 1 stop]

       ]]
     set i i + 1]

  ifelse obs-ahead = 0 [report false][report true]
end

to-report check_wall [view_distance4] ;;check if there is any wall ahead. return false if not. return ture if there is any.

  let i 1
  let obs-ahead 0

  while [i <= view_distance4][
     if patch-left-and-ahead 0 i != nobody[
     ask patch-left-and-ahead 0 i [
       if wall = 1 [set obs-ahead obs-ahead + 1]

       ]]
     set i i + 1]

  ifelse obs-ahead = 0 [report false][report true]
end


to export_data  ;; to export the result heat map to an asc file.
  file-close
  if file-exists? "data/finalmap.asc" [file-delete "data/finalmap.asc"]
  file-open "data/finalmap.asc"
  file-print "ncols         43   \r\n"
  file-print "nrows         32   \r\n"
  file-print "xllcorner     0   \r\n"
  file-print "yllcorner     0   \r\n"
  file-print  "cellsize     0.5   \r\n"
  file-print  "NODATA_value  -9999   \r\n"

  let i 31
  while [i > -1]
    [ set the-row []
      set the-row patches with [pycor = i]
        foreach sort-on [pxcor] the-row [ ?1 -> ask ?1 [file-write path] ]
     file-print "   \r\n"
     set i i - 1]

  file-close

end


to draw-empirical-data   ;;draw the empirical heat map using scaled color
  set empirical-data gis:load-dataset "data/empirical-data.asc"
  gis:apply-raster empirical-data empirical-heat

  ask turtles [ht]

  let min-h min [empirical-heat] of patches
  let max-h max [empirical-heat] of patches

  ask patches [set pcolor scale-color blue empirical-heat max-h min-h ]
end

;;read the empirical gradients data into a list for faster processing
to read-gradients-data
  set gradients [ 0 ]  ;; item 0 is not being used

  file-close

  file-open "data/gradient.txt"

  while [not file-at-end?][

  set gradients lput file-read gradients]

  file-close

end


to-report heatmap [x y]  ;; x = entrance #, y = exit #.  reports a list of the heat map between x and y.

let number (x - 1) * 1335 * 18 + (y - 1) * 1335 + 3 ;;the location of the first number of the heat map it needs

let report-list []

repeat 1333 [
set report-list lput item number gradients report-list
set number number + 1]

report report-list

end

to update-gradients  ;;gradient map is different for each agent. agents use this function to ask patches update gradients in its turn to move

  let i 0
  let x 1
  let y 32

  repeat 43[
      repeat 31[
         ask patch x y [set mygradient item i [my-heat-map] of myself]
         set y y - 1
         set i i + 1]
      set x x + 1  set y 32
  ]

  ask patches with [obstacle > 0 or wall = 1 or pycor = 1] [set mygradient 9999 ]  ;;walls and obstacles have gradient = 9999, so no one moves into them
end




to draw-gradient  ;;to draw the gradient map. note that this map is different for each agent

  ask turtles [ht]

  let min-h min [mygradient] of patches with [mygradient != 9999 ]
  let max-h max [mygradient] of patches with [mygradient != 9999 ]

  ask patches with [mygradient != 9999 ][set pcolor scale-color blue mygradient max-h min-h ]
  ask patches with [mygradient = 9999 ][set pcolor white]
end


to clear-graph  ;;used to clear the map after drawing the path frequency

    ask patches [set pcolor black]
    ask patches[ if obstacle >= 10000 [set pcolor grey]]
    ask patches with [pycor = 0 or pycor = 33 or pxcor = 0 or pxcor = 44] [set pcolor 2]

end




to get-gradient-no-heat  ;;calculate gradients map purely based on distance

  ask patches with [wall != 1 and pycor > 1] [
    set mygradient distance [mydestination] of myself
    ]

  set my-heat-map []

  let x 1
  let y 32

  repeat 43[
      repeat 31[
         set my-heat-map lput [mygradient] of patch x y my-heat-map
         set y y - 1]
      set x x + 1  set y 32
  ]
end


to compare-chart  ;;compare the simulation results with empirical data, and plot the differences on a chart
  let sum-path sum [path] of patches

  ask patches [set heat path / sum-path]

  set empirical-data gis:load-dataset "data/empirical-data.asc"
  gis:apply-raster empirical-data empirical-heat

  set list-of-heat-diff []

  ask patches with [wall = 0 and pycor != 1 ][set heat-diff heat - empirical-heat set list-of-heat-diff lput heat-diff list-of-heat-diff ]


  set no-duplicates-heat-diff-list remove-duplicates list-of-heat-diff

  set frequency-list map [ ?1 -> frequency ?1 list-of-heat-diff ] no-duplicates-heat-diff-list

  set log-freq []
  foreach frequency-list [ ?1 -> set log-freq lput log ?1 10 log-freq ]

  let m 0
  set-current-plot "CompareChart"
  clear-plot
  while [m < length frequency-list ]
    [plotxy item m no-duplicates-heat-diff-list item m log-freq
    set m m + 1]


end


to-report frequency [i lst]  ;;report the frequency of i in list

  report length filter [ ?1 -> ?1 = i ] lst
end
@#$#@#$#@
GRAPHICS-WINDOW
172
10
765
461
-1
-1
13.0
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
44
0
33
0
0
1
ticks
30.0

BUTTON
17
13
80
46
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
16
59
79
92
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

BUTTON
85
60
148
93
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
775
13
892
46
NIL
show_path
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

SLIDER
6
294
146
327
view_distance
view_distance
0
50
50.0
1
1
NIL
HORIZONTAL

SWITCH
11
191
147
224
auto-create?
auto-create?
0
1
-1000

TEXTBOX
13
230
163
248
Create one agent per tick.
11
0.0
1

BUTTON
15
102
147
135
NIL
create-new-agent
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
8
252
147
285
number-to-create
number-to-create
0
5
1.0
1
1
NIL
HORIZONTAL

BUTTON
777
155
892
188
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

PLOT
914
10
1177
160
Entrances frequency
Entrance number
Times chosen
0.0
16.0
0.0
10.0
true
false
"" ""
PENS
"times" 1.0 1 -16777216 true "clear-plot" "clear-plot\nlet n 0\nwhile [n <= 16][\n  ask patches with [recorder = 1 and entrance = n][plot chosenAsEntrance]\n  set n n + 1]"

PLOT
915
178
1179
328
Exits frequency
Exit number
Times chosen
0.0
18.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 1 -16777216 true "" "clear-plot\nlet n 0\nwhile [n <= 18][\n  ask patches with [recorder2 = 1 and exit = n][plot chosenAsExit]\n  set n n + 1]"

CHOOSER
7
336
149
381
Scenario
Scenario
1 2 3 4
3

BUTTON
15
147
145
180
NIL
add-obstacle
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
777
109
893
142
NIL
clear-graph
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
776
62
894
98
NIL
draw-empirical-data
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
920
344
1186
516
CompareChart
differences
log of counts
-0.025
0.025
0.0
0.0
true
false
"" ""
PENS
"default" 1.0 2 -16777216 true "" ""

SWITCH
8
390
168
423
UpdateCompareChart?
UpdateCompareChart?
0
1
-1000

INPUTBOX
8
433
163
493
total_periods_to_run
200.0
1
0
Number

BUTTON
778
205
893
238
NIL
compare-chart
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

This is a reimplementation of the pedestrian model in “Walk This Way: Improving Pedestrian Agent-Based Models through Scene Activity Analysis” by Andrew Crooks et al. The purpose of pedestrian models in general, is to better understand and model how pedestrians utilize and move through space. This model makes use of mobility datasets from video surveillance to explore the potential that this type of information offers for the improvement of agent-based pedestrian models.     

This reimplementation model is written by Yang Zhou, PhD student in Computational Social Science at George Mason University.

## HOW IT WORKS

There are 16 entrances and 18 exits in the model. An agent is created at an entrance, and will choose one exit as its destination. Agents move towards their destinations using shortest route while avoiding both the fixed obstacles and the other agents. The rule of selecting shortest route is simple: set the patch that one can see with the lowest gradient as target, and move towards it. One can see a patch that is both within vision and not blocked by obstacles. The method of calculating gradients will be explained in the follwoing text.

Two types of empirical data are used in this model. Firstly, the empirical of probability of choosing each entrance and exit is used when creating agents and assigning their entrance and exits. Secondly, the empirical data of how people have moved on this map on August 25th is used to construct the gradients map, according to which agents select their path towards their destinations. The more frequently being chosen as a path + the closer to destination, the lower the gradient will be. When the empirical gradient maps are not used, the gradients map is constructed purely based on distance to destinations. Four scenarios are designed to compare the simulation results with the empirical result, in order to show how mobility data could help to improve pedestrian models.

Scenario 1: No Realistic Information about Entrance/Exit Probabilities or Heat Maps
In this scenario, entrance and exit locations are considered known, but traffic flow through them is considered unknown. Under such conditions, we run the model to understand its basic functionality without calibrating it with real data about entrance and exit probabilities, nor activity-based heat maps. This will serve as a comparison benchmark, to assess later on how the ABM calibration through such information improves (or reduces) our ability to model movement within our scene.

Scenario 2: Realistic Entrance/Exit Probabilities But Disabled Heat Maps
In this scenario, we explore the effects of introducing realistic entrance and exit probabilities on the model. The heat map models used are distance-based, and not informed by the real datasets. Instead, we use distance-based gradients (i.e., agents Tchoose an exit and walk the shortest route to that exit).

Scenario 3: Realistic Heat Maps but Disabled Entrance/Exit Probabilities
In this scenario we introduce real data-derived heat maps in the model calibration. These activity-based heat map-informed gradients are derived from harvesting the scene activity data, however entrance and exit probabilities are turned off. In a sense one could consider this a very simple form of learning how agents walk on paths more frequently traveled within the scene. It also allows us to compare to extent to which the quality of the results are due to the heat maps versus entrance and exit probability.

Scenario 4: Realistic Entrance/Exit Probabilities and Heat Maps Enabled
In the final scenario we use all available information to calibrate our ABM, namely, the heat map-informed gradients and entrance-exit combinations and see how this knowledge impacts the performance of the ABM.


## HOW TO USE IT

Basics:
1.	Choose a scenario using the chooser “Scenario”.
2.	Turn on auto-create? To automatically create x agents at each period. x could be changed using the slider “number-to-create”.
3.	Choose a view distance, which is the distance an agent can see and design its shortest route. Note that agents can not see through obstacles. The default value is 50, which means agents can see as far as the map. This setting is identical with the original model.
4.	Press setup to load data. This process will take some time due to big data size.
5.	Press go to run the model.

Options for testing:
1.	Press create-new-agent to create one agents
2.	Press add-obstacle to create one obstacle in the middle of the map.

 Results:
1.	Press show_path to show the frequency of each path being walked on. Click on clear_graph to clear.
2.	Press export_data to export the frequency map to data/finalmap.asc
3.	The charts named "Entrances frequency" and "Exits frequency" show the frequency of each entrance or exit being chosen.
4.	The chart named "CompareChart" show the differences of the results compared to the empirical data. On the x axis is the difference between simulated and empirical data, and on the y axis is the log of counts of the corresponding differences. If UpdateCompareChart? is turned on, the chart is updated in each period, otherwise press compare_chart to draw it.


## THINGS TO NOTICE

There is one gradient map for each pair of entrance and exit, therefore, 16 * 18 = 288 maps are loaded. However, the final result is compared to only one path frequency map which is an empirical dataset obtained on August 25th.

Also please note that, when the entrance/exit probabilities table is used, some entrances are exits have a probability of being chosen equals to zero. While the table is not used, agents just randomly choose any entrances or exits.

## THINGS TO TRY

Try to add more agents each period. Try to change the view distance.

Try to add an additional obstacle to test if agents are avoiding obstacles correctly. You can add more code to create different obstacles.

## EXTENDING THE MODEL

Think about what other data might be used in this model to improve the simulation?


## RELATED MODELS

The original model can be found here:
https://www.openabm.org/model/4706/version/1/view


## CREDITS AND REFERENCES

Crooks, A., Croitoru, A., Lu, X., Wise, S., Irvine, J. M., & Stefanidis, A. (2015). Walk This Way: Improving Pedestrian Agent-Based Models through Scene Activity Analysis. ISPRS International Journal of Geo-Information, 4(3), 1627-1656. See: http://www.mdpi.com/2220-9964/4/3/1627/htm

The model was created by Yang Zhao under the guidance of Andrew Crooks
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

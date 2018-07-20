;Paper Title: From Cyber Space Opinion Leaders and the Spread of Anti-Vaccine Extremism to Physical Space Disease Vulnerable Clusters
;By Xiaoyi Yuan

extensions [
  CSV
]

globals [

  recover-rate     ;the rate of recovery when people get infected; After recovery, they are permanently immuned
  extremists       ;list of people who are extremists
]

turtles-own [
  ID                      ;each turtle gets an ID
  location                ;record the turtle's patch location so that after network visualization, he/she knows where to go back
  local-neighbors         ;the physical space neighbors (8 neighbors for each one of them)
  anti-vaccine-sentiment  ;range from -1 to 1, higher the value, more likely to be an anti-vaccine extremist. if -1, it means that the person is very pro-vaccination
  extremist?              ;True or False
  vaccinated? ;True means vacinnated, False means not vaccinated
  susceptible?;True means susceptible (those who don't get the vaccine will be susceptible) , False means not susceptible
  infected? ;True means that the person is infectious
  recovered?  ;True means that the person is recovered from the infection and once recovered, he/she will be permanently immnued
]



links-own [
  rewired?
]

to setup

  ca

ask patches [
  sprout 1    ;Total number of patches is 2601.
              ;In this model, for the sake of simplicity, I don't consider the density of physical space, so the world is always "full of people" (one person on each patch)
  ]

ask turtles [
  set shape "person"
  set color brown
  set anti-vaccine-sentiment 0
  set extremist? False
  set extremists []
  set location patch-here
  set local-neighbors turtles-on neighbors
  set vaccinated? False
  set susceptible? False
  set infected? False
  set recovered? False
  ]




reset-ticks

end




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;; information network;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;two types of connection between people in this model:
;1. physical connection: each person has 8 neighbors around them, symbolizing real-world physical spatial connections
;(This connection facilitates disease transmission, and in this model, I assume that people don't communicate their opinion within spatial connections)
;2. cyber connection: the network.
;(This connection symbolize the online opinion communication, and of course, disease won't transmit through online connections)

to generate-network


  ;Scale-free network, characterized by a power law degree distribution


  ask links [die]

  ;randomly select two person and connect them first
  let node1 one-of turtles
  ask one-of turtles [
    if node1 != self [
    create-link-with node1
    [set color cyan]
    ]
  ]

  ;then the one with higher degree would have a higher probability of attracting new links

  while [count turtles with [count link-neighbors > 1] <= num-nodes-connected]
  [

  let old-node [one-of both-ends] of one-of links
  ask one-of turtles [
    if old-node != nobody and old-node != self
       [
         create-link-with old-node
         [set color cyan]
       ]
    ]
  ]



end

to hide-network
  ask links [
    hide-link
  ]
end

to show-network
  ask links [
    show-link
  ]
end






;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;; opinion diffusion ;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to setup-opinions
  set extremists []
  ask turtles [
    set extremist? false
    set color brown
    set anti-vaccine-sentiment 0
  ]

end


to spread-extremism
  setup-opinions
  assign-sentiment
  assign-leaders-extremists
  cyber-spread-extremism
  local-spread-extremism

end



;1. Assign anti-vaccine-sentiment (uniform distribution)

to assign-sentiment

  ask turtles [
  set anti-vaccine-sentiment median (list -1 (random-normal 0 1) 1)
]


end


;2. Assign certain percent (a parameter) of opinion leaders as extremists (reassign their anti-vaccine-sentiment as 1)

to assign-leaders-extremists

  ;first find out who are the most highly connected people
  let lst (reverse (sort-on [count link-neighbors] turtles))

  set extremists sublist lst 0 n-extremists-leaders

  foreach extremists [
    ask ? [
    set anti-vaccine-sentiment 1
    set extremist? True
    set color cyan

    ]
  ]




end


;3. social influence on the cyber-network (the less stubborn a person is, the higher probability that person would be influenced)

to cyber-spread-extremism

  ;those who are connected with extremist opinion leaders are potential targets

  let potential-targets []
  foreach extremists [
    ask ? [
      set potential-targets lput link-neighbors potential-targets
    ]
  ]

  ;If their anti-vaccination-sentiments are higher than a certain level, they will be turned into extremists under the influence
  foreach potential-targets [
    ask ? [
      if anti-vaccine-sentiment >= threshold-sentiment [

        set extremist? True

      ]
    ]
  ]

  ask turtles [
    if extremist? and not member? self extremists [
      set extremists lput self extremists
      set color cyan
    ]
  ]



end



;4. social influence on the physical space (the less stubborn a person is, the higher probability that person would be influenced)

to local-spread-extremism

  let potential-targets []
  foreach extremists [
    ask ? [
      set potential-targets lput local-neighbors potential-targets
    ]
  ]


  foreach potential-targets [
    ask ? [

      if anti-vaccine-sentiment >= threshold-sentiment [
        set extremist? True

      ]
    ]
   ]

  ask turtles [
    if extremist? and not member? self extremists [

      set extremists lput self extremists
      set color cyan
    ]
  ]



end



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;; disease transmission process;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to setup-disease
  clear-plot
  reset-ticks
  ask turtles [
    set infected? False
    set recovered? false
    set susceptible? False
    set vaccinated? False
  ]



end

to vaccinate-non-extremists

  setup-disease

  ask turtles with [extremist? = False][
    set vaccinated? True


  ]
  ask turtles with [extremist? = True] [
    set vaccinated? False
    set color cyan
  ]


end

to vaccinate-random-people

  setup-disease

  ask turtles [
    set vaccinated? True
    set color brown
  ]

  ask n-of length extremists turtles  [
    set vaccinated? False
    set color cyan
  ]




end

to transmit-disease

  spread-disease
  recover

end



to infect


  ask turtles with [vaccinated? = False][
    set susceptible? True

  ]
  ask n-of 10 turtles with [susceptible? = True] [
    set infected? True
    set color red
  ]

end

to spread-disease
  ask turtles with [susceptible? = True and recovered? = False] [
    let n-infected-neighbors 0
    ask turtles-on neighbors [
      if infected? = True [
        set n-infected-neighbors n-infected-neighbors + 1
      ]
    ]

    if random-float 1 <= (1 - e ^ (- 0.05 * n-infected-neighbors)) [
    set infected? True
    set color red
    ]
  ]
tick
end


to recover
  ask turtles with [infected? = True] [
    if random-float 1 <= 0.001 [
      set recovered? True
      set infected? False
      set susceptible? False
      set color green
    ]
  ]

end



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;; visualizations ;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;Since agents are connected in two ways, the physical (patches) and the information network
;Therefore there are two ways of visualization that shows their connections

to visualize-cyber-network

  ask turtles [

       set size (sqrt count my-links) / 3

  ]
  ;; layout-spring makes all the links act like springs.
  ;; 0.2 - spring constant; how hard the spring pushes or pulls to get to its ideal length
  ;; 2   - ideal spring length
  ;; 0.5 - repulsion; how hard all turtles push against each other to space things out
  layout-spring turtles links 0.2 2 0.5

  ;; the layout doesn't look good if nodes get squeezed up against edges of the world
  ask turtles [
    ;; stay away from the edges of the world; the closer I get to the edge, the more I try
    ;; to get away from it.
    facexy 0 0
    fd (distancexy 0 0) / 100
  ]
end




to visualize-physical-space
  ask turtles [
    move-to location

  ]

end


to uniform-size
  ask turtles [
    set size 1
  ]
end


to degree-size
  ask turtles [
    set size (sqrt count my-links) / 3
  ]
end



to make-report

  let parameter_lst []

  let lst1 [1 2 3 4 5 10 15 20 30]

  let i 0
  while [i <= 8] [
      set n-extremists-leaders item i lst1
      set threshold-sentiment 0.5
      while [threshold-sentiment <= 1] [
          set parameter_lst lput list n-extremists-leaders precision threshold-sentiment 2 parameter_lst
          set threshold-sentiment threshold-sentiment + 0.05
      ]
      set i i + 1
  ]

  let n 0

  while [n <= 90] [

  set n-extremists-leaders item 0 (item n parameter_lst)
  set threshold-sentiment item 1 (item n parameter_lst)

  let nextremists []
  let infected_e []
  let infected_r []


  let lst []

  repeat 20 [

  ;spread extremism

   setup-opinions
   spread-extremism
   set nextremists lput length extremists nextremists

  ;vaccinate extremists

   setup-disease
   vaccinate-non-extremists
   infect
   let ninfected []
   while [count turtles with [infected? = True] > 0] [
     transmit-disease
     set ninfected lput count turtles with [infected? = true] ninfected]
   set infected_e lput max ninfected infected_e


  ;vaccinate random people

   setup-disease
   vaccinate-random-people
   infect
   let ninfected2 []
   while [count turtles with [infected? = true] > 0] [
     transmit-disease
     set ninfected2 lput count turtles with [infected? = true] ninfected2]
   set infected_r lput max ninfected2 infected_r

  ]


   let mean_extremists mean nextremists
   let sd_extremists standard-deviation nextremists
   let mean_infected_e mean infected_e
   let sd_infected_e standard-deviation infected_e
   let mean_infected_r mean infected_r
   let sd_infected_r standard-deviation infected_r

   set lst lput (list mean_extremists sd_extremists mean_infected_e sd_infected_e) lst
   set lst lput (list mean_extremists sd_extremists mean_infected_r sd_infected_r) lst
   csv:to-file (word n-extremists-leaders "-" threshold-sentiment ".csv") lst

   file-close

   set n n + 1
  ]

end
@#$#@#$#@
GRAPHICS-WINDOW
224
10
744
551
25
25
10.0
1
10
1
1
1
0
1
1
1
-25
25
-25
25
0
0
1
ticks
30.0

BUTTON
72
31
135
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

SLIDER
20
120
193
153
num-nodes-connected
num-nodes-connected
0
2601
2500
1
1
NIL
HORIZONTAL

BUTTON
20
153
193
186
NIL
generate-network
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
19
222
107
255
NIL
hide-network
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
106
222
193
255
NIL
show-network
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
752
459
832
504
links
count links
17
1
11

BUTTON
19
255
193
288
NIL
visualize-cyber-network
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
19
288
193
321
NIL
visualize-physical-space
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
19
321
111
354
NIL
uniform-size
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
321
193
354
NIL
degree-size
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
21
421
213
454
n-extremists-leaders
n-extremists-leaders
0
30
30
1
1
NIL
HORIZONTAL

SLIDER
21
454
213
487
threshold-sentiment
threshold-sentiment
0
1
1.0000000000000004
0.01
1
NIL
HORIZONTAL

MONITOR
919
459
1004
504
extremists
length extremists
17
1
11

BUTTON
21
486
213
519
NIL
spread-extremism
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
752
70
902
103
NIL
vaccinate-non-extremists\n
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
752
103
902
136
NIL
infect
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
751
201
1109
438
disease transmission
NIL
NIL
0.0
10.0
0.0
100.0
true
true
"" ""
PENS
"infected" 1.0 0 -5298144 true "" "plot count turtles with [infected? = True]"
"recovered" 1.0 0 -13210332 true "" "plot count turtles with [recovered? = True]"
"susceptible" 1.0 0 -4079321 true "" "plot count turtles with [susceptible? = True]"

BUTTON
752
136
902
169
NIL
transmit-disease
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
832
504
919
549
susceptibles
count turtles with [susceptible? = True]
17
1
11

MONITOR
752
504
832
549
vaccinated
count turtles with [vaccinated? = True]
17
1
11

MONITOR
919
504
1004
549
infected
count turtles with [infected? = True]
17
1
11

MONITOR
1003
504
1104
549
recovered
count turtles with [recovered? = True]
17
1
11

BUTTON
956
71
1109
104
NIL
vaccinate-random-people
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
1003
459
1104
504
vaccine coverage
precision (count turtles with [vaccinated? = True] / count turtles) 2
17
1
11

TEXTBOX
49
93
199
111
1. Create Cyber Network
11
0.0
1

TEXTBOX
22
204
172
222
Network Visualization
11
0.0
1

TEXTBOX
58
395
208
430
2. Spread of Extremism
11
0.0
1

TEXTBOX
772
30
901
58
3. Vaccination and \nDisease Transmission
11
0.0
1

TEXTBOX
970
33
1120
51
4. Comparison Group
11
0.0
1

TEXTBOX
919
57
1195
79
(Vaccinate same number of random chosen population)
9
0.0
1

BUTTON
956
104
1109
137
NIL
infect
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
956
137
1109
170
NIL
Transmit-disease
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

MONITOR
832
459
919
504
population
count turtles
17
1
11

TEXTBOX
908
26
923
180
|\n|\n|\n|\n|\n|\n|\n|\n|\n|\n|
11
0.0
1

@#$#@#$#@
## WHAT IS IT?

This model simulates the spread of anti-vaccine sentiments in cyber and physical space and how it creates emergence of clusters of anti-vacciners, which eventually lead to higher probablity of disease outbreaks.


## HOW IT WORKS

1. Physical space: by clicking setup botton, you create a population of agents and each of them is locate on different patches.

2. Cyber space: the network created represents their cyber space connections where information flows.

3. The model starts with a number of anti-vaccine extremists (n-extremists-leaders) and a level of anti-vaccine sentiment for the whole population (threshold-sentiment). Although these opinion leaders are extremists by default, other population will not become extremists until meeting two requirements: they are connected to an extremists in either cyber or physical space and their anti-vaccine sentiment is higher than the threshold-sentiment value. The spread of extremism has two stages: first in cyber space where opinion leaders spread their anti-vaccine sentiments to those who are connected to them; second in physical space where extremists spread their anti-vaccine sentiment to their physical (patch) neighbors. The neighbors are defined using Moore neighborhood (8 neighbors for each agent).

4. After the spread of anti-vaccine sentiment in two spaces, those who become extremists are those who are not getting vaccinated and the rest of the population get vaccinated.  Those who are not vaccinated get infected once they have at least one of their physical space neighbors get infected. Those who are vaccinated and who are recovered will not be infected. The disease transmission process uses SIR model, which start with randomly choose 2 people to get infected and assumes that every infection gain recovery eventually.

5. The comparison group is to compare the disease transmission results between vaccinate non-extremists (tends to be clustered) and vaccinate same number of people but choose them randomly (tends to be dispersed).

## HOW TO USE IT

Create agents and their cyber network and try different values of two sliders (n-extremists-leaders and sentiment-threshold) and observe consequences in the disease transmission stage (the peak number of people get infected).


## THINGS TO NOTICE

1. What's the difference between vaccinating non-extremists and same number of randomly chosen population? What is the cause of such difference?

2. Is there drastic difference between having small and big number of opinion leaders? How about higher and lower sentiment threshold?


## THINGS TO TRY

1. Number of people connected in the cyber network
2. Keep the sentiment threshold the same, change number of extremists leaders
3. Keep the number of extremists leaders the same, change sentiment threshold


## EXTENDING THE MODEL

One possible extension is to create other typologies of cyber networks (such as small world network or random network). Although social media networks tend to be scale-free like (such as Twitter re-tweet network), other typologies result in different patterns of information flow that has meaningful implications for

## NETLOGO FEATURES

The visualization of the cyber network and physical network: When agents are initiated and the cyber network is created, you can play with different ways of visualizing the agents. The size of the agent symbolize the degree of connection in the cyber network.


## RELATED MODELS

This model is inspired by Marcel Salthe and Sabastian Bonhoeffer's model in effect of opinion clustering on disease outbreaks.

Salathé, Marcel, and Sebastian Bonhoeffer. 2008. “The Effect of Opinion Clustering on Disease Outbreaks.” Journal of The Royal Society Interface 5 (29): 1505–8.


## CREDITS AND REFERENCES

Author: Xiaoyi Yuan
Institution: Computational Social Science at Geoget Mason University
Contact: xyuan5@gmu.edu
Last updated date: Feb 3 2017
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
NetLogo 5.3.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="network_type">
      <value value="&quot;scale free network&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-nodes-connected">
      <value value="2500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-extremists-leaders">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rewiring-probability">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threshold-sentiment">
      <value value="0.95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-links">
      <value value="5000"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles</metric>
    <enumeratedValueSet variable="network_type">
      <value value="&quot;scale free network&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-nodes-connected">
      <value value="2500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-extremists-leaders">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="rewiring-probability">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="threshold-sentiment">
      <value value="0.95"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-links">
      <value value="5000"/>
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

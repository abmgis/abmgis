extensions [gis]
breed [site-agents site-agent]
breed [start-points start-point]

site-agents-own [
  site-information ;; GIS data attributes
  site-arrival     ;; ticks since starting
  ]

patches-own [
  value          ;; this is the quantity we will be diffusing
  ecol-index     ;; ecolocgical favorability index
  adjusted-index ;; ecol-index adjusted for presence of resident for IDD spread
  patchtype      ;; can be suitable or unsuitable
  patch-arrival  ;; ticks since starting
  ]

globals [
  suitable        ;; patches suitable for agriculture
  unsuitable      ;; patches unsuitable for agriculture
  stopsim         ;; stops simulation
  landmap         ;; name of raster file of land for spreading (in ESRI ASCII format)
  sitesfile       ;; name of vector points file of sites (in ESRI shapefile format)
  basemap         ;; GIS base map for setting up world
  patch-size-km   ;; size of patches in real-earth units
  maxindex        ;; maximum value of ecol-index
  sites           ;; GIS sites map
  sitefields      ;; Names of data fields in sites attribute database
  filebase        ;; spread type for base output file name
  startlist       ;; list of xy pairs for starting patches
  use-sites       ;; records information for sites loaded from GIS vector points file
  ]

to setup[filename]
  clear-all
  set startlist [ ]
  set use-sites 0
  ifelse empty? filename [
    setup-world "" ] [
    setup-world filename ; lets raster basemap file be loaded from behavior space or command line
    ]
  set stopsim false
  reset-ticks
end

to setup-world[filename]
  ;; set up virtual world using GIS raster base map

  ifelse empty? filename [
    ;; load raster land basemap
    user-message "Please select raster basemap of land area (*.asc)" ;; loads raster basemap interactively
    set landmap user-file ] [
    set landmap filename ;; lets raster basemap file be loaded from behavior space or command line
    ]

  ;; adjust dimensions of NetLogo world to match match GIS raster base map aspect
  let world-wd 0
  let world-ht 0
  set basemap gis:load-dataset landmap
  let gis-wd gis:width-of basemap
  let gis-ht gis:height-of basemap
  ifelse gis-wd >= gis-ht
    [set world-wd world-max-dim
     set world-ht int (gis-ht * world-wd / gis-wd)]
    [set world-ht world-max-dim
     set world-wd int (gis-wd * world-ht / gis-ht)]
  resize-world 0 world-wd 0 world-ht
  gis:set-world-envelope (gis:envelope-of basemap)
  gis:apply-raster basemap ecol-index
  set maxindex max [ecol-index] of patches

  ;; identify suitable and unsuitable for agriculture on the basis of the ecol-threshold variable and ecol-index
  ;; values derived from raster basemap.
  ;; agriculture cannot spread into areas where ecol-index < ecol-threshold
  ask patches [
    set adjusted-index ecol-index
    set value 0
    ifelse ecol-index >= ecol-threshold
      [set patchtype "suitable"]
      [set patchtype "unsuitable"]
    ]

  ;; determine size of patches in real-world units
  if GIS-grid-cell-km = "" or GIS-grid-cell-km <= 0 [set GIS-grid-cell-km 1] ;; if not specified, default to 1km raster grid cells
  set patch-size-km (gis-wd * GIS-grid-cell-km) / world-wd
  output-print "patch size = " output-type patch-size-km output-print " km in geographic units"

  set unsuitable patches with [patchtype = "unsuitable"] ;; initialize unsuitable patch set (i.e., unsuitable for agriculture)
  ask unsuitable [
    ifelse ecol-index >= 0 or ecol-index <= 0
      [set pcolor grey] ;; color ecologially unsuitable patches grey
      [set pcolor blue] ;; color patches corresponding to null value raster cells blue
    ]

  set suitable patches with [patchtype = "suitable"] ;; initialize suitable patch set (i.e., suitable for agriculture)
  if color-world [ ask suitable [set-shading] ]
end

to set-shading
  ;; this bombs regularly due to a bug in NetLogo AFAICT. But it does not affect the model function, only the display.
  carefully [
    ;; trap randomly occuring error that I don't understand
    ;;set pcolor scale-color green ecol-index maxindex ecol-threshold ;; scale color of suitable from dark (most suitable) to light
    set pcolor scale-color 55 ecol-index maxindex ecol-threshold] [ ;; scale color of suitable from dark (most suitable) to light
    user-message "You need to run setup again"
    stop
  ]


end

to load-sites[filename]
  ;; load GIS vector file of sites and create turtles (site-agents) for each site

  ask site-agents [die] ;; remove previously loaded site data

  ifelse empty? filename [
    user-message "Please select shapefile of sites (*.shp)" ;; loads GIS sites file interactively
    set sitesfile user-file ] [
    set sitesfile filename  ;; lets sites file be loaded from behavior space or command line
    ]

  set sites gis:load-dataset sitesfile
  set sitefields gis:property-names sites
  let feature-list gis:feature-list-of sites

  foreach feature-list [ ?1 ->
    ;; create a site-agent turtle for each GIS vector site
    let sitepoint gis:centroid-of ?1
    let prop-list []
    let this-feature ?1
    foreach sitefields [ ??1 -> ;; iterate through all of the data that corresponsds to each site and make a list that will be handed off to agents
      let prop-field gis:property-value this-feature ??1
      set prop-list lput prop-field prop-list
    ]

    let location gis:location-of sitepoint
    ifelse empty? location [
    ][
    create-site-agents 1 [ ;; initialize an agent to represent a site in the simulation
      setxy item 0 location item 1 location
      set shape "circle"
      set color yellow
      set size 3
      set site-information prop-list
      if [pcolor] of patch-here = blue ;; check to make sure the site is not located in the ocean, useful for sites on the coastline
      [ print "ERROR Site Located in Water"
        print prop-list
        set color red]
      ]
    ]
  ]
  set use-sites 1 ;; sites are loaded so output can be saved
end

to import-start[filename]
  ;; import 1 or more start points for agriculture spread from file of east/north geospatial coordinates
  ;; create a list of xy pairs for starting points

  let startfile ""

  ifelse empty? filename [
    user-message "Please select file of starting points"
    set startfile user-file ] [  ;; load start points interactively
    set startfile filename ;; load start points from BehaviorSpace or the command line
    ]

  file-open startfile

  while [not file-at-end?] [ ;; make a list of starting point coordinate pairs
    let coords (read-from-string file-read-line)
    let startpoints geocoord-to-netlogo item 0 coords item 1 coords
    set startlist lput startpoints startlist
  ]
  file-close
  setup-startpoints
end

to mouse-set-start
  ;; create a list of xy pairs for starting point for agriculture spread by clicking with a mouse
  ;; user needs to click inside the world for anything to happen

  if (mouse-down? and abs mouse-xcor < max-pxcor and abs mouse-ycor < max-pycor ) [
    let startpoints (list mouse-xcor mouse-ycor)
    set startlist lput startpoints startlist
    setup-startpoints
    stop
  ]
end

to setup-startpoints
  ;; set start points for agriculture spread from list of xy coordinate pairs

  let startx 0
  let starty 0

  foreach startlist [ ?1 -> ;; iterate through each xy coordinate pair in the list of starting points
    if (abs item 0 ?1 < max-pxcor and abs item 1 ?1 < max-pycor )  [
      ask patch (item 0 ?1) (item 1 ?1) [ ;; set start point for diffusion
        set value 1
        set ecol-index max [ecol-index] of suitable
        set startx pxcor
        set starty pycor
      ]

      create-start-points 1 [  ;; create a turtle to mark start point for diffusion
        set color red
        set size 5
        set shape "x"
        setxy startx starty
      ]
    ]
  ]
end

to reset-start
  ;; reset the starting points for agriculture spread by clearing the list of xy pairs and killing the turtles

  foreach startlist [ ?1 ->
    ask patch item 0 ?1 item 1 ?1 [set value 0]
  ]
 set startlist [ ]
 ask start-points [die]
end

to reset-spread
  ;; reset spread values without having to reload GIS
  ;; does NOT reset the starting points
  ;; does NOT require re-import of GIS raster and vector data

  ask site-agents [ set site-arrival 0]

  ask suitable [
    set value 0
    set adjusted-index ecol-index
    if color-world [set-shading]
  ]

  setup-startpoints
  set stopsim false
  reset-ticks
end

to spread
  ;; spread control routine

  let before count suitable with [value = 1]

  ;; reset areas where agriculture cannot spread
  ask unsuitable [set value 0]
  ask suitable [
   ifelse value = 0
     [
       ask site-agents-here [set site-arrival ticks]
       set patch-arrival ticks
     ] [ ;; ticks recorded only until agriculture reaches patch
       if ecol-index = 0 [set value 0] ;; spread limited by ecol-index and bad environment
       let threshold random (maxindex + 1)
       ;; spread agriculture to neighboring patches
       if spread-type = "neighborhood" [
         set filebase "neighbor_ecol"
         neighbor-spread threshold
       ]
       if spread-type = "leapfrog" [
         set filebase "leapfrog_ecol"
         leap-frog threshold
       ]
       if spread-type = "IDD" [
         set filebase "IDD_ecol"
         IDD threshold
       ]
       if spread-type = "neighborhood no constraints" [
         set filebase "neighbor"
         neighbor-spread 0
       ]
       if spread-type = "leapfrog no constraints" [
         set filebase "leapfrog"
         leap-frog 0
       ]
       if ticks > 1 [set pcolor scale-color red patch-arrival 0 ticks] ;; color by arrival of spread
     ]
  ]

  ;; automatic stop routine
  let after count suitable with [value = 1]
  if ticks > 9 and after <= before [set stopsim true] ;; give simulation a chance to get started before seeing if it should stop
end

to leap-frog[threshold]
  ;; agriculture can spread to patches at 'leap-distance' from originating cell
  ;; 'leap-distance' may need to be 5 or more cells for this to spread consistently

  ;; pick a cell at a random direction and a random distance within the "leap" radius
  let rdir random 360
  let rdist random leap-distance

  ;; make sure it is a valid patch where agriculture can spread
  if patch-at-heading-and-distance rdir rdist != nobody
    and [patchtype] of patch-at-heading-and-distance rdir rdist = "suitable"
    and [ecol-index] of patch-at-heading-and-distance rdir rdist >= threshold ;; only spread to patch with sufficiently good environment
    [ ask patch-at-heading-and-distance rdir rdist [set value 1]]
end

to IDD[threshold]
  ;; routine for spreading agriculture to "best" neighboring patches within lead-distance - Ideal Despotic Distribution model
  ;; "best" is environmental suitability minus a cost if already occupied = 'adjusted-index'

  let spreadzone patches in-radius leap-distance

  if any? spreadzone with [adjusted-index >= threshold] [ ;; only pick patches with sufficiently good environment
    let best max [adjusted-index] of spreadzone ;; find best patches to spread to, with value diminished by occupation
    ask spreadzone with [adjusted-index = best] [
      set value 1 ;; occupy patch
      set adjusted-index adjusted-index * ((100 - occupied-cost) / 100) ;; diminish suitability for each time occupied
    ]
  ]
end

to neighbor-spread[threshold]
  ;; spread to neighboring patches
  ifelse threshold = 0
  [ask neighbors [set value 1]] ;; spread to all neighboring patchest
  [ask neighbors with [ecol-index >= threshold] [set value 1]] ;; spread to neighboring patches with sufficiently good environment
end

to go
  if stopsim [
    update-arrival
    if save-output [save-data]
    if combined-output [save-bsdata-for-R]
    stop
    ]
;  ask suitable [
;    if value = 1 [set adjusted-index ecol-index - (round ((occupied-cost / 100) * ecol-index))]
;  ]
  spread
  tick
end

to update-arrival
  ;; If spread does not reach a site-agent for some reason,
  ;; it grabs an arrival value from the mean of the neighboring cells so that it is not 0
  foreach (list site-agents) [ ?1 ->
    ask ?1 [
      if site-arrival = 0 [
        set site-arrival mean [patch-arrival] of neighbors
      ]
    ]
  ]

end

to save-data
  if use-sites = 0 [stop] ;; don't save data if sites are not loaded

  let filename (word filebase "_"behaviorspace-run-number"_" date-and-time ".csv")
  file-open filename
  let header ""
  foreach sitefields [ ?1 ->
    set header (word header ?1 ",")
  ]
  set header (word header "arrival,xcoord,ycoord")
  file-print header
  foreach (list site-agents) [ ?1 ->
    ask ?1 [
      foreach site-information [ ??1 ->
        let value-to-print ??1
        ifelse value-to-print = nobody
            [set value-to-print ","]
            [set value-to-print word ??1 ","]

        file-type (value-to-print)
      ]

      file-print (word site-arrival "," xcor "," ycor)
    ]
  ]
  file-close
  output-type "results saved to " output-print filename
end

to save-bsdata-for-R
  if use-sites = 0 [stop] ;; don't save data if sites are not loaded

  let filename (word filebase ".csv")
  file-open filename
  let header ""
  foreach sitefields [ ?1 ->
    set header (word header ?1 ",")
  ]
  if behaviorspace-run-number = 1 [
    set header (word header "arrival,xcoord,ycoord,run")
    file-print header
    ]
  foreach (list site-agents) [ ?1 ->
    ask ?1 [
      foreach site-information [ ??1 ->
        let value-to-print ??1
        ifelse value-to-print = nobody
            [set value-to-print ","]
            [set value-to-print word ??1 ","]

        file-type (value-to-print)
      ]
      file-print (word site-arrival "," xcor "," ycor "," behaviorspace-run-number)
    ]
  ]
  file-close
  output-type "results saved to " output-print filename
end

to-report geocoord-to-netlogo [geox geoy]
  ;; converts geographic coordinate pair to NetLogo coordinate pair in a list
  ;; with thanks to Eric Russell (GIS extension developer)

  let envelope gis:world-envelope ; [ xmin xmax ymin ymax ]
  let xscale (max-pxcor - min-pxcor) / (item 1 envelope - item 0 envelope)
  let yscale (max-pycor - min-pycor) / (item 3 envelope - item 2 envelope)
  let netlogo-x (geox - item 0 envelope) * xscale + min-pxcor
  let netlogo-y (geoy - item 2 envelope) * yscale + min-pycor

  report list netlogo-x netlogo-y
end


; Copyright Michael Barton, Arizona State University, Salvador Pardo Gordo, University of Valencia, & Sean Bergin, Arizona State University, 2013.
@#$#@#$#@
GRAPHICS-WINDOW
185
10
964
595
-1
-1
3.0
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
256
0
191
0
0
1
ticks
30.0

BUTTON
90
195
170
228
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
5
10
85
43
setup world
setup \"\"
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
5
195
85
228
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
5
275
170
320
spread-type
spread-type
"neighborhood" "leapfrog" "IDD" "neighborhood no constraints" "leapfrog no constraints"
0

BUTTON
5
115
170
148
reset spread
reset-spread
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
5
355
170
388
leap-distance
leap-distance
1
20
5.0
1
1
NIL
HORIZONTAL

INPUTBOX
5
460
170
520
world-max-dim
256.0
1
0
Number

INPUTBOX
5
520
170
580
GIS-grid-cell-km
0.77
1
0
Number

BUTTON
5
80
170
113
set start with mouse
mouse-set-start
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
5
320
170
353
occupied-cost
occupied-cost
0
100
5.0
5
1
%
HORIZONTAL

OUTPUT
5
585
170
680
12

SLIDER
5
240
170
273
ecol-threshold
ecol-threshold
0
20
20.0
1
1
NIL
HORIZONTAL

SWITCH
5
390
170
423
save-output
save-output
1
1
-1000

BUTTON
5
45
170
78
import starting points file
import-start \"\"
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
5
150
170
183
reset starting points
reset-start
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
90
10
170
43
setup sites
load-sites \"\"
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
315
625
442
658
color-world
color-world
1
1
-1000

TEXTBOX
450
625
600
666
If color-world automatically is on, the world may fail to load.
11
0.0
1

BUTTON
185
625
307
658
set world color
ask suitable [set-shading]
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
5
425
170
458
combined-output
combined-output
1
1
-1000

@#$#@#$#@
## WHAT IS IT?

This models explores the spread of agriculture. It was designed to carry out experiments in the spread of agriculture to the Iberian peninsula, but could be applied to any other area of the world. This model does not assume a spread of farmers or farming ideas, but simply models the spread of farming practice under variable ecological conditions and with different ways of spreading geographically.

Several different spreading algorithms are available to the user (explained in more detail below). The starting point(s) of the spread of agriculture can be set interactively with a mouse or by importing a text file of xy coordinates (geospatial earth coordinates, not NetLogo world coordinates).

The GIS Extension allows the user to import a raster basemap in which cell values represent the suitability of the associated land for agriculture (applicable in several spread routines), and a vector map of known prehistoric farming sites. The time of arrival of agriculture (in model ticks) is recorded at each site, and site information can be saved at the end of a simulation run. The time of arrival of agriculture at each site in the simulation can then be compared with the real-world arrival of agriculture at the same sites.


## HOW IT WORKS

To set up a simulation, the user first needs to load a raster basemap of the area to be investigated. Optionally, the user can also load a vector points map of sites. The raster and vector map must be in the same geospatial projection.

### Base map
The raster basemap needs to be in ESRI ASCII format to be read by the GIS extension. Each raster cell should have a value that indicates the relative suitability for agriculture. The model assumes that a higher value indicates greater suitability. A slider for <ecol-threshold> can be used to identify the value below which agriculture is not possible. There is a higher probability of agriculture spreading to cells with a higher suitability value than with a lower value. The model automatically scales this probability between the highest value on the map and the threshold value.

### Sites map
The vector points map sites needs to be in ESRI shapfile format. Any associated attribute fields will be used in the output from the simulation.

### Starting points
An origin point or set of points for farming can be set interactively with a mouse or from a text file of geospatial coordinate pairs.

For a coordinates file, the coordinates must be in a geospatial projection recognized by the GIS base map (e.g., longitude/latitude or UTM). Each coordinate pair must be
1) written as east (horizontal or x coordinate) and north (vertical or y coordinate),
2) separated by a space,
3) inside square brackets, and
4) on a new line

For example, if the UTM coordinates for point 1 are 728707 east, 4374094 north, and the coordinates for point 2 are 996073 east 4720022 north, they must be written as:

[728707 4374094]
[996073 4720022]

### Spreading algorithms
Five types of spreading algorithms can be selected. Two these are neighborhood spreading routines.

"Neighborhood" spreading will spread from any patch that has agriculture to neighboring patches that do not already have agriculture and are suitable for agriculture. The probability of spreading to any of these neighboring patches is determined by the relative suitability.

"Leapfrog" spreading will spread from any patch that has agriculture to a randomly selected patch within the radius of a user set <leap-distance> that does not already have agriculture and is suitable for agriculture. Again, the probability of spreading to any of neighboring patch is determined by the relative suitability.

"IDD" spreading simulates the dynamics of "ideal free distribution" and "ideal despotic distribution" models from human behavioral ecology (Abrahams and Healey 1990; Fretwell and Lucas Jr. 1970; McClure et al 2006; Whitehead and ope 1991). Each patch that has agriculture will look for the 'best' neighboring patches--i.e., those that have the highest suitability values of all neighboring patches. Agriculture can spread to a patch that is suitable for agriculture whether or not agriculture already is present in that patch. But each time that agriculture spreads to a patch, it lowers its suitability value by the percentage given in the <occupied-cost> factor (set by the user). Thus, patches that are initially highly suitable for agriculture can become less and less suitable the more often they are occupied, representing an increasingly dense population of farmers using up the most desirable land in a patch.

The two other spreading types are "neighborhood no constraints" and "leapfrog no constraints". These work like the 'constrained versions already described but without taking into account the suitability of the cell for agriculture.

### Saving output
Optionally, the model will save a *.csv file of all sites (if a file of sites has been loaded), showing their identifying field, the time of arrival of agriculture in model ticks, and the xy coordinates of each site. The file is automatically time and date stamped,

## HOW TO USE IT

Select a raster base map (*.asc). Note that the size of the NetLogo world in cells can be set through the world-max-dim entry field. Also, the user can indicate the real world size of the raster cells in the GIS data set with the GIS-grid-cell-km entry field

Optionally, select vector sites map (*.shp), and provide the name of the attribute data field to identify sites.

Set one of more starting points using a mouse or load starting points from a text file of coordinate pairs.

Select a threshold value of the GIS raster data below which agriculture is not possible (This is related to the underlying GIS raster data used to parameterize a simulation).

Select a spreading algorithm. If "leapfrog" is chosen, set the maximum <leap-distance> slider. If "IDD" is chosen, set the <occupy-cost> slider.

Set the <save-output> switch to on if an output csv file of site data is desired.

Press <Go>. At the end of a simulation run, the output will be automatically saved if the <save-output> switch is on and a file of sites has been loaded.

Pressing the <reset-spread> button will return the simulation to its initial state, without reloading the raster or vector files and without resetting the start points.

Pressing the <reset-start> button will remove all starting points. New starting points will have to be set with a mouse or loaded from a file.

### Non-interactive use:
GIS files can be loaded non-interactively in BehaviorSpace or from the command line. Initializing commands take the form of

setup [rasterfilename]
load-sites [vectorfilename]
import-start [startfilename]

where [rasterfilename] is a string of the path to the GIS raster file, [vectorfilename] is a string of the path to the optional GIS vector points file, and [startfilename] is a string of the path to a file with starting points

## THINGS TO NOTICE

If an "IDD" spread algorithm is used, agriculture might not spread if <occupy-cost> is too low. This is because it may provide a greater return and minimal cost to simply increase the use of the initial start patch than to spread to another patch.

## THINGS TO TRY

Compare spreading from multiple start points with spreading from a single start point.

## POTENTIAL ENHANCEMENTS

The "IDD" spread algorithm could be enhanced to take into account existing occupation by foragers or pastoralists.

## HOW TO CITE

[If we put this in the CoMSES Net CML, we can put that citation format here]

## COPYRIGHT AND LICENSE

Copyright 2013 Michael Barton (Arizona State Univesity), Salva Pardo (Universidad de Valencia), & Sean Bergin (Arizona State University)

![CC BY-NC-SA 3.0](http://i.creativecommons.org/l/by-nc-sa/3.0/88x31.png)

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

## REFERENCES

Abrahams, M. V. and M. C. Healey (1990). Variation in the competitive abilities of fishermen and its influence on the spatial distribution of the British Columbia Salmon Troll Fleet. Canadian Journal of Fisheries and Aquatic Sciences 47: 1116-1121.

Fretwell, S. D. and H. L. Lucas Jr. (1970). On territorial behavior and other factors influencing habitat distribution in birds. Acta Biotheoretica XIX: 16-36.

McClure, S., Jochim, M. A., & Barton, C. M. (2006). Behavioral ecology, domestic animals, and land use during the transition to agriculture in Valencia, eastern Spain. In D. Kennett & B. Winterhalder (Eds.), Foraging Theory and the Transition to Agriculture (pp. 197–216). Washingtion, D.C.: Smithsonian Institution Press.

Whitehead, H. and P. L. Hope (1991). Sperm whalers off the Galapagos Islands and in the western North Pacific, 1830-1850. Ideal Free Whalers? Ethnology and Sociobiology 12: 147-161
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

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.0.1
@#$#@#$#@
setup
repeat 10 [ go ]
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment" repetitions="10" runMetricsEveryStep="false">
    <setup>setup "/Users/sbergin/Dropbox/Spain\ Neo\ Model/files/ecologic_mapv2.asc"
setup-sites "/Users/sbergin/Dropbox/Spain\ Neo\ Model/shapes\ and\ document/neolithic_spread_model.shp"</setup>
    <go>go</go>
    <enumeratedValueSet variable="color-world">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="save-output">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment3" repetitions="10" runMetricsEveryStep="false">
    <setup>setup "/Users/sbergin/Dropbox/Spain Neo Model/files 2/ecologic_mapv2.asc"
load-sites "/Users/sbergin/Dropbox/Spain Neo Model/shapes and document/neolithic_spread_model.shp"
reset-spread
reset-start
import-start "/Users/sbergin/Dropbox/Spain Neo Model/files 2/startpoints.txt"</setup>
    <go>go</go>
    <enumeratedValueSet variable="color-world">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="save-output">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Experiment 2 6.11.13" repetitions="50" runMetricsEveryStep="false">
    <setup>setup "/Users/sbergin/Dropbox/Spain Neo Model/Maps and Data/ecol_index.asc"
load-sites "/Users/sbergin/Dropbox/Spain Neo Model/Maps and Data/sites.shp"
reset-spread
reset-start
import-start "/Users/sbergin/Dropbox/Spain Neo Model/coastal_startpoints.txt"</setup>
    <go>go</go>
    <enumeratedValueSet variable="color-world">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spread-type">
      <value value="&quot;leapfrog&quot;"/>
      <value value="&quot;neighborhood&quot;"/>
      <value value="&quot;IDD&quot;"/>
      <value value="&quot;leapfrog no constraints&quot;"/>
      <value value="&quot;neighborhood no constraints&quot;"/>
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
1
@#$#@#$#@

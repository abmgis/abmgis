
extensions [gis nw]
globals [netlogo-meter-conversion netlogo-mile-conversion minutes-per-hour-ratio ; conversion factors
         AOI develop-dataset commercial-dataset VDOT-dataset roads-dataset census-dataset ACS-dataset silver-line silver-line-stops ; data layers
         day hour minutes  ;; time keeper for model
         optimize-am optimize-pm not-commuting am-go pm-go ;; these are to reduce run time of model
         temp-variable
         pop-commuters
         baseline
         mean-opt-commute-minutes
         mean-calc-commute-minutes
         blkcommutersnum
         blkcommuters
         num-commuting

         mean-avg-speed-list
         mean-rel-speed-list
         mean-traffic-effect-list
         mean-time-diff-list

         mean-avg-speed-agg
         mean-rel-speed-agg
         mean-traffic-effect-agg
         mean-time-diff-agg

         mean-link-speed-diff


         ]
patches-own [landarea road? node-count original-color view vertex-here num-commuters newpop]
breed [VDOT-vertices VDOT-vertex]
breed [road-vertices road-vertex]
breed [metro-stop-labels metro-stop-label]
breed [pop-centers pop-center]
breed [commuters commuter]
VDOT-vertices-own [road-name ADT AAWDT maxcap]
road-vertices-own [possible-node in-view linked-to links-to-here feature-number speed-limit road-name VDOT? ADT AAWDT maxcap VDOT-rd blockgroupid start-pop
                   transmodes traffic-count-minute traffic-count-hr traffic-count-day traffic-count-hr-list traffic-count-day-list
                    reston-work-area development bus]
links-own [name posted-speed dist time-min time-secs
           list-of-speeds-now  avg-speed-of-drivers-now
           history-of-avg-speeds hist-mean]

pop-centers-own [blockgroupid road-nodes-contained new
                 ;; ACS metrics
                 commuterpop percent-totcommuters count-blk-commuters
                 ho-units median-earnings
                 comm-out comm-va comm-rest carsolo carpool pubtr bus metro othermode
                 LV5_530 LV530_6 LV6_630 LV630_7 LV7_730 LV730_8 LV8_830 LV830_9 LV9_10]

commuters-own [home-vertex work-vertex ; start and end nodes, used to define commute path
               work-loc ;; patch with work-vertex used to say that you arrived at work
               actual-blockgrp new ;; if on develop
               ;; American Community Survey based attributes
               blockgroupid ;; blockgroup attributes associated with
               earnings ;; normal distribution around median wage for blockgroup
               avg-min-rate ;; average wage rate per min, based on earnings
               work-pl ;; 1=res, 2=VA not res, 3=out of state
               ;; mode of travel
               mode ;; 1-carsolo, 2-carpool, 3-bus, 4-metro, 5-othermode
               mode-pubtr ;; 1 = yes public transit
               ;; time to leave to go to work
               lvtime ;;timeframe to depart for work

               ;; commute start time defined based on lvtime time frame from ACS
               am-commute-start-hour am-commute-start-minute
               pm-commute-start-hour pm-commute-start-minute

               ;; total commute dist, time with no traffic
               tot-opt-commute-dist ;; from user interface
               tot-opt-commute-time ;; from user interface
               tot-opt-commute-costs ;; costs that take into account mileage
               tot-opt-commute-costs-time ;; costs that take into account value of time as well

               ;; commute path and metrics for Reston portion, under no traffic
               commute-path ;; set of nodes to commute
               commute-distance ;; distance of commute path in miles
               opt-commute-minutes ;; optimum time to traverse commute path when no traffic
               opt-commute-avg-speed ;; average speed for commute path based on dist/time
               commute-costs ;; base costs for fares, gas, car etc for the Reston portion

               ;; traffic effects
               traffic-effect ;; ratio of actual distance to intended distance
               actual-commute-minutes ;; actual commute time through Reston
               actual-commute-costs-time ;; costs that incorporate actual commute time

               ;; commute progress so far
               commute-distance-traveled ; miles covered so far in commute
               commute-time-so-far ; minutes covered so far in commute
               opt-commute-time-so-far ; time it should have taken to get this far based on link time value
               calc-commute-minutes ;; calculates estimate of commute time based on progress so far
               diff-in-minutes ;; optimum minus the actual commute time
               avg-speed ; avereage speed of commute so far


               ;; control movement of commuter and also allow passing through multiple nodes in one tick
               status ;; 1=home, 2=am-commute, 3=work, 4=pm-commute
               go-beyond ; 1 for still time to keep going, otherwise 0
               steps ; for incrementing when commuting multiple nodes in one minute
               dist-ahead ; dist for this segment as how far to go this step
               time-traveled ;; for segment

               ;; nodes traveled to
               previous-node current-node next-node

               ;; info about link (segment) to traverse
               link-to-travel ;; used to update congestion effects
               link-speed-limit ;; used in display for relative speed
               link-dist ; used to calculate how much further to next node
               link-time-estimate ; minutes to cover segment

               ;; measures for node level
               dist-traveled-toward-next-node
               distance-remaining-to-next-node
               opt-time-remaining-to-next-node
               opt-time-so-far-toward-next-node
               act-time-so-far-toward-next-node

               ;; measures for minute level
               distance-to-cover-this-minute
               distance-during-this-minute
               time-remaining-for-minute
               time-passed-so-far-in-min

               ;; speed for this segment, mph
               speed-intended ; speed commuter will attempt to go e.g. posted-speed on link from roads in GIS, or controlled speed from interface
               current-speed ; actual speed of the commuter for this past segement based on dist-ahead etc
               relative-speed ; current speed compared to intended

               ]



;;************ SETUP **************************
to setup ;; SETUP (called by button Setup)
  clear-all
  load-gis
  setup-landuse ; comment this out for faster load time - this is the background
  setup-VDOT-data
  setup-roads-and-nodes
  setup-metro
end

  to load-gis  ;; GIS DATA (called by setup)
     set census-dataset gis:load-dataset "Reston_data/reston_census_blocks_simplify_0001.shp" ; block level polygons
     set commercial-dataset gis:load-dataset "Reston_data/commercial_reston.shp" ;; commercial areas polygons
     set develop-dataset gis:load-dataset "Reston_data/development.shp" ;; areas where development is planned for residential

     set silver-line gis:load-dataset "Reston_data/metro_complete.shp" ;lines metro line
     set silver-line-stops gis:load-dataset "Reston_data/metro_stops.shp" ;points metro stops
    ; ;bus stops
    ; ; stop lights

    ;; for full dataset 307x307 netlogo, 6140mx6140m = 20m per patch
    set VDOT-dataset gis:load-dataset "Reston_data/VDOT_roads.shp"; VDOT roads info
    set roads-dataset gis:load-dataset "Reston_data/reston_roads_layer.shp";"Reston_roads.shp" ;lines roads layer


    set ACS-dataset gis:load-dataset "Reston_data/Reston_ACS2013_blockgrps.shp" ; blockgroup polygons with attributes from 2013 ACS 5yr estimates on Reston commuters

    set AOI gis:load-dataset "Reston_data/AOI2.shp" ;bounding boxe of Reston area

    gis:set-world-envelope gis:envelope-of roads-dataset;AOI ; set display extent of view use one of these AOIs

    gis:set-transformation-ds (gis:envelope-of roads-dataset) (list (min-pxcor) (max-pxcor) (min-pycor) (max-pycor))

    set netlogo-meter-conversion precision 10.0045 6 ; multiply netlogo distance and this value to get distance in meters
    set netlogo-mile-conversion precision 0.006217 6 ; multiply netlogo distance and this to get distance in miles
    set minutes-per-hour-ratio precision  0.01667 6 ; mutliple speed (mph) and this value to get distance traveled in 1 tick (where 1 tick = 1 min)

  end

  to setup-landuse ;; LANDUSE (called by setup)
    ;; display background patch color
    ;; from census data landarea ALAND10  larger area darker green
    gis:apply-coverage census-dataset "ALAND10" landarea

    let minval gis:property-minimum census-dataset "ALAND10"
    let maxval gis:property-maximum census-dataset "ALAND10"
    ask patches
     [ifelse (landarea > 0)
       [set pcolor scale-color green landarea maxval minval]
       [set pcolor blue + 2]
      set original-color precision pcolor 3
     ]

  end



  to setup-VDOT-data  ;;
   foreach gis:feature-list-of VDOT-dataset ;; for each road feature in the GIS
     [ [?1] -> let rd-name (gis:property-value ?1 "namelen_LO")
      let AADT1 (gis:property-value ?1 "ADT")
      let AAWDT1 (gis:property-value ?1 "AAWDT")
      let maxcap1 (gis:property-value ?1 "MAXIMUMSCA")

     ;; to create road-vertices NODES
     foreach gis:vertex-lists-of ?1 ; for the road feature, get the list of vertices
       [ [??1] ->
        let previous-node-pt nobody
        let first-node-pt nobody
        foreach ??1  ; for each vertex in road segment feature
         [ [???1] -> let location gis:location-of ???1
          if not empty? location
           [
            ifelse any? VDOT-vertices with [(xcor = item 0 location and ycor = item 1 location) and AAWDT > AAWDT1] ; if there is not a road-vertex here already
             []
             [
             create-VDOT-vertices 1
               [set xcor item 0 location
                set ycor item 1 location
                set road-name rd-name ; takes road name from GIS
                set ADT AADT1 ; takes speed limit from GIS
                set AAWDT AAWDT1 ; takes speed limit from GIS
                set maxcap maxcap1 ; takes speed limit from GIS
                set size 0
                set shape "circle"
                set color red
                set hidden? false ; I comment this out when I want to see the road nodes
                ]
              ]
           ] ] ] ]

end

  to setup-roads-and-nodes  ;; ROADS and NODES (called by setup)
    ;; to display roads as single color
    gis:set-drawing-color gray
    ;gis:draw roads-dataset 1

    ;; to display road as graduated color by speeds
   let minval gis:property-minimum roads-dataset "SPEED_LIMI"
   let maxval gis:property-maximum roads-dataset "SPEED_LIMI"

   foreach gis:feature-list-of roads-dataset ;; for each road feature in the GIS
     [ [?1] -> ;gis:set-drawing-color scale-color orange (gis:property-value ? "SPEED_LIMI") maxval minval
      ;gis:draw ? 1 ; to draw the roads

      ;; get attributes from GIS to assign to road vertices
      let rd-name (gis:property-value ?1 "FULLNAME")
      let sp-lim (gis:property-value ?1 "SPEED_LIMI")
      let bus? (gis:property-value ?1 "BUSROUTE")


     ;; to create road-vertices NODES
     foreach gis:vertex-lists-of ?1 ; for the road feature, get the list of vertices
       [ [??1] ->
        let previous-node-pt nobody
        let first-node-pt nobody
        foreach ??1  ; for each vertex in road segment feature
         [ [???1] -> let location gis:location-of ???1
          if not empty? location
           [
            ifelse any? road-vertices with [xcor = item 0 location and ycor = item 1 location] ; if there is not a road-vertex here already
             []
             [
             create-road-vertices 1
               [set xcor item 0 location
                set ycor item 1 location
                set road-name rd-name ; takes road name from GIS
                set speed-limit sp-lim ; takes speed limit from GIS
                set bus bus? ; if on bus route assign a 1
                set size 0
                set shape "circle"
                set color cyan
                set hidden? false ; I comment this out when I want to see the road nodes

                ;; get attributes about road from VDOT data
                if any? VDOT-vertices-here
                   [let VDOT-here one-of VDOT-vertices-here
                     set VDOT? 1
                     set ADT ([ADT] of VDOT-here)
                     set AAWDT ([AAWDT] of VDOT-here)
                     set maxcap ([maxcap] of VDOT-here)
                     set VDOT-rd ([road-name] of VDOT-here) ; for double-checking, note inconsistent with spelling out LANE or LN for example
                   ]
                ]
              ]

              ;; create link to previous node
              let node-here (road-vertices with [xcor = item 0 location and ycor = item 1 location]) ; get the node here
              ifelse previous-node-pt = nobody
                 [set first-node-pt node-here] ; first vertex in feature
                 [let who-node 0
                  let who-prev 0
                   ask node-here
                    [create-link-with previous-node-pt ; create link to previous node
                      set who-node who]
                  ask previous-node-pt [set who-prev who]
                  ask link who-node who-prev [set name rd-name set posted-speed sp-lim] ; to get name and speed from GIS
                  ]
              set previous-node-pt one-of node-here

         ] ] ] ]
      ask links ; update attributes of road links and linked nodes
         [let endpoint1 end1
          let endpoint2 end2
          let link-distance 0
          ask end1 [ set linked-to endpoint2 ; update point to say who it is connected to for ref
                    set link-distance distance endpoint2] ; calc distance of link in netlogo units
          ask end2 [set linked-to endpoint1] ; update point to say who it is connected to for ref

          ;; set up attributes
          set dist precision (link-distance * netlogo-mile-conversion) 6; convert netlogo distances to miles
          set time-min precision ((dist / posted-speed) / minutes-per-hour-ratio) 6 ; time in minutes to travel segment at posted-speed
          set time-secs precision (time-min * 60) 2 ; time in seconds to travel segment at posted-speed
          set hidden? false
          set list-of-speeds-now []
          set history-of-avg-speeds []
          set thickness 1
          ]

  ask road-vertices with [linked-to = 0] [die] ; removes the few vertices along view edges that don't connect to anything

  ask road-vertices
    [;set links-to-here (count road-vertices with [linked-to = myself])
     set links-to-here (count link-neighbors)
      ]

  ask patches [set node-count (count road-vertices-here) set vertex-here one-of road-vertices-here] ; for debugging
    ;; to display roads as single color
   ; gis:set-drawing-color gray
   ; gis:draw roads-dataset 1



 ;; assign road-vertices that fall within commercial area of reston
    foreach gis:feature-list-of commercial-dataset
      [ [?1] -> ask road-vertices [if gis:contained-by? self  ?1 [set reston-work-area 1]] ]

  end

  to setup-metro  ;; METRO (called by setup)
    ;; to display metro line
    gis:set-drawing-color black
    gis:draw silver-line 1

    ;; to display metro line stops and labels
    foreach gis:feature-list-of silver-line-stops
     [ [?1] -> gis:set-drawing-color black
      gis:fill ?1 3.0
      let location gis:location-of (first (first (gis:vertex-lists-of ?1)))
       if not empty? location
        [create-metro-stop-labels 1
          [set xcor (item 0 location - 2)
           set ycor (item 1 location - 9)
           set size 0
           set label-color black
           set label gis:property-value ?1 "NAME" ] ] ]
  end





;;************** CREATE COMMUTERS ***********************

to setup-commuters
    clear-all-plots
    clear-output

    set pop-commuters 0
    set minutes 0
    set hour 0
    set day 0

    ask pop-centers [die]
    ask commuters [die]
    ask patches [set num-commuters 0]
    ask links [set color gray set thickness 1 set hist-mean posted-speed]
    set mean-link-speed-diff 0


         set mean-avg-speed-list []
         set mean-rel-speed-list []
         set mean-traffic-effect-list []
         set mean-time-diff-list []

         set mean-avg-speed-agg 0
         set mean-rel-speed-agg 0
         set mean-traffic-effect-agg 0
         set mean-time-diff-agg 0


    set mean-opt-commute-minutes 0
    set mean-calc-commute-minutes 0

    setup-pop-centers
    make-commuters
    assign-destination
    assign-commute-path
    assign-commute-costs

   ask commuters [set size 5]

    set minutes 0
    set hour 0
    set day 1

    set pop-commuters count commuters

   ;; congestion effects display
   ask links [set list-of-speeds-now [] set avg-speed-of-drivers-now posted-speed set history-of-avg-speeds [] set hist-mean posted-speed] ;initialize list values


   reset-ticks


   update-display



end



;; CREATE THE POPULATION CENTERS AS CENTER OF BLOCK GROUP
;; Data from ACS 2013 5yr from census bureau

  to setup-pop-centers ;; create pop center at center of each block

    foreach gis:feature-list-of ACS-dataset
      [ [?1] ->
      ;; identify road-vertices within blockgroups
      let count-nodes 0
      let id (gis:property-value ?1 "BLOCKGRP")
      ask road-vertices [if gis:contained-by? self  ?1 [set count-nodes (count-nodes + 1) set blockgroupid id]]

      ;; assign attributes to center point of polygon of block-group
      let center gis:centroid-of ?1
      let center-location gis:location-of center
      if not empty? center-location
        [create-pop-centers 1
          [set xcor (item 0 center-location)
          set ycor (item 1 center-location)
          set size 0
          set blockgroupid (gis:property-value ?1 "BLOCKGRP")
          set median-earnings (gis:property-value ?1 "MEDEARN")
          set commuterpop (gis:property-value ?1 "COMMUTER")
          set percent-totcommuters 0 ;; calculated after commuters made
          set count-blk-commuters 0 ;; calculated after commuters made
          set ho-units (gis:property-value ?1 "HO_UNITS")
          ;; values below stored as ratio of commuter population for this block
          set comm-out ((gis:property-value ?1 "COMMOUT") / commuterpop)
          set comm-va ((gis:property-value ?1 "COMMVA") / commuterpop)
          set comm-rest ((gis:property-value ?1 "COMMREST") / commuterpop)

          set carsolo ((gis:property-value ?1 "CARSOLO") / commuterpop)
          set carpool ((gis:property-value ?1 "CARPOOL") / commuterpop)
          set pubtr ((gis:property-value ?1 "PUBTR") / commuterpop)
          set bus ((gis:property-value ?1 "BUS") / commuterpop)
          set metro ((gis:property-value ?1 "SUBWAY") / commuterpop)
          set othermode ((gis:property-value ?1 "OTHERTOT") / commuterpop)

          set LV5_530 ((gis:property-value ?1 "LV5_530") / commuterpop)
          set LV530_6 ((gis:property-value ?1 "LV530_6") / commuterpop)
          set LV6_630 ((gis:property-value ?1 "LV6_630") / commuterpop)
          set LV630_7 ((gis:property-value ?1 "LV630_7") / commuterpop)
          set LV7_730 ((gis:property-value ?1 "LV7_730") / commuterpop)
          set LV730_8 ((gis:property-value ?1 "LV730_8") / commuterpop)
          set LV8_830 ((gis:property-value ?1 "LV8_830") / commuterpop)
          set LV830_9 ((gis:property-value ?1 "LV830_9") / commuterpop)
          set LV9_10  ((gis:property-value ?1 "LV9_10") / commuterpop)

          ;; select road nodes that act as residential locations within block group and assign value for population count
          let commpop (gis:property-value ?1 "COMMUTER")
          set road-nodes-contained count-nodes
          let count-end-nodes (count road-vertices with [blockgroupid = id and links-to-here = 1])
          ifelse count-end-nodes > 0
             [ask road-vertices with [blockgroupid = id and links-to-here = 1][set start-pop (round (commpop / count-end-nodes))] ]
             [if road-nodes-contained > 0 [ask road-vertices with [blockgroupid = id] [set start-pop round (commpop / count-nodes )]]]

          ]
        ]
     ]
  end



;; MAKE COMMUTER POPULATION

  to make-commuters
   ;; create commuters on residential road-vertices

  ;; if development is on, color patches of new development
  ;; create new pop centers
  if develop? = true
    [
      gis:apply-coverage develop-dataset "NEWPOP" newpop

      foreach gis:feature-list-of develop-dataset
         [ [?1] ->
          ask road-vertices [if gis:contained-by? self  ?1 [set development 1]]

          let id (gis:property-value ?1 "BLOCKGRP")
          let units (gis:property-value ?1 "NEWPOP")
          let center gis:centroid-of ?1
          let center-location gis:location-of center
          if not empty? center-location
          [create-pop-centers 1
             [set xcor (item 0 center-location)
              set ycor (item 1 center-location)
              set new 1
              let commuters-per-unit 1.25
              ask min-one-of road-vertices [distance myself]
                [hatch-commuters round ((units * commuters-per-unit) * (pop-size / 100))
                    [set actual-blockgrp id
                    set home-vertex one-of road-vertices-here
                    ;set blockgroupid 510594812021 ;; inherit attributes from this blockgroup which is most similar to pop properties
                    set shape "circle"
                    set color 13
                    set new 1
                    set status 1
                    ;set size 5
                    ]
                  ]
                ]
             ]
          ask pop-centers with [new = 1] [die]
          ]
         ]


  ask pop-centers
     [let blkpop 0  let blkgrp 0  set blkgrp blockgroupid
      set blkpop round ((pop-size / 100) * commuterpop)
      hatch-commuters round blkpop ;; user input of percent of pop to model from "pop-size" slider
          [set blockgroupid blkgrp set size 0 set shape "circle"]
       ]

    ask commuters with [new = 0]
        [move-to one-of road-vertices with [blockgroupid = blockgroupid and start-pop > 0 and reston-work-area = 0]
         set home-vertex one-of road-vertices-here
         ]

    ask pop-centers
        [ let tot-commuters count commuters with [new = 0]
          set count-blk-commuters count (commuters with [blockgroupid = [blockgroupid] of myself])
          set percent-totcommuters (count-blk-commuters / tot-commuters)
          set blkcommutersnum count-blk-commuters ;; count of commuters with same blockgroup id
           set blkcommuters commuters with [blockgroupid = [blockgroupid] of myself] ;; set of commuters with same blockgroup id

          assign-attributes-from-ACS
         ]

  if develop? = true
   [
    ;; for new development areas, assign attributes based on this block group
      ask pop-centers with [blockgroupid = 510594812021]
        [
           set blkcommutersnum count commuters with [new = 1] ;; count of commuters with same blockgroup id
           set blkcommuters commuters with [new = 1] ;; set of commuters with same blockgroup id

          assign-attributes-from-ACS
        ]
   ]
        ;; globals to optimize model run time
      set optimize-am (min [am-commute-start-hour] of commuters)
      set optimize-pm ( min [pm-commute-start-hour] of commuters)

  end



 ;; ASSIGN COMMUTE CHARACTERISTICS based on ACS data

   to assign-attributes-from-ACS


         ;; SET EARNINGS (commuters that work : 3-out of state, 2-in state but not Reston, 1-Reston)
            ask blkcommuters [set earnings random-normal [median-earnings] of myself 1 ;; uses median income of blockgroup to assign value as normal distr
                              set avg-min-rate (((earnings / 52) / 40) / 60) ;; 52 weeks a year, 40 hours a week (pre tax)
                              ]

         ;; SET WORK PLACE (commuters that work : 3-out of state, 2-in state but not Reston, 1-Reston)
            if (comm-out * blkcommutersnum) >= 1 [ask n-of (comm-out * blkcommutersnum) blkcommuters [set work-pl 3]] ;; OUT OF STATE
            if (comm-rest * blkcommutersnum) >= 1 [ask n-of (comm-rest * blkcommutersnum) blkcommuters [set work-pl 1]] ;; RESTON
            ask blkcommuters with [work-pl = 0] [set work-pl 2] ;; VA but not Reston

         ;; SET MODE (1-carsolo, 2-carpool, 3-bus, 4-metro, 5-other)
            if (metro * blkcommutersnum) >= 1 [ ask n-of (metro * blkcommutersnum) blkcommuters with [work-pl > 1] [set mode 4 set mode-pubtr 1] ];; if metro you work outside of reston
            if (bus * blkcommutersnum) >= 1 [ask n-of (bus * blkcommutersnum) blkcommuters with [mode = 0] [set mode 3 set mode-pubtr 1]] ;;
            if (othermode * blkcommutersnum) >= 1 [ask n-of (othermode * blkcommutersnum) blkcommuters with [mode = 0] [set mode 5] ];; if you take other mode (walk, bike assume work in Reston)
            if (carpool * blkcommutersnum) >= 1 [ask n-of (carpool * blkcommutersnum) blkcommuters with [mode = 0] [set mode 2]]
            ;;if (carsolo * blkcommutersnum) >= 1 [ask n-of (carsolo * blkcommutersnum) blkcommuters with [mode = 0] [set mode 1]]
            ask blkcommuters with [mode = 0] [set mode 1] ;; set remaining as carsolo

         ;; ASSIGN COMMUTE START TIME FRAME
           if (LV5_530 * blkcommutersnum) >= 1 [ask n-of (LV5_530 * blkcommutersnum) blkcommuters [set am-commute-start-hour 5 set am-commute-start-minute random 30 set lvtime 1]];;random-normal 15 1  ]
           if (LV530_6 * blkcommutersnum) >= 1 [ask n-of (LV530_6 * blkcommutersnum) blkcommuters with [am-commute-start-hour = 0] [set am-commute-start-hour 5 set am-commute-start-minute ((random 30) + 30) set lvtime 2]]
           if (LV6_630 * blkcommutersnum) >= 1 [ask n-of (LV6_630 * blkcommutersnum) blkcommuters with [am-commute-start-hour = 0][set am-commute-start-hour 6 set am-commute-start-minute random 30 set lvtime 3]]
           if (LV630_7 * blkcommutersnum) >= 1 [ask n-of (LV630_7 * blkcommutersnum) blkcommuters with [am-commute-start-hour = 0][set am-commute-start-hour 6 set am-commute-start-minute ((random 30) + 30) set lvtime 4]]
           if (LV7_730 * blkcommutersnum) >= 1 [ask n-of (LV7_730 * blkcommutersnum) blkcommuters with [am-commute-start-hour = 0][set am-commute-start-hour 7 set am-commute-start-minute random 30 set lvtime 5]]
           if (LV730_8 * blkcommutersnum) >= 1 [ask n-of (LV730_8 * blkcommutersnum) blkcommuters with [am-commute-start-hour = 0][set am-commute-start-hour 7 set am-commute-start-minute ((random 30) + 30) set lvtime 6]]
           if (LV8_830 * blkcommutersnum) >= 1 [ask n-of (LV8_830 * blkcommutersnum) blkcommuters with [am-commute-start-hour = 0][set am-commute-start-hour 8 set am-commute-start-minute random 30 set lvtime 7]]
           if (LV830_9 * blkcommutersnum) >= 1 [ask n-of (LV830_9 * blkcommutersnum) blkcommuters with [am-commute-start-hour = 0][set am-commute-start-hour 8 set am-commute-start-minute ((random 30) + 30) set lvtime 8]]
           if (LV9_10 * blkcommutersnum)  >= 1 [ask n-of (LV9_10 * blkcommutersnum) blkcommuters with [am-commute-start-hour = 0][set am-commute-start-hour 9 set am-commute-start-minute random 60 set lvtime 9]]
           ask blkcommuters with [am-commute-start-hour = 0][set lvtime 10] ;; commute not in window of interest

    end


 ;; ASSIGN WORK LOCATION / OR DESTINATION WHERE LEAVE MODEL

  to assign-destination
   ;; WORK OUT OF STATE (assume you take metro or toll road)
         ask commuters with [work-pl = 3]
            [if mode = 4 [set work-vertex (road-vertex 4895)] ;; metro
             if work-vertex = 0 [set work-vertex (road-vertex 4099)] ;; toll road  or just ask carsolos to take toll road (mode = 1 )
             ]
   ;; WORK IN STATE but not Reston
        ;; METRO
         ask commuters with [work-pl = 2] [if mode = 4 [set work-vertex (road-vertex 4895)]] ;; METRO

         ;; CAR (although includes bus, other, carpool for now as well too)
           ;; Assign exit of Reston on one of roads in proportion based on Virginia DOT data
           let commuteoutbycar (commuters with [work-pl = 2 and work-vertex = 0]) ; mode = 1])  ;; set of commuters who work in state and go by car
           let count-commuteoutbycar count commuteoutbycar ;; count of commuters who work in state and go by car
         ;; SOUTH
            ask n-of (.2 * count-commuteoutbycar)  commuteoutbycar [set work-vertex (road-vertex 5557)]  ;; FFX PKWAY
            ask n-of (.2 * count-commuteoutbycar)  commuteoutbycar [set work-vertex (road-vertex 3134)]  ;; RESTON PKWAY
            ask n-of (.06 * count-commuteoutbycar)  commuteoutbycar [set work-vertex (road-vertex 4606)] ;; LAWYERS
         ;; WEST
            ask n-of (.01 * count-commuteoutbycar)  commuteoutbycar [set work-vertex (road-vertex 4440)]  ;; BARON CAMERON
            ask n-of (.01 * count-commuteoutbycar)  commuteoutbycar [set work-vertex (road-vertex 4776)] ;; SPRING ST
            ask n-of (.01 * count-commuteoutbycar)  commuteoutbycar [set work-vertex (road-vertex 3434)]  ;; TOLL RD
            ask n-of (.01 * count-commuteoutbycar)  commuteoutbycar [set work-vertex (road-vertex 3638)] ;; SUNRISE VALLEY
         ;; NORTH
         ;; EAST
            ask commuteoutbycar with [work-vertex = 0] [set work-vertex (road-vertex 4099)] ;; TOLL RD
   ;; WORK IN RESTON
      ask commuters with [work-pl = 1]
       [;; let reston-work-locs 0
        ;; let place 0
        ;; set reston-work-locs road-vertices with [reston-work-area = 1]
        ;; set place one-of reston-work-locs
        ;; let pl-who [who] of place
        ;; set work-vertex one-of road-vertices with [who = pl-who] ;; for whatever reason this work-vertex doesn't work right when calculating commute path
        set work-vertex (road-vertex 3725) ;; city center for simplicity
         ]

    ask commuters with [work-vertex = 0] [die] ;; if not assigned a work-vertex, remove from model

    ;; FOR TESTING, ask all to go to same place
   ;; ask commuters [set work-vertex (road-vertex 4104)]



end



      ;; ASSIGN COMMUTE PATH

  to assign-commute-path
   ;; update some attributes
      ask commuters
         [  set speed-intended 1 ;; if 0 then you get errors in other processes
             ask work-vertex [set temp-variable patch-here]
             set work-loc temp-variable ;; set place where work is located so know when arrived at work

         ;; redundant for testing set hour to 0 and minute to 1 or lvtime, this is actually set up above
             set am-commute-start-hour 0;
             set am-commute-start-minute 1;lvtime;1;random 5 + 1 ;lvtime ;1
             set pm-commute-start-hour round (random-normal 17 1)
             set pm-commute-start-minute random 60
          ]
        ;; redundant for testing
        set optimize-am (min [am-commute-start-hour] of commuters)
        set optimize-pm ( min [pm-commute-start-hour] of commuters)

   ;; ASSIGN COMMUTE PATH
     ask commuters
         [
          set current-node home-vertex ;one-of road-vertices-here
          set previous-node current-node
          set next-node current-node

        ;; assign  Commmute Path based on user display
           let end-loc work-vertex
           ;let path 0 ; netlogo 5_1 initial list
           let path []; netlogo 6_0 initialize list
           let commute-links 0
           if optimize-commute = "Time" ;; "Time"
                 [ask home-vertex [set path nw:turtles-on-weighted-path-to end-loc "time-secs"]
                  if path = [] [die] ; if not on a route connected or to short commute then remove
                  if path = false [die]; added due to netlogo 6_0
                  if length path < 3 [die] ; number of nodes in path ; original code netlogo 5_1
                  set commute-path path ;best-commute-time-path
                  ask home-vertex [set commute-links nw:weighted-path-to end-loc "time-min"] ;; get links of commpath
                   ]
           if optimize-commute = "Distance"
                  [ask home-vertex [set path nw:turtles-on-weighted-path-to end-loc "dist"] ; assigns commuter the fastest path to end-location (although we know not everyone uses this)
                  if path = [] [die] ; if not on a route connected or to short commute then remove
                  if path = false [die]; added due to netlogo 6_0
                  if length path < 3 [die]
                   set commute-path path
                   ask home-vertex [set commute-links nw:weighted-path-to end-loc "dist"]
                   ]
           ;; calculate commute time and distance and avg speed based on commute path
            let time 0
            let comm-dist 0
            foreach commute-links
               [ [?1] -> let link-time 0
                let link-distance 0 ;precision 0 6
                 ask ?1 [set link-time time-min set link-distance precision dist 6]
                 set time time + link-time
                 set comm-dist precision (comm-dist + link-distance) 6
                ]
         ;; Commute Path measures
         set opt-commute-minutes precision time 4
         set commute-distance precision comm-dist 6
         set opt-commute-avg-speed precision (commute-distance / (opt-commute-minutes * minutes-per-hour-ratio )) 2

         if mode = "othermode" [set opt-commute-minutes ((commute-distance / 2 ) / minutes-per-hour-ratio) set opt-commute-avg-speed 2] ;; for walkers
         ]

     if reduce-cars = true
       [ask commuters with [work-pl = 1 and mode = "carsolo"]
           [ if commute-distance < 1
                [set mode othermode
                 set opt-commute-avg-speed 2
                 set opt-commute-minutes ((commute-distance / 2 ) / minutes-per-hour-ratio)
                ]
             if [bus] of home-vertex = 1
               [set mode bus]
           ]


       ]

  end


  ;; ASSIGN ONE-WAY COMMUTE COSTS

  to assign-commute-costs
    ask commuters
      [
      ;; Assign one-way commute costs
         ;; Reston portion of commute or workers in Reston
         if mode < 3 [set commute-costs ((base-car-cost + (gas-price / avg-mpg)) * commute-distance)] ;; if go by car or carpool
         if mode = 2 [set commute-costs (commute-costs / 2)] ;; if go by carpool divide by 2
         if mode = 3 [set commute-costs bus-fare] ;; if go by bus
         if mode = 4 [set commute-costs metro-fare] ;; if go by metro, most take bus also
         if mode = 5 [set commute-costs 0] ;; assume pedestrian
         ;; if go by Toll Road in car, add tolls
         if (mode < 3 and (work-vertex = (road-vertex 4104) or work-vertex = (road-vertex 3438))) [set commute-costs (commute-costs + car-tolls)] ;; if go by car and toll road and in toll fees

         ;; Incorporate average total trip mileage and time from user interface
         if (mode < 3 and work-pl > 1)  [set tot-opt-commute-dist random-normal car-trip 1 set tot-opt-commute-time ((tot-opt-commute-dist / 50) * 60)];; car outside of Reston, time based on 50mph
         if mode = 3 [set tot-opt-commute-time random-normal bus-trip 1] ;; if go by bus or metro, incorporate time of average commute
         if mode = 4 [set tot-opt-commute-time random-normal metro-trip 1]
         if mode = 5 [set tot-opt-commute-time opt-commute-minutes  set tot-opt-commute-dist commute-distance] ;; if go by pedestrian (assume stay in Reston)

         ;; for car trip outside of reston, add in cost per distance e.g. tot gas price per mile
         if (mode < 3 and work-pl > 1) [set tot-opt-commute-costs ((base-car-cost + (gas-price / avg-mpg)) * tot-opt-commute-dist)] ;; adds in gas per mile and base car price for total commute distance
         if (mode = 2 and work-pl > 1) [set tot-opt-commute-costs (tot-opt-commute-costs / 2)] ;; if go by carpool divide by 2
         if tot-opt-commute-costs = 0  [set tot-opt-commute-costs commute-costs] ;; all others either in Reston or no extra costs based on miles

         ;; add in value of time
         ;; to add in cost of of time as percent of hourly wage rate per minute
         set tot-opt-commute-costs precision tot-opt-commute-costs 2
         let cost-of-time (tot-opt-commute-time * (avg-min-rate * (value-of-time / 100)))
         set tot-opt-commute-costs-time precision (tot-opt-commute-costs + cost-of-time) 2

          ]
  end



 ;;************ MOVE COMMUTERS and CONTROL TIME *****************

  to update-time ; time of day check (called by procedures to move commuters)
     ;; ticks are like julian minutes
      tick

     ;; calc day, time as hours and minutes on 24 hour clock
      set minutes minutes + 1 ;
      ifelse hour = 23 and minutes = 60
          [set day day + 1 set hour 0 set minutes 0]
          [if minutes = 60 [set hour hour + 1 set minutes 0]]
  end



 to go-directed ;; MAIN PROCEDURE TO ENABLE COMMUTERS TO GO, VIA DIRECTED PATH called by Button
   ;; to optimize running time, check status of all commuters, if all at home or work set not comuting to 1
     ifelse all? commuters [status = 1] or all? commuters [status = 4] ;; using any? resulted in much slower so must use all?
       [set not-commuting 1] ;all at home or work
       [set not-commuting 0] ; some are commuting

   ;; tick and update time
     update-time


     set num-commuting count commuters with [status = 2 or status = 4]

     ask links [ set history-of-avg-speeds fput avg-speed-of-drivers-now history-of-avg-speeds
                  set list-of-speeds-now [] set avg-speed-of-drivers-now posted-speed] ;reset links speed of commuter every minute

    ask road-vertices [set traffic-count-hr traffic-count-hr + traffic-count-minute
                       set traffic-count-day traffic-count-day + traffic-count-minute
                       set traffic-count-minute 0]

   ;; to optimize, only ask commuters to commute if during commute times to speed up processing - this saves 10-15secs per run for a full day's simulation
    ifelse (hour >= optimize-am or not-commuting = 0) [set am-go 1] [set am-go 0]
    ifelse (hour >= optimize-pm or not-commuting = 0) [set pm-go 1] [set pm-go 0]


   ;; to enable movement of commuters

    if am-go = 1 or pm-go = 1 ; if in the commute time frame - this is to enable faster model run
      [


       ask commuters
        [ ;; check to see if it is my commute time, if so update status  and get commute route
         if am-commute-start-hour = hour and am-commute-start-minute = minutes
             [set status 2];
         if pm-commute-start-hour = hour and pm-commute-start-minute = minutes
             [set status 4]

          if status = 2 and current-node = work-vertex [set status 3 set size 0] ; if arrived at work
          if status = 4 and current-node = home-vertex [set status 1 set size 0] ; if arrived at home

         if reduce-cars = TRUE [ask commuters with [mode = "bus" or mode = "othermode"] [move-to work-vertex set status 3] ]

         ;; if it is commute time then start
         if status = 2 or status = 4 ; 2 is ready for am commute 4 is ready for pm commute
          [


           set time-remaining-for-minute precision 1 6 ; initialize time for commuter



           ;; this is how the commuters go
           if ticks = 1 [get-directed-next-node-and-link]
           identify-how-far-to-go-based-on-speed-and-time

           if link-to-travel = 0 [die]
           move-to-new-location
           update-info
           get-directed-next-node-and-link


            ;; to go through multiple
             ;; loop to do until reach one-minute
             set steps 0
             while [go-beyond = 1] ;[distance-to-cover-this-minute-in-one-minute > dist-traveled]; to enable loop for when need to cover multiple nodes e.g. partway = 2
              [set steps steps + 1 ; will also be helpful when many locations w/in one minute but not accurate
               identify-how-far-to-go-based-on-speed-and-time
               if link-to-travel = 0 [die]
               move-to-new-location
               update-info
               get-directed-next-node-and-link
               if current-node = work-vertex [set go-beyond 0 set steps 0 set status 3 stop] ;; arrived at work
               if steps = 50 [set go-beyond 0 move-to next-node stop] ;print "stopped short" print who print time-remaining-for-minute  ] ; for debugging
               ]


            ;; clear out every tick
             set distance-during-this-minute 0
             set distance-to-cover-this-minute 0

             set time-traveled 0
             set time-remaining-for-minute 0
             set time-passed-so-far-in-min 0
            ]
           ]
          ]

            ifelse any? commuters with [status = 2]
              [set mean-opt-commute-minutes mean [opt-commute-time-so-far] of commuters with [status = 2]
               let mean-traffic-impact ((mean [traffic-effect] of commuters with [status = 2]) )
               let mean-calc-minutes (mean [commute-time-so-far] of commuters with [status = 2])
               set mean-calc-commute-minutes mean-calc-minutes + (mean-calc-minutes * mean-traffic-impact)

                 ]
              []

         if any? commuters with [status = 2 or status = 4]
         [
         let mean-avg-speed-now mean [avg-speed] of commuters with [status = 2 or status = 4]
         let mean-relative-speed-now mean [relative-speed] of commuters with [status = 2 or status = 4]
         let mean-traffic-effect-now mean [traffic-effect] of commuters with [status = 2 or status = 4]
         let mean-time-diff-now mean [diff-in-minutes] of commuters with [status = 2 or status = 4]

         set mean-avg-speed-list  fput mean-avg-speed-now mean-avg-speed-list
         set mean-rel-speed-list  fput mean-relative-speed-now mean-rel-speed-list
         set mean-traffic-effect-list  fput mean-traffic-effect-now mean-traffic-effect-list
         set mean-time-diff-list  fput mean-time-diff-now mean-time-diff-list

         set mean-avg-speed-agg mean mean-avg-speed-list
         set mean-rel-speed-agg mean mean-rel-speed-list
         set mean-traffic-effect-agg mean mean-traffic-effect-list
         set mean-time-diff-agg mean mean-time-diff-list
         ]

         ask links [if length history-of-avg-speeds > 0 [set hist-mean mean history-of-avg-speeds]]


         let diff-list []
         ask links with [(posted-speed - hist-mean) > 5]
           [let diff posted-speed - hist-mean
           set diff-list fput diff diff-list]
         if  not empty? diff-list [set mean-link-speed-diff mean diff-list]

   update-display
  end


;; PROCESSES THAT ALLOW COMMUTERS TO GO


  to identify-next-node-and-link  ;; get next node and distance between previous and next nodes
     ;; if you have reached your next-node, pick a new node for next-node
     if [vertex-here] of patch-here = next-node ; this is issue for the 5 with 2 nodes
          [
           ;; update current-node and pick next-node
           set current-node one-of road-vertices-here
           ask current-node [ask link-neighbors [set possible-node 1]] ; next node is one of link-neighbors, but not the one just visited
           ask previous-node [set possible-node 0]
           ask current-node [set possible-node 0]
           set next-node one-of road-vertices with [possible-node = 1]

           if next-node = nobody [set next-node previous-node] ; need this for the few dead-ends, go back

           ;; get the next link to travel
           let node1 [who] of current-node
           let node2 [who] of next-node

           set link-to-travel (link node1 node2) ; identifies the link to travel next

          ;; if link-to-travel = 0 [print "no-link" stop] ; for debugging because couldn't find link

           ;; get attributes of link
           set link-dist precision [dist] of link-to-travel 6 ; distance in miles for this segment
           set link-speed-limit [posted-speed] of link-to-travel ; posted speed limit for this segment
           set link-time-estimate precision ([time-min] of link-to-travel) 6 ; time in minutes at posted speed to travel segment

           ;; reset these values so can get ready to travel towards new next-node
           set distance-remaining-to-next-node link-dist
           set dist-traveled-toward-next-node 0
           set act-time-so-far-toward-next-node 0
           ask road-vertices with [possible-node = 1] [set possible-node 2]
          ]

  end


 to get-directed-next-node-and-link

       if [vertex-here] of patch-here = next-node  or current-node = next-node; this is issue for the 5 with 2 nodes
       [
        ; set current-node next-node
         if current-node = work-vertex [stop]

        ;; commute to one node at a time by getting the list item number for current location, then grab next location in commute-path
          let route-length (length commute-path)
          let next-pos ((position (current-node) commute-path) + 1)

          if next-pos < route-length
            [set next-node item (next-pos) commute-path]


          ;; get link to travel next
           let node1 [who] of current-node
           let node2 [who] of next-node
           set link-to-travel (link node1 node2) ; identifies the link to travel next


           ;; get attributes of link
           ifelse link-to-travel = 0 or link-to-travel = nobody
               [die] ; if can't find link

               [
                set link-dist precision [dist] of link-to-travel 6 ; distance in miles for this segment
                set link-speed-limit precision [posted-speed] of link-to-travel 2 ; posted speed limit for this segment
                set link-time-estimate precision ([time-min] of link-to-travel) 4 ; time in minutes at posted speed to travel segment

                ;; reset these values so can get ready to travel towards new next-node
                set distance-remaining-to-next-node precision link-dist 6
                set opt-time-remaining-to-next-node precision link-time-estimate 4
                set opt-time-so-far-toward-next-node 0
                set dist-traveled-toward-next-node 0
                set act-time-so-far-toward-next-node 0

           ]
         ]

 end


  to identify-how-far-to-go-based-on-speed-and-time
         ;; set commuter speed


           if to-control-speed = "Constant speed" ;gets speed from interface
               [set speed-intended set-constant-speed]
           if to-control-speed = "Posted speed limit" ; get speed limit from GIS
               [
                 ifelse link-to-travel = 0 or link-to-travel = nobody [];print who die]
                     [
                       set speed-intended link-speed-limit ; precision [posted-speed] of link-to-travel 2
                     ] ;
               ]

         ;; calc distance to cover based on speed and time remaining in minute
           set distance-to-cover-this-minute precision (speed-intended * (time-remaining-for-minute * minutes-per-hour-ratio)) 4

           if to-control-speed = "None-dist to next node"
               [set distance-to-cover-this-minute precision link-dist 4]  ; distance will be the link distance for that segement

         ;; calc how far to go this cycle (either partway or to next-node)
          if time-remaining-for-minute > 0 ;; if there is still time in the minute, then determine how far to go
            [
              if distance-to-cover-this-minute >= distance-remaining-to-next-node ; just set dist-ahead to next node, this happens when no control of speed and just going node to node
                 [set dist-ahead precision distance-remaining-to-next-node 4] ; go to next node
              if distance-to-cover-this-minute < distance-remaining-to-next-node ; if only need to go partway toward node
                 [set dist-ahead precision distance-to-cover-this-minute 4] ; go the specified distance toward the node
             ]

  end


   to move-to-new-location
       ;; move commuter towards next-node, based on distance calculated above
        face next-node

        ;; check to see if car here if so, go to patch before, update distance traveled

      ;; if traffic-effects is not on, then just keep going
     if traffic-effects = false
          [fd (dist-ahead / netlogo-mile-conversion) ]  ; just move ahead the distance desired converts distance from miles into netlogo units

      ;; if traffic-effects is on, check to see if car on next spot, if so check the spot before it and update distance to travel
     if traffic-effects = true ;;and (status = 2 or status = 4)
       [
        let traffic-check 1
        let car-dist 0

        ;; find neartest spot on path that does not have more than 4 cars
        while [traffic-check > 0]
         [
          let distance-to-check ((dist-ahead / netlogo-mile-conversion) - .1) ;; netlogo units
          set distance-to-check (distance-to-check - car-dist)

          if patch-ahead distance-to-check = nobody [stop];; if at edge of model space and can't go that far then stop

          ;; if at work, then stop
          if work-loc = patch-here [set status 3 set size 0 set traffic-check 0 stop]

          ;; if no place to go, ;; go forward at one 1 mile per hour ( ~ 2.5 patches)
          if distance-to-check <= 0
               [ifelse dist-ahead > 0
                 [set traffic-effect precision (netlogo-mile-conversion / dist-ahead) 2] ; 0.017
                [set dist-ahead netlogo-mile-conversion] ; 0.017 (or just go one netlogo unit)
                fd (dist-ahead / netlogo-mile-conversion)
                set traffic-check 0]

          ;; keep looking for space
          if distance-to-check > 0
            [

             ifelse [num-commuters] of patch-ahead distance-to-check < road-capacity ;; if less than 6 cars on this spot, move there
               [face next-node
                ;if distance next-node < distance-to-check [move-to next-node]
                fd distance-to-check  ;; move to place
                if car-dist = 0 [set traffic-effect 0]
                if car-dist > 0
                  [set traffic-effect precision ((car-dist * netlogo-mile-conversion) / dist-ahead) 2 ;; calculate difference between intended distance and impact of traffic
                   set dist-ahead precision (distance-to-check * netlogo-mile-conversion) 4] ;; update the dist-ahead to actual dist-ahead traveled
                set traffic-check 0
                 ]
             ;; to keep looking for place to go if more than six cars on spot
               [set car-dist car-dist + 1]
              ]
          if distance next-node < 2 [move-to next-node set traffic-check 0]

          ] ; end of while
       if distance next-node < 2 [move-to next-node set traffic-check 0]

        ]
   end



   to update-info
         ask patch-here [set num-commuters count commuters-here with [status = 2 or status = 4]]

       ;; update distance traveled so far toward node
        set dist-traveled-toward-next-node precision (dist-traveled-toward-next-node + dist-ahead) 6 ; this is for those that only go partway, it gets cleared out when new next-node picked
        set distance-remaining-to-next-node (link-dist - dist-traveled-toward-next-node) ;;distance-remaining-to-next-node - dist-ahead) ; gets remaining distance to next-node, used in calcing dist-ahead
        ;; update distance so far in minute
        set distance-during-this-minute (distance-during-this-minute + dist-ahead) ; just a tally of miles covered during minute
        ;; update total distance so far
        set commute-distance-traveled precision (commute-distance-traveled + dist-ahead) 6;; tally of miles covered so far in commute

       ;; update time so far for this segment toward node
        if dist-ahead = 0
           [set current-speed 0]
        if dist-traveled-toward-next-node > 0 and link-dist > 0
             [let portion-of-link-covered precision (dist-traveled-toward-next-node / link-dist) 4;; ratio of distance of link covered
              set  opt-time-so-far-toward-next-node precision (portion-of-link-covered * link-time-estimate) 4 ;; optimum minutes for link portion covered
              set  opt-time-remaining-to-next-node precision ((1 - portion-of-link-covered) * link-time-estimate) 4 ;; optimum minutes remaining for link




       ;; calculate current-speed for segment
          set current-speed precision ((1 - traffic-effect) * speed-intended) 2;((1 - traffic-effect) * speed-intended) 2 ;; speed based on intended speed vs how far actually went
          set relative-speed precision (current-speed / speed-intended) 2 ;; ratio of speed compared to posted (intended speed)
          ]

  ;;     ;; actual time towards next node as distance covered / actual speed
      if distance-during-this-minute < .01 and current-speed = 0 [set commute-time-so-far commute-time-so-far + 1] ;; add a minute of time if didn't go anywhere and had zero speed

        ifelse dist-ahead = 0 or current-speed = 0
            [set act-time-so-far-toward-next-node  (1 - time-remaining-for-minute)]
            [set act-time-so-far-toward-next-node precision ((dist-ahead / current-speed ) * 60) 4] ; / minutes-per-hour-ratio) 4]; calc time in minutes to travel the segment just covered



        if to-control-speed = "None-dist to next node" [set act-time-so-far-toward-next-node 1
                                                        set current-speed precision (((1 - traffic-effect) * dist-ahead) / act-time-so-far-toward-next-node) 2 ;; speed based on intended speed vs how far actually went
                                                        ] ;; travel at minute per node

        ;; time during minute
        set time-passed-so-far-in-min precision (time-passed-so-far-in-min + act-time-so-far-toward-next-node) 4; tally of time passed in minutes, when time = 100 then that is 1 minute; multiply by 60 to get seconds
        if time-remaining-for-minute = 1 and time-passed-so-far-in-min = 0 [set time-passed-so-far-in-min 1 set act-time-so-far-toward-next-node 1]
        set time-remaining-for-minute precision ( 1 - time-passed-so-far-in-min) 4; keeps track of time in minutes

        ;; update time so far of commute
        if current-speed > 0
           [set opt-commute-time-so-far ( opt-commute-time-so-far + opt-time-so-far-toward-next-node)]; ideal commute time based on progress
        set commute-time-so-far (commute-time-so-far + act-time-so-far-toward-next-node) ; actual minutes covered so far in commute

        set avg-speed precision ((commute-distance-traveled / commute-time-so-far) / minutes-per-hour-ratio ) 2

       ;; ESTIMATE HOW MUCH RESTON COMMUTE TIME WILL BE AS OF RIGHT NOW
       set diff-in-minutes precision (opt-commute-time-so-far - commute-time-so-far) 4
       set calc-commute-minutes (opt-commute-minutes + diff-in-minutes)


       ;; if reach next-node
       if distance next-node < 1 [move-to next-node] ;; if within one patch (20 meters) just go ahead

        let who-of-next [who] of next-node
        if any? road-vertices-here with [who = who-of-next]
           [
            set previous-node current-node
            set current-node next-node
           ;; update traffic count at that node when you arrive
           ifelse current-node = work-vertex or previous-node = current-node
             []
             [ask current-node [set traffic-count-minute traffic-count-minute + 1]]
            ]

       ;; update link data for current speeds - used for display of congestion effects to color segment
        let commuter-speed current-speed
       ifelse status = 2 or status = 4 and current-node = work-vertex
         [stop]
         [ifelse link-to-travel = 0 or link-to-travel = nobody
              []
              [ask link-to-travel
                 [set list-of-speeds-now fput commuter-speed list-of-speeds-now
                  set avg-speed-of-drivers-now (mean (list-of-speeds-now))]
               ]
         ]


       ;; If arrived at home or work, update status
         if status = 2 ;and commute-time-so-far > 2
            [if (current-node = work-vertex) [set status 3 set go-beyond 0 update-commute-stats set time-remaining-for-minute 0] ];status 3 arrived at work
         if status = 4 ;and commute-time-so-far > 2
            [if (current-node = home-vertex) [set status 1 set go-beyond 0 update-commute-stats] ] ;status 1 arrived at home

        ;; If not at home or work and still time in the minute, keep going to next node
        if (status = 2 or status = 4)
           [ifelse (time-remaining-for-minute < .01 ) [set go-beyond 0][set go-beyond 1]] ; go-beyond is 1 to keep going if still time to travel towards next node, otherwise you are done


   end


  ;; UPDATE COMMUTE STATS WHEN DONE COMMUTING

   to update-commute-stats

     set actual-commute-minutes commute-time-so-far ;; actual commute time



     ;; zero out commute data
   ;  set commute-time-so-far 0


  end











;; ******** DISPLAY **************
  to update-display

  ifelse develop? = true
    [
       ask patches with [newpop > 1] [set pcolor 37]
       ]
      [ask patches with [newpop > 1] [set pcolor original-color]]



 set baseline 0

if ticks >= 0
   [

; current-speeds
    if Link_Display = "Road Current Speed"
      [ask links
        [if length (list-of-speeds-now) >= 2
            ;[set color 57] ; light green
            [if avg-speed-of-drivers-now >= posted-speed [set color 55] ; green
             if avg-speed-of-drivers-now >= (posted-speed * .75) and avg-speed-of-drivers-now < posted-speed  [set color 26] ; orange
             if avg-speed-of-drivers-now >= (posted-speed * .5) and avg-speed-of-drivers-now < (posted-speed * .75)  [set color 15] ; red
             if avg-speed-of-drivers-now < (posted-speed * .5) [set color 13] ; maroon red
            ]  ]
         ]

; history-of-avg-speeds

    if Link_Display = "Road Speed History"
       [ask links
        [if length (list-of-speeds-now) >= 2
          [
            ;[set color 57] ; light green
           if hist-mean >= posted-speed [set color 117] ;light violet
             if hist-mean < posted-speed and avg-speed-of-drivers-now >= (posted-speed * .75) [set color 57] ; light green
             if hist-mean < (posted-speed * .75) and avg-speed-of-drivers-now >= (posted-speed * .5) [set color 47] ; light yellow
             if hist-mean < (posted-speed * .5) [set color 17] ; light red
             ]
         ]
       ]

    if Link_Display = "Roads"
      [ask links [set color gray] ]

    if show-impacted-roads = True [ask links with [(posted-speed - hist-mean) > 5] [set color magenta set thickness 3]]
    if show-impacted-roads = False [ask links [set thickness 1]]

  ;; COMMUTER DISPLAY COLOR
     ifelse Commuter_Display = "None"
       [ask commuters [set size 0]]

        ;; set color based on display chosen
        [ask commuters
         [ ifelse status = 3
              [set size 0]
              [set size 5]

          if Commuter_Display = "Leave time"
             [if lvtime >= 1 and lvtime < 2 [set color 29] ; 5-5:30
              if lvtime >= 2 and lvtime < 3 [set color 28] ; 5:30 - 6
              if lvtime >= 3 and lvtime < 4 [set color 27] ; 6 - 6:30
              if lvtime >= 4 and lvtime < 5 [set color 26] ; 6:30 - 7
              if lvtime >= 5 and lvtime < 6 [set color 25] ; 7 - 7:30
              if lvtime >= 6 and lvtime < 6 [set color 24] ; 7:30 - 8
              if lvtime >= 7 and lvtime < 6 [set color 23] ; 8 - 8:30
              if lvtime >= 8 and lvtime < 6 [set color 22] ; 8:30 - 9
              if lvtime >= 9 and lvtime < 10 [set color 21] ; 9 - 10
              if lvtime >= 10 [set color 20] ; other
              ]

          if Commuter_Display = "Mode"
             [if mode = 1 [set color gray + 2] ; car solo
              if mode = 2 [set color gray] ; car pool
              if mode = 3 [set color orange] ; bus
              if mode = 4 [set color red ] ; metro
              if mode = 4 [set color blue ] ; other
             ]

           if Commuter_Display = "Current speed" or Commuter_Display = "Relative speed"
             [let max-speed 50 let speed-display 0
              if Commuter_Display = "Current speed" [set speed-display current-speed] ;mph
              ;;if Commuter_Display = "Average speed" [set speed-display avg-speed] ;mph
              if Commuter_Display = "Relative speed" [set speed-display current-speed  set max-speed link-speed-limit] ; current speed compared to posted speed for segment use this instead of max-speed below

              if speed-display >= max-speed [set color violet] ; violet
              if speed-display < max-speed and speed-display >= (max-speed * .75) [set color 54] ; green
              if speed-display < (max-speed * .75) and speed-display >= (max-speed * .5) [set color 45] ; yellow
              if speed-display < (max-speed * .5) [set color red] ; dark red
              if status = 1 or status = 3 [set color gray]
              ]
          ]
       ]
  ]

  end
@#$#@#$#@
GRAPHICS-WINDOW
387
12
876
636
-1
-1
1.0
1
10
1
1
1
0
0
0
1
-240
240
-307
307
1
1
1
ticks
30.0

BUTTON
158
205
239
238
1. Setup
Setup
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
135
287
280
320
2. Create Commuters
setup-commuters
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
888
13
980
58
Commuter Pop
pop-commuters
17
1
11

SLIDER
179
392
369
425
set-constant-speed
set-constant-speed
1
70
50.0
1
1
mph
HORIZONTAL

PLOT
888
64
1107
184
Metrics
Time
Number
0.0
2.0
0.0
80.0
true
true
"" ""
PENS
"Current Speed mph" 1.0 0 -8630108 true "" "if any? commuters with [status = 2 or status = 4] [plot mean [current-speed] of commuters with [status = 2 or status = 4]]"
"Avg Speed mph" 1.0 0 -12087248 true "" "if any? commuters with [status = 2 or status = 4] [plot mean [avg-speed] of commuters with [status = 2 or status = 4]]"
"Relative-Speed %" 1.0 0 -1184463 true "" "if any? commuters with [status = 2 or status = 4] [plot (mean [relative-speed] of commuters with [status = 2 or status = 4] * 100)]"
"Traffic effect %" 1.0 0 -955883 true "" "if any? commuters with [status = 2 or status = 4][plot ( mean [traffic-effect] of commuters with [status = 2 or status = 4] * 100)]"
"Time DIff" 1.0 0 -16777216 true "" "if any? commuters with [status = 2 or status = 4][plot mean [diff-in-minutes] of commuters with [status = 2 or status = 4]]"

CHOOSER
885
576
1035
621
Commuter_Display
Commuter_Display
"Leave time" "Mode" "Current speed" "Relative speed" "None"
3

CHOOSER
23
390
177
435
to-control-speed
to-control-speed
"Posted speed limit" "Constant speed" "None-dist to next node"
0

SLIDER
135
247
268
280
pop-size
pop-size
2
100
2.0
1
1
percent
HORIZONTAL

TEXTBOX
12
56
392
210
Instructions: \n- Set model to fastest setting, press Setup to load display (~15 secs)\n- Adjust population and optimize commute \n- Press Create Commuters (~15secs+  based on pop-size)\n- Adjust settings for commute related variables\n- Press Commute to show movement of commuters each minute (~15-45 secs based on pop)\n\n- To reset model, adjust settings, press Create Commuters, do not need to press Setup
11
0.0
1

BUTTON
129
463
280
496
3. Commute
go-directed
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
1112
64
1272
184
LeaveTime
Time Category
Percent
0.0
9.0
0.0
100.0
true
false
"" ""
PENS
"default" 1.0 1 -16777216 true "" "let pop pop-commuters\nif ticks = 2\n;if (pop > 0) and (day > 0 and (hour = 0 and minutes = 0))\n[\nset-plot-pen-color 29 plot (count commuters with [lvtime = 1] / pop) * 100\nset-plot-pen-color 28 plot (count commuters with [lvtime = 2] / pop) * 100\nset-plot-pen-color 27 plot (count commuters with [lvtime = 3] / pop) * 100\nset-plot-pen-color 26 plot (count commuters with [lvtime = 4] / pop) * 100\nset-plot-pen-color 25 plot (count commuters with [lvtime = 5] / pop) * 100\nset-plot-pen-color 24 plot (count commuters with [lvtime = 6] / pop) * 100\nset-plot-pen-color 23 plot (count commuters with [lvtime = 7] / pop) * 100\nset-plot-pen-color 22 plot (count commuters with [lvtime = 8] / pop) * 100\nset-plot-pen-color 21 plot (count commuters with [lvtime = 9] / pop) * 100\n]"

SWITCH
23
356
176
389
traffic-effects
traffic-effects
0
1
-1000

PLOT
887
312
1076
432
Travel Mode
Time
Percent
0.0
5.0
0.0
100.0
true
true
"" ""
PENS
"carsolo" 1.0 0 -16777216 true "" "plot (count commuters with [mode = 1] / pop-commuters) * 100"
"carpool" 1.0 0 -5987164 true "" "plot (count commuters with [mode = 2] / pop-commuters) * 100"
"bus" 1.0 0 -13345367 true "" "plot (count commuters with [mode = 3] / pop-commuters) * 100"
"metro" 1.0 0 -5298144 true "" "plot (count commuters with [mode = 4] / pop-commuters) * 100"
"other" 1.0 0 -6565750 true "" "plot (count commuters with [mode = 5] / pop-commuters) * 100"

PLOT
886
189
1076
309
Commute Time
NIL
Minutes
0.0
2.0
0.0
10.0
true
true
"" ""
PENS
"actual" 1.0 0 -955883 true "" "if ticks > 0 and any? commuters with [status = 2 or status = 4] [plot mean-calc-commute-minutes]"
"ideal" 1.0 0 -14835848 true "" "if ticks > 0 and any? commuters with [status = 2 or status = 4][plot mean-opt-commute-minutes]"

CHOOSER
9
242
131
287
Optimize-Commute
Optimize-Commute
"Time" "Distance"
1

SLIDER
102
529
225
562
gas-price
gas-price
1
5
2.57
.01
1
$gal
HORIZONTAL

SLIDER
9
566
156
599
car-tolls
car-tolls
1
10
3.5
.25
1
$oneway
HORIZONTAL

SLIDER
159
566
262
599
bus-fare
bus-fare
0
9
1.75
.05
1
$
HORIZONTAL

SLIDER
264
566
379
599
metro-fare
metro-fare
0
9
5.9
.01
1
$
HORIZONTAL

SLIDER
228
528
380
561
base-car-cost
base-car-cost
0
1
0.31
.01
1
$/mi
HORIZONTAL

SLIDER
6
529
98
562
avg-mpg
avg-mpg
0
50
25.0
1
1
NIL
HORIZONTAL

SLIDER
19
615
130
648
car-trip
car-trip
0
50
26.0
1
1
miles
HORIZONTAL

SLIDER
180
427
371
460
value-of-time
value-of-time
0
200
100.0
10
1
% hr-wage
HORIZONTAL

SLIDER
251
615
371
648
metro-trip
metro-trip
0
90
60.0
1
1
min
HORIZONTAL

SLIDER
136
615
245
648
bus-trip
bus-trip
0
60
40.0
1
1
min
HORIZONTAL

PLOT
887
435
1077
556
Oneway Trip Cost
Time
OneWay
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"carsolo" 1.0 0 -16777216 true "" "plot mean [tot-opt-commute-costs] of commuters with [mode = 1]"
"carpool" 1.0 0 -5987164 true "" "plot mean [tot-opt-commute-costs] of commuters with [mode = 2]"
"bus" 1.0 0 -13345367 true "" "plot mean [tot-opt-commute-costs] of commuters with [mode = 3]"
"metro" 1.0 0 -5298144 true "" "plot mean [tot-opt-commute-costs] of commuters with [mode = 4]"
"other" 1.0 0 -6565750 true "" "plot mean [tot-opt-commute-costs] of commuters with [mode = 5]"

PLOT
1082
435
1274
555
Cost w Time
Time
Oneway
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"carsolo" 1.0 0 -16777216 true "" "plot mean [tot-opt-commute-costs-time] of commuters with [mode = 1]"
"carpool" 1.0 0 -5987164 true "" "plot mean [tot-opt-commute-costs-time] of commuters with [mode = 2]"
"bus" 1.0 0 -13345367 true "" "plot mean [tot-opt-commute-costs-time] of commuters with [mode = 3]"
"metro" 1.0 0 -5298144 true "" "plot mean [tot-opt-commute-costs-time] of commuters with [mode = 4]"
"other" 1.0 0 -6565750 true "" "plot mean [tot-opt-commute-costs-time] of commuters with [mode = 5]"

SLIDER
178
355
368
388
road-capacity
road-capacity
1
10
1.0
1
1
cars fit in 20m
HORIZONTAL

SWITCH
274
248
375
281
develop?
develop?
0
1
-1000

TEXTBOX
9
10
334
54
Model of Transportation and Residential Development for Reston, VA, USA 
16
0.0
1

TEXTBOX
887
557
1037
585
Display Controls:
12
0.0
1

TEXTBOX
10
512
371
530
Optional settings - oneway total commute trip costs and length:
11
0.0
1

PLOT
1081
312
1274
432
Trip Length
Time
Minutes
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"carsolo" 1.0 0 -16777216 true "" "plot mean [tot-opt-commute-time] of commuters with [mode = 1]"
"carpool" 1.0 0 -7500403 true "" "plot mean [tot-opt-commute-time] of commuters with [mode = 2]"
"bus" 1.0 0 -13345367 true "" "plot mean [tot-opt-commute-time] of commuters with [mode = 3]"
"metro" 1.0 0 -5298144 true "" "plot mean [tot-opt-commute-time] of commuters with [mode = 4]"
"other" 1.0 0 -6565750 true "" "plot mean [tot-opt-commute-time] of commuters with [mode = 5]"

PLOT
1080
189
1274
309
Diff Time Actual vs Ideal
NIL
Minutes
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"default" 1.0 2 -16777216 true "" "ask commuters with [status = 2 or status = 4] [plot diff-in-minutes]"
"pen-1" 1.0 0 -7500403 true "" "plot baseline"

SWITCH
11
289
128
322
reduce-cars
reduce-cars
1
1
-1000

CHOOSER
885
624
1036
669
Link_Display
Link_Display
"Roads" "Road Current Speed" "Road Speed History"
2

SWITCH
1042
626
1237
659
show-impacted-roads
show-impacted-roads
1
1
-1000

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
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
NetLogo 6.0
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

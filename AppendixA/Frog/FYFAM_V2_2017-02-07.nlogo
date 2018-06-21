extensions [ time table ]

__includes [ "parameters.nls" ]

breed [ breeders breeder ]  ; Adult female breeders
breed [ eggmasses eggmass ] ; Egg masses
breed [ tadpoles tadpole ] ; Tadpoles

globals
[
  ; Global variables calculated by code
  cells                  ; An agentset of cells (patches that are modeled as habitat)
  time                   ; A Logo-time value for time at which current time step started
  formatted-time         ; A string with current time
  next-time              ; The time at which the current time step ends
  step-length            ; Length of the current time step (days)
  prev-step-length       ; Length of the previous time step (days)
  run-duration           ; Maximum number of days to simulate (days)
  end-time-code          ; Logo-time variable for ending time
  run-time               ; Execution time (sec)
  days-with-ovi-temps    ; Number of days with temperature => min-oviposit-temperature,
                         ; updated in update-habitat
  cell-size              ; The width of a patch/cell in the geometry file's units
  max-cell-elevation     ;
  min-cell-elevation
  flow                   ; River flow
  temperature            ; Air temperature

  ; Frog fate counters, updated in save-event
  eggmasses-created      ; Number of eggmasses created
  eggmasses-died-desic   ; Number of eggmasses died of desiccation
  eggmasses-died-scour   ; Number of eggmasses died of scour
  eggmasses-emptied      ; Number of eggmasses that hatched into tadpoles
  tadpoles-hatched       ; Number of tadpoles hatched
  tadpoles-died-desic    ; Number of tadpoles died of desiccation
  tadpoles-died-scour    ; Number of tadpoles died of scour
  number-of-new-frogs    ; Number of successful offspring- tadpoles metamorphosed into frogs

  ; Internal data structures
  input-time-series  ; Time-series input set (time extension's LogoTime data type)
  input-time-list    ; List of times in input-time-series
  depth-flow-list    ; List of flows in the depth hydraulic input file
  velocity-flow-list ; List of flows in the velocity hydraulic input file
  cell-patches       ; A *table* linking cell numbers to corresponding patches
  breeder-suitable-cells ; An agentset of cells suitable for breeders; static, created in read-cell-variables
  todays-breeder-cells ; An agentset of cells usable by breeders on the current time step, updated in update-habitat
  ovi-suitable-cells ; An agentset of cells suitable for oviposition; updated in update-habitat
  metamorph-date-list ; A list of dates on which frogs metamorphose, for median-metamorph-date

  ; =============== Parameters ===============
  ; Definitions and values of the following parameters are in "parameters.nls"

  ; File names
  geom-file-name
  cell-file-name
  velocity-file-name
  depth-file-name
  time-series-file-name

  summary-outfile-name  ; Summary output file
  event-outfile-name    ; Event output file
  event-list            ; List of events to write to events output file

  ; Display parameters
  max-shade-depth       ; The depth at which cell colors are bluest (m)
  max-shade-velocity    ; The velocity at which cell colors are reddest (m/s)
  write-frames?         ; Set to true to write the View to a graphics file each tick, for making movies of model run

  ; Habitat parameters
  velocity-shelter-factor

  ; Breeder parameters
  num-breeders
  readiness-t-days
  min-oviposit-temperature
  max-oviposition-depth-rate
  max-breeder-density
  breeder-selection-radius
  oviposition-radius
  min-expected-ovi-depth
  expected-incubation-time
  oviposition-optimal-velocity
  fecundity-mean
  fecundity-SD
  fecundity-max
  fecundity-min

  ; Egg mass parameters
  eggs-devel-slope
  eggs-devel-const
  eggs-min-devel-days
  eggs-hatching-rate
  eggs-desiccation-survival
  eggs-elevation-above-cell
  eggs-scouring-v01
  eggs-scouring-v09

  ; Tadpole parameters
  tadpole-move-radius
  tadpole-desiccation-survival
  tadpole-scouring-v01
  tadpole-scouring-v09
  tadpole-devel-constant
  tadpole-devel-slope

]

patches-own
[
  cell-number  ; Arbitrary reference number for cells
  depth             ; Water depth in METERS
  velocity          ; Water velocity in m/s
  has-shelter?      ; A static boolean for whether cell has velocity shelter for egg masses
  breeder-suitable? ; A static boolean for whether cell is suitable for breeders, set from input
  breeder-suitable-now? ; A dynamic boolean for whether cell has hab & depths for breeders on current time step
  ovi-suitable?     ; A dynamic boolean for whether cell is suitable for oviposition, set in update-habitat
  prev-depth        ; Depth at previous time step; used in oviposition, set in update-habitat

  elevation    ; Cell bed elevation
  depth-lookup  ; Lookup table of depth values for each flow in global depth-flow-list
  velocity-lookup  ; Lookup table of vel values for each flow in global velocity-flow-list
  flow-at-wetting  ; Flow above which depth becomes non-zero

  actual-x    ; Cell coordinates from geometry input file, for output
  actual-y
]

turtles-own
[
  parent-breeder  ; The who number of breeders, inherited by eggmasses and tadpoles
]

breeders-own
[
  ready?      ; Is breeder ready to breed?
  depth-cell  ; The cell that the breeder uses to monitor water levels
]

eggmasses-own
[
  eggs-frac-developed  ; Fraction of development; 1 = ready to hatch
  eggs-in-mass     ; Number of eggs in mass
]

tadpoles-own
[
  tadpole-age
  tadpole-frac-developed
]


to setup

  ca

  file-close ; Just in case a file got left open.

  show "Setting parameter values"
  set-parameters  ; This procedure is in the separate "parameters.nls" file.

  show "Reading geometry"
  read-geom
  display

  show "Reading cell variables"
  read-cell-variables

  show "Reading hydraulics and building lookup tables"
  read-hydraulics

  reset

  show "End of setup"

end

to reset
  ; This procedure finishes setting up AND allows the model to be re-started
  ; without re-building the habitat

  ; Make sure "setup" has been run at least once
  if geom-file-name = 0 [ error "You neglected to run setup!" ]

  ask turtles [ die ]
  clear-output
  clear-plot

  reset-ticks

  random-seed 111  ; Un-comment this to set random number seed.

  file-close ; Just in case a file got left open.

  ; Set time variables
  show "Setting time variables"
  set time time:create-with-format start-time "M/d/yyyy H:mm"
  set formatted-time time:show time "MM/dd/yyyy HH:mm"
  set end-time-code time:plus time run-duration "DAYS"
  if time:is-after time end-time-code [ error "Really, the simulation must end after it starts" ]
  output-print formatted-time

  ; Read all the input file's data into a LogoTimeSeries variable
  show "Reading time-series input file"
  if not file-exists? time-series-file-name [ error (word "Input file " time-series-file-name " not found") ]
;  set input-time-series time:ts-load time-series-file-name
  set input-time-series time:ts-load-with-format time-series-file-name "M/d/yyyy H:mm"

  ; Extract from the LogoTimeSeries a list of the time values in the input file
  set input-time-list time:ts-get-range input-time-series time end-time-code "LOGOTIME"
  if empty? input-time-list [ error "Time-series input file contains no data for start-time through run-duration" ]
  ; Test output
  ; foreach input-time-list [ show time:show ? "MMMM d, yyyy HH:mm" ]

  ; Initialize the next-time variable
  set next-time 0
  set step-length 0
  set days-with-ovi-temps 0

  show "Updating habitat"
  update-habitat

  ; Create adult breeders
  show "Creating breeders"

  ; Initial global variables
  set eggmasses-created 0      ; Number of eggmasses created
  set eggmasses-died-desic 0   ; Number of eggmasses died of desiccation
  set eggmasses-died-scour 0   ; Number of eggmasses died of scour
  set eggmasses-emptied 0      ; Number of eggmasses that hatched into tadpoles
  set tadpoles-hatched 0       ; Number of tadpoles hatched
  set tadpoles-died-desic 0    ; Number of tadpoles died of desiccation
  set tadpoles-died-scour 0    ; Number of tadpoles died of scour
  set number-of-new-frogs 0    ; Number of successful new frogs

  set metamorph-date-list (list)

  let edge-patches patches with [(cell-number > 0) and (any? neighbors with [cell-number = 0])]
  create-breeders num-breeders
  [
    set ready? false
    set shape "frog top"
    set color yellow
    set size 8
    set parent-breeder who
    move-to one-of patches with [pycor = min-pycor or pycor = max-pycor]
    if cell-number = 0
    [
      let dest-patches edge-patches with [pxcor = [pxcor] of myself]
      if any? dest-patches [ move-to one-of dest-patches]
    ]
  ]

  ; Create the summary output file.
  if file-output?
  [
    show "Initializing output files"
    set summary-outfile-name date-and-time
    set summary-outfile-name remove " " summary-outfile-name
    set summary-outfile-name replace-item 2 summary-outfile-name "-"
    set summary-outfile-name replace-item 5 summary-outfile-name "-"
    set summary-outfile-name (word "Output-" summary-outfile-name ".csv")
    ; show summary-outfile-name
    if file-exists? summary-outfile-name [ file-delete summary-outfile-name ]
    file-open summary-outfile-name
    file-print (word "Frog model output file, Created " date-and-time)
    file-print "Start of time step,Flow,Temperature,Breeders,Egg masses,Tadpoles,New frogs,Median metamorph date,eggmasses-created,eggmasses-died-desic,eggmasses-died-scour,eggmasses-emptied,tadpoles-hatched,tadpoles-died-desic,tadpoles-died-scour"
    file-close
  ]

  ; Create the events output file and list of events that get written to it.
  ; The events are written to the file in update-output
  ; The event list must be created whether or not file output is on; it is always used.
  set event-list (list)
  if file-output?
  [
    set event-outfile-name remove ".csv" summary-outfile-name
    set event-outfile-name (word event-outfile-name "-Events.csv")
    ; show event-outfile-name
    if file-exists? event-outfile-name [ file-delete event-outfile-name ]
    set event-list (list)
    set event-list lput (word "Frog model events output file, Created " date-and-time) event-list
    set event-list lput "Start of time step,LifeStage,ID,ParentBreederID,X-coord,Y-coord,Event" event-list
  ]

  show "End of reset"

end

to go

  if (ticks < 1) [ reset-timer ]

  tick  ; Advance the time step counter

  ; Determine length of the current time step: the time (days) between current time and
  ; the next time in the input file.
  ; Time values are all taken from the list of time values in the input file
  ; If it is not the first tick, advance the time by reading the first value on the time list
  set time time:copy first input-time-list
  set formatted-time time:show time "MM/dd/yyyy HH:mm"

  ; Then remove the current time from the list, and stop if it is the last time.
  ; Also stop if there are no more frogs of any life stage
  set input-time-list remove-item 0 input-time-list
  if (empty? input-time-list) or (not any? turtles)
  [
    set run-time timer
    show (word "Execution finished in " run-time " seconds")
    stop
  ]

  ; Now, the first item on the time list is the start of the *next* time step
  set next-time time:copy first input-time-list

  ; Finally, calculate the time step length, and remember length of previous step
  set prev-step-length step-length
  set step-length time:difference-between time next-time "days"

  ; Set daily depths, velocities
  update-habitat

  ; Display current time, flow, temperature
  output-print (word (time:show time "MMMdd, yyyy HH:mm") "; step length: " step-length "; flow: " flow " temperature: " temperature)

  ; Breeders ready for oviposition select habitat
  ask breeders with [ready?] [ select-breeder-habitat ]

  ; Breeders lay eggs
  ask breeders with [ready?] [ oviposit ]

  ; Breeders not ready for oviposition decide if they become ready
  ask breeders with [not ready?] [ decide-if-ready ]

  ; Egg mortality
  ask eggmasses [ eggs-survive ]

  ; Egg development
  ask eggmasses [ eggs-develop ]

  ; Egg hatching
  ask eggmasses [ eggs-hatch ]

  if any? tadpoles
  [
    ; Tadpole habitat selection - a patch procedure for efficiency
    ask cells with [ any? tadpoles-here] [ select-tadpole-habitat ]

    ; Tadpole survival - a patch procedure for efficiency
    ask cells with [ any? tadpoles-here] [ tadpoles-survive ]

  ]

  ; Tadpole development
  ask tadpoles [ tadpoles-develop ]

  ; Last: output
  update-output

end

to read-geom  ; Global procedure to set spatial scale and assign cell numbers to patches

  ; First, make sure file name and file exist
  if empty? geom-file-name [ error "Missing geometry file name" ]
  if not file-exists? geom-file-name
    [ user-message (word "Geometry file " geom-file-name " not found")
      stop
    ]

  ; Set patch variables to dummy values for key variables, to distinguish cell
  ; from non-cell patches
  ask patches
  [
    set cell-number -999
    set depth -999
    set velocity -999
    set breeder-suitable-now? false
    set ovi-suitable? false
    set pcolor 52 ; Forest green
  ]

  ; Create the table linking cell numbers to patches
  set cell-patches table:make

  ; Open file and skip the 3 header lines
  file-open geom-file-name
  let header-string "a string"
  repeat 3 [set header-string file-read-line ]

  ; Create lists of cell numbers, X and Y coordinates in file
  let cell-numbers (list)
  let actual-x-coords (list)
  let actual-y-coords (list)

  while [not file-at-end?]
  [
   set cell-numbers fput file-read cell-numbers
   set actual-x-coords fput file-read actual-x-coords
   set actual-y-coords fput file-read actual-y-coords
  ]
  file-close

  ; Calculate space dimensions and patch size
  let num-x-coords length remove-duplicates actual-x-coords
  let num-y-coords length remove-duplicates actual-y-coords

  ; Single-cell-width spaces cause division by zero below
  if num-x-coords = 0 or num-y-coords = 0
    [ error "Sorry, one-cell-width spaces are not allowed" ]

  let min-actual-x min actual-x-coords
  let min-actual-y min actual-y-coords
  let max-actual-x max actual-x-coords
  let max-actual-y max actual-y-coords

  let patch-size-x (max-actual-x - min-actual-x) / (num-x-coords - 1)
  let patch-size-y (max-actual-y - min-actual-y) / (num-y-coords - 1)

  ; Check for problems
  if abs ((patch-size-x - patch-size-y) / patch-size-x) > 0.01
  [ user-message "Cells in geometry file are not square" ]

  ; Set world size
  set cell-size patch-size-x
  show (word "Cell size: " cell-size)
  let maximum-patch-x round ((max-actual-x - min-actual-x) / cell-size)
  let maximum-patch-y round ((max-actual-y - min-actual-y) / cell-size)
  ; Approximate a good patch size - turned off
  ; set-patch-size max (list (21 - (maximum-patch-x * 0.051)) 0.5)
  resize-world 0 maximum-patch-x 0 maximum-patch-y

  ; Set patch values for actual coordinates and cell number
  let index 0
  while [ index < length cell-numbers ]
  [
    let the-x item index actual-x-coords
    let transformed-x round ((the-x - min-actual-x) / cell-size)
    let the-y item index actual-y-coords
    let transformed-y round ((the-y - min-actual-y) / cell-size)
    let the-cell-num item index cell-numbers

    ; Check for illegal cell numbers
    if the-cell-num <= 0 [ error "Error in cell geometry: Non-positive cell number" ]

    ask patch transformed-x transformed-y
    [
      set cell-number the-cell-num
      set actual-x the-x
      set actual-y the-y
      set pcolor cell-number
    ]

    table:put cell-patches the-cell-num (patch transformed-x transformed-y)
    set index index + 1
  ]

  ; Finally, create an agentset of patches that are modeled cells
  set cells patches with [cell-number > 0]

end

to read-cell-variables  ; Observer procedure to read in cell data

  ; First, make sure file name and file exist
  if empty? cell-file-name [ error "Missing cell file name" ]
  if not file-exists? cell-file-name
    [ user-message (word "Cell variables file " cell-file-name " not found")
      stop
    ]

  ; Open file and skip the 3 header lines
  file-open cell-file-name
  let header-string "a string"
  repeat 3 [set header-string file-read-line ]

  ; Read in cell variables
  let a-cell-number 0
  let an-elevation 0
  let a-suitability 0
  let a-has-shelter 0

  while [not file-at-end?]
  [
   set a-cell-number file-read
   set an-elevation file-read
   set a-suitability file-read
   set a-has-shelter file-read
   ask (table:get cell-patches a-cell-number)
   [
     set elevation an-elevation
     ifelse a-suitability = 0
     [ set breeder-suitable? false ]
     [ ifelse a-suitability = 1
       [ set breeder-suitable? true ]
       [ error (word "A breeder suitability value in " cell-file-name " is not equal to 0 or 1") ]
     ]
     ifelse a-has-shelter = 0
     [ set has-shelter? false ]
     [ ifelse a-has-shelter = 1
       [ set has-shelter? true ]
       [ error (word "A has-shelter value in " cell-file-name " is not equal to 0 or 1") ]
     ]
   ]
  ]

  file-close

  ; Now set globals based on cell variables
  set max-cell-elevation max [elevation] of cells
  set min-cell-elevation min [elevation] of cells
  set breeder-suitable-cells cells with [breeder-suitable?]

end

to read-hydraulics
  ; Observer procedure to read in depth and velocity lookup tables for each cell.

  ; Depth first

  ; First, make sure file name and file exist
  if empty? depth-file-name [ error "Missing depth file name" ]
  if not file-exists? depth-file-name
    [ error (word "Depth file " depth-file-name " not found") ]

  ; Open file and skip the 3 header lines
  file-open depth-file-name
  let header-string "a string"
  repeat 3 [set header-string file-read-line ]

  ; Read in the number of flows
  let num-depth-flows file-read
  if not is-number? num-depth-flows [ error "Error reading number of flows in depth file" ]

  ; Read in the flow list
  set depth-flow-list (list)
  repeat num-depth-flows [ set depth-flow-list lput file-read depth-flow-list ]
  ; show depth-flow-list

  ; Read in the depth table for each cell
  while [not file-at-end?]
  [
    let next-cell file-read
    ask (table:get cell-patches next-cell)
    [  set depth-lookup (list)
      repeat num-depth-flows [ set depth-lookup lput file-read depth-lookup ]
      ; show depth-lookup
    ]

  ]
  file-close

  ; Velocity second

  ; First, make sure file name and file exist
  if empty? velocity-file-name [ error "Missing velocity file name" ]
  if not file-exists? velocity-file-name
    [ error (word "Velocity file " velocity-file-name " not found") ]

  ; Open file and skip the 3 header lines
  file-open velocity-file-name
  repeat 3 [set header-string file-read-line ]

  ; Read in the number of flows
  let num-vel-flows file-read
  if not is-number? num-vel-flows [ error "Error reading number of flows in velocity file" ]

  ; Read in the flow list
  set velocity-flow-list (list)
  repeat num-vel-flows [ set velocity-flow-list lput file-read velocity-flow-list ]
  ; show velocity-flow-list

  ; Read in the velocity table for each cell
  while [not file-at-end?]
  [
    let next-cell file-read
    ask (table:get cell-patches next-cell)
    [
      set velocity-lookup (list)
      repeat num-vel-flows [ set velocity-lookup lput file-read velocity-lookup ]
      ; show velocity-lookup
    ]

  ]
  file-close

  ; Some error checking
  ask cells
  [
    if length depth-lookup != num-depth-flows
    [ error (word "Cell " cell-number "does not have correct number of depths in lookup table") ]
    if length velocity-lookup != num-vel-flows
    [ error (word "Cell " cell-number "does not have correct number of velocities in lookup table") ]
  ]

  ; Now set the minimum flow at which cell is wet
  ask cells
  [
    ifelse first depth-lookup > 0.0  ; Depth is non-zero at lowest lookup table flow
    [
      set flow-at-wetting 0.0
    ]
    [ ; Depth is zero at lowest lookup-table flow
      ifelse last depth-lookup <= 0.0  ; The last value in lookup table is zero
      [
        set flow-at-wetting 999999
      ]
      [ ; Last value in table is non-zero
        ifelse item (length depth-flow-list - 2) depth-lookup > 0.0 ; The second-to-last value is also non-zero
        [ ; The second-to-last value is also non-zero, so do interpolation
          let d-index-low 0
          while [ item d-index-low depth-lookup <= 0 ] ; Find the first non-zero depth
          [ set d-index-low d-index-low + 1 ]

          let d-index-high d-index-low + 1
          let Q1 item d-index-low depth-flow-list
          let Q2 item d-index-high depth-flow-list
          let D1 item d-index-low depth-lookup
          let D2 item d-index-high depth-lookup

          let slope (D2 - D1) / (Q2 - Q1)
          let y-intercept D2 - (slope * Q2)
          ifelse y-intercept < 0
          [ ; y-intercept is negative, so depth goes to zero before flow does
            set flow-at-wetting (-1 * y-intercept / slope)
          ]
          [ ; y-intercept is positive so cell is extrapolated to have depth > 0 at zero flow.
            set flow-at-wetting 0.0
          ]

          ; Now check whether flow-at-wetting is less than the highest lookup-table flow with non-zero depth
          let Q0 item (d-index-low - 1) depth-flow-list
          if flow-at-wetting < Q0 [ set flow-at-wetting Q0 ]
        ] ; Do interpolation
        [ ; If there is depth only at highest flow, flow-at-wetting is halfway between it and next-lowest flow
          set flow-at-wetting ((last depth-flow-list) + (item (length depth-flow-list - 2) depth-flow-list)) / 2
        ]

      ] ; Last value in table is non-zero
    ] ; Depth is zero at lowest lookup-table flow
    ] ; ask cells

end

to update-habitat ; Observer procedure to set daily flow, temperature, depth, velocity of patches

  ; See the procedure test-hydraulics for a way to test depth and velocity updates

    ; Update the number of days with temperature above oviposition threshold
    ; Here, temperature is still from previous time step
    ifelse temperature >= min-oviposit-temperature
    [ set days-with-ovi-temps days-with-ovi-temps + prev-step-length ]
    [ set days-with-ovi-temps 0 ]
    ; show days-with-ovi-temps

    ; First, get today's flow and temperature
    let prev-flow flow
    set flow time:ts-get input-time-series time "flow"
    set temperature time:ts-get input-time-series time "temperature"

    ; Second, interpolate the depth and velocity, and ovi-suitability, from flow
    update-hydraulics-for flow

    ; Third, update agentsets of cells used by breeders, if there are breeders
    if any? breeders
    [
      ask breeder-suitable-cells
      [
        set breeder-suitable-now? ifelse-value (depth > 0 and any? neighbors with [ depth <= 0 and cell-number > 0])
          [ true ][ false ]
      ]
      set todays-breeder-cells breeder-suitable-cells with [ breeder-suitable-now? ]

      set ovi-suitable-cells cells with [ ovi-suitable? ]
    ]

    ; Finally, re-color the patches
    shade-patches

end

to update-hydraulics-for [a-flow] ; Observer procedure to interpolate depth, velocity of patches from flow

  ; See the procedure test-hydraulics for a way to test depth and velocity updates

    ; First, interpolate the depth index from flow
    let d-index-high 1
    ifelse a-flow < last depth-flow-list
    [
      while [ a-flow > item d-index-high depth-flow-list]
        [ set d-index-high d-index-high + 1 ]
    ]
    [
      set d-index-high (length depth-flow-list - 1)
    ]
    let d-index-low d-index-high - 1

    ; Second, interpolate the velocity index from flow
    let v-index-high 1
    ifelse a-flow < last velocity-flow-list
    [
      while [ a-flow > item v-index-high velocity-flow-list]
        [ set v-index-high v-index-high + 1 ]
    ]
    [
      set v-index-high (length velocity-flow-list - 1)
    ]
    let v-index-low v-index-high - 1

    ;show (word "Flow: " flow " high index: " d-index-high " low index: " d-index-low)
    ;show (word "Flow: " flow " high index: " v-index-high " low index: " v-index-low)

    ; Now have cells do the interpolation
    ; If flow is less than lowest in table,
    ; ->extrapolate depth downward but don't allow neg. depth
    ; ->interpolate velocity between zero and lowest in table
    ask cells
    [
      ; First, see if flow is below the flow at which depth first exceeds zero
      ifelse a-flow <= flow-at-wetting
      [
        set depth 0.0
        set velocity 0.0
      ]
      [
        ; If not, interpolate depth
        set prev-depth depth

        let lowQ item d-index-low depth-flow-list
        let highQ item d-index-high depth-flow-list
        let lowD item d-index-low depth-lookup
        let highD item d-index-high depth-lookup
        ; Check for flow-at-wetting and use it for interpolation
        ; if cell is dry at lowQ from interpolation table.
        if lowQ < flow-at-wetting
          [
            set lowQ flow-at-wetting
            if lowD > 0.0 [error "Depth interpolation error: Depth not zero for Q below flow-at-wetting"]
          ]
        let diff highQ - lowQ
        let ratio (a-flow - lowQ) / diff

        set depth lowD + ratio * (highD - lowD)
        if depth < 0 [ set depth 0.0 ]

        ; Then velocity
        ifelse a-flow < (item 0 velocity-flow-list)
        [
          ; Flow is less than lowest in table, so interpolate from zero to lowest table flow
          set velocity (a-flow / first velocity-flow-list) * first velocity-lookup
          ; But velocity must be zero if depth is zero
          if depth <= 0 [set velocity 0.0]
        ]
        [
          set lowQ item v-index-low velocity-flow-list
          set highQ item v-index-high velocity-flow-list
          let lowV item v-index-low velocity-lookup
          let highV item v-index-high velocity-lookup
          ; Check for flow-at-wetting and use it for interpolation
          ; if cell is dry at lowQ from interpolation table.
          if lowQ < flow-at-wetting
            [
              set lowQ flow-at-wetting
              set lowV 0.0 ; Velocity *might* not be zero at flow-at-wetting due to var. in hydraulic sims.
            ]
          set diff highQ - lowQ
          set ratio (a-flow - lowQ) / diff

          set velocity lowV + ratio * (highV - lowV)
          if velocity < 0 [ error (word "Velocity interpolated to negative value at cell " cell-number)]
        ]
      ] ; ifelse a-flow < flow-at-wetting

      ; Update oviposition suitability
      set ovi-suitable? ovi-suitability  ; A reporter
    ]

end

; Observer procedure to color the patches by elevation or depth
to shade-patches
  ; Non-cell patches are given a constant color in read-geom

  ask cells
  [
    ifelse depth <= 0
      [ ; Patch is above water so shade it green
        set pcolor scale-color green (elevation - min-cell-elevation) 0 (max-cell-elevation - min-cell-elevation)
      ]
      [ ; Patch is below water so shade it by depth or velocity
        ; Velocity is shaded yellow-red
        ifelse shade-variable = "depth"
        [ set pcolor scale-color blue depth max-shade-depth  0]
        [ set pcolor (list 255 (255 * (1 - (min (list velocity max-shade-velocity) / max-shade-velocity))) 0)]

      ]
  ]

end

to decide-if-ready  ; A breeder procedure to decide if ready for oviposition

  let prob-readiness (days-with-ovi-temps / readiness-t-days) * step-length
  ; show prob-readiness
  if (temperature >= min-oviposit-temperature) and random-bernoulli prob-readiness
  [
    let the-breeder self
    let potential-cells todays-breeder-cells with
    [
      ; "other breeders" doesn't work in following statement
      ((count breeders-here with [self != the-breeder]) / (cell-size * cell-size)) < max-breeder-density
    ]
    ifelse any? potential-cells
    [ ; Do stuff breeder does when ready
      set ready? true
      set color red
      move-to one-of potential-cells
      let deep-cells cells with [depth >= 0.2]
      if not any? deep-cells [error "In decide-if-ready, no cells with depth >= 0.2 m"]
      set depth-cell min-one-of deep-cells [distance myself]
      if distance depth-cell > (50 / cell-size) [ error "In decide-if-ready, breeder chose depth cell > 50 m away" ]
      ; Save event output
      save-event "readied-to-breed"
    ]
    [
      show "Warning: breeder has no suitable cells to move to when ready"
    ]

  ]

end

to select-breeder-habitat   ; A breeder reporter

  ; Test output - uncomment the file-* statements in this procedure to get test output
  ; User must manually delete the file between runs!
;  file-open "BreederHabitatTestOutput.csv"
;  ask patches in-radius (breeder-selection-radius / cell-size)
;  [
;    file-print (word
;      [who] of myself ","
;      ticks ","
;      [pxcor] of myself ","
;      [pycor] of myself ","
;      pxcor ","
;      pycor ","
;      depth ","
;      count neighbors with [ depth <= 0 and cell-number > 0] ","
;      breeder-suitable? ","
;      count breeders-here with [self != myself] ","
;      count ovi-suitable-cells in-radius (oviposition-radius / cell-size))
;  ]

  let the-breeder self
  let selection-radius (breeder-selection-radius / cell-size) ; Scale radiuses by cell size
  let ovi-radius (oviposition-radius / cell-size)
  let suitable-cells (patches in-radius selection-radius) with
  [
    breeder-suitable-now? and
    ; "other breeders" doesn't work in following statement
    ((count breeders-here with [self != the-breeder]) / (cell-size * cell-size)) < max-breeder-density
  ]

  ifelse any? suitable-cells
  [
    ;show "Finding max suitable-cell"
    move-to max-one-of suitable-cells [ count (patches in-radius ovi-radius) with [ovi-suitable?] ]
;    file-print (word who "," ticks ",,moved to:," pxcor "," pycor "," depth ","
;      count neighbors with [ depth <= 0 and cell-number > 0] "," breeder-suitable? ","
;      count breeders-here with [self != the-breeder] "," count ovi-suitable-cells in-radius (oviposition-radius / cell-size))
;    file-close
  ]
  [
   show "Warning in select-breeder-habitat: No suitable cells within habitat selection radius"
   set suitable-cells (todays-breeder-cells) with
   [
     ; "other breeders" doesn't work in following statement
     ((count breeders-here with [self != the-breeder]) / (cell-size * cell-size)) < max-breeder-density
   ]

   ifelse any? suitable-cells  ; Move to nearest suitable cell, outside radius
   [
     move-to min-one-of suitable-cells [ distance myself ]
;     file-print (word who "," ticks ",,moved beyond selection-radius to:," pxcor "," pycor "," depth ","
;     count neighbors with [ depth <= 0 and cell-number > 0] "," breeder-suitable? ","
;     count breeders-here with [self != the-breeder] "," count ovi-suitable-cells in-radius (oviposition-radius / cell-size))
;     file-close
   ]
   [
     show "Warning in select-breeder-habitat: no suitable cells found"  ; Don't move in this case
;     file-print (word who "," ticks ",,No suitable cell-stayed at:," pxcor "," pycor "," depth ","
;     count neighbors with [ depth <= 0 and cell-number > 0] "," breeder-suitable? ","
;     count breeders-here with [self != the-breeder] "," count ovi-suitable-cells in-radius (oviposition-radius / cell-size))
;     file-close
   ]
  ]

end

to-report ovi-suitability   ; A boolean patch procedure reporting whether cell is suitable for oviposition

  ; Just report false on first time step when depth-change-rate cannot be calculated.
  if prev-step-length <= 0 [ report false ]

  ; Consider the elevation difference between egg mass and cell bottom
  let needed-depth min-expected-ovi-depth + eggs-elevation-above-cell
  let depth-change-rate (prev-depth - depth) / prev-step-length

  report

   ; Current depth
   depth >= needed-depth and

   ; Expected depth at end of incubation
   depth - (depth-change-rate * expected-incubation-time) >= needed-depth and

   ; Scour survival probability
   eggs-scour-survival > 0.95

end

to oviposit ; A breeder procedure to select oviposition habitat and create egg mass.

  ; Stop if prev-step-length is zero, which should be only on first time step, when oviposition should not happen
  if prev-step-length = 0 [ stop ]

  ; Test outputs: pxcor, pycor, temperature, depth, prev-depth, prev-step-length, oviposited?, egg-pxcor, egg-pycor, egg-velocity, eggs-in-mass
  ; For test outputs, uncomment the following file and print statements, and other print statements in this procedure
  ; The user must manually delete previous versions of the file!
;  file-open "OvipositTestOutput.csv"
;  file-type (word who ","
;                  pxcor ","
;                  pycor ","
;                  temperature ","
;                  [depth] of depth-cell ","
;                  [prev-depth] of depth-cell ","
;                  prev-step-length ",")

  ; First decide whether to oviposit (oviposition timing submodel)
  if temperature < min-oviposit-temperature
  [
;    file-print "false,temperature"
;    file-close
    stop
  ]

  ; Calculate rate of change in water level / depth
  let depth-change-rate (([depth] of depth-cell) - ([prev-depth] of depth-cell)) / prev-step-length

  ; If depth-cell goes dry, find another one for use next tick - nearest cell with depth > 0.2 m
  if [depth] of depth-cell <= 0
    [
      let deep-cells cells with [depth >= 0.2]
      if not any? deep-cells [error "In oviposition, no cells with depth >= 0.2 m"]
      set depth-cell min-one-of deep-cells [distance myself]
      if distance depth-cell > (50 / cell-size) [ error "In oviposition, breeder chose depth cell > 50 m away" ]
    ]

  if abs depth-change-rate > max-oviposition-depth-rate
  [
;    file-print "false,depth-change"
;    file-close
    stop
  ]

  ; Now select a cell (oviposition habitat selection submodel)
  let potential-egg-cells ovi-suitable-cells in-radius (oviposition-radius / cell-size)

  if any? potential-egg-cells
  [
    ; A second temporary output file for oviposition cell selection
    ; The user must delete previous versions of the file!
;    file-open "OviCellSelTestOutput.csv"  ; oviposition cell selection test output
;    ask potential-egg-cells  ; oviposition cell selection test output
;    [  ; oviposition cell selection test output
;      file-print (word   ; oviposition cell selection test output
;        [pxcor] of myself ","  ; oviposition cell selection test output
;        [pycor] of myself ","  ; oviposition cell selection test output
;        pxcor ","  ; oviposition cell selection test output
;        pycor ","  ; oviposition cell selection test output
;        depth ","  ; oviposition cell selection test output
;        velocity ","  ; oviposition cell selection test output
;        has-shelter? ","  ; oviposition cell selection test output
;        egg-velocity ","  ; oviposition cell selection test output
;        ovi-suitable?)  ; oviposition cell selection test output
;    ]  ; oviposition cell selection test output

      hatch-eggmasses 1
      [
        move-to min-one-of potential-egg-cells [ abs (egg-velocity - oviposition-optimal-velocity) ]
        set eggs-frac-developed 0.0
        set color black
        set size 3
        set shape "circle"
        set eggs-in-mass round random-normal fecundity-mean fecundity-SD
        if eggs-in-mass > fecundity-max [ set eggs-in-mass fecundity-max ]
        if eggs-in-mass < fecundity-min [ set eggs-in-mass fecundity-min ]
        ; Save event output
        save-event "created"

;        file-print (word "true,," pxcor "," pycor "," depth "," prev-depth "," egg-velocity "," eggs-in-mass)
;        file-close
;        file-print (word "Selected cell,," pxcor "," pycor "," depth "," velocity "," has-shelter? "," egg-velocity "," ovi-suitable?)  ; oviposition cell selection test output
;        file-close  ; oviposition cell selection test output
      ]

    ; Save event output
    save-event "oviposited"

    die

  ]

;  file-print "false,no-egg-cells"
;  file-close

end

to eggs-survive  ; An egg mass procedure

  ; Optional test output
  ; User must manually delete this file between uses.
  ; file-open "Eggs-survival-TestOut.csv"
  ; file-type (word who "," ticks "," eggs-in-mass "," depth "," velocity "," has-shelter? "," eggs-scour-survival "," eggs-elevation-above-cell ",")

  ; First, desiccation; considers that egg masses could be higher than cell bottom
  if (depth - eggs-elevation-above-cell) <= 0.0
  [
    set eggs-in-mass floor (eggs-in-mass * (eggs-desiccation-survival ^ step-length))
    ; file-print (word "desiccation," eggs-in-mass)   ; Optional test output
    ; file-close   ; Optional test output

    if eggs-in-mass <= 0
    [
      ; Save event output
      save-event "died-desiccation"
      ; file-close   ; Optional test output
      die
    ]

    stop  ; This is necessary to prevent scouring mortality when the egg mass is not below water
          ; (and to facilitate test output)
  ]

  ; Second, scouring

  if not random-bernoulli (eggs-scour-survival ^ step-length)
  [
    ; file-print (word "scour," eggs-in-mass)   ; Optional test output
    ; file-close   ; Optional test output
    ; Save event output
    save-event "died-scour"

    die
  ]

    ; file-print (word "none," eggs-in-mass)   ; Optional test output
    ; file-close   ; Optional test output
end

to-report eggs-scour-survival   ; A patch or egg mass procedure, daily probability of egg mass surviving scour

  report logistic-with-1-9-input eggs-scouring-v01 eggs-scouring-v09 egg-velocity

end

to-report egg-velocity  ; A patch procedure that reports velocity experienced by egg masses

  ifelse has-shelter?
  [ report velocity * velocity-shelter-factor ]
  [ report velocity ]

end

to eggs-develop  ; An egg mass procedure

  let eggs-daily-development 1.0 / ((eggs-devel-slope * temperature) + eggs-devel-const)
  let max-daily-development 1.0 / eggs-min-devel-days

  if eggs-daily-development > max-daily-development [ set eggs-daily-development max-daily-development ] ; this happens at high temperatures

  let development step-length * eggs-daily-development

  if (eggs-daily-development > (1 / eggs-min-devel-days)) or (eggs-daily-development < 0)
  [ error (word "In eggs-develop, illegal value of daily-development: " eggs-daily-development) ] ; This can also happen at high T

  set eggs-frac-developed eggs-frac-developed + development
  set color 10 * eggs-frac-developed ; Shades egg masses from black to grey as they develop

  ; Optional test output
  ; User must manually delete this file between uses.
;  file-open "Eggs-devel-TestOut.csv"
;  file-print (word who "," ticks "," temperature "," development "," eggs-frac-developed)
;  file-close

end

to eggs-hatch ; An eggmass procedure

  if eggs-frac-developed < 1.0 [ stop ]
  let num-hatching-now ceiling (eggs-hatching-rate * step-length * eggs-in-mass)
  set eggs-in-mass eggs-in-mass - num-hatching-now

  ; Optional test output
  ; User must manually delete this file between uses.
;  file-open "Eggs-hatch-TestOut.csv"
;  file-print (word who "," ticks "," eggs-hatching-rate "," eggs-in-mass "," num-hatching-now)
;  file-close

  hatch-tadpoles num-hatching-now
  [
    set shape "default"
    set color one-of base-colors
    set size 1
    set tadpole-age 0
    set tadpole-frac-developed 0.0
    ; Save event output
    save-event "hatched"
  ]

  if eggs-in-mass < 1
  [
    ; Save event output
    save-event "emptied"

    die
  ]

end

to select-tadpole-habitat  ; A *patch* procedure, to reduce computation

  ; Optional test output
  ; User must manually delete this file between uses.
;  file-open "Tadpole-HabSelection-TestOut.csv"
;  let a-tadpole one-of tadpoles-here  ; Used only for test output

  let selection-radius (tadpole-move-radius / cell-size) ; Scale radius by cell size
  if selection-radius < 1.5 [ set selection-radius 1.5 ] ; Be sure to include at least neighbor cells AND current cell

  let potential-cells (patches in-radius selection-radius) with [ depth > 0 ]

  if any? potential-cells
  [
    ask tadpoles-here [move-to min-one-of potential-cells [ velocity ]]
;    ask a-tadpole [file-type (word velocity ",")]  ; optional test output
  ]

  ; Test output
;  ask potential-cells [ file-type (word velocity ",")]
;  file-print selection-radius
;  file-close

end

to tadpoles-survive  ; A *patch* procedure, to reduce computation

  ; Optional test output
  ; User must manually delete this file between uses.
;  file-open "Tadpole-Survival-TestOut.csv"

  ; First, desiccation
  if depth <= 0.0
  [
    let survival-prob (tadpole-desiccation-survival ^ step-length)
    ask tadpoles-here
    [
      if not random-bernoulli survival-prob
      [
        ; Save event output
        save-event "died-desiccation"

;        file-print (word who "," ticks "," depth "," velocity ",-1,died-desiccation")

        die
      ]
    ]
  ]

  ; Second, scouring
  let survival-prob (logistic-with-1-9-input tadpole-scouring-v01 tadpole-scouring-v09 velocity) ^ step-length

  ask tadpoles-here
  [
    if not random-bernoulli survival-prob
    [
      ; Save event output
      save-event "died-scour"

;      file-print (word who "," ticks "," depth "," velocity "," survival-prob ",died-scour")

      die
    ]

;    file-print (word who "," ticks "," depth "," velocity "," survival-prob ",survived")

  ]

;  file-close

end

to tadpoles-develop  ; A tadpole procedure

  set tadpole-age tadpole-age + step-length  ; Increment age by length of current time step

  ; Starting in version 2, tadpole development is temperature-dependent.
  let tadpole-daily-development 1 / ((tadpole-devel-slope * temperature) + tadpole-devel-constant)
  set tadpole-frac-developed tadpole-frac-developed + (step-length * tadpole-daily-development)

  if tadpole-frac-developed > 1.0  ; Development is complete so write output and leave model
  [
    ; Save event output
    save-event "metamorphosed"
    die
  ]

end

to-report logistic-with-1-9-input [ L1 L9 input ] ; General logistic evaluator

  let z (ln (1 / 9) + ((ln 81 / (L1 - L9)) * (L1 - input)))
  if z > 20 [ report 1.0 ] ; An approximation that avoids overflow errors
  if z < -20 [ report 0.0 ] ; An approximation that avoids underflow errors
  let exp-z exp z
  report exp-z / (1 + exp-z)

end

to test-logistic-with-1-9-low-high [ L1 L9 low high ] ; An observer test procedure

  let value low
  let increment (high - low) / 20
  while [value <= high]
  [
    show (word "Value: " value " logistic: " (logistic-with-1-9-input L1 L9 value))
    set value value + increment
  ]

end

to-report random-bernoulli [ probability-true ]

  ; First, some defensive programming to make
  ; sure "probability-true" has a sensible value.
  if (probability-true < 0.0 or probability-true > 1.0)
  [ user-message (word "Warning in random-bernoulli: probability-true equals " probability-true) ]

  report random-float 1.0 < probability-true

end

to save-event [an-event-type] ; A turtle procedure to save events for the event output file

  set event-list lput (word formatted-time "," breed "," who "," parent-breeder "," actual-x "," actual-y "," an-event-type) event-list

  ; Update global counters of event types
  if breed = eggmasses
  [
    if an-event-type = "created" [ set eggmasses-created eggmasses-created + 1 ]                ; Number of eggmasses created
    if an-event-type = "died-desiccation" [ set eggmasses-died-desic eggmasses-died-desic + 1 ] ; Number of eggmasses died of desiccation
    if an-event-type = "died-scour" [ set eggmasses-died-scour eggmasses-died-scour + 1 ]       ; Number of eggmasses died of scour
    if an-event-type = "emptied" [ set eggmasses-emptied eggmasses-emptied + 1 ]                ; Number of eggmasses that hatched into tadpoles
  ]
  if breed = tadpoles
  [
    if an-event-type = "hatched" [ set tadpoles-hatched tadpoles-hatched + 1 ]                 ; Number of tadpoles hatched
    if an-event-type = "died-desiccation" [ set tadpoles-died-desic tadpoles-died-desic + 1 ]  ; Number of tadpoles died of desiccation
    if an-event-type = "died-scour" [ set tadpoles-died-scour tadpoles-died-scour + 1 ]        ; Number of tadpoles died of scour
    if an-event-type = "metamorphosed"
    [
      set number-of-new-frogs number-of-new-frogs + 1     ; Number of successful new frogs
      set metamorph-date-list list metamorph-date-list formatted-time  ; Used by median-metamorph-date
    ]
  ]

end

to update-output

  ; File output
  if file-output? and (not is-string? summary-outfile-name or not is-string? event-outfile-name)
  [ error "You must execute setup or reset after turning on file output" ]

  if file-output?
  [
    file-open summary-outfile-name
    file-print (word formatted-time "," flow "," temperature ","
      count breeders "," count eggmasses "," count tadpoles "," number-of-new-frogs "," median-metamorph-date ","
      eggmasses-created "," eggmasses-died-desic "," eggmasses-died-scour "," eggmasses-emptied ","
      tadpoles-hatched "," tadpoles-died-desic "," tadpoles-died-scour)
    file-close
  ]

  if file-output? and not empty? event-list
  [
    file-open event-outfile-name
    foreach event-list [ file-print ? ]  ; Write each event to the file
    file-close
    set event-list (list)                ; Clear the event list
  ]

  ; Plot
  set-current-plot "Abundance"
  set-current-plot-pen "Eggs"
  plot sum [eggs-in-mass] of eggmasses

  set-current-plot-pen "Tadpoles"
  plot count tadpoles

  set-current-plot-pen "New frogs"
  plot number-of-new-frogs

  ; Write the display to a file if wanted, to make movies of a simulation
  ; Replace "export-interface" with "export-view" to get just the World instead of whole interface
  if write-frames? [ export-interface (word "frogs-frame-" (10000 + ticks) ".png") ]

end

to-report median-metamorph-date ; A global procedure to output median tadpole metamorphosis date

  ; Deal with empty lists (no tadpoles metamorphosed yet)
  ifelse empty? metamorph-date-list
  [ report "1/1" ]
  [ report substring (item (int (length metamorph-date-list) / 2) metamorph-date-list) 0 10 ]

end

to test-mean-hydraulics  ; A test procedure to output hydraulic summary data at flows over a range

  ; Set the range of flows (m3/s) and increment
  let min-flow 0.1
  let increment 0.1
  let max-flow 70

  let this-flow min-flow

  ; Set up an output file
   file-close ; Just in case one is open.
   if file-exists? "Hydraulic-Test-Output.csv" [ file-delete "Hydraulic-Test-Output.csv" ]
   file-open "Hydraulic-Test-Output.csv"
   file-print (word "Frog model hydraulic test output file, Created " date-and-time)
   file-print "Flow,Mean depth,Mean velocity,Wetted area"

  ; Update hydraulics and write output
  while [this-flow <= max-flow]
  [
    update-hydraulics-for this-flow

    ; New write output
    let wet-cells cells with [ depth > 0 ]
    file-print (word this-flow ","
      mean [depth] of wet-cells ","
      mean [velocity] of wet-cells ","
      (count wet-cells * cell-size ) )

    ; And remember to increment the flow!
    set this-flow this-flow + increment
    show (word "Processing flow: " this-flow)

  ]   ; while

  ; Now tidy up
  file-close

end

to test-cell-hydraulics  ; A test procedure to output hydraulic data for selected cells

  ; Set the range of flows (m3/s) and increment
  let min-flow 0.1
  let increment 0.1
  let max-flow 70

  let this-flow min-flow

  ; Set up an output file
   file-close ; Just in case one is open.
   if file-exists? "Hydraulic-Cell-Test-Output.csv" [ file-delete "Hydraulic-Cell-Test-Output.csv" ]
   file-open "Hydraulic-Cell-Test-Output.csv"
   file-print (word "Frog model individual cell hydraulic test output file, Created " date-and-time)
   file-print "Cell,flow-at-wetting,Flow,Depth,Velocity"

  ; Select some cells
  let the-test-cells n-of 20 cells

  ; Update hydraulics and write output
  while [this-flow <= max-flow]
  [
    update-hydraulics-for this-flow

    ; New write output
    ask the-test-cells
    [
      file-print (word cell-number "," flow-at-wetting "," this-flow "," depth "," velocity)
    ]

    ; And remember to increment the flow!
    set this-flow this-flow + increment
    show (word "Processing flow: " this-flow)

  ]   ; while

  ; Now tidy up
  file-close

end
@#$#@#$#@
GRAPHICS-WINDOW
181
10
836
401
-1
-1
1.5
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
429
0
239
1
1
1
ticks
30.0

BUTTON
4
12
96
45
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
3
109
145
169
start-time
4/1/2013 00:00
1
0
String

BUTTON
4
63
67
96
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

OUTPUT
3
409
494
493
12

BUTTON
74
63
137
96
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

CHOOSER
4
179
96
224
shade-variable
shade-variable
"depth" "velocity"
0

SWITCH
4
232
119
265
file-output?
file-output?
1
1
-1000

PLOT
666
344
940
494
Abundance
Time step
Number
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Eggs" 1.0 0 -16777216 true "" ""
"Tadpoles" 1.0 0 -13791810 true "" ""
"New frogs" 1.0 0 -2674135 true "" ""

BUTTON
101
13
158
46
NIL
reset
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
4
271
146
304
Display has-shelter?
ask cells with [has-shelter?][set pcolor yellow]
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
3
312
174
345
Display breeder-suitable?
ask cells with [breeder-suitable?][set pcolor orange]
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
# FYFAM Yellow-legged frog model, Version 2

Last modified 7 February, 2017 (speed improvements)

## Copying
Copyright 2014, 2015 by Lang Railsback & Associates, Arcata California.
For information, contact Steve Railsback, Steve@LangRailsback.com

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program.  If not, see <http://www.gnu.org/licenses/>.

## Documentation
Version 2 of FYFAM and its software are described in a separate report, currently unpublished. The report is available from Lang Railsback & Associates.

A complete description of Version 1 of FYFAM was published as a supplement to:
Railsback, S. F., B. C. Harvey, S. J. Kupferberg, M. M. Lang, S. McBain, and H. H. J. Welsh. In press. Modeling potential river management conflicts between frogs and salmonids. Canadian Journal of Fisheries and Aquatic Sciences.


## GPL license
                    GNU GENERAL PUBLIC LICENSE
                       Version 3, 29 June 2007

 Copyright (C) 2007 Free Software Foundation, Inc. <http://fsf.org/>
 Everyone is permitted to copy and distribute verbatim copies
 of this license document, but changing it is not allowed.

                            Preamble

  The GNU General Public License is a free, copyleft license for
software and other kinds of works.

  The licenses for most software and other practical works are designed
to take away your freedom to share and change the works.  By contrast,
the GNU General Public License is intended to guarantee your freedom to
share and change all versions of a program--to make sure it remains free
software for all its users.  We, the Free Software Foundation, use the
GNU General Public License for most of our software; it applies also to
any other work released this way by its authors.  You can apply it to
your programs, too.

  When we speak of free software, we are referring to freedom, not
price.  Our General Public Licenses are designed to make sure that you
have the freedom to distribute copies of free software (and charge for
them if you wish), that you receive source code or can get it if you
want it, that you can change the software or use pieces of it in new
free programs, and that you know you can do these things.

  To protect your rights, we need to prevent others from denying you
these rights or asking you to surrender the rights.  Therefore, you have
certain responsibilities if you distribute copies of the software, or if
you modify it: responsibilities to respect the freedom of others.

  For example, if you distribute copies of such a program, whether
gratis or for a fee, you must pass on to the recipients the same
freedoms that you received.  You must make sure that they, too, receive
or can get the source code.  And you must show them these terms so they
know their rights.

  Developers that use the GNU GPL protect your rights with two steps:
(1) assert copyright on the software, and (2) offer you this License
giving you legal permission to copy, distribute and/or modify it.

  For the developers' and authors' protection, the GPL clearly explains
that there is no warranty for this free software.  For both users' and
authors' sake, the GPL requires that modified versions be marked as
changed, so that their problems will not be attributed erroneously to
authors of previous versions.

  Some devices are designed to deny users access to install or run
modified versions of the software inside them, although the manufacturer
can do so.  This is fundamentally incompatible with the aim of
protecting users' freedom to change the software.  The systematic
pattern of such abuse occurs in the area of products for individuals to
use, which is precisely where it is most unacceptable.  Therefore, we
have designed this version of the GPL to prohibit the practice for those
products.  If such problems arise substantially in other domains, we
stand ready to extend this provision to those domains in future versions
of the GPL, as needed to protect the freedom of users.

  Finally, every program is threatened constantly by software patents.
States should not allow patents to restrict development and use of
software on general-purpose computers, but in those that do, we wish to
avoid the special danger that patents applied to a free program could
make it effectively proprietary.  To prevent this, the GPL assures that
patents cannot be used to render the program non-free.

  The precise terms and conditions for copying, distribution and
modification follow.

                       TERMS AND CONDITIONS

  \0. Definitions.

  "This License" refers to version 3 of the GNU General Public License.

  "Copyright" also means copyright-like laws that apply to other kinds of
works, such as semiconductor masks.

  "The Program" refers to any copyrightable work licensed under this
License.  Each licensee is addressed as "you".  "Licensees" and
"recipients" may be individuals or organizations.

  To "modify" a work means to copy from or adapt all or part of the work
in a fashion requiring copyright permission, other than the making of an
exact copy.  The resulting work is called a "modified version" of the
earlier work or a work "based on" the earlier work.

  A "covered work" means either the unmodified Program or a work based
on the Program.

  To "propagate" a work means to do anything with it that, without
permission, would make you directly or secondarily liable for
infringement under applicable copyright law, except executing it on a
computer or modifying a private copy.  Propagation includes copying,
distribution (with or without modification), making available to the
public, and in some countries other activities as well.

  To "convey" a work means any kind of propagation that enables other
parties to make or receive copies.  Mere interaction with a user through
a computer network, with no transfer of a copy, is not conveying.

  An interactive user interface displays "Appropriate Legal Notices"
to the extent that it includes a convenient and prominently visible
feature that (1) displays an appropriate copyright notice, and (2)
tells the user that there is no warranty for the work (except to the
extent that warranties are provided), that licensees may convey the
work under this License, and how to view a copy of this License.  If
the interface presents a list of user commands or options, such as a
menu, a prominent item in the list meets this criterion.

  \1. Source Code.

  The "source code" for a work means the preferred form of the work
for making modifications to it.  "Object code" means any non-source
form of a work.

  A "Standard Interface" means an interface that either is an official
standard defined by a recognized standards body, or, in the case of
interfaces specified for a particular programming language, one that
is widely used among developers working in that language.

  The "System Libraries" of an executable work include anything, other
than the work as a whole, that (a) is included in the normal form of
packaging a Major Component, but which is not part of that Major
Component, and (b) serves only to enable use of the work with that
Major Component, or to implement a Standard Interface for which an
implementation is available to the public in source code form.  A
"Major Component", in this context, means a major essential component
(kernel, window system, and so on) of the specific operating system
(if any) on which the executable work runs, or a compiler used to
produce the work, or an object code interpreter used to run it.

  The "Corresponding Source" for a work in object code form means all
the source code needed to generate, install, and (for an executable
work) run the object code and to modify the work, including scripts to
control those activities.  However, it does not include the work's
System Libraries, or general-purpose tools or generally available free
programs which are used unmodified in performing those activities but
which are not part of the work.  For example, Corresponding Source
includes interface definition files associated with source files for
the work, and the source code for shared libraries and dynamically
linked subprograms that the work is specifically designed to require,
such as by intimate data communication or control flow between those
subprograms and other parts of the work.

  The Corresponding Source need not include anything that users
can regenerate automatically from other parts of the Corresponding
Source.

  The Corresponding Source for a work in source code form is that
same work.

  \2. Basic Permissions.

  All rights granted under this License are granted for the term of
copyright on the Program, and are irrevocable provided the stated
conditions are met.  This License explicitly affirms your unlimited
permission to run the unmodified Program.  The output from running a
covered work is covered by this License only if the output, given its
content, constitutes a covered work.  This License acknowledges your
rights of fair use or other equivalent, as provided by copyright law.

  You may make, run and propagate covered works that you do not
convey, without conditions so long as your license otherwise remains
in force.  You may convey covered works to others for the sole purpose
of having them make modifications exclusively for you, or provide you
with facilities for running those works, provided that you comply with
the terms of this License in conveying all material for which you do
not control copyright.  Those thus making or running the covered works
for you must do so exclusively on your behalf, under your direction
and control, on terms that prohibit them from making any copies of
your copyrighted material outside their relationship with you.

  Conveying under any other circumstances is permitted solely under
the conditions stated below.  Sublicensing is not allowed; section 10
makes it unnecessary.

  \3. Protecting Users' Legal Rights From Anti-Circumvention Law.

  No covered work shall be deemed part of an effective technological
measure under any applicable law fulfilling obligations under article
11 of the WIPO copyright treaty adopted on 20 December 1996, or
similar laws prohibiting or restricting circumvention of such
measures.

  When you convey a covered work, you waive any legal power to forbid
circumvention of technological measures to the extent such circumvention
is effected by exercising rights under this License with respect to
the covered work, and you disclaim any intention to limit operation or
modification of the work as a means of enforcing, against the work's
users, your or third parties' legal rights to forbid circumvention of
technological measures.

  \4. Conveying Verbatim Copies.

  You may convey verbatim copies of the Program's source code as you
receive it, in any medium, provided that you conspicuously and
appropriately publish on each copy an appropriate copyright notice;
keep intact all notices stating that this License and any
non-permissive terms added in accord with section 7 apply to the code;
keep intact all notices of the absence of any warranty; and give all
recipients a copy of this License along with the Program.

  You may charge any price or no price for each copy that you convey,
and you may offer support or warranty protection for a fee.

  \5. Conveying Modified Source Versions.

  You may convey a work based on the Program, or the modifications to
produce it from the Program, in the form of source code under the
terms of section 4, provided that you also meet all of these conditions:

    a) The work must carry prominent notices stating that you modified
    it, and giving a relevant date.

    b) The work must carry prominent notices stating that it is
    released under this License and any conditions added under section
    7.  This requirement modifies the requirement in section 4 to
    "keep intact all notices".

    c) You must license the entire work, as a whole, under this
    License to anyone who comes into possession of a copy.  This
    License will therefore apply, along with any applicable section 7
    additional terms, to the whole of the work, and all its parts,
    regardless of how they are packaged.  This License gives no
    permission to license the work in any other way, but it does not
    invalidate such permission if you have separately received it.

    d) If the work has interactive user interfaces, each must display
    Appropriate Legal Notices; however, if the Program has interactive
    interfaces that do not display Appropriate Legal Notices, your
    work need not make them do so.

  A compilation of a covered work with other separate and independent
works, which are not by their nature extensions of the covered work,
and which are not combined with it such as to form a larger program,
in or on a volume of a storage or distribution medium, is called an
"aggregate" if the compilation and its resulting copyright are not
used to limit the access or legal rights of the compilation's users
beyond what the individual works permit.  Inclusion of a covered work
in an aggregate does not cause this License to apply to the other
parts of the aggregate.

  \6. Conveying Non-Source Forms.

  You may convey a covered work in object code form under the terms
of sections 4 and 5, provided that you also convey the
machine-readable Corresponding Source under the terms of this License,
in one of these ways:

    a) Convey the object code in, or embodied in, a physical product
    (including a physical distribution medium), accompanied by the
    Corresponding Source fixed on a durable physical medium
    customarily used for software interchange.

    b) Convey the object code in, or embodied in, a physical product
    (including a physical distribution medium), accompanied by a
    written offer, valid for at least three years and valid for as
    long as you offer spare parts or customer support for that product
    model, to give anyone who possesses the object code either (1) a
    copy of the Corresponding Source for all the software in the
    product that is covered by this License, on a durable physical
    medium customarily used for software interchange, for a price no
    more than your reasonable cost of physically performing this
    conveying of source, or (2) access to copy the
    Corresponding Source from a network server at no charge.

    c) Convey individual copies of the object code with a copy of the
    written offer to provide the Corresponding Source.  This
    alternative is allowed only occasionally and noncommercially, and
    only if you received the object code with such an offer, in accord
    with subsection 6b.

    d) Convey the object code by offering access from a designated
    place (gratis or for a charge), and offer equivalent access to the
    Corresponding Source in the same way through the same place at no
    further charge.  You need not require recipients to copy the
    Corresponding Source along with the object code.  If the place to
    copy the object code is a network server, the Corresponding Source
    may be on a different server (operated by you or a third party)
    that supports equivalent copying facilities, provided you maintain
    clear directions next to the object code saying where to find the
    Corresponding Source.  Regardless of what server hosts the
    Corresponding Source, you remain obligated to ensure that it is
    available for as long as needed to satisfy these requirements.

    e) Convey the object code using peer-to-peer transmission, provided
    you inform other peers where the object code and Corresponding
    Source of the work are being offered to the general public at no
    charge under subsection 6d.

  A separable portion of the object code, whose source code is excluded
from the Corresponding Source as a System Library, need not be
included in conveying the object code work.

  A "User Product" is either (1) a "consumer product", which means any
tangible personal property which is normally used for personal, family,
or household purposes, or (2) anything designed or sold for incorporation
into a dwelling.  In determining whether a product is a consumer product,
doubtful cases shall be resolved in favor of coverage.  For a particular
product received by a particular user, "normally used" refers to a
typical or common use of that class of product, regardless of the status
of the particular user or of the way in which the particular user
actually uses, or expects or is expected to use, the product.  A product
is a consumer product regardless of whether the product has substantial
commercial, industrial or non-consumer uses, unless such uses represent
the only significant mode of use of the product.

  "Installation Information" for a User Product means any methods,
procedures, authorization keys, or other information required to install
and execute modified versions of a covered work in that User Product from
a modified version of its Corresponding Source.  The information must
suffice to ensure that the continued functioning of the modified object
code is in no case prevented or interfered with solely because
modification has been made.

  If you convey an object code work under this section in, or with, or
specifically for use in, a User Product, and the conveying occurs as
part of a transaction in which the right of possession and use of the
User Product is transferred to the recipient in perpetuity or for a
fixed term (regardless of how the transaction is characterized), the
Corresponding Source conveyed under this section must be accompanied
by the Installation Information.  But this requirement does not apply
if neither you nor any third party retains the ability to install
modified object code on the User Product (for example, the work has
been installed in ROM).

  The requirement to provide Installation Information does not include a
requirement to continue to provide support service, warranty, or updates
for a work that has been modified or installed by the recipient, or for
the User Product in which it has been modified or installed.  Access to a
network may be denied when the modification itself materially and
adversely affects the operation of the network or violates the rules and
protocols for communication across the network.

  Corresponding Source conveyed, and Installation Information provided,
in accord with this section must be in a format that is publicly
documented (and with an implementation available to the public in
source code form), and must require no special password or key for
unpacking, reading or copying.

  \7. Additional Terms.

  "Additional permissions" are terms that supplement the terms of this
License by making exceptions from one or more of its conditions.
Additional permissions that are applicable to the entire Program shall
be treated as though they were included in this License, to the extent
that they are valid under applicable law.  If additional permissions
apply only to part of the Program, that part may be used separately
under those permissions, but the entire Program remains governed by
this License without regard to the additional permissions.

  When you convey a copy of a covered work, you may at your option
remove any additional permissions from that copy, or from any part of
it.  (Additional permissions may be written to require their own
removal in certain cases when you modify the work.)  You may place
additional permissions on material, added by you to a covered work,
for which you have or can give appropriate copyright permission.

  Notwithstanding any other provision of this License, for material you
add to a covered work, you may (if authorized by the copyright holders of
that material) supplement the terms of this License with terms:

    a) Disclaiming warranty or limiting liability differently from the
    terms of sections 15 and 16 of this License; or

    b) Requiring preservation of specified reasonable legal notices or
    author attributions in that material or in the Appropriate Legal
    Notices displayed by works containing it; or

    c) Prohibiting misrepresentation of the origin of that material, or
    requiring that modified versions of such material be marked in
    reasonable ways as different from the original version; or

    d) Limiting the use for publicity purposes of names of licensors or
    authors of the material; or

    e) Declining to grant rights under trademark law for use of some
    trade names, trademarks, or service marks; or

    f) Requiring indemnification of licensors and authors of that
    material by anyone who conveys the material (or modified versions of
    it) with contractual assumptions of liability to the recipient, for
    any liability that these contractual assumptions directly impose on
    those licensors and authors.

  All other non-permissive additional terms are considered "further
restrictions" within the meaning of section 10.  If the Program as you
received it, or any part of it, contains a notice stating that it is
governed by this License along with a term that is a further
restriction, you may remove that term.  If a license document contains
a further restriction but permits relicensing or conveying under this
License, you may add to a covered work material governed by the terms
of that license document, provided that the further restriction does
not survive such relicensing or conveying.

  If you add terms to a covered work in accord with this section, you
must place, in the relevant source files, a statement of the
additional terms that apply to those files, or a notice indicating
where to find the applicable terms.

  Additional terms, permissive or non-permissive, may be stated in the
form of a separately written license, or stated as exceptions;
the above requirements apply either way.

  \8. Termination.

  You may not propagate or modify a covered work except as expressly
provided under this License.  Any attempt otherwise to propagate or
modify it is void, and will automatically terminate your rights under
this License (including any patent licenses granted under the third
paragraph of section 11).

  However, if you cease all violation of this License, then your
license from a particular copyright holder is reinstated (a)
provisionally, unless and until the copyright holder explicitly and
finally terminates your license, and (b) permanently, if the copyright
holder fails to notify you of the violation by some reasonable means
prior to 60 days after the cessation.

  Moreover, your license from a particular copyright holder is
reinstated permanently if the copyright holder notifies you of the
violation by some reasonable means, this is the first time you have
received notice of violation of this License (for any work) from that
copyright holder, and you cure the violation prior to 30 days after
your receipt of the notice.

  Termination of your rights under this section does not terminate the
licenses of parties who have received copies or rights from you under
this License.  If your rights have been terminated and not permanently
reinstated, you do not qualify to receive new licenses for the same
material under section 10.

  \9. Acceptance Not Required for Having Copies.

  You are not required to accept this License in order to receive or
run a copy of the Program.  Ancillary propagation of a covered work
occurring solely as a consequence of using peer-to-peer transmission
to receive a copy likewise does not require acceptance.  However,
nothing other than this License grants you permission to propagate or
modify any covered work.  These actions infringe copyright if you do
not accept this License.  Therefore, by modifying or propagating a
covered work, you indicate your acceptance of this License to do so.

  \10. Automatic Licensing of Downstream Recipients.

  Each time you convey a covered work, the recipient automatically
receives a license from the original licensors, to run, modify and
propagate that work, subject to this License.  You are not responsible
for enforcing compliance by third parties with this License.

  An "entity transaction" is a transaction transferring control of an
organization, or substantially all assets of one, or subdividing an
organization, or merging organizations.  If propagation of a covered
work results from an entity transaction, each party to that
transaction who receives a copy of the work also receives whatever
licenses to the work the party's predecessor in interest had or could
give under the previous paragraph, plus a right to possession of the
Corresponding Source of the work from the predecessor in interest, if
the predecessor has it or can get it with reasonable efforts.

  You may not impose any further restrictions on the exercise of the
rights granted or affirmed under this License.  For example, you may
not impose a license fee, royalty, or other charge for exercise of
rights granted under this License, and you may not initiate litigation
(including a cross-claim or counterclaim in a lawsuit) alleging that
any patent claim is infringed by making, using, selling, offering for
sale, or importing the Program or any portion of it.

  \11. Patents.

  A "contributor" is a copyright holder who authorizes use under this
License of the Program or a work on which the Program is based.  The
work thus licensed is called the contributor's "contributor version".

  A contributor's "essential patent claims" are all patent claims
owned or controlled by the contributor, whether already acquired or
hereafter acquired, that would be infringed by some manner, permitted
by this License, of making, using, or selling its contributor version,
but do not include claims that would be infringed only as a
consequence of further modification of the contributor version.  For
purposes of this definition, "control" includes the right to grant
patent sublicenses in a manner consistent with the requirements of
this License.

  Each contributor grants you a non-exclusive, worldwide, royalty-free
patent license under the contributor's essential patent claims, to
make, use, sell, offer for sale, import and otherwise run, modify and
propagate the contents of its contributor version.

  In the following three paragraphs, a "patent license" is any express
agreement or commitment, however denominated, not to enforce a patent
(such as an express permission to practice a patent or covenant not to
sue for patent infringement).  To "grant" such a patent license to a
party means to make such an agreement or commitment not to enforce a
patent against the party.

  If you convey a covered work, knowingly relying on a patent license,
and the Corresponding Source of the work is not available for anyone
to copy, free of charge and under the terms of this License, through a
publicly available network server or other readily accessible means,
then you must either (1) cause the Corresponding Source to be so
available, or (2) arrange to deprive yourself of the benefit of the
patent license for this particular work, or (3) arrange, in a manner
consistent with the requirements of this License, to extend the patent
license to downstream recipients.  "Knowingly relying" means you have
actual knowledge that, but for the patent license, your conveying the
covered work in a country, or your recipient's use of the covered work
in a country, would infringe one or more identifiable patents in that
country that you have reason to believe are valid.

  If, pursuant to or in connection with a single transaction or
arrangement, you convey, or propagate by procuring conveyance of, a
covered work, and grant a patent license to some of the parties
receiving the covered work authorizing them to use, propagate, modify
or convey a specific copy of the covered work, then the patent license
you grant is automatically extended to all recipients of the covered
work and works based on it.

  A patent license is "discriminatory" if it does not include within
the scope of its coverage, prohibits the exercise of, or is
conditioned on the non-exercise of one or more of the rights that are
specifically granted under this License.  You may not convey a covered
work if you are a party to an arrangement with a third party that is
in the business of distributing software, under which you make payment
to the third party based on the extent of your activity of conveying
the work, and under which the third party grants, to any of the
parties who would receive the covered work from you, a discriminatory
patent license (a) in connection with copies of the covered work
conveyed by you (or copies made from those copies), or (b) primarily
for and in connection with specific products or compilations that
contain the covered work, unless you entered into that arrangement,
or that patent license was granted, prior to 28 March 2007.

  Nothing in this License shall be construed as excluding or limiting
any implied license or other defenses to infringement that may
otherwise be available to you under applicable patent law.

  \12. No Surrender of Others' Freedom.

  If conditions are imposed on you (whether by court order, agreement or
otherwise) that contradict the conditions of this License, they do not
excuse you from the conditions of this License.  If you cannot convey a
covered work so as to satisfy simultaneously your obligations under this
License and any other pertinent obligations, then as a consequence you may
not convey it at all.  For example, if you agree to terms that obligate you
to collect a royalty for further conveying from those to whom you convey
the Program, the only way you could satisfy both those terms and this
License would be to refrain entirely from conveying the Program.

  \13. Use with the GNU Affero General Public License.

  Notwithstanding any other provision of this License, you have
permission to link or combine any covered work with a work licensed
under version 3 of the GNU Affero General Public License into a single
combined work, and to convey the resulting work.  The terms of this
License will continue to apply to the part which is the covered work,
but the special requirements of the GNU Affero General Public License,
section 13, concerning interaction through a network will apply to the
combination as such.

  \14. Revised Versions of this License.

  The Free Software Foundation may publish revised and/or new versions of
the GNU General Public License from time to time.  Such new versions will
be similar in spirit to the present version, but may differ in detail to
address new problems or concerns.

  Each version is given a distinguishing version number.  If the
Program specifies that a certain numbered version of the GNU General
Public License "or any later version" applies to it, you have the
option of following the terms and conditions either of that numbered
version or of any later version published by the Free Software
Foundation.  If the Program does not specify a version number of the
GNU General Public License, you may choose any version ever published
by the Free Software Foundation.

  If the Program specifies that a proxy can decide which future
versions of the GNU General Public License can be used, that proxy's
public statement of acceptance of a version permanently authorizes you
to choose that version for the Program.

  Later license versions may give you additional or different
permissions.  However, no additional obligations are imposed on any
author or copyright holder as a result of your choosing to follow a
later version.

  \15. Disclaimer of Warranty.

  THERE IS NO WARRANTY FOR THE PROGRAM, TO THE EXTENT PERMITTED BY
APPLICABLE LAW.  EXCEPT WHEN OTHERWISE STATED IN WRITING THE COPYRIGHT
HOLDERS AND/OR OTHER PARTIES PROVIDE THE PROGRAM "AS IS" WITHOUT WARRANTY
OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO,
THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
PURPOSE.  THE ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE PROGRAM
IS WITH YOU.  SHOULD THE PROGRAM PROVE DEFECTIVE, YOU ASSUME THE COST OF
ALL NECESSARY SERVICING, REPAIR OR CORRECTION.

  \16. Limitation of Liability.

  IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MODIFIES AND/OR CONVEYS
THE PROGRAM AS PERMITTED ABOVE, BE LIABLE TO YOU FOR DAMAGES, INCLUDING ANY
GENERAL, SPECIAL, INCIDENTAL OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE
USE OR INABILITY TO USE THE PROGRAM (INCLUDING BUT NOT LIMITED TO LOSS OF
DATA OR DATA BEING RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD
PARTIES OR A FAILURE OF THE PROGRAM TO OPERATE WITH ANY OTHER PROGRAMS),
EVEN IF SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

  \17. Interpretation of Sections 15 and 16.

  If the disclaimer of warranty and limitation of liability provided
above cannot be given local legal effect according to their terms,
reviewing courts shall apply local law that most closely approximates
an absolute waiver of all civil liability in connection with the
Program, unless a warranty or assumption of liability accompanies a
copy of the Program in return for a fee.

                     END OF TERMS AND CONDITIONS

            How to Apply These Terms to Your New Programs

  If you develop a new program, and you want it to be of the greatest
possible use to the public, the best way to achieve this is to make it
free software which everyone can redistribute and change under these terms.

  To do so, attach the following notices to the program.  It is safest
to attach them to the start of each source file to most effectively
state the exclusion of warranty; and each file should have at least
the "copyright" line and a pointer to where the full notice is found.

    <one line to give the program's name and a brief idea of what it does.>
    Copyright (C) <year>  <name of author>

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

Also add information on how to contact you by electronic and paper mail.

  If the program does terminal interaction, make it output a short
notice like this when it starts in an interactive mode:

    <program>  Copyright (C) <year>  <name of author>
    This program comes with ABSOLUTELY NO WARRANTY; for details type `show w'.
    This is free software, and you are welcome to redistribute it
    under certain conditions; type `show c' for details.

The hypothetical commands `show w' and `show c' should show the appropriate
parts of the General Public License.  Of course, your program's commands
might be different; for a GUI interface, you would use an "about box".

  You should also get your employer (if you work as a programmer) or school,
if any, to sign a "copyright disclaimer" for the program, if necessary.
For more information on this, and how to apply and follow the GNU GPL, see
<http://www.gnu.org/licenses/>.

  The GNU General Public License does not permit incorporating your program
into proprietary programs.  If your program is a subroutine library, you
may consider it more useful to permit linking proprietary applications with
the library.  If this is what you want to do, use the GNU Lesser General
Public License instead of this License.  But first, please read
<http://www.gnu.org/philosophy/why-not-lgpl.html>.
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

frog top
true
0
Polygon -7500403 true true 146 18 135 30 119 42 105 90 90 150 105 195 135 225 165 225 195 195 210 150 195 90 180 41 165 30 155 18
Polygon -7500403 true true 91 176 67 148 70 121 66 119 61 133 59 111 53 111 52 131 47 115 42 120 46 146 55 187 80 237 106 269 116 268 114 214 131 222
Polygon -7500403 true true 185 62 234 84 223 51 226 48 234 61 235 38 240 38 243 60 252 46 255 49 244 95 188 92
Polygon -7500403 true true 115 62 66 84 77 51 74 48 66 61 65 38 60 38 57 60 48 46 45 49 56 95 112 92
Polygon -7500403 true true 200 186 233 148 230 121 234 119 239 133 241 111 247 111 248 131 253 115 258 120 254 146 245 187 220 237 194 269 184 268 186 214 169 222
Circle -16777216 true false 157 38 18
Circle -16777216 true false 125 38 18

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
NetLogo 5.3
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="ExampleSensitivityExperiment" repetitions="1" runMetricsEveryStep="true">
    <setup>reset</setup>
    <go>go</go>
    <metric>formatted-time</metric>
    <metric>flow</metric>
    <metric>temperature</metric>
    <metric>count breeders</metric>
    <metric>count eggmasses</metric>
    <metric>count tadpoles</metric>
    <metric>number-of-new-frogs</metric>
    <metric>eggmasses-created</metric>
    <metric>eggmasses-died-desic</metric>
    <metric>eggmasses-died-scour</metric>
    <metric>eggmasses-emptied</metric>
    <metric>median-metamorph-date</metric>
    <metric>tadpoles-hatched</metric>
    <metric>tadpoles-died-desic</metric>
    <metric>tadpoles-died-scour</metric>
    <enumeratedValueSet variable="file-output?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tadpole-move-radius">
      <value value="1"/>
      <value value="3"/>
      <value value="5"/>
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

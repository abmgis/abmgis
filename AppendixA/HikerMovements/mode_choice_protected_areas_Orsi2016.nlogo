extensions [gis]

globals [strade sentieri eccellenze tamponi eccellenze_shp tamponi_shp distance_fassa distance_ega distance_busstop distance_parking roadistance_parking
  distance_ciampedie distance_coronelle distance_fronza distance_gardeccia distance_paolina distance_principe distance_realberto distance_rodadevael distance_vaiolon distance_vajolet distance_zigolade
  slope_angle aspect_angle
  time-closure time-opening first-bus-journey last-bus-journey first-lift-journey last-lift-journey accesscar1 accesscar2 buschedule1 buschedule2 liftschedule1 liftschedule2
  parking-time-pass parking-time-ciampedie parking-time-paolina
  traffic-east traffic-west traffic-east1 traffic-east2 traffic-west1 traffic-west2
  queue-bus-vigo queue-bus-carezza queue-bus-vigo1 queue-bus-vigo2 queue-bus-carezza1 queue-bus-carezza2 queue-lift-ciampedie queue-lift-paolina queue-lift-ciampedie1 queue-lift-ciampedie2 queue-lift-paolina1 queue-lift-paolina2
  crowding-pass crowding-ciampedie crowding-paolina crowding-pass1 crowding-pass2 crowding-ciampedie1 crowding-ciampedie2 crowding-paolina1 crowding-paolina2
  hours counter
  toll-factor
  lambda_m1 lambda_m2 b_toll_m1 err_toll_m1
  b_toll_m2 err_toll_m2 b_parkingpass_m1 err_parkingpass_m1 b_parkingpass_m2 err_parkingpass_m2 b_accesscar1_m1 err_accesscar1_m1 b_accesscar1_m2 err_accesscar1_m2 b_accesscar2_m1 err_accesscar2_m1 b_accesscar2_m2 err_accesscar2_m2
  b_traffic1_m1 err_traffic1_m1 b_traffic1_m2 err_traffic1_m2 b_traffic2_m1 err_traffic2_m1 b_traffic2_m2 err_traffic2_m2 b_crowding1_m1 err_crowding1_m1 b_crowding1_m2 err_crowding1_m2 b_crowding2_m1 err_crowding2_m1 b_crowding2_m2 err_crowding2_m2
  asc_bus_m1 err_ascbus_m1 asc_bus_m2 err_ascbus_m2 b_busfare_m1 err_busfare_m1 b_busfare_m2 err_busfare_m2 b_frequency_m1 err_frequency_m1 b_frequency_m2 err_frequency_m2 b_buschedule1_m1 err_buschedule1_m1 b_buschedule1_m2 err_buschedule1_m2
  b_buschedule2_m1 err_buschedule2_m1 b_buschedule2_m2 err_buschedule2_m2 b_queuebus1_m1 err_queuebus1_m1 b_queuebus1_m2 err_queuebus1_m2 b_queuebus2_m1 err_queuebus2_m1 b_queuebus2_m2 err_queuebus2_m2 asc_lift_m1 err_asclift_m1 asc_lift_m2 err_asclift_m2
  b_liftfare_m1 err_liftfare_m1 b_liftfare_m2 err_liftfare_m2 b_parkinglift_m1 err_parkinglift_m1 b_parkinglift_m2 err_parkinglift_m2 b_liftschedule1_m1 err_liftschedule1_m1 b_liftschedule1_m2 err_liftschedule1_m2
  b_liftschedule2_m1 err_liftschedule2_m1 b_liftschedule2_m2 err_liftschedule2_m2 b_queuelift1_m1 err_queuelift1_m1 b_queuelift1_m2 err_queuelift1_m2 b_queuelift2_m1 err_queuelift2_m1 b_queuelift2_m2 err_queuelift2_m2
  asc_none_m1 err_ascnone_m1 asc_none_m2 err_ascnone_m2
  paot-aquila paot-roda paot-vaiolon
  max-paot-aquila max-paot-roda max-paot-vaiolon
  tot-paot-aquila tot-paot-roda tot-paot-vaiolon
  avg-paot-aquila avg-paot-roda avg-paot-vaiolon
  low-paot-roda low-paot-aquila low-paot-vaiolon
  crowding-m1 crowding-m2 ;crowding-34
  tot-visitors
  mode1 mode2 mode3 mode5 mode6 mode7
  car-pct bus-pct none-pct road-pct lift-pct
  people-over-the-day
  traffic-eastbound traffic-westbound traffic
  tot-traffic-eastbound tot-traffic-westbound tot-traffic
  avg-traffic-eastbound avg-traffic-westbound avg-traffic
  visitor-passage tot-passage
  tot-earnings toll-earnings bus-earnings lift-earnings]

;lambda_m1 and lambda_m2 are the nest parameters of the nested logit models for the group of visitors preferring road-accessible and lift-accessible trailheads, respectively
;all global variables holding b in their names are betas of the discrete choice model, while global variables holding err in their names are the standard errors of betas
;indices m1 and m2 refer to the model of visitors preferring road-accessible trailheads and the model of visitors preferring lift-accessible trailheads, respectively

patches-own [roads trails core buffer dist_fassa dist_ega dist_busstop dist_parking roadist_parking
  dist_ciampedie dist_coronelle dist_fronza dist_gardeccia dist_paolina dist_principe dist_realberto dist_rodadevael dist_vaiolon dist_vajolet dist_zigolade
  costalunga_pass parking
  slope aspect
  potd]

breed [background-eastbound-cars background-eastbound-car] ;background-cars are cars travelling on the road: they do not stop at the pass, but contribute to traffic on the road
breed [background-westbound-cars background-westbound-car]
breed [eastbound-busses eastbound-bus]
breed [westbound-busses westbound-bus]
breed [cablecars cablecar]
breed [visitors visitor] ;visitors are intended as groups of visitors of different size (i.e. from 1 to 5 individuals)

background-eastbound-cars-own [age-car passage cumulative-passage]
background-westbound-cars-own [age-car passage cumulative-passage]
eastbound-busses-own [life-bus bus-stop time-stop occupancy]
westbound-busses-own [life-bus bus-stop time-stop occupancy]
cablecars-own [occupancy]

;bus-stop is a variable to compute the time spent at the bus stop

;terminal is a variable to verify that a bus has reached the end of the line

visitors-own [life birth group-size segment theoretical-transport-mode transport-mode waiting our-bus our-cablecar origin on-the-way-to on-the-car parking-time on-the-bus on-the-cablecar on-the-chairlift arrived
  excursion hike-stop time-stop final-time local-time time-factor advance aquila-stop
  roda-de-vael aquila paolina fronza vaiolon ciampedie gardeccia coronelle zigolade vajolet principe re-alberto
  vcar vbus vlift vnone
  logsum-car logsum-bus logsum-lift logsum-none
  nestprob-car nestprob-bus nestprob-lift nestprob-none
  in-nest-car in-nest-bus in-nest-lift in-nest-none
  pcar pbus plift pnone
  speed speed-factor alpha
  passage cumulative-passage
  crowding crowding-time crowding-ratio
  calibration calibration-time
  chairlift-calibration]

;life measures the time (in ticks) spent in the environment

;group-size expresses the number of people in a group (i.e. 1 to 5)

;segment expresses the type of visitor based on preference towards ways of access: group 1 visitors prefer road accessible trailheads, while group 2 visitors prefer lift accessible trailheads

;theoretical-transport-mode expresses the basic mode of transport chosen by visitors for their day excursion: car (1), bus (2), cable car or chairlift (3), none (4). The latter option implies that visitors
;go elsewhere because the conditions are not satisfactory

;transport-mode expresses the actual transportation option chosen by visitors given additional options available (e.g. car + lift) and constraints imposed by road closures. Additional options include:
;crossing (5), car + lift (6), bus + lift (7)

;waiting defines whether a visitor is waiting for a bus or cable car or chairlift (1) or not (0)

;origin defines whether a visitor comes from the side of Vigo di Fassa (1) or Carezza (2)

;on-the-way-to defines whether visitors are on their way to (1) the destination or on their way back (0)

;on-the-bus defines whether a visitor is on the bus (1) or not (0)

;vcar, vbus, vlift, vnone are the utilities of the four main alternatives considered in the discrete choice model



to setup
  ca

  ;GIS layers are loaded


  set eccellenze gis:load-dataset "data/eccellenze_zero.asc"
  gis:set-world-envelope gis:envelope-of eccellenze
  gis:paint eccellenze 255
  gis:apply-raster eccellenze core

  set tamponi gis:load-dataset "data/tamponi_zero.asc"
  gis:set-world-envelope gis:envelope-of eccellenze
  gis:paint tamponi 255
  gis:apply-raster tamponi buffer

  set distance_fassa gis:load-dataset "data/dist_fassa_1000.asc"
  gis:set-world-envelope gis:envelope-of eccellenze
  gis:paint distance_fassa 255
  gis:apply-raster distance_fassa dist_fassa

  set distance_ega gis:load-dataset "data/dist_ega_1000.asc"
  gis:set-world-envelope gis:envelope-of eccellenze
  gis:paint distance_ega 255
  gis:apply-raster distance_ega dist_ega

  set distance_busstop gis:load-dataset "data/dist_busstop_1000.asc"
  gis:set-world-envelope gis:envelope-of eccellenze
  gis:paint distance_busstop 255
  gis:apply-raster distance_busstop dist_busstop

  set distance_parking gis:load-dataset "data/dist_parking_1000.asc"
  gis:set-world-envelope gis:envelope-of eccellenze
  gis:paint distance_parking 255
  gis:apply-raster distance_parking dist_parking

  set roadistance_parking gis:load-dataset "data/roadist_parking_1000.asc"
  gis:set-world-envelope gis:envelope-of eccellenze
  gis:paint roadistance_parking 255
  gis:apply-raster roadistance_parking roadist_parking

  set distance_ciampedie gis:load-dataset "data/dist_ciampedie_1000.asc"
  gis:set-world-envelope gis:envelope-of eccellenze
  gis:paint distance_ciampedie 255
  gis:apply-raster distance_ciampedie dist_ciampedie

  set distance_coronelle gis:load-dataset "data/dist_coronelle_1000.asc"
  gis:set-world-envelope gis:envelope-of eccellenze
  gis:paint distance_coronelle 255
  gis:apply-raster distance_coronelle dist_coronelle

  set distance_fronza gis:load-dataset "data/dist_fronza_1000.asc"
  gis:set-world-envelope gis:envelope-of eccellenze
  gis:paint distance_fronza 255
  gis:apply-raster distance_fronza dist_fronza

  set distance_gardeccia gis:load-dataset "data/dist_gardeccia_1000.asc"
  gis:set-world-envelope gis:envelope-of eccellenze
  gis:paint distance_gardeccia 255
  gis:apply-raster distance_gardeccia dist_gardeccia

  set distance_paolina gis:load-dataset "data/dist_paolina_1000.asc"
  gis:set-world-envelope gis:envelope-of eccellenze
  gis:paint distance_paolina 255
  gis:apply-raster distance_paolina dist_paolina

  set distance_principe gis:load-dataset "data/dist_principe_1000.asc"
  gis:set-world-envelope gis:envelope-of eccellenze
  gis:paint distance_principe 255
  gis:apply-raster distance_principe dist_principe

  set distance_realberto gis:load-dataset "data/dist_realberto_1000.asc"
  gis:set-world-envelope gis:envelope-of eccellenze
  gis:paint distance_realberto 255
  gis:apply-raster distance_realberto dist_realberto

  set distance_rodadevael gis:load-dataset "data/dist_rodadevael_1000.asc"
  gis:set-world-envelope gis:envelope-of eccellenze
  gis:paint distance_rodadevael 255
  gis:apply-raster distance_rodadevael dist_rodadevael

  set distance_vaiolon gis:load-dataset "data/dist_vaiolon_1000.asc"
  gis:set-world-envelope gis:envelope-of eccellenze
  gis:paint distance_vaiolon 255
  gis:apply-raster distance_vaiolon dist_vaiolon

  set distance_vajolet gis:load-dataset "data/dist_vajolet_1000.asc"
  gis:set-world-envelope gis:envelope-of eccellenze
  gis:paint distance_vajolet 255
  gis:apply-raster distance_vajolet dist_vajolet

  set distance_zigolade gis:load-dataset "data/dist_zigolade_1000.asc"
  gis:set-world-envelope gis:envelope-of eccellenze
  gis:paint distance_zigolade 255
  gis:apply-raster distance_zigolade dist_zigolade

  set sentieri gis:load-dataset "data/sentieri_zero.asc"
  gis:set-world-envelope gis:envelope-of eccellenze
  gis:paint sentieri 255
  gis:apply-raster sentieri trails

  set strade gis:load-dataset "data/strade_zero.asc"
  gis:set-world-envelope gis:envelope-of eccellenze
  gis:paint strade 255
  gis:apply-raster strade roads

  set slope_angle gis:load-dataset "data/slope_limited.asc"
  gis:set-world-envelope gis:envelope-of eccellenze
  gis:paint slope_angle 255
  gis:apply-raster slope_angle slope

  set aspect_angle gis:load-dataset "data/aspect_final.asc"
  gis:set-world-envelope gis:envelope-of eccellenze
  gis:paint aspect_angle 255
  gis:apply-raster aspect_angle aspect




  if car-access = "free" [
    set accesscar1 -1
    set accesscar2 -1
  ]

  if car-access = "before 10am and after 4pm" [
    set time-closure 18000
    set time-opening 39600
    set accesscar1 1
    set accesscar2 0
  ]

  if car-access = "before 8am and after 6pm" [
    set time-closure 10800
    set time-opening 46800
    set accesscar1 0
    set accesscar2 1
  ]

  if bus-schedule = "6am-8pm" [
    set first-bus-journey 3600
    set last-bus-journey 54000
    set buschedule1 -1
    set buschedule2 -1
  ]

  if bus-schedule = "8am-6pm" [
    set first-bus-journey 10800
    set last-bus-journey 46800
    set buschedule1 1
    set buschedule2 0
  ]

  if bus-schedule = "10am-4pm" [
    set first-bus-journey 18000
    set last-bus-journey 39600
    set buschedule1 0
    set buschedule2 1
  ]

  if lift-schedule = "6am-8pm" [
    set first-lift-journey 3600
    set last-lift-journey 54000
    set liftschedule1 -1
    set liftschedule2 -1
  ]

  if lift-schedule = "8am-6pm" [
    set first-lift-journey 10800
    set last-lift-journey 46800
    set liftschedule1 1
    set liftschedule2 0
  ]

  if lift-schedule = "10am-4pm" [
    set first-lift-journey 18000
    set last-lift-journey 39600
    set liftschedule1 0
    set liftschedule2 1
  ]

  if (car-access != "free") and (toll-per-vehicle != 0) [
    show "WARNING: you cannot impose road toll and road restrictions simultaneously!"
  ]

setup-patches

setup-cablecars

setup-parameters

reset-ticks

end

to setup-patches
  ask patches with [(roads > 0) and (trails = 0)] [
    set pcolor yellow
  ]
  ask patches with [(trails > 0) and (roads = 0)] [
    set pcolor blue
  ]
  ask patches with [(trails > 0) and (roads > 0)] [
    set pcolor yellow
  ]
  ask patch 234 -212 [
    set pcolor red
  ]
  ask patch 217 -167 [
    set pcolor red
  ]
  ask patch 33 -267 [
    set pcolor red
  ]
  ask patch 89 -237 [
    set pcolor red
  ]
end

to setup-cablecars
  create-cablecars 2
  ask cablecar 0 [
    setxy 234 -212
    set color red
  ]
  ask cablecar 1 [
    setxy 217 -167
    set color red
  ]
end

to setup-parameters

  set lambda_m1 0.547
  set lambda_m2 0.749
  set b_toll_m1 -0.119
  set err_toll_m1 0.022
  set b_toll_m2 -0.095
  set err_toll_m2 0.02
  set b_parkingpass_m1 -0.057
  set err_parkingpass_m1 0.019
  set b_parkingpass_m2 -0.046
  set err_parkingpass_m2 0.017
  set b_accesscar1_m1 -0.032
  set err_accesscar1_m1 0.209
  set b_accesscar1_m2 0.06
  set err_accesscar1_m2 0.176
  set b_accesscar2_m1 -0.658
  set err_accesscar2_m1 0.251
  set b_accesscar2_m2 -0.876
  set err_accesscar2_m2 0.264
  set b_traffic1_m1 0.395
  set err_traffic1_m1 0.212
  set b_traffic1_m2 0.361
  set err_traffic1_m2 0.196
  set b_traffic2_m1 -0.341
  set err_traffic2_m1 0.215
  set b_traffic2_m2 -0.647
  set err_traffic2_m2 0.242
  set b_crowding1_m1 -0.069
  set err_crowding1_m1 0.127
  set b_crowding1_m2 0.172
  set err_crowding1_m2 0.088
  set b_crowding2_m1 -0.39
  set err_crowding2_m1 0.133
  set b_crowding2_m2 -0.496
  set err_crowding2_m2 0.135
  set asc_bus_m1 0.005
  set err_ascbus_m1 0.445
  set asc_bus_m2 1.09
  set err_ascbus_m2 0.401
  set b_busfare_m1 -0.252
  set err_busfare_m1 0.057
  set b_busfare_m2 -0.095
  set err_busfare_m2 0.041
  set b_frequency_m1 -0.008
  set err_frequency_m1 0.008
  set b_frequency_m2 -0.031
  set err_frequency_m2 0.008
  set b_buschedule1_m1 0.551
  set err_buschedule1_m1 0.19
  set b_buschedule1_m2 0.442
  set err_buschedule1_m2 0.152
  set b_buschedule2_m1 -1.24
  set err_buschedule2_m1 0.256
  set b_buschedule2_m2 -0.673
  set err_buschedule2_m2 0.181
  set b_queuebus1_m1 -0.215
  set err_queuebus1_m1 0.18
  set b_queuebus1_m2 -0.012
  set err_queuebus1_m2 0.132
  set b_queuebus2_m1 -0.101
  set err_queuebus2_m1 0.174
  set b_queuebus2_m2 -0.346
  set err_queuebus2_m2 0.154
  set asc_lift_m1 0.428
  set err_asclift_m1 0.546
  set asc_lift_m2 1.72
  set err_asclift_m2 0.467
  set b_liftfare_m1 -0.31
  set err_liftfare_m1 0.069
  set b_liftfare_m2 -0.118
  set err_liftfare_m2 0.025
  set b_parkinglift_m1 -0.076
  set err_parkinglift_m1 0.029
  set b_parkinglift_m2 -0.036
  set err_parkinglift_m2 0.014
  set b_liftschedule1_m1 0.426
  set err_liftschedule1_m1 0.315
  set b_liftschedule1_m2 0.187
  set err_liftschedule1_m2 0.136
  set b_liftschedule2_m1 -0.842
  set err_liftschedule2_m1 0.352
  set b_liftschedule2_m2 -0.27
  set err_liftschedule2_m2 0.146
  set b_queuelift1_m1 -0.17
  set err_queuelift1_m1 0.31
  set b_queuelift1_m2 -0.043
  set err_queuelift1_m2 0.132
  set b_queuelift2_m1 0.298
  set err_queuelift2_m1 0.315
  set b_queuelift2_m2 -0.373
  set err_queuelift2_m2 0.155
  set asc_none_m1 -2.26
  set err_ascnone_m1 0.295
  set asc_none_m2 -1.57
  set err_ascnone_m2 0.303

  ; toll-factor is a parameter used to reduce the amount of background traffic according to the toll
  set toll-factor 0.02 * toll-per-vehicle + 1

end


to go
  compute-parameters
  generate-visitors
  generate-background-traffic
  generate-eastbound-busses
  generate-westbound-busses
  move-background-traffic
  move-eastbound-busses
  move-westbound-busses
  move-cablecars
  choose-transport
  get-on-the-car
  drive
  park-the-car
  get-on-bus
  get-off-bus
  get-on-cablecar
  get-off-cablecar
  take-the-chairlift
  choose-excursion
  hike
  do-plots
  compute-outputs
  calibrate
  if ticks = last-lift-journey + 2000 [
    type toll-per-vehicle type ";" type bus-ticket type ";" type lift-ticket type ";" type bus-frequency type ";" type tot-visitors type ";"
    type max-paot-roda type ";" type max-paot-aquila type ";" type max-paot-vaiolon type ";"
    type avg-paot-roda type ";" type avg-paot-aquila type ";" type avg-paot-vaiolon type ";"
    type low-paot-roda type ";" type low-paot-aquila type ";" type low-paot-vaiolon type ";"
    type crowding-m1 type ";" type crowding-m2 type ";"
    type people-over-the-day type ";"
    type mode1 type ";" type mode2 type ";" type mode3 type";" type none-pct type ";" type mode5 type ";" type mode6 type ";" type mode7 type ";"
    type car-pct type ";" type bus-pct type ";" type road-pct type ";" type lift-pct type ";"
    type avg-traffic-eastbound type ";" type avg-traffic-westbound type ";" type avg-traffic type ";" type visitor-passage type ";" type tot-passage type ";"
    type toll-earnings type ";" type bus-earnings type ";" type lift-earnings type ";" print tot-earnings
  ]
  tick
end

;parameters of the effect coded variables (e.g. traffic, queues at lifts) are computed
;traffic is measured as the number of cars on the road divided by the length of the road (expressed as the length of the road): traffic-west is the traffic of cars heading west, while traffic-east is that of cars heading east

to compute-parameters

  set parking-time-pass (([parking] of patch 88 -277) * 10) / 60

  set parking-time-ciampedie (([parking] of patch 235 -212) * 5) / 60

  set parking-time-paolina (([parking] of patch 33 -268) * 5) / 60

  set traffic-west (count visitors with [(origin = 1) and (on-the-car = 1) and (xcor > 100) and (xcor < 230)])
  + (count background-westbound-cars with [(xcor > 100) and (xcor < 230)]) / count patches with [(pcolor = yellow) and (pxcor > 100) and (pxcor < 230)]

  set traffic-east (count visitors with [(origin = 2) and (on-the-car = 1) and (xcor > 40) and (xcor < 75)])
  + (count background-eastbound-cars with [(xcor > 40) and (xcor < 75)]) / count patches with [(pcolor = yellow) and (pxcor > 40) and (pxcor < 75)]


  ifelse traffic-east <= 0.1
  [set traffic-east1 -1
    set traffic-east2 -1]
  [ifelse traffic-east <= 0.5
    [set traffic-east1 1
      set traffic-east2 0]
    [set traffic-east1 0
      set traffic-east2 1]
  ]


  ifelse traffic-west <= 0.1
  [set traffic-west1 -1
    set traffic-west2 -1]
  [ifelse traffic-west <= 0.5
    [set traffic-west1 1
      set traffic-west2 0]
    [set traffic-west1 0
      set traffic-west2 1]
  ]

  if ticks mod bus-frequency = 0 [
    set queue-bus-vigo sum [group-size] of visitors with [(pxcor = 236) and (pycor = -215) and (waiting > 1)]
  ]

  if ticks mod bus-frequency = 0 [
    set queue-bus-carezza sum [group-size] of visitors with [(pxcor = 29) and (pycor = -270) and (waiting > 1)]
  ]

  ifelse queue-bus-vigo <= 10
  [set queue-bus-vigo1 -1
    set queue-bus-vigo2 -1]
  [ifelse queue-bus-vigo <= 50
    [set queue-bus-vigo1 1
      set queue-bus-vigo2 0]
    [set queue-bus-vigo1 0
      set queue-bus-vigo2 1]
  ]

  ifelse queue-bus-carezza <= 10
  [set queue-bus-carezza1 -1
    set queue-bus-carezza2 -1]
  [ifelse queue-bus-carezza <= 50
    [set queue-bus-carezza1 1
      set queue-bus-carezza2 0]
    [set queue-bus-carezza1 0
      set queue-bus-carezza2 1]
  ]

  set queue-lift-ciampedie sum [group-size] of visitors with [(pxcor >= 234) and (pxcor <= 235) and (pycor = -212) and (waiting >= 1)]

  set queue-lift-paolina sum [group-size] of visitors with [(pxcor = 33) and (pycor = -268) and (waiting >= 1)]

  ifelse queue-lift-ciampedie <= 50
  [set queue-lift-ciampedie1 -1
    set queue-lift-ciampedie2 -1]
  [ifelse queue-lift-ciampedie <= 100
    [set queue-lift-ciampedie1 1
      set queue-lift-ciampedie2 0]
    [set queue-lift-ciampedie1 0
      set queue-lift-ciampedie2 1]
  ]

  ifelse queue-lift-paolina <= 50
  [set queue-lift-paolina1 -1
    set queue-lift-paolina2 -1]
  [ifelse queue-lift-paolina <= 100
    [set queue-lift-paolina1 1
      set queue-lift-paolina2 0]
    [set queue-lift-paolina1 0
      set queue-lift-paolina2 1]
  ]

  set crowding-pass sum [group-size] of visitors with [(pxcor > 84) and (pxcor < 137) and (pycor > -268) and (pycor < -248)] / count patches with [(pxcor > 84) and (pxcor < 137) and (pycor > -268) and (pycor < -248) and (pcolor = blue)]

  set crowding-ciampedie sum [group-size] of visitors with [(pxcor > 142) and (pxcor < 205) and (pycor > -196) and (pycor < -130)] / count patches with [(pxcor > 142) and (pxcor < 205) and (pycor > -196) and (pycor < -130) and (pcolor = blue)]

  set crowding-paolina sum [group-size] of visitors with [(pxcor > 95) and (pxcor < 129) and (pycor > -246) and (pycor < -230)] / count patches with [(pxcor > 95) and (pxcor < 129) and (pycor > -246) and (pycor < -230) and (pcolor = blue)]

  ifelse crowding-pass <= 1
  [set crowding-pass1 -1
    set crowding-pass2 -1]
  [ifelse crowding-pass <= 2
    [set crowding-pass1 1
      set crowding-pass2 0]
    [set crowding-pass1 0
      set crowding-pass2 1]
  ]

  ifelse crowding-ciampedie <= 1
  [set crowding-ciampedie1 -1
    set crowding-ciampedie2 -1]
  [ifelse crowding-ciampedie <= 2
    [set crowding-ciampedie1 1
      set crowding-ciampedie2 0]
    [set crowding-ciampedie1 0
      set crowding-ciampedie2 1]
  ]

  ifelse crowding-ciampedie <= 1
  [set crowding-ciampedie1 -1
    set crowding-ciampedie2 -1]
  [ifelse crowding-ciampedie <= 2
    [set crowding-ciampedie1 1
      set crowding-ciampedie2 0]
    [set crowding-ciampedie1 0
      set crowding-ciampedie2 1]
  ]

end

;visitors are generated in Vigo and Carezza according to the average distribution measured in the field and up to the total visitor flow defined by the user
;the total number of visitors specified by the user is distributed across hours based on observations in the field, then one visitor (in fact a group of visitors travelling together) is generated every x seconds, where x is determined by the number
;of visitors to be generated in one hour (e.g. if during one hour a total of 1200 visitors have to be generated, one group of visitors is generated every 9 seconds because, considering an average of 3 people per group, 1000 visitors are equivalent
;to 400 groups, namely one every 9 seconds

to generate-visitors
  if (ticks > 7200) and (ticks <= 10800) and (int(ticks mod ((3600 * 3) / (0.05 * visitor-flow))) = 0) and (sum [group-size] of visitors < visitor-flow) [
    create-visitors 1]
  if (ticks > 10800) and (ticks <= 14400) and (int(ticks mod ((3600 * 3) / (0.28 * visitor-flow))) = 0) and (sum [group-size] of visitors < visitor-flow) [
    create-visitors 1]
  if (ticks > 14400) and (ticks <= 18000) and (int(ticks mod ((3600 * 3) / (0.31 * visitor-flow))) = 0) and (sum [group-size] of visitors < visitor-flow) [
    create-visitors 1]
  if (ticks > 18000) and (ticks <= 21600) and (int(ticks mod ((3600 * 3) / (0.23 * visitor-flow))) = 0) and (sum [group-size] of visitors < visitor-flow) [
    create-visitors 1]
  if (ticks > 21600) and (ticks <= 25200) and (int(ticks mod ((3600 * 3) / (0.13 * visitor-flow))) = 0) and (sum [group-size] of visitors < visitor-flow) [
    create-visitors 1]
  if (ticks > 25200) and (ticks <= 28800) and (int(ticks mod ((3600 * 3) / (0.13 * visitor-flow))) = 0) and (sum [group-size] of visitors < visitor-flow) [
    create-visitors 1]
  ask visitors [
    set life life + 1
  ]
  ask visitors [
    if life = 1 [
    set birth ticks
    set group-size 1 + random 5
    set on-the-way-to 1
    set speed-factor random-float 0.004 - random-float 0.004
    set advance random 900
    set aquila-stop random 150
    ifelse random 100 < visitors-in-vigo
    [set origin 1]
    [set origin 2]
    ifelse random 100 < road-access
    [set segment 1]
    [set segment 2]

    ]
  ]
  ask visitors [
    if (life = 1) and (origin = 1) [
      setxy 244 -211
    ]
  ]
  ask visitors [
    if (life = 1) and (origin = 2) [
      setxy 25 -270
    ]
  ]

  ask visitors [
    ifelse transport-mode = 1
    [set final-time 48600]
    [ifelse transport-mode = 2
      [set final-time last-bus-journey - 1800]
      [ifelse (transport-mode = 3) and (excursion < 30)
        [set final-time last-lift-journey]
        [ifelse (transport-mode = 3) and (excursion > 30)
          [set final-time last-lift-journey + 1800]
          [ifelse transport-mode = 4
            [set final-time 0]
            [ifelse (transport-mode = 5) and (last-bus-journey > last-lift-journey)
              [set final-time last-lift-journey - 3600]
              [ifelse (transport-mode = 5) and (last-bus-journey < last-lift-journey)
                [set final-time last-bus-journey - 3600]
                [ifelse transport-mode = 6
                  [set final-time last-lift-journey - 1800]
                  [ifelse (transport-mode = 7) and (last-bus-journey > last-lift-journey)
                    [set final-time last-lift-journey]
                    [set final-time last-bus-journey - 3600]
                  ]
                ]
              ]
            ]
          ]
        ]
      ]
    ]
  ]

end


to generate-background-traffic
  ifelse car-access = "free"
    [if (ticks > 0) and (ticks <= 3600) and (int(ticks mod ((3600 * toll-factor) / (0.003 * visitor-flow))) = 0) [
      create-background-eastbound-cars 1]
     if (ticks > 3600) and (ticks <= 7200) and (int(ticks mod ((3600 * toll-factor) / (0.005 * visitor-flow))) = 0) [
      create-background-eastbound-cars 1]
     if (ticks > 7200) and (ticks <= 10800) and (int(ticks mod ((3600 * toll-factor) / (0.02 * visitor-flow))) = 0) [
      create-background-eastbound-cars 1]
     if (ticks > 10800) and (ticks <= 14400) and (int(ticks mod ((3600 * toll-factor) / (0.029 * visitor-flow))) = 0) [
      create-background-eastbound-cars 1]
     if (ticks > 14400) and (ticks <= 18000) and (int(ticks mod ((3600 * toll-factor) / (0.087 * visitor-flow))) = 0) [
      create-background-eastbound-cars 1]
     if (ticks > 18000) and (ticks <= 21600) and (int(ticks mod ((3600 * toll-factor) / (0.107 * visitor-flow))) = 0) [
      create-background-eastbound-cars 1]
     if (ticks > 21600) and (ticks <= 25200) and (int(ticks mod ((3600 * toll-factor) / (0.131 * visitor-flow))) = 0) [
      create-background-eastbound-cars 1]
     if (ticks > 25200) and (ticks <= 28800) and (int(ticks mod ((3600 * toll-factor) / (0.096 * visitor-flow))) = 0) [
      create-background-eastbound-cars 1]
     if (ticks > 28800) and (ticks <= 32400) and (int(ticks mod ((3600 * toll-factor) / (0.084 * visitor-flow))) = 0) [
      create-background-eastbound-cars 1]
     if (ticks > 32400) and (ticks <= 36000) and (int(ticks mod ((3600 * toll-factor) / (0.102 * visitor-flow))) = 0) [
      create-background-eastbound-cars 1]
     if (ticks > 36000) and (ticks <= 39600) and (int(ticks mod ((3600 * toll-factor) / (0.117 * visitor-flow))) = 0) [
      create-background-eastbound-cars 1]
     if (ticks > 39600) and (ticks <= 43200) and (int(ticks mod ((3600 * toll-factor) / (0.153 * visitor-flow))) = 0) [
      create-background-eastbound-cars 1]
     if (ticks > 43200) and (ticks <= 46800) and (int(ticks mod ((3600 * toll-factor) / (0.122 * visitor-flow))) = 0) [
      create-background-eastbound-cars 1]
     if (ticks > 46800) and (ticks <= 50400) and (int(ticks mod ((3600 * toll-factor) / (0.066 * visitor-flow))) = 0) [
      create-background-eastbound-cars 1]
     if (ticks > 50400) and (ticks <= 54000) and (int(ticks mod ((3600 * toll-factor) / (0.044 * visitor-flow))) = 0) [
      create-background-eastbound-cars 1]
     if (ticks > 54000) and (ticks <= 57600) and (int(ticks mod ((3600 * toll-factor) / (0.020 * visitor-flow))) = 0) [
      create-background-eastbound-cars 1]

    ]


  [ifelse car-access = "before 10am and after 4pm"
    [if (ticks > 0) and (ticks <= 3600) and (int(ticks mod (3600 / (0.003 * visitor-flow))) = 0) [
      create-background-eastbound-cars 1]
     if (ticks > 3600) and (ticks <= 7200) and (int(ticks mod (3600 / (0.005 * visitor-flow))) = 0) [
      create-background-eastbound-cars 1]
     if (ticks > 7200) and (ticks <= 10800) and (int(ticks mod (3600 / (0.02 * visitor-flow))) = 0) [
      create-background-eastbound-cars 1]
     if (ticks > 10800) and (ticks <= 14400) and (int(ticks mod (3600 / (0.029 * visitor-flow))) = 0) [
      create-background-eastbound-cars 1]
     if (ticks > 14400) and (ticks <= 18000) and (int(ticks mod (3600 / (0.137 * visitor-flow))) = 0) [
      create-background-eastbound-cars 1]
     if (ticks > 39600) and (ticks <= 43200) and (int(ticks mod (3600 / (0.203 * visitor-flow))) = 0) [
      create-background-eastbound-cars 1]
     if (ticks > 43200) and (ticks <= 46800) and (int(ticks mod (3600 / (0.122 * visitor-flow))) = 0) [
      create-background-eastbound-cars 1]
     if (ticks > 46800) and (ticks <= 50400) and (int(ticks mod (3600 / (0.066 * visitor-flow))) = 0) [
      create-background-eastbound-cars 1]
     if (ticks > 50400) and (ticks <= 54000) and (int(ticks mod (3600 / (0.044 * visitor-flow))) = 0) [
      create-background-eastbound-cars 1]
     if (ticks > 54000) and (ticks <= 57600) and (int(ticks mod (3600 / (0.020 * visitor-flow))) = 0) [
      create-background-eastbound-cars 1]

    ]

    [if (ticks > 0) and (ticks <= 3600) and (int(ticks mod (3600 / (0.003 * visitor-flow))) = 0) [
      create-background-eastbound-cars 1]
     if (ticks > 3600) and (ticks <= 7200) and (int(ticks mod (3600 / (0.005 * visitor-flow))) = 0) [
      create-background-eastbound-cars 1]
     if (ticks > 7200) and (ticks <= 10800) and (int(ticks mod (3600 / (0.05 * visitor-flow))) = 0) [
      create-background-eastbound-cars 1]
     if (ticks > 46800) and (ticks <= 50400) and (int(ticks mod (3600 / (0.076 * visitor-flow))) = 0) [
      create-background-eastbound-cars 1]
     if (ticks > 50400) and (ticks <= 54000) and (int(ticks mod (3600 / (0.044 * visitor-flow))) = 0) [
      create-background-eastbound-cars 1]
     if (ticks > 54000) and (ticks <= 57600) and (int(ticks mod (3600 / (0.020 * visitor-flow))) = 0) [
      create-background-eastbound-cars 1]

    ]
  ]


   ifelse car-access = "free"
    [if (ticks > 0) and (ticks <= 3600) and (int(ticks mod ((3600 * toll-factor) / (0.003 * visitor-flow))) = 0) [
      create-background-westbound-cars 1]
     if (ticks > 3600) and (ticks <= 7200) and (int(ticks mod ((3600 * toll-factor) / (0.009 * visitor-flow))) = 0) [
      create-background-westbound-cars 1]
     if (ticks > 7200) and (ticks <= 10800) and (int(ticks mod ((3600 * toll-factor) / (0.018 * visitor-flow))) = 0) [
      create-background-westbound-cars 1]
     if (ticks > 10800) and (ticks <= 14400) and (int(ticks mod ((3600 * toll-factor) / (0.044 * visitor-flow))) = 0) [
      create-background-westbound-cars 1]
     if (ticks > 14400) and (ticks <= 18000) and (int(ticks mod ((3600 * toll-factor) / (0.128 * visitor-flow))) = 0) [
      create-background-westbound-cars 1]
     if (ticks > 18000) and (ticks <= 21600) and (int(ticks mod ((3600 * toll-factor) / (0.158 * visitor-flow))) = 0) [
      create-background-westbound-cars 1]
     if (ticks > 21600) and (ticks <= 25200) and (int(ticks mod ((3600 * toll-factor) / (0.12 * visitor-flow))) = 0) [
      create-background-westbound-cars 1]
     if (ticks > 25200) and (ticks <= 28800) and (int(ticks mod ((3600 * toll-factor) / (0.093 * visitor-flow))) = 0) [
      create-background-westbound-cars 1]
     if (ticks > 28800) and (ticks <= 32400) and (int(ticks mod ((3600 * toll-factor) / (0.072 * visitor-flow))) = 0) [
      create-background-westbound-cars 1]
     if (ticks > 32400) and (ticks <= 36000) and (int(ticks mod ((3600 * toll-factor) / (0.102 * visitor-flow))) = 0) [
      create-background-westbound-cars 1]
     if (ticks > 36000) and (ticks <= 39600) and (int(ticks mod ((3600 * toll-factor) / (0.104 * visitor-flow))) = 0) [
      create-background-westbound-cars 1]
     if (ticks > 39600) and (ticks <= 43200) and (int(ticks mod ((3600 * toll-factor) / (0.108 * visitor-flow))) = 0) [
      create-background-westbound-cars 1]
     if (ticks > 43200) and (ticks <= 46800) and (int(ticks mod ((3600 * toll-factor) / (0.089 * visitor-flow))) = 0) [
      create-background-westbound-cars 1]
     if (ticks > 46800) and (ticks <= 50400) and (int(ticks mod ((3600 * toll-factor) / (0.071 * visitor-flow))) = 0) [
      create-background-westbound-cars 1]
     if (ticks > 50400) and (ticks <= 54000) and (int(ticks mod ((3600 * toll-factor) / (0.030 * visitor-flow))) = 0) [
      create-background-westbound-cars 1]
     if (ticks > 54000) and (ticks <= 57600) and (int(ticks mod ((3600 * toll-factor) / (0.018 * visitor-flow))) = 0) [
      create-background-westbound-cars 1]

    ]


  [ifelse car-access = "before 10am and after 4pm"
    [if (ticks > 0) and (ticks <= 3600) and (int(ticks mod (3600 / (0.003 * visitor-flow))) = 0) [
      create-background-westbound-cars 1]
     if (ticks > 3600) and (ticks <= 7200) and (int(ticks mod (3600 / (0.009 * visitor-flow))) = 0) [
      create-background-westbound-cars 1]
     if (ticks > 7200) and (ticks <= 10800) and (int(ticks mod (3600 / (0.018 * visitor-flow))) = 0) [
      create-background-westbound-cars 1]
     if (ticks > 10800) and (ticks <= 14400) and (int(ticks mod (3600 / (0.044 * visitor-flow))) = 0) [
      create-background-westbound-cars 1]
     if (ticks > 14400) and (ticks <= 18000) and (int(ticks mod (3600 / (0.178 * visitor-flow))) = 0) [
      create-background-westbound-cars 1]
     if (ticks > 39600) and (ticks <= 43200) and (int(ticks mod (3600 / (0.158 * visitor-flow))) = 0) [
      create-background-westbound-cars 1]
     if (ticks > 43200) and (ticks <= 46800) and (int(ticks mod (3600 / (0.089 * visitor-flow))) = 0) [
      create-background-westbound-cars 1]
     if (ticks > 46800) and (ticks <= 50400) and (int(ticks mod (3600 / (0.071 * visitor-flow))) = 0) [
      create-background-westbound-cars 1]
     if (ticks > 50400) and (ticks <= 54000) and (int(ticks mod (3600 / (0.030 * visitor-flow))) = 0) [
      create-background-westbound-cars 1]
     if (ticks > 54000) and (ticks <= 57600) and (int(ticks mod (3600 / (0.018 * visitor-flow))) = 0) [
      create-background-westbound-cars 1]

    ]

    [if (ticks > 0) and (ticks <= 3600) and (int(ticks mod (3600 / (0.003 * visitor-flow))) = 0) [
      create-background-westbound-cars 1]
     if (ticks > 3600) and (ticks <= 7200) and (int(ticks mod (3600 / (0.009 * visitor-flow))) = 0) [
      create-background-westbound-cars 1]
     if (ticks > 7200) and (ticks <= 10800) and (int(ticks mod (3600 / (0.021 * visitor-flow))) = 0) [
      create-background-westbound-cars 1]
     if (ticks > 46800) and (ticks <= 50400) and (int(ticks mod (3600 / (0.081 * visitor-flow))) = 0) [
      create-background-westbound-cars 1]
     if (ticks > 50400) and (ticks <= 54000) and (int(ticks mod (3600 / (0.030 * visitor-flow))) = 0) [
      create-background-westbound-cars 1]
     if (ticks > 54000) and (ticks <= 57600) and (int(ticks mod (3600 / (0.018 * visitor-flow))) = 0) [
      create-background-westbound-cars 1]

    ]
  ]

  ask background-eastbound-cars [
    set age-car age-car + 1
  ]
   ask background-eastbound-cars [
      if age-car = 1 [     ;this condition ensures that cars already travelling are not brought back to the starting point
      setxy 4 -261
    ]
  ]
  ask background-westbound-cars [
    set age-car age-car + 1
  ]
   ask background-westbound-cars [
      if age-car = 1 [     ;this condition ensures that cars already travelling are not brought back to the starting point
      setxy 251 -200
    ]
  ]
end

;busses going to the east (Vigo) are generated in Carezza according to the frequency set by the user

to generate-eastbound-busses
  if (ticks >= first-bus-journey) and (ticks <= last-bus-journey) and ((ticks - 3600) mod (bus-frequency * 60) = 0) [
    create-eastbound-busses 1]
    ask eastbound-busses [
      set life-bus life-bus + 1
      set color grey
    ]
    ask eastbound-busses [
      if life-bus = 1 [      ;this condition ensures that busses already travelling are not brought back to the starting point
      setxy 17 -275
    ]
  ]
end

;busses going to the west (Carezza) are generated in Vigo according to the frequency set by the user

to generate-westbound-busses
  if (ticks >= first-bus-journey) and (ticks <= last-bus-journey) and ((ticks - 3600) mod (bus-frequency * 60) = 0) [
    create-westbound-busses 1]
    ask westbound-busses [
      set life-bus life-bus + 1
      set color grey
    ]
    ask westbound-busses [
      if life-bus = 1 [      ;this condition ensures that busses already travelling are not brought back to the starting point
      setxy 250 -222
    ]
  ]
end


;cars move following patches with a decreasing cost distance from either Vigo (eastbound) or Carezza (westbound)

to move-background-traffic
  ask background-eastbound-cars [
      face min-one-of neighbors [dist_fassa]
      fd 0.5 + random-float 0.2
  ]
  ask background-eastbound-cars [
    if pxcor > 244 [
      die
    ]
  ]
  ask background-westbound-cars [
      face min-one-of neighbors [dist_ega]
      fd 0.5 + random-float 0.2
  ]
  ask background-westbound-cars [
    if pxcor < 19 [
      die
    ]
  ]
end

;busses move following patches with a decreasing cost distance from either Vigo (eastbound) or Carezza (westbound)

to move-eastbound-busses
  ask eastbound-busses with [life-bus > 1] [
    ifelse (time-stop > 0) and (time-stop < 5)
    []
    [face min-one-of neighbors [dist_fassa]
      fd 0.5]
    if (pxcor = 234) and (pycor = -216) [
      set bus-stop 1
    ]

    if (pxcor = 79) and (pycor = -280) [
      set bus-stop 2
    ]

    if (pxcor = 80) and (pycor = -280) [
      set bus-stop 2
    ]

    if (pxcor = 29) and (pycor = -271) [
      set bus-stop 3
    ]
    if (bus-stop = 1) or (bus-stop = 2) or (bus-stop = 3) [
      set time-stop time-stop + 1
  ]
    if time-stop = 5 [
      set bus-stop 0
      set time-stop 0
    ]
    if pxcor > 244 [
      die
    ]
  ]
end

to move-westbound-busses
  ask westbound-busses with [life-bus > 1] [
    ifelse (time-stop > 0) and (time-stop < 5)
    []
    [face min-one-of neighbors [dist_ega]
      fd 0.5]
    if (pxcor = 236) and (pycor = -216) [
      set bus-stop 1
    ]

    if (pxcor = 82) and (pycor = -280) [
      set bus-stop 2
    ]
    if (pxcor = 83) and (pycor = -280) [
      set bus-stop 2
    ]

    if (pxcor = 31) and (pycor = -271) [
      set bus-stop 3
    ]
    if (bus-stop = 1) or (bus-stop = 2) or (bus-stop = 3) [
      set time-stop time-stop + 1
  ]
    if time-stop = 5 [
      set bus-stop 0
      set time-stop 0
    ]
    if pxcor < 19 [
      die
    ]
  ]
end

;cablecars move every 15 minutes according to the real frequency of service

to move-cablecars
  ask cablecars [
    if (xcor > 233.5) and (ycor < -211.5) [
      face patch 217 -167
    ]
    if (xcor < 217.5) and (ycor > -167.5) [
      face patch 234 -212
    ]
  ]
    ask cablecars [
      if ((ticks mod 900 = 0) and (pcolor = red) and (ticks >= first-lift-journey + 1800) and (ticks <= 28800)) or
      ((ticks mod 900 = 0) and (pcolor = red) and (ticks >= 32400) and (ticks <= last-lift-journey + 1800)) [
        fd 1
      ]
      if pcolor != red [
        fd 0.2
      ]
    ]
end

;visitors choose their mode of transport given the conditions of access (e.g. toll, schedules, etc.) imposed by the user. Distinction is made between free and restricted access: in the latter case, if a visitor is generated after the road has been closed,
;the car option is simply removed from the list of transport options available

to choose-transport
  ask visitors with [(segment = 1) and (origin = 1) and (theoretical-transport-mode = 0)] [
    if (life = 3599) or (ticks = time-closure - advance) [

      set vcar (b_toll_m1 + random-float err_toll_m1 - random-float err_toll_m1) * toll-per-vehicle + (b_parkingpass_m1 + random-float err_parkingpass_m1 - random-float err_parkingpass_m1) * parking-time-pass + (b_accesscar1_m1 + random-float err_accesscar1_m1
          - random-float err_accesscar1_m1) * accesscar1 + (b_accesscar2_m1 + random-float err_accesscar2_m1 - random-float err_accesscar2_m1) * accesscar2 + (b_traffic1_m1 + random-float err_traffic1_m1 - random-float err_traffic1_m1) * traffic-west1
          + (b_traffic2_m1 + random-float err_traffic2_m1 - random-float err_traffic2_m1) * traffic-west2 + (b_crowding1_m1 + random-float err_crowding1_m1 - random-float err_crowding1_m1) * crowding-pass1 + (b_crowding2_m1 + random-float err_crowding2_m1
          - random-float err_crowding2_m1) * crowding-pass2

      set vbus asc_bus_m1 + random-float err_ascbus_m1 - random-float err_ascbus_m1 + (b_busfare_m1 + random-float err_busfare_m1 - random-float err_busfare_m1) * bus-ticket + (b_frequency_m1 + random-float err_frequency_m1 - random-float err_frequency_m1) * bus-frequency
          + (b_buschedule1_m1 + random-float err_buschedule1_m1 - random-float err_buschedule1_m1) * buschedule1 + (b_buschedule2_m1 + random-float err_buschedule2_m1 - random-float err_buschedule2_m1) * buschedule2 + (b_queuebus1_m1 + random-float err_queuebus1_m1
          - random-float err_queuebus1_m1) * queue-bus-vigo1 + (b_queuebus2_m1 + random-float err_queuebus2_m1 - random-float err_queuebus2_m1) * queue-bus-vigo2 + (b_crowding1_m1 + random-float err_crowding1_m1 - random-float err_crowding1_m1) * crowding-pass1
          + (b_crowding2_m1 + random-float err_crowding2_m1 - random-float err_crowding2_m1) * crowding-pass2

      set vlift asc_lift_m1 + random-float err_asclift_m1 - random-float err_asclift_m1 + (b_liftfare_m1 + random-float err_liftfare_m1 - random-float err_liftfare_m1) * lift-ticket + (b_parkinglift_m1 + random-float err_parkinglift_m1 - random-float err_parkinglift_m1) * parking-time-ciampedie
          + (b_liftschedule1_m1 + random-float err_liftschedule1_m1 - random-float err_liftschedule1_m1) * liftschedule1 + (b_liftschedule2_m1 + random-float err_liftschedule2_m1 - random-float err_liftschedule2_m1) * liftschedule2
          + (b_queuelift1_m1 + random-float err_queuelift1_m1 - random-float err_queuelift1_m1) * queue-lift-ciampedie1 + (b_queuelift2_m1 + random-float err_queuelift2_m1 - random-float err_queuelift2_m1) * queue-lift-ciampedie2
          + (b_crowding1_m1 + random-float err_crowding1_m1 - random-float err_crowding1_m1) * crowding-ciampedie1 + (b_crowding2_m1 + random-float err_crowding2_m1 - random-float err_crowding2_m1) * crowding-ciampedie2

      set vnone asc_none_m1 + random-float err_ascnone_m1 - random-float err_ascnone_m1

      set logsum-car ln(exp(vcar / lambda_m1) + exp(vbus / lambda_m1) + exp(vlift / lambda_m1))

      set logsum-bus ln(exp(vcar / lambda_m1) + exp(vbus / lambda_m1) + exp(vlift / lambda_m1))

      set logsum-lift ln(exp(vcar / lambda_m1) + exp(vbus / lambda_m1) + exp(vlift / lambda_m1))

      set logsum-none ln(exp(vnone))

      set nestprob-car exp(lambda_m1 * logsum-car) / (exp(lambda_m1 * logsum-car) + (exp(logsum-none)))

      set nestprob-bus exp(lambda_m1 * logsum-car) / (exp(lambda_m1 * logsum-car) + (exp(logsum-none)))

      set nestprob-lift exp(lambda_m1 * logsum-car) / (exp(lambda_m1 * logsum-car) + (exp(logsum-none)))

      set nestprob-none exp(logsum-none) / (exp(lambda_m1 * logsum-car) + exp(logsum-none))

      set in-nest-car exp(vcar / lambda_m1) /(exp(vcar / lambda_m1) + exp(vbus / lambda_m1) + exp(vlift / lambda_m1))

      set in-nest-bus exp(vbus / lambda_m1) /(exp(vcar / lambda_m1) + exp(vbus / lambda_m1) + exp(vlift / lambda_m1))

      set in-nest-lift exp(vlift / lambda_m1) /(exp(vcar / lambda_m1) + exp(vbus / lambda_m1) + exp(vlift / lambda_m1))

      set in-nest-none 1

      set pcar nestprob-car * in-nest-car

      set pbus nestprob-bus * in-nest-bus

      set plift nestprob-lift * in-nest-lift

      set pnone nestprob-none * in-nest-none

    ]
  ]

ask visitors with [(segment = 1) and (origin = 2) and (theoretical-transport-mode = 0)] [
    if (life = 3599) or (ticks = time-closure - advance) [

      set vcar (b_toll_m1 + random-float err_toll_m1 - random-float err_toll_m1) * toll-per-vehicle + (b_parkingpass_m1 + random-float err_parkingpass_m1 - random-float err_parkingpass_m1) * parking-time-pass + (b_accesscar1_m1 + random-float err_accesscar1_m1
          - random-float err_accesscar1_m1) * accesscar1 + (b_accesscar2_m1 + random-float err_accesscar2_m1 - random-float err_accesscar2_m1) * accesscar2 + (b_traffic1_m1 + random-float err_traffic1_m1 - random-float err_traffic1_m1) * traffic-east1
          + (b_traffic2_m1 + random-float err_traffic2_m1 - random-float err_traffic2_m1) * traffic-east2 + (b_crowding1_m1 + random-float err_crowding1_m1 - random-float err_crowding1_m1) * crowding-pass1 + (b_crowding2_m1 + random-float err_crowding2_m1
          - random-float err_crowding2_m1) * crowding-pass2

      set vbus asc_bus_m1 + random-float err_ascbus_m1 - random-float err_ascbus_m1 + (b_busfare_m1 + random-float err_busfare_m1 - random-float err_busfare_m1) * bus-ticket + (b_frequency_m1 + random-float err_frequency_m1 - random-float err_frequency_m1) * bus-frequency
          + (b_buschedule1_m1 + random-float err_buschedule1_m1 - random-float err_buschedule1_m1) * buschedule1 + (b_buschedule2_m1 + random-float err_buschedule2_m1 - random-float err_buschedule2_m1) * buschedule2 + (b_queuebus1_m1 + random-float err_queuebus1_m1
          - random-float err_queuebus1_m1) * queue-bus-carezza1 + (b_queuebus2_m1 + random-float err_queuebus2_m1 - random-float err_queuebus2_m1) * queue-bus-carezza2 + (b_crowding1_m1 + random-float err_crowding1_m1 - random-float err_crowding1_m1) * crowding-pass1
          + (b_crowding2_m1 + random-float err_crowding2_m1 - random-float err_crowding2_m1) * crowding-pass2

      set vlift asc_lift_m1 + random-float err_asclift_m1 - random-float err_asclift_m1 + (b_liftfare_m1 + random-float err_liftfare_m1 - random-float err_liftfare_m1) * lift-ticket + (b_parkinglift_m1 + random-float err_parkinglift_m1 - random-float err_parkinglift_m1) * parking-time-paolina
          + (b_liftschedule1_m1 + random-float err_liftschedule1_m1 - random-float err_liftschedule1_m1) * liftschedule1 + (b_liftschedule2_m1 + random-float err_liftschedule2_m1 - random-float err_liftschedule2_m1) * liftschedule2
          + (b_queuelift1_m1 + random-float err_queuelift1_m1 - random-float err_queuelift1_m1) * queue-lift-paolina1 + (b_queuelift2_m1 + random-float err_queuelift2_m1 - random-float err_queuelift2_m1) * queue-lift-paolina2
          + (b_crowding1_m1 + random-float err_crowding1_m1 - random-float err_crowding1_m1) * crowding-paolina1 + (b_crowding2_m1 + random-float err_crowding2_m1 - random-float err_crowding2_m1) * crowding-paolina2

      set vnone asc_none_m1 + random-float err_ascnone_m1 - random-float err_ascnone_m1

      set logsum-car ln(exp(vcar / lambda_m1) + exp(vbus / lambda_m1) + exp(vlift / lambda_m1))

      set logsum-bus ln(exp(vcar / lambda_m1) + exp(vbus / lambda_m1) + exp(vlift / lambda_m1))

      set logsum-lift ln(exp(vcar / lambda_m1) + exp(vbus / lambda_m1) + exp(vlift / lambda_m1))

      set logsum-none ln(exp(vnone))

      set nestprob-car exp(lambda_m1 * logsum-car) / (exp(lambda_m1 * logsum-car) + (exp(logsum-none)))

      set nestprob-bus exp(lambda_m1 * logsum-car) / (exp(lambda_m1 * logsum-car) + (exp(logsum-none)))

      set nestprob-lift exp(lambda_m1 * logsum-car) / (exp(lambda_m1 * logsum-car) + (exp(logsum-none)))

      set nestprob-none exp(logsum-none) / (exp(lambda_m1 * logsum-car) + exp(logsum-none))

      set in-nest-car exp(vcar / lambda_m1) /(exp(vcar / lambda_m1) + exp(vbus / lambda_m1) + exp(vlift / lambda_m1))

      set in-nest-bus exp(vbus / lambda_m1) /(exp(vcar / lambda_m1) + exp(vbus / lambda_m1) + exp(vlift / lambda_m1))

      set in-nest-lift exp(vlift / lambda_m1) /(exp(vcar / lambda_m1) + exp(vbus / lambda_m1) + exp(vlift / lambda_m1))

      set in-nest-none 1

      set pcar nestprob-car * in-nest-car

      set pbus nestprob-bus * in-nest-bus

      set plift nestprob-lift * in-nest-lift

      set pnone nestprob-none * in-nest-none

    ]
  ]

ask visitors with [(segment = 2) and (origin = 1) and (theoretical-transport-mode = 0)] [
    if (life = 3599) or (ticks = time-closure - advance) [

      set vcar (b_toll_m2 + random-float err_toll_m2 - random-float err_toll_m2) * toll-per-vehicle + (b_parkingpass_m2 + random-float err_parkingpass_m2 - random-float err_parkingpass_m2) * parking-time-pass + (b_accesscar1_m2 + random-float err_accesscar1_m2
          - random-float err_accesscar1_m2) * accesscar1 + (b_accesscar2_m2 + random-float err_accesscar2_m2 - random-float err_accesscar2_m2) * accesscar2 + (b_traffic1_m2 + random-float err_traffic1_m2 - random-float err_traffic1_m2) * traffic-west1
          + (b_traffic2_m2 + random-float err_traffic2_m2 - random-float err_traffic2_m2) * traffic-west2 + (b_crowding1_m2 + random-float err_crowding1_m2 - random-float err_crowding1_m2) * crowding-pass1 + (b_crowding2_m2 + random-float err_crowding2_m2
          - random-float err_crowding2_m2) * crowding-pass2

      set vbus asc_bus_m2 + random-float err_ascbus_m2 - random-float err_ascbus_m2 + (b_busfare_m2 + random-float err_busfare_m2 - random-float err_busfare_m2) * bus-ticket + (b_frequency_m2 + random-float err_frequency_m2 - random-float err_frequency_m2) * bus-frequency
          + (b_buschedule1_m2 + random-float err_buschedule1_m2 - random-float err_buschedule1_m2) * buschedule1 + (b_buschedule2_m2 + random-float err_buschedule2_m2 - random-float err_buschedule2_m2) * buschedule2 + (b_queuebus1_m2 + random-float err_queuebus1_m2
          - random-float err_queuebus1_m2) * queue-bus-vigo1 + (b_queuebus2_m2 + random-float err_queuebus2_m2 - random-float err_queuebus2_m2) * queue-bus-vigo2 + (b_crowding1_m2 + random-float err_crowding1_m2 - random-float err_crowding1_m2) * crowding-pass1
          + (b_crowding2_m2 + random-float err_crowding2_m2 - random-float err_crowding2_m2) * crowding-pass2

      set vlift asc_lift_m2 + random-float err_asclift_m2 - random-float err_asclift_m2 + (b_liftfare_m2 + random-float err_liftfare_m2 - random-float err_liftfare_m2) * lift-ticket + (b_parkinglift_m2 + random-float err_parkinglift_m2 - random-float err_parkinglift_m2) * parking-time-ciampedie
          + (b_liftschedule1_m2 + random-float err_liftschedule1_m2 - random-float err_liftschedule1_m2) * liftschedule1 + (b_liftschedule2_m2 + random-float err_liftschedule2_m2 - random-float err_liftschedule2_m2) * liftschedule2
          + (b_queuelift1_m2 + random-float err_queuelift1_m2 - random-float err_queuelift1_m2) * queue-lift-ciampedie1 + (b_queuelift2_m2 + random-float err_queuelift2_m2 - random-float err_queuelift2_m2) * queue-lift-ciampedie2
          + (b_crowding1_m2 + random-float err_crowding1_m2 - random-float err_crowding1_m2) * crowding-ciampedie1 + (b_crowding2_m2 + random-float err_crowding2_m2 - random-float err_crowding2_m2) * crowding-ciampedie2

      set vnone asc_none_m2 + random-float err_ascnone_m2 - random-float err_ascnone_m2

      set logsum-car ln(exp(vcar / lambda_m2) + exp(vbus / lambda_m2) + exp(vlift / lambda_m2))

      set logsum-bus ln(exp(vcar / lambda_m2) + exp(vbus / lambda_m2) + exp(vlift / lambda_m2))

      set logsum-lift ln(exp(vcar / lambda_m2) + exp(vbus / lambda_m2) + exp(vlift / lambda_m2))

      set logsum-none ln(exp(vnone))

      set nestprob-car exp(lambda_m2 * logsum-car) / (exp(lambda_m2 * logsum-car) + (exp(logsum-none)))

      set nestprob-bus exp(lambda_m2 * logsum-car) / (exp(lambda_m2 * logsum-car) + (exp(logsum-none)))

      set nestprob-lift exp(lambda_m2 * logsum-car) / (exp(lambda_m2 * logsum-car) + (exp(logsum-none)))

      set nestprob-none exp(logsum-none) / (exp(lambda_m2 * logsum-car) + exp(logsum-none))

      set in-nest-car exp(vcar / lambda_m2) /(exp(vcar / lambda_m2) + exp(vbus / lambda_m2) + exp(vlift / lambda_m2))

      set in-nest-bus exp(vbus / lambda_m2) /(exp(vcar / lambda_m2) + exp(vbus / lambda_m2) + exp(vlift / lambda_m2))

      set in-nest-lift exp(vlift / lambda_m2) /(exp(vcar / lambda_m2) + exp(vbus / lambda_m2) + exp(vlift / lambda_m2))

      set in-nest-none 1

      set pcar nestprob-car * in-nest-car

      set pbus nestprob-bus * in-nest-bus

      set plift nestprob-lift * in-nest-lift

      set pnone nestprob-none * in-nest-none

    ]
  ]

ask visitors with [(segment = 2) and (origin = 2) and (theoretical-transport-mode = 0)] [
    if (life = 3599) or (ticks = time-closure - advance) [

      set vcar (b_toll_m2 + random-float err_toll_m2 - random-float err_toll_m2) * toll-per-vehicle + (b_parkingpass_m2 + random-float err_parkingpass_m2 - random-float err_parkingpass_m2) * parking-time-pass + (b_accesscar1_m2 + random-float err_accesscar1_m2
          - random-float err_accesscar1_m2) * accesscar1 + (b_accesscar2_m2 + random-float err_accesscar2_m2 - random-float err_accesscar2_m2) * accesscar2 + (b_traffic1_m2 + random-float err_traffic1_m2 - random-float err_traffic1_m2) * traffic-east1
          + (b_traffic2_m2 + random-float err_traffic2_m2 - random-float err_traffic2_m2) * traffic-east2 + (b_crowding1_m2 + random-float err_crowding1_m2 - random-float err_crowding1_m2) * crowding-pass1 + (b_crowding2_m2 + random-float err_crowding2_m2
          - random-float err_crowding2_m2) * crowding-pass2

      set vbus asc_bus_m2 + random-float err_ascbus_m2 - random-float err_ascbus_m2 + (b_busfare_m2 + random-float err_busfare_m2 - random-float err_busfare_m2) * bus-ticket + (b_frequency_m2 + random-float err_frequency_m2 - random-float err_frequency_m2) * bus-frequency
          + (b_buschedule1_m2 + random-float err_buschedule1_m2 - random-float err_buschedule1_m2) * buschedule1 + (b_buschedule2_m2 + random-float err_buschedule2_m2 - random-float err_buschedule2_m2) * buschedule2 + (b_queuebus1_m2 + random-float err_queuebus1_m2
          - random-float err_queuebus1_m2) * queue-bus-carezza1 + (b_queuebus2_m2 + random-float err_queuebus2_m2 - random-float err_queuebus2_m2) * queue-bus-carezza2 + (b_crowding1_m2 + random-float err_crowding1_m2 - random-float err_crowding1_m2) * crowding-pass1
          + (b_crowding2_m2 + random-float err_crowding2_m2 - random-float err_crowding2_m2) * crowding-pass2

      set vlift asc_lift_m2 + random-float err_asclift_m2 - random-float err_asclift_m2 + (b_liftfare_m2 + random-float err_liftfare_m2 - random-float err_liftfare_m2) * lift-ticket + (b_parkinglift_m2 + random-float err_parkinglift_m2 - random-float err_parkinglift_m2) * parking-time-paolina
          + (b_liftschedule1_m2 + random-float err_liftschedule1_m2 - random-float err_liftschedule1_m2) * liftschedule1 + (b_liftschedule2_m2 + random-float err_liftschedule2_m2 - random-float err_liftschedule2_m2) * liftschedule2
          + (b_queuelift1_m2 + random-float err_queuelift1_m2 - random-float err_queuelift1_m2) * queue-lift-paolina1 + (b_queuelift2_m2 + random-float err_queuelift2_m2 - random-float err_queuelift2_m2) * queue-lift-paolina2
          + (b_crowding1_m2 + random-float err_crowding1_m2 - random-float err_crowding1_m2) * crowding-paolina1 + (b_crowding2_m2 + random-float err_crowding2_m2 - random-float err_crowding2_m2) * crowding-paolina2

      set vnone asc_none_m2 + random-float err_ascnone_m2 - random-float err_ascnone_m2

      set logsum-car ln(exp(vcar / lambda_m2) + exp(vbus / lambda_m2) + exp(vlift / lambda_m2))

      set logsum-bus ln(exp(vcar / lambda_m2) + exp(vbus / lambda_m2) + exp(vlift / lambda_m2))

      set logsum-lift ln(exp(vcar / lambda_m2) + exp(vbus / lambda_m2) + exp(vlift / lambda_m2))

      set logsum-none ln(exp(vnone))

      set nestprob-car exp(lambda_m2 * logsum-car) / (exp(lambda_m2 * logsum-car) + (exp(logsum-none)))

      set nestprob-bus exp(lambda_m2 * logsum-car) / (exp(lambda_m2 * logsum-car) + (exp(logsum-none)))

      set nestprob-lift exp(lambda_m2 * logsum-car) / (exp(lambda_m2 * logsum-car) + (exp(logsum-none)))

      set nestprob-none exp(logsum-none) / (exp(lambda_m2 * logsum-car) + exp(logsum-none))

      set in-nest-car exp(vcar / lambda_m2) /(exp(vcar / lambda_m2) + exp(vbus / lambda_m2) + exp(vlift / lambda_m2))

      set in-nest-bus exp(vbus / lambda_m2) /(exp(vcar / lambda_m2) + exp(vbus / lambda_m2) + exp(vlift / lambda_m2))

      set in-nest-lift exp(vlift / lambda_m2) /(exp(vcar / lambda_m2) + exp(vbus / lambda_m2) + exp(vlift / lambda_m2))

      set in-nest-none 1

      set pcar nestprob-car * in-nest-car

      set pbus nestprob-bus * in-nest-bus

      set plift nestprob-lift * in-nest-lift

      set pnone nestprob-none * in-nest-none

    ]
  ]

ask visitors with [(pcar != 0) and (pbus != 0) and (plift != 0) and (pnone != 0) and (transport-mode = 0)] [
      let random-number random-float 1
      ifelse random-number < pcar
      [set theoretical-transport-mode 1]
      [ifelse random-number < pcar + pbus
        [set theoretical-transport-mode 2]
        [ifelse random-number < pcar + pbus + plift
          [set theoretical-transport-mode 3]
          [set theoretical-transport-mode 4]
        ]
      ]
    ]

 ask visitors with [(origin = 1) and (theoretical-transport-mode != 0) and (transport-mode = 0)] [
    ifelse (car-access = "free") or ((car-access = "before 10am and after 4pm") and (ticks < time-closure)) or ((car-access = "before 8am and after 6pm") and (ticks < time-closure))

    [ifelse theoretical-transport-mode = 3
      [ifelse random 100 > 94
      [set transport-mode 5]
      [ifelse (pcar > pbus) and (random 100 > 69)
        [set transport-mode 6]
        [ifelse (pbus > pcar) and (random 100 > 97)
          [set transport-mode 7]
          [set transport-mode 3]
        ]
      ]
      ]
      [set transport-mode theoretical-transport-mode]
    ]

    [ifelse theoretical-transport-mode = 3
      [ifelse random 100 > 90
      [set transport-mode 5]
        [ifelse (pbus > pcar) and (random 100 > 97)
          [set transport-mode 7]
          [set transport-mode 3]
        ]
      ]
      [ifelse theoretical-transport-mode = 1
        [ifelse pcar > pbus + plift
          [set transport-mode 4]
          [ifelse pbus > plift
            [set transport-mode 2]
            [set transport-mode 3]
          ]
        ]
      [set transport-mode theoretical-transport-mode]
    ]
  ]
  ]

  ask visitors with [(origin = 2) and (theoretical-transport-mode != 0) and (transport-mode = 0)] [
    ifelse (car-access = "free") or ((car-access = "before 10am and after 4pm") and (ticks < time-closure)) or ((car-access = "before 8am and after 6pm") and (ticks < time-closure))

    [ifelse theoretical-transport-mode = 3
      [ifelse random 100 > 94
      [set transport-mode 5]
      [ifelse (pcar > pbus) and (random 100 > 96)
        [set transport-mode 6]
        [ifelse (pbus > pcar) and (random 100 > 96)
          [set transport-mode 7]
          [set transport-mode 3]
        ]
      ]
      ]
      [set transport-mode theoretical-transport-mode]
    ]

    [ifelse theoretical-transport-mode = 3
      [ifelse random 100 > 90
      [set transport-mode 5]
        [ifelse (pbus > pcar) and (random 100 > 96)
          [set transport-mode 7]
          [set transport-mode 3]
        ]
      ]
      [ifelse theoretical-transport-mode = 1
        [ifelse pcar > pbus + plift
          [set transport-mode 4]
          [ifelse pbus > plift
            [set transport-mode 2]
            [set transport-mode 3]
          ]
        ]
      [set transport-mode theoretical-transport-mode]
    ]
  ]
  ]


  ;visitors taking the bus go to the bus stop
  ask visitors with [(transport-mode = 2) and (on-the-way-to = 1) and (origin = 1) and (pxcor = 244) and (pycor = -211) and (life > 3600)] [
      move-to patch 236 -215
    ]
  ask visitors with [(transport-mode = 2) and (on-the-way-to = 1) and (origin = 1)] [
    if (pxcor = 236) and (pycor = -215) [
      set waiting waiting + 1
    ]
  ]

  ask visitors with [(transport-mode = 2) and (on-the-way-to = 1) and (origin = 2) and (pxcor = 25) and (pycor = -270) and (life > 3600)] [
      move-to patch 29 -270
    ]
  ask visitors with [(transport-mode = 2) and (on-the-way-to = 1) and (origin = 2)] [
    if (pxcor = 29) and (pycor = -270) [
      set waiting waiting + 1
    ]
  ]

  ask visitors with [(transport-mode = 7) and (on-the-way-to = 1) and (origin = 1) and (pxcor = 244) and (pycor = -211) and (life > 3600)] [
      move-to patch 236 -215
    ]
  ask visitors with [(transport-mode = 7) and (on-the-way-to = 1) and (origin = 1)] [
    if (pxcor = 236) and (pycor = -215) [
      set waiting waiting + 1
    ]
  ]

  ask visitors with [(transport-mode = 7) and (on-the-way-to = 1) and (origin = 2) and (pxcor = 25) and (pycor = -270) and (life > 3600)] [
      move-to patch 29 -270
    ]
  ask visitors with [(transport-mode = 7) and (on-the-way-to = 1) and (origin = 2)] [
    if (pxcor = 29) and (pycor = -270) [
      set waiting waiting + 1
    ]
  ]

  ask visitors with [(transport-mode = 4) and (origin = 1)] [
    move-to patch 238 -248
  ]

  ask visitors with [(transport-mode = 4) and (origin = 2)] [
    move-to patch 30 -284
  ]


end

;visitors who chose car as their transport mode get on their car. A distinction is made between free access and restricted access: in the latter case, visitors get on the car after a given time if they had been generated well in advance of road closing time
;or prior to time closure if they had been generated only few minutes before closing of the road
to get-on-the-car
;  ifelse car-access = "free"
;  [ask visitors with [(transport-mode = 1) and (life = 3600)] [
;      set on-the-car 1
;    ]
;  ask visitors with [(transport-mode = 3) and (life = 3600)] [
;      set on-the-car 1
;    ]
;  ]
;  [ask visitors with [(transport-mode = 1) and (pxcor = 238) and (pycor = -248)] [
;      if (life = 3600) or (ticks = time-closure - 1) [
;        set on-the-car 1
;      ]
;  ]
;  ask visitors with [(transport-mode = 1) and (pxcor = 30) and (pycor = -284)] [
;      if (life = 3600) or (ticks = time-closure - 1) [
;        set on-the-car 1
;      ]
;  ]
;  ask visitors with [(transport-mode = 3) and (life = 3600)] [
;    set on-the-car 1
;  ]
;  ]

  ask visitors with [(on-the-way-to = 1) and (origin = 1) and (pxcor = 244) and (pycor = -211) and ((transport-mode = 1) or (transport-mode = 6))] [
    set on-the-car 1
  ]

  ask visitors with [(on-the-way-to = 1) and (origin = 2) and (pxcor = 25) and (pycor = -270) and ((transport-mode = 1) or (transport-mode = 6))] [
    set on-the-car 1
  ]

  ask visitors with [(on-the-way-to = 1) and (origin = 1) and (pxcor = 244) and (pycor = -211) and (life > 3600) and ((transport-mode = 3) or (transport-mode = 5))] [
    set on-the-car 1
  ]

  ask visitors with [(on-the-way-to = 1) and (origin = 2) and (pxcor = 25) and (pycor = -270) and (life > 3600) and ((transport-mode = 3) or (transport-mode = 5))] [
    set on-the-car 1
  ]

  ask visitors with [(on-the-car = 0) and (transport-mode = 1) and (on-the-way-to = 0)] [
    if (pxcor = 88) and (pycor = -277) [
      set on-the-car 1
      set color white
      ask patch 88 -277 [
        set parking parking - 1
      ]
    ]
  ]
  ask visitors with [(on-the-car = 0) and ((transport-mode = 3) or (transport-mode = 6)) and (on-the-way-to = 0)] [
    if (pxcor = 234) and (pycor = -213) [
      set on-the-car 1
      set color white
      ask patch 235 -212 [
        set parking parking - 1
      ]
    ]
  ]
  ask visitors with [(on-the-car = 0) and ((transport-mode = 3) or (transport-mode = 6)) and (on-the-way-to = 0)] [
    if (pxcor = 31) and (pycor = -266) [
      set on-the-car 1
      set color white
      ask patch 33 -268 [
        set parking parking - 1
      ]
    ]
  ]
end

to drive
  ask visitors with [(transport-mode = 1) and (on-the-way-to = 1) and (on-the-car = 1)] [
    ifelse (pxcor = 88) and (pycor = -277)
      []
      [face min-one-of neighbors [roadist_parking]
         fd 0.5 + random-float 0.2]
  ]

  ask visitors with [(transport-mode = 1) and (on-the-way-to = 0) and (on-the-car = 1) and (origin = 1) and (arrived = 0)] [
    ifelse (pxcor = 253) and (pycor = -220)
      [move-to patch 238 -248]
      [face min-one-of neighbors [dist_fassa]
      fd 0.5 + random-float 0.2]
  ]

  ask visitors with [(transport-mode = 1) and (on-the-way-to = 0) and (on-the-car = 1) and (origin = 2) and (arrived = 0)] [
    ifelse (pxcor = 15) and (pycor = -275)
      [move-to patch 30 -284]
      [face min-one-of neighbors [dist_ega]
      fd 0.5 + random-float 0.2]
  ]

  ask visitors with [(transport-mode = 3) and (on-the-way-to = 1) and (on-the-car = 1) and (origin = 1)] [
    ifelse (pxcor = 235) and (pycor = -212)
      []
      [face min-one-of neighbors [distance patch 235 -212]
         fd 0.5 + random-float 0.2]
  ]

  ask visitors with [(transport-mode = 3) and (on-the-way-to = 0) and (on-the-car = 1) and (origin = 1)] [
    move-to patch 238 -248
  ]

  ask visitors with [(transport-mode = 3) and (on-the-way-to = 1) and (on-the-car = 1) and (origin = 2)] [
    ifelse (pxcor = 33) and (pycor = -268)
    []
    [face min-one-of neighbors [distance patch 33 -268]
       fd 0.5 + random-float 0.2]
    ]


  ask visitors with [(transport-mode = 3) and (on-the-way-to = 0) and (on-the-car = 1) and (origin = 2)] [
    move-to patch 30 -284
    ]

  ask visitors with [(transport-mode = 5) and (on-the-way-to = 1) and (on-the-car = 1) and (origin = 1)] [
    ifelse (pxcor = 235) and (pycor = -212)
    []
    [face min-one-of neighbors [distance patch 235 -212]
      fd 0.5 + random-float 0.2]
  ]

  ask visitors with [(transport-mode = 5) and (on-the-way-to = 0) and (on-the-car = 1) and (origin = 1)] [
    move-to patch 238 -248
  ]

  ask visitors with [(transport-mode = 5) and (on-the-way-to = 1) and (on-the-car = 1) and (origin = 2)] [
    ifelse (pxcor = 33) and (pycor = -268)
    []
    [face min-one-of neighbors [distance patch 33 -268]
      fd 0.5 + random-float 0.2]
  ]

   ask visitors with [(transport-mode = 5) and (on-the-way-to = 0) and (on-the-car = 1) and (origin = 2)] [
    move-to patch 30 -284
   ]

  ;visitors using car + lift and starting from Vigo drive to the Paolina chairlift's parking lot
   ask visitors with [(transport-mode = 6) and (on-the-way-to = 1) and (on-the-car = 1) and (origin = 1)] [
    ifelse (pxcor = 33) and (pycor = -268)
    []
    [ifelse (pxcor = 41) and (pycor = -269)
      [move-to patch 33 -268]
      [face min-one-of neighbors [dist_ega]
      fd 0.5 + random-float 0.2]
      ]
    ]

    ;visitors using car + lift and starting from Carezza drive to the Ciampedie lift's parking lot
    ask visitors with [(transport-mode = 6) and (on-the-way-to = 1) and (on-the-car = 1) and (origin = 2)] [
    ifelse (pxcor = 235) and (pycor = -212)
    []
    [ifelse (pxcor = 239) and (pycor = -215)
      [move-to patch 235 -212]
      [face min-one-of neighbors [dist_fassa]
      fd 0.5 + random-float 0.2]
      ]
    ]

    ;visitors using car + lift and starting from Vigo go back to Vigo
    ask visitors with [(transport-mode = 6) and (on-the-way-to = 0) and (on-the-car = 1) and (origin = 1) and (pxcor < 41) and (arrived = 0)] [
      move-to patch 41 -269
      ]

    ask visitors with [(transport-mode = 6) and (on-the-way-to = 0) and (on-the-car = 1) and (origin = 1) and (pxcor >= 41) and (arrived = 0)] [
      ifelse (pxcor = 253) and (pycor = -220)
      [move-to patch 238 -248]
      [face min-one-of neighbors [dist_fassa]
          fd 0.5 + random-float 0.2]
    ]

    ;visitors using car + lift and starting from Carezza go back to Carezza
    ask visitors with [(transport-mode = 6) and (on-the-way-to = 0) and (on-the-car = 1) and (origin = 2) and (pycor > -215) and (arrived = 0)] [
      move-to patch 239 -215
    ]

    ask visitors with [(transport-mode = 6) and (on-the-way-to = 0) and (on-the-car = 1) and (origin = 2) and (pycor <= -215) and (arrived = 0)] [
      ifelse (pxcor = 15) and (pycor = -275)
      [move-to patch 30 -284]
      [face min-one-of neighbors [dist_ega]
          fd 0.5 + random-float 0.2]
    ]

  ask visitors [
    ifelse on-the-car = 1
    [set color white]
    [set color orange]
  ]


  ask visitors [
    if ((pxcor = 238) and (pycor = -248)) or ((pxcor = 30) and (pycor = -284)) [
      set arrived 1
    ]
  ]

end

to park-the-car

 ; visitors using the car park the car at the Pass
 ask visitors with [(on-the-car = 1) and (transport-mode = 1) and (on-the-way-to = 1) and (pxcor = 88) and (pycor = -277)] [
      set parking-time parking-time + 1
    ]

 ask visitors with [(on-the-car = 1) and (transport-mode = 1) and (on-the-way-to = 1) and (pxcor = 88) and (pycor = -277)] [
      if parking-time > ([parking] of patch 88 -277) * 10 [
      set on-the-car 0
      ask patch 88 -277 [
        set parking parking + 1
      ]
    ]
  ]

  ;visitors taking the lift park the car at the lift station Ciampedie and start waiting for the next available ride
  ask visitors with [(on-the-car = 1) and (transport-mode = 3)] [
    if (on-the-way-to = 1) and (pxcor = 235) and (pycor = -212) [
      set parking-time parking-time + 1
    ]
  ]
  ask visitors with [(on-the-car = 1) and (transport-mode = 3) and (on-the-way-to = 1) and (pxcor = 235) and (pycor = -212)] [
    if parking-time > ([parking] of patch 235 -212) * 5 [
      set on-the-car 0
      ask patch 235 -212 [
        set parking parking + 1
      ]
    ]
  ]
  ask visitors with [(on-the-car = 0) and (transport-mode = 3)] [
    if (on-the-way-to = 1) and (pxcor = 235) and (pycor = -212) [
      set waiting waiting + 1
    ]
  ]


  ;visitors taking the lift park the car at the lift station Paolina and start waiting for the next available ride
  ask visitors with [(on-the-car = 1) and (transport-mode = 3)] [
    if (on-the-way-to = 1) and (pxcor = 33) and (pycor = -268) [
      set parking-time parking-time + 1
    ]
  ]
  ask visitors with [(on-the-car = 1) and (transport-mode = 3) and (on-the-way-to = 1) and (pxcor = 33) and (pycor = -268)] [
    if parking-time > ([parking] of patch 33 -268) * 5 [
      set on-the-car 0
      ask patch 33 -268 [
        set parking parking + 1
      ]
    ]
  ]
  ask visitors with [(on-the-car = 0) and (transport-mode = 3)] [
    if (on-the-way-to = 1) and (pxcor = 33) and (pycor = -268) [
      set waiting waiting + 1
    ]
  ]


  ;visitors doing the traverse park the car at the lift station Ciampedie and start waiting for the next available ride
  ask visitors with [(on-the-car = 1) and (transport-mode = 5)] [
    if (on-the-way-to = 1) and (pxcor = 235) and (pycor = -212) [
      set parking-time parking-time + 1
    ]
  ]
  ask visitors with [(on-the-car = 1) and (transport-mode = 5) and (on-the-way-to = 1) and (pxcor = 235) and (pycor = -212)] [
    if parking-time > [parking] of patch 233 -211 [
      set on-the-car 0
      ask patch 235 -212 [
        set parking parking + 1
      ]
    ]
  ]
  ask visitors with [(on-the-car = 0) and (transport-mode = 5)] [
    if (on-the-way-to = 1) and (pxcor = 235) and (pycor = -212) [
      set waiting waiting + 1
    ]
  ]


  ;visitors doing the traverse park the car at the lift station Paolina and start waiting for the next available ride
  ask visitors with [(on-the-car = 1) and (transport-mode = 5)] [
    if (on-the-way-to = 1) and (pxcor = 33) and (pycor = -268) [
      set parking-time parking-time + 1
    ]
  ]
  ask visitors with [(on-the-car = 1) and (transport-mode = 5) and (on-the-way-to = 1) and (pxcor = 33) and (pycor = -268)] [
    if parking-time > [parking] of patch 33 -268 [
      set on-the-car 0
      ask patch 33 -268 [
        set parking parking + 1
      ]
    ]
  ]
  ask visitors with [(on-the-car = 0) and (transport-mode = 5)] [
    if (on-the-way-to = 1) and (pxcor = 33) and (pycor = -268) [
      set waiting waiting + 1
    ]
  ]

  ;visitors using car + lift park the car at the lift station Ciampedie and start waiting for the next available ride
  ask visitors with [(on-the-car = 1) and (transport-mode = 6)] [
    if (on-the-way-to = 1) and (pxcor = 235) and (pycor = -212) [
      set parking-time parking-time + 1
    ]
  ]
  ask visitors with [(on-the-car = 1) and (transport-mode = 6) and (on-the-way-to = 1) and (pxcor = 235) and (pycor = -212)] [
    if parking-time > [parking] of patch 233 -211 [
      set on-the-car 0
      ask patch 235 -212 [
        set parking parking + 1
      ]
    ]
  ]
  ask visitors with [(on-the-car = 0) and (transport-mode = 6)] [
    if (on-the-way-to = 1) and (pxcor = 235) and (pycor = -212) [
      set waiting waiting + 1
    ]
  ]


  ;visitors using car + lift park the car at the lift station Paolina and start waiting for the next available ride
  ask visitors with [(on-the-car = 1) and (transport-mode = 6)] [
    if (on-the-way-to = 1) and (pxcor = 33) and (pycor = -268) [
      set parking-time parking-time + 1
    ]
  ]
  ask visitors with [(on-the-car = 1) and (transport-mode = 6) and (on-the-way-to = 1) and (pxcor = 33) and (pycor = -268)] [
    if parking-time > [parking] of patch 33 -268 [
      set on-the-car 0
      ask patch 33 -268 [
        set parking parking + 1
      ]
    ]
  ]
  ask visitors with [(on-the-car = 0) and (transport-mode = 6)] [
    if (on-the-way-to = 1) and (pxcor = 33) and (pycor = -268) [
      set waiting waiting + 1
    ]
  ]

end



to get-on-bus
  ;visitors based in Vigo take westbound busses
  ask visitors with [(pxcor = 236) and (pycor = -215) and (origin = 1) and (on-the-bus = 0) and ((transport-mode = 2) or (transport-mode = 7)) and (on-the-way-to = 1)] [
    if any? westbound-busses with [(pxcor = 236) and (pycor = -216)] [
      if (sum [group-size] of visitors with [(pxcor = 236) and (pycor = -215) and (waiting > [waiting] of myself)] + [occupancy] of one-of westbound-busses with [(pxcor = 236) and (pycor = -216)] < 60) [
      set on-the-bus 1
      set our-bus [who] of one-of westbound-busses with [(pxcor = 236) and (pycor = -216)]
      ask westbound-bus our-bus [
        set occupancy occupancy + [group-size] of myself
        ]
      ]
    ]
  ]

  ;visitors based in Vigo take eastbound busses to go back to Vigo
  ask visitors with [(pxcor = 80) and (pycor = -279) and (origin = 1) and (on-the-bus = 0) and (transport-mode = 2) and (on-the-way-to = 0)] [
    if any? eastbound-busses with [(pxcor = 80) and (pycor = -280)] [
      if (sum [group-size] of visitors with [(pxcor = 80) and (pycor = -279) and (waiting > [waiting] of myself)] + [occupancy] of one-of eastbound-busses with [(pxcor = 80) and (pycor = -280)] < 60) [
      set on-the-bus 1
      set our-bus [who] of one-of eastbound-busses with [(pxcor = 80) and (pycor = -280)]
      ask eastbound-bus our-bus [
        set occupancy occupancy + [group-size] of myself
        ]
      ]
    ]
  ]

  ;visitors based in Carezza take eastbound busses
  ask visitors with [(pxcor = 29) and (pycor = -270) and (origin = 2) and (on-the-bus = 0) and ((transport-mode = 2) or (transport-mode = 7)) and (on-the-way-to = 1)] [
    if any? eastbound-busses with [(pxcor = 29) and (pycor = -271)] [
      if (sum [group-size] of visitors with [(pxcor = 29) and (pycor = -270) and (waiting > [waiting] of myself)] + [occupancy] of one-of eastbound-busses with [(pxcor = 29) and (pycor = -271)] < 60) [
      set on-the-bus 1
      set our-bus [who] of one-of eastbound-busses with [(pxcor = 29) and (pycor = -271)]
      ask eastbound-bus our-bus [
        set occupancy occupancy + [group-size] of myself
        ]
      ]
    ]
  ]

  ;visitors based in Carezza take westbound busses to go back to Carezza
  ask visitors with [(pxcor = 82) and (pycor = -279) and (origin = 2) and (on-the-bus = 0) and (transport-mode = 2) and (on-the-way-to = 0)] [
    if any? westbound-busses with [(pxcor = 82) and (pycor = -280)] [
      if (sum [group-size] of visitors with [(pxcor = 82) and (pycor = -279) and (waiting > [waiting] of myself)] + [occupancy] of one-of westbound-busses with [(pxcor = 82) and (pycor = -280)] < 60) [
      set on-the-bus 1
      set our-bus [who] of one-of westbound-busses with [(pxcor = 82) and (pycor = -280)]
      ask westbound-bus our-bus [
        set occupancy occupancy + [group-size] of myself
        ]
      ]
    ]
  ]

 ;visitors using bus + lift and based in Vigo take the bus to go back to Vigo
  ask visitors with [(pxcor = 29) and (pycor = -270) and (origin = 1) and (on-the-bus = 0) and (transport-mode = 7) and (on-the-way-to = 0)] [
    if any? eastbound-busses with [(pxcor = 29) and (pycor = -271)] [
      if (sum [group-size] of visitors with [(pxcor = 29) and (pycor = -270) and (waiting > [waiting] of myself)] + [occupancy] of one-of eastbound-busses with [(pxcor = 29) and (pycor = -271)] < 60) [
      set on-the-bus 1
      set our-bus [who] of one-of eastbound-busses with [(pxcor = 29) and (pycor = -271)]
      ask eastbound-bus our-bus [
        set occupancy occupancy + [group-size] of myself
        ]
      ]
    ]
  ]

 ;visitors using bus + lift and based in Carezza take the bus and go back to Carezza
  ask visitors with [(pxcor = 236) and (pycor = -215) and (origin = 2) and (on-the-bus = 0) and (transport-mode = 7) and (on-the-way-to = 0)] [
    if any? westbound-busses with [(pxcor = 236) and (pycor = -216)] [
      if (sum [group-size] of visitors with [(pxcor = 236) and (pycor = -215) and (waiting > [waiting] of myself)] + [occupancy] of one-of westbound-busses with [(pxcor = 236) and (pycor = -216)] < 60) [
      set on-the-bus 1
      set our-bus [who] of one-of westbound-busses with [(pxcor = 236) and (pycor = -216)]
      ask westbound-bus our-bus [
        set occupancy occupancy + [group-size] of myself
        ]
      ]
    ]
  ]

  ;visitors doing the crossing excursion go back to Vigo
  ask visitors with [(pxcor = 29) and (pycor = -270) and (origin = 1) and (on-the-bus = 0) and (transport-mode = 5) and (on-the-way-to = 0)] [
    if any? eastbound-busses with [(pxcor = 29) and (pycor = -271)] [
      if (sum [group-size] of visitors with [(pxcor = 29) and (pycor = -270) and (waiting > [waiting] of myself)] + [occupancy] of one-of eastbound-busses with [(pxcor = 29) and (pycor = -271)] < 60) [
      set on-the-bus 1
      set our-bus [who] of one-of eastbound-busses with [(pxcor = 29) and (pycor = -271)]
      ask eastbound-bus our-bus [
        set occupancy occupancy + [group-size] of myself
        ]
      ]
    ]
  ]

  ;visitors doing the crossing excursion go back to Carezza
  ask visitors with [(pxcor = 236) and (pycor = -215) and (origin = 2) and (on-the-bus = 0) and (transport-mode = 5) and (on-the-way-to = 0)] [
    if any? westbound-busses with [(pxcor = 236) and (pycor = -216)] [
      if (sum [group-size] of visitors with [(pxcor = 236) and (pycor = -215) and (waiting > [waiting] of myself)] + [occupancy] of one-of westbound-busses with [(pxcor = 236) and (pycor = -216)] < 60) [
      set on-the-bus 1
      set our-bus [who] of one-of westbound-busses with [(pxcor = 236) and (pycor = -216)]
      ask westbound-bus our-bus [
        set occupancy occupancy + [group-size] of myself
        ]
      ]
    ]
  ]

  ask visitors with [(on-the-bus = 1) and (origin = 1) and (on-the-way-to = 1) and ((transport-mode = 2) or (transport-mode = 7))] [
    move-to westbound-bus our-bus
  ]
  ask visitors with [(on-the-bus = 1) and (origin = 1) and (on-the-way-to = 0) and ((transport-mode = 2) or (transport-mode = 7))] [
    move-to eastbound-bus our-bus
  ]
  ask visitors with [(on-the-bus = 1) and (origin = 2) and (on-the-way-to = 1) and ((transport-mode = 2) or (transport-mode = 7))] [
    move-to eastbound-bus our-bus
  ]
  ask visitors with [(on-the-bus = 1) and (origin = 2) and (on-the-way-to = 0) and ((transport-mode = 2) or (transport-mode = 7))] [
    move-to westbound-bus our-bus
  ]
  ask visitors with [(on-the-bus = 1) and (origin = 1) and (on-the-way-to = 0) and (transport-mode = 5)] [
    move-to eastbound-bus our-bus
  ]
  ask visitors with [(on-the-bus = 1) and (origin = 2) and (on-the-way-to = 0) and (transport-mode = 5)] [
    move-to westbound-bus our-bus
  ]

  ;once a visitor is on the bus the waiting counter is reset
  ask visitors [
    if on-the-bus = 1 [
      set waiting 0
    ]
  ]


end

to get-off-bus
  ask visitors with [(on-the-bus = 1) and (origin = 1) and (on-the-way-to = 1) and (transport-mode = 2)] [
    if [bus-stop] of westbound-bus our-bus = 2 [
      set on-the-bus 0
      ask westbound-bus our-bus [
        set occupancy occupancy - [group-size] of myself
      ]
      set our-bus -10
      move-to patch 76 -277
    ]
  ]

  ask visitors with [(on-the-bus = 1) and (origin = 1) and (on-the-way-to = 0) and (transport-mode = 2)] [
    if [bus-stop] of eastbound-bus our-bus = 1 [
      set on-the-bus 0
      ask eastbound-bus our-bus [
        set occupancy occupancy - [group-size] of myself
      ]
      set our-bus -10
      move-to patch 238 -248
      set arrived 1
    ]
  ]

  ask visitors with [(on-the-bus = 1) and (origin = 2) and (on-the-way-to = 1) and (transport-mode = 2)] [
    if [bus-stop] of eastbound-bus our-bus = 2 [
      set on-the-bus 0
      ask eastbound-bus our-bus [
        set occupancy occupancy - [group-size] of myself
      ]
      set our-bus -10
      move-to patch 76 -277
    ]
  ]

ask visitors with [(on-the-bus = 1) and (origin = 2) and (on-the-way-to = 0) and (transport-mode = 2)] [
    if [bus-stop] of westbound-bus our-bus = 3 [
      set on-the-bus 0
      ask westbound-bus our-bus [
        set occupancy occupancy - [group-size] of myself
      ]
      set our-bus -10
      move-to patch 30 -284
      set arrived 1
    ]
  ]

  ask visitors with [(on-the-bus = 1) and (origin = 1) and (on-the-way-to = 1) and (transport-mode = 7)] [
    if [bus-stop] of westbound-bus our-bus = 3 [
      set on-the-bus 0
      ask westbound-bus our-bus [
        set occupancy occupancy - [group-size] of myself
      ]
      set our-bus -10
      move-to patch 33 -268
    ]
  ]

  ask visitors with [(on-the-bus = 1) and (origin = 1) and (on-the-way-to = 0) and (transport-mode = 7)] [
    if [bus-stop] of eastbound-bus our-bus = 1 [
      set on-the-bus 0
      ask eastbound-bus our-bus [
        set occupancy occupancy - [group-size] of myself
      ]
      set our-bus -10
      move-to patch 238 -248
    ]
  ]

  ask visitors with [(on-the-bus = 1) and (origin = 2) and (on-the-way-to = 1) and (transport-mode = 7)] [
    if [bus-stop] of eastbound-bus our-bus = 1 [
      set on-the-bus 0
      ask eastbound-bus our-bus [
        set occupancy occupancy - [group-size] of myself
      ]
      set our-bus -10
      move-to patch 235 -212
    ]
  ]

ask visitors with [(on-the-bus = 1) and (origin = 2) and (on-the-way-to = 0) and (transport-mode = 7)] [
    if [bus-stop] of westbound-bus our-bus = 3 [
      set on-the-bus 0
      ask westbound-bus our-bus [
        set occupancy occupancy - [group-size] of myself
      ]
      set our-bus -10
      move-to patch 30 -284
    ]
  ]

  ask visitors with [(on-the-bus = 1) and (origin = 1) and (on-the-way-to = 0) and (transport-mode = 5)] [
    if [bus-stop] of eastbound-bus our-bus = 1 [
      set on-the-bus 0
      ask eastbound-bus our-bus [
        set occupancy occupancy - [group-size] of myself
      ]
      set our-bus -10
      move-to patch 238 -248
    ]
  ]

ask visitors with [(on-the-bus = 1) and (origin = 2) and (on-the-way-to = 0) and (transport-mode = 5)] [
    if [bus-stop] of westbound-bus our-bus = 3 [
      set on-the-bus 0
      ask westbound-bus our-bus [
        set occupancy occupancy - [group-size] of myself
      ]
      set our-bus -10
      move-to patch 30 -284
    ]
  ]

;visitors using bus + lift start waiting for the first available lift ride
ask visitors with [(on-the-bus = 0) and (transport-mode = 7) and (on-the-way-to = 1)] [
  if (pxcor = 235) and (pycor = -212) [
    set waiting waiting + 1
  ]
]

;visitors using bus + lift start waiting for the first available chairlift ride
ask visitors with [(on-the-bus = 0) and (transport-mode = 7) and (on-the-way-to = 1)] [
  if (pxcor = 33) and (pycor = -268) [
    set waiting waiting + 1
  ]
]


end

to get-on-cablecar
  ask visitors with [(pxcor = 235) and (pycor = -212) and (on-the-car = 0) and (on-the-cablecar = 0) and (on-the-way-to = 1) and (our-cablecar != -10)] [
    if any? cablecars with [(pxcor = 234) and (pycor = -212)] [
      if (sum [group-size] of visitors with [(pxcor = 235) and (pycor = -212) and (waiting > [waiting] of myself)] + [occupancy] of one-of cablecars with [(pxcor = 234) and (pycor = -212)] < 60) [
        set on-the-cablecar 1
        set our-cablecar [who] of one-of cablecars-on patch 234 -212
        ask cablecar our-cablecar [
          set occupancy occupancy + [group-size] of myself
          ]
        ]
      ]
    ]
  ask visitors with [(pxcor = 216) and (pycor = -167) and (on-the-car = 0) and (on-the-cablecar = 0) and (on-the-way-to = 0)] [
    if any? cablecars with [(pxcor = 217) and (pycor = -167)] [
      if (sum [group-size] of visitors with [(pxcor = 216) and (pycor = -167) and (waiting > [waiting] of myself)] + [occupancy] of one-of cablecars with [(pxcor = 217) and (pycor = -167)] < 60) [
        set on-the-cablecar 1
        set our-cablecar [who] of one-of cablecars-on patch 217 -167
        ask cablecar our-cablecar [
          set occupancy occupancy + [group-size] of myself
          ]
        ]
      ]
    ]

  ask visitors with [on-the-cablecar = 1] [
    move-to cablecar our-cablecar
  ]
end

to get-off-cablecar
  ask visitors with [(on-the-cablecar = 1) and (on-the-way-to = 1)] [
    if (pxcor = 217) and (pycor = -167) [
      set on-the-cablecar 0
      ask cablecar our-cablecar [
        set occupancy occupancy - [group-size] of myself
      ]
      set our-cablecar -10
      move-to patch 214 -166
    ]
  ]
  ask visitors with [(on-the-cablecar = 1) and (on-the-way-to = 0)] [
    if (pxcor = 234) and (pycor = -212) [
      set on-the-cablecar 0
      ask cablecar our-cablecar [
        set occupancy occupancy - [group-size] of myself
      ]
      set our-cablecar -10
      move-to patch 234 -213
    ]
  ]


  ;visitors doing the crossing excursion move to the bus stop
  ask visitors with [(excursion = 42) and (on-the-way-to = 0) and (on-the-cablecar = 0) and (pxcor = 234) and (pycor = -213)] [
    move-to patch 236 -215
  ]

  ;visitors doing the crossing excursion start waiting the bus on their way back to Carezza
  ask visitors with [(excursion = 42) and (on-the-way-to = 0) and (pxcor = 236) and (pycor = -215)] [
    set waiting waiting + 1
  ]

  ;visitors using bus + cablecar go to the bus stop
  ask visitors with [(transport-mode = 7) and (on-the-way-to = 0) and (on-the-cablecar = 0) and (pxcor = 234) and (pycor = -213)] [
    move-to patch 236 -215
  ]

  ;visitors using bus + cablecar start waiting the bus on their way back to Carezza
  ask visitors with [(transport-mode = 7) and (on-the-way-to = 0) and (pxcor = 236) and (pycor = -215)] [
    set waiting waiting + 1
  ]

end

;visitors on the side of Carezza take the chairlift
to take-the-chairlift
  if ticks mod 3600 = 0 [set hours 1]
  if hours = 1 [set counter counter + 1]
  if counter = 3600 [
    set hours 0
    set counter 0]

 ;visitors going up
  if any? visitors-on patch 33 -268 [
    ask max-one-of visitors-on patch 33 -268 [waiting] [
     if ((ticks mod 10 = 0) and (ticks >= first-lift-journey) and (ticks <= 26100) and (counter >= 0) and (counter < 3600 - liftstop * 60) and (on-the-car = 0) and (on-the-way-to = 1)) or
     ((ticks mod 10 = 0) and (ticks >= 30600) and (ticks <= last-lift-journey) and (counter >= 0) and (counter < 3600 - liftstop * 60) and (on-the-car = 0) and (on-the-way-to = 1)) [
       set on-the-chairlift 1
       move-to patch 33 -267
      ]
    ]
  ]

  ask visitors with [(on-the-chairlift = 1) and (on-the-way-to = 1)] [
    ifelse (pxcor = 89) and (pycor = -237)
    [set on-the-chairlift 0
      move-to patch 90 -237]
    [face patch 89 -237
     fd 0.2]
  ]

 ;visitors going down
  if any? visitors-on patch 88 -235 [
    ask max-one-of visitors-on patch 88 -235 [waiting] [
     if ((ticks mod 10 = 0) and (ticks >= first-lift-journey) and (ticks <= 26100) and (counter >= 0) and (counter < 3600 - liftstop * 60) and (on-the-car = 0) and (on-the-way-to = 0)) or
     ((ticks mod 10 = 0) and (ticks >= 30600) and (ticks <= last-lift-journey) and (counter >= 0) and (counter < 3600 - liftstop * 60) and (on-the-car = 0) and (on-the-way-to = 0)) [
       set on-the-chairlift 1
       move-to patch 88 -236
      ]
    ]
  ]

  ask visitors with [(on-the-chairlift = 1) and (on-the-way-to = 0)] [
    ifelse (pxcor = 32) and (pycor = -266)
    [set on-the-chairlift 0
      move-to patch 31 -266]
    [face patch 32 -266
     fd 0.2]
  ]

  ;visitors doing the crossing excursion move to the bus stop
  ask visitors with [(excursion = 41) and (on-the-way-to = 0) and (on-the-chairlift = 0) and (pxcor = 31) and (pycor = -266)] [
    move-to patch 29 -270
  ]

  ;visitors doing the crossing excursion start waiting the bus on their way back to Vigo
  ask visitors with [(excursion = 41) and (on-the-way-to = 0) and (pxcor = 29) and (pycor = -270)] [
    set waiting waiting + 1
  ]

  ;visitors using bus + chairlift go to the bus stop
  ask visitors with [(transport-mode = 7) and (on-the-way-to = 0) and (on-the-cablecar = 0) and (pxcor = 31) and (pycor = -266)] [
    move-to patch 29 -270
  ]

  ;visitors using bus + chairlift start waiting the bus on their way back to Vigo
  ask visitors with [(transport-mode = 7) and (on-the-way-to = 0) and (pxcor = 29) and (pycor = -270)] [
    set waiting waiting + 1
  ]

end

to choose-excursion

  ; excursions are assigned to visitors taking the car or the bus and starting the excursion before 10am
  ask visitors with [((transport-mode = 1) or (transport-mode = 2)) and (birth < 14400) and (excursion = 0) and ((on-the-car = 1) or (on-the-bus = 1))] [
    let random-number random 100
    ifelse random-number < 20
      [set excursion 11]
      [ifelse (random-number >= 20) and (random-number < 30)
        [set excursion 12]
        [ifelse (random-number >= 30) and (random-number < 40)
          [set excursion 14]
          [ifelse (random-number >= 40) and (random-number < 60)
            [set excursion 15]
            [ifelse (random-number >= 60) and (random-number < 70)
              [set excursion 16]
              [ifelse (random-number >= 70) and (random-number < 80)
                [set excursion 17]
                [ifelse (random-number >= 80) and (random-number < 90)
                  [set excursion 18]
                  [set excursion 19]
                ]
              ]
            ]
          ]
        ]
      ]
  ]

  ;excursions are assigned to visitors taking the car or bus and starting the excursion between 10am and 11am
  ask visitors with [((transport-mode = 1) or (transport-mode = 2)) and (birth >= 14400) and (birth < 18000) and (excursion = 0) and ((on-the-car = 1) or (on-the-bus = 1))] [
    let random-number random 100
    ifelse random-number < 60
      [set excursion 11]
      [ifelse (random-number >= 60) and (random-number < 80)
        [set excursion 13]
        [ifelse (random-number >= 80) and (random-number < 90)
          [set excursion 14]
          [set excursion 17]
        ]
      ]
  ]

  ;excursions are assigned to visitors taking the car or bus and starting the excursion after 11am
  ask visitors with [((transport-mode = 1) or (transport-mode = 2)) and (birth >= 18000) and (excursion = 0) and ((on-the-car = 1) or (on-the-bus = 1))] [
    let random-number random 100
    ifelse random-number < 50
      [set excursion 11]
      [ifelse (random-number >= 50) and (random-number < 83)
        [set excursion 13]
        [set excursion 14]
      ]
  ]


  ; excursions are assigned to visitors taking the cablecar and starting the excursion before 10am
  ask visitors with [((transport-mode = 3) or (transport-mode = 6) or (transport-mode = 7)) and (birth < 14400) and (excursion = 0) and (on-the-cablecar = 1)] [
    let random-number random 100
    ifelse random-number < 20
      [set excursion 21]
      [ifelse (random-number >= 20) and (random-number < 60)
        [set excursion 23]
        [ifelse (random-number >= 60) and (random-number < 80)
          [set excursion 24]
          [set excursion 26]
        ]
      ]
  ]


  ; excursions are assigned to visitors taking the cablecar and starting the excursion between 10am and 11am
  ask visitors with [((transport-mode = 3) or (transport-mode = 6) or (transport-mode = 7)) and (birth >= 14400) and (birth < 18000) and (excursion = 0) and (on-the-cablecar = 1)] [
    let random-number random 100
    ifelse random-number < 20
      [set excursion 21]
      [ifelse (random-number >= 20) and (random-number < 40)
        [set excursion 22]
        [ifelse (random-number >= 40) and (random-number < 50)
          [set excursion 23]
          [ifelse (random-number >= 50) and (random-number < 70)
            [set excursion 25]
            [set excursion 26]
          ]
        ]
      ]
  ]

  ; excursions are assigned to visitors taking the cablecar and starting the excursion after 11am
  ask visitors with [((transport-mode = 3) or (transport-mode = 6) or (transport-mode = 7)) and (birth >= 18000) and (excursion = 0) and (on-the-cablecar = 1)] [
    let random-number random 100
    ifelse random-number < 33
      [set excursion 21]
      [ifelse (random-number >= 33) and (random-number < 66)
        [set excursion 25]
        [set excursion 26]
      ]
  ]



  ; excursions are assigned to visitors taking the chairlift and starting the excursion before 10am
  ask visitors with [((transport-mode = 3) or (transport-mode = 6) or (transport-mode = 7)) and (birth < 14400) and (excursion = 0) and (on-the-chairlift = 1)] [
    let random-number random 100
    ifelse random-number < 20
      [set excursion 31]
      [ifelse (random-number >= 20) and (random-number < 40)
        [set excursion 32]
        [ifelse (random-number >= 40) and (random-number < 60)
          [set excursion 33]
          [set excursion 34]
          ]
        ]
    ]

  ; excursions are assigned to visitors taking the chairlift and starting the excursion between 10am and 11am
  ask visitors with [((transport-mode = 3) or (transport-mode = 6) or (transport-mode = 7)) and (birth >= 14400) and (birth < 18000) and (excursion = 0) and (on-the-chairlift = 1)] [
    let random-number random 100
    ifelse random-number < 10
      [set excursion 33]
      [ifelse (random-number >= 10) and (random-number < 90)
        [set excursion 34]
        [set excursion 35]
      ]
  ]

  ; excursions are assigned to visitors taking the chairlift and starting the excursion after 11am
  ask visitors with [((transport-mode = 3) or (transport-mode = 6) or (transport-mode = 7)) and (birth >= 18000) and (excursion = 0) and (on-the-chairlift = 1)] [
    set excursion 34
  ]

  ;the crossing excursion is assigned to visitors based in Vigo
  ask visitors with [(origin = 1) and (transport-mode = 5)] [
    set excursion 41
  ]

  ;the crossing excursion is assigned to visitors based in Carezza
  ask visitors with [(origin = 2) and (transport-mode = 5)] [
    set excursion 42
  ]

end

to hike
  ; each visitor is assigned a hiking speed through the Tobler's equation
  ; the actual slope of the trail is computed considering the slope of the terrain and the direction of the visitor (heading) with respect to the aspect of the slope
  ; the basic speed is given by a value of 0.03 patches per second plus a speed factor that can vary between -0.003 and 0.003
  ; hikers doing long excursions walk almost continuously (i.e. walk 90% of time)
  ask visitors with [((excursion = 12) or (excursion = 16) or (excursion = 17) or (excursion = 18) or (excursion = 21) or (excursion = 22) or (excursion = 23) or (excursion = 24)
    or (excursion = 32)) and (on-the-car = 0) and (on-the-bus = 0) and (on-the-cablecar = 0) and (on-the-chairlift = 0)] [
    set alpha atan (tan([slope] of patch-here) * sin(90 - (heading - [aspect] of patch-here))) 1
    ifelse random 100 < 90
      [set speed (0.056 + speed-factor) * exp(-3.5 * abs(tan(alpha) + 0.05))]
      [set speed 0]
  ]

  ; hikers doing medium excursions sometimes stop while walking (i.e. walk 80% of time)
  ask visitors with [((excursion = 11) or (excursion = 14) or (excursion = 25) or (excursion = 31) or (excursion = 35) or (excursion = 41) or (excursion = 42))
    and (on-the-car = 0) and (on-the-bus = 0) and (on-the-cablecar = 0) and (on-the-chairlift = 0)] [
    set alpha atan (tan([slope] of patch-here) * sin(90 - (heading - [aspect] of patch-here))) 1
    ifelse random 100 < 80
      [set speed (0.054 + speed-factor) * exp(-3.5 * abs(tan(alpha) + 0.05))]
      [set speed 0]
  ]

  ; hikers doing short excursions often stop while walking (i.e. walk 70% of time)
  ask visitors with [((excursion = 13) or (excursion = 15) or (excursion = 19) or (excursion = 26) or (excursion = 33) or (excursion = 34))
    and (on-the-car = 0) and (on-the-bus = 0) and (on-the-cablecar = 0) and (on-the-chairlift = 0)] [
    set alpha atan (tan([slope] of patch-here) * sin(90 - (heading - [aspect] of patch-here))) 1
    ifelse random 100 < 70
      [set speed (0.052 + speed-factor) * exp(-3.5 * abs(tan(alpha) + 0.05))]
      [set speed 0]
  ]

  ;locations where visitors stop along the hike are defined
  ask visitors [
    ifelse (pxcor = 90) and (pycor = -237)   ;Paolina
    [set hike-stop 1]
    [ifelse (pxcor = 112) and (pycor = -243)   ;Aquila di Christomannos
      [set hike-stop 1]
      [ifelse (pxcor = 129) and (pycor = -219)   ;Roda de Vael
        [set hike-stop 1]
        [ifelse (pxcor = 98) and (pycor = -188)   ;Vaiolon
          [set hike-stop 1]
          [ifelse (pxcor = 129) and (pycor = -166)   ;Zigolade
            [set hike-stop 1]
            [ifelse (pxcor = 98) and (pycor = -146)   ;Coronelle
              [set hike-stop 1]
              [ifelse (pxcor = 80) and (pycor = -138)   ;Fronza
                [set hike-stop 1]
                [ifelse (pxcor = 152) and (pycor = -118)   ;Gardeccia
                  [set hike-stop 1]
                  [ifelse (pxcor = 131) and (pycor = -76)   ;Vajolet
                    [set hike-stop 1]
                    [ifelse (pxcor = 105) and (pycor = -75)   ;Re Alberto
                      [set hike-stop 1]
                      [ifelse (pxcor = 214) and (pycor = -166)   ;Ciampedie
                        [set hike-stop 1]
                        [ifelse (pxcor = 145) and (pycor = -18)   ;Passo Principe
                          [set hike-stop 1]
                          [set hike-stop 0
                            set local-time 0]
                        ]
                      ]
                    ]
                  ]
                ]
              ]
            ]
          ]
        ]
      ]
    ]

    if hike-stop = 1 [
      set time-stop time-stop + 1
    ]

    if hike-stop = 0 [
      set time-stop 0
    ]
  ]

  ; when visitors arrive at the Roda de Vael hut, the people-over-the-day counter is updated
  ask visitors with [(pxcor = 129) and (pycor = -219) and (roda-de-vael = 1)] [
    if time-stop = 1 [
      ask patch 129 -219 [
        set potd potd + [group-size] of myself
      ]
    ]
  ]



  ;the variable local-time is assigned the time at which a visitor reaches a popular point
  ask visitors with [local-time = 0] [
    if (pxcor = 90) and (pycor = -237) [  ;Paolina
      set local-time ticks
    ]
    if (pxcor = 112) and (pycor = -243) [   ;Aquila di Christomannos
      set local-time ticks
    ]
    if (pxcor = 129) and (pycor = -219) [   ;Roda de Vael
      set local-time ticks
    ]
    if (pxcor = 98) and (pycor = -188) [   ;Vaiolon
      set local-time ticks
    ]
    if (pxcor = 129) and (pycor = -166) [   ;Zigolade
      set local-time ticks
    ]
    if (pxcor = 98) and (pycor = -146) [   ;Coronelle
      set local-time ticks
    ]
    if (pxcor = 80) and (pycor = -138) [   ;Fronza
      set local-time ticks
    ]
    if (pxcor = 152) and (pycor = -118) [   ;Gardeccia
      set local-time ticks
    ]
    if (pxcor = 131) and (pycor = -76) [   ;Vajolet
      set local-time ticks
    ]
    if (pxcor = 105) and (pycor = -75) [   ;Re Alberto
      set local-time ticks
    ]
    if (pxcor = 214) and (pycor = -166) [   ;Ciampedie
      set local-time ticks
    ]
    if (pxcor = 145) and (pycor = -18) [   ;Passo Principe
      set local-time ticks
    ]
    ]

  ;the time-factor is a number ranging from 0 to 1 and proportional to the difference in time between the end of the excursion day and the time of birth (i.e. final-time - birth)
  ;that is multiplied by the length of a stopover to ensure that visitors make shorter stopovers when they leave late
  ;time-factor for long hikes
  ask visitors with [(excursion = 12) or (excursion = 16) or (excursion = 17) or (excursion = 18) or (excursion = 21) or (excursion = 22) or (excursion = 23) or (excursion = 24) or (excursion = 32)] [
    ifelse final-time - birth > 28800
    [set time-factor 1]
    [ifelse (final-time - birth > 27000) and (final-time - birth <= 28800)
      [set time-factor 0.9]
      [ifelse (final-time - birth > 25200) and (final-time - birth <= 27000)
        [set time-factor 0.8]
        [ifelse (final-time - birth > 23400) and (final-time - birth <= 25200)
          [set time-factor 0.7]
          [ifelse (final-time - birth > 21600) and (final-time - birth <= 23400)
            [set time-factor 0.5]
            [set time-factor 0.3]
          ]
        ]
      ]
    ]
  ]


  ;time-factor for medium hikes
  ask visitors with [(excursion = 11) or (excursion = 14) or (excursion = 25) or (excursion = 31) or (excursion = 35) or (excursion = 41) or (excursion = 42)] [
    ifelse final-time - birth > 28800
    [set time-factor 1.4]
    [ifelse (final-time - birth > 27000) and (final-time - birth <= 28800)
      [set time-factor 1.2]
      [ifelse (final-time - birth > 25200) and (final-time - birth <= 27000)
        [set time-factor 1]
        [ifelse (final-time - birth > 23400) and (final-time - birth <= 25200)
          [set time-factor 0.8]
          [ifelse (final-time - birth > 21600) and (final-time - birth <= 23400)
            [set time-factor 0.6]
            [set time-factor 0.4]
          ]
        ]
      ]
    ]
  ]

  ;time-factor for short hikes
  ask visitors with [(excursion = 13) or (excursion = 15) or (excursion = 19) or (excursion = 26) or (excursion = 33) or (excursion = 34)] [
    ifelse final-time - birth > 28800
    [set time-factor 1.6]
    [ifelse (final-time - birth > 27000) and (final-time - birth <= 28800)
      [set time-factor 1.4]
      [ifelse (final-time - birth > 25200) and (final-time - birth <= 27000)
        [set time-factor 1.2]
        [ifelse (final-time - birth > 23400) and (final-time - birth <= 25200)
          [set time-factor 1]
          [ifelse (final-time - birth > 21600) and (final-time - birth <= 23400)
            [set time-factor 0.8]
            [set time-factor 0.6]
          ]
        ]
      ]
    ]
  ]

  ;;;;;;EXCURSIONS FROM THE COSTALUNGA PASS;;;;;;;;

  ;excursion 11: Costalunga-Roda de Vael-Aquila-Paolina-Costalunga
  ask visitors with [(excursion = 11) and (on-the-car = 0) and (on-the-bus = 0) and (on-the-way-to = 1) and (roda-de-vael = 0) and (aquila = 0) and (paolina = 0)] [
    ifelse (pxcor = 129) and (pycor = -219)
    []
    [face min-one-of neighbors [dist_rodadevael]
    fd speed]
  ]

  ask visitors with [(excursion = 11) and (on-the-car = 0) and (on-the-bus = 0) and (roda-de-vael = 1) and (aquila = 0) and (paolina = 0)] [
    if (time-stop = 0) or (time-stop > (6840 - random 3600 + random 3600) * time-factor) [
      ifelse (pxcor = 112) and (pycor = -243)
       []
       [face min-one-of neighbors [dist_paolina]
         fd speed]
    ]
  ]

  ask visitors with [(excursion = 11) and (on-the-car = 0) and (on-the-bus = 0) and (roda-de-vael = 1) and (aquila = 1) and (paolina = 0)] [
    if (time-stop = 0) or (time-stop > (600 - aquila-stop - 4 * sum [group-size] of visitors with [(pxcor = 112) and (pycor = -243)])) [
      ifelse (pxcor = 90) and (pycor = -237)
       []
       [face min-one-of neighbors [dist_paolina]
         fd speed]
    ]
  ]

  ask visitors with [(excursion = 11) and (transport-mode = 1) and (on-the-car = 0) and (roda-de-vael = 1) and (aquila = 1) and (paolina = 1)] [
    if (time-stop = 0) or (time-stop > (2880 - random 2280 + random 2280) * time-factor) [
      ifelse (pxcor = 88) and (pycor = -277)
       []
       [face min-one-of neighbors [dist_parking]
         fd speed]
    ]
  ]

  ask visitors with [(excursion = 11) and (transport-mode = 2) and (on-the-bus = 0) and (waiting = 0) and (arrived = 0) and (roda-de-vael = 1) and (aquila = 1) and (paolina = 1)] [
    if (time-stop = 0) or (time-stop > (2880 - random 2280 + random 2280) * time-factor) [
      ifelse (pxcor = 76) and (pycor = -277)
       []
       [face min-one-of neighbors [dist_busstop]
         fd speed]
    ]
  ]



  ;excursion 12: Costalunga-Paolina-Aquila-Roda de Vael-Coronelle-Fronza-Paolina-Costalunga
  ask visitors with [(excursion = 12) and (on-the-car = 0) and (on-the-bus = 0) and (on-the-way-to = 1) and (paolina = 0) and (aquila = 0) and (roda-de-vael = 0) and (coronelle = 0) and (fronza = 0)] [
    ifelse (pxcor = 90) and (pycor = -237)
    []
    [face min-one-of neighbors [dist_paolina]
    fd speed]
  ]

  ask visitors with [(excursion = 12) and (on-the-car = 0) and (on-the-bus = 0) and (paolina = 1) and (aquila = 0) and (roda-de-vael = 0) and (coronelle = 0) and (fronza = 0)] [
    if (time-stop = 0) or (time-stop > (1860 - random 1740 + random 1740) * time-factor) [
      ifelse (pxcor = 112) and (pycor = -243)
       []
       [face min-one-of neighbors [dist_rodadevael]
         fd speed]
    ]
  ]

  ask visitors with [(excursion = 12) and (on-the-car = 0) and (on-the-bus = 0) and (paolina = 1) and (aquila = 1) and (roda-de-vael = 0) and (coronelle = 0) and (fronza = 0)] [
    if (time-stop = 0) or (time-stop > (600 - aquila-stop - 4 * sum [group-size] of visitors with [(pxcor = 112) and (pycor = -243)])) [
      ifelse (pxcor = 129) and (pycor = -219)
       []
       [face min-one-of neighbors [dist_rodadevael]
         fd speed]
    ]
  ]

  ask visitors with [(excursion = 12) and (on-the-car = 0) and (on-the-bus = 0) and (on-the-car = 0) and (paolina = 1) and (aquila = 1) and (roda-de-vael = 1) and (coronelle = 0) and (fronza = 0)] [
    if (time-stop = 0) or (time-stop > (2400 - random 1800 + random 1800) * time-factor) [
      ifelse (pxcor = 98) and (pycor = -146)
       []
       [face min-one-of neighbors [dist_coronelle]
         fd speed]
    ]
  ]

  ask visitors with [(excursion = 12) and (on-the-car = 0) and (on-the-bus = 0) and (paolina = 1) and (aquila = 1) and (roda-de-vael = 1) and (coronelle = 1) and (fronza = 0)] [
    if (time-stop = 0) or (time-stop > (600 - random 300 + random 300) * time-factor) [
      ifelse (pxcor = 80) and (pycor = -138)
       []
       [face min-one-of neighbors [dist_fronza]
         fd speed]
    ]
  ]

  ask visitors with [(excursion = 12) and (on-the-car = 0) and (on-the-bus = 0) and (paolina = 1) and (aquila = 1) and (roda-de-vael = 1) and (coronelle = 1) and (fronza = 1)] [
    if (time-stop = 0) or (time-stop > (600 - random 300 + random 300) * time-factor) [
      ifelse (pxcor = 90) and (pycor = -237)
       []
       [face min-one-of neighbors [dist_paolina]
         fd speed]
    ]
  ]

  ask visitors with [(excursion = 12) and (transport-mode = 1) and (on-the-car = 0) and (paolina = 2) and (aquila = 1) and (roda-de-vael = 1) and (coronelle = 1) and (fronza = 1)] [
    if (time-stop = 0) or (time-stop > (1140 - random 900 + random 900) * time-factor) [
      ifelse (pxcor = 88) and (pycor = -277)
       []
       [face min-one-of neighbors [dist_parking]
         fd speed]
    ]
  ]

  ask visitors with [(excursion = 12) and (transport-mode = 2) and (on-the-bus = 0) and (waiting = 0) and (arrived = 0) and (paolina = 2) and (aquila = 1) and (roda-de-vael = 1) and (coronelle = 1) and (fronza = 1)] [
    if (time-stop = 0) or (time-stop > (1140 - random 900 + random 900) * time-factor) [
      ifelse (pxcor = 76) and (pycor = -277)
       []
       [face min-one-of neighbors [dist_busstop]
         fd speed]
    ]
  ]



  ;excursion 13: Costalunga-Paolina-Costalunga
  ask visitors with [(excursion = 13) and (on-the-car = 0) and (on-the-bus = 0) and (on-the-way-to = 1) and (paolina = 0)] [
    ifelse (pxcor = 90) and (pycor = -237)
    []
    [face min-one-of neighbors [dist_paolina]
      fd speed]
  ]

  ask visitors with [(excursion = 13) and (transport-mode = 1) and (on-the-car = 0) and (paolina = 1)] [
    if (time-stop = 0) or (time-stop > (5220 - random 1260 + random 1260) * time-factor) [
      ifelse (pxcor = 88) and (pycor = -277)
       []
       [face min-one-of neighbors [dist_parking]
         fd speed]
    ]
  ]

  ask visitors with [(excursion = 13) and (transport-mode = 2) and (on-the-bus = 0) and (waiting = 0) and (arrived = 0) and (paolina = 1)] [
    if (time-stop = 0) or (time-stop > (5220 - random 1260 + random 1260) * time-factor) [
      ifelse (pxcor = 76) and (pycor = -277)
       []
       [face min-one-of neighbors [dist_busstop]
         fd speed]
    ]
  ]



  ;excursion 14: Costalunga-Paolina-Aquila-Roda de Vael-Costalunga
  ask visitors with [(excursion = 14) and (on-the-car = 0) and (on-the-bus = 0) and (on-the-way-to = 1) and (roda-de-vael = 0) and (aquila = 0) and (paolina = 0)] [
    ifelse (pxcor = 90) and (pycor = -237)
    []
    [face min-one-of neighbors [dist_paolina]
    fd speed]
  ]

  ask visitors with [(excursion = 14) and (on-the-car = 0) and (on-the-bus = 0) and (roda-de-vael = 0) and (aquila = 0) and (paolina = 1)] [
    if (time-stop = 0) or (time-stop > (1860 - random 1740 + random 1740) * time-factor) [
      ifelse (pxcor = 112) and (pycor = -243)
       []
       [face min-one-of neighbors [dist_rodadevael]
         fd speed]
    ]
  ]

  ask visitors with [(excursion = 14) and (on-the-car = 0) and (on-the-bus = 0) and (roda-de-vael = 0) and (aquila = 1) and (paolina = 1)] [
    if (time-stop = 0) or (time-stop > (600 - aquila-stop - 4 * sum [group-size] of visitors with [(pxcor = 112) and (pycor = -243)])) [
      ifelse (pxcor = 129) and (pycor = -219)
       []
       [face min-one-of neighbors [dist_rodadevael]
         fd speed]
    ]
  ]

  ask visitors with [(excursion = 14) and (transport-mode = 1) and (on-the-car = 0) and (roda-de-vael = 1) and (aquila = 1) and (paolina = 1)] [
    if (time-stop = 0) or (time-stop > (2340 - random 1500 + random 1500) * time-factor) [
      ifelse (pxcor = 88) and (pycor = -277)
       []
       [face min-one-of neighbors [dist_parking]
         fd speed]
    ]
  ]

  ask visitors with [(excursion = 14) and (transport-mode = 2) and (on-the-bus = 0) and (waiting = 0) and (arrived = 0) and (roda-de-vael = 1) and (aquila = 1) and (paolina = 1)] [
    if (time-stop = 0) or (time-stop > (2340 - random 1500 + random 1500) * time-factor) [
      ifelse (pxcor = 76) and (pycor = -277)
       []
       [face min-one-of neighbors [dist_busstop]
         fd speed]
    ]
  ]



  ;excursion 15: Costalunga-Roda de Vael-Costalunga
  ask visitors with [(excursion = 15) and (on-the-car = 0) and (on-the-bus = 0) and (on-the-way-to = 1) and (roda-de-vael = 0)] [
    ifelse (pxcor = 129) and (pycor = -219)
    []
    [face min-one-of neighbors [dist_rodadevael]
      fd speed]
  ]

  ask visitors with [(excursion = 15) and (transport-mode = 1) and (on-the-car = 0) and (on-the-bus = 0) and (roda-de-vael = 1)] [
    if (time-stop = 0) or (time-stop > (4860 - random 3000 + random 3000) * time-factor) [
      ifelse (pxcor = 88) and (pycor = -277)
       []
       [face min-one-of neighbors [dist_parking]
         fd speed]
    ]
  ]

  ask visitors with [(excursion = 15) and (transport-mode = 2) and (on-the-bus = 0) and (waiting = 0) and (arrived = 0) and (roda-de-vael = 1)] [
    if (time-stop = 0) or (time-stop > (4860 - random 3000 + random 3000) * time-factor) [
      ifelse (pxcor = 76) and (pycor = -277)
       []
       [face min-one-of neighbors [dist_busstop]
         fd speed]
    ]
  ]



  ;excursion 16: Costalunga-Roda de Vael-Aquila-Fronza-Paolina-Aquila-Roda de Vael-Costalunga
  ask visitors with [(excursion = 16) and (on-the-car = 0) and (on-the-bus = 0) and (on-the-way-to = 1) and (paolina = 0) and (aquila = 0) and (roda-de-vael = 0) and (fronza = 0)] [
    ifelse (pxcor = 129) and (pycor = -219)
    []
    [face min-one-of neighbors [dist_rodadevael]
    fd speed]
  ]

  ask visitors with [(excursion = 16) and (on-the-car = 0) and (on-the-bus = 0) and (paolina = 0) and (aquila = 0) and (roda-de-vael = 1) and (fronza = 0)] [
    if (time-stop = 0) or (time-stop > (1860 - random 1740 + random 1740) * time-factor) [
      ifelse (pxcor = 112) and (pycor = -243)
       []
       [face min-one-of neighbors [dist_paolina]
         fd speed]
    ]
  ]

  ask visitors with [(excursion = 16) and (on-the-car = 0) and (on-the-bus = 0) and (paolina = 0) and (aquila = 1) and (roda-de-vael = 1) and (fronza = 0)] [
    if (time-stop = 0) or (time-stop > (600 - aquila-stop - 4 * sum [group-size] of visitors with [(pxcor = 112) and (pycor = -243)])) [
      ifelse (pxcor = 80) and (pycor = -138)
       []
       [face min-one-of neighbors [dist_fronza]
         fd speed]
    ]
  ]

  ask visitors with [(excursion = 16) and (on-the-car = 0) and (on-the-bus = 0) and (paolina = 0) and (aquila = 1) and (roda-de-vael = 1) and (fronza = 1)] [
    if (time-stop = 0) or (time-stop > (1320 - random 660 + random 660) * time-factor) [
      ifelse (pxcor = 90) and (pycor = -237)
       []
       [face min-one-of neighbors [dist_paolina]
         fd speed]
    ]
  ]

  ask visitors with [(excursion = 16) and (on-the-car = 0) and (on-the-bus = 0) and (paolina = 1) and (aquila = 1) and (roda-de-vael = 1) and (fronza = 1)] [
    if (time-stop = 0) or (time-stop > (1140 - random 900 + random 900) * time-factor) [
      ifelse (pxcor = 112) and (pycor = -243)
       []
       [face min-one-of neighbors [dist_rodadevael]
         fd speed]
    ]
  ]

  ask visitors with [(excursion = 16) and (on-the-car = 0) and (on-the-bus = 0) and (paolina = 1) and (aquila = 2) and (roda-de-vael = 1) and (fronza = 1)] [
    if (time-stop = 0) or (time-stop > (600 - aquila-stop - 4 * sum [group-size] of visitors with [(pxcor = 112) and (pycor = -243)])) [
      ifelse (pxcor = 129) and (pycor = -219)
       []
       [face min-one-of neighbors [dist_rodadevael]
         fd speed]
    ]
  ]

  ask visitors with [(excursion = 16) and (transport-mode = 1) and (on-the-car = 0) and (paolina = 1) and (aquila = 2) and (roda-de-vael = 2) and (fronza = 1)] [
    if (time-stop = 0) or (time-stop > (600 - random 300 + random 300) * time-factor) [
      ifelse (pxcor = 88) and (pycor = -277)
       []
       [face min-one-of neighbors [dist_parking]
         fd speed]
    ]
  ]

  ask visitors with [(excursion = 16) and (transport-mode = 2) and (on-the-bus = 0) and (waiting = 0) and (arrived = 0) and (paolina = 1) and (aquila = 2) and (roda-de-vael = 2) and (fronza = 1)] [
    if (time-stop = 0) or (time-stop > (600 - random 300 + random 300) * time-factor) [
      ifelse (pxcor = 76) and (pycor = -277)
       []
       [face min-one-of neighbors [dist_busstop]
         fd speed]
    ]
  ]



  ;excursion 17: Costalunga-Roda de Vael-Zigolade-Roda de Vael-Aquila-Paolina-Costalunga
    ask visitors with [(excursion = 17) and (on-the-car = 0) and (on-the-bus = 0) and (on-the-way-to = 1) and (paolina = 0) and (aquila = 0) and (roda-de-vael = 0) and (zigolade = 0)] [
    ifelse (pxcor = 129) and (pycor = -219)
    []
    [face min-one-of neighbors [dist_rodadevael]
    fd speed]
  ]

  ask visitors with [(excursion = 17) and (on-the-car = 0) and (on-the-bus = 0) and (paolina = 0) and (aquila = 0) and (roda-de-vael = 1) and (zigolade = 0)] [
    if (time-stop = 0) or (time-stop > (1860 - random 1740 + random 1740) * time-factor) [
      ifelse (pxcor = 129) and (pycor = -166)
       []
       [face min-one-of neighbors [dist_zigolade]
         fd speed]
    ]
  ]

  ask visitors with [(excursion = 17) and (on-the-car = 0) and (on-the-bus = 0) and (paolina = 0) and (aquila = 0) and (roda-de-vael = 1) and (zigolade = 1)] [
    if (time-stop = 0) or (time-stop > (600 - random 300 + random 300) * time-factor) [
      ifelse (pxcor = 129) and (pycor = -219)
       []
       [face min-one-of neighbors [dist_rodadevael]
         fd speed]
    ]
  ]

  ask visitors with [(excursion = 17) and (on-the-car = 0) and (on-the-bus = 0) and (paolina = 0) and (aquila = 0) and (roda-de-vael = 2) and (zigolade = 1)] [
    if (time-stop = 0) or (time-stop > (2400 - random 1800 + random 1800) * time-factor) [
      ifelse (pxcor = 112) and (pycor = -243)
       []
       [face min-one-of neighbors [dist_paolina]
         fd speed]
    ]
  ]

  ask visitors with [(excursion = 17) and (on-the-car = 0) and (on-the-bus = 0) and (paolina = 0) and (aquila = 1) and (roda-de-vael = 2) and (zigolade = 1)] [
    if (time-stop = 0) or (time-stop > (600 - aquila-stop - 4 * sum [group-size] of visitors with [(pxcor = 112) and (pycor = -243)])) [
      ifelse (pxcor = 90) and (pycor = -237)
       []
       [face min-one-of neighbors [dist_paolina]
         fd speed]
    ]
  ]

  ask visitors with [(excursion = 17) and (transport-mode = 1) and (on-the-car = 0) and (paolina = 1) and (aquila = 1) and (roda-de-vael = 2) and (zigolade = 1)] [
    if (time-stop = 0) or (time-stop > (600 - random 300 + random 300) * time-factor) [
      ifelse (pxcor = 88) and (pycor = -277)
       []
       [face min-one-of neighbors [dist_parking]
         fd speed]
    ]
  ]

  ask visitors with [(excursion = 17) and (transport-mode = 2) and (on-the-bus = 0) and (waiting = 0) and (arrived = 0) and (paolina = 1) and (aquila = 1) and (roda-de-vael = 2) and (zigolade = 1)] [
    if (time-stop = 0) or (time-stop > (600 - random 300 + random 300) * time-factor) [
      ifelse (pxcor = 76) and (pycor = -277)
       []
       [face min-one-of neighbors [dist_busstop]
         fd speed]
    ]
  ]



  ;excursion 18: Costalunga-Paolina-Fronza-Coronelle-Roda de Vael-Costalunga
  ask visitors with [(excursion = 18) and (on-the-car = 0) and (on-the-bus = 0) and (on-the-way-to = 1) and (paolina = 0) and (roda-de-vael = 0) and (coronelle = 0) and (fronza = 0)] [
    ifelse (pxcor = 90) and (pycor = -237)
    []
    [face min-one-of neighbors [dist_paolina]
    fd speed]
  ]

  ask visitors with [(excursion = 18) and (on-the-car = 0) and (on-the-bus = 0) and (paolina = 1) and (roda-de-vael = 0) and (coronelle = 0) and (fronza = 0)] [
    if (time-stop = 0) or (time-stop > (1860 - random 1740 + random 1740) * time-factor) [
      ifelse (pxcor = 80) and (pycor = -138)
       []
       [face min-one-of neighbors [dist_fronza]
         fd speed]
    ]
  ]

  ask visitors with [(excursion = 18) and (on-the-car = 0) and (on-the-bus = 0) and (paolina = 1) and (roda-de-vael = 0) and (coronelle = 0) and (fronza = 1)] [
    if (time-stop = 0) or (time-stop > (1320 - random 660 + random 660) * time-factor) [
      ifelse (pxcor = 98) and (pycor = -146)
       []
       [face min-one-of neighbors [dist_coronelle]
         fd speed]
    ]
  ]

  ask visitors with [(excursion = 18) and (on-the-car = 0) and (on-the-bus = 0) and (paolina = 1) and (roda-de-vael = 0) and (coronelle = 1) and (fronza = 1)] [
    if (time-stop = 0) or (time-stop > (600 - random 300 + random 300) * time-factor) [
      ifelse (pxcor = 129) and (pycor = -219)
       []
       [face min-one-of neighbors [dist_rodadevael]
         fd speed]
    ]
  ]

  ask visitors with [(excursion = 18) and (transport-mode = 1) and (on-the-car = 0) and (paolina = 1) and (roda-de-vael = 1) and (coronelle = 1) and (fronza = 1)] [
    if (time-stop = 0) or (time-stop > (2340 - random 1500 + random 1500) * time-factor) [
      ifelse (pxcor = 88) and (pycor = -277)
       []
       [face min-one-of neighbors [dist_parking]
         fd speed]
    ]
  ]

  ask visitors with [(excursion = 18) and (transport-mode = 2) and (on-the-bus = 0) and (waiting = 0) and (arrived = 0) and (paolina = 1) and (roda-de-vael = 1) and (coronelle = 1) and (fronza = 1)] [
    if (time-stop = 0) or (time-stop > (2340 - random 1500 + random 1500) * time-factor) [
      ifelse (pxcor = 76) and (pycor = -277)
       []
       [face min-one-of neighbors [dist_busstop]
         fd speed]
    ]
  ]



  ;excursion 19: Costalunga-Paolina-Aquila-Paolina-Costalunga
  ask visitors with [(excursion = 19) and (on-the-car = 0) and (on-the-bus = 0) and (on-the-way-to = 1) and (paolina = 0) and (aquila = 0)] [
    ifelse (pxcor = 90) and (pycor = -237)
    []
    [face min-one-of neighbors [dist_paolina]
    fd speed]
  ]

  ask visitors with [(excursion = 19) and (on-the-car = 0) and (on-the-bus = 0) and (paolina = 1) and (aquila = 0)] [
    if (time-stop = 0) or (time-stop > (1860 - random 1740 + random 1740) * time-factor) [
      ifelse (pxcor = 112) and (pycor = -243)
       []
       [face min-one-of neighbors [dist_rodadevael]
         fd speed]
    ]
  ]

  ask visitors with [(excursion = 19) and (on-the-car = 0) and (on-the-bus = 0) and (paolina = 1) and (aquila = 1)] [
    if (time-stop = 0) or (time-stop > (600 - aquila-stop - 4 * sum [group-size] of visitors with [(pxcor = 112) and (pycor = -243)])) [
      ifelse (pxcor = 90) and (pycor = -237)
       []
       [face min-one-of neighbors [dist_paolina]
         fd speed]
    ]
  ]

  ask visitors with [(excursion = 19) and (transport-mode = 1) and (on-the-car = 0) and (paolina = 2) and (aquila = 1)] [
    if (time-stop = 0) or (time-stop > (2880 - random 2280 + random 2280) * time-factor) [
      ifelse (pxcor = 88) and (pycor = -277)
       []
       [face min-one-of neighbors [dist_parking]
         fd speed]
    ]
  ]

  ask visitors with [(excursion = 19) and (transport-mode = 2) and (on-the-bus = 0) and (waiting = 0) and (arrived = 0) and (paolina = 2) and (aquila = 1)] [
    if (time-stop = 0) or (time-stop > (2880 - random 2280 + random 2280) * time-factor) [
      ifelse (pxcor = 76) and (pycor = -277)
       []
       [face min-one-of neighbors [dist_busstop]
         fd speed]
    ]
  ]



  ;visitors move to the bus stop
  ask visitors with [(pxcor = 76) and (pycor = -277) and (on-the-way-to = 0) and (origin = 1)] [
    move-to patch 80 -279
  ]

  ask visitors with [(pxcor = 76) and (pycor = -277) and (on-the-way-to = 0) and (origin = 2)] [
    move-to patch 82 -279
  ]

  ;visitors start waiting for the bus to go back
  ask visitors with [(pxcor = 80) and (pycor = -279) and (on-the-way-to = 0) and (origin = 1)] [
    set waiting waiting + 1
  ]

  ask visitors with [(pxcor = 82) and (pycor = -279) and (on-the-way-to = 0) and (origin = 2)] [
    set waiting waiting + 1
  ]



    ;;;;;;EXCURSIONS FROM CIAMPEDIE;;;;;;

  ;excursion 21: Ciampedie-Gardeccia-Vajolet-Gardeccia-Ciampedie
  ask visitors with [(excursion = 21) and (on-the-cablecar = 0) and (gardeccia = 0) and (vajolet = 0) and (ciampedie = 1)] [
    if (time-stop = 0) or (time-stop > (1200 - random 600 + random 600) * time-factor) [
      ifelse (pxcor = 152) and (pycor = -118)
       []
       [face min-one-of neighbors [dist_gardeccia]
         fd speed]
    ]
  ]

  ask visitors with [(excursion = 21) and (on-the-cablecar = 0) and (gardeccia = 1) and (vajolet = 0) and (ciampedie = 1)] [
    if (time-stop = 0) or (time-stop > (2940 - random 2400 + random 2400) * time-factor) [
      ifelse (pxcor = 131) and (pycor = -76)
       []
       [face min-one-of neighbors [dist_vajolet]
         fd speed]
    ]
  ]

  ask visitors with [(excursion = 21) and (on-the-cablecar = 0) and (gardeccia = 1) and (vajolet = 1) and (ciampedie = 1)] [
    if (time-stop = 0) or (time-stop > (4560 - random 1380 + random 1380) * time-factor) [
      ifelse (pxcor = 152) and (pycor = -118)
       []
       [face min-one-of neighbors [dist_gardeccia]
         fd speed]
    ]
  ]

  ask visitors with [(excursion = 21) and (on-the-cablecar = 0) and (gardeccia = 2) and (vajolet = 1) and (ciampedie = 1)] [
    if (time-stop = 0) or (time-stop > (600 - random 180 + random 180) * time-factor) [
      ifelse (pxcor = 214) and (pycor = -166)
       []
       [face min-one-of neighbors [dist_ciampedie]
         fd speed]
    ]
  ]

  ask visitors with [(excursion = 21) and (on-the-cablecar = 0) and (gardeccia = 2) and (vajolet = 1) and (ciampedie = 2)] [
    if time-stop > (720 - random 660 + random 660) * time-factor [
      move-to patch 216 -167
    ]
  ]



  ;excursion 22: Ciampedie-Roda de Vael-Vajolet-Gardeccia-Ciampedie
  ask visitors with [(excursion = 22) and (on-the-cablecar = 0) and (roda-de-vael = 0) and (gardeccia = 0) and (vajolet = 0) and (ciampedie = 1)] [
    if (time-stop = 0) or (time-stop > (1200 - random 600 + random 600) * time-factor) [
      ifelse (pxcor = 129) and (pycor = -219)
       []
       [face min-one-of neighbors [dist_rodadevael]
         fd speed]
    ]
  ]

  ask visitors with [(excursion = 22) and (on-the-cablecar = 0) and (roda-de-vael = 1) and (gardeccia = 0) and (vajolet = 0) and (ciampedie = 1)] [
    if (time-stop = 0) or (time-stop > (1800 - random 1200 + random 1200) * time-factor) [
      ifelse (pxcor = 131) and (pycor = -76)
       []
       [face min-one-of neighbors [dist_vajolet]
         fd speed]
    ]
  ]

  ask visitors with [(excursion = 22) and (on-the-cablecar = 0) and (roda-de-vael = 1) and (gardeccia = 0) and (vajolet = 1) and (ciampedie = 1)] [
    if (time-stop = 0) or (time-stop > (2700 - random 1200 + random 1200) * time-factor) [
      ifelse (pxcor = 152) and (pycor = -118)
       []
       [face min-one-of neighbors [dist_gardeccia]
         fd speed]
    ]
  ]

  ask visitors with [(excursion = 22) and (on-the-cablecar = 0) and (roda-de-vael = 1) and (gardeccia = 1) and (vajolet = 1) and (ciampedie = 1)] [
    if (time-stop = 0) or (time-stop > (600 - random 180 + random 180) * time-factor) [
      ifelse (pxcor = 214) and (pycor = -166)
       []
       [face min-one-of neighbors [dist_ciampedie]
         fd speed]
    ]
  ]

  ask visitors with [(excursion = 22) and (on-the-cablecar = 0) and (roda-de-vael = 1) and (gardeccia = 1) and (vajolet = 1) and (ciampedie = 2)] [
    if time-stop > (720 - random 660 + random 660) * time-factor [
      move-to patch 216 -167
    ]
  ]



  ;excursion 23: Ciampedie-Gardeccia-Vajolet-Passo Principe-Vajolet-Gardeccia-Ciampedie
  ask visitors with [(excursion = 23) and (on-the-cablecar = 0) and (gardeccia = 0) and (vajolet = 0) and (principe = 0) and (ciampedie = 1)] [
    if (time-stop = 0) or (time-stop > (1200 - random 600 + random 600) * time-factor) [
      ifelse (pxcor = 152) and (pycor = -118)
       []
       [face min-one-of neighbors [dist_gardeccia]
         fd speed]
    ]
  ]

  ask visitors with [(excursion = 23) and (on-the-cablecar = 0) and (gardeccia = 1) and (vajolet = 0) and (principe = 0) and (ciampedie = 1)] [
    if (time-stop = 0) or (time-stop > (720 - random 480 + random 480) * time-factor) [
      ifelse (pxcor = 131) and (pycor = -76)
       []
       [face min-one-of neighbors [dist_vajolet]
         fd speed]
    ]
  ]

  ask visitors with [(excursion = 23) and (on-the-cablecar = 0) and (gardeccia = 1) and (vajolet = 1) and (principe = 0) and (ciampedie = 1)] [
    if (time-stop = 0) or (time-stop > (2700 - random 1200 + random 1200) * time-factor) [
      ifelse (pxcor = 145) and (pycor = -18)
       []
       [face min-one-of neighbors [dist_principe]
         fd speed]
    ]
  ]

  ask visitors with [(excursion = 23) and (on-the-cablecar = 0) and (gardeccia = 1) and (vajolet = 1) and (principe = 1) and (ciampedie = 1)] [
    if (time-stop = 0) or (time-stop > (2460 - random 2040 + random 2040) * time-factor) [
      ifelse (pxcor = 131) and (pycor = -76)
       []
       [face min-one-of neighbors [dist_vajolet]
         fd speed]
    ]
  ]

  ask visitors with [(excursion = 23) and (on-the-cablecar = 0) and (gardeccia = 1) and (vajolet = 2) and (principe = 1) and (ciampedie = 1)] [
    if (time-stop = 0) or (time-stop > (600 - random 300 + random 300) * time-factor) [
      ifelse (pxcor = 152) and (pycor = -118)
       []
       [face min-one-of neighbors [dist_gardeccia]
         fd speed]
    ]
  ]

  ask visitors with [(excursion = 23) and (on-the-cablecar = 0) and (gardeccia = 2) and (vajolet = 2) and (principe = 1) and (ciampedie = 1)] [
    if (time-stop = 0) or (time-stop > (600 - random 180 + random 180) * time-factor) [
      ifelse (pxcor = 214) and (pycor = -166)
       []
       [face min-one-of neighbors [dist_ciampedie]
         fd speed]
    ]
  ]

  ask visitors with [(excursion = 23) and (on-the-cablecar = 0) and (gardeccia = 2) and (vajolet = 2) and (principe = 1) and (ciampedie = 2)] [
    if time-stop > (720 - random 660 + random 660) * time-factor [
      move-to patch 216 -167
    ]
  ]



  ;excursion 24: Ciampedie-Gardeccia-Vajolet-Re Alberto-Vajolet-Gardeccia-Ciampedie
  ask visitors with [(excursion = 24) and (on-the-cablecar = 0) and (gardeccia = 0) and (vajolet = 0) and (re-alberto = 0) and (ciampedie = 1)] [
    if (time-stop = 0) or (time-stop > (1200 - random 600 + random 600) * time-factor) [
      ifelse (pxcor = 152) and (pycor = -118)
       []
       [face min-one-of neighbors [dist_gardeccia]
         fd speed]
    ]
  ]

  ask visitors with [(excursion = 24) and (on-the-cablecar = 0) and (gardeccia = 1) and (vajolet = 0) and (re-alberto = 0) and (ciampedie = 1)] [
    if (time-stop = 0) or (time-stop > (720 - random 480 + random 480) * time-factor) [
      ifelse (pxcor = 131) and (pycor = -76)
       []
       [face min-one-of neighbors [dist_vajolet]
         fd speed]
    ]
  ]

  ask visitors with [(excursion = 24) and (on-the-cablecar = 0) and (gardeccia = 1) and (vajolet = 1) and (re-alberto = 0) and (ciampedie = 1)] [
    if (time-stop = 0) or (time-stop > (2700 - random 1200 + random 1200) * time-factor) [
      ifelse (pxcor = 105) and (pycor = -75)
       []
       [face min-one-of neighbors [dist_realberto]
         fd speed]
    ]
  ]

  ask visitors with [(excursion = 24) and (on-the-cablecar = 0) and (gardeccia = 1) and (vajolet = 1) and (re-alberto = 1) and (ciampedie = 1)] [
    if (time-stop = 0) or (time-stop > (2400 - random 600 + random 600) * time-factor) [
      ifelse (pxcor = 131) and (pycor = -76)
       []
       [face min-one-of neighbors [dist_vajolet]
         fd speed]
    ]
  ]

  ask visitors with [(excursion = 24) and (on-the-cablecar = 0) and (gardeccia = 1) and (vajolet = 2) and (re-alberto = 1) and (ciampedie = 1)] [
    if (time-stop = 0) or (time-stop > (600 - random 300 + random 300) * time-factor) [
      ifelse (pxcor = 152) and (pycor = -118)
       []
       [face min-one-of neighbors [dist_gardeccia]
         fd speed]
    ]
  ]

  ask visitors with [(excursion = 24) and (on-the-cablecar = 0) and (gardeccia = 2) and (vajolet = 2) and (re-alberto = 1) and (ciampedie = 1)] [
    if (time-stop = 0) or (time-stop > (600 - random 180 + random 180) * time-factor) [
      ifelse (pxcor = 214) and (pycor = -166)
       []
       [face min-one-of neighbors [dist_ciampedie]
         fd speed]
    ]
  ]

  ask visitors with [(excursion = 24) and (on-the-cablecar = 0) and (gardeccia = 2) and (vajolet = 2) and (re-alberto = 1) and (ciampedie = 2)] [
    if time-stop > (720 - random 660 + random 660) * time-factor [
      move-to patch 216 -167
    ]
  ]



  ;excursion 25: Ciampedie-Roda de Vael-Ciampedie
  ask visitors with [(excursion = 25) and (on-the-cablecar = 0) and (roda-de-vael = 0) and (ciampedie = 1)] [
    if (time-stop = 0) or (time-stop > (1200 - random 600 + random 600) * time-factor) [
      ifelse (pxcor = 129) and (pycor = -219)
       []
       [face min-one-of neighbors [dist_rodadevael]
         fd speed]
    ]
  ]

  ask visitors with [(excursion = 25) and (on-the-cablecar = 0) and (roda-de-vael = 1) and (ciampedie = 1)] [
    if (time-stop = 0) or (time-stop > (5580 - random 3240 + random 3240) * time-factor) [
      ifelse (pxcor = 214) and (pycor = -166)
       []
       [face min-one-of neighbors [dist_ciampedie]
         fd speed]
    ]
  ]

  ask visitors with [(excursion = 25) and (on-the-cablecar = 0) and (roda-de-vael = 1) and (ciampedie = 2)] [
    if time-stop > (1680 - random 1020 + random 1020) * time-factor [
      move-to patch 216 -167
    ]
  ]



  ;excursion 26: Ciampedie-Gardeccia-Ciampedie
  ask visitors with [(excursion = 26) and (on-the-cablecar = 0) and (gardeccia = 0) and (ciampedie = 1)] [
    if (time-stop = 0) or (time-stop > (1200 - random 600 + random 600) * time-factor) [
      ifelse (pxcor = 152) and (pycor = -118)
       []
       [face min-one-of neighbors [dist_gardeccia]
         fd speed]
    ]
  ]

  ask visitors with [(excursion = 26) and (on-the-cablecar = 0) and (gardeccia = 1) and (ciampedie = 1)] [
    if (time-stop = 0) or (time-stop > (6000 - random 3180 + random 3180) * time-factor) [
      ifelse (pxcor = 214) and (pycor = -166)
       []
       [face min-one-of neighbors [dist_ciampedie]
         fd speed]
    ]
  ]

  ask visitors with [(excursion = 26) and (on-the-cablecar = 0) and (gardeccia = 1) and (ciampedie = 2)] [
    if time-stop > (1680 - random 1020 + random 1020) * time-factor [
      move-to patch 216 -167
    ]
  ]



   ;;;;;;EXCURSIONS FROM PAOLINA;;;;;;

  ;excursion 31: Paolina-Aquila-Roda de Vael-Vaiolon-Paolina
  ask visitors with [(excursion = 31) and (on-the-chairlift = 0) and (aquila = 0) and (roda-de-vael = 0) and (vaiolon = 0) and (paolina = 1)] [
    if (time-stop = 0) or (time-stop > (1200 - random 600 + random 600) * time-factor) [
      ifelse (pxcor = 112) and (pycor = -243)
       []
       [face min-one-of neighbors [dist_rodadevael]
         fd speed]
    ]
  ]

  ask visitors with [(excursion = 31) and (on-the-chairlift = 0) and (aquila = 1) and (roda-de-vael = 0) and (vaiolon = 0) and (paolina = 1)] [
    if (time-stop = 0) or (time-stop > (600 - aquila-stop - 4 * sum [group-size] of visitors with [(pxcor = 112) and (pycor = -243)])) [
      ifelse (pxcor = 129) and (pycor = -219)
       []
       [face min-one-of neighbors [dist_rodadevael]
         fd speed]
    ]
  ]

  ask visitors with [(excursion = 31) and (on-the-chairlift = 0) and (aquila = 1) and (roda-de-vael = 1) and (vaiolon = 0) and (paolina = 1)] [
    if (time-stop = 0) or (time-stop > (2580 - random 540 + random 540) * time-factor) [
      ifelse (pxcor = 98) and (pycor = -188)
       []
       [face min-one-of neighbors [dist_vaiolon]
         fd speed]
    ]
  ]

  ask visitors with [(excursion = 31) and (on-the-chairlift = 0) and (aquila = 1) and (roda-de-vael = 1) and (vaiolon = 1) and (paolina = 1)] [
    if (time-stop = 0) or (time-stop > (2040 - random 600 + random 600) * time-factor) [
      ifelse (pxcor = 90) and (pycor = -237)
       []
       [face min-one-of neighbors [dist_paolina]
         fd speed]
    ]
  ]

  ask visitors with [(excursion = 31) and (on-the-chairlift = 0) and (aquila = 1) and (roda-de-vael = 1) and (vaiolon = 1) and (paolina = 2)] [
    if time-stop > (300 - random 180 + random 180) * time-factor [
      move-to patch 88 -235
    ]
  ]



  ;excursion 32: Paolina-Aquila-Roda de Vael-Coronelle-Fronza-Paolina
  ask visitors with [(excursion = 32) and (on-the-chairlift = 0) and (aquila = 0) and (roda-de-vael = 0) and (coronelle = 0) and (fronza = 0) and (paolina = 1)] [
    if (time-stop = 0) or (time-stop > (1200 - random 600 + random 600) * time-factor) [
      ifelse (pxcor = 112) and (pycor = -243)
       []
       [face min-one-of neighbors [dist_rodadevael]
         fd speed]
    ]
  ]

  ask visitors with [(excursion = 32) and (on-the-chairlift = 0) and (aquila = 1) and (roda-de-vael = 0) and (coronelle = 0) and (fronza = 0) and (paolina = 1)] [
    if (time-stop = 0) or (time-stop > (600 - aquila-stop - 4 * sum [group-size] of visitors with [(pxcor = 112) and (pycor = -243)])) [
      ifelse (pxcor = 129) and (pycor = -219)
       []
       [face min-one-of neighbors [dist_rodadevael]
         fd speed]
    ]
  ]

  ask visitors with [(excursion = 32) and (on-the-chairlift = 0) and (aquila = 1) and (roda-de-vael = 1) and (coronelle = 0) and (fronza = 0) and (paolina = 1)] [
    if (time-stop = 0) or (time-stop > (2100 - random 540 + random 540) * time-factor) [
      ifelse (pxcor = 98) and (pycor = -146)
       []
       [face min-one-of neighbors [dist_coronelle]
         fd speed]
    ]
  ]

  ask visitors with [(excursion = 32) and (on-the-chairlift = 0) and (aquila = 1) and (roda-de-vael = 1) and (coronelle = 1) and (fronza = 0) and (paolina = 1)] [
    if (time-stop = 0) or (time-stop > (600 - random 300 + random 300) * time-factor) [
      ifelse (pxcor = 80) and (pycor = -138)
       []
       [face min-one-of neighbors [dist_fronza]
         fd speed]
    ]
  ]

  ask visitors with [(excursion = 32) and (on-the-chairlift = 0) and (aquila = 1) and (roda-de-vael = 1) and (coronelle = 1) and (fronza = 1) and (paolina = 1)] [
    if (time-stop = 0) or (time-stop > (2160 - random 1080 + random 1080) * time-factor) [
      ifelse (pxcor = 90) and (pycor = -237)
       []
       [face min-one-of neighbors [dist_paolina]
         fd speed]
    ]
  ]

  ask visitors with [(excursion = 32) and (on-the-chairlift = 0) and (aquila = 1) and (roda-de-vael = 1) and (coronelle = 1) and (fronza = 1) and (paolina = 2)] [
    if time-stop > (300 - random 180 + random 180) * time-factor [
      move-to patch 88 -235
    ]
  ]



  ;excursion 33: Paolina-Fronza-Paolina
  ask visitors with [(excursion = 33) and (on-the-chairlift = 0) and (fronza = 0) and (paolina = 1)] [
    if (time-stop = 0) or (time-stop > (1200 - random 600 + random 600) * time-factor) [
      ifelse (pxcor = 80) and (pycor = -138)
       []
       [face min-one-of neighbors [dist_fronza]
         fd speed]
    ]
  ]

  ask visitors with [(excursion = 33) and (on-the-chairlift = 0) and (fronza = 1) and (paolina = 1)] [
    if (time-stop = 0) or (time-stop > (6780 - random 600 + random 600) * time-factor) [
      ifelse (pxcor = 90) and (pycor = -237)
       []
       [face min-one-of neighbors [dist_paolina]
         fd speed]
    ]
  ]

  ask visitors with [(excursion = 33) and (on-the-chairlift = 0) and (fronza = 1) and (paolina = 2)] [
    if time-stop > (300 - random 180 + random 180) * time-factor [
      move-to patch 88 -235
    ]
  ]



  ;excursion 34: Paolina-Aquila-Roda de Vael-Aquila-Paolina
  ask visitors with [(excursion = 34) and (on-the-chairlift = 0) and (aquila = 0) and (roda-de-vael = 0) and (paolina = 1)] [
    if (time-stop = 0) or (time-stop > (1200 - random 600 + random 600) * time-factor) [
      ifelse (pxcor = 112) and (pycor = -243)
       []
       [face min-one-of neighbors [dist_rodadevael]
         fd speed]
    ]
  ]

  ask visitors with [(excursion = 34) and (on-the-chairlift = 0) and (aquila = 1) and (roda-de-vael = 0) and (paolina = 1)] [
    if (time-stop = 0) or (time-stop > (600 - aquila-stop - 4 * sum [group-size] of visitors with [(pxcor = 112) and (pycor = -243)])) [
      ifelse (pxcor = 129) and (pycor = -219)
       []
       [face min-one-of neighbors [dist_rodadevael]
         fd speed]
    ]
  ]

  ask visitors with [(excursion = 34) and (on-the-chairlift = 0) and (aquila = 1) and (roda-de-vael = 1) and (paolina = 1)] [
    if (time-stop = 0) or (time-stop > (5100 - random 2280 + random 2280) * time-factor) [
      ifelse (pxcor = 112) and (pycor = -243)
       []
       [face min-one-of neighbors [dist_paolina]
         fd speed]
    ]
  ]

  ask visitors with [(excursion = 34) and (on-the-chairlift = 0) and (aquila = 2) and (roda-de-vael = 1) and (paolina = 1)] [
    if (time-stop = 0) or (time-stop > (300 - random 150 + random 150) * time-factor) [
      ifelse (pxcor = 90) and (pycor = -237)
       []
       [face min-one-of neighbors [dist_paolina]
         fd speed]
    ]
  ]

  ask visitors with [(excursion = 34) and (on-the-chairlift = 0) and (aquila = 2) and (roda-de-vael = 1) and (paolina = 2)] [
    if time-stop > (300 - random 180 + random 180) * time-factor [
      move-to patch 88 -235
    ]
  ]



  ;excursion 35: Paolina-Aquila-Roda de Vael-Zigolade-Roda de Vael-Aquila-Paolina
  ask visitors with [(excursion = 35) and (on-the-chairlift = 0) and (aquila = 0) and (roda-de-vael = 0) and (zigolade = 0) and (paolina = 1)] [
    if (time-stop = 0) or (time-stop > (1200 - random 600 + random 600) * time-factor) [
      ifelse (pxcor = 112) and (pycor = -243)
       []
       [face min-one-of neighbors [dist_rodadevael]
         fd speed]
    ]
  ]

  ask visitors with [(excursion = 35) and (on-the-chairlift = 0) and (aquila = 1) and (roda-de-vael = 0) and (zigolade = 0) and (paolina = 1)] [
    if (time-stop = 0) or (time-stop > (600 - aquila-stop - 4 * sum [group-size] of visitors with [(pxcor = 112) and (pycor = -243)])) [
      ifelse (pxcor = 129) and (pycor = -219)
       []
       [face min-one-of neighbors [dist_rodadevael]
         fd speed]
    ]
  ]

  ask visitors with [(excursion = 35) and (on-the-chairlift = 0) and (aquila = 1) and (roda-de-vael = 1) and (zigolade = 0) and (paolina = 1)] [
    if (time-stop = 0) or (time-stop > (2400 - random 540 + random 540) * time-factor) [
      ifelse (pxcor = 129) and (pycor = -166)
       []
       [face min-one-of neighbors [dist_zigolade]
         fd speed]
    ]
  ]

  ask visitors with [(excursion = 35) and (on-the-chairlift = 0) and (aquila = 1) and (roda-de-vael = 1) and (zigolade = 1) and (paolina = 1)] [
    if (time-stop = 0) or (time-stop > (1020 - random 240 + random 240) * time-factor) [
      ifelse (pxcor = 129) and (pycor = -219)
       []
       [face min-one-of neighbors [dist_rodadevael]
         fd speed]
    ]
  ]

  ask visitors with [(excursion = 35) and (on-the-chairlift = 0) and (aquila = 1) and (roda-de-vael = 2) and (zigolade = 1) and (paolina = 1)] [
    if (time-stop = 0) or (time-stop > (720 - random 360 + random 360) * time-factor) [
      ifelse (pxcor = 112) and (pycor = -243)
       []
       [face min-one-of neighbors [dist_paolina]
         fd speed]
    ]
  ]

  ask visitors with [(excursion = 35) and (on-the-chairlift = 0) and (aquila = 2) and (roda-de-vael = 2) and (zigolade = 1) and (paolina = 1)] [
    if (time-stop = 0) or (time-stop > (600 - 4 * sum [group-size] of visitors with [(pxcor = 112) and (pycor = -243)])) [
      ifelse (pxcor = 90) and (pycor = -237)
       []
       [face min-one-of neighbors [dist_paolina]
         fd speed]
    ]
  ]

  ask visitors with [(excursion = 35) and (on-the-chairlift = 0) and (aquila = 2) and (roda-de-vael = 2) and (zigolade = 1) and (paolina = 2)] [
    if time-stop > (300 - random 180 + random 180) * time-factor [
      move-to patch 88 -235
    ]
  ]


 ;;;;;;;;;CROSSING EXCURSIONS;;;;;;;;

 ;excursion 41: Ciampedie-Roda de Vael-Aquila-Paolina
 ask visitors with [(excursion = 41) and (on-the-cablecar = 0) and (roda-de-vael = 0) and (aquila = 0) and (paolina = 0) and (ciampedie = 1)] [
    if (time-stop = 0) or (time-stop > (1200 - random 600 + random 600) * time-factor) [
      ifelse (pxcor = 129) and (pycor = -219)
       []
       [face min-one-of neighbors [dist_rodadevael]
         fd speed]
    ]
  ]

  ask visitors with [(excursion = 41) and (on-the-cablecar = 0) and (roda-de-vael = 1) and (aquila = 0) and (paolina = 0) and (ciampedie = 1)] [
    if (time-stop = 0) or (time-stop > (4860 - random 3240 + random 3240) * time-factor) [
      ifelse (pxcor = 112) and (pycor = -243)
       []
       [face min-one-of neighbors [dist_paolina]
         fd speed]
    ]
  ]

  ask visitors with [(excursion = 41) and (on-the-cablecar = 0) and (roda-de-vael = 1) and (aquila = 1) and (paolina = 0) and (ciampedie = 1)] [
    if (time-stop = 0) or (time-stop > (600 - aquila-stop - 4 * sum [group-size] of visitors with [(pxcor = 112) and (pycor = -243)])) [
      ifelse (pxcor = 90) and (pycor = -237)
       []
       [face min-one-of neighbors [dist_paolina]
         fd speed]
    ]
  ]

  ask visitors with [(excursion = 41) and (on-the-cablecar = 0) and (roda-de-vael = 1) and (aquila = 1) and (paolina = 1) and (ciampedie = 1)] [
    if time-stop > (300 - random 180 + random 180) * time-factor [
      move-to patch 88 -235
    ]
  ]


  ;excursion 42: Paolina-Aquila-Roda de Vael-Ciampedie
  ask visitors with [(excursion = 42) and (on-the-chairlift = 0) and (aquila = 0) and (roda-de-vael = 0) and (paolina = 1) and (ciampedie = 0)] [
    if (time-stop = 0) or (time-stop > (1200 - random 600 + random 600) * time-factor) [
      ifelse (pxcor = 112) and (pycor = -243)
       []
       [face min-one-of neighbors [dist_rodadevael]
         fd speed]
    ]
  ]

  ask visitors with [(excursion = 42) and (on-the-chairlift = 0) and (aquila = 1) and (roda-de-vael = 0) and (paolina = 1) and (ciampedie = 0)] [
    if (time-stop = 0) or (time-stop > (600 - aquila-stop - 4 * sum [group-size] of visitors with [(pxcor = 112) and (pycor = -243)])) [
      ifelse (pxcor = 129) and (pycor = -219)
       []
       [face min-one-of neighbors [dist_rodadevael]
         fd speed]
    ]
  ]

  ask visitors with [(excursion = 42) and (on-the-chairlift = 0) and (aquila = 1) and (roda-de-vael = 1) and (paolina = 1) and (ciampedie = 0)] [
    if (time-stop = 0) or (time-stop > (4860 - random 3240 + random 3240) * time-factor) [
      ifelse (pxcor = 214) and (pycor = -166)
       []
       [face min-one-of neighbors [dist_ciampedie]
         fd speed]
    ]
  ]

  ask visitors with [(excursion = 42) and (on-the-chairlift = 0) and (aquila = 1) and (roda-de-vael = 1) and (paolina = 1) and (ciampedie = 1)] [
    if time-stop > (720 - random 660 + random 660) * time-factor [
      move-to patch 216 -167
    ]
  ]



  ask visitors with [roda-de-vael = 0] [
    if (pxcor = 129) and (pycor = -219) [
      set roda-de-vael 1
    ]
  ]

  ask visitors with [vaiolon = 0] [
    if (pxcor = 98) and (pycor = -188) [
      set vaiolon 1
    ]
  ]

  ask visitors with [paolina = 0] [
    if (pxcor = 90) and (pycor = -237) [
      set paolina 1
    ]
  ]

  ask visitors with [aquila = 0] [
    if (pxcor = 112) and (pycor = -243) [
      set aquila 1
    ]
  ]

  ask visitors with [fronza = 0] [
    if (pxcor = 80) and (pycor = -138) [
      set fronza 1
    ]
  ]

  ask visitors with [coronelle = 0] [
    if (pxcor = 98) and (pycor = -146) [
      set coronelle 1
    ]
  ]

  ask visitors with [zigolade = 0] [
    if (pxcor = 129) and (pycor = -166) [
      set zigolade 1
    ]
  ]

  ask visitors with [vajolet = 0] [
    if (pxcor = 131) and (pycor = -76) [
      set vajolet 1
    ]
  ]

  ask visitors with [principe = 0] [
    if (pxcor = 145) and (pycor = -18) [
      set principe 1
    ]
  ]
  ask visitors with [re-alberto = 0] [
    if (pxcor = 105) and (pycor = -75) [
      set re-alberto 1
    ]
  ]

  ask visitors with [gardeccia = 0] [
    if (pxcor = 152) and (pycor = -118) [
      set gardeccia 1
    ]
  ]

  ask visitors with [ciampedie = 0] [
    if (pxcor = 214) and (pycor = -166) [
      set ciampedie 1
    ]
  ]

  ask visitors with [(excursion > 10) and (excursion < 20)] [
    if (roda-de-vael = 1) or (paolina = 1) [
      set on-the-way-to 0
    ]
  ]

  ask visitors with [(excursion > 20) and (excursion < 30)] [
    if (roda-de-vael = 1) or (gardeccia = 1) [
      set on-the-way-to 0
    ]
  ]

  ask visitors with [(excursion > 30) and (excursion < 40)] [
    if (aquila = 1) or (fronza = 1) [
      set on-the-way-to 0
    ]
  ]

  ask visitors with [excursion > 40] [
    if roda-de-vael = 1 [
      set on-the-way-to 0
    ]
  ]


  ask visitors with [(excursion > 20) and (excursion < 30) and (on-the-way-to = 0)] [
    if (pxcor = 214) and (pycor = -166) [
      set ciampedie 2
    ]
  ]

  ask visitors with [(excursion > 30) and (excursion < 40) and (on-the-way-to = 0)] [
    if (pxcor = 90) and (pycor = -237) [
      set paolina 2
    ]
  ]

  ask visitors with [(excursion = 12) and (coronelle = 1)] [
      if (pxcor = 90) and (pycor = -237) [
        set paolina 2
      ]
  ]

  ask visitors with [(excursion = 16) and (fronza = 1)] [
      if (pxcor = 129) and (pycor = -219) [
        set roda-de-vael 2
      ]
      if (pxcor = 112) and (pycor = -243) [
        set aquila 2
      ]
  ]

  ask visitors with [(excursion = 17) and (zigolade = 1)] [
      if (pxcor = 129) and (pycor = -219) [
        set roda-de-vael 2
      ]
  ]

  ask visitors with [(excursion = 19) and (aquila = 1)] [
      if (pxcor = 90) and (pycor = -237) [
        set paolina 2
      ]
  ]

  ask visitors with [(excursion = 21) and (vajolet = 1)] [
      if (pxcor = 152) and (pycor = -118) [
        set gardeccia 2
      ]
  ]

  ask visitors with [(excursion = 23) and (principe = 1)] [
      if (pxcor = 131) and (pycor = -76) [
        set vajolet 2
      ]
      if (pxcor = 152) and (pycor = -118) [
        set gardeccia 2
      ]
  ]

  ask visitors with [(excursion = 24) and (re-alberto = 1)] [
      if (pxcor = 131) and (pycor = -76) [
        set vajolet 2
      ]
      if (pxcor = 152) and (pycor = -118) [
        set gardeccia 2
      ]
  ]

  ask visitors with [(excursion = 34) and (roda-de-vael = 1)] [
      if (pxcor = 112) and (pycor = -243) [
        set aquila 2
      ]
  ]

  ask visitors with [(excursion = 35) and (zigolade = 1)] [
      if (pxcor = 129) and (pycor = -219) [
        set roda-de-vael 2
      ]
      if (pxcor = 112) and (pycor = -243) [
        set aquila 2
      ]
  ]

end


  to do-plots

    set paot-roda sum [group-size] of visitors with [(pxcor = 129) and (pycor = -219)]
    set paot-aquila sum [group-size] of visitors with [(pxcor = 112) and (pycor = -243)]
    set paot-vaiolon sum [group-size] of visitors with [(pxcor = 98) and (pycor = -188)]

    set-current-plot "PAOT"
    set-current-plot-pen "Roda de Vael"
    plot paot-roda
    set-current-plot-pen "Aquila"
    plot paot-aquila
    set-current-plot-pen "Vaiolon"
    plot paot-vaiolon

    set-current-plot "Traffic"
    set-current-plot-pen "Eastbound"
    plot count visitors with [(transport-mode = 1) and (origin = 1) and (on-the-way-to = 0) and (on-the-car = 1) and (pxcor >= 89) and (pxcor <= 228)]
      + count visitors with [(transport-mode = 6) and (origin = 2) and (on-the-way-to = 1) and (on-the-car = 1) and (pxcor >= 89) and (pxcor <= 228)]
      + count visitors with [(transport-mode = 6) and (origin = 1) and (on-the-way-to = 0) and (on-the-car = 1) and (pxcor >= 89) and (pxcor <= 228)]
      + count visitors with [(transport-mode = 1) and (origin = 2) and (on-the-way-to = 1) and (on-the-car = 1) and (pxcor >= 38) and (pxcor <= 87)]
      + count visitors with [(transport-mode = 6) and (origin = 2) and (on-the-way-to = 1) and (on-the-car = 1) and (pxcor >= 38) and (pxcor <= 87)]
      + count visitors with [(transport-mode = 6) and (origin = 1) and (on-the-way-to = 0) and (on-the-car = 1) and (pxcor >= 38) and (pxcor <= 87)]
      + count background-eastbound-cars with [(pxcor >= 38) and (pxcor <= 228)]
    set-current-plot-pen "Westbound"
    plot count visitors with [(transport-mode = 1) and (origin = 1) and (on-the-way-to = 1) and (on-the-car = 1) and (pxcor >= 89) and (pxcor <= 228)]
      + count visitors with [(transport-mode = 6) and (origin = 2) and (on-the-way-to = 0) and (on-the-car = 1) and (pxcor >= 89) and (pxcor <= 228)]
      + count visitors with [(transport-mode = 6) and (origin = 1) and (on-the-way-to = 1) and (on-the-car = 1) and (pxcor >= 89) and (pxcor <= 228)]
      + count visitors with [(transport-mode = 1) and (origin = 2) and (on-the-way-to = 0) and (on-the-car = 1) and (pxcor >= 38) and (pxcor <= 87)]
      + count visitors with [(transport-mode = 6) and (origin = 2) and (on-the-way-to = 0) and (on-the-car = 1) and (pxcor >= 38) and (pxcor <= 87)]
      + count visitors with [(transport-mode = 6) and (origin = 1) and (on-the-way-to = 1) and (on-the-car = 1) and (pxcor >= 38) and (pxcor <= 87)]
      + count background-westbound-cars with [(pxcor >= 38) and (pxcor <= 228)]
    set-current-plot-pen "Total"
    plot count visitors with [((on-the-car = 1) and (pxcor >= 38) and (pxcor <= 87)) or ((on-the-car = 1) and (pxcor >= 89) and (pxcor <= 228))]
    + count background-eastbound-cars with [(pxcor >= 38) and (pxcor <= 228)]
    + count background-westbound-cars with [(pxcor >= 38) and (pxcor <= 228)]

;    set-current-plot "Crowding"
;    set-current-plot-pen "548"
;    plot sum [group-size] of visitors with [(pxcor >= 106) and (pycor <= 115) and (pycor > -268) and (pycor < -255)]
;    set-current-plot-pen "549"
;    plot sum [group-size] of visitors with [(pxcor >= 115) and (pycor <= 124) and (pycor > -245) and (pycor < -235)]
;    set-current-plot-pen "541"
;    plot sum [group-size] of visitors with [(pxcor >= 115) and (pycor <= 121) and (pycor > -207) and (pycor < -197)]


;    set-current-plot "Crowding"
;    ;the number of total visitors is divided by 20 to make the related plot compatible with those of crowding
;    set-current-plot-pen "Tot segment 1"
;    plot sum ([group-size] of visitors with [((excursion = 11) or (excursion = 13) or (excursion = 14) or (excursion = 15) or (excursion = 17) or (excursion = 19) or
;          (excursion = 25) or (excursion = 26) or (excursion = 31) or (excursion = 34) or (excursion = 35))
;      and (segment = 1) and (on-the-car = 0) and (on-the-bus = 0) and (on-the-cablecar = 0) and (on-the-chairlift = 0) and (arrived = 0)]) / 10
;    set-current-plot-pen "Tot segment 2"
;    plot sum ([group-size] of visitors with [((excursion = 11) or (excursion = 13) or (excursion = 14) or (excursion = 15) or (excursion = 17) or (excursion = 19) or
;          (excursion = 25) or (excursion = 26) or (excursion = 31) or (excursion = 34) or (excursion = 35))
;      and (segment = 2) and (on-the-car = 0) and (on-the-bus = 0) and (on-the-cablecar = 0) and (on-the-chairlift = 0) and (arrived = 0)]) / 10
;    set-current-plot-pen "Segment 1"
;    ifelse any? visitors with [((excursion = 11) or (excursion = 13) or (excursion = 14) or (excursion = 15) or (excursion = 17) or (excursion = 19) or
;          (excursion = 25) or (excursion = 26) or (excursion = 31) or (excursion = 34) or (excursion = 35))
;      and (segment = 1) and (on-the-car = 0) and (on-the-bus = 0) and (on-the-cablecar = 0) and (on-the-chairlift = 0) and (arrived = 0)]
;    [plot ((sum [group-size] of visitors with [((excursion = 11) or (excursion = 13) or (excursion = 14) or (excursion = 15) or (excursion = 17) or (excursion = 19) or
;          (excursion = 25) or (excursion = 26) or (excursion = 31) or (excursion = 34) or (excursion = 35))
;      and (segment = 1) and (on-the-car = 0) and (on-the-bus = 0) and (on-the-cablecar = 0) and (on-the-chairlift = 0) and (arrived = 0)
;      and (sum [group-size] of visitors with [(excursion != 0) and (on-the-car = 0) and (on-the-bus = 0) and (on-the-cablecar = 0) and (on-the-chairlift = 0)
;        and (arrived = 0)] in-radius 2 - [group-size] of self < 8)] ) / (sum [group-size] of visitors with [((excursion = 11) or (excursion = 13) or (excursion = 14) or (excursion = 15) or (excursion = 17) or (excursion = 19) or
;          (excursion = 25) or (excursion = 26) or (excursion = 31) or (excursion = 34) or (excursion = 35))
;      and (segment = 1) and (on-the-car = 0) and (on-the-bus = 0) and (on-the-cablecar = 0) and (on-the-chairlift = 0) and (arrived = 0)])) * 100]
;    [plot 0]
;    set-current-plot-pen "Segment 2"
;    ifelse any? visitors with [((excursion = 11) or (excursion = 13) or (excursion = 14) or (excursion = 15) or (excursion = 17) or (excursion = 19) or
;          (excursion = 25) or (excursion = 26) or (excursion = 31) or (excursion = 34) or (excursion = 35))
;      and (segment = 2) and (on-the-car = 0) and (on-the-bus = 0) and (on-the-cablecar = 0) and (on-the-chairlift = 0) and (arrived = 0)]
;    [plot ((sum [group-size] of visitors with [((excursion = 11) or (excursion = 13) or (excursion = 14) or (excursion = 15) or (excursion = 17) or (excursion = 19) or
;          (excursion = 25) or (excursion = 26) or (excursion = 31) or (excursion = 34) or (excursion = 35))
;      and (segment = 2) and (on-the-car = 0) and (on-the-bus = 0) and (on-the-cablecar = 0) and (on-the-chairlift = 0) and (arrived = 0)
;      and (sum [group-size] of visitors with [(excursion != 0) and (on-the-car = 0) and (on-the-bus = 0) and (on-the-cablecar = 0) and (on-the-chairlift = 0)
;        and (arrived = 0)] in-radius 2 - [group-size] of self < 16)] ) / (sum [group-size] of visitors with [((excursion = 11) or (excursion = 13) or (excursion = 14) or (excursion = 15) or (excursion = 17) or (excursion = 19) or
;          (excursion = 25) or (excursion = 26) or (excursion = 31) or (excursion = 34) or (excursion = 35))
;      and (segment = 2) and (on-the-car = 0) and (on-the-bus = 0) and (on-the-cablecar = 0) and (on-the-chairlift = 0) and (arrived = 0)])) * 100]
;    [plot 0]


    set-current-plot "Modal split"
    set-current-plot-pen "Total visitors"
    ifelse any? visitors
    [plot (sum [group-size] of visitors with [transport-mode > 0]) / 20]
    [plot 0]
    set-current-plot-pen "1"
    ifelse any? visitors with [transport-mode > 0]
      [plot (sum [group-size] of visitors with [transport-mode = 1] / sum [group-size] of visitors with [transport-mode > 0]) * 100]
      [plot 0]
    set-current-plot-pen "2"
    ifelse any? visitors with [transport-mode > 0]
      [plot (sum [group-size] of visitors with [transport-mode = 2] / sum [group-size] of visitors with [transport-mode > 0]) * 100]
      [plot 0]
    set-current-plot-pen "3"
    ifelse any? visitors with [transport-mode > 0]
      [plot (sum [group-size] of visitors with [transport-mode = 3] / sum [group-size] of visitors with [transport-mode > 0]) * 100]
      [plot 0]
    set-current-plot-pen "4"
    ifelse any? visitors with [transport-mode > 0]
      [plot (sum [group-size] of visitors with [transport-mode = 4] / sum [group-size] of visitors with [transport-mode > 0]) * 100]
      [plot 0]
    set-current-plot-pen "5"
    ifelse any? visitors with [transport-mode > 0]
      [plot (sum [group-size] of visitors with [transport-mode = 5] / sum [group-size] of visitors with [transport-mode > 0]) * 100]
      [plot 0]
    set-current-plot-pen "6"
    ifelse any? visitors with [transport-mode > 0]
      [plot (sum [group-size] of visitors with [transport-mode = 6] / sum [group-size] of visitors with [transport-mode > 0]) * 100]
      [plot 0]
    set-current-plot-pen "7"
    ifelse any? visitors with [transport-mode > 0]
      [plot (sum [group-size] of visitors with [transport-mode = 7] / sum [group-size] of visitors with [transport-mode > 0]) * 100]
      [plot 0]


  end

to compute-outputs

    ;max-paot parameters are computed

    ifelse paot-roda > max-paot-roda
    [set max-paot-roda paot-roda]
    []

    ifelse paot-aquila > max-paot-aquila
    [set max-paot-aquila paot-aquila]
    []

    ifelse paot-vaiolon > max-paot-vaiolon
    [set max-paot-vaiolon paot-vaiolon]
    []

    ;avg-paot parameters are computed as the average PAOT between 10am and 4pm

    if (ticks >= 18000) and (ticks <= 39600) [
      set tot-paot-roda tot-paot-roda + paot-roda
      set tot-paot-aquila tot-paot-aquila + paot-aquila
      set tot-paot-vaiolon tot-paot-vaiolon + paot-vaiolon
    ]

    set avg-paot-roda tot-paot-roda / 21601
    set avg-paot-aquila tot-paot-aquila / 21601
    set avg-paot-vaiolon tot-paot-vaiolon / 21601

    if ticks > 46000 [
    set tot-visitors sum [group-size] of visitors
    set mode1 (sum [group-size] of visitors with [transport-mode = 1] / sum [group-size] of visitors with [transport-mode > 0]) * 100
    set mode2 (sum [group-size] of visitors with [transport-mode = 2] / sum [group-size] of visitors with [transport-mode > 0]) * 100
    set mode3 (sum [group-size] of visitors with [transport-mode = 3] / sum [group-size] of visitors with [transport-mode > 0]) * 100
    set mode5 (sum [group-size] of visitors with [transport-mode = 5] / sum [group-size] of visitors with [transport-mode > 0]) * 100
    set mode6 (sum [group-size] of visitors with [transport-mode = 6] / sum [group-size] of visitors with [transport-mode > 0]) * 100
    set mode7 (sum [group-size] of visitors with [transport-mode = 7] / sum [group-size] of visitors with [transport-mode > 0]) * 100
    set car-pct (sum [group-size] of visitors with [(transport-mode = 1) or (transport-mode = 6)] / sum [group-size] of visitors with [transport-mode > 0]) * 100
    set bus-pct (sum [group-size] of visitors with [(transport-mode = 2) or (transport-mode = 5) or (transport-mode = 7)] / sum [group-size] of visitors with [transport-mode > 0]) * 100
    set none-pct (sum [group-size] of visitors with [transport-mode = 4] / sum [group-size] of visitors with [transport-mode != 0]) * 100
    set road-pct (sum [group-size] of visitors with [(transport-mode = 1) or (transport-mode = 2)] / sum [group-size] of visitors with [transport-mode > 0]) * 100
    set lift-pct (sum [group-size] of visitors with [(transport-mode = 3) or (transport-mode = 5) or (transport-mode = 6) or (transport-mode = 7)] / sum [group-size] of visitors with [transport-mode > 0]) * 100
    ]

    set people-over-the-day [potd] of patch 129 -219

   ;avg-traffic parameters are computed as the average traffic between 8am and 6pm

    set traffic-eastbound count visitors with [(transport-mode = 1) and (origin = 1) and (on-the-way-to = 0) and (on-the-car = 1) and (pxcor >= 89) and (pxcor <= 228)]
      + count visitors with [(transport-mode = 6) and (origin = 2) and (on-the-way-to = 1) and (on-the-car = 1) and (pxcor >= 89) and (pxcor <= 228)]
      + count visitors with [(transport-mode = 6) and (origin = 1) and (on-the-way-to = 0) and (on-the-car = 1) and (pxcor >= 89) and (pxcor <= 228)]
      + count visitors with [(transport-mode = 1) and (origin = 2) and (on-the-way-to = 1) and (on-the-car = 1) and (pxcor >= 38) and (pxcor <= 87)]
      + count visitors with [(transport-mode = 6) and (origin = 2) and (on-the-way-to = 1) and (on-the-car = 1) and (pxcor >= 38) and (pxcor <= 87)]
      + count visitors with [(transport-mode = 6) and (origin = 1) and (on-the-way-to = 0) and (on-the-car = 1) and (pxcor >= 38) and (pxcor <= 87)]
      + count background-eastbound-cars with [(pxcor >= 38) and (pxcor <= 228)]

    set traffic-westbound count visitors with [(transport-mode = 1) and (origin = 1) and (on-the-way-to = 1) and (on-the-car = 1) and (pxcor >= 89) and (pxcor <= 228)]
      + count visitors with [(transport-mode = 6) and (origin = 2) and (on-the-way-to = 0) and (on-the-car = 1) and (pxcor >= 89) and (pxcor <= 228)]
      + count visitors with [(transport-mode = 6) and (origin = 1) and (on-the-way-to = 1) and (on-the-car = 1) and (pxcor >= 89) and (pxcor <= 228)]
      + count visitors with [(transport-mode = 1) and (origin = 2) and (on-the-way-to = 0) and (on-the-car = 1) and (pxcor >= 38) and (pxcor <= 87)]
      + count visitors with [(transport-mode = 6) and (origin = 2) and (on-the-way-to = 0) and (on-the-car = 1) and (pxcor >= 38) and (pxcor <= 87)]
      + count visitors with [(transport-mode = 6) and (origin = 1) and (on-the-way-to = 1) and (on-the-car = 1) and (pxcor >= 38) and (pxcor <= 87)]
      + count background-westbound-cars with [(pxcor >= 38) and (pxcor <= 228)]

    set traffic count visitors with [((on-the-car = 1) and (pxcor >= 38) and (pxcor <= 87)) or ((on-the-car = 1) and (pxcor >= 89) and (pxcor <= 228))]
    + count background-eastbound-cars with [(pxcor >= 38) and (pxcor <= 228)]
    + count background-westbound-cars with [(pxcor >= 38) and (pxcor <= 228)]

    if (ticks >= 10800) and (ticks <= 46800) [
      set tot-traffic-eastbound tot-traffic-eastbound + traffic-eastbound
      set tot-traffic-westbound tot-traffic-westbound + traffic-westbound
      set tot-traffic tot-traffic + traffic
    ]

    set avg-traffic-eastbound tot-traffic-eastbound / 36001
    set avg-traffic-westbound tot-traffic-westbound / 36001
    set avg-traffic tot-traffic / 36001

    ;the number of vehicles passing on the road is computed

    ask visitors with [(origin = 1) and (on-the-car = 1)] [
      if (pxcor = 92) and (pycor = -278) [
        set passage 1
      ]
    ]

    ask visitors with [(origin = 2) and (on-the-car = 1)] [
      if (pxcor = 82) and (pycor = -280) [
        set passage 1
      ]
    ]

    ask background-eastbound-cars [
      if (pxcor = 92) and (pycor = -278) [
        set passage 1
      ]
    ]

    ask background-westbound-cars [
      if (pxcor = 92) and (pycor = -278) [
        set passage 1
      ]
    ]

    ask visitors with [passage = 1] [
      set cumulative-passage cumulative-passage + 1
    ]

    ask background-eastbound-cars with [passage = 1] [
      set cumulative-passage cumulative-passage + 1
    ]

    ask background-westbound-cars with [passage = 1] [
      set cumulative-passage cumulative-passage + 1
    ]

    ask visitors with [cumulative-passage = 1] [
      set visitor-passage visitor-passage + 1
      set tot-passage tot-passage + 1
    ]

    ask background-eastbound-cars with [cumulative-passage = 1] [
      set tot-passage tot-passage + 1
    ]

    ask background-westbound-cars with [cumulative-passage = 1] [
      set tot-passage tot-passage + 1
    ]


    ;low-paot parameters indicate the amount of time over which PAOT at a location is below a given threshold

    if paot-roda < 400 [
      set low-paot-roda low-paot-roda + 1
    ]

    if paot-aquila < 70 [
      set low-paot-aquila low-paot-aquila + 1
    ]

    if paot-vaiolon < 15 [
      set low-paot-vaiolon low-paot-vaiolon + 1
    ]

    ;crowding parameters are computed as the proportion of time during which the crowding perceived by a visitor is below a given threshold

    ask visitors with [((excursion = 11) or (excursion = 13) or (excursion = 14) or (excursion = 15) or (excursion = 17) or (excursion = 19) or (excursion = 25) or (excursion = 26)
        or (excursion = 31) or (excursion = 34) or (excursion = 35))
      and (segment = 1) and (on-the-car = 0) and (on-the-bus = 0) and (on-the-cablecar = 0) and (on-the-chairlift = 0) and (arrived = 0)] [
      if sum [group-size] of visitors with [(excursion != 0) and (on-the-car = 0) and (on-the-bus = 0) and (on-the-cablecar = 0) and (on-the-chairlift = 0) and (arrived = 0)] in-radius 2 - [group-size] of self < 8 [
        set crowding crowding + 1
      ]
      set crowding-time crowding-time + 1
      set crowding-ratio (crowding / crowding-time) * 100
    ]

    ask visitors with [((excursion = 11) or (excursion = 13) or (excursion = 14) or (excursion = 15) or (excursion = 17) or (excursion = 19) or (excursion = 25) or (excursion = 26)
        or (excursion = 31) or (excursion = 34) or (excursion = 35))
      and (segment = 2) and (on-the-car = 0) and (on-the-bus = 0) and (on-the-cablecar = 0) and (on-the-chairlift = 0) and (arrived = 0)] [
      if sum [group-size] of visitors with [(excursion != 0) and (on-the-car = 0) and (on-the-bus = 0) and (on-the-cablecar = 0) and (on-the-chairlift = 0) and (arrived = 0)] in-radius 2 - [group-size] of self < 16 [
        set crowding crowding + 1
      ]
      set crowding-time crowding-time + 1
      set crowding-ratio (crowding / crowding-time) * 100
    ]


    if any? visitors with [((excursion = 11) or (excursion = 13) or (excursion = 14) or (excursion = 15) or (excursion = 17) or (excursion = 19) or (excursion = 25) or (excursion = 26)
        or (excursion = 31) or (excursion = 34) or (excursion = 35)) and (segment = 1)] [
      set crowding-m1 sum [crowding-ratio] of visitors with [((excursion = 11) or (excursion = 13) or (excursion = 14) or (excursion = 15) or (excursion = 17) or (excursion = 19) or (excursion = 25) or (excursion = 26)
        or (excursion = 31) or (excursion = 34) or (excursion = 35)) and (segment = 1)] / count visitors with [((excursion = 11) or (excursion = 13) or (excursion = 14) or (excursion = 15) or (excursion = 17) or (excursion = 19) or (excursion = 25) or (excursion = 26)
        or (excursion = 31) or (excursion = 34) or (excursion = 35)) and (segment = 1)]
    ]

    if any? visitors with [((excursion = 11) or (excursion = 13) or (excursion = 14) or (excursion = 15) or (excursion = 17) or (excursion = 19) or (excursion = 25) or (excursion = 26)
        or (excursion = 31) or (excursion = 34) or (excursion = 35)) and (segment = 2)] [
      set crowding-m2 sum [crowding-ratio] of visitors with [((excursion = 11) or (excursion = 13) or (excursion = 14) or (excursion = 15) or (excursion = 17) or (excursion = 19) or (excursion = 25) or (excursion = 26)
        or (excursion = 31) or (excursion = 34) or (excursion = 35)) and (segment = 2)] / count visitors with [((excursion = 11) or (excursion = 13) or (excursion = 14) or (excursion = 15) or (excursion = 17) or (excursion = 19) or (excursion = 25) or (excursion = 26)
        or (excursion = 31) or (excursion = 34) or (excursion = 35)) and (segment = 2)]
    ]
;
;    if any? visitors with [excursion = 34] [
;      set crowding-34 sum [crowding-ratio] of visitors with [excursion = 34] / count visitors with [excursion = 34]
;    ]


    ;total earnings are given by the number of vehicles times the toll plus the number of people riding the bus times the bus ticket plus the number of people riding
    ;cableways times the ticket of cableways

    set tot-earnings (count visitors with [(transport-mode = 1) or (transport-mode = 6)]) * toll-per-vehicle
    + (sum [group-size] of visitors with [(transport-mode = 2) or (transport-mode = 5) or (transport-mode = 7)]) * bus-ticket
    + (sum [group-size] of visitors with [(transport-mode = 3) or (transport-mode = 5) or (transport-mode = 6) or (transport-mode = 7)]) * lift-ticket

    set toll-earnings (count visitors with [(transport-mode = 1) or (transport-mode = 6)]) * toll-per-vehicle

    set bus-earnings (sum [group-size] of visitors with [(transport-mode = 2) or (transport-mode = 5) or (transport-mode = 7)]) * bus-ticket

    set lift-earnings (sum [group-size] of visitors with [(transport-mode = 3) or (transport-mode = 5) or (transport-mode = 6) or (transport-mode = 7)]) * lift-ticket

  end

to calibrate
  ask visitors with [on-the-way-to = 0] [
    ifelse (pxcor = 87) and (pycor = -266)
    [set calibration 1]
    [set calibration 0]
  ]

  ask visitors [
    if calibration = 1 [
      set calibration-time calibration-time + 1
    ]
  ]


  ask visitors with [(pxcor = 87) and (pycor = -266) and (calibration-time = 1)] [
      ask patch 87 -266 [
        set potd potd + [group-size] of myself
    ]
  ]

  ask visitors with [(on-the-chairlift = 1) and (on-the-way-to = 0)] [
    set chairlift-calibration chairlift-calibration + 1
  ]

  ask visitors with [chairlift-calibration = 1] [
    ask patch 0 0 [
      set potd potd + [group-size] of myself
    ]
  ]
  if ticks = 28800 [
    type "13" type " " type [potd] of patch 87 -266 type " " print [potd] of patch 0 0
  ]
  if ticks = 32400 [
    type "14" type " " type [potd] of patch 87 -266 type " " print [potd] of patch 0 0
  ]
  if ticks = 36000 [
    type "15" type " " type [potd] of patch 87 -266 type " " print [potd] of patch 0 0
  ]
  if ticks = 39600 [
    type "16" type " " type [potd] of patch 87 -266 type " " print [potd] of patch 0 0
  ]
  if ticks = 43200 [
    type "17" type " " type [potd] of patch 87 -266 type " " print [potd] of patch 0 0
  ]
  if ticks = 46800 [
    type "18" type " " type [potd] of patch 87 -266 type " " print [potd] of patch 0 0
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
233
41
783
638
-1
-1
2.0
1
10
1
1
1
0
1
1
1
0
270
-293
0
0
0
1
ticks
30.0

BUTTON
19
45
82
78
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
97
45
160
78
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
20
416
192
449
bus-frequency
bus-frequency
20
120
90.0
1
1
NIL
HORIZONTAL

SLIDER
20
372
192
405
lift-ticket
lift-ticket
5
25
8.0
1
1
NIL
HORIZONTAL

SLIDER
20
284
192
317
toll-per-vehicle
toll-per-vehicle
0
30
0.0
1
1
NIL
HORIZONTAL

SLIDER
20
329
192
362
bus-ticket
bus-ticket
0
6
3.0
0.5
1
NIL
HORIZONTAL

CHOOSER
20
461
221
506
car-access
car-access
"free" "before 10am and after 4pm" "before 8am and after 6pm"
0

CHOOSER
20
517
158
562
bus-schedule
bus-schedule
"6am-8pm" "8am-6pm" "10am-4pm"
0

CHOOSER
21
578
159
623
lift-schedule
lift-schedule
"6am-8pm" "8am-6pm" "10am-4pm"
0

SLIDER
20
641
192
674
liftstop
liftstop
0
15
2.0
1
1
NIL
HORIZONTAL

SLIDER
20
133
192
166
visitor-flow
visitor-flow
100
5000
5000.0
100
1
NIL
HORIZONTAL

SLIDER
22
180
194
213
visitors-in-vigo
visitors-in-vigo
0
100
50.0
1
1
NIL
HORIZONTAL

SLIDER
22
235
194
268
road-access
road-access
0
100
10.0
1
1
NIL
HORIZONTAL

MONITOR
804
42
939
95
visitors on car (%)
(sum [group-size] of visitors with [transport-mode = 1] / sum [group-size] of visitors with [transport-mode > 0]) * 100
17
1
13

MONITOR
964
42
1102
95
visitors on bus (%)
(sum [group-size] of visitors with [transport-mode = 2] / sum [group-size] of visitors with [transport-mode != 0]) * 100
17
1
13

MONITOR
806
104
937
157
visitors on lift (%)
(sum [group-size] of visitors with [transport-mode = 3] / sum [group-size] of visitors with [transport-mode != 0]) * 100
17
1
13

MONITOR
964
104
1112
157
visitors at home (%)
(sum [group-size] of visitors with [transport-mode = 4] / sum [group-size] of visitors with [transport-mode != 0]) * 100
17
1
13

MONITOR
805
248
947
301
POTD Roda de Vael
[potd] of patch 129 -219
17
1
13

PLOT
796
327
996
477
PAOT
Time
N. of visitors
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"Roda de Vael" 1.0 0 -13840069 true "" ""
"Aquila" 1.0 0 -13345367 true "" ""
"Vaiolon" 1.0 0 -2674135 true "" ""

MONITOR
806
167
954
220
visitors crossing (%)
(sum [group-size] of visitors with [transport-mode = 5] / sum [group-size] of visitors with [transport-mode > 0]) * 100
17
1
13

MONITOR
967
167
1065
220
car + lift (%)
(sum [group-size] of visitors with [transport-mode = 6] / sum [group-size] of visitors with [transport-mode > 0]) * 100
17
1
13

MONITOR
1077
167
1178
220
bus + lift (%)
(sum [group-size] of visitors with [transport-mode = 7] / sum [group-size] of visitors with [transport-mode > 0]) * 100
17
1
13

PLOT
797
489
997
639
Traffic
Time
N. of vehicles
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"Eastbound" 1.0 0 -5825686 true "" ""
"Westbound" 1.0 0 -14070903 true "" ""
"Total" 1.0 0 -13840069 true "" ""

PLOT
999
328
1199
478
Crowding
Time
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"Tot segment 1" 1.0 0 -14454117 true "" ""
"Segment 1" 1.0 0 -13840069 true "" ""
"Segment 2" 1.0 0 -2674135 true "" ""
"Tot segment 2" 1.0 0 -955883 true "" ""

MONITOR
956
248
1079
301
POTD calibration
[POTD] of patch 87 -266
17
1
13

MONITOR
1087
249
1196
302
Chairlift calibr.
[potd] of patch 0 0
17
1
13

PLOT
999
490
1199
640
Modal split
Time
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"1" 1.0 0 -2674135 true "" ""
"2" 1.0 0 -14439633 true "" ""
"3" 1.0 0 -13345367 true "" ""
"4" 1.0 0 -9276814 true "" ""
"5" 1.0 0 -6459832 true "" ""
"6" 1.0 0 -955883 true "" ""
"7" 1.0 0 -8330359 true "" ""
"Total visitors" 1.0 0 -16777216 true "" ""

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
NetLogo 6.0.1
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

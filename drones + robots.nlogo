turtles-own [direction]
breed [drones drone]
breed [people person]
breed[robots bot]
breed[robots2 bot2]

robots-own[path start_loc goal_loc available? flag]
drones-own [counter random_move_duration per-in-sight detected-patch? cur_heading direction]
people-own [targeted?]
patches-own[father G_cost visited? active? scanned?]

globals [detected-people burnablePatchCount percentageBurned mainlist Final-Cost p-valids found?  people-locations total-dead countSuccessfullyRescued]

to setup
  clear-all
  import-pcolors "floorPlan_8.png"
  ;set_plan
  creat_turtls
  frame
  set total-dead 0
  set people-locations []

  ask patches
  [
    set father nobody
    set G_cost 0
    set visited? false
    set active? false
    set scanned? false
  ]

  ask robots
  [
    set path nobody

    set start_loc (patch 6 74)
    set available? true
  ]

  set p-valids patches with [pcolor != 13 and pcolor != 14 and pcolor != 15 and pcolor != black]

  fire-at-start
  set burnablePatchCount count patches with [ pxcor > 10 and pxcor < 140  and pycor > 10 and pycor < 140 ]


  reset-ticks
end

to frame
  ask patches with [pxcor = 0 or pxcor = 1 or pxcor = 2  ]
  [
    set pcolor 123]
  ask patches with [pycor = 0 or pycor = 1 or pycor = 2  ]
  [
    set pcolor 123]
   ask patches with [pxcor = 150 or pxcor = 149 or pxcor = 148  ]
  [
    set pcolor 123 ]
  ask patches with [pycor = 150 or pycor = 149  or pycor = 148 ]
  [
    set pcolor 123]

end

;to set_plan
;  ask patches with [pcolor > 63 and pcolor < 68][
;    set pcolor lime
;  ]
;
;  ask patches with [pcolor > 43 and pcolor < 48][
;    set pcolor yellow
;  ]
;
;  ask patches with [pcolor mod 10 < 4.5 and pcolor != green and pcolor != yellow and pcolor != lime][
;    set pcolor black
;  ]
;
;  ask patches with [pcolor mod 10 >= 4.5 and pcolor != green and pcolor != yellow and pcolor != lime][
;    set pcolor white
;  ]
;end

to creat_turtls
  let agent_size 5
  let num_people 20

  ask n-of 1 patches with [pcolor = white] [
    sprout-drones number-of-drones [ ; sprout number Creates number new turtles on the current patch
      setxy 17 75
      set shape "airplane"
      set size agent_size     ;; bigger turtles are easier to see
      face one-of neighbors4  ;; face north, south, east, or west
      ifelse random 2 = 0
        [ set direction 1     ;; follow right hand wall
          set color red ]
        [ set direction -1    ;; follow left hand wall
          set color green ]
      ;ask neighbors4 with-min [pxcor] [if pcolor > 3 [show word "cool"""]]
      set per-in-sight nobody ; nobody: indicate that no agent was found
      set counter 0
      set random_move_duration 0
    ]
  ]

  ask n-of num_people patches with [pcolor = white and pxcor > 10 and pxcor < 140  and pycor > 10 and pycor < 140] [
    sprout-people 1 [ ; sprout number Creates number new turtles on the current patch
      set shape "person"
      set size agent_size
      face one-of neighbors4  ;; face north, south, east, or west
      set targeted? false
    ]
  ]

  ask patch 6 74 [
    sprout-robots 4 [ ; sprout number Creates number new turtles on the current patch
      set shape "bug"
      set size agent_size
      face one-of neighbors4  ;; face north, south, east, or west
    ]
  ]
end

to set_robots
  while [any? robots with [available?] and not empty? people-locations] [
      ask one-of robots with [ available?] [
        let x_tar item 0 item 0 people-locations
        let y_tar item 1 item 0 people-locations
        set people-locations remove-item 0 people-locations

        set goal_loc (patch x_tar y_tar)

;      while [[pcolor] of patch-here = red][
;        face min-one-of patches with [pcolor != red ] [ distance myself ]
;        forward 1
;      ]

        set path A* start_loc goal_loc p-valids
        set available? false

        set flag false
      ]
  ]
end

to go

  if percentageBurned >= 1 or 20 - (countSuccessfullyRescued + total-dead) = 0 [stop]

  ask drones [
    if counter > 30 and random_move_duration <= 20[
      rt random 360               ; set random heading
      if ([pcolor] of patch-ahead deflect-radius mod 10 = 0) or ([pcolor] of patch-ahead deflect-radius = 123)
      [
       set heading heading - 180
      ]
      ;fd drone-speed                    ; advance one step
      set random_move_duration random_move_duration + 1
      if random_move_duration = 20
      [
        set counter 0
        set random_move_duration 0
        let temp random 3

        if temp = 0 [
          set heading 0
        ]
        if temp = 1 [
          set heading 90
        ]
        if temp = 2 [
          set heading 180
        ]
        if temp = 3 [
          set heading 270
        ]
      ]
    ]

    fly
  ]

  ;robots2-scan
  every 0.5 [print people-locations]

   if fireSpread [
    fire

    set percentageBurned count patches with [ pxcor > 10 and pxcor < 140  and pycor > 10 and pycor < 140 and (pcolor = 13 or pcolor = 14 or pcolor = 15)] / burnablePatchCount
  ]

  ask people [
    if [pcolor] of patch-here = 15 or [pcolor] of patch-here = 14 or [pcolor] of patch-here = 13[
      set total-dead total-dead + 1
      set people-locations remove patch-here people-locations
      die
    ]
  ]

  set p-valids patches with [pcolor != 13 and pcolor != 14 and pcolor != 15 and pcolor != black]

  if any? robots with [available?] and not empty? people-locations [
    set_robots
  ]

  ask robots with [not available?]  [
    pd
    if path != False [

      move-to first path
      set path remove-item 0 path

      if empty? path and not flag [
        ask people-on goal_loc [

          die]

        ;set path nobody
        set flag true
        set path A* goal_loc start_loc p-valids
        if path = false[
          die
          set path nobody
        ]
        ]

      if empty? path and flag [
        set countSuccessfullyRescued countSuccessfullyRescued + 1
        set available? true
        ]
      ]
    ]

  tick
end

to-report F_cost [Goal]
  report G_cost + H_cost Goal
end

to-report H_cost [Goal]
  report distance Goal ; euclidean distance to the goal
end

; A* algorithm. Inputs:

to-report A* [Start Goal valid-map]
  ; clear all the information in the agents
  ask valid-map with [visited?]
  [
    set father nobody
    set G_cost 0
    set visited? false
    set active? false
  ]

  ; Active the staring point to begin the searching loop
  ask Start
  [
    set father self
    set visited? true
    set active? true
  ]

  let exists? true

  while [not [visited?] of Goal and exists?]
  [
    ; We only work on the valid pacthes that are active
    let options valid-map with [active?]

    ; If any
    ifelse any? options
    [
      ; Take one of the active patches with minimal expected cost
      ask min-one-of options [F_cost Goal]
      [
        ; Store its real cost (to reach it) to compute the real cost
        ; of its children
        let Cost-path-father G_cost

        ; and deactivate it, because its children will be computed right now
        set active? false

        ; Compute its valid neighbors
        let valid-neighbors neighbors with [member? self valid-map]
        ask valid-neighbors
        [
          let t ifelse-value visited? [F_cost Goal] [2 ^ 20]

          if t > (Cost-path-father + distance myself + H_cost Goal)
          [
            ; The current patch becomes the father of its neighbor in the new path
            set father myself
            set visited? true
            set active? true

            ; and store the real cost in the neighbor from the real cost of its father
            set G_cost Cost-path-father + distance father
            set Final-Cost precision G_cost 3
          ]
        ]
      ]
    ]

    ; If there are no more options, there is no path between #Start and #Goal
    [
      set exists? false
    ]
  ]

  ; After the searching loop, if there exists a path
  ifelse exists?
  [
    let current Goal
    set Final-Cost (precision [G_cost] of Goal 3)
    let rep (list current)

    While [current != Start]
    [
      carefully[set current [father] of current
        set rep fput current rep]
      []
    ]
    report rep
  ]
  [
    ; Otherwise, there is no path, and we return False
    report false
  ]
end


to fire-at-start

  ask n-of fireCountBlack patches with [pcolor = black and pxcor > 10 and pxcor < 140  and pycor > 10 and pycor < 140][

    set pcolor red
  ]

   ask n-of fireCountWhite patches with [pcolor = white and pxcor > 10 and pxcor < 140  and pycor > 10 and pycor < 140][

    set pcolor red
  ]

end


to fire
  ask patches with [(pcolor = 14 or pcolor = 15) and  pxcor > 10 and pxcor < 140  and pycor > 10 and pycor < 140] [

    (ifelse(pcolor = 14)[


      if ((random 100) < 6 and not any? neighbors4 with [pcolor = white or pcolor = black])[set pcolor 13]

        ask neighbors4 with [pcolor = white or pcolor = black or pcolor = 64.9 or pcolor = 45.3 or pcolor = 4.5 or pcolor = 42.6][


          (ifelse (pcolor = white)

          [if  (random 100) < spreadSpeedWhite [set pcolor 15]]

          ;(pcolor = black)

          [if (random 100) < spreadSpeedBlack [set pcolor 15]])
      ]
    ]

    ;(pcolor = 15)
      [


        if (random 100) < 6 [ set pcolor 14]

        ask neighbors4 with [pcolor = white or pcolor = black or pcolor = 64.9 or pcolor = 45.3][


            (ifelse (pcolor = white )

            [if (random 100) < spreadSpeedWhite [set pcolor 15]]

            ;(pcolor = black)

            [if (random 100) < spreadSpeedBlack [set pcolor 15]])
       ]
    ]
   )
  ]

  set p-valids patches with [pcolor != 13 and pcolor != 14 and pcolor != 15 and pcolor != black]
end

to fly
;  ifelse not (pcolor mod 10 = 0)
;  [
;    fd drone-speed
;  ]
;  [
;    die
;    show word "problem"""
;  ]

  ifelse (pcolor mod 10 = 0) or (pcolor mod 10 = 13) or (pcolor mod 10 = 14) or
    (pcolor mod 10 = 15)
  [

    ;Reset their position
    setxy 17 75

  ]
  [
    ifelse [pcolor] of patch-ahead 1 mod 10 = 0 or [pcolor] of patch-ahead 1 = 123
      [
        bk 1
      ]
      [
        fd drone-speed
      ]
  ]

  detect

end

to detect
  let deg 0
  set cur_heading heading
  let turn-angle 0
  let wall-blocked False

  while [deg <= 360][
    ;show deg
    let dist 1
    rt deg
    set dist 1
    let last-patch patch-here
    ;; iterate through all the patches
    ;; starting at the patch directly ahead
    ;; going through MAXIMUM-VISIBILITY
    ;carefully[
    while [dist <= detect-radius] [
      let p nobody
      set p patch-ahead dist
      ;; if we are looking diagonally across
      ;; a patch it is possible we'll get the
      ;; same patch for distance x and x + 1
      ;; but we don't need to check again.
      if p != last-patch and dist <= detect-radius[
        ;; find the angle between the turtle's position
        ;; and the top of the patch.
        let col [pcolor] of p


        let neighbours [neighbors4] of p
        ;; if that angle is less than the angle toward the
        ;; last visible patch there is no direct line from the turtle
        ;; to the patch in question that is not obstructed by another
        ;; patch.
;        ifelse ((col mod 10 = 0) or col = 123)
;        [set dist detect-radius + 1]
;        [ask p [set pcolor blue]]

        ifelse ((col mod 10 = 0) or col = 123)
        [set dist detect-radius + 1]
        [
          ask p
          [
            if scanned? = False
            [
              ;set pcolor blue
              set scanned? True
            ]
          ]
        ]

        set detected-people turtles-on p

        if (any? detected-people)
        [
          ask detected-people with [(breed = people) and (targeted? = False)]
          [
            set targeted? True
            let coords list (xcor) (ycor)
            set people-locations (insert-item (length people-locations) people-locations coords)
          ]
        ]

        set last-patch p
      ]
      set dist dist + 1
    ]

    set deg deg + angle-shift
  ]
  set heading cur_heading

  ;;RANDOMNESS IN MOVEMENT SEGMENT
  let loop_check 0
  while [loop_check <= detect-radius]
  [
    let patch_ahead patch-ahead loop_check
    ;show [pcolor] of patch_ahead
    ifelse ([pcolor] of patch_ahead mod 10 = 0) or ([pcolor] of patch_ahead = 123)
    [
      ;show word"Found wall"""
      set loop_check detect-radius + 1
    ]
    [
      ;show word"No wall, or frame ahead"""
      ;show loop_check
      if loop_check = detect-radius
      [
        ;show word"Checking for scanned patches...."""
        ifelse [scanned?] of patch-ahead (loop_check + 1) = True or [pcolor] of patch-ahead (loop_check + 1) mod 10 = 0 or [pcolor] of patch-ahead (loop_check + 1) = 123
        [
          ;show word"Detected patch"""
          set counter counter + 1
        ]
        [
          ;show word"Undetected patch"""
          set counter 0
        ]
      ]
      set loop_check loop_check + 1

    ]
  ]

  if not wall? (90 * direction) and (wall? (135 * direction) or
    wall? (140 * direction) or wall? (145 * direction) or wall? (150 * direction)
  or wall? (155 * direction) or wall? (130 * direction)
  or wall? (135 * direction) or wall? (130 * direction)
  or wall? (125 * direction) or wall? (120 * direction)
  or wall? (110 * direction) or wall? (100 * direction)
    or wall? (115 * direction) or wall? (105 * direction)
   or wall? (95 * direction))
  [ rt 90 * direction ]

  while [wall? 0] [
    lt 90 * direction
  ]
  ;fd drone-speed
end

to-report wall? [angle]  ;; turtle procedure
  ;; note that angle may be positive or negative.  if angle is
  ;; positive, the turtle looks right.  if angle is negative,
  ;; the turtle looks left.
  ;show ([pcolor] of patch-right-and-ahead angle deflect-radius)
  report (0 = ([pcolor] of patch-right-and-ahead angle deflect-radius) mod 10) or (123 = ([pcolor] of patch-right-and-ahead angle deflect-radius))
end
@#$#@#$#@
GRAPHICS-WINDOW
213
13
691
492
-1
-1
3.133333333333334
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
149
0
149
0
0
1
ticks
30.0

BUTTON
29
18
93
51
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
103
19
185
52
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
0

SWITCH
30
59
136
92
fireSpread
fireSpread
0
1
-1000

SLIDER
27
140
198
173
fireCountBlack
fireCountBlack
0
10
6.0
1
1
patches
HORIZONTAL

SLIDER
25
183
198
216
fireCountWhite
fireCountWhite
0
10
6.0
1
1
patches
HORIZONTAL

SLIDER
24
226
197
259
spreadSpeedBlack
spreadSpeedBlack
0
50
50.0
1
1
%
HORIZONTAL

SLIDER
24
269
197
302
spreadSpeedWhite
spreadSpeedWhite
0
20
20.0
1
1
%
HORIZONTAL

SLIDER
24
457
197
490
number-of-drones
number-of-drones
0
10
3.0
1
1
NIL
HORIZONTAL

SLIDER
24
317
197
350
drone-speed
drone-speed
0
1
0.65
0.05
1
NIL
HORIZONTAL

SLIDER
23
412
196
445
detect-radius
detect-radius
1
50
14.0
1
1
NIL
HORIZONTAL

SLIDER
23
365
196
398
angle-shift
angle-shift
0
1
0.25
0.05
1
NIL
HORIZONTAL

SLIDER
25
101
198
134
deflect-radius
deflect-radius
0.01
2
1.16
0.05
1
NIL
HORIZONTAL

PLOT
698
338
938
488
№ Dead People
Time
Deaths
0.0
1000.0
0.0
20.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot total-dead"

PLOT
700
163
940
324
№ People Waiting To Be Rescued
NIL
NIL
0.0
10.0
0.0
20.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot 20 - (countSuccessfullyRescued + total-dead)"

PLOT
699
12
937
152
№ Successfully Rescued People
NIL
NIL
0.0
10.0
0.0
20.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot countSuccessfullyRescued"

MONITOR
555
459
689
508
Percentage Burned
percentageBurned * 100
2
1
12

MONITOR
919
356
1044
401
Count Dead People
total-dead
17
1
11

MONITOR
917
182
1040
227
Waiting To Be Rescued
20 - (countSuccessfullyRescued + total-dead)
17
1
11

MONITOR
915
31
1046
76
Successfully Rescued
countSuccessfullyRescued
17
1
11

@#$#@#$#@
## WHAT IS IT?

This is a simulation of an emergency situation in a burning bulding. Civilians are located inside said building with different fire starting locations. Drones are sent to scout the area and robots are called to save the people.

## HOW IT WORKS

The people in the house are static and simply wait to be rescued.
Fire spreads randomly with a set probability to the neighbouring patches.
Drones will scout around the bulding while following its walls clockwise, or counter-clockwise
Robots will find the optimal path to rescue the detected people, if a robot gets trapped  in fire on the way to rescue a person it will die.

## HOW TO USE IT
The setup button is pressed at the beginign to set the enviroment. The go button is bassicly to start runing the simulation. 

Besides the set and the go buttons, the user interface consists of a number of sliders, each slider has a name which indecates its functionality. 

The button "fireSpread" can be set to on or off, in case the user want to use the effect of fire or not. 

## THINGS TO NOTICE

Each plots has a monitor next, the monitors simply represent the current value of the plot

## THINGS TO TRY

To experement with the effect of each slider just increase or decrease the slider
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

drone
true
0
Rectangle -7500403 false true 135 75 165 90
Line -7500403 true 135 60 150 75
Line -7500403 true 135 60 135 75
Line -7500403 true 135 90 135 105
Line -7500403 true 135 105 135 105
Line -7500403 true 135 105 150 90
Line -7500403 true 165 60 165 60
Line -7500403 true 165 60 150 75
Line -7500403 true 165 60 165 75
Line -7500403 true 165 90 165 105
Line -7500403 true 165 105 150 90

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
NetLogo 6.2.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="5000"/>
    <exitCondition>count people = 0</exitCondition>
    <metric>count people</metric>
    <metric>total-dead</metric>
    <enumeratedValueSet variable="spreadSpeedWhite">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fireSpread">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-drones">
      <value value="1"/>
      <value value="2"/>
      <value value="3"/>
      <value value="4"/>
      <value value="5"/>
      <value value="6"/>
      <value value="7"/>
      <value value="8"/>
      <value value="9"/>
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="angle-shift">
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="deflect-radius">
      <value value="1.16"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fireCountBlack">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="detect-radius">
      <value value="12"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="spreadSpeedBlack">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="drone-speed">
      <value value="0.65"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fireCountWhite">
      <value value="6"/>
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

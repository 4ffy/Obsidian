------------------------------------------------------------------------
--  RENDER : CONSTRUCT AREAS
------------------------------------------------------------------------
--
--  Oblige Level Maker
--
--  Copyright (C) 2008-2016 Andrew Apted
--
--  This program is free software; you can redistribute it and/or
--  modify it under the terms of the GNU General Public License
--  as published by the Free Software Foundation; either version 2
--  of the License, or (at your option) any later version.
--
--  This program is distributed in the hope that it will be useful,
--  but WITHOUT ANY WARRANTY; without even the implied warranty of
--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--  GNU General Public License for more details.
--
------------------------------------------------------------------------


function edge_get_rail(S, dir)
  assert(S.area)

  local N = S:neighbor(dir, "NODIR")

  assert(N != "NODIR")

  if not (N and N.area) then return nil end
  if N.area == S.area then return nil end

--[[  fixme??
  local bord = S.border[dir]

  if bord.kind == "rail" then return bord end

  if bord.kind != nil then return nil end
--]]

  local junc = Junction_lookup(S.area, N.area)

--!!!! FIXME
  if junc.kind == "rail" then return junc end

  return nil
end



function Render_outer_sky(S, dir, floor_h)
  assert(not geom.is_corner(dir))

  local x1, y1 = S.x1, S.y1
  local x2, y2 = S.x2, S.y2

  if dir == 2 then y2 = y1 ; y1 = y1 - 8 end
  if dir == 8 then y1 = y2 ; y2 = y2 + 8 end

  if dir == 4 then x2 = x1 ; x1 = x1 - 8 end
  if dir == 6 then x1 = x2 ; x2 = x2 + 8 end

  local f_brush = brushlib.quad(x1, y1, x2, y2)

  each C in f_brush do
    C.flags = DOOM_LINE_FLAGS.draw_never
  end

  local c_brush = brushlib.copy(f_brush)

  table.insert(f_brush, { t=floor_h, reachable=true })
  table.insert(c_brush, { b=floor_h + 16, delta_z = -16 })

  brushlib.set_mat(f_brush, "_SKY", "_SKY")
  brushlib.set_mat(c_brush, "_SKY", "_SKY")

  Trans.brush(f_brush)
  Trans.brush(c_brush)
end



function Render_edge(E)

  if E.kind == "nothing" then
    return
  end


  local A   = assert(E.area)
  local dir = assert(E.dir)

  if A.mode == "void" then return end


  local DIAG_DIR_MAP = { [1]=8, [9]=2, [3]=4, [7]=6 }


  local function raw_wall_brush()
    local S = E.S

    local TK = 16

    local x1, y1 = S.x1, S.y1
    local x2, y2 = S.x2, S.y2

    if dir == 2 then y2 = y1 + TK end
    if dir == 8 then y1 = y2 - TK end

    if dir == 4 then x2 = x1 + TK end
    if dir == 6 then x1 = x2 - TK end


    if dir == 2 or dir == 4 or dir == 6 or dir == 8 then
      return brushlib.quad(x1, y1, x2, y2)

    elseif dir == 1 then
      return
      {
        { x=x1,      y=y2      }
        { x=x2,      y=y1      }
        { x=x2,      y=y1 + TK }
        { x=x1 + TK, y=y2      }
      }

    elseif dir == 9 then
      return
      {
        { x=x1,      y=y2      }
        { x=x1,      y=y2 - TK }
        { x=x2 - TK, y=y1      }
        { x=x2,      y=y1      }
      }

    elseif dir == 3 then
      return
      {
        { x=x1,      y=y1 }
        { x=x2,      y=y2 }
        { x=x2 - TK, y=y2 }
        { x=x1,      y=y1 + TK }
      }

    elseif dir == 7 then
      return
      {
        { x=x1,      y=y1 }
        { x=x1 + TK, y=y1 }
        { x=x2,      y=y2 - TK }
        { x=x2,      y=y2 }
      }

    else
      error("edge_wall : bad dir")
    end
  end


  local function edge_wall__OLD(mat)
    local brush = raw_wall_brush()

    brushlib.set_mat(brush, mat, mat)

    Trans.brush(brush)
  end


  local function edge_inner_sky()
    local floor_h = assert(A.floor_h)

    assert(not geom.is_corner(dir))

    local x1, y1 = S.x1, S.y1
    local x2, y2 = S.x2, S.y2

    if dir == 2 then y2 = y1 + 8 end
    if dir == 8 then y1 = y2 - 8 end

    if dir == 4 then x2 = x1 + 8 end
    if dir == 6 then x1 = x2 - 8 end

    local brush = brushlib.quad(x1, y1, x2, y2)

    each C in brush do
      C.flags = DOOM_LINE_FLAGS.draw_never
    end

    table.insert(brush, { b=floor_h + 16, delta_z = -16 })

    brushlib.set_mat(brush, "_SKY", "_SKY")

    Trans.brush(brush)
  end


  local function edge_wall()

    -- find the prefab to use
    local reqs =
    {
      kind = "wall"

      seed_w = assert(E.long)

      height = A.ceil_h - A.floor_h
    }

    if geom.is_corner(dir) then
      reqs.where = "diagonal"
      reqs.seed_h = reqs.seed_w
    else
      reqs.where = "edge"
    end

    -- TODO : pictures, detailed walls


    local skin = {}

    skin.wall = assert(E.wall_mat or A.wall_mat)


    local def = Fab_pick(reqs)

    local z = A.floor_h

    local T

    if geom.is_corner(dir) then
      local dir2 = DIAG_DIR_MAP[dir]
      local S = E.S

      T = Trans.box_transform(S.x1, S.y1, S.x2, S.y2, z, dir2)

    else  -- axis-aligned edge

      T = Trans.edge_transform(E, z, 0, 0, def.deep, 0, false)
    end

    Trans.set_fitted_z(T, A.floor_h, A.ceil_h)

    Fabricate(R, def, T, { skin })
  end


  local function straddle_fence()

    -- find the prefab to use
    local reqs =
    {
      kind = "fence"

      seed_w = assert(E.long)
    }

    if geom.is_corner(dir) then
      reqs.where = "diagonal"
      reqs.seed_h = reqs.seed_w
    else
      reqs.where = "edge"
    end

    -- TODO : secret fences, barred fences


    local skin = { wall=E.fence_mat }


    local def = Fab_pick(reqs)

    local z = assert(E.fence_top_z) - def.fence_h

    local T

    if geom.is_corner(dir) then
      local dir2 = DIAG_DIR_MAP[dir]
      local S = E.S

      T = Trans.box_transform(S.x1, S.y1, S.x2, S.y2, z, dir2)

    else  -- axis-aligned edge

      T = Trans.edge_transform(E, z, 0, 0, def.deep, def.over)
    end

    Fabricate(R, def, T, { skin })
  end


  local function seed_touches_junc(S, junc)
    -- FIXME
    each dir in geom.ALL_DIRS do
--    if S.border[dir].junction == junc then return true end
    end

    return false
  end


  local function calc_step_A_mode(S, dir)
--FIXME
do return "narrow" end

    local junc = S.border[dir].junction
    if not junc or junc.kind != "steps" then return "narrow" end

    local N, bord

    if geom.is_straight(dir) then
      N = S:neighbor(geom.LEFT[dir])
      if not (N and N.area == S.area) then return "" end

      N = N:neighbor(dir)
      if not (N and N.area == S.area) then return "" end

      bord = N.border[geom.RIGHT[dir]]
      if bord.junction == junc then return "wide" end

      return "xx"

    else  -- corner

      local dir2 = geom.ROTATE[5][dir]
      local dir3 = geom.RIGHT[dir2]

      N = S:neighbor(dir2)
      if not (N and N.area == S.area) then return "" end

      N = N:neighbor(dir3)
      if not (N and N.area == S.area) then return "" end

      if seed_touches_junc(N, junc) then return "wide" end

      N = N:neighbor(10 - dir2)
      if not (N and N.area == S.area) then return "" end

      if seed_touches_junc(N, junc) then return "wide" end

      return "xx"
    end
  end


  local function calc_step_B_mode(S, dir)
--FIXME
do return "narrow" end

    local junc = S.border[dir].junction
    if not junc or junc.kind != "steps" then return "narrow" end

    local N, bord

    if geom.is_straight(dir) then
      N = S:neighbor(geom.RIGHT[dir])
      if not (N and N.area == S.area) then return "" end

      N = N:neighbor(dir)
      if not (N and N.area == S.area) then return "" end

      bord = N.border[geom.LEFT[dir]]
      if bord.junction == junc then return "wide" end

      return "xx"

    else  -- corner

      local dir2 = geom.ROTATE[3][dir]
      local dir3 = geom.LEFT[dir2]

      N = S:neighbor(dir2)
      if not (N and N.area == S.area) then return "" end

      N = N:neighbor(dir3)
      if not (N and N.area == S.area) then return "" end

      if seed_touches_junc(N, junc) then return "wide" end

      N = N:neighbor(10 - dir2)
      if not (N and N.area == S.area) then return "" end

      if seed_touches_junc(N, junc) then return "wide" end

      return "wide"
    end
  end


  local function make_step_brush(S, dir, a_mode, b_mode, TK)
    -- define points A and B

    local ax, ay = S.x1, S.y1
    local bx, by = S.x2, S.y2

    if dir == 2 then by = ay ; ax,bx = bx,ax end
    if dir == 8 then ay = by end
    if dir == 4 then bx = ax end
    if dir == 6 then ax = bx ; ay,by = by,ay end

    if dir == 1 or dir == 9 then
      ax,bx = bx,ax
    end

    if dir == 3 or dir == 9 then
      ax,bx = bx,ax
      ay,by = by,ay
    end

    -- compute vectors of points A and B

    local adx, ady = 0, 0
    local bdx, bdy = 0, 0

    if dir == 8 then
      ady, bdy = -1, -1
      if a_mode == "narrow" then adx =  0.5 elseif a_mode == "wide" then adx = -1 end
      if b_mode == "narrow" then bdx = -0.5 elseif b_mode == "wide" then bdx =  1 end
    elseif dir == 2 then
      ady, bdy = 1, 1
      if a_mode == "narrow" then adx = -0.5 elseif a_mode == "wide" then adx =  1 end
      if b_mode == "narrow" then bdx =  0.5 elseif b_mode == "wide" then bdx = -1 end
    elseif dir == 4 then
      adx, bdx = 1, 1
      if a_mode == "narrow" then ady =  0.5 elseif a_mode == "wide" then ady = -1 end
      if b_mode == "narrow" then bdy = -0.5 elseif b_mode == "wide" then bdy =  1 end
    elseif dir == 6 then
      adx, bdx = -1, -1
      if a_mode == "narrow" then ady = -0.5 elseif a_mode == "wide" then ady =  1 end
      if b_mode == "narrow" then bdy =  0.5 elseif b_mode == "wide" then bdy = -1 end

    elseif dir == 1 then
      if a_mode != "wide" then ady = 1 else adx = 1 end
      if b_mode != "wide" then bdx = 1 else bdy = 1 end
    elseif dir == 9 then
      if a_mode != "wide" then ady = -1 else adx = -1 end
      if b_mode != "wide" then bdx = -1 else bdy = -1 end
    elseif dir == 3 then
      if a_mode != "wide" then adx = -1 else ady =  1 end
      if b_mode != "wide" then bdy =  1 else bdx = -1 end
    elseif dir == 7 then
      if a_mode != "wide" then adx =  1 else ady = -1 end
      if b_mode != "wide" then bdy = -1 else bdx =  1 end
    else
      error("bad dir in make_step_brush")
    end

--[[ HANDY DEBUG
stderrf("dir = %d\n", dir)
stderrf("A = (%d %d)  B = (%d %d)\n", ax - S.x1, ay - S.y1, bx - S.x1, by - S.y1)
stderrf("dA = (%1.1f %1.1f)  dB = (%1.1f %1.1f)\n", adx, ady, bdx, bdy)
--]] 

    local brush =
    {
      { x = bx, y = by }
      { x = ax, y = ay }
      { x = ax + adx * TK, y = ay + ady * TK }
      { x = bx + bdx * TK, y = by + bdy * TK }
    }

    return brush
  end


  local function edge_steps()
    local mat = assert(E.steps_mat)
    local steps_z1 = E.steps_z1
    local steps_z2 = E.steps_z2

    -- wrong side?
    assert(steps_z2 > steps_z1)

    local diff_h = steps_z2 - steps_z1
    assert(diff_h > 8)

    local num_steps = 1

    while (diff_h / num_steps) > 24 do
      num_steps = num_steps + 1
    end

    local thick = 16 * num_steps
    if thick > 64 then thick = 64 end

    -- determine A and B modes (FIXME? quite broken atm)
    local a_mode = calc_step_A_mode(S, dir)
    local b_mode = calc_step_B_mode(S, dir)

    for i = 1, num_steps do
      local z = steps_z1 + i * diff_h / (num_steps + 1)
      local TK = thick * (num_steps + 1 - i) / num_steps

      local brush = make_step_brush(E.S, E.dir, a_mode, b_mode, TK)

      table.insert(brush, { t=z })

      brushlib.set_mat(brush, mat, mat)

      Trans.brush(brush)
    end
  end


  local function straddle_door()
    assert(E.peer)
    assert(E.peer.area)

    assert(E.conn)

    local z = E.conn.door_h or A.floor_h
    assert(z)

    local LOCK = E.conn.lock


    -- setup skin
    local inner_mat = assert(A.wall_mat)
    local outer_mat = assert(E.peer.area.wall_mat)

    if E.conn.flip_it then
      inner_mat, outer_mat = outer_mat, inner_mat
    end

    local skin1 = { wall=inner_mat, outer=outer_mat }


    -- find the prefab to use
    local reqs =
    {
      kind = "door"

      seed_w = assert(E.long)
    }

    if geom.is_corner(dir) then
      reqs.where = "diagonal"
      reqs.seed_h = reqs.seed_w
    else
      reqs.where = "edge"
    end

    if LOCK then
      if LOCK.kind == "intraroom" then
        reqs.key = "barred"
        skin1.lock_tag = assert(LOCK.tag)
      elseif #LOCK.goals == 2 then
        error("Locked double")
      elseif #LOCK.goals == 3 then
        error("Locked triple")
      elseif LOCK.goals[1].kind == "SWITCH" then
        reqs.switch = LOCK.goals[1].item
        skin1.lock_tag = assert(LOCK.goals[1].tag)
      else
        reqs.key = LOCK.goals[1].item
      end

    else -- normal door

      if E.kind == "secret_door" then
        reqs.key = "secret"
      
      elseif E.kind == "arch" then
        reqs.kind = "arch"
      end
    end


    local def = Fab_pick(reqs)

    local T

    if geom.is_corner(dir) then
      if E.conn.flip_it then dir = 10 - dir end

      local dir2 = DIAG_DIR_MAP[dir]

      local S = E.S

      T = Trans.box_transform(S.x1, S.y1, S.x2, S.y2, z, dir2)

    else  -- axis-aligned edge

      T = Trans.edge_transform(E, z, 0, 0, def.deep, def.over, E.conn.flip_it)
    end

    Fabricate(R, def, T, { skin1 })
  end


  local function straddle_window()
    assert(E.peer and E.peer.area)

    local z = assert(E.window_z)

    local inner_mat = assert(A.wall_mat)
    local outer_mat = assert(E.peer.area.wall_mat)

    local skin1 = { wall=inner_mat, outer=outer_mat }


    -- FIXME : find it properly
    local fab_name = "Window_wide"


    if geom.is_corner(dir) then
      fab_name = fab_name .. "_diag"

      local def = Fab_lookup(fab_name)

      local dir2 = DIAG_DIR_MAP[dir]

      local S = E.S
      local T = Trans.box_transform(S.x1, S.y1, S.x2, S.y2, z, dir2)

      Fabricate(R, def, T, { skin1 })

    else  -- axis-aligned edge

      local def = Fab_lookup(fab_name)

      local T = Trans.edge_transform(E, z, 0, 0, def.deep, def.over)

      Fabricate(R, def, T, { skin1 })
    end
  end


  ---| Render_edge |---

  assert(E)
  assert(E.kind)

  if Edge_is_wallish(E) then
    Corner_mark_walls(E)
  end

  if E.kind == "wall" then
    edge_wall()

  elseif E.kind == "sky_edge" and A.floor_h then
    edge_inner_sky()

  elseif E.kind == "steps" then
    edge_steps()

  elseif E.kind == "fence" then
    straddle_fence()

  elseif E.kind == "arch" or E.kind == "door" or
         E.kind == "lock_door" or E.kind == "secret_door" then
    straddle_door()

  elseif E.kind == "window" then
    straddle_window()

  else
    error("Unknown edge kind: " .. tostring(E.kind))
  end
end



function Render_junction(A, S, dir)
  if S.done_all then return end

  -- proper EDGE objects are handled elsewhere
  if S.edge[dir] then return end

  local N = S:neighbor(dir, "NODIR")

  if N == "NODIR" then return end

  -- same area?  absolutely nothing needed
  if N and N.area == A then return end

  -- find the junction (N.area may be NIL)
  local junc
  
  if N and N.area then
    junc = Junction_lookup(A, N.area)
  else
    junc = Junction_lookup(A, "map_edge")
  end

  if not junc then return end

  for pass = 1, 2 do
    local E

    if (junc.A1 == A) == (pass == 1) then
      E = junc.E1
    else
      E = junc.E2
    end

    if E then
      E.S    = S
      E.dir  = dir
      E.long = 1

      Render_edge(E)
    end

    if pass == 1 then
      S   = S:neighbor(dir)
      dir = 10 - dir
    end
  end
end



function Render_corner(cx, cy)

  local corner

  local analysis


  local function make_post()
    local mx, my = corner.x, corner.y
    local mat    = corner.post_mat or "METAL"
    
    local brush  = brushlib.quad(mx - 12, my - 12, mx + 12, my + 12)

    if corner.post_top_h then
      brushlib.add_top(brush, corner.post_top_h)
    end

    brushlib.set_mat(brush, mat, mat)

    Trans.brush(brush)
  end


  local function make_pillar()
    -- TODO
  end


  local function init_analysis()
    analysis = {}

    each dir in geom.ALL_DIRS do
      if corner.walls[dir] then
        analysis[dir] = corner.walls[dir]
      else
        analysis[dir] = {}
      end
    end
  end


  local function build_filler(dir, L_tex, R_tex)
    if L_tex != R_tex then
      L_tex = "METAL"
    end

    local x = corner.x
    local y = corner.y

    local ax, ay = geom.delta(geom.RIGHT_45[dir])
    local bx, by = geom.delta(geom. LEFT_45[dir])

    ax = ax * 16 ; ay = ay * 16
    bx = bx * 16 ; by = by * 16

    local w_brush = brushlib.triangle(x, y, x+ax, y+ay, x+bx, y+by)

    brushlib.set_mat(w_brush, L_tex)

    Trans.brush(w_brush)
  end


  local function detect_gap(dir, num_left, num_right)
    -- dir is a corner direction (1, 3, 7, 9)
    
    -- the starting line must be clear
    if analysis[dir].L or analysis[dir].R then return false end

    local L_dir = dir
    local R_dir = dir

    for i = 1, num_left do
      L_dir = geom.LEFT_45[L_dir]

      if analysis[L_dir].L or analysis[L_dir].R then return false end
    end

    for i = 1, num_right do
      R_dir = geom.RIGHT_45[R_dir]

      if analysis[R_dir].L or analysis[R_dir].R then return false end
    end

    L_dir = geom.LEFT_45 [L_dir]
    R_dir = geom.RIGHT_45[R_dir]

    local L_tex = analysis[L_dir].R
    local R_tex = analysis[R_dir].L
    
    if L_tex and R_tex then
      build_filler(dir, L_tex, R_tex)
      return true
    end

    return false
  end


  local function polish_walls()
    --
    -- Find gaps where two walls meet at a corner, and fill that gap
    -- (producing a nice polished finish).
    --
    -- Algorithm:
    --   1. analyse the eight lines coming off this corner.
    --      each line may have a wall on each side (left and right).
    --      [ this is done while rendering all the edges ]
    --
    --   2. detect the cases where we need a gap filler.
    --      e.g. they require nothing on the three or four lines
    --      which lie in-between the two walls.
    --

    if table.empty(corner.walls) then return end

    init_analysis()

    each dir in geom.CORNERS do
      if detect_gap(dir, 1, 1) or detect_gap(dir, 1, 2) or
         detect_gap(dir, 2, 1) or detect_gap(dir, 2, 2)
      then
        -- Ok, gap was filled
      end
    end
  end


  ---| Render_corner |---

  corner = Corner_lookup(cx, cy)

  if corner.kind == nil or corner.kind == "nothing" then
    polish_walls()

  elseif corner.kind == "post" then
    make_post()

  elseif corner.kind == "pillar" then
    make_pillar()

  else
    error("Unknown corner kind: " .. tostring(corner.kind))
  end
end



function Render_sink_part(A, S, where, sink)
 

  local function check_inner_point(cx, cy)
    local corner = Corner_lookup(cx, cy)

    if corner and corner.inner_point then
      return true
    else
      return false
    end
  end


  local function corner_coord(C)
    local x, y = S.x1, S.y1

    if C == 3 or C == 9 then x = S.x2 end
    if C == 7 or C == 9 then y = S.y2 end

    return x, y
  end


  local function apply_brush(brush, is_trim)
    local mul

    if where == "floor" then
      mul = -1 ; brushlib.add_top(brush, A.floor_h + 2)
    else
      mul =  1 ; brushlib.add_bottom(brush, A.ceil_h - 2)
    end

    local T = brush[#brush]

    if is_trim then
      if not sink.trim_mat then return end

      T.delta_z = (2 + sink.trim_dz) * mul
      brushlib.set_mat(brush, sink.trim_mat, sink.trim_mat)
    else
      T.delta_z = (2 + sink.dz) * mul
      brushlib.set_mat(brush, sink.mat, sink.mat)
    end

    Trans.brush(brush)
  end


  local function do_whole_square()
    local brush =
    {
      { x = S.x1, y = S.y1 }
      { x = S.x2, y = S.y1 }
      { x = S.x2, y = S.y2 }
      { x = S.x1, y = S.y2 }
    }

    apply_brush(brush)
  end


  local function do_whole_triangle(A, C, B)
    local cx, cy = corner_coord(C)
    local ax, ay = corner_coord(A)
    local bx, by = corner_coord(B)

    local brush =
    {
      { x = ax, y = ay }
      { x = cx, y = cy }
      { x = bx, y = by }
    }

    apply_brush(brush)
  end


  local function do_triangle(A, C, B, away)
    -- A, B, C are corner numbers
    -- C is the corner either near or away from where the sink goes
    -- the brush formed by A->C->B should be valid (anti-clockwise)

    local cx, cy = corner_coord(C)
    local ax, ay = corner_coord(A)
    local bx, by = corner_coord(B)

    local ax2, ay2 = (ax + cx) / 2, (ay + cy) / 2
    local bx2, by2 = (bx + cx) / 2, (by + cy) / 2

    local k1 = 0.41666
    local k2 = 1 - k1

    if away then k1, k2 = k2, k1 end

    local ax3, ay3 = ax * k1 + cx * k2, ay * k1 + cy * k2
    local bx3, by3 = bx * k1 + cx * k2, by * k1 + cy * k2

--[[ DEBUG
stderrf("C = (%d %d)\n", cx, cy)
stderrf("A = (%d %d)  | (%d %d)  | (%d %d)\n", ax,ay, ax2,ay2, ax3,ay3)
stderrf("B = (%d %d)  | (%d %d)  | (%d %d)\n", bx,by, bx2,by2, bx3,by3)
stderrf("away = %s\n\n", string.bool(away))
--]]

    local brush, trim

    if away then
      brush =
      {
        { x = ax,  y = ay  }
        { x = ax3, y = ay3 }
        { x = bx3, y = by3 }
        { x = bx,  y = by  }
      }

      trim =
      {
        { x = bx2, y = by2 }
        { x = bx3, y = by3 }
        { x = ax3, y = ay3 }
        { x = ax2, y = ay2 }
      }

    else -- near
      brush =
      {
        { x = ax3, y = ay3 }
        { x = cx,  y = cy  }
        { x = bx3, y = by3 }
      }

      trim =
      {
        { x = ax2, y = ay2 }
        { x = ax3, y = ay3 }
        { x = bx3, y = by3 }
        { x = bx2, y = by2 }
      }
    end

    apply_brush(brush)
    apply_brush(trim, "is_trim")
  end


  -- categorize corners
  local p1 = check_inner_point(S.sx    , S.sy)
  local p3 = check_inner_point(S.sx + 1, S.sy)
  local p7 = check_inner_point(S.sx    , S.sy + 1)
  local p9 = check_inner_point(S.sx + 1, S.sy + 1)


  if S.diagonal == 1 then
    local p_val = sel(p1,1,0) + sel(p3,2,0) + sel(p7,4,0)

    if p_val == 7 then do_whole_triangle(1,3,7) end

    if p_val == 1 then do_triangle(7,1,3, false) end
    if p_val == 2 then do_triangle(1,3,7, false) end
    if p_val == 4 then do_triangle(3,7,1, false) end

    if p_val == 6 then do_triangle(7,1,3, true) end
    if p_val == 5 then do_triangle(1,3,7, true) end
    if p_val == 3 then do_triangle(3,7,1, true) end

  elseif S.diagonal == 3 then
    local p_val = sel(p1,1,0) + sel(p3,2,0) + sel(p9,4,0)

    if p_val == 7 then do_whole_triangle(1,3,9) end

    if p_val == 1 then do_triangle(9,1,3, false) end
    if p_val == 2 then do_triangle(1,3,9, false) end
    if p_val == 4 then do_triangle(3,9,1, false) end

    if p_val == 6 then do_triangle(9,1,3, true) end
    if p_val == 5 then do_triangle(1,3,9, true) end
    if p_val == 3 then do_triangle(3,9,1, true) end

  elseif S.diagonal == 9 then
    local p_val = sel(p9,1,0) + sel(p7,2,0) + sel(p3,4,0)

    if p_val == 7 then do_whole_triangle(9,7,3) end

    if p_val == 1 then do_triangle(3,9,7, false) end
    if p_val == 2 then do_triangle(9,7,3, false) end
    if p_val == 4 then do_triangle(7,3,9, false) end

    if p_val == 6 then do_triangle(3,9,7, true) end
    if p_val == 5 then do_triangle(9,7,3, true) end
    if p_val == 3 then do_triangle(7,3,9, true) end

  elseif S.diagonal == 7 then

    local p_val = sel(p9,1,0) + sel(p7,2,0) + sel(p1,4,0)

    if p_val == 7 then do_whole_triangle(9,7,1) end

    if p_val == 1 then do_triangle(1,9,7, false) end
    if p_val == 2 then do_triangle(9,7,1, false) end
    if p_val == 4 then do_triangle(7,1,9, false) end

    if p_val == 6 then do_triangle(1,9,7, true) end
    if p_val == 5 then do_triangle(9,7,1, true) end
    if p_val == 3 then do_triangle(7,1,9, true) end

  else  -- Square --

    local p_val = sel(p1,1,0) + sel(p3,2,0) + sel(p7,4,0) + sel(p9,8,0)

    -- nothing open
    if p_val == 0 then return end

    -- all corners open
    if p_val == 15 then do_whole_square() end

    -- one corner open

    if p_val ==  1 then do_triangle(7,1,9, false) ; do_triangle(9,1,3, false) end
    if p_val ==  2 then do_triangle(1,3,7, false) ; do_triangle(7,3,9, false) end

    if p_val ==  4 then do_triangle(3,7,1, false) ; do_triangle(9,7,3, false) end
    if p_val ==  8 then do_triangle(1,9,7, false) ; do_triangle(3,9,1, false) end

    -- two open, two closed

    if p_val == 3  then do_triangle(7,1,9, false) ; do_triangle(3,9,1, true)  end
    if p_val == 12 then do_triangle(7,1,9, true)  ; do_triangle(3,9,1, false) end

    if p_val == 5  then do_triangle(1,3,7, true)  ; do_triangle(9,7,3, false) end
    if p_val == 10 then do_triangle(1,3,7, false) ; do_triangle(9,7,3, true)  end

    -- the "proper" way
    --if p_val ==  9 then do_triangle(7,1,3, false) ; do_triangle(3,9,7, false) end
    --if p_val ==  6 then do_triangle(9,7,1, false) ; do_triangle(1,3,9, false) end

    -- the "alternative" way : connects the two sub-areas
    if p_val ==  6 then do_triangle(7,1,3, true) ; do_triangle(3,9,7, true) end
    if p_val ==  9 then do_triangle(9,7,1, true) ; do_triangle(1,3,9, true) end
    
    -- three corners open

    if p_val == 14 then do_triangle(7,1,9, true)  ; do_triangle(9,1,3, true)  end
    if p_val == 13 then do_triangle(1,3,7, true)  ; do_triangle(7,3,9, true)  end

    if p_val == 11 then do_triangle(3,7,1, true)  ; do_triangle(9,7,3, true)  end
    if p_val ==  7 then do_triangle(1,9,7, true)  ; do_triangle(3,9,1, true)  end
  end
end



function Render_void(A, S)
  -- used for VOID areas

  local w_brush = S:make_brush()

  brushlib.set_mat(w_brush, A.wall_mat)

  Trans.brush(w_brush)
end



function Render_floor(A, S)
  if S.done_floor then return end

  local f_brush = S:make_brush()

  local f_h = S.floor_h or A.floor_h
  assert(f_h)

  local f_mat = S.floor_mat or A.floor_mat
  local f_side = S.floor_side or S.floor_mat or A.floor_side or f_mat

  local tag = S.tag
-- tag = A.id
-- if A.room then tag = A.room.id end


  -- handle railings [ must be done here ]
  each C in f_brush do
    local info = edge_get_rail(S, C.__dir)
    if info then
      C.rail = assert(info.rail_mat)
      C.v1 = 0
      C.back_rail = C.rail
      C.back_v1 = 0
      C.blocked = info.blocked
    end
  end


  table.insert(f_brush, { t=f_h, light=S.light, tag=tag })

  brushlib.set_mat(f_brush, f_side, f_mat)

  Trans.brush(f_brush)

  -- remember floor brush for the spot logic
  table.insert(A.floor_brushes, f_brush)

  if A.floor_sink then
    Render_sink_part(A, S, "floor",   A.floor_sink)
  end
end



function Render_ceiling(A, S)
  if S.done_ceil then return end

  local c_h = S.ceil_h or A.ceil_h
  assert(c_h)

  local c_mat  = S.ceil_mat  or A.ceil_mat
  local c_side = S.ceil_side or S.ceil_mat or A.ceil_side or c_mat

  local c_brush = S:make_brush()

  table.insert(c_brush, { b=c_h })

  brushlib.set_mat(c_brush, c_side, c_mat)

  Trans.brush(c_brush)

  if A.ceil_sink then
    Render_sink_part(A, S, "ceiling", A.ceil_sink)
  end
end



function Render_hallway(A, S)
  local R = A.room

  -- determine common part of prefab name
  local fab_common

  if S.hall_piece then
    if S.hall_piece.shape == "I" then
      fab_common = "stair_"
    else
      fab_common = "curve_"
    end

    -- append "big" or "small"
    fab_common = fab_common .. S.hall_piece.z_size
  end

  local skin = {}

--- if A.room.hallway.parent then skin.floor = "FLAT14" end


  if S.hall_piece then
    local fab_name = "Hall_f_" .. fab_common
    local def = Fab_lookup(fab_name)

    local z = S.floor_h + S.hall_piece.z_offset
    local T = Trans.box_transform(S.x1, S.y1, S.x2, S.y2, z, S.hall_piece.dir)

    if S.hall_piece.mirror then T.mirror_x = SEED_SIZE / 2 end

    Fabricate(A.room, def, T, { skin })

  else
    Render_floor(A, S)
  end


  if S.hall_piece and not A.is_outdoor and not R.hallway.parent then
    local fab_name = "Hall_c_" .. fab_common
    local def = Fab_lookup(fab_name)

    local z = S.ceil_h + S.hall_piece.z_offset
    local T = Trans.box_transform(S.x1, S.y1, S.x2, S.y2, z, S.hall_piece.dir)

    if S.hall_piece.mirror then T.mirror_x = 96 end

    Fabricate(A.room, def, T, { skin })
  else
    Render_ceiling(A, S)
  end
end



function Render_seed(A, S)
  assert(S.area == A)

  if S.done_all then
    -- done elsewhere
    return
  end

  if S.kind == "void" or A.mode == "void" then
    Render_void(A, S)
    return
  end

  -- create edge-lines for spot finding code
  each dir in geom.ALL_DIRS do
    local N = S:neighbor(dir)
    if N and N.area != A then
      table.insert(A.side_edges, S:get_line(dir))
    end
  end

  if A.mode == "hallway" then
    Render_hallway(A, S)
    return
  end

  Render_floor  (A, S)
  Render_ceiling(A, S)
end



function Render_mark_done(chunk, mode)
  -- mode can be "all", "floor" or "ceil"

  mode = "done_" .. mode

  for sx = chunk.sx1, chunk.sx2 do
  for sy = chunk.sy1, chunk.sy2 do
    local S = SEEDS[sx][sy]

    S[mode] = true
  end
  end
end



function Render_chunk(chunk)
  --
  -- this handles prefabs which occupy a seed rectangle (chunk) and
  -- are responsible for making the whole floor and/or ceiling.
  --

  -- unused closets will be rendered as void
  if chunk.kind == "closet" and not chunk.content_kind then
    return
  end

  local A = chunk.area

  gui.debugf("\n\n Render_chunk in %s (%s / %s)\n", A.room.name, chunk.kind, chunk.content_kind or "-")

  local dir = chunk.from_dir or chunk.dir or 2

  local skin = {}

  local reqs =
  {
    where  = "seeds"

    seed_w = chunk.sw
    seed_h = chunk.sh
  }

  if geom.is_horiz(dir) then
    reqs.seed_w = chunk.sh
    reqs.seed_h = chunk.sw
  end


  local function do_start()
    reqs.kind = "start"
  end

  local function do_exit()
    reqs.kind = "exit"
  end

  local function do_cage()
    reqs.kind = "cage"
  end

  local function do_trap()
    reqs.kind = "trap"

    -- FIXME : tag for trap door!!
  end

  local function do_teleporter()
    reqs.kind = "teleporter"

    local C = assert(chunk.conn)

    if C.R1 == A.room then
      skin. in_tag = C.tele_tag2
      skin.out_tag = C.tele_tag1
    else
      skin. in_tag = C.tele_tag1
      skin.out_tag = C.tele_tag2
    end

    skin. in_target = string.format("tele%d", skin. in_tag)
    skin.out_target = string.format("tele%d", skin.out_tag)
  end

  local function do_stairs()
    reqs.kind = "stairs"
  end

  local function do_joiner()
    reqs.kind = "joiner"

    local C = assert(chunk.conn)
    if C.flip_it then
      dir = 10 - dir
    end

    local LOCK = C.lock

    if LOCK then
      if LOCK.kind == "intraroom" then
        reqs.key = "barred"
        skin.lock_tag = assert(LOCK.tag)
      elseif #LOCK.goals == 2 then
        error("Locked double")
      elseif #LOCK.goals == 3 then
        error("Locked triple")
      elseif LOCK.goals[1].kind == "SWITCH" then
        reqs.switch = LOCK.goals[1].item
      else
        reqs.key = LOCK.goals[1].item
      end
    end
  end

  local function do_switch()
    reqs.kind = "switch"

    --??? reqs.switch = "intraroom"

    assert(chunk.lock)

    skin.lock_tag = assert(chunk.lock.tag)
    skin.action   = 103  -- open door
  end

  local function do_item()
    reqs.kind = "item"

    skin.object = assert(chunk.content_item)
  end

  local function do_nice_item()
    reqs.kind = "nice_item"

    reqs.key = "secret"  -- FIXME
  end


  local function chunk_coords(def)
    local S1 = SEEDS[chunk.sx1][chunk.sy1]
    local S2 = SEEDS[chunk.sx2][chunk.sy2]

    local x1, y1 = S1.x1, S1.y1
    local x2, y2 = S2.x2, S2.y2

    -- move closets to align with nearby walls

    if chunk.kind == "closet" and chunk.from_dir
       -- FIXME and chunk.shape == "U"
       and def.y_fit == "top"
       and not def.no_align
    then
      if chunk.from_dir == 2 then y1 = y1 - 16 end
      if chunk.from_dir == 8 then y2 = y2 + 16 end

      if chunk.from_dir == 4 then x1 = x1 - 16 end
      if chunk.from_dir == 6 then x2 = x2 + 16 end
    end

    return x1,y1, x2,y2
  end


  ---| Render_chunk |---

  -- handle a ceiling paired with a floor
  if chunk.next_highest then
    Render_chunk(chunk.next_highest)
  end

  -- FIXME : reqs.shape

  -- room kind and (for joiners) neighbor room kind
  if A.room then
    reqs.env = A.room:get_env()
  end

  if chunk.kind == "joiner" then
    assert(chunk.conn)
    local A2 = chunk.conn:other_area(A)
    reqs.neighbor = A2.room:get_env()
  end


  local what = chunk.content_kind


  -- FIXME : support e.g. kind=="floor" + what=="START" (e.g. a raising start)
  --         [ most of the checks below assume kind=="closet" ]


  -- FIXME : "SECRET_EXIT"


  if chunk.kind == "stair" then
    do_stairs()

  elseif chunk.kind == "joiner" then
    do_joiner()

  elseif what == "START" then
    do_start()

  elseif what == "EXIT" then
    do_exit()

  elseif what == "TELEPORTER" then
    do_teleporter()

  elseif what == "SWITCH" then
    do_switch()

  elseif what == "KEY" or what == "WEAPON" or what == "ITEM" then
    do_item()

  elseif what == "NICE_ITEM" then
    do_nice_item()

  elseif what == "CAGE" then
    do_cage()

  elseif what == "TRAP" then
    do_trap()

  else
    error("Unsupported chunk kind: " .. tostring(chunk.kind) .. " / " .. tostring(what))
  end


  --- pick the prefab ---

  local def = Fab_pick(reqs)


  -- build the prefab --

  local tex_ref = chunk.tex_ref or chunk.from_area or chunk.dest_area

  if tex_ref then
    skin.wall  = tex_ref.wall_mat
    skin.floor = tex_ref.floor_mat
    skin.ceil  = tex_ref.ceil_mat

    if tex_ref.is_outdoor then
      skin.wall = A.facade_mat or A.zone.facade_mat
    end
  end


  local x1, y1, x2, y2 = chunk_coords(def)

  local floor_h = assert(A.floor_h) + (def.raise_z or 0)

  local T = Trans.box_transform(x1, y1, x2, y2, floor_h, dir)

  Fabricate(A.room, def, T, { skin })

  
  -- mark seeds as done --

  local done_mode

  if def.done_mode then
    done_mode = def.done_mode

  elseif def.kind == "floor" or def.kind == "stairs" then
    done_mode = "floor"

  elseif def.kind == "ceil" then
    done_mode = "ceil"

  else
    done_mode = "all"
  end

  Render_mark_done(chunk, done_mode)
end



function Render_area(A)
  if A.is_stairwell then
    error("A.is_stairwell")
    return
  end

  each E in A.edges do
    assert(E.area == A)
    Render_edge(E)
  end

  each S in A.seeds do
    Render_seed(A, S)

    each dir in geom.ALL_DIRS do
      Render_junction(A, S, dir)
    end
  end
end



function Render_depot(depot)
  -- dest_R is the room which gets the trap spots
  local dest_R = assert(depot.room)

  local x1 = depot.x1
  local y1 = depot.y1

  local z = assert(LEVEL.player1_z)


  local def = PREFABS["Depot"]
  assert(def)

  local x2 = x1 + def.seed_w * SEED_SIZE
  local y2 = y1 + def.seed_h * SEED_SIZE

  local skin1 =
  {
    wall = "_ERROR"
  }

  assert(depot.skin)


  local T = Trans.box_transform(x1, y1, x2, y2, z, 2)

  Fabricate(dest_R, def, T, { skin1, depot.skin })
end



function Render_all_areas()
  each A in LEVEL.areas do
    Render_area(A)
  end

  for cx = 1, SEED_W + 1 do
  for cy = 1, SEED_H + 1 do
    Render_corner(cx, cy)
  end
  end

  each depot in LEVEL.depots do
    Render_depot(depot)
  end
end


------------------------------------------------------------------------


function Render_properties_for_area(A)

  -- scenic parts done elsewhere...
  if A.mode == "scenic" then
    return
  end


  local R = A.room
  if not R then R = A.face_room end


  if A.mode == "void" then
    A.wall_mat   = A.facade_mat or A.zone.facade_mat
    A.floor_mat  = A.wall_mat
    return
  end


  if not A.floor_h then
    A.floor_h = -7
  end


  if R then
    A.wall_mat = assert(R.main_tex)

  else
    A.floor_mat = "_ERROR"
  end

  if A.mode == "hallway" then
    A.floor_mat = "FLAT5_1"
    A.wall_mat  = "WOOD1"
    A.ceil_mat  = "WOOD1"

    -- TEMP CRUD to match 'hall_piece' texture usage
    if A.room and A.room.skin and A.room.skin.wall then
      A.floor_mat = A.room.skin.wall
      A. ceil_mat = A.room.skin.wall
    end

    if A.ceil_h then
      -- done already
    elseif A.is_porch then
      A.ceil_h = A.floor_h + 128
    elseif not A.is_outdoor then
      A.ceil_h = A.floor_h + 80
    end
  end


  if A.mode == "cage" then
    if A.is_outdoor then
      A.floor_mat = LEVEL.cliff_mat
    else
      A.floor_mat = A.zone.facade_mat
    end
  end


  if A.mode == "liquid" then
    A.floor_mat = "_LIQUID"
--    A.wall_mat  = "ASHWALL7"
  end


  if A.mode == "trap" and not A.is_outdoor then
    A.ceil_h = A.floor_h + 144
  end


  if A.is_outdoor then
    A.wall_mat = assert(A.zone.facade_mat)
  end


  if A.is_outdoor and not A.is_porch then
    A.ceil_mat = "_SKY"
  end


  A.wall_mat = A.wall_mat or A.floor_mat
  A.ceil_mat = A.ceil_mat or A.wall_mat

  --DEBUG FOR SECRETS
  if A.room and A.room.is_secret then
---  A.floor_mat = "REDWALL"
  end

--[[ ZONE TESTING
if A.mode != "hallway" then
if A.zone.id == 1 then A.floor_mat = "FWATER1" end
if A.zone.id == 2 then A.floor_mat = "NUKAGE1" end
if A.zone.id == 3 then A.floor_mat = "LAVA1" end
if A.zone.id == 4 then A.floor_mat = "CEIL5_2" end
end
--]]

  assert(A.wall_mat)
end



function Render_set_all_properties()
  each A in LEVEL.areas do
    Render_properties_for_area(A)
  end
end



------------------------------------------------------------------------


function Render_importants()

  local R  -- the current room


  local function calc_player_see_dist(spot, dir)
    local dx, dy = geom.delta(dir)
    local z = spot.z1 + 48

    local n = 1

    while n < 18 do
      local x2 = spot.mx + n * dx * 64
      local y2 = spot.my + n * dy * 64

      if gui.trace_ray(spot.mx, spot.my, z, x2, y2, z, "v") then
        break;
      end

      n = n + 1
    end

    local dist = (n - 1) / 3

--- stderrf("***** can_see_dist [%d] --> %1.2f\n", dir, dist)

    return dist

--[[ OLD SEED-BASED LOGIC
    -- returns # of whole seeds, zero if a wall directly nearby

    local R = S.area and S.area.room

    if not R then return 0 end

    local dist = 0

    while dist < 20 do
      local N = S:neighbor(dir, "NODIR")
      if not N then break; end

      -- step across a diagonal boundary
      if N == "NODIR" then
        N = S.top or S.bottom
        if N then N = S:neighbor(dir) end
        if not N then break; end
      end

      if (N.area and N.area.room) != R then break; end

      S = N ; dist = dist + 1.0
    end

stderrf("***** can_see_dist [%d] --> %d\n", dir, dist)
    return dist
--]]
  end


  local function player_dir(spot)
--[[
    local S = Seed_from_coord(spot.x, spot.y)

    -- hacky fix for diagonal seeds
    if not (S.area and S.area.room) and S.top then
      S = S.top
    end
--]]

    local D2 = calc_player_see_dist(spot, 2)
    local D4 = calc_player_see_dist(spot, 4)
    local D6 = calc_player_see_dist(spot, 6)
    local D8 = calc_player_see_dist(spot, 8)

    -- up against a wall?
    if D2 <= 1 and D8 > 1 then D8 = D8 * 1.8 end
    if D8 <= 1 and D2 > 1 then D2 = D2 * 1.8 end
    if D4 <= 1 and D6 > 1 then D6 = D6 * 1.8 end
    if D6 <= 1 and D4 > 1 then D4 = D4 * 1.8 end

    local D_max = math.max(D2, D4, D6, D8)

    if D2 < D_max and D4 < D_max and D6 < D_max then return 8 end
    if D2 < D_max and D4 < D_max and D8 < D_max then return 6 end
    if D2 < D_max and D6 < D_max and D8 < D_max then return 4 end
    if D4 < D_max and D6 < D_max and D8 < D_max then return 2 end

    -- more than one direction is maximal, break the tie
    for loop = 1,50 do
      if D2 == D_max and rand.odds(20) then return 2 end
      if D4 == D_max and rand.odds(20) then return 4 end
      if D6 == D_max and rand.odds(20) then return 6 end
      if D8 == D_max and rand.odds(20) then return 8 end
    end

    return rand.dir()
  end


  local function content_big_item(spot, item)
    local reqs =
    {
      kind  = "item"
      where = "point"
      size  = assert(spot.space)
    }

    if spot.goal and spot.goal.kind == "KEY" then
      reqs.item_kind = "key"
    end

    local def = Fab_pick(reqs)

    local skin1 = { object=item }

    local T = Trans.spot_transform(spot.mx, spot.my, spot.z1, spot.dir)

    Fabricate(R, def, T, { skin1 })

--- Trans.entity("light", spot.mx, spot.my, spot.z1+112, { cave_light=176 })
  end


  local function content_very_big_item(spot, item, is_weapon)
--[[  FIXME : LOWERING PEDESTALS

    -- sometimes make a lowering pedestal
    local prob = sel(is_weapon, 40, 20)

    if rand.odds(prob) and
       THEME.lowering_pedestal_skin and
       not S.chunk[2]
    then
      local mx, my = spot.x, spot.y
      local z1 = spot.z

      local z_top

      if R.kind == "cave" then
        z_top = z1 + rand.pick({ 64, 96 })

      else
        local z2 = S.ceil_h or S.room.ceil_h or (z1 + 256)

        if z2 < z1 + 170 then
          z_top = z1 + 64
        else
          z_top = z1 + 128
        end
      end

      Build.lowering_pedestal(S, z_top, THEME.lowering_pedestal_skin)

      Trans.entity(item, mx, my, z_top)
      Trans.entity("light", mx, my, z_top + 24, { cave_light=176 })

      return
    end
--]]

    content_big_item(spot, item)
  end


  local function content_start_pad(spot, dir)
    local reqs =
    {
      kind  = "start"
      where = "point"
      size  = assert(spot.space)
    }

    local def = Fab_pick(reqs)

    local T = Trans.spot_transform(spot.mx, spot.my, spot.z1, 10 - dir)

    Fabricate(R, def, T, { })
  end


  local function content_coop_pair(spot, dir)
    -- no prefab for this : add player entities directly

    local mx = spot.mx
    local my = spot.my
    local  z = spot.z1

    local angle = geom.ANGLES[dir]

    local dx, dy = geom.delta(dir)

    dx = dx * 24 ; dy = dy * 24

    Trans.entity(R.player_set[1], mx - dy, my + dx, z, { angle=angle })
    Trans.entity(R.player_set[2], mx + dy, my - dx, z, { angle=angle })

    if GAME.ENTITIES["player8"] then
      mx = mx - dx * 2
      my = my - dy * 2

      Trans.entity(R.player_set[3], mx - dy, my + dx, z, { angle=angle })
      Trans.entity(R.player_set[4], mx + dy, my - dx, z, { angle=angle })
    end
  end


  local function content_start(spot)
    local dir = player_dir(spot)

---???    if OB_CONFIG.game == "quake" then
---???      local skin = { floor="SLIP2", wall="SLIPSIDE" }
---???
---???      Build.quake_exit_pad(S, z1 + 16, skin, LEVEL.next_map)

    if R.player_set then
      content_coop_pair(spot, dir)

--[[
    elseif false and PARAM.raising_start and R.svolume >= 20 and
       R.kind != "cave" and
       THEME.raising_start_switch and rand.odds(25)
    then
      -- TODO: fix this
      gui.debugf("Raising Start made\n")

      local skin =
      {
        f_tex = S.f_tex or R.main_tex,
        switch_w = THEME.raising_start_switch,
      }

      Build.raising_start(S, 6, z1, skin)
      angle = 0

      S.no_floor = true
      S.raising_start = true
      R.has_raising_start = true
--]]
    else

      content_start_pad(spot, dir)
    end
  end


  local function content_exit(spot, secret_exit)
    local reqs =
    {
      kind  = "exit"
      where = "point"
      size  = assert(spot.space)
    }

    if secret_exit then
      reqs.key = "secret"
    end

    local def = Fab_pick(reqs)

    local skin1 = { }

    local dir = spot.dir or 2

    local T = Trans.spot_transform(spot.mx, spot.my, spot.z1, 10 - dir)

    Fabricate(R, def, T, { skin1 })
  end


  local function content_switch(spot)
    local reqs =
    {
      kind  = "switch"
      where = "point"
      size  = assert(spot.space)

      --??  switch = spot.goal.item
    }

    local def = Fab_pick(reqs)

    local skin1 = { }

    skin1.lock_tag = assert(spot.goal.tag)

    skin1.action = spot.goal.action  -- can be NIL

    local T = Trans.spot_transform(spot.mx, spot.my, spot.z1, spot.dir)

    Fabricate(R, def, T, { skin1 })
  end


  local function content_weapon(spot)
    local weapon = assert(spot.content_item)

    if R.is_start or R.kind == "hallway" then
      -- bare item
      Trans.entity(weapon, spot.mx, spot.my, spot.z1)
    else
      content_very_big_item(spot, weapon, "is_weapon")
    end

    gui.debugf("Placed weapon '%s' @ (%d,%d,%d)\n", weapon, spot.mx, spot.my, spot.z1)
  end


  local function content_item(spot)
    local item = assert(spot.content_item)

    if R.is_start or R.kind == "hallway" then
      -- bare item
      Trans.entity(item, spot.mx, spot.my, spot.z1)
    else
      content_big_item(spot, item)
    end
  end


  local function content_flag(spot)
    -- TODO : prefab for flag base

    content_big_item(spot, assert(spot.content_item))
  end


  local function content_teleporter(spot)
    local C = assert(spot.conn)

    local reqs =
    {
      kind  = "teleporter"
      where = "point"
      size  = assert(spot.space)
    }

    local def = Fab_pick(reqs)

    local skin1 = {}

    if C.R1 == R then
      skin1. in_tag = C.tele_tag2
      skin1.out_tag = C.tele_tag1
    else
      skin1. in_tag = C.tele_tag1
      skin1.out_tag = C.tele_tag2
    end

    skin1. in_target = string.format("tele%d", skin1. in_tag)
    skin1.out_target = string.format("tele%d", skin1.out_tag)

    local spot_dir = player_dir(spot)

    local T = Trans.spot_transform(spot.mx, spot.my, spot.z1, spot_dir)

    Fabricate(R, def, T, { skin1 })
  end


  local function content_mon_teleport(spot)
    -- creates a small sector with a tag and teleportman entity

    -- ignore unused spots [ can validly happen ]
    if not spot.tag then return end

    local r = 16

    local brush = brushlib.quad(spot.mx - r, spot.my - r, spot.mx + r, spot.my + r)

    -- mark as "no draw"
    each C in brush do
      C.draw_never = 1
    end

    local A = assert(spot.area)

    -- make it higher to ensure it doesn't get eaten by the floor brush
    -- (use delta_z to lower to real height)

    local top =
    {
      t = A.floor_h + 1
      delta_z = -1
      tag = assert(spot.tag)
    }

    table.insert(brush, top)

    brushlib.set_mat(brush, A.floor_mat, A.floor_mat)

    Trans.brush(brush)

    -- add teleport entity
    Trans.entity("teleport_spot", spot.mx, spot.my, top.t + 1)
  end


  local function build_important(spot)
    if spot.content_kind == "START" then
      content_start(spot)

    elseif spot.content_kind == "EXIT" then
      content_exit(spot)

    elseif spot.content_kind == "SECRET_EXIT" then
      content_exit(spot, "secret_exit")

    elseif spot.content_kind == "KEY" then
      content_very_big_item(spot, assert(spot.content_item))

    elseif spot.content_kind == "SWITCH" then
      content_switch(spot)

    elseif spot.content_kind == "WEAPON" then
      content_weapon(spot)

    elseif spot.content_kind == "ITEM" then
      content_item(spot)

    elseif spot.content_kind == "FLAG" then
      content_flag(spot)

    elseif spot.content_kind == "TELEPORTER" then
      content_teleporter(spot)

    elseif spot.content_kind == "MON_TELEPORT" then
      content_mon_teleport(spot)
    else
      error("unknown important: " .. tostring(spot.content_kind))
    end
  end


  local function build_trigger(spot)
    local r = spot.trigger.r

    local action = assert(spot.trigger.action)
    local tag    = assert(spot.trigger.tag)

    local brush = brushlib.quad(spot.mx - r, spot.my - r, spot.mx + r, spot.my + r)

    each C in brush do
      C.special = action
      C.tag     = tag
    end

    brushlib.set_kind(brush, "trigger")

    Trans.brush(brush)
  end


  local function build_a_crate(chunk)
    if chunk.sw < 2 then return end
    if chunk.sh < 2 then return end

    local A = chunk.area

    local floor_mat = A.floor_mat
    if not floor_mat then return end

    local reqs =
    {
      kind  = "decor"
      where = "point"

      size  = 96
      height = A.ceil_h - A.floor_h
    }

    local def = Fab_pick(reqs)
    local skin1 = { floor=floor_mat }
    local T = Trans.spot_transform(chunk.mx, chunk.my, A.floor_h, 2)

    if def.z_fit then
      Trans.set_fitted_z(T, A.floor_h, A.ceil_h)
    end

    Fabricate(A.room, def, T, { skin1 })
  end


  local function build_a_pool(chunk)
    if chunk.sw < 2 then return end
    if chunk.sh < 2 then return end

    local floor_mat = chunk.area.floor_mat
    if not floor_mat then return end

    local reqs =
    {
      kind  = "floor"
      where = "seeds"

      seed_w = chunk.sw
      seed_h = chunk.sh
    }

    local def = Fab_pick(reqs)
    local skin1 = { floor=floor_mat }

    local S1 = SEEDS[chunk.sx1][chunk.sy1]
    local S2 = SEEDS[chunk.sx2][chunk.sy2]

    local T = Trans.box_transform(S1.x1, S1.y1, S2.x2, S2.y2, chunk.area.floor_h, 2)

    Fabricate(chunk.area.room, def, T, { skin1 })

    -- only for pit test
    Render_mark_done(chunk, "floor")
  end


  ---| Render_importants |---

  each room in LEVEL.rooms do
    R = room

    each chunk in R.chunks do
      if chunk.content_kind then
        chunk.z1 = assert(chunk.area.floor_h)
        build_important(chunk)
      else
        -- temporary crap!!!
        if chunk.is_straddler then
          build_a_pool(chunk)
        else
          build_a_crate(chunk)
        end
      end
    end

    each chunk in R.closets do Render_chunk(chunk) end
    each chunk in R.stairs  do Render_chunk(chunk) end
    each chunk in R.joiners do Render_chunk(chunk) end

    -- TODO
    -- each spot in R.triggers do
    --   build_trigger(spot)
    -- end
  end
end


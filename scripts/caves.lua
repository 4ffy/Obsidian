----------------------------------------------------------------
--  CAVE GENERATION
----------------------------------------------------------------
--
--  Oblige Level Maker
--
--  Copyright (C) 2009-2010 Andrew Apted
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
----------------------------------------------------------------
--
--  The generation method used here was described by Jim Babcock
--  in his article: "Cellular Automata Method for Generating Random
--  Cave-Like Levels".
--
----------------------------------------------------------------

--[[ *** CLASS INFORMATION ***

class CAVE
{
  w, h   -- width and height (in cells)

  cells  -- ARRAY_2D : number  -- > 0 means solid
                               -- < 0 means empty

  flood  -- ARRAY_2D : number  -- contiguous areas will have the
                               -- same value (positive for solid
                               -- and negative for empty).

  empty_id  -- the main empty area in the flood_fill
               this is set by the validate_conns() method

  islands  -- LIST : CAVE
}

--------------------------------------------------------------]]


CAVE_CLASS = {}


function CAVE_CLASS.new(w, h)
  local cave = { w=w, h=h, cells = table.array_2D(w, h) }
  table.set_class(cave, CAVE_CLASS)
  return cave
end


function CAVE_CLASS.valid_cell(cave, x, y)
  return (1 <= x and x <= cave.w) and (1 <= y and y <= cave.h)
end


function CAVE_CLASS.get(cave, x, y)
  return cave.cells[x][y]
end


function CAVE_CLASS.set(cave, x, y, val)
  cave.cells[x][y] = val
end


function CAVE_CLASS.fill(cave, val, x1,y1, x2,y2)
  if not x1 then
    x1, x2 = 1,cave.w
    y1, y2 = 1,cave.h
  end

  for x = x1,x2 do for y = y1,y2 do
    cave.cells[x][y] = val
  end end
end


function CAVE_CLASS.negate(cave, x1,y1, x2,y2)
  if not x1 then
    x1, x2 = 1,cave.w
    y1, y2 = 1,cave.h
  end

  for x = x1,x2 do for y = y1,y2 do
    if cave.cells[x][y] then
      cave.cells[x][y] = - cave.cells[x][y]
    end
  end end

  return cave
end


function CAVE_CLASS.copy(cave)

  -- only copies 'w', 'h' and 'cells' members

  local newbie = CAVE_CLASS.new(cave.w, cave.h)

  for x = 1,cave.w do for y = 1,cave.h do
    newbie.cells[x][y] = cave.cells[x][y]
  end end

  return newbie
end


function CAVE_CLASS.dump(cave)
  for y = cave.h,1,-1 do
    local line = "@c| ";
    
    for x = 1,cave.w do
      local ch = " "
      local cell = cave.cells[x][y]
      if  cell == 0      then ch = "?" end
      if (cell or 0) > 0 then ch = "#" end
      if (cell or 0) < 0 then ch = "." end
      line = line .. ch
    end

    gui.debugf("%s\n", line)
  end

  gui.debugf("\n")
end


function CAVE_CLASS.union(cave, other)
  local W = math.min(cave.w, other.w)
  local H = math.min(cave.h, other.h)

  for x = 1,W do for y = 1,H do
    if (cave.cells[x][y] or 0) < 0 and
       (other.cells[x][y] or 0) > 0
    then
      cave.cells[x][y] = other.cells[x][y]
    end
  end end
end


function CAVE_CLASS.intersection(cave, other)
  local W = math.min(cave.w, other.w)
  local H = math.min(cave.h, other.h)

  for x = 1,W do for y = 1,H do
    if (cave.cells[x][y] or 0) > 0 and
       (other.cells[x][y] or 0) < 0
    then
      cave.cells[x][y] = other.cells[x][y]
    end
  end end
end


function CAVE_CLASS.subtract(cave, other)
  local W = math.min(cave.w, other.w)
  local H = math.min(cave.h, other.h)

  local empty_id = cave.empty_id or -1

  for x = 1,W do for y = 1,H do
    if (cave.cells[x][y] or 0) > 0 and
       (other.cells[x][y] or 0) > 0
    then
      cave.cells[x][y] = empty_id
    end
  end end
end


function CAVE_CLASS.generate(cave, solid_prob)

  -- The initial contents of the cave form a map where the cave
  -- will be generated.  The following values can be used:
  --
  --    nil : never touched
  --     -1 : forced off
  --      0 : computed normally
  --     +1 : forced on
  --
  -- Result elements can be: nil, -1 or +1.
  --

-- FIXME: support -2, +2 as 'forced' on, -1,+1 as initial values

  solid_prob = solid_prob or 40

  local W = cave.w
  local H = cave.h

  local map  = cave.cells

  -- these arrays only use 0 and 1 as values
  local work = table.array_2D(W, H)
  local temp = table.array_2D(W, H)

  -- populate initial map
  for x = 1,W do for y = 1,H do
    if not map[x][y] or map[x][y] < 0 then
      work[x][y] = 0
    elseif map[x][y] > 0 then
      work[x][y] = 1
    else
      work[x][y] = rand.sel(solid_prob, 1, 0)
    end
  end end

  local function calc_new(x, y, loop)
    if not map[x][y] then return 0 end
    if map[x][y] > 0 then return 1 end
    if map[x][y] < 0 then return 0 end

    if x == 1 or x == W or y == 1 or y == H then
      return work[x][y]
    end

    local neighbors = 0
    for nx = x-1,x+1 do for ny = y-1,y+1 do
      neighbors = neighbors + work[nx][ny]
    end end

    if neighbors >= 5 then return 1 end

    if loop >= 5 then return 0 end

    if x <= 2 or x >= W-1 or y <= 2 or y >= H-1 then return 0 end

    -- check larger area
    local neighbors = 0
    for nx = x-2,x+2 do for ny = y-2,y+2 do
      if math.abs(x-nx) == 2 and math.abs(y-ny) == 2 then
        -- skip the corners of the 5x5 block
      else
        neighbors = neighbors + work[nx][ny]
      end
    end end

    if neighbors <= 2 then return 1 end

    return 0
  end

  -- perform the cellular automation steps
  for loop = 1,7 do
    for x = 1,W do for y = 1,H do
      temp[x][y] = calc_new(x, y, loop)
    end end

    work, temp = temp, work
  end

  -- convert values for the result
  for x = 1,W do for y = 1,H do
    if map[x][y] == 0 then
      work[x][y] = sel(work[x][y] > 0, 1, -1)
    else
      work[x][y] = map[x][y]
    end
  end end

  cave.cells = work
end


function CAVE_CLASS.gen_empty(cave)
  
  -- this is akin to generate(), but making all target cells empty

  local W = cave.w
  local H = cave.h

  local cells = cave.cells

  for x = 1,W do for y = 1,H do
    if not cells[x][y] then
      -- skip it
    elseif cells[x][y] > 0 then
      cells[x][y] = 1
    else
      cells[x][y] = -1
    end
  end end

  return cave
end


function CAVE_CLASS.flood_fill(cave)
  -- generate the 'flood' member, an array where each contiguous region
  -- has a unique id.  Empty areas are negative, Solid areas use positive.
  -- Zero is invalid.  Nil cells remain nil.

  local W = cave.w
  local H = cave.h

  local cells = cave.cells
  local flood = table.array_2D(W, H)

  local solid_id =  1
  local empty_id = -1

  local next_points = {}

  local function flood_point(x, y)

    -- spread value from this cell to neighbors

    local A = flood[x][y]
    assert(A)

    for side = 2,8,2 do
      local nx, ny = geom.nudge(x, y, side)
      if nx >= 1 and nx <= W and ny >= 1 and ny <= H then
        local B = flood[nx][ny]

        if B and ((A > 0 and A < B) or (A < 0 and A > B)) then
          flood[nx][ny] = A
          table.insert(next_points, { x=nx, y=ny })
        end
      end
    end
  end

--[[
  local function update_info(x, y)
    local f = flood[x][y]
    if not f then return end

    if f < 0 then
      flood.empty_cells = flood.empty_cells + 1
    else
      flood.solid_cells = flood.solid_cells + 1
    end

    local reg = flood.regions[f]

    if not reg then
      reg =
      {
        id = f,
        x1 = x, y1 = y,
        x2 = x, y2 = y,
        cells = 0,
      }

      flood.regions[f] = reg

      if f < 0 then
        flood.empty_regions = flood.empty_regions + 1
      else
        flood.solid_regions = flood.solid_regions + 1
      end
    end

    if x < reg.x1 then reg.x1 = x end
    if y < reg.y1 then reg.y1 = y end
    if x > reg.x2 then reg.x2 = x end
    if y > reg.y2 then reg.y2 = y end

    reg.cells = reg.cells + 1
  end
--]]

  -- initial setup

  for x = 1,W do for y = 1,H do
    if not cells[x][y] then
      -- ignore it
    elseif cells[x][y] < 0 then
      flood[x][y] = empty_id ; empty_id = empty_id - 1
    else
      flood[x][y] = solid_id ; solid_id = solid_id + 1
    end
  end end

  -- perform the flood-fill

  for x = 1,W do for y = 1,H do
    if flood[x][y] then
      flood_point(x, y)
    end
  end end

  while #next_points > 0 do
    local np_list = next_points ; next_points = {}

    for _,P in ipairs(np_list) do
      flood_point(P.x, P.y)
    end
  end

--[[
  -- create information for each region
  flood.regions = {}

  flood.empty_cells = 0
  flood.solid_cells = 0
  flood.empty_regions = 0
  flood.solid_regions = 0

  for x = 1,W do for y = 1,H do
    update_info(x, y)
  end end

  -- find largest regions
  for what,reg in pairs(flood.regions) do
    if what < 0 then
      if not flood.largest_empty or reg.cells > flood.largest_empty.cells then
        flood.largest_empty = reg
      end
    else
      if not flood.largest_solid or reg.cells > flood.largest_solid.cells then
        flood.largest_solid = reg
      end
    end
  end
--]]

  cave.flood = flood
end


function CAVE_CLASS.validate_conns(cave, point_list)

  -- checks that all connections can reach each other.

  local empty_id = nil

  if not cave.flood then
    cave:flood_fill()
  end

  for _,P in ipairs(point_list) do
    if (cave.flood[P.x][P.y] or 0) >= 0 then
      -- not valid : the cell is solid or absent
      return false
    end

    local reg = cave.flood[P.x][P.y]

    if not empty_id then
      empty_id = reg
    elseif empty_id ~= reg then
      -- not valid : the empty areas are disjoint
      return false
    end
  end -- P

  cave.empty_id = empty_id

  return true
end


---???  function CAVE_CLASS.solidify_other_empties(cave)


function CAVE_CLASS.copy_island(cave, reg_id)
  local W = cave.w
  local H = cave.h

  local flood = assert(cave.flood)

  local island = CAVE_CLASS.new(cave.w, cave.h)

  for x = 1,W do for y = 1,H do
    local val = flood[x][y]
    if val == nil then
      -- nothing to copy
    else
      island.cells[x][y] = sel(val == reg_id, 1, -1)
    end
  end end

island:dump("Island for " .. tostring(reg_id))

  return island
end


function CAVE_CLASS.find_islands(cave)
  
  -- an "island" is contiguous solid area which never touches NIL

  local islands = {}

  local W = cave.w
  local H = cave.h

  if not cave.flood then
    cave:flood_fill()
  end

  local flood = cave.flood

  -- scan the cave, determine which regions are islands

  -- a table mapping region ids to a string value: "maybe" if could be
  -- an island, and "no" when definitely not an island. 
  local potentials = {}

  for x = 1,W do for y = 1,H do
    local reg = flood[x][y]
    if (reg or 0) > 0 then

      if not potentials[reg] then
        potentials[reg] = "maybe"
      end

      if x == 1 or x == W or y == 1 or y == H then
        potentials[reg] = "no"
      end

      if potentials[reg] ~= "no" then
        for side = 2,8,2 do
          local nx, ny = geom.nudge(x, y, side)
          if cave:valid_cell(nx, ny) and flood[nx][ny] == nil then
            potentials[reg] = "no"
            break;
          end
        end
      end

    end
  end end

  -- create the islands

  for reg,pot in pairs(potentials) do
    if pot == "maybe" then
      table.insert(islands, cave:copy_island(reg))
    end
  end

  cave.islands = islands
end


--TODO
function CAVE_CLASS.main_empty_region(cave)

  -- find the largest empty region

  local empty_reg = flood.largest_empty

  if not empty_reg then
    return
  end

  -- size check
  local W = flood.w
  local H = flood.h

  local size_ok = true

  local size_x = empty_reg.x2 - empty_reg.x1 + 1
  local size_y = empty_reg.y2 - empty_reg.y1 + 1

  if (size_x*1.6 < W and size_y*1.6 < H) or
     (size_x*3.2 < W or  size_y*3.2 < H) then
    size_ok = false
  end 

  return empty_reg, size_ok
end


function CAVE_CLASS.grow(cave)
  -- grow the cave : it will have more solids, less empties.
  -- nil cells are not affected.

  local W = cave.w
  local H = cave.h

  local work = table.array_2D(W, H)
  local cells = cave.cells

  local function handle_neighbor(x, y, side)
    local nx, ny = geom.nudge(x, y, side)
    
    if nx < 1 or nx > W or ny < 1 or ny > H then
      return
    end

    if (cells[nx][ny] or 0) < 0 then
      work[nx][ny] = cells[x][y]
    end
  end

  for x = 1,W do for y = 1,H do
    work[x][y] = cells[x][y]

    if (cells[x][y] or 0) > 0 then
      for side = 2,8,2 do
        handle_neighbor(x, y, side)
      end
    end
  end end

  cave.cells = work
end


function CAVE_CLASS.shrink(cave, keep_edges)
  -- shrink the cave : it will have more empties, less solids.
  -- when 'keep_edges' is true, cells at edges are not touched.
  -- nil cells are not affected.

  local W = cave.w
  local H = cave.h

  local work = table.array_2D(W, H)
  local cells = cave.cells

  local SIDES = { 2,4,6,8 }

  local function value_for_spot(x, y)
    rand.shuffle(SIDES)

    local hit_edge = false

    for _,side in ipairs(SIDES) do
      local nx, ny = geom.nudge(x, y, side)
    
      if nx < 1 or nx > W or ny < 1 or ny > H or not cells[nx][ny] then
        hit_edge = true
      elseif cells[nx][ny] < 0 then
        return cells[nx][ny]
      end
    end

    if hit_edge and not keep_sides then
      return nil
    end

    return cells[x][y]
  end

  for x = 1,W do for y = 1,H do
    if (cells[x][y] or 0) > 0 then
      work[x][y] = value_for_spot(x, y)
    else
      work[x][y] = cells[x][y]
    end
  end end

  cave.cells = work
end


function CAVE_CLASS.remove_dots(cave, keep_edges, callback)
  -- removes isolated solid cells from the cave.
  -- diagonal cells are NOT checked.

  local W = cave.w
  local H = cave.h

  local cells = cave.cells

  local function is_isolated(x, y)
    local count = 0

    for side = 2,8,2 do
      local nx, ny = geom.nudge(x, y, side)

      if nx < 1 or nx > W or ny < 1 or ny > H or not cells[nx][ny] then
        if keep_edges then return false end
      elseif cells[nx][ny] > 0 then
        count = count + 1
      end
    end

    return (count == 0)
  end

  for x = 1,W do for y = 1,H do
    if is_isolated(x, y) then
      local dx = sel(x > W/2, -1, 1)
      cells[x][y] = cells[x+dx][y]
      if callback then
        callback(cave, x, y)
      end
    end
  end end
end


function CAVE_CLASS.is_land_locked(cave, x, y)
  if x <= 1 or x >= cave.w or y <= 1 or y >= cave.h then
    return false
  end

  local cells = cave.cells

  for dx = -1,1 do for dy = -1,1 do
    if (cells[x+dx][y+dy] or 0) < 0 then
      return false
    end
  end end

  return true
end


function CAVE_CLASS.is_empty_locked(cave, x, y)
  if x <= 1 or x >= cave.w or y <= 1 or y >= cave.h then
    return false
  end

  local cells = cave.cells

  for dx = -1,1 do for dy = -1,1 do
    if (cells[x+dx][y+dy] or 0) >= 0 then
      return false
    end
  end end

  return true
end


function CAVE_CLASS.distance_map(cave, ref_points)
  assert(cave.flood)
  assert(cave.empty_id)

  local W = cave.w
  local H = cave.h

  local work = table.array_2D(W, H)
  local flood = cave.flood

  local next_points = {}

  local function flood_point(x, y)

    -- spread this distance into neighbor cells
    local dist = work[x][y] + 1

    for side = 2,8,2 do
      local nx, ny = geom.nudge(x, y, side)
      if nx >= 1 and nx <= W and ny >= 1 and ny <= H then
        local F = flood[nx][ny]
        local W =  work[nx][ny]

        if F == cave.empty_id and (not W or W > dist) then
          flood[nx][ny] = dist
          table.insert(next_points, { x=nx, y=ny })
        end
      end
    end
  end

  -- perform the fill

  for _,P in ipairs(ref_points) do
    work[P.x][P.y] = 0
    flood_point(P.x, P.y)
  end

  while #next_points > 0 do
    local np_list = next_points ; next_points = {}

    for _,P in ipairs(np_list) do
      flood_point(P.x, P.y)
    end
  end

  return work
end


function CAVE_CLASS.furthest_point(cave, ref_points)
  local dist_map = cave:distance_map(ref_points)

  local best_x, best_y
  local best_dist = 9e9

  for x = 1,W do for y = 1,H do
    local dist = dist_map[x][y]
    if dist and dist < (best_dist+3) then

      -- prefer away from edges
      if x == 1 or x == W then dist = dist + 0.1 end
      if y == 1 or y == H then dist = dist + 0.2 end

      -- prefer a spot away from the wall
      if cave:is_empty_locked(x, y) then
        dist = dist - 2.4
      end

      if dist < best_dist then
        best_x, best_y = x, y
        best_dist = dist
      end

    end
  end end

  return best_x, best_y  -- could be nil !
end


function CAVE_CLASS.render(cave, base_x, base_y, brush_func, data, square_caves)

  -- TODO: make base_x/y and square_caves a class field ??

  local W = cave.w
  local H = cave.h

  local cells = cave.cells

  local corner_map = table.array_2D(W + 1, H + 1)

  local function analyse_corner(corner_map, x, y, side)
    local dx, dy = geom.delta(side)

    local cx = x + sel(dx < 0, 0, 1)
    local cy = y + sel(dy < 0, 0, 1)

    if corner_map[cx][cy] then return end  -- already decided

    local function test_nb(dx, dy)
      local nx = x + dx
      local ny = y + dy

      if nx < 1 or nx > W or ny < 1 or ny > H then return true end

      return not cells[nx][ny] or (cells[nx][ny] > 0)
    end

    local A = test_nb(0, dy)
    local B = test_nb(dx, 0)
    local C = test_nb(dx, dy)

    if C then return end

    if not A and not B then

      if test_nb(-dx, 0) and test_nb(0, -dy) and rand.odds(70) then
        corner_map[cx][cy] = "drop"
        return
      end

      corner_map[cx][cy] = rand.pick { "x", "y", "xy", "split" }
      return
    end

    if A and not B then
      if rand.odds(40) then corner_map[cx][cy] = "x" end
      return
    end

    if B and not A then
      if rand.odds(40) then corner_map[cx][cy] = "y" end
      return
    end

    -- assert(A and B and not C)

    if rand.odds(1) then corner_map[cx][cy] = "split" end
    return
  end


  local function add_brush(corner_map, x, y, bx, by)
    bx = bx + (x - 1) * 64
    by = by + (y - 1) * 64

    -- most basic method (mostly for debugging)
    if square_caves then
      brush_func(data,
      {
        { x=bx+64, y=by },
        { x=bx+64, y=by+64 },
        { x=bx,    y=by+64 },
        { x=bx,    y=by },
      })

      return;
    end

    local coords = { }
    local SIDES  = { 1,3,9,7 }

    for _,side in ipairs(SIDES) do
      local dx, dy = geom.delta(side)

      local cx = x + sel(dx < 0, 0, 1)
      local cy = y + sel(dy < 0, 0, 1)

      local fx = bx + sel(dx < 0, 0, 64)
      local fy = by + sel(dy < 0, 0, 64)

      local what = corner_map[cx][cy]

      if what == "drop" then
        -- ignore it

      elseif what == "split" then
        if side == 1 or side == 9 then
          table.insert(coords, { x=fx, y=fy-dy*24 })
          table.insert(coords, { x=fx-dx*24, y=fy })
        else
          table.insert(coords, { x=fx-dx*24, y=fy })
          table.insert(coords, { x=fx, y=fy-dy*24 })
        end

      else
        if what == "x" then fx = fx - dx*24 end
        if what == "y" then fy = fy - dy*24 end

        if what == "xy" then
          fx = fx - dx*16
          fy = fy - dy*16
        end

        table.insert(coords, { x=fx, y=fy })
      end
    end

  --- gui.debugf("CAVE BRUSH:\n%s\n\n", table.tostr(coords,2))

    brush_func(data, coords)
  end


  ---| Cave.render |---

  for x = 1,W do for y = 1,H do
    if (cells[x][y] or 0) > 0 then
      for side = 1,9,2 do if side ~= 5 then
        analyse_corner(corner_map, x, y, side)
      end end
    end
  end end -- for x, y

  for x = 1,W do for y = 1,H do
    if (cells[x][y] or 0) > 0 then
      add_brush(corner_map, x, y, base_x, base_y)
    end
  end end
end


---------------------------------------------------------------------


function Cave_build_room(R)

do return end --!!!!!!!!!  FIXME CAVES

  local cave  = R.cave

  local w_tex  = R.cave_tex
  local w_info = get_mat(w_tex)
  local high_z = EXTREME_H

  local base_x = SECTIONS[R.kx1][R.ky1].x1
  local base_y = SECTIONS[R.kx1][R.ky1].y1

  local function WALL_brush(data, coords)
    if data.shadow_info then
      local sh_coords = shadowify_brush(coords, 40)
--!!!!      Trans.old_brush(data.shadow_info, sh_coords, -EXTREME_H, (data.z2 or EXTREME_H) - 4)
    end

    if data.f_z then table.insert(coords, { t=data.f_z, delta_z=data.delta_f }) end
    if data.c_z then table.insert(coords, { b=data.c_z, delta_z=data.delta_c }) end

    Trans.set_mat(coords, data.wtex, data.ftex)

    Trans.brush(coords)
  end

  local function FC_brush(data, coords)
    if data.f_info then
      local coord2 = table.deep_copy(coords)
      table.insert(coord2, { t=data.f_z, delta_z=data.delta_f })

      Trans.set_mat(coord2, data.wtex, data.ftex)
      Trans.brush(coord2)
    end

    if data.c_info then
      local coord2 = table.deep_copy(coords)
      table.insert(coord2, { b=data.c_z, delta_z=data.delta_c })

      Trans.set_mat(coords, data.wtex, data.ctex)
      Trans.brush(coord2)
    end
  end

  local function choose_tex(last, tab)
    local tex = rand.key_by_probs(tab)

    if last then
      for loop = 1,5 do
        if not Mat_similar(last, tex) then break; end
        tex = rand.key_by_probs(tab)
      end
    end

    return tex
  end

  -- DO WALLS --

  local data = { info=w_info, wtex=w_tex, ftex=w_tex, ctex=w_tex }

  if R.is_lake then
    data.info = Mat_liquid()
    data.delta_f = rand.sel(70, -48, -72)
    data.f_z = R.cave_floor_h + 8
    data.ftex = data.info.t_face.tex -- TEMP CRUD
  end

  if R.outdoor and not R.is_lake and R.cave_floor_h + 144 < SKY_H and rand.odds(88) then
    data.f_z = R.cave_floor_h + rand.sel(65, 80, 144)
  end

  if PARAM.outdoor_shadows and R.outdoor and not R.is_lake then
--!!!!!    data.shadow_info = get_light(-1)
  end

  -- grab walkway now (before main cave is modified)

  local walkway = cave:copy_island(cave.empty_id)


  -- handle islands first

  for _,island in ipairs(cave.islands) do

    -- FIXME
    if LEVEL.liquid and not R.is_lake and --[[ reg.cells > 4 and --]]
       rand.odds(50)
    then

      -- create a lava/nukage pit
      local pit = Mat_liquid()

      island:render(base_x, base_y, WALL_brush,
                    { f_z=R.cave_floor_h+8, ftex=pit.t_face.tex,
                      delta_f=rand.sel(70, -52, -76) })

      cave:subtract(island)
    end
  end


  cave:render(base_x, base_y, WALL_brush, data, THEME.square_caves)


  if R.is_lake then return end
  if THEME.square_caves then return end
  if PARAM.simple_caves then return end


  local ceil_h = R.cave_floor_h + R.cave_h

  -- TODO: @ pass 3, 4 : come back up (ESP with liquid)

  local last_ftex = R.cave_tex

  for i = 1,rand.index_by_probs({ 10,10,70 })-1 do
    walkway:shrink(false)

---???    if rand.odds(sel(i==1, 20, 50)) then
---???      walkway:shrink(false)
---???    end

    walkway:remove_dots()

    -- DO FLOOR and CEILING --

    data = {}


    if R.outdoor then
      data.ftex = choose_tex(last_ftex, THEME.landscape_trims or THEME.landscape_walls)
    else
      data.ftex = choose_tex(last_ftex, THEME.cave_trims or THEME.cave_walls)
    end

    last_ftex = data.ftex

    data.f_info = get_mat(data.ftex)

    if LEVEL.liquid and i==2 and rand.odds(60) then  -- TODO: theme specific prob
      data.f_info = get_liquid()

      -- FIXME: this bugs up monster/pickup/key spots
      if rand.odds(0) then
        data.delta_f = -(i * 10 + 40)
      end
    end

    if true then
      data.delta_f = -(i * 10)
    end

    data.f_z = R.cave_floor_h + i
    data.ftex = data.f_info.t_face.tex

    data.c_info = nil

    if not R.outdoor then
      data.c_info = w_info

      if i==2 and rand.odds(60) then
        data.c_info = Mat_sky()
      elseif rand.odds(50) then
        data.c_info = get_mat(data.ftex)
      elseif rand.odds(80) then
        data.ctex = choose_tex(data.ctex, THEME.cave_trims or THEME.cave_walls)
        data.c_info = get_mat(data.ctex)
      end

      data.delta_c = int((0.6 + (i-1)*0.3) * R.cave_h)

      data.c_z = ceil_h - i
    end


    walkway:render(base_x, base_y, FC_brush, data)
  end
end


function OLD__Rooms_do_small_exit()
  local C = R.conns[1]
  local T = C:seed(C:neighbor(R))
  local out_combo = T.room.main_tex
  if T.room.outdoor then out_combo = R.main_tex end

  -- FIXME: use single one over a whole episode
  local skin_name = rand.key_by_probs(THEME.small_exits)
  local skin = assert(GAME.EXITS[skin_name])

  local skin2 =
  {
    wall = out_combo,
    floor = T.f_tex or C.conn_ftex,
    ceil = out_combo,
  }

  assert(THEME.exit.switches)
  -- FIXME: hacky
  skin.switch = rand.key_by_probs(THEME.exit.switches)

--!!!!!!  Build.small_exit(R, THEME.exit, skin, skin2)

  local skin = table.copy(assert(GAME.EXITS["tech_small"]))
  skin.inner = w_tex
  skin.outer = o_tex

  local T = Trans.doorway_transform(S, z1, 8)
  Trans.modify("scale_x", 192 / 256)
  Trans.modify("scale_y", 192 / 256)

  ttfn_fabricate("SMALL_EXIT", T, { skin })

  return
end


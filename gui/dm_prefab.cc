//------------------------------------------------------------------------
//  DOOM PREFAB loader
//------------------------------------------------------------------------
//
//  Oblige Level Maker
//
//  Copyright (C) 2012 Andrew Apted
//
//  This program is free software; you can redistribute it and/or
//  modify it under the terms of the GNU General Public License
//  as published by the Free Software Foundation; either version 2
//  of the License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//------------------------------------------------------------------------
//
//  A.P.I
//  =====
//  
//  wadfab_load(name)
//  --> no result, raises error on failure
//  
//  wadfab_free()
//  --> no result
//  
//  wadfab_get_polygon(index)
//  -->  sector_num, { {x=#,y=#,side=# } ... }
//  
//  wadfab_get_sector(index)
//  -->  { floor_h=#, floor_tex="...",
//          ceil_h=#,  ceil_tex="...",
//         special=#, tag=#, light=#
//       }
//  
//  wadfab_get_side(index)
//  -->  { upper_tex="", mid_tex="", lower_tex="",
//         x_offset=#, y_offset=#
//       }
// 
//  wadfab_get_line(index)
//  -->  { special=#, tag=#, flags=# }
//  
//  wadfab_get_thing(index)
//  -->  { id=#, x=#, y=#, angle=#, flags=# }
//
//------------------------------------------------------------------------

#include "headers.h"
#include "hdr_fltk.h"
#include "hdr_lua.h"
#include "hdr_ui.h"

#include "ajpoly.h"

#include "lib_file.h"
#include "lib_util.h"
#include "lib_wad.h"

#include "main.h"
#include "m_lua.h"

#include "csg_main.h"

#include "dm_prefab.h"
#include "g_doom.h"


// callbacks for AJ-Polygonator

void Appl_FatalError(const char *str, ...)
{
  // FIXME
}

void Appl_Printf(const char *str, ...)
{
  // FIXME
}


int wadfab_free(lua_State *L)
{
  ajpoly::CloseMap();
  ajpoly::FreeWAD();

  return 0;
}


int wadfab_load(lua_State *L)
{
  const char *name = luaL_checkstring(L, 1);

  char filename[PATH_MAX];

  sprintf(filename, "%s/x_doom/%s", home_dir, name);

  // check home directory, if not found then try install dir
  if (! FileExists(filename))
    sprintf(filename, "%s/x_doom/%s", install_dir, name);

  if (! FileExists(filename))
    return luaL_error(L, "wadfab_load: no such file: %s", name);

  if (! ajpoly::LoadWAD(filename))
    return luaL_error(L, "wadfab_load: %s", ajpoly::GetError());

  if (! ajpoly::OpenMap("*" /* first one */))
    return luaL_error(L, "wadfab_load: %s", ajpoly::GetError());

  return 0;
}


//------------------------------------------------------------------------


static void push_char8(lua_State *L, const char * buf)
{
  size_t len = 0;

  while (len < 8 && buf[len] != 0)
    len++;

  lua_pushlstring(L, buf, len);
}


int wadfab_get_thing(lua_State *L)
{
  int index = luaL_checkint(L, 1);

  if (index < 0 || index >= ajpoly::num_things)
    return 0;

  const ajpoly::thing_c * T = ajpoly::Thing(index);

  lua_newtable(L);

  lua_pushinteger(L, T->x);
  lua_setfield(L, -2, "x");

  lua_pushinteger(L, T->y);
  lua_setfield(L, -2, "y");

  lua_pushinteger(L, T->angle);
  lua_setfield(L, -2, "angle");

  lua_pushinteger(L, T->type);
  lua_setfield(L, -2, "id");

  lua_pushinteger(L, T->options);
  lua_setfield(L, -2, "flags");

  return 1;
}


int wadfab_get_sector(lua_State *L)
{
  int index = luaL_checkint(L, 1);

  if (index < 0 || index >= ajpoly::num_sectors)
    return 0;

  const ajpoly::sector_c * S = ajpoly::Sector(index);

  lua_newtable(L);

  lua_pushinteger(L, S->floor_h);
  lua_setfield(L, -2, "floor_h");

  lua_pushinteger(L, S->ceil_h);
  lua_setfield(L, -2, "ceil_h");

  lua_pushinteger(L, S->special);
  lua_setfield(L, -2, "special");

  lua_pushinteger(L, S->light);
  lua_setfield(L, -2, "light");

  lua_pushinteger(L, S->tag);
  lua_setfield(L, -2, "tag");

  lua_pushstring(L, S->floor_tex);
  lua_setfield(L, -2, "floor_tex");

  lua_pushstring(L, S->ceil_tex);
  lua_setfield(L, -2, "ceil_tex");

  return 1;
}


int wadfab_get_side(lua_State *L)
{
  int index = luaL_checkint(L, 1);

  if (index < 0 || index >= ajpoly::num_sides)
    return 0;

  const raw_sidedef_t * side = &friz_sides[index];

  int x_offset = LE_S16(side->x_offset);
  int y_offset = LE_S16(side->y_offset);

  lua_newtable(L);

  lua_pushinteger(L, x_offset);
  lua_setfield(L, -2, "x_offset");

  lua_pushinteger(L, y_offset);
  lua_setfield(L, -2, "y_offset");

  push_char8(L, side->upper_tex);
  lua_setfield(L, -2, "upper_tex");

  push_char8(L, side->lower_tex);
  lua_setfield(L, -2, "lower_tex");

  push_char8(L, side->mid_tex);
  lua_setfield(L, -2, "mid_tex");

  return 1;
}


int wadfab_get_line(lua_State *L)
{
  int index = luaL_checkint(L, 1);

  if (index < 0 || index >= ajpoly::num_lines)
    return 0;

  const raw_linedef_t * line = &friz_lines[index];

  int special = LE_S16(line->type);
  int   flags = LE_S16(line->flags);
  int     tag = LE_S16(line->tag);

  lua_newtable(L);

  lua_pushinteger(L, special);
  lua_setfield(L, -2, "special");

  lua_pushinteger(L, flags);
  lua_setfield(L, -2, "flags");

  lua_pushinteger(L, tag);
  lua_setfield(L, -2, "tag");

  return 1;
}


static int side_for_seg(const raw_ho_seg_t * seg, bool opposite = false)
{
  int ld = LE_S16(seg->linedef);

  if (ld < 0) // miniseg?
    return -1;

  if (ld >= ajpoly::num_lines)
    return -1; //??? Main_FatalError("wadfab_get_polygon: bad linedef #%d", ld);

  const raw_linedef_t * line = &friz_lines[ld];

  int sd;

  if ((seg->side ? true : false) != opposite)
    sd = LE_S16(line->sidedef2);
  else
    sd = LE_S16(line->sidedef1);

  // an absent side does not normally occur
  if (sd < 0 || sd >= ajpoly::num_sides)
    return -1;

  return sd;
}


static void push_ho_seg(lua_State *L, int tab_index, const raw_ho_seg_t * seg)
{
  lua_newtable(L);

  int v_idx = LE_U16(seg->end);

  double x, y;

  if (v_idx & IS_GL_VERT)
  {
    v_idx ^= IS_GL_VERT;

    if (v_idx >= ajpoly::num_ho_verts)
      luaL_error(L, "wadfab_get_polygon: bad GL vertex #%d", v_idx);

    const raw_ho_vertex_t * vert = &friz_ho_verts[v_idx];

    x = LE_S32(vert->x) / 65536.0;
    y = LE_S32(vert->y) / 65536.0;
  }
  else
  {
    if (v_idx >= ajpoly::num_verts)
      luaL_error(L, "wadfab_get_polygon: bad vertex #%d", v_idx);

    const raw_vertex_t * vert = &friz_verts[v_idx];

    x = LE_S16(vert->x);
    y = LE_S16(vert->y);
  }

  lua_pushnumber(L, x);
  lua_setfield(L, -2, "x");

  lua_pushnumber(L, y);
  lua_setfield(L, -2, "y");

  int ld = LE_S16(seg->linedef);

  if (ld >= 0 && ld < ajpoly::num_lines)
  {
    lua_pushinteger(L, ld);
    lua_setfield(L, -2, "line");
  }

  int sd = side_for_seg(seg, true /* opposite */);

  if (sd < 0)
    sd = side_for_seg(seg, false);

  if (sd >= 0)
  {
    lua_pushinteger(L, sd);
    lua_setfield(L, -2, "side");
  }

  lua_rawseti(L, -2, tab_index);
}


int wadfab_get_polygon(lua_State *L)
{
  int index = luaL_checkint(L, 1);

  if (index < 0 || index >= ajpoly::num_polygons)
    return 0;

  const raw_ho_subsec_t * sub = &friz_polygons[index];

  int sect_id   = LE_U16(sub->sector);
  int seg_num   = LE_U16(sub->num);
  int seg_first = LE_U16(sub->first);

  if (seg_num <= 0 || seg_first + seg_num > ajpoly::num_ho_segs)
    return luaL_error(L, "wadfab_get_polygon: bad GL-subsector #%d", index);

  const raw_ho_seg_t * seg = &friz_ho_segs[seg_first];

  if (sect_id == 0xFFFF)
    sect_id = -1;

  // result #1 : SECTOR
  lua_pushinteger(L, sect_id);

  // result #2 : COORDS
  lua_createtable(L, seg_num, 0);

  for (int tab_index = 1 ; tab_index <= seg_num ; tab_index++)
  {
    // GL subsectors are clockwise, but OBLIGE are anti-clockwise.
    // hence reverse the order.  We also use 'end' instead of 'start'.

    push_ho_seg(L, tab_index, seg + (seg_num - tab_index));
  }

  return 2;
}


//--- editor settings ---
// vi:ts=2:sw=2:expandtab

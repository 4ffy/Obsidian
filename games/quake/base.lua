------------------------------------------------------------------------
--  BASE FILE for QUAKE
------------------------------------------------------------------------
--
--  Oblige Level Maker
--
--  Copyright (C) 2006-2015 Andrew Apted
--  Copyright (C)      2011 Chris Pisarczyk
--
--  This program is free software; you can redistribute it and/or
--  modify it under the terms of the GNU General Public License
--  as published by the Free Software Foundation; either version 2,
--  of the License, or (at your option) any later version.
--
--  This program is distributed in the hope that it will be useful,
--  but WITHOUT ANY WARRANTY; without even the implied warranty of
--  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--  GNU General Public License for more details.
--
------------------------------------------------------------------------

QUAKE = { }


------------------------------------------------------------

gui.import("entities")
gui.import("monsters")
gui.import("pickups")
gui.import("weapons")
gui.import("shapes")
gui.import("materials")
gui.import("themes")
gui.import("levels")
gui.import("resources")

------------------------------------------------------------

OB_GAMES["quake"] =
{
  label = _("Quake"),
  priority = 27,

  format = "quake",
  game_dir = "quake",

  use_generics = true,

  tables =
  {
    QUAKE
  },

  hooks =
  {
    get_levels  = QUAKE.get_levels,
    begin_level = QUAKE.begin_level
  },
}


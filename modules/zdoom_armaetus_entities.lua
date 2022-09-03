----------------------------------------------------------------
--  MODULE: Obsidian Resource Pack Entities
----------------------------------------------------------------
--
--  Copyright (C) 2019-2022 MsrSgtShooterPerson
--  Copyright (C) 2022 Demios
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
------------------------------------------------------------------

ORP_ENTITIES = {}

ORP_ENTITIES.DECORATE =
[[Actor blood_pack 27000
{
  +FloorClip
  Radius 32
  Height 64
  States
  {
  Spawn:
    BLDP A -1
    Stop
  }
}

ACTOR burning_top 27001
{
  States
  {
  Spawn:
    FTOP ABC 4 Bright
    Loop
  }
}

ACTOR burning_debris 27002
{
  States
  {
  Spawn:
    FDEB ABC 4 Bright
	Loop
  }
}
]]

---------------------------------------------------------------
--  MODULE: Chex Quest 3 Control
----------------------------------------------------------------
--
--  Copyright (C) 2009-2010 Andrew Apted
--  Copyright (C) 2020-2021 MsrSgtShooterPerson
--  Copyright (C) 2021 Cubebert
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
----------------------------------------------------------------

CTL_CHEX3 = {}

function CTL_CHEX3.monster_setup(self)

  for _,opt in pairs(self.options) do
    PARAM[opt.name] = gui.get_module_slider_value(self.name, opt.name)

    local M = GAME.MONSTERS[string.sub(opt.name, 7)]

    if M and PARAM[opt.name] ~= "Default" then
      M.prob    = PARAM[opt.name] * 100
      M.density = M.prob * .006 + .1

      -- allow Spectres to be controlled individually
      M.replaces = nil

      -- loosen some of the normal restrictions
      M.skip_prob = nil
      M.crazy_prob = nil

      if M.prob > 40 then
        M.level = 1
        M.weap_min_damage = nil
      end

      if M.prob > 200 then
        M.boss_type = nil
      end
    end
  end -- for opt
end


OB_MODULES["chex3_mon_control"] =
{
  name = "chex3_mon_control",

  label = _("Chex Quest 3 Monster Control"),

  game = "chex3",
  engine = "!vanilla",

  hooks =
  {
    setup = CTL_CHEX3.monster_setup
  },

  options =
  {
     {
      name = "float_commonus",
      label = _("Commonus"),
      valuator = "slider",
      units = "",
      min = 0,
      max = 20,
      increment = .02,
      default = "Default",
      nan = "Default,", 
      presets = "0:0 (None at all)," ..
      ".02:0.02 (Scarce)," ..
      ".14:0.14 (Less)," ..
      ".5:0.5 (Plenty)," ..
      "1.2:1.2 (More)," ..
      "3:3 (Heaps)," ..
      "20:20 (INSANE),",
     },

     {
      name = "float_bipedicus",
      label = _("Bipedicus"),
      valuator = "slider",
      units = "",
      min = 0,
      max = 20,
      increment = .02,
      default = "Default",
      nan = "Default,", 
      presets = "0:0 (None at all)," ..
      ".02:0.02 (Scarce)," ..
      ".14:0.14 (Less)," ..
      ".5:0.5 (Plenty)," ..
      "1.2:1.2 (More)," ..
      "3:3 (Heaps)," ..
      "20:20 (INSANE),",
     },

    {
      name = "float_armored_biped",
      label = _("Armored Bipedicus"),
      valuator = "slider",
      units = "",
      min = 0,
      max = 20,
      increment = .02,
      default = "Default",
      nan = "Default,", 
      presets = "0:0 (None at all)," ..
      ".02:0.02 (Scarce)," ..
      ".14:0.14 (Less)," ..
      ".5:0.5 (Plenty)," ..
      "1.2:1.2 (More)," ..
      "3:3 (Heaps)," ..
      "20:20 (INSANE),",
     },

     {
      name = "float_quadrumpus",
      label = _("Quadrumpus"),
      valuator = "slider",
      units = "",
      min = 0,
      max = 20,
      increment = .02,
      default = "Default",
      nan = "Default,", 
      presets = "0:0 (None at all)," ..
      ".02:0.02 (Scarce)," ..
      ".14:0.14 (Less)," ..
      ".5:0.5 (Plenty)," ..
      "1.2:1.2 (More)," ..
      "3:3 (Heaps)," ..
      "20:20 (INSANE),",
     },

     {
      name = "float_cycloptis",
      label = _("Cycloptis"),
      valuator = "slider",
      units = "",
      min = 0,
      max = 20,
      increment = .02,
      default = "Default",
      nan = "Default,", 
      presets = "0:0 (None at all)," ..
      ".02:0.02 (Scarce)," ..
      ".14:0.14 (Less)," ..
      ".5:0.5 (Plenty)," ..
      "1.2:1.2 (More)," ..
      "3:3 (Heaps)," ..
      "20:20 (INSANE),",
     },

     
     {
      name = "float_larva",
      label = _("Larva"),
      valuator = "slider",
      units = "",
      min = 0,
      max = 20,
      increment = .02,
      default = "Default",
      nan = "Default,", 
      presets = "0:0 (None at all)," ..
      ".02:0.02 (Scarce)," ..
      ".14:0.14 (Less)," ..
      ".5:0.5 (Plenty)," ..
      "1.2:1.2 (More)," ..
      "3:3 (Heaps)," ..
      "20:20 (INSANE),",
     },

     
     {
      name = "float_flemmine",
      label = _("Flem Mine"),
      valuator = "slider",
      units = "",
      min = 0,
      max = 20,
      increment = .02,
      default = "Default",
      nan = "Default,", 
      presets = "0:0 (None at all)," ..
      ".02:0.02 (Scarce)," ..
      ".14:0.14 (Less)," ..
      ".5:0.5 (Plenty)," ..
      "1.2:1.2 (More)," ..
      "3:3 (Heaps)," ..
      "20:20 (INSANE),",
     },
	 
     
     {
      name = "float_stridicus",
      label = _("Stridicus"),
      valuator = "slider",
      units = "",
      min = 0,
      max = 20,
      increment = .02,
      default = "Default",
      nan = "Default,", 
      presets = "0:0 (None at all)," ..
      ".02:0.02 (Scarce)," ..
      ".14:0.14 (Less)," ..
      ".5:0.5 (Plenty)," ..
      "1.2:1.2 (More)," ..
      "3:3 (Heaps)," ..
      "20:20 (INSANE),",
     },
	 
     
     {
      name = "float_super_cyclop",
      label = _("Super Cycloptis"),
      valuator = "slider",
      units = "",
      min = 0,
      max = 20,
      increment = .02,
      default = "Default",
      nan = "Default,", 
      presets = "0:0 (None at all)," ..
      ".02:0.02 (Scarce)," ..
      ".14:0.14 (Less)," ..
      ".5:0.5 (Plenty)," ..
      "1.2:1.2 (More)," ..
      "3:3 (Heaps)," ..
      "20:20 (INSANE),",
     }
  },
}


----------------------------------------------------------------

CTL_CHEX3.WEAPON_PREF_CHOICES =
{
  "normal",  _("Normal"),
  "vanilla", _("Vanilla"),
  "none",    _("NONE"),
}


function CTL_CHEX3.weapon_setup(self)

  for _,opt in pairs(self.options) do
    if opt.valuator and opt.valuator == "slider" then
      PARAM[opt.name] = gui.get_module_slider_value(self.name, opt.name) 
    end

    local W = GAME.WEAPONS[string.sub(opt.name, 7)] -- Strip the float_ prefix from the weapon name for table lookup

    if W and PARAM[opt.name] ~= "Default" then
      W.add_prob = PARAM[opt.name] * 100
      W.pref     = W.add_prob * 0.28 + 1 -- Complete guesswork right now - Dasho

      -- loosen some of the normal restrictions
      W.level = 1
    end
  end -- for opt

  -- specific instructions for the weapon_pref choices
  PARAM.weapon_prefs = self.options.weapon_prefs.value

  if PARAM.weapon_prefs == "vanilla"
  or PARAM.weapon_prefs == "none" then
    for _,mon in pairs(GAME.MONSTERS) do
      mon.weapon_prefs = nil
    end
  end

  if PARAM.weapon_prefs == "vanilla" then
    GAME.MONSTERS["Flem Mine"].weap_prefs = { zorch_propulsor = 2.0 }
  end

end


OB_MODULES["chex3_weapon_control"] =
{

  name = "chex3_weapon_control",

  label = _("Chex Quest 3 Weapon Control"),

  game = "chex3",
  engine = "!vanilla",

  hooks =
  {
    setup = CTL_CHEX3.weapon_setup
  },

  options =
  {
     
     {
      name = "float_super_bootspork",
      label = _("Super Bootspork"),
      valuator = "slider",
      units = "",
      min = 0,
      max = 10,
      increment = .02,
      default = "Default",
      nan = "Default,", 
      presets = "0:0 (None)," ..
      ".02:0.02 (Scarce)," ..
      ".14:0.14 (Less)," ..
      ".5:0.5 (Plenty)," ..
      "1.2:1.2 (More)," ..
      "3:3 (Heaps)," ..
      "10:10 (I LOVE IT),",
     },

     {
      name = "float_large_zorcher",
      label = _("Large Zorcher"),
      valuator = "slider",
      units = "",
      min = 0,
      max = 10,
      increment = .02,
      default = "Default",
      nan = "Default,", 
      presets = "0:0 (None)," ..
      ".02:0.02 (Scarce)," ..
      ".14:0.14 (Less)," ..
      ".5:0.5 (Plenty)," ..
      "1.2:1.2 (More)," ..
      "3:3 (Heaps)," ..
      "10:10 (I LOVE IT),",
     },

     {
      name = "float_rapid_zorcher",
      label = _("Rapid Zorcher"),
      valuator = "slider",
      units = "",
      min = 0,
      max = 10,
      increment = .02,
      default = "Default",
      nan = "Default,", 
      presets = "0:0 (None)," ..
      ".02:0.02 (Scarce)," ..
      ".14:0.14 (Less)," ..
      ".5:0.5 (Plenty)," ..
      "1.2:1.2 (More)," ..
      "3:3 (Heaps)," ..
      "10:10 (I LOVE IT),",
     },

     {
      name = "float_zorch_propulsor",
      label = _("Zorch Propulsor"),
      valuator = "slider",
      units = "",
      min = 0,
      max = 10,
      increment = .02,
      default = "Default",
      nan = "Default,", 
      presets = "0:0 (None)," ..
      ".02:0.02 (Scarce)," ..
      ".14:0.14 (Less)," ..
      ".5:0.5 (Plenty)," ..
      "1.2:1.2 (More)," ..
      "3:3 (Heaps)," ..
      "10:10 (I LOVE IT),",
     },
	 
     {
      name = "float_phasing_zorcher",
      label = _("Phasing Zorcher"),
      valuator = "slider",
      units = "",
      min = 0,
      max = 10,
      increment = .02,
      default = "Default",
      nan = "Default,", 
      presets = "0:0 (None)," ..
      ".02:0.02 (Scarce)," ..
      ".14:0.14 (Less)," ..
      ".5:0.5 (Plenty)," ..
      "1.2:1.2 (More)," ..
      "3:3 (Heaps)," ..
      "10:10 (I LOVE IT),",
     },
	 
     {
      name = "float_laz_device",
      label = _("LAZ Device"),
      valuator = "slider",
      units = "",
      min = 0,
      max = 10,
      increment = .02,
      default = "Default",
      nan = "Default,", 
      presets = "0:0 (None)," ..
      ".02:0.02 (Scarce)," ..
      ".14:0.14 (Less)," ..
      ".5:0.5 (Plenty)," ..
      "1.2:1.2 (More)," ..
      "3:3 (Heaps)," ..
      "10:10 (I LOVE IT),",
     },

    weapon_prefs =
    {
      name="weapon_prefs",
      label=_("Weapon Preferences"),
      choices=CTL_CHEX3.WEAPON_PREF_CHOICES,
      tooltip="Alters selection of weapons that are prefered to show up depending on enemy palette for a chosen map.\n\n" ..
      "Normal: Monsters have weapon preferences. Stronger weapons and ammo are more likely to appear directly with stronger enemies.\n\n" ..
      "Vanilla: Vanilla Oblige-style preferences. Increases Zorch Propulsors if the map has more Flem Mines. \n\n" ..
      "NONE: No preferences at all. For those who like to live life dangerously with Super Cycloptises and only Super Bootsporks.",
      default="normal",
	  priority = 0,
    },
  },
}
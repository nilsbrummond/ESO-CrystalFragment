--
-- Crystal Fragment Passive
-- 
-- github.com/nilsbrummond/ESO-CrystalFragments
--

-- Detects the effect 'Crystal Fragment Passive' which grants the
-- next use of 'Crystal Fragment' as an instant cast ability.
-- 
-- The default game indicator of the passive effect is glowing purple
-- hands on the player.
--
-- This addon's goal is to give a clearer indication of the presense of 
-- the passive effect.

-- TODO:
--    Make the indicator look better...
--    De-Register hooks if not a sorcerer


-- Notes:
--
-- Sorcerer:
-- GetUnitClassId('player') == 2

-- GetBuffAbilityType(string unitTag, integer serverSlot)
-- Returns: integer buffAbilityType

-- CheckUnitBuffsForAbilityType(string unitTag, integer abilityType)
-- Returns: bool found


CFP = {}
CFP.version = 0.03
CFP.debug = false
CFP.active = false

local function GetBuffIcon()
  return 'esoui/art/icons/ability_sorcerer_thunderclap.dds'
end

local function Debug(text)

  if CFP.debug then
    d (text)
  end

end

local function Initialize( self, addOnName )

  if addOnName ~= "CrystalFragmentsPassive" then return end

  -- if GetUnitClass('player') == 'Sorceser' then d('good') end

  EVENT_MANAGER:RegisterForEvent( 
      "CrystalFragmentsPassive", EVENT_EFFECT_CHANGED, CFP.EventEffectChanged )

  EVENT_MANAGER:RegisterForEvent(
      "CrystalFragmentsPassive", EVENT_ACTIVE_WEAPON_PAIR_CHANGED, CFP.EventWeaponSwap )

  CFP.InitializeGUI()
end

-- Fade the Indicator over time from alpha 1 to .2
function CFP.Update()

  if CFP.active then
    local gameTime = GetGameTimeMilliseconds() / 1000
    local left = math.floor( CFP.endTime - gameTime )

    if ( left > 0 ) then
      local alpha = (left / CFP.duration) + 0.2
      CFP.TLW:SetAlpha(alpha)
    else
      CFP.TLW:SetAlpha(0)
    end
  end

end

function CFP.EventEffectChanged( eventCode, changeType, effectSlot,
  effectName, unitTag, beginTime, endTime, stackCount, iconName, 
  buffType, effectType, abilityType, statusEffectType)

  -- self buffs only
  if unitTag ~= "player" then return end

  -- This is the buff by name
  if effectName ~= "Crystal Fragments Passive" then return end

  Debug( "CFP:" .. " " .. changeType .. " " .. effectSlot .. " " .. 
         effectName .. " " .. unitTag .. " " .. beginTime .. " " .. 
         endTime .. " " .. stackCount ..  " " .. " " .. iconName .. " " .. 
         buffType .. " " .. effectType .. " " .. abilityType .. " " ..
         statusEffectType )

  -- TODO: Need to find the CONSTants for 1, 2, and 3 in here:
  if (2 == changeType) then
    -- Buff ended
    CFP.DisableIndicator()
  elseif (1 == changeType) or (3 == changeType) then
    -- Buff added
    CFP.EnableIndicator(beginTime, endTime)
  end

end

function CFP.EventWeaponSwap( activeWeaponPair, locked )

  Debug ( "SWAP lvl=" .. activeWeaponPair .. " lock=" .. locked )

  CFP.UpdateIndicator()

end

function CFP.EnableIndicator(beginTime, endTime)

  Debug ( "CFP.EnableIndicator" )

  CFP.active = true
  CFP.endTime = endTime
  CFP.duration = endTime - beginTime
  CFP.TLW:SetAlpha(1)
  CFP.TLW:SetHidden(false)

  CFP.UpdateIndicator()

end

function CFP.DisableIndicator()

  Debug ( "CFP.DisableIndicator" )

  CFP.active = false
  CFP.TLW:SetHidden(true)

end

function CFP.UpdateIndicator()

  if not CFP.active then return end

  Debug ( "CFP.UpdateIndicator" )

  -- Find which slot the "Crystal Fragment" ability is slotted.

  local index = -1

  for x = 3,8 do
    if GetSlotName(x) == "Crystal Fragments" then
      index = x
    end
  end

  if index < 0 then 
    CFP.TLW:SetHidden(true)
    return 
  end

  CFP.Anchor(index)
  CFP.TLW:SetHidden(false)

end

-- Just cause a chain by itself is boring.
function CFP.BallAndChain( object )
	
	local T = {}
	setmetatable( T , { __index = function( self , func )
		
		if func == "__BALL" then	return object end
		
		return function( self , ... )
			assert( object[func] , func .. " missing in object" )
			object[func]( object , ... )
			return self
		end
	end })
	
	return T
end

-- Anchor the indicator over the correct button.
function CFP.MakeAnchor(h)

  -- Action Slots vs the UI buttons - index is off by 1.

  return function (index)
      local win = CFP.TLW
      win:SetAnchor(
          BOTTOM, 
          ZO_ActionBar1:GetChild(index+1),
          TOP,
          0, -h/3)
    end

end

function CFP.InitializeGUI()

  local w,h = ZO_ActionBar1:GetChild(3):GetDimensions()

  CFP.TLW = CFP.BallAndChain( 
      WINDOW_MANAGER:CreateTopLevelWindow("CFP_BuffDisplay") )
    :SetHidden(true)
    :SetDimensions(w,h)
  .__BALL

  CFP.icon = CFP.BallAndChain(
      WINDOW_MANAGER:CreateControl("CFP_Icon", CFP.TLW, CT_TEXTURE) )
    :SetHidden(false)
    :SetTexture(GetBuffIcon())
    :SetDimensions(w,h)
    :SetAnchorFill(CFP.TLW)
  .__BALL

  CFP.Anchor = CFP.MakeAnchor(h)
  CFP.Anchor(3)

end

-- Init Hook --
EVENT_MANAGER:RegisterForEvent( 
  "CrystalFragmentsPassive", EVENT_ADD_ON_LOADED, Initialize )


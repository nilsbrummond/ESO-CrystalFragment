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

-- Release Notes:
--    Indicator now hidden when in UI mode.
--    Better looking now.


-- Notes:
--
-- Sorcerer:
-- GetUnitClassId('player') == 2

-- GetBuffAbilityType(string unitTag, integer serverSlot)
-- Returns: integer buffAbilityType

-- CheckUnitBuffsForAbilityType(string unitTag, integer abilityType)
-- Returns: bool found


CFP = {}
CFP.version = 0.04
CFP.debug = false
CFP.active = false
CFP.enabled = false


local function Debug(text)

  if CFP.debug then
    d (text)
  end

end

-- Just cause a chain by itself is boring.
local function BallAndChain( object )
	
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


local function Initialize( self, addOnName )

  if addOnName ~= "CrystalFragmentsPassive" then return end

  CFP.InitializeGUI()

  EVENT_MANAGER:RegisterForEvent(
      "CrystalFragmentsPassive", EVENT_PLAYER_ACTIVATED, CFP.EventPlayerActivated )

  -- In case the player is already active.
  if IsPlayerActivated() then
    CFP.EventPlayerActivated()
  end

end

function CFP.EventPlayerActivated()

  -- TODO: find the global constant for 2 - sorcerer...
  if GetUnitClassId('player') == 2 then

    if not CFP.enabled then
      CFP.enabled = true
      EVENT_MANAGER:RegisterForEvent( 
          "CrystalFragmentsPassive", 
          EVENT_EFFECT_CHANGED, CFP.EventEffectChanged )

      EVENT_MANAGER:RegisterForEvent(
          "CrystalFragmentsPassive", 
          EVENT_ACTIVE_WEAPON_PAIR_CHANGED, CFP.EventWeaponSwap )
      
      EVENT_MANAGER:RegisterForEvent( 
          "CrystalFragmentsPassive", 
          EVENT_RETICLE_HIDDEN_UPDATE, CFP.EventReticleHiddenUpdate )
    end

  else
    
    if CFP.enabled then
      CFP.enabled = false

      -- TODO: need to verify UnregisterForEvent signature...

      EVENT_MANAGER:UnregisterForEvent( 
          "CrystalFragmentsPassive", 
          EVENT_EFFECT_CHANGED, CFP.EventEffectChanged )

      EVENT_MANAGER:UnregisterForEvent(
          "CrystalFragmentsPassive", 
          EVENT_ACTIVE_WEAPON_PAIR_CHANGED, CFP.EventWeaponSwap )
 
      EVENT_MANAGER:UnregisterForEvent( 
          "CrystalFragmentsPassive", 
          EVENT_RETICLE_HIDDEN_UPDATE, CFP.EventReticleHiddenUpdate )

      -- Just in case..
      CFP.DisableIndicator()
    end

  end
end

-- Fade the Indicator over time from alpha 1 to .2
function CFP.Update()

  if CFP.active then
    local gameTime = GetGameTimeMilliseconds() / 1000
    local left = CFP.endTime - gameTime

    if ( left > 0.01 ) then
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

function CFP.EventReticleHiddenUpdate(event, hidden)
  
  Debug ( "Reticle hidden=" .. tostring(hidden) )

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

  if IsReticleHidden() then
    -- hide al the combat UI stuff...  
    -- in charcter sheet, inventory, etc..
    CFP.TLW:SetHidden(true)
    return 
  end

  -- Find which slot the "Crystal Fragment" ability is slotted.

  local index = -1

  for x = 3,8 do
    if GetSlotName(x) == "Crystal Fragments" then
      index = x
    end
  end

  if index < 0 then 
    -- Crystal Fragments is not on the action bar.
    CFP.TLW:SetHidden(true)
    return 
  end

  -- anchor the indicator to the correct action button and show it.
  CFP.Anchor(index)
  CFP.TLW:SetHidden(false)

end

-- Anchor the indicator over the correct button.
local function MakeAnchor(h)

  -- Why h/3 as the offset above the action button?
  -- Rule of thirds is always a good place to start...
  -- http://en.wikipedia.org/wiki/Rule_of_thirds
  local y_offset = -h/3

  return function (index)
      local win = CFP.TLW
      win:SetAnchor(
          BOTTOM, 
          -- Action Slots vs the UI buttons - index is off by 1.
          ZO_ActionBar1:GetChild(index+1),
          TOP,
          0, y_offset)
    end

end

-- Anchor the indicator covering the correct button.
-- local function MakeAnchorFill(h)
-- 
--   return function (index)
--       local win = CFP.TLW
--       win:SetAnchor(
--           BOTTOM, 
--           -- Action Slots vs the UI buttons - index is off by 1.
--           ZO_ActionBar1:GetChild(index+1),
--           TOP,
--           0, -10)
--     end
-- 
-- end

function CFP.InitializeGUI()

  -- Just use the first action button for sizing...
  local w,h = ZO_ActionBar1:GetChild(3):GetDimensions()

  CFP.TLW = BallAndChain( 
      WINDOW_MANAGER:CreateTopLevelWindow("CFPBuffDisplay") )
    :SetHidden(true)
    :SetDimensions(2*w/3,2*h/3)
  .__BALL

  CFP.icon = BallAndChain(
      WINDOW_MANAGER:CreateControl("CFPIcon", CFP.TLW, CT_TEXTURE) )
    :SetHidden(false)
    :SetTexture('esoui/art/icons/ability_sorcerer_thunderclap.dds')
    :SetDimensions(2*w/3,2*h/3)
    :SetAnchorFill(CFP.TLW)
  .__BALL

  CFP.decoration = BallAndChain(
      WINDOW_MANAGER:CreateControl("CFPDecoration", CFP.TLW, CT_TEXTURE) )
    :SetHidden(false)
    :SetTexture('/esoui/art/actionbar/actionslot_toggledon.dds')
    :SetDimensions(2*w/3,2*h/3)
    :SetAnchorFill(CFP.TLW)
  .__BALL

  CFP.Anchor = MakeAnchor(h)
  -- CFP.Anchor = MakeAnchorFill(h)
  CFP.Anchor(3)

end

-- Init Hook --
EVENT_MANAGER:RegisterForEvent( 
  "CrystalFragmentsPassive", EVENT_ADD_ON_LOADED, Initialize )


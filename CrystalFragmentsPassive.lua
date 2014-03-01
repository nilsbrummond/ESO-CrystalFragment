--
-- Crystal Fragment Passive
--


-- Sorcerer:
-- GetUnitClassId('player') == 2

-- GetBuffAbilityType(string unitTag, integer serverSlot)
-- Returns: integer buffAbilityType

-- CheckUnitBuffsForAbilityType(string unitTag, integer abilityType)
-- Returns: bool found


-- 4 to 8


CFP = {}

local function GetBuffIcon()
  return 'esoui/art/icons/ability_sorcerer_thunderclap.dds'
end

local function Initialize( self, addOnName )

  if addOnName ~= "CrystalFragmentsPassive" then return end

  d( "CrystalFragmentsPassive" )

  if GetUnitClass('player') == 'Sorceser' then d('good') end

  EVENT_MANAGER:RegisterForEvent( 
      "CrystalFragmentsPassive", EVENT_EFFECT_CHANGED, CFP.EventEffectChanged )

  EVENT_MANAGER:RegisterForEvent(
      "CrystalFragmentsPassive", EVENT_ACTIVE_WEAPON_PAIR_CHANGED, CFP.EventWeaponSwap )

  CFP.InitializeGUI()

  -- CFP.UpdateIndicator()
end


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

  d( "CFP:" .. " " .. changeType .. " " .. effectSlot .. " " .. effectName .. " " .. unitTag .. " " .. beginTime .. " " .. endTime .. " " .. stackCount ..  " " .. " " .. iconName .. " " .. buffType .. " " .. effectType .. " " .. abilityType .. " " .. statusEffectType )

  if (2 == changeType) then
    -- Buff ended
    CFP.DisableIndicator()
  elseif (1 == changeType) or (3 == changeType) then
    -- Buff added
    CFP.EnableIndicator(beginTime, endTime)
  end

end

function CFP.EventWeaponSwap( activeWeaponPair, locked )

  d ( "SWAP lvl=" .. activeWeaponPair .. " lock=" .. locked )

  CFP.UpdateIndicator()

end

function CFP.EnableIndicator(beginTime, endTime)

  d ( "CFP.EnableIndicator" )

  CFP.active = true
  CFP.endTime = endTime
  CFP.duration = endTime - beginTime
  CFP.TLW:SetAlpha(1)
  CFP.TLW:SetHidden(false)

  CFP.UpdateIndicator()

end

function CFP.DisableIndicator()

  d ( "CFP.DisableIndicator" )

  CFP.active = false
  CFP.TLW:SetHidden(true)

end

function CFP.UpdateIndicator()

  if not CFP.active then return end

  d ( "CFP.UpdateIndicator" )

  local index = -1

  for x = 3,8 do
    if GetSlotName(x) == "Crystal Fragments" then
      index = x
    end
  end

  if index < 0 then 
    d ( "Not on bar" )
    CFP.TLW:SetHidden(true)
    return 
  end

  d ( "buff on" )

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

function CFP.MakeAnchor(h)

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


-- @description InteractiveToolbar_basefunc
-- @author MPL
-- @website http://forum.cockos.com/member.php?u=70694
-- @noindex



  ---------------------------------------------------
  function msg(s) if s then ShowConsoleMsg(s..'\n') end end
  ---------------------------------------------------
  function MPL_GetTableOfCtrlValues(str)  -- split .:
    if not str or type(str) ~= 'string' then return end
    local t = {} for val in str:gmatch('[%-%d]+.') do t[#t+1] = val end
    if #t == 0 and str:match('%d+') then t[1] = str end
    return t
  end
  ---------------------------------------------------
  function spairs(t, order) --http://stackoverflow.com/questions/15706270/sort-a-table-in-lua
    local keys = {}
    for k in pairs(t) do keys[#keys+1] = k end
    if order then table.sort(keys, function(a,b) return order(t, a, b) end)  else  table.sort(keys) end
    local i = 0
    return function()
              i = i + 1
              if keys[i] then return keys[i], t[keys[i]] end
           end
  end
  ---------------------------------------------------
  function MPL_GetTableOfCtrlValues2(str, dig_cnt0)  -- split float
    if not str  then return end
    local dig_cnt
    local minus = str:match('%-')
    if not dig_cnt0 then dig_cnt = 3 else dig_cnt = dig_cnt0 end
    local t = {} for val in str:gmatch('[%-%d]+.') do t[#t+1] = val end
    if #t == 0 and str:match('%d+') then t[1] = str end
    if tonumber(str) then
      local int, div = math.modf(tonumber(str))
      div = tostring(div):match('%.(%d+)')
      --div = math.floor(math.abs(div * 10*dig_cnt))
      --div = string.format("%0"..dig_cnt.."d", div)
      local int_str
      if minus and not tostring(int):match('%-') then 
        int_str = '-'..int
       else
        int_str = tostring(int)
      end
      return {int_str..'.', tostring(div)}
     else 
      return {'undefined'}
    end
  end
  ---------------------------------------------------
  function MPL_ModifyFloatVal(src_val,int_ID,int_cnt,change_val,data, positive_only, pow_tol, ignore_fields)
    if not src_val then return end
    local out_val = src_val
    local int_ID0 = int_cnt - int_ID -- ID from end
    if int_ID0 == 0 then  
      
      if not ignore_fields then 
        if pow_tol then  out_val = out_val + change_val*10^pow_tol  else  out_val = out_val + change_val*0.001  end
       else
        if pow_tol then out_val = out_val + change_val*10^pow_tol else out_val = out_val + change_val*0.01 end
      end    
      
     elseif int_ID0 == 1 then
      
      if not ignore_fields then 
        if pow_tol then out_val = out_val + change_val*10^pow_tol else out_val = out_val + change_val*0.01 end
       else
        if pow_tol then out_val = out_val + change_val*10^pow_tol else out_val = out_val + change_val*0.01 end
      end
      
    end
    
    if math.abs(out_val) < 0.00001 then   out_val = 0 end            
    if positive_only == true and type(positive_only) == 'boolean' then return lim(out_val, 0, math.huge) 
     elseif positive_only and type(positive_only) == 'function' then return positive_only(out_val)
     else
      return out_val
    end
  end  
  ---------------------------------------------------
  function MPL_ModifyFloatVal2(src_val,int_ID,int_cnt,change_val,data, positive_only, pow_tol, ignore_fields)
    if not src_val then return end
    local out_val = src_val
    local int_ID0 = int_cnt - int_ID -- ID from end
    if int_ID0 == 0 then  
      out_val = out_val + change_val*0.01
     elseif int_ID0 == 1 then
      out_val = out_val + change_val
    end
    
    if math.abs(out_val) < 0.00001 then   out_val = 0 end            
    if positive_only == true and type(positive_only) == 'boolean' then return lim(out_val, 0, math.huge) 
     elseif positive_only and type(positive_only) == 'function' then return positive_only(out_val)
     else
      return out_val
    end
  end 
  -------------------------------------------------------------------------------
  function MPL_ModifyTimeVal(src_val_sec,int_ID,int_cnt,change_val,data, positive_only)
    local out_val = src_val_sec
    if not src_val_sec then return end
    local int_ID0 = int_cnt - int_ID -- ID from end
    local rul_format = data.rul_format
    
    -- Minutes:seconds
      if rul_format == 0 then 
        if int_ID0 == 0 then -- ms
          out_val = out_val + change_val*0.001
         elseif int_ID0 == 1 then -- s
          out_val = out_val + change_val
         elseif int_ID0 == 2 then -- min
          out_val = out_val + change_val*60
         elseif int_ID0 == 3 then -- hour
          out_val = out_val + change_val*3600         
        end
      end
  
    -- Measures.Beats
      if rul_format == 1 then 
        local measures_out
        local out_val_beats
        local beats, measures, cml, fullbeats, cdenom = TimeMap2_timeToBeats(0, out_val)
        if int_ID0 == 0 then 
          out_val_beats = fullbeats + change_val*0.01
         elseif int_ID0 == 1 then 
          out_val_beats = fullbeats + change_val
         elseif int_ID0 == 2 then 
          measures_out = measures + change_val     
        end
        if not measures_out then
          out_val = TimeMap2_beatsToTime(0, out_val_beats)
         else 
          out_val = TimeMap2_beatsToTime(0, beats, measures_out)
        end
      end
  
    -- Seconds
      if rul_format == 2 then 
        if int_ID0 == 0 then -- ms
          out_val = out_val + change_val*0.001
         elseif int_ID0 == 1 then -- s
          out_val = out_val + change_val    
        end
      end
  
    -- Samples
      if rul_format == 3 then 
        if int_ID0 == 0 then 
          out_val = out_val + change_val/data.SR
        end
      end
  
    -- HH:MM:SS:frame
      if rul_format == 4 then 
        if int_ID0 == 0 then -- ms
          out_val = out_val + change_val/data.FR
         elseif int_ID0 == 1 then -- s
          out_val = out_val + change_val
         elseif int_ID0 == 2 then -- min
          out_val = out_val + change_val*60
         elseif int_ID0 == 3 then -- hour
          out_val = out_val + change_val*3600         
        end
      end
  
    -- frames
      if rul_format == 5 then 
        if int_ID0 == 0 then -- ms
          out_val = out_val + change_val/data.FR
         elseif int_ID0 == 1 then -- s
          out_val = out_val + change_val    
        end
      end
                                  
    if positive_only == true then return lim(out_val, 0, math.huge) 
     else
      return out_val
    end
  end  
  ---------------------------------------------------
  function MPL_GetCurrentRulerFormat()
    local ruler = -1
    local buf = reaper.format_timestr_pos( 30, '',-1 )
    if buf:match('%d%:%d%d%.%d%d%d') then return 0      -- Minutes:seconds
      elseif buf:match('%d%.%d+.%d%d') then return 1    -- Measures.Beats / Minutes:seconds
                                                        -- Measures.Beats (minimal)
                                                        -- Measures.Beats (minimal) / Minutes:seconds
      elseif buf:match('%d%.%d%d%d') then return 2      -- Seconds
      elseif buf:match('[^%p]%d+[^%p]') then 
        if tonumber(buf) > 10000 then 
          return 3                                      -- Samples
         else 
          return 5                                      -- Frames
        end           
      elseif buf:match('%d%:%d%d%:%d%d%:%d%d') then return 4 -- hhmmssfr
    end
    return ruler
  end
  ---------------------------------------------------
  --strNeed64 reaper.mkvolstr(strNeed64, vol )
  --strNeed64 reaper.mkpanstr(strNeed64, pan )
  function MPL_FormatPan(pan_val)
    local pan_str = 'undefined'
          if pan_val > 0 then 
            pan_str = math.floor((pan_val*100))..'% R'
           elseif pan_val < 0 then
            pan_str = math.floor(math.abs(pan_val*100))..'% L'
           elseif pan_val == 0 then
            pan_str = 'Center'
          end
    return pan_str
  end
  ---------------------------------------------------
  function MPL_GetFormattedGrid()
    local grid_flags, grid_division, grid_swingmode, grid_swingamt = GetSetProjectGrid( 0, false )
    local is_triplet
    local denom = 1/grid_division
    local grid_str
    if denom >=2 then 
      is_triplet = (1/grid_division) % 3 == 0 
      grid_str = '1/'..math.floor(denom)
      if is_triplet then grid_str = '1/'..math.floor(denom*2/3) end
     else 
      grid_str = 1
      is_triplet = math.abs(grid_division - 0.6666) < 0.001
    end
    return grid_division, grid_str, is_triplet
  end     
  ---------------------------------------------------
  function MPL_ReduceFXname(s)
    local s_out = s:match('[%:%/%s]+(.*)')
    if not s_out then return s end
    s_out = s_out:gsub('%(.-%)','') 
    if s_out:match('%/(.*)') then s_out = s_out:match('%/(.*)') end
    if not s_out then return s else return s_out end
  end
 ---------------------------------------------------  
  function lim(val, min,max) --local min,max 
    if not min or not max then min, max = 0,1 end 
    return math.max(min,  math.min(val, max) ) 
  end
  ---------------------------------------------------
  function HasWindXYWHChanged(last_gfxx, last_gfxy, last_gfxw, last_gfxh, last_dock)
    local  dock, wx,wy,ww,wh = gfx.dock(-1, 0,0,0,0)
    local retval=0
    if wx ~= last_gfxx or wy ~= last_gfxy then retval= 2 end --- minor
    if ww ~= last_gfxw or wh ~= last_gfxh or dock ~= last_dock then retval= 1 end --- major
    if not last_gfxx then retval = -1 end
    return retval, wx,wy,ww,wh, dock
  end
  ---------------------------------------------------
  function CopyTable(orig)--http://lua-users.org/wiki/CopyTable
      local orig_type = type(orig)
      local copy
      if orig_type == 'table' then
          copy = {}
          for orig_key, orig_value in next, orig, nil do
              copy[CopyTable(orig_key)] = CopyTable(orig_value)
          end
          setmetatable(copy, CopyTable(getmetatable(orig)))
      else -- number, string, boolean, etc
          copy = orig
      end
      return copy
  end 
  ---------------------------------------------------
  function ExtState_Load(conf)
    local def = ExtState_Def()
    for key in pairs(def) do 
      local es_str = GetExtState(def.ES_key, key)
      if es_str == '' then conf[key] = def[key] else conf[key] = tonumber(es_str) or es_str end
    end
  end  
  ---------------------------------------------------
  function ExtState_Save(conf)
    conf.dock2 , conf.wind_x, conf.wind_y, conf.wind_w, conf.wind_h= gfx.dock(-1, 0,0,0,0)
    for key in pairs(conf) do SetExtState(conf.ES_key, key, conf[key], true)  end
  end
   
    function F_open_URL(url) if GetOS():match("OSX") then os.execute('open '.. url) else os.execute('start '..url) end  end
  ---------------------------------------------------
  function Menu(mouse, t)
    local str, check ,hidden= '', '',''
    for i = 1, #t do
      if t[i].state then check = '!' else check ='' end
      if t[i].hidden then hidden = '#' else hidden ='' end
      local add_str= hidden..check..t[i].str
      add_str= add_str:gsub('!|', '|!')
      str = str..add_str
      str = str..'|'
    end
    gfx.x = mouse.x
    gfx.y = mouse.y
    local ret = gfx.showmenu(str)
    if ret > 0 then if t[ret].func then t[ret].func() end end
  end  
  ---------------------------------------------------   
  function math_q(num)  if math.abs(num - math.floor(num)) < math.abs(num - math.ceil(num)) then return math.floor(num) else return math.ceil(num) end end
  ---------------------------------------------------  
  function HasCurPosChanged()
    local cur_pos = GetCursorPositionEx( 0 )
    local ret = false
    if lastcur_pos and lastcur_pos ~= cur_pos then  ret = true end
    lastcur_pos = cur_pos
    return ret
  end
  ---------------------------------------------------
  function HasTimeSelChanged()
    local TS_st, TSend = GetSet_LoopTimeRange2( 0, false, false, -1, -1, false )
    local ret = false
    if lastTS_st and lastTSend and (lastTS_st ~= TS_st or lastTSend ~=TSend)  then  ret = true end
    lastTS_st, lastTSend = TS_st, TSend
    return ret
  end
  ---------------------------------------------------
  function HasGridChanged()
    local _, ProjGid = GetSetProjectGrid( 0, false )
    local ret = false
    if last_ProjGid and last_ProjGid ~= ProjGid  then  ret = true end
    last_ProjGid = ProjGid
    return ret
  end 
  ---------------------------------------------------
  function HasPlayStateChanged()
    local int_playstate = GetPlayStateEx( 0 )
    local ret = false
    if lastint_playstate and lastint_playstate ~= int_playstate  then  ret = true end
    lastint_playstate = int_playstate
    return ret
  end 
  ---------------------------------------------------
  function HasRulerFormChanged()
    local FormTS = format_timestr_pos( 100, '', -1 )
    local ret = false
    if last_FormTS and last_FormTS ~= FormTS  then  ret = true end
    last_FormTS = FormTS 
    return ret
  end
  ---------------------------------------------------
  function dBFromReaperVal(val)  local out
    if val < 1 then 
      out = 20*math.log(val, 10)
     else 
      out = 6*math.log(val, 2)
    end 
    return string.format('%.2f',out)
  end
  ---------------------------------------------------
  function ReaperValfromdB(dB_val)  local out
    local dB_val = tonumber(dB_val)
    if dB_val < 0 then 
      out = 10^(dB_val/20)
     else 
      out = 10^(dB_val/20)
    end 
    return out--string.format('%.2f',tonumber(out))
  end
  ---------------------------------------------------
  function HasSelEnvChanged()
    local Sel_env = GetSelectedEnvelope( 0 )
    local ret = false
    if (Sel_env and not last_Sel_env) or (last_Sel_env and last_Sel_env ~= Sel_env)  then  ret = true end
    last_Sel_env = Sel_env 
    return ret
  end  
  ---------------------------------------------------
  function Config_ParseIni(conf_path, widgets) 
    local def_conf = Config_DefaultStr()
    --  create if not exists
      local f = io.open(conf_path, 'r')
      local cont
      if f then
        cont = f:read('a')
        f:close()
       else
        f = io.open(conf_path, 'w')
        if f then 
          f:write(def_conf)
          f:close()
        end
      end
    
    
                      
    --  parse widgets 
      for i = 1, #widgets.types_t do 
        local widg_str = widgets.types_t[i]
        if widg_str ~= nil then
          local retval, str_widgets_tags = BR_Win32_GetPrivateProfileString( widg_str, 'order', '', conf_path )
          widgets[widg_str] = {}
          for w in str_widgets_tags:gmatch('#(%a+)') do widgets[widg_str] [  #widgets[widg_str] +1 ] = w end
            
          widgets[widg_str].buttons = {}
          local retval, buttons_str = BR_Win32_GetPrivateProfileString( widg_str, 'buttons', '', conf_path )
          for w in buttons_str:gmatch('#(%a+)') do widgets[widg_str].buttons [  #widgets[widg_str].buttons +1 ] = w end
        end
      end
      
    -- persist
      local retval, pers_widg = BR_Win32_GetPrivateProfileString( 'Persist', 'order', '', conf_path )
      widgets.Persist = {}
      for w in pers_widg:gmatch('#(%a+)') do widgets.Persist [  #widgets.Persist +1 ] = w end
      
  end
  ---------------------------------------------------
  function Config_DumpIni(widgets, conf_path) 
      local str = '//Configuration for MPL InfoTool'
        
  
                        
      --  parse widgets 
        for i = 1, #widgets.types_t do 
          local widg_str = widgets.types_t[i]
          if widg_str then 
            str = str..'\n'..'['..widg_str..']'
            local ord = ''
            for i2 =1 , #widgets[widg_str] do 
              ord = ord..'#'..widgets[widg_str][i2]..' '
            end
            str = str..'\norder='..ord
            if widgets[widg_str].buttons and #widgets[widg_str].buttons > 0 then
              local b_ord = ''
              for i2 =1 , #widgets[widg_str].buttons do 
                b_ord = b_ord..'#'..widgets[widg_str].buttons[i2]..' '
              end
              str = str..'\nbuttons='..b_ord
            end
          end
        end
        
      -- persist
          local widg_str = 'Persist'
          str = str..'\n'..'['..widg_str..']'
          local ord = ''
          for i2 =1 , #widgets[widg_str] do 
            ord = ord..'#'..widgets[widg_str][i2]..' '
          end
          str = str..'\norder='..ord
          if widgets[widg_str].buttons and #widgets[widg_str].buttons > 0 then
            local b_ord = ''
            for i2 =1 , #widgets[widg_str].buttons do 
              b_ord = b_ord..'#'..widgets[widg_str].buttons[i2]..' '
            end
            str = str..'\nbuttons='..b_ord
          end
          
        
      local f = io.open(conf_path, 'w')        
      if f then 
        f:write(str)
        f:close()
      end           
    end
  ---------------------------------------------------
  function Config_Reset(conf_path)
    local def_conf = Config_DefaultStr()
    local f = io.open(conf_path, 'w')
    if f then 
      f:write(def_conf)
      f:close()
    end
    redraw = 1
    SCC_trig = true
  end

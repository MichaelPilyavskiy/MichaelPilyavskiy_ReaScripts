-- @description Create send between selected tracks and track under mouse cursor
-- @version 1.14
-- @author MPL
-- @metapackage
-- @provides
--    [main] . > mpl_Send selected tracks to track under mouse cursor (multichannel).lua
--    [main] . > mpl_Send selected tracks to track under mouse cursor (channel 1-2 to 1-2).lua
--    [main] . > mpl_Send selected tracks to track under mouse cursor (channel 1-2 to 1-2, post-fader).lua
--    [main] . > mpl_Send selected tracks to track under mouse cursor (channel 1-2 to 1-2, pre-fx).lua
--    [main] . > mpl_Send selected tracks to track under mouse cursor (channel 1-2 to 1-2, post-fx).lua
--    [main] . > mpl_Send selected tracks to track under mouse cursor (channel 1-2 to 3-4).lua
--    [main] . > mpl_Send selected tracks to track under mouse cursor (channel 1-2 to 5-6).lua
--    [main] . > mpl_Send selected tracks to track under mouse cursor (channel 1-2 to 7-8).lua
--    [main] . > mpl_Send selected tracks to track under mouse cursor (channel 1-2 to 9-10).lua
--    [main] . > mpl_Send selected tracks to track under mouse cursor (channel 1-2 to 11-12).lua
--    [main] . > mpl_Send selected tracks to track under mouse cursor (channel 1-2 to 13-14).lua
--    [main] . > mpl_Send selected tracks to track under mouse cursor (channel 1-2 to 15-16).lua
--    [main] . > mpl_Send selected tracks to track under mouse cursor (channel 3-4 to 1-2).lua
--    [main] . > mpl_Send selected tracks to track under mouse cursor (channel 5-6 to 1-2).lua
--    [main] . > mpl_Send selected tracks to track under mouse cursor (channel 7-8 to 1-2).lua
--    [main] . > mpl_Send selected tracks to track under mouse cursor (channel 9-10 to 1-2).lua
--    [main] . > mpl_Send selected tracks to track under mouse cursor (channel 11-12 to 1-2).lua
--    [main] . > mpl_Send selected tracks to track under mouse cursor (channel 13-14 to 1-2).lua
--    [main] . > mpl_Send selected tracks to track under mouse cursor (channel 15-16 to 1-2).lua
--    [main] . > mpl_Send track under mouse cursor to selected tracks  (multichannel).lua
--    [main] . > mpl_Send track under mouse cursor to selected tracks  (channel 1-2 to 1-2).lua
--    [main] . > mpl_Send track under mouse cursor to selected tracks  (channel 1-2 to 3-4).lua
--    [main] . > mpl_Send track under mouse cursor to selected tracks  (channel 1-2 to 5-6).lua
--    [main] . > mpl_Send track under mouse cursor to selected tracks  (channel 1-2 to 7-8).lua
--    [main] . > mpl_Send track under mouse cursor to selected tracks  (channel 1-2 to 9-10).lua
--    [main] . > mpl_Send track under mouse cursor to selected tracks  (channel 1-2 to 11-12).lua
--    [main] . > mpl_Send track under mouse cursor to selected tracks  (channel 1-2 to 13-14).lua
--    [main] . > mpl_Send track under mouse cursor to selected tracks  (channel 1-2 to 15-16).lua
--    [main] . > mpl_Send track under mouse cursor to selected tracks  (channel 3-4 to 1-2).lua
--    [main] . > mpl_Send track under mouse cursor to selected tracks  (channel 5-6 to 1-2).lua
--    [main] . > mpl_Send track under mouse cursor to selected tracks (channel 7-8 to 1-2).lua
--    [main] . > mpl_Send track under mouse cursor to selected tracks (channel 9-10 to 1-2).lua
--    [main] . > mpl_Send track under mouse cursor to selected tracks (channel 11-12 to 1-2).lua
--    [main] . > mpl_Send track under mouse cursor to selected tracks (channel 13-14 to 1-2).lua
--    [main] . > mpl_Send track under mouse cursor to selected tracks (channel 15-16 to 1-2).lua
-- @website http://forum.cockos.com/showthread.php?t=188335  
-- @changelog
--    + Proper undo flags
--    + Remove SWS dependency
--    + Send selected tracks to track under mouse cursor (channel 1-2 to 1-2, post-fader)
--    + Send selected tracks to track under mouse cursor (channel 1-2 to 1-2, pre-fx)
--    + Send selected tracks to track under mouse cursor (channel 1-2 to 1-2, post-fx)

  

  
  ---------------------------------------------------------------------
  function GetDestTrGUID()
    local t = {}
    local src_track = VF_GetTrackUnderMouseCursor()
    if src_track then t[1] = GetTrackGUID( src_track ) end  
    return t   
  end
  ---------------------------------------------------------------------
  function GetSrcTrGUID()
    local t = {}
    for i = 1, CountSelectedTracks(0) do
      local tr = GetSelectedTrack(0,i-1)
      t[#t+1] = GetTrackGUID( tr )
    end  
    return t 
  end
  --------------------------------------------------------------------- 
  function Check_t(src_t, dest_t)
    for i = 1, #src_t do
      local chGUID = src_t[i]:gsub('%p', '')
      for i = #dest_t, 1, -1 do
        if dest_t[i]:gsub('%p', '') == chGUID then
          table.remove(dest_t,i)
          break
        end
      end
    end
  end
  ---------------------------------------------------------------------   
  function AddSends(source_type, src_t0, dest_t0, MCH_mode, src_ch, dest_ch, defsendvol, defsendflag, custom_sendmode)
     src_t, dest_t = CopyTable(src_t0), CopyTable(dest_t0)
    if source_type == false then  src_t, dest_t = CopyTable(dest_t0), CopyTable(src_t0) end
    
    -- validate mode
      if MCH_mode==false and not (src_ch and dest_ch) then return end
    
    -- loop source tracks
    for srci = 1, #src_t do
      local src_tr =  VF_GetTrackByGUID( src_t[srci] )
      local src_tr_ch = GetMediaTrackInfo_Value( src_tr, 'I_NCHAN')
      
      for desti = 1, #dest_t do
        local dest_tr =  VF_GetTrackByGUID(dest_t[desti] )
        
        -- check for existing sends
          local is_exist = false
          for sendid =1,  GetTrackNumSends( src_tr, 0 ) do
            local dest_tr_check = GetTrackSendInfo_Value( src_tr, 0, sendid-1, 'P_DESTTRACK' ) 
            local dest_tr_src_ch = GetTrackSendInfo_Value( src_tr, 0, sendid-1, 'I_SRCCHAN')
            local dest_tr_dest_ch = GetTrackSendInfo_Value( src_tr, 0, sendid-1, 'I_DSTCHAN')
            
            
            if (dest_tr_check == dest_tr and dest_tr_src_ch == src_ch-1 and dest_tr_dest_ch == dest_ch-1) then is_exist = true break end
          end
        
        -- perform main stuff
        if not is_exist then  
          local new_id = CreateTrackSend( src_tr, dest_tr )
          SetTrackSendInfo_Value( src_tr, 0, new_id, 'D_VOL', defsendvol)
          local sendmode = defsendflag
          if custom_sendmode then sendmode = custom_sendmode end
          SetTrackSendInfo_Value( src_tr, 0, new_id, 'I_SENDMODE', defsendflag&255) -- obey MIDI flag
          
          if MCH_mode == true then
            local dest_tr_ch = GetMediaTrackInfo_Value( dest_tr, 'I_NCHAN')
            if dest_tr_ch < src_tr_ch then SetMediaTrackInfo_Value( dest_tr, 'I_NCHAN', src_tr_ch ) end -- increase dest channel count up to src track
            SetTrackSendInfo_Value( src_tr, 0, new_id, 'I_DSTCHAN', 0) -- always start multichannel from 1st chan
            if dest_tr_ch == 2 then src_flag = 0 else src_flag = 0|(1024*math.floor(src_tr_ch/2)) end
            SetTrackSendInfo_Value( src_tr, 0, new_id, 'I_SRCCHAN',src_flag)
          end
          
          if MCH_mode == false then
            if GetMediaTrackInfo_Value( src_tr, 'I_NCHAN'  ) < src_ch+1 then SetMediaTrackInfo_Value( src_tr, 'I_NCHAN', src_ch+1  ) end 
            if GetMediaTrackInfo_Value( dest_tr, 'I_NCHAN'  ) < dest_ch+1 then SetMediaTrackInfo_Value( dest_tr, 'I_NCHAN', dest_ch+1  ) end  
            SetTrackSendInfo_Value( src_tr, 0, new_id, 'I_SRCCHAN', src_ch-1)
            SetTrackSendInfo_Value( src_tr, 0, new_id, 'I_DSTCHAN', dest_ch-1)
          end   
                   
        end
      end
    end
  end
  ---------------------------------------------------------------------  
  function Parsing_filename()
    local filename = ({reaper.get_action_context()})[2]
    local script_title = GetShortSmplName(filename):gsub('%.lua','')
    local source_type = script_title:match('Send selected tracks to track under mouse cursor') ~= nil -- true==selected tracks is source
    local channel_mode = script_title:match('%((.*)%)')
    local MCH_mode, dest_ch, src_ch = false
    if channel_mode:match('multichannel') then 
      MCH_mode = true 
     else
      src_ch = channel_mode:match('channel (%d+)') if src_ch then src_ch = tonumber(src_ch) end
      dest_ch = channel_mode:match('to (%d+)') if dest_ch then dest_ch = tonumber(dest_ch) end
    end
    
    local custom_sendmode
    if script_title:match('post%-fader') then custom_sendmode = 0 end
    if script_title:match('pre%-fx') then custom_sendmode = 1 end
    if script_title:match('post%-fx') then custom_sendmode = 3 end
    
    return source_type, MCH_mode, src_ch, dest_ch, script_title, custom_sendmode
  end
  ---------------------------------------------------------------------  
  function main(source_type, MCH_mode, src_ch, dest_ch, script_title, defsendvol, defsendflag, custom_sendmode)
    Undo_BeginBlock()
    local src_GUID = GetSrcTrGUID()
    local dest_GUID = GetDestTrGUID()    
    Check_t(src_GUID,dest_GUID)
    if #src_GUID < 1 or #dest_GUID < 1 then return end
    AddSends(source_type, src_GUID,dest_GUID, MCH_mode, src_ch, dest_ch, defsendvol, defsendflag, custom_sendmode)
    TrackList_AdjustWindows(false)
    Undo_EndBlock(script_title, 0xFFFFFFFF) 
  end 
  ----------------------------------------------------------------------
  function VF_CheckFunctions(vrs)  local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'  if  reaper.file_exists( SEfunc_path ) then dofile(SEfunc_path)  if not VF_version or VF_version < vrs then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to version '..vrs..' or newer', '', 0) else return true end   else  reaper.MB(SEfunc_path:gsub('%\\', '/')..' not found. You should have ReaPack installed. Right click on ReaPack package and click Install, then click Apply', '', 0) if reaper.APIExists('ReaPack_BrowsePackages') then ReaPack_BrowsePackages( 'Various functions' ) else reaper.MB('ReaPack extension not found', '', 0) end end end
  --------------------------------------------------------------------  
  local ret = VF_CheckFunctions(3.17) if ret then local ret2 = VF_CheckReaperVrs(5.975,true) if ret2 then 
    local defsendvol = VF_spk77_getinivalue( get_ini_file(), 'REAPER', 'defsendvol')
    local defsendflag = VF_spk77_getinivalue( get_ini_file(), 'REAPER', 'defsendflag')
    local source_type, MCH_mode, src_ch, dest_ch, script_title, custom_sendmode = Parsing_filename()
    main(source_type, MCH_mode, src_ch, dest_ch, script_title, defsendvol, defsendflag, custom_sendmode)
  end end
-- @description Random modulated parameters LFO phase on selected tracks 
-- @version 1.02
-- @author MPL
-- @website http://forum.cockos.com/showthread.php?t=188335
-- @changelog
--    # VF independent

  for key in pairs(reaper) do _G[key]=reaper[key]  end 
  ---------------------------------------------------
  function VF_CheckReaperVrs(rvrs, showmsg) 
    local vrs_num =  GetAppVersion()
    vrs_num = tonumber(vrs_num:match('[%d%.]+'))
    if rvrs > vrs_num then 
      if showmsg then reaper.MB('Update REAPER to newer version '..'('..rvrs..' or newer)', '', 0) end
      return
     else
      return true
    end
  end
  ---------------------------------------------------
  script_title_out = 'Random modulated parameters LFO phase on selected tracks'
  
  function main()
    for i = 1, CountSelectedTracks()do
      local tr =GetSelectedTrack(0,i-1)
      for fxnumber = 1,  TrackFX_GetCount( tr ) do
        for paramnumber = 1,  TrackFX_GetNumParams( tr, fxnumber-1 ) do
          local ret = TrackFX_GetNamedConfigParm( tr, fxnumber-1, 'param.'..(paramnumber-1)..'.lfo.active' ) 
          if ret then TrackFX_SetNamedConfigParm( tr, fxnumber-1,  'param.'..(paramnumber-1)..'.lfo.phase',math.random() ) end  
        end
      end
    end
  end
  ---------------------------------------------------
  if VF_CheckReaperVrs(6.37,true) then  
    Undo_BeginBlock2( 0 )
    main()
    Undo_EndBlock2( 0, script_title_out, 0xFFFFFFFF )
  end
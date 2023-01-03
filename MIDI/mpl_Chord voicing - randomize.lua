-- @description Chord voicing - randomize
-- @version 1.01
-- @author MPL
-- @provides [main=main,midi_editor] .
-- @changelog
--  # apply to selected chord only

  -- [[debug search filter: NOT function NOT reaper NOT gfx NOT VF]]
  ----------------------------------------------------------------------  
  function main(take)
    if not take or not TakeIsMIDI(take) then return end  
    
    local ret, extdata = GetSetMediaItemInfo_String(  GetMediaItemTake_Item( take ), 'P_EXT:mplchords', '',0 )
    local evts = getevts(take)  
     chords = {}
    if not ret then chords = chords_storetoitem(take, evts, ret==false) else chords = chords_parse_itemextdata(extdata) end
    
    modifychords(chords) 
    setevtsback(take,evts,chords)
  end
  ----------------------------------------------------------------------
  function modifychords(chords)
    for ppq in spairs(chords) do
      has_selectedflag= false
      for chordnote = 1, #chords[ppq] do if chords[ppq][chordnote].flags&1==1 then has_selectedflag = true break end end
      
      if has_selectedflag then 
        local chordpattern = {} for chordnote = 1, #chords[ppq] do  chordpattern[chords[ppq][chordnote].pitch %12] = true end -- chord normalized pattern 
        for chordnote = 1, #chords[ppq] do 
          local src_pitch = chords[ppq][chordnote].pitch
          local new_note = math.floor(src_pitch + math.random()*24 - 12)
          local new_note = checknote(src_pitch, new_note, chordpattern, chords[ppq])
          chords[ppq][chordnote].pitch = new_note
        end 
      end
    end
  end
  ----------------------------------------------------------------------
  function checknote_HasAlreadyInChord(new_note, chord_t)
    local has_note = false for i = 1, #chord_t do if chord_t[i].pitch == new_note then return true end end
  end
  ----------------------------------------------------------------------
  function checknote(src_pitch, new_note, chordpattern, chord_t) 
    if chordpattern[new_note%12] and not checknote_HasAlreadyInChord(new_note, chord_t) then return new_note end -- check if already fit conditions
    for offs = 1, 12 do
      new_note = new_note + 1
      if chordpattern[new_note%12] and not checknote_HasAlreadyInChord(new_note, chord_t) then return new_note end -- check if already fit conditions
    end
    return src_pitch
  end 
  ----------------------------------------------------------------------
  function setevtsback(take,evts,chords)
    local str = ""
    local s_pack = string.pack
    local ppq_pos = 0
    for i = 1, #evts-1 do
      if not evts[i].isnote then
        str=str..s_pack("i4Bs4", evts[i].ppq_pos - ppq_pos, evts[i].flags , evts[i].msg1)
        ppq_pos = evts[i].ppq_pos
      end
    end
    
    for ppq in spairs(chords) do
      for chordnote = 1, #chords[ppq] do
        str=str..string.pack("i4BI4BBB", chords[ppq][chordnote].ppq_pos - ppq_pos, 0, 3, 0x90 | chords[ppq][chordnote].chan, chords[ppq][chordnote].pitch, chords[ppq][chordnote].vel)
        str=str..string.pack("i4BI4BBB", chords[ppq][chordnote].ppq_len, 0, 3, 0x80 | chords[ppq][chordnote].chan, chords[ppq][chordnote].pitch, 0)
        ppq_pos = chords[ppq][chordnote].ppq_pos+chords[ppq][chordnote].ppq_len
      end
    end
    
    MIDI_SetAllEvts(take, str)
    MIDI_Sort(take)
  end
  ----------------------------------------------------------------------
  function chords_parse_itemextdata(extdata)
    local chords = {}
    for line in extdata:gmatch('[^\r\n]+') do
      local ppq = line:match('%d+')
      if tonumber(ppq) then
        ppq = tonumber(ppq)
        chords[ppq] = {}
        for block in line:gmatch('%[.-%]') do
          local pitch, ppq_pos, ppq_len, vel, chan, flags = block:match('(%d+) (%d+) (%d+) (%d+) (%d+) (%d+)')
          chords[ppq][#chords[ppq]+1] = {
            pitch=tonumber(pitch),
            vel=tonumber(vel),
            chan=tonumber(chan),
            ppq_pos=tonumber(ppq_pos),
            ppq_len=tonumber(ppq_len),
            flags=tonumber(flags),
            
            }
        end 
      end
    end
    return chords
  end
  ----------------------------------------------------------------------
  function getevts(take)   
    local gotAllOK, MIDIstring = MIDI_GetAllEvts(take, "")
    if not gotAllOK then return end 
    local s_unpack = string.unpack
    local MIDIlen = MIDIstring:len()
    local idx = 0    
    local offset, flags, msg1
    local ppq_pos = 0
    local nextPos, prevPos = 1, 1 
    local pitch
    
    -- collect mesages
    local evts = {}
    local notesopen = {}
    while nextPos <= MIDIlen do  
        prevPos = nextPos
        offset, flags, msg1, nextPos = s_unpack("i4Bs4", MIDIstring, prevPos) 
        ppq_pos = ppq_pos + offset
        local pos_sec = MIDI_GetProjTimeFromPPQPos( take, ppq_pos )
        local CClane, pitch, CCval,vel, pitch_format
        local isNoteOn = msg1:byte(1)>>4 == 0x9 
        local isNoteOff = msg1:byte(1)>>4 == 0x8
        local pitch
        if isNoteOn or isNoteOff then
          pitch = msg1:byte(2)
        end
        if not isNoteOff then
          idx = idx + 1
          evts[idx] = {
                            flags=flags, 
                            msg1=msg1,
                            ppq_pos = ppq_pos,
                            isnote = isNoteOn}
        end
        
        if isNoteOn then
          notesopen[pitch] = idx
        end
        
        if isNoteOff==true then  
          local last_rel_pitchid = notesopen[pitch]
          if evts[last_rel_pitchid] then
            local ppq_len = ppq_pos - evts[last_rel_pitchid].ppq_pos
            evts[last_rel_pitchid].ppq_len = ppq_len
            notesopen[pitch] = nil
          end
        end
    end
    return evts
  end
  
  
  ----------------------------------------------------------------------
  function chords_storetoitem(take, evts, store_to_rpp) 
    local ppq_filter =  reaper.MIDI_GetPPQPosFromProjQN( take, 0.25 ) 
    local last_ppq_pos = 0
    -- extract chords
      local chords = {}
      for i = 1, #evts do
        if evts[i].isnote then 
          local msg1 = evts[i].msg1
          local flags = evts[i].flags
          local ppq_pos = evts[i].ppq_pos 
          local ppq_len = evts[i].ppq_len 
          if ppq_pos - last_ppq_pos < ppq_filter then ppq_pos = last_ppq_pos end
          if not chords[ppq_pos] then  chords[ppq_pos] = {} end
          local norm_pitch = msg1:byte(2)%12
          chords[ppq_pos] [#chords[ppq_pos]+1]= {
              pitch = msg1:byte(2),
              vel = msg1:byte(3),
              chan = msg1:byte(1)&0xF,
              ppq_len = ppq_len,
              ppq_pos = evts[i].ppq_pos ,
              flags = flags
            }
          last_ppq_pos = ppq_pos
        end
      end
      
    -- store chords
      local outstr = ''
      for ppq in spairs(chords) do
        outstr = outstr..'\n'..ppq
        for note =1, #chords[ppq] do
          outstr = outstr..' ['..chords[ppq][note].pitch..' '..chords[ppq][note].ppq_pos..' '..chords[ppq][note].ppq_len..' '..chords[ppq][note].vel..' '..chords[ppq][note].chan..' '..chords[ppq][note].flags..']'
        end
      end
    
    if store_to_rpp then GetSetMediaItemInfo_String(  GetMediaItemTake_Item( take ), 'P_EXT:mplchords', outstr, true ) end
    return chords
  end
  ----------------------------------------------------------------------
  function VF_CheckFunctions(vrs)  local SEfunc_path = reaper.GetResourcePath()..'/Scripts/MPL Scripts/Functions/mpl_Various_functions.lua'  if  reaper.file_exists( SEfunc_path ) then dofile(SEfunc_path)  if not VF_version or VF_version < vrs then  reaper.MB('Update '..SEfunc_path:gsub('%\\', '/')..' to version '..vrs..' or newer', '', 0) else return true end   else  reaper.MB(SEfunc_path:gsub('%\\', '/')..' not found. You should have ReaPack installed. Right click on ReaPack package and click Install, then click Apply', '', 0) if reaper.APIExists('ReaPack_BrowsePackages') then reaper.ReaPack_BrowsePackages( 'Various functions' ) else reaper.MB('ReaPack extension not found', '', 0) end end end
  --------------------------------------------------------------------  
  local ret = VF_CheckFunctions(3.51) if ret then local ret2 = VF_CheckReaperVrs(5.32,true) if ret2 then 
    Undo_BeginBlock()
    local ME = reaper.MIDIEditor_GetActive()
    if ME then
      --take = reaper.MIDIEditor_GetTake(ME)
      for takeindex = 1, 100 do
        local take = MIDIEditor_EnumTakes( ME, takeindex-1, true) 
        if not take then break end
        main(take) 
      end
     else
      for i = 1, CountSelectedMediaItems(0) do
        local item = GetSelectedMediaItem(0,i-1)
        local take = GetActiveTake(item) 
        if take then main(take) end
      end
    end
    Undo_EndBlock('Chord voicing - randomize', 0xFFFFFFFF)
  end end
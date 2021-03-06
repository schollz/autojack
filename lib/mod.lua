local mod=require 'core/mods'

local sleep=0.1

local function oscapture(cmd,raw)
  local f=assert(io.popen(cmd,'r'))
  local s=assert(f:read('*a'))
  f:close()
  if raw then return s end
  s=string.gsub(s,'^%s+','')
  s=string.gsub(s,'%s+$','')
  s=string.gsub(s,'[\n\r]+',' ')
  return s
end

local function osexecute(cmd)
  print(cmd)
  sleep=sleep+0.1
  os.execute("echo 'sleep "..sleep.."; "..cmd.."; rm /dev/shm/run"..sleep..".sh' > /dev/shm/run"..sleep..".sh; chmod +x /dev/shm/run"..sleep..".sh; /dev/shm/run"..sleep..".sh &")
end

local function load_jack(num,connect)
  alsain="alsa_in"
  if num>0 then
    alsain="alsa_in-0"..num
  end
  jack_connect="jack_connect"
  if connect==false then
    jack_connect="jack_disconnect"
  end
  local cmd=jack_connect.." "..alsain..":capture_1 crone:input_1"
  osexecute(cmd)
  cmd=jack_connect.." "..alsain..":capture_2 crone:input_2"
  osexecute(cmd)
end

mod.hook.register("system_post_startup","autojack",function()
  osexecute("killall alsa_in")
  osexecute("killall alsa_out")
  local state=oscapture("aplay -l",true)
  print(state)
  local alsacards={}
  for line in state:gmatch("[^\r\n]+") do
    local chunks={}
    for substring in line:gmatch("%S+") do
      table.insert(chunks,substring)
    end
    if chunks[1]=="card" then
      if chunks[2]~="0:" then
        print("found usb audio device: "..chunks[3])
        table.insert(alsacards,chunks[3])
      end
    end
  end

  local activated=0
  for _,dev in ipairs(alsacards) do
    cmd="alsa_in -d hw:CARD="..dev
    osexecute(cmd)
    load_jack(activated,false)
    load_jack(activated,true)
    activated=activated+1
  end
end)


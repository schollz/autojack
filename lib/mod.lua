local mod=require 'core/mods'

local sleep=0.1

local function oscapture(cmd, raw)
  local f = assert(io.popen(cmd, 'r'))
  local s = assert(f:read('*a'))
  f:close()
  if raw then return s end
  s = string.gsub(s, '^%s+', '')
  s = string.gsub(s, '%s+$', '')
  s = string.gsub(s, '[\n\r]+', ' ')
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

mod.hook.register("system_post_startup","opzop1",function()
  local alsacards={"OPZ","OP1"}
  print("running opzop1")
  osexecute("killall alsa_in")
  osexecute("killall alsa_out")
  local state=oscapture("aplay -l",true)
  print(state)

  local activated=0
  for _,dev in ipairs(alsacards) do
   if string.find(state,dev) then
      cmd="alsa_in -d hw:CARD="..dev
      osexecute(cmd)
      load_jack(activated,false)
      load_jack(activated,true)
      activated=activated+1
    end
  end
end)


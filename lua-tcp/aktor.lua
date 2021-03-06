-----------------------------------------------
function send_to_visu(sid,cmd)
conn=net.createConnection(net.TCP, 0) 
conn:on("receive", function(conn, payload) print(payload) end)
-- senden an shc
conn:connect(80,"192.168.0.54")
conn:send("GET /shc/index.php?app=shc&a&ajax=executeswitchcommand&sid=" ..sid.. "&command=" ..cmd.." HTTP/1.1\r\n") 
conn:send("Host: 192.168.0.54\r\n") 
conn:send("Accept: */*\r\n") 
conn:send("User-Agent: Mozilla/4.0 (compatible; esp8266 Lua; Windows NT 5.1)\r\n")
conn:send("\r\n")
conn:on("sent",function(conn)
                      conn:close()
                  end)
conn:on("disconnection", function(conn)
       print("Got disconnection...")
  end)

end
-----------------------------------------------
function read_temp(pin)
--pin = 4
status,temp,humi,temp_decimial,humi_decimial = dht.read(pin)
if( status == dht.OK ) then
  -- Integer firmware using this example
--  print(     
--    string.format(
--      "DHT Temperature:%d.%03d;Humidity:%d.%03d\r\n",
--      math.floor(temp),
--      temp_decimial,
--      math.floor(humi),
--      humi_decimial
--    )
--  )
  -- Float firmware using this example
  --print("DHT Temperature:"..temp..";".."Humidity:"..humi)
elseif( status == dht.ERROR_CHECKSUM ) then
  print( "DHT Checksum error." );
elseif( status == dht.ERROR_TIMEOUT ) then
  print( "DHT Time out." );
end

return temp_decimial,humi_decimial,temp,humi

end

--------------------------------------------------
-- wlan verbinden
-----------------------------------------------

---------------------------------
print("wait")
-----------------------------------------------------
-- befehle ueber TCP empfangen
-----------------------------------------------------
ipshow = 0 -- damit nach empfangen der ip, tcp server startet
push = 0
change = 5
p1 = 1
p2 = 1

lampe1 = 0 -- 0 = aus
lampe2 = 0
-- config fuer gpios!
gpio.mode(6, gpio.HIGH)
gpio.write(6, gpio.HIGH)
gpio.mode(7, gpio.HIGH)
gpio.write(7, gpio.HIGH)


relay1 = 4
relay2 = 5
gpio.mode(relay1,gpio.OUTPUT)
gpio.mode(relay2,gpio.OUTPUT)

tmr.alarm(0, 150, 1, function()
     if wifi.sta.getip() == nil then
        --print("wait\n")
     elseif(ipshow == 0) then
        print("SS Running v0.3")
      print(wifi.sta.getip()) 
        ipshow = 1
sv=net.createServer(net.TCP, 1) -- anpassen das schneller beendet wird 1sek  
sv:listen(9274,function(c)
  c:on("receive", function(c, pl) 
  print(pl) -- gibt empfangen daten in console aus!
  -- empfangen daten zerlegen
  typ = string.sub(pl,0,1)
  pin = string.sub(pl,3,3) -- geht nur mit einstelligen pins!
  befehl = string.sub(pl,5,5) 
  -- type =0 node.restart!
-- Type 2 = Ausgang
if(typ == "2") then
  gpio.mode(pin,gpio.OUTPUT)
      if(befehl == "1") then
        print("low")
        --gpio.write(pin,gpio.LOW)
                if(pin == "4") then
                    lampe1=1
                end
                if(pin == "5") then
                    lampe2=1
                end
      end
      
      if(befehl == "0") then
      print("high")
      --gpio.write(pin, gpio.HIGH) 
                if(pin == "4") then 
                    lampe1=0
                end
                if(pin == "5") then
                    lampe2=0
                end

     end       
-- type 3 = eingang
elseif(typ == "3") then
c:send(gpio.read(pin))
print("abfrage:" ..gpio.read(pin).. "\n next...")
elseif(typ == "4") then
read_temp(pin)
t = temp
h = humi
c:send(t.. "|" ..h)

elseif(typ =="0") then
node.restart()
end
        if string.sub(pl, 0, 11) == "**command**"  then
        payload = pl
        tmr.stop(0)
             dofile("wifi_tools.lua")
        end   
  end)
  end)
-- end ipshow if
    end

-- einstellungen fuer schalter

sid1 = 20
sid2 = 21


schalter1 = gpio.read(6)
schalter2 = gpio.read(7)

status1 = gpio.read(4)
status2 = gpio.read(5)

--print(schalter1)

-- fuer schalter1 
if(schalter1 == 0 and p1 ~= schalter1) then
p1 = 0
--print("debug if 1")
    if(lampe1 == 0) then
        lampe1 = 1
        --print("licht zu lampe1 = 1")
        send_to_visu(sid1,status1)
        
    elseif(lampe1 == 1) then
        lampe1 = 0
        --print("licht zu lampe1 = 0")
        send_to_visu(sid1,status1)
    end
elseif(schalter1 == 1 and p1 ~= schalter1) then
p1 = 1
--print("debug if 2")
    if(lampe1 == 0) then
        lampe1 = 1
       -- print("licht zu lampe1 = 1")
        send_to_visu(sid1,status1)
    elseif(lampe1 == 1) then
        lampe1 = 0
        --print("licht zu lampe1 = 0")
        send_to_visu(sid1,status1)
    end
end
-- end fuer schalter 1
-- fuer schalter2
if(schalter2 == 0 and p2 ~= schalter2) then
p2 = 0
--print("debug2 if 1")
    if(lampe2 == 0) then
        lampe2 = 1
        --print("licht zu lampe2 = 1")
        send_to_visu(sid2,status2)
    elseif(lampe2 == 1) then
        lampe2 = 0
       -- print("licht zu lampe2 = 0")
        send_to_visu(sid2,status2)
    end
elseif(schalter2 == 1 and p2 ~= schalter2) then
p2 = 1
--print("debug2 if 2")
    if(lampe2 == 0) then
        lampe2 = 1
        --print("licht zu lampe2 = 1")
        send_to_visu(sid2,status2)
    elseif(lampe2 == 1) then
        lampe2 = 0
       -- print("licht zu lampe2 = 0")
        send_to_visu(sid2,status2)
    end
end
-- end fuer schalter 2

--- fuer relays schalten
if(lampe1 == 1) then
gpio.write(relay1,gpio.LOW)
--print("s1 low")
end
if(lampe1 == 0) then
gpio.write(relay1,gpio.HIGH)
--print("s1 high")
end

if(lampe2 == 1) then
gpio.write(relay2,gpio.LOW)
--print("s2 low")
end
if(lampe2 == 0) then
gpio.write(relay2,gpio.HIGH)
--print("s2 high")
end
    
-- end tmr funktion
 end)

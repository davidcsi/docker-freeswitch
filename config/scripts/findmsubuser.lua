--
function doTranslation(caller_id_number,country_code)
  -- caller_id_number: 0034844621540 -- don't touch it
  if string.find(caller_id_number, "^00[1-9]%d%d%d%d%d%d.*") then return caller_id_number end
  -- caller_id_number: 01844621542
  caller_id_number = string.gsub(caller_id_number, "^0([%d%d%d%d%d.*])", "00" .. country_code .. "%1")
  -- caller_id_number: +34844621540
  caller_id_number = string.gsub(caller_id_number, "^+([1-9]%d%d%d%d%d%d.*)", "00" .. "%1")
  -- caller_id_number: 34844621540
  caller_id_number = string.gsub(caller_id_number, "^([1-9]%d%d%d%d%d%d.*)", "00" .. "%1")
  return caller_id_number
end

-- lookup correct user for invite from CLPBX:
-- select * from accounts where contact like "<%sip:egbertiets@%>" or (user="egbertkantoor" and host="89.184.172.55" and port="5080");

local api = freeswitch.API();
local dbh = freeswitch.Dbh("odbc://mobileconnect:david:1234")
if dbh:connected() == false then
  freeswitch.consoleLog("notice", "findmsubuser.lua cannot connect to database" .. dsn .. "\n")
  return
end


local remote_host = string.match(session:getVariable("sip_h_X-SRC-IP"),"^[%a%d.]+$") or "geen"
local remote_port = string.match(session:getVariable("sip_h_X-SRC-PORT"),"^[%d]+$") or "geen"
local ruri_user = string.match(session:getVariable("sip_req_user"),"^[%a%d.%-_+]+$") or "geen"
local ruri = string.match(session:getVariable("sip_req_user") .. "@" .. session:getVariable("sip_req_host"),"^[%a%d@%-._]+$") or "geen"
local msubuser = nil
local remoteuser = ""
local remotepass = ""

-- freeswitch.consoleLog("notice", "FindMsubUser: remote_host: " .. remote_host .. ", remote_port: " .. remote_port .. ", ruri_user: " .. ruri_user .. ", ruri: " .. ruri .. "\n")

-- first assume request uri (ruri) is the contact retsiger (we) registered:
-- select * from accounts where contact="<ruri>" limit 1
local my_query = string.format("select * from accounts where contact='<sip:%s>' and host='%s' and status!='D' limit 1", ruri, remote_host)
assert (dbh:query(my_query, function(u)
  freeswitch.consoleLog("notice", "=====================\n")
  freeswitch.consoleLog("notice", "findmsubuser, found: " .. u.msub .. " by using contactadres / ruri\n")
  freeswitch.consoleLog("notice", "=====================\n")
  msubuser=u.msub
  remotedomain=u.domain
  remoteuser=u.user
  remotepass=u.pass
end))




-- if no account found, try searching based on request uri user combined with host and port.
-- select * from accounts where (host="remote_host" and port="remote_port") and (user="ruri_user" or contact like "<sip:ruri_user@%>") limit 1
if not msubuser then
  local my_query = string.format("select * from accounts where (host='%s' and port='%s') and (user='%s' or contact like '<sip:%s@%%>') and status!='D' limit 1", remote_host,remote_port,ruri_user,ruri_user)
  assert (dbh:query(my_query, function(u)
    freeswitch.consoleLog("notice", "=====================\n")
    freeswitch.consoleLog("notice", "findmsubuser, found: " .. u.msub .. " by using remote host/port and ruri-user\n")
    freeswitch.consoleLog("notice", "=====================\n")
    msubuser=u.msub
    remotedomain=u.domain
    remoteuser=u.user
    remotepass=u.pass
  end))
end

-- use lookuptable for accounts that use NAPTR/SRV
if not msubuser then
  freeswitch.consoleLog("notice", "ruri: " .. ruri .. ", ruri_user: " .. ruri_user .. ", remote_host: " .. remote_host)
  --local my_query = string.format("select account.* from ipdomains join accounts on (ipdomains.domain=accounts.host) where (contact='<sip:%s>' or user='%s' or contact like '<sip:%s@%%>') and ipdomains.ip='%s' limit 1", ruri, ruri_user, ruri_user, remote_host)
  local my_query = string.format("select accounts.* from ipdomains join accounts on (ipdomains.domain=accounts.host) where contact='<sip:%s>' and ipdomains.ip='%s' and status!='D' limit 1", ruri, remote_host)
  assert (dbh:query(my_query, function(u)
    freeswitch.consoleLog("notice", "=====================\n")
    freeswitch.consoleLog("notice", "findmsubuser, found: " .. u.msub .. " by using ip->domain lookup and contactadres / ruri\n")
    freeswitch.consoleLog("notice", "=====================\n")
    msubuser=u.msub
    remotedomain=u.domain
    remoteuser=u.user
    remotepass=u.pass
  end))
end

if not msubuser then 
  session:setVariable("msubuser","notfound")
  session:setVariable("remotedomain","notfound")
  session:setVariable("remoteuser","notfound")
  session:setVariable("remotepass","notfound")
else

  -- Set default
  session:setVariable("msub_country_code","31") 
  session:setVariable("msub_country","") 
  -- At this point we should have the msub, let's get the country
  local my_query = string.format("select ucase(sim_country) as sim_country, country_number as msub_country_code from channel, country_number where ucase(sim_country) = country_code and username  = '%s'", msubuser)
  assert (dbh:query(my_query, function(u)

    user_country=u.sim_country
    msub_country_code = u.msub_country_code
    original_caller_id_number = session:getVariable("sip_from_user")
    translated_caller_id_number = doTranslation( original_caller_id_number, msub_country_code) 

    session:setVariable( "msub_country",u.sim_country )
    session:setVariable( "msub_country_code", msub_country_code )
    session:setVariable( "translated_caller_id_number", translated_caller_id_number )

    freeswitch.consoleLog("notice", "=====================\n")
    freeswitch.consoleLog("notice", "findmsubuser, caller_id_number Translation [" .. msubuser.. "] country: [" .. user_country .. "] originalClg: [" .. original_caller_id_number .. "] TranslatedClg: [" .. translated_caller_id_number .. "]\n")
    freeswitch.consoleLog("notice", "=====================\n")

    session:setVariable( "effective_caller_id_name", translated_caller_id_number )
    session:setVariable( "effective_caller_id_number", translated_caller_id_number )

  end))

  session:setVariable("msubuser",msubuser)
  session:setVariable("remotedomain",remotedomain)
  session:setVariable("remoteuser",remoteuser)
  session:setVariable("remotepass",remotepass)
end

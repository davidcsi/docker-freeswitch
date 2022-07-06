numbers = {
  "01562245222",
  "15222",
  "0034844621540",
  "34844621540",
  "+34844621540",




  '"01562245222"',
  '"15222"',
  '"0034844621540"',
  '"34844621540"',
  '"+34844621540"'
}

function doTranslation(clgnum,cc)

  -- Remove any quotes, they shouldn't be there in the first place.
  clgnum = string.find(clgnum, "\"") and string.gsub(clgnum, "\"", "") or clgnum
  -- clgnum: 0034844621540 -- don't touch it
  if string.find(clgnum, "^00[1-9]%d%d%d%d%d%d.*") then return clgnum end
  -- clgnum: 01844621542
  clgnum = string.find(clgnum, "^0[1-9]%d%d%d%d.*") and string.gsub(clgnum, "^0([%d%d%d%d%d.*])", "00" .. country_code .. "%1") or clgnum
  -- clgnum: +34844621540
  clgnum = string.find(clgnum, "^+[1-9]%d%d%d%d%d%d.*") and string.gsub(clgnum, "^+([1-9]%d%d%d%d%d%d.*)", "00" .. "%1") or clgnum
  -- clgnum: 34844621540
  clgnum = string.find(clgnum, "^([1-9]%d%d%d%d%d%d.*)") and string.gsub(clgnum, "^([1-9]%d%d%d%d%d%d.*)", "00" .. "%1") or clgnum

  return clgnum

end

for _, number in ipairs(numbers) do
  freeswitch.consoleLog("notice", "==========================<" .. number .. ">===========================" )
  freeswitch.consoleLog("notice", "Translated: " .. doTranslation(number, country_code) )
end

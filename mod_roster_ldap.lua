local ldap  = module:require 'ldap';
local timer = require 'util.timer';

if not ldap then
    return;
end

local params = module:get_option('ldap');

local ldap_roster = {}

local function split(st, sep)
  local i = 0
  return function()
    if i < string.len(st) then
      local s, e = string.find(st, sep, i)
      s, e = s or 0, e or string.len(st)
      local r = string.sub(st, i, s - 1)
      i = e + 1
      return r
    end
  end
end

local function dc_to_host(dn)
  local host, comps = '', {};
  for comp in split(dn, ',') do
    table.insert(comps, comp);
  end
  for i = #comps, 1, -1 do
    local comp = comps[i];
    if not string.match(comp, 'dc=') then
      return string.sub(host, 1, -2);
    end
    host = string.sub(comp, string.find(comp, '=') + 1)..'.'..host;
  end
end

local function ldap_to_entry(dn, attrs)
  local host = dc_to_host(dn);
  local name = attrs[params.roster.namefield];
  return { jid = attrs[params.roster.usernamefield]..'@'..host, name=name };
end

local function inject_roster_contacts(username, host, roster)
  for jid, entry in pairs(ldap_roster) do
    if not (jid == username..'@'..host or roster[jid]) then
      module:log('debug', 'injecting '..jid..' as '..entry.name)
      roster[jid] = {};
      local r = roster[jid];
      r.subscription = 'both';
      r.name = entry.name;
      r.groups = { [params.roster.group_name] = true };
      r.persist = false;
    end
  end

  if roster[false] then
    roster[false].version = true;
  end
end

local function update_roster()
  local ld = ldap.getconnection();

  local basedn = params.roster.basedn;
  local filter = params.roster.filter;

  local new_ldap_roster = {};

  for user_dn, user_attrs in ld:search { base = basedn, scope = 'onelevel', filter = filter } do
    local entry = ldap_to_entry(user_dn, user_attrs);
    new_ldap_roster[entry.jid] = entry;
  end

  ldap_roster = new_ldap_roster;
  module:log('info', 'updated LDAP roster');

  ld:close();

  return params.roster.refresh_time
end

local function remove_virtual_contacts(username, host, datastore, data)
  if datastore == 'roster' then
    local new_roster =  {};
    for jid, contact in pairs(data) do
      if contact.persist ~= false then
        new_roster[jid] = contact
      end
    end
    if new_roster[false] then
      new_roster[false].version = nil;
    end
    return username, host, datastore, new_roster;
  end

  return username, host, datastore, data
end

function module.load()
  update_roster()
  timer.add_task(params.roster.refresh_time, update_roster)
  module:hook('roster-load', inject_roster_contacts);
  datamanager.add_callback(remove_virtual_contacts);
end

function module.unload()
  datamanager.remove_callback(remove_virtual_contacts);
end

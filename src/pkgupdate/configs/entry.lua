-- Do not edit this file. It is the entry point. Edit the user.lua file.

l10n = {} -- table with selected localizations
Export('l10n')
-- This is helper function for including localization packages.
function for_l10n(fragment)
	for _, lang in pairs(l10n or {}) do
		Install(fragment .. lang, {ignore = {"missing"}})
	end
end
Export('for_l10n')

local branch = ""
local lists
if uci then
	-- If something is really broken, we could be unable to load the uci dynamic module. Try to do some recovery in such case and hope it works well the next time.
	local cursor = uci.cursor()
	branch = cursor:get("updater", "override", "branch")
	if branch then
		WARN("Branch overriden to " .. branch)
		branch = branch .. "/"
	else
		branch = ""
	end
	lists = cursor:get("updater", "pkglists", "lists")
	l10n = cursor:get("updater", "l10n", "langs")
	if type(l10n) == "string" then
		l10n = {l10n}
	end
else
	ERROR("UCI library is not available. Not processing user lists.")
end

-- Guess what board this is.
local base_model = ""
if model then
	if model:match("[Oo]mnia") then
		base_model = "omnia/"
	elseif model:match("[Tt]urris") then
		base_model = "turris/"
	end
end

-- Definitions common url base
local base_url = "https://api.turris.cz/updater-defs/" .. turris_version .. "/" .. base_model .. branch
-- Reused options for remotely fetched scripts
local script_options = {
	security = "Remote",
	ca = "file:///etc/ssl/updater.pem",
	crl = "file:///tmp/crl.pem",
	ocsp = false,
	pubkey = {
		"file:///etc/updater/keys/release.pub",
		"file:///etc/updater/keys/standby.pub",
		"file:///etc/updater/keys/test.pub" -- It is normal for this one to not be present in production systems
	}
}

-- The distribution base script. It contains the repository and bunch of basic packages
Script("base",  base_url .. "base.lua", script_options)

if lists then
	if type(lists) == "string" then -- if there is single list then uci returns just a string
		lists = {lists}
	end
	-- Go through user lists and pull them in.
	local exec_list = {} -- We want to run userlist only even if it's defined multiple times
	if type(lists) == "table" then
		for _, l in ipairs(lists) do
			if exec_list[l] then
				WARN("User list " .. l .. " specified multiple times")
			else
				Script("userlist-" .. l, base_url .. "userlists/" .. l .. ".lua", script_options)
				exec_list[l] = true
			end
		end
	end
end

-- Some auto-generated by command line
Script("auto-src", "file:///etc/updater/auto.lua", { security = "Local" })
-- Some provided by the user
Script("user-src", "file:///etc/updater/user.lua", { security = "Local" })
-- Add local repositories (might be missing if not installed or used)
Script("localrepo", "file:///usr/share/updater/localrepo/localrepo.lua", { ignore = { "missing" } })
-- Load all lua scripts from /etc/updater/conf.d
local confd_type, _ = stat('/etc/updater/conf.d')
if confd_type == 'd' then
	for name, tp in pairs(ls('/etc/updater/conf.d')) do
		if tp == 'r' and name:match('.*.lua') then
			Script("conf.d-" .. name:sub(1, name:find('.lua$') - 1), "file:///etc/updater/conf.d/" .. name, { security = "Local" })
		end
	end
end

-- Repositories configured in opkg configuration.
-- We read only customfeeds.conf as that should be only file where user should add additional repositories
local custom_feed = io.open("/etc/opkg/customfeeds.conf")
if custom_feed then
	local pubkeys = {}
	for f in pairs(ls('/etc/opkg/keys')) do
		table.insert(pubkeys, "file:///etc/opkg/keys/" .. f)
	end
	for line in custom_feed:lines() do
		if line:match('^%s*src/gz ') then
			local name, feed_uri = line:match('src/gz[%s]+([^%s]+)[%s]+([^%s]+)')
			if name and feed_uri then
				DBG("Adding custom opkg feed " .. name .. " (" .. feed_uri .. ")")
				Repository(name, feed_uri, {pubkey = pubkeys, ignore = {"missing"}})
			else
				WARN("Malformed line in customfeeds.conf:\n" .. line)
			end
		end
	end
	custom_feed:close()
else
	ERROR("No /etc/opkg/customfeeds.conf file. No opkg feeds are included.")
end

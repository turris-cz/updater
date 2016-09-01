--[[
Copyright 2016, CZ.NIC z.s.p.o. (http://www.nic.cz/)

This file is part of the turris updater.

Updater is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

Updater is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with Updater.  If not, see <http://www.gnu.org/licenses/>.
]]--

require "lunit"
local migrator = require "migrator"

module("migrator-tests", package.seeall, lunit.testcase)

function test_pkgs_format()
	local pkgs = {YYY = true, XXX = true}
	assert_equal([[
>>XXX<<<
>>YYY<<<
]], migrator.pkgs_format(pkgs, ">>", "<<<"))
	assert_equal("", migrator.pkgs_format({}, "", ""))
	assert_equal("", migrator.pkgs_format({}, "!!!", "???"))
	assert_equal([[
XXX
YYY
]], migrator.pkgs_format(pkgs, "", ""))
end

function test_extra_pkgs()
	mock_gen("updater.required_pkgs", function () return {
		{
			action = 'reinstall',
			name = 'pkg1'
		},
		{
			action = 'require',
			name = 'pkg2'
		},
		{
			action = 'remove',
			name = 'pkg3'
		}
	} end)
	mock_gen("backend.status_parse", function ()
		-- A little bit smaller than the real thing, but this should be enough for the test
		local status = utils.map({'pkg1', 'pkg2', 'pkg3', 'pkg4', 'pkg5'}, function (_, name)
			return name, {
				Package = name,
				Status = {'install', 'user', 'installed'}
			}
		end)
		-- This one is mentioned but not actually installed, so check it doesn't get confused by that
		status.pkg4.Status[3] = 'not-installed'
		return status
	end)
	local result = migrator.extra_pkgs('epoint')
	--[[
	pkg1 not present, since it is required by the current configs
	pkg2 as well
	pkg3 is being removed by the current config, so it is present
	pkg4 is not installed, so it is not added
	pkg5 is installed but not mentioned by the planner, so we want to add it (this situation probably never happens in real life, though).
	]]
	assert_table_equal({pkg3 = true, pkg5 = true}, result)
	assert_table_equal({
		{
			f = "updater.required_pkgs",
			p = {"epoint"}
		},
		{
			f = "backend.status_parse",
			p = {}
		}
	}, mocks_called)
end

function teardown()
	mocks_reset()
end

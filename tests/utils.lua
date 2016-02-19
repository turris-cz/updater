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
local U = require "utils"

module("utils-tests", package.seeall, lunit.testcase)

function test_lines2set()
	local treq = {
		line = true,
		another = true
	}
	assert_table_equal(treq, U.lines2set([[line
another]]))
	assert_table_equal(treq, U.lines2set([[another
line]]))
	assert_table_equal(treq, U.lines2set([[line
another
line]]))
end

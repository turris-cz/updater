/*
 * Copyright 2016, CZ.NIC z.s.p.o. (http://www.nic.cz/)
 *
 * This file is part of NUCI configuration server.
 *
 * NUCI is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 * NUCI is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with NUCI.  If not, see <http://www.gnu.org/licenses/>.
 */

#include "ctest.h"

int main(void) {
	Suite *suite = gen_test_suite();
	SRunner *runner = srunner_create(suite);

	srunner_run_all(runner, CK_NORMAL);
	int failed = srunner_ntests_failed(runner);

	srunner_free(runner);
	return !!failed;
}

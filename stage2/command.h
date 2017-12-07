/* command.h: Command lookup
 *
 * Copyright 2016 Vincent Damewood
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#ifndef COMMAND_H
#define COMMAND_H

// FIXME: Once memory allocation is implemented, allow commands
// to be registered.
//int cmdRegister(const char *, int (*)(int,char*[]));
int (*cmdGet(const char*))(int,char*[]);

#endif /* COMMAND_H */

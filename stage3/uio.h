/* uio.h: User interface input/output
 *
 * Copyright 2015, 2016 Vincent Damewood
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

#ifndef UIO_H
#define UIO_H

#include <stdint.h>

const char *uioPrompt(const char *prompt);

// Output Functions
void  uioPrint(const char *string);
void  uioPrintChar(const char c);
void  uioPrintf(const char *format, ...);
void  uioPrintN(int length, const char *string);

#endif /* UIO_H */

/*
 * Copyright © 2009 Arnaud Fontaine <arnau@debian.org>
 *
 * Permission  is  hereby  granted,  free  of charge,  to  any  person
 * obtaining  a copy  of  this software  and associated  documentation
 * files   (the  "Software"),   to  deal   in  the   Software  without
 * restriction, including without limitation  the rights to use, copy,
 * modify, merge, publish,  distribute, sublicense, and/or sell copies
 * of  the Software, and  to permit  persons to  whom the  Software is
 * furnished to do so, subject to the following conditions:
 *
 * The  above copyright  notice and  this permission  notice  shall be
 * included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE  IS PROVIDED  "AS IS", WITHOUT  WARRANTY OF  ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT  NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY,   FITNESS    FOR   A   PARTICULAR    PURPOSE   AND
 * NONINFRINGEMENT. IN  NO EVENT SHALL  THE AUTHORS BE LIABLE  FOR ANY
 * CLAIM,  DAMAGES  OR  OTHER  LIABILITY,  WHETHER  IN  AN  ACTION  OF
 * CONTRACT, TORT OR OTHERWISE, ARISING  FROM, OUT OF OR IN CONNECTION
 * WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 *
 * Except as  contained in  this notice, the  names of the  authors or
 * their institutions shall not be used in advertising or otherwise to
 * promote the  sale, use or  other dealings in this  Software without
 * prior written authorization from the authors.
 */

#include <string.h>
#include <limits.h>
#include <stdlib.h>
#include <stdio.h>
#include <assert.h>

#include "xcb_ewmh.h"
#include "xcb_atom.h"
#include "xcb_aux.h"
#include "../xcb-util-common.h"

/**
 * @brief The  structure used  on screen initialization  including the
 * atoms name and its length
 */
typedef struct {
  /** The Atom name length */
  uint8_t name_len;
  /** The Atom name string */
  char *name;
} ewmh_atom_t;

define(`DO_ENTRY', `
  { sizeof("$1") - 1, "$1" }ifelse(`$2', , , `,')')dnl

define(`DO', `DO_ENTRY(`$1', `$2')ifelse(`$2', , , `DO(shift($@))')')dnl

/**
 * @brief List  of atoms where each  entry contains the  Atom name and
 * its length
 */
static ewmh_atom_t ewmh_atoms[] = {dnl
                                   include(atomlist.m4)dnl
};

#define NB_EWMH_ATOMS countof(ewmh_atoms)

/** Get the number of elements from the reply length */
#define GET_NB_FROM_LEN(len, shift_value) ((len) >> (shift_value))

/** Get the length of elements from the number of elements of a reply */
#define GET_LEN_FROM_NB(nb, shift_value) ((nb) << (shift_value))

/**
 * Common functions and macro
 */

#define DO_GET_PROPERTY(atom, name, request_type, length)               \
  xcb_get_property_cookie_t                                             \
  xcb_ewmh_get_##name(xcb_ewmh_connection_t *ewmh,                      \
                      xcb_window_t window)                              \
  {                                                                     \
    return xcb_get_property(ewmh->connection, 0, window, ewmh->atom,    \
                            request_type, 0, length);                   \
  }                                                                     \
                                                                        \
  xcb_get_property_cookie_t                                             \
  xcb_ewmh_get_##name##_unchecked(xcb_ewmh_connection_t *ewmh,          \
                                  xcb_window_t window)                  \
  {                                                                     \
    return xcb_get_property_unchecked(ewmh->connection, 0, window,      \
                                      ewmh->atom, request_type, 0,      \
                                      length);                          \
  }

#define DO_GET_ROOT_PROPERTY(atom, name, request_type, length)          \
  xcb_get_property_cookie_t                                             \
  xcb_ewmh_get_##name(xcb_ewmh_connection_t *ewmh)                      \
  {                                                                     \
    return xcb_get_property(ewmh->connection, 0, ewmh->root,            \
                            ewmh->atom, request_type, 0, length);       \
  }                                                                     \
                                                                        \
  xcb_get_property_cookie_t                                             \
  xcb_ewmh_get_##name##_unchecked(xcb_ewmh_connection_t *ewmh)          \
  {                                                                     \
    return xcb_get_property_unchecked(ewmh->connection, 0, ewmh->root,  \
                                      ewmh->atom, request_type, 0,      \
                                      length);                          \
  }

/**
 * Generic  function for  EWMH atoms  with  a single  value which  may
 * actually be either WINDOW or CARDINAL
 *
 * _NET_NUMBER_OF_DESKTOPS, CARDINAL/32
 * _NET_CURRENT_DESKTOP desktop, CARDINAL/32
 * _NET_ACTIVE_WINDOW, WINDOW/32
 * _NET_SUPPORTING_WM_CHECK, WINDOW/32
 * _NET_SHOWING_DESKTOP desktop, CARDINAL/32
 * _NET_WM_DESKTOP desktop, CARDINAL/32
 * _NET_WM_PID CARDINAL/32
 * _NET_WM_USER_TIME CARDINAL/32
 * _NET_WM_USER_TIME_WINDOW WINDOW/32
 */

/**
 * Macro defining  a generic function  for reply with a  single value,
 * considering that the  value is 32-bit long (actually  only used for
 * WINDOW and CARDINAL)
 */
#define DO_REPLY_SINGLE_VALUE(name, name_type, reply_type)              \
  uint8_t								\
  xcb_ewmh_get_##name##_from_reply(name_type *atom_value,		\
				   xcb_get_property_reply_t *r)		\
  {                                                                     \
    if(!r || r->type != reply_type || r->format != 32 ||                \
       xcb_get_property_value_length(r) != 4)                           \
      return 0;                                                         \
                                                                        \
    *atom_value = *((name_type *) xcb_get_property_value(r));           \
    return 1;                                                           \
  }                                                                     \
                                                                        \
  uint8_t								\
  xcb_ewmh_get_##name##_reply(xcb_ewmh_connection_t *ewmh,		\
			      xcb_get_property_cookie_t cookie,		\
			      name_type *atom_value,			\
			      xcb_generic_error_t **e)			\
  {                                                                     \
    xcb_get_property_reply_t *r =                                       \
      xcb_get_property_reply(ewmh->connection,                          \
                             cookie, e);                                \
                                                                        \
    const uint8_t ret = xcb_ewmh_get_##name##_from_reply(atom_value, r); \
                                                                        \
    free(r);                                                            \
    return ret;                                                         \
  }

/** Define reply functions for common WINDOW Atom */
DO_REPLY_SINGLE_VALUE(window, xcb_window_t, WINDOW)

/** Define reply functions for common CARDINAL Atom */
DO_REPLY_SINGLE_VALUE(cardinal, uint32_t, CARDINAL)

#define DO_SINGLE_VALUE(atom, name, reply_type,                         \
                        out_type, func_reply)                           \
  DO_GET_PROPERTY(atom, name, reply_type, 1L)                           \
                                                                        \
  xcb_void_cookie_t                                                     \
  xcb_ewmh_set_##name##_checked(xcb_ewmh_connection_t *ewmh,            \
                                xcb_window_t window,                    \
                                out_type value)                         \
  {                                                                     \
    return xcb_change_property_checked(ewmh->connection,                \
                                       XCB_PROP_MODE_REPLACE,           \
                                       window, ewmh->atom,              \
                                       reply_type, 32, 1,               \
                                       &value);                         \
  }                                                                     \
                                                                        \
  xcb_void_cookie_t                                                     \
  xcb_ewmh_set_##name(xcb_ewmh_connection_t *ewmh,                      \
                      xcb_window_t window,                              \
                      out_type value)                                   \
  {                                                                     \
    return xcb_change_property(ewmh->connection, XCB_PROP_MODE_REPLACE, \
                               window, ewmh->atom, reply_type, 32, 1,   \
                               &value);                                 \
  }

#define DO_ROOT_SINGLE_VALUE(atom, name, reply_type,                    \
                             out_type, func_reply)                      \
  DO_GET_ROOT_PROPERTY(atom, name, reply_type, 1L)                      \
                                                                        \
  xcb_void_cookie_t                                                     \
  xcb_ewmh_set_##name##_checked(xcb_ewmh_connection_t *ewmh,            \
                                out_type value)                         \
  {                                                                     \
    return xcb_change_property_checked(ewmh->connection,                \
                                       XCB_PROP_MODE_REPLACE,           \
                                       ewmh->root, ewmh->atom,          \
                                       reply_type, 32, 1, &value);      \
  }                                                                     \
                                                                        \
  xcb_void_cookie_t                                                     \
  xcb_ewmh_set_##name(xcb_ewmh_connection_t *ewmh,                      \
                      out_type value)                                   \
  {                                                                     \
    return xcb_change_property(ewmh->connection, XCB_PROP_MODE_REPLACE, \
                               ewmh->root, ewmh->atom, reply_type,      \
                               32, 1, &value);                          \
  }

/**
 * Generic function for EWMH atoms with  a list of values which may be
 * actually WINDOW or ATOM.
 *
 * _NET_SUPPORTED, ATOM[]/32
 * _NET_CLIENT_LIST, WINDOW[]/32
 * _NET_CLIENT_LIST_STACKING, WINDOW[]/32
 * _NET_VIRTUAL_ROOTS, WINDOW[]/32
 * _NET_WM_WINDOW_TYPE, ATOM[]/32
 * _NET_WM_ALLOWED_ACTIONS, ATOM[]
 */

/**
 * Macro defining  a generic function  for reply containing a  list of
 * values and also defines a function to wipe the reply.
 *
 * The length is right-shifted by  (len_shift + 2) respectively to get
 * the actual length of a list  values from a value made from multiple
 * component  (such as  coordinates), and  divide by  (r->format  / 8)
 * where r->format always equals to 32 in this case.
 */
#define DO_REPLY_LIST_VALUES_ATOM(name, name_type, reply_type)		\
  uint8_t                                                               \
  xcb_ewmh_get_##name##_from_reply(xcb_ewmh_get_##name##_reply_t *data, \
                                   xcb_get_property_reply_t *r)         \
  {                                                                     \
    if(!r || r->type != reply_type || r->format != 32)                  \
      return 0;                                                         \
                                                                        \
    data->_reply = r;                                                   \
    data->name##_len = xcb_get_property_value_length(data->_reply) /	\
      sizeof(name_type);						\
                                                                        \
    data->name = (name_type *) xcb_get_property_value(data->_reply);    \
    return 1;                                                           \
  }                                                                     \
                                                                        \
  uint8_t                                                               \
  xcb_ewmh_get_##name##_reply(xcb_ewmh_connection_t *ewmh,              \
                              xcb_get_property_cookie_t cookie,         \
                              xcb_ewmh_get_##name##_reply_t *data,      \
                              xcb_generic_error_t **e)                  \
  {                                                                     \
    xcb_get_property_reply_t *r =                                       \
      xcb_get_property_reply(ewmh->connection,                          \
                             cookie, e);                                \
                                                                        \
    const uint8_t ret = xcb_ewmh_get_##name##_from_reply(data, r);      \
                                                                        \
    /* If the  last call  was not successful  (ret equals to  0), then  \
       just free the reply as the data value is not consistent */       \
    if(!ret)                                                            \
      free(r);                                                          \
                                                                        \
    return ret;                                                         \
  }                                                                     \
                                                                        \
  void                                                                  \
  xcb_ewmh_get_##name##_reply_wipe(xcb_ewmh_get_##name##_reply_t *data) \
  {                                                                     \
    free(data->_reply);                                                 \
  }

#define DO_ROOT_LIST_VALUES(atom, name, kind_type, kind, shift)         \
  DO_GET_ROOT_PROPERTY(atom, name, kind_type, UINT_MAX)                 \
                                                                        \
  xcb_void_cookie_t                                                     \
  xcb_ewmh_set_##name##_checked(xcb_ewmh_connection_t *ewmh,            \
                                uint32_t list_len,                      \
                                xcb_##kind##_t *list)                   \
  {                                                                     \
    return xcb_change_property_checked(ewmh->connection,                \
                                       XCB_PROP_MODE_REPLACE,           \
                                       ewmh->root, ewmh->atom,          \
                                       kind_type, 32,                   \
                                       GET_LEN_FROM_NB(list_len,        \
                                                       shift),          \
                                       list);                           \
  }                                                                     \
                                                                        \
  xcb_void_cookie_t                                                     \
  xcb_ewmh_set_##name(xcb_ewmh_connection_t *ewmh,                      \
                      uint32_t list_len,                                \
                      xcb_##kind##_t *list)                             \
  {                                                                     \
    return xcb_change_property(ewmh->connection, XCB_PROP_MODE_REPLACE, \
                               ewmh->root, ewmh->atom, kind_type,       \
                               32, GET_LEN_FROM_NB(list_len, shift),    \
                               list);                                   \
  }

#define DO_LIST_VALUES(atom, name, kind_type, kind)                     \
  DO_GET_PROPERTY(atom, name, kind_type, UINT_MAX)                      \
                                                                        \
  xcb_void_cookie_t                                                     \
  xcb_ewmh_set_##name##_checked(xcb_ewmh_connection_t *ewmh,            \
                                xcb_window_t window,                    \
                                uint32_t list_len,                      \
                                xcb_##kind##_t *list)                   \
  {                                                                     \
    return xcb_change_property_checked(ewmh->connection,                \
                                       XCB_PROP_MODE_REPLACE, window,   \
                                       ewmh->atom, kind_type, 32,       \
                                       list_len, list);                 \
  }                                                                     \
                                                                        \
  xcb_void_cookie_t                                                     \
  xcb_ewmh_set_##name(xcb_ewmh_connection_t *ewmh,                      \
                      xcb_window_t window,                              \
                      uint32_t list_len,                                \
                      xcb_##kind##_t *list)                             \
  {                                                                     \
    return xcb_change_property(ewmh->connection, XCB_PROP_MODE_REPLACE, \
                               window, ewmh->atom, kind_type, 32,       \
                               list_len, list);                         \
  }                                                                     \
                                                                        \
  uint8_t                                                               \
  xcb_ewmh_get_##name##_from_reply(xcb_ewmh_get_##kind##s_reply_t *name, \
                                   xcb_get_property_reply_t *r)         \
  {                                                                     \
    return xcb_ewmh_get_##kind##s_from_reply(name, r);                  \
  }                                                                     \
                                                                        \
  uint8_t                                                               \
  xcb_ewmh_get_##name##_reply(xcb_ewmh_connection_t *ewmh,              \
                              xcb_get_property_cookie_t cookie,         \
                              xcb_ewmh_get_##kind##s_reply_t *name,     \
                              xcb_generic_error_t **e)                  \
  {                                                                     \
    return xcb_ewmh_get_##kind##s_reply(ewmh, cookie, name, e);         \
  }

#define DO_REPLY_STRUCTURE(name, out_type)                              \
  uint8_t                                                               \
  xcb_ewmh_get_##name##_from_reply(out_type *out,                       \
                                   xcb_get_property_reply_t *r)         \
  {                                                                     \
    if(!r || r->type != CARDINAL || r->format != 32 ||                  \
       xcb_get_property_value_length(r) != sizeof(out_type))            \
      return 0;                                                         \
                                                                        \
    memcpy(out, xcb_get_property_value(r),                              \
           xcb_get_property_value_length(r));                           \
                                                                        \
    return 1;                                                           \
  }                                                                     \
                                                                        \
  uint8_t                                                               \
  xcb_ewmh_get_##name##_reply(xcb_ewmh_connection_t *ewmh,              \
                              xcb_get_property_cookie_t cookie,         \
                              out_type *out,                            \
                              xcb_generic_error_t **e)                  \
  {                                                                     \
    xcb_get_property_reply_t *r =                                       \
      xcb_get_property_reply(ewmh->connection, cookie, e);              \
                                                                        \
    const uint8_t ret = xcb_ewmh_get_##name##_from_reply(out, r);       \
    free(r);                                                            \
    return ret;                                                         \
  }

/**
 * UTF8_STRING handling
 */

uint8_t
xcb_ewmh_get_utf8_strings_from_reply(xcb_ewmh_connection_t *ewmh,
                                     xcb_ewmh_get_utf8_strings_reply_t *data,
                                     xcb_get_property_reply_t *r)
{
  if(!r || r->type != ewmh->UTF8_STRING || r->format != 8)
    return 0;

  data->_reply = r;
  data->strings_len = xcb_get_property_value_length(data->_reply);
  data->strings = (char *) xcb_get_property_value(data->_reply);

  return 1;
}

uint8_t
xcb_ewmh_get_utf8_strings_reply(xcb_ewmh_connection_t *ewmh,
                                xcb_get_property_cookie_t cookie,
                                xcb_ewmh_get_utf8_strings_reply_t *data,
                                xcb_generic_error_t **e)
{
  xcb_get_property_reply_t *r = xcb_get_property_reply(ewmh->connection,
                                                       cookie, e);

  const uint8_t ret = xcb_ewmh_get_utf8_strings_from_reply(ewmh, data, r);

  /* If the last call was not  successful (ret equals to 0), then just
     free the reply as the data value is not consistent */
  if(!ret)
    free(r);

  return ret;
}

void
xcb_ewmh_get_utf8_strings_reply_wipe(xcb_ewmh_get_utf8_strings_reply_t *data)
{
  free(data->_reply);
}

#define DO_REPLY_UTF8_STRING(atom, name)                                \
  uint8_t                                                               \
  xcb_ewmh_get_##name##_from_reply(xcb_ewmh_connection_t *ewmh,         \
                                   xcb_ewmh_get_utf8_strings_reply_t *data, \
                                   xcb_get_property_reply_t *r)         \
  {                                                                     \
    return xcb_ewmh_get_utf8_strings_from_reply(ewmh, data, r);         \
  }                                                                     \
                                                                        \
  uint8_t                                                               \
  xcb_ewmh_get_##name##_reply(xcb_ewmh_connection_t *ewmh,              \
                              xcb_get_property_cookie_t cookie,         \
                              xcb_ewmh_get_utf8_strings_reply_t *data,  \
                              xcb_generic_error_t **e)                  \
  {                                                                     \
    return xcb_ewmh_get_utf8_strings_reply(ewmh, cookie, data, e);      \
  }

#define DO_ROOT_UTF8_STRING(atom, name)                                 \
  DO_GET_ROOT_PROPERTY(atom, name, 0, UINT_MAX)                         \
  DO_REPLY_UTF8_STRING(atom, name)                                      \
                                                                        \
  xcb_void_cookie_t                                                     \
  xcb_ewmh_set_##name(xcb_ewmh_connection_t *ewmh,                      \
                      uint32_t strings_len,                             \
                      const char *strings)                              \
  {                                                                     \
    return xcb_change_property(ewmh->connection, XCB_PROP_MODE_REPLACE, \
                               ewmh->root, ewmh->atom,                  \
                               ewmh->UTF8_STRING, 8, strings_len,       \
                               strings);                                \
  }                                                                     \
                                                                        \
  xcb_void_cookie_t                                                     \
  xcb_ewmh_set_##name##_checked(xcb_ewmh_connection_t *ewmh,            \
                                uint32_t strings_len,                   \
                                const char *strings)                    \
  {                                                                     \
    return xcb_change_property_checked(ewmh->connection,                \
                                       XCB_PROP_MODE_REPLACE,           \
                                       ewmh->root, ewmh->atom,          \
                                       ewmh->UTF8_STRING, 8,            \
                                       strings_len, strings);           \
  }

#define DO_UTF8_STRING(atom, name)                                      \
  DO_GET_PROPERTY(atom, name, 0, UINT_MAX)                              \
  DO_REPLY_UTF8_STRING(atom, name)                                      \
                                                                        \
  xcb_void_cookie_t                                                     \
  xcb_ewmh_set_##name(xcb_ewmh_connection_t *ewmh,                      \
                      xcb_window_t window,                              \
                      uint32_t strings_len,                             \
                      const char *strings)                              \
  {                                                                     \
    return xcb_change_property(ewmh->connection, XCB_PROP_MODE_REPLACE, \
                               window, ewmh->atom, ewmh->UTF8_STRING,   \
                               8, strings_len, strings);                \
  }                                                                     \
                                                                        \
  xcb_void_cookie_t                                                     \
  xcb_ewmh_set_##name##_checked(xcb_ewmh_connection_t *ewmh,            \
                                xcb_window_t window,                    \
                                uint32_t strings_len,                   \
                                const char *strings)                    \
  {                                                                     \
    return xcb_change_property_checked(ewmh->connection,                \
                                       XCB_PROP_MODE_REPLACE,           \
                                       window, ewmh->atom,              \
                                       ewmh->UTF8_STRING, 8,            \
                                       strings_len, strings);           \
  }

/**
 * ClientMessage generic function
 */
xcb_void_cookie_t
xcb_ewmh_send_client_message(xcb_connection_t *c,
                             xcb_window_t window,
                             xcb_window_t dest,
                             xcb_atom_t atom,
                             uint32_t data_len,
                             const uint32_t *data)
{
  xcb_client_message_event_t ev;
  memset(&ev, 0, sizeof(xcb_client_message_event_t));

  ev.response_type = XCB_CLIENT_MESSAGE;
  ev.window = window;
  ev.format = 32;
  ev.type = atom;

  while(data_len)
    {
      data_len--;
      ev.data.data32[data_len] = data[data_len];
    }

  return xcb_send_event(c, 0, dest, XCB_EVENT_MASK_SUBSTRUCTURE_NOTIFY |
                        XCB_EVENT_MASK_SUBSTRUCTURE_REDIRECT,
                        (char *) &ev);
}

DO_REPLY_LIST_VALUES_ATOM(windows, xcb_window_t, WINDOW)
DO_REPLY_LIST_VALUES_ATOM(atoms, xcb_atom_t, ATOM)

/**
 * Atoms initialisation
 */

xcb_intern_atom_cookie_t *
xcb_ewmh_init_atoms(xcb_connection_t *c,
                    xcb_ewmh_connection_t * const ewmh,
                    const int screen_nbr)
{
  ewmh->connection = c;

  xcb_screen_t *screen = xcb_aux_get_screen(ewmh->connection, screen_nbr);
  if(!screen)
    return NULL;

  /* Compute _NET_WM_CM_Sn according to the screen number 'n' */
  char wm_cm_sn[32];
  const int wm_cm_sn_len = snprintf(wm_cm_sn, 32, "_NET_WM_CM_S%d",
                                    screen_nbr);

  assert(wm_cm_sn_len > 0 && wm_cm_sn_len < 32);

  ewmh->root = screen->root;

  xcb_intern_atom_cookie_t *ewmh_cookies = malloc(sizeof(xcb_intern_atom_cookie_t) *
                                                  NB_EWMH_ATOMS);

  uint8_t i;
  for(i = 0; i < NB_EWMH_ATOMS; i++)
    {
      if(strcmp(ewmh_atoms[i].name, "_NET_WM_CM_Sn") == 0)
        ewmh_cookies[i] = xcb_intern_atom(ewmh->connection, 0,
                                          wm_cm_sn_len, wm_cm_sn);
      else
        ewmh_cookies[i] = xcb_intern_atom(ewmh->connection, 0,
                                          ewmh_atoms[i].name_len,
                                          ewmh_atoms[i].name);
    }

  return ewmh_cookies;
}

uint8_t
xcb_ewmh_init_atoms_replies(xcb_ewmh_connection_t * const ewmh,
                            xcb_intern_atom_cookie_t *ewmh_cookies,
                            xcb_generic_error_t **e)
{
  uint8_t i = 0;
  xcb_intern_atom_reply_t *reply;

  define(`DO_ENTRY', `  if((reply = xcb_intern_atom_reply(ewmh->connection, ewmh_cookies[i++], e)) == NULL)
    goto init_atoms_replies_error;
  ewmh->$1 = reply->atom;
  free(reply);

')dnl
    include(atomlist.m4)dnl

  free(ewmh_cookies);
  return 1;

 init_atoms_replies_error:
  free(ewmh_cookies);
  return 0;
}

/**
 * _NET_SUPPORTED
 */

DO_ROOT_LIST_VALUES(_NET_SUPPORTED, supported, ATOM, atom, 0)

/**
 * _NET_CLIENT_LIST
 * _NET_CLIENT_LIST_STACKING
 */

DO_ROOT_LIST_VALUES(_NET_CLIENT_LIST, client_list, WINDOW, window, 0)

DO_ROOT_LIST_VALUES(_NET_CLIENT_LIST_STACKING, client_list_stacking, WINDOW,
                    window, 0)

/**
 * _NET_NUMBER_OF_DESKTOPS
 */

DO_ROOT_SINGLE_VALUE(_NET_NUMBER_OF_DESKTOPS, number_of_desktops,
                     CARDINAL, uint32_t, cardinal)

/**
 * _NET_DESKTOP_GEOMETRY
 */

DO_GET_ROOT_PROPERTY(_NET_DESKTOP_GEOMETRY, desktop_geometry, CARDINAL, 2L)

xcb_void_cookie_t
xcb_ewmh_set_desktop_geometry(xcb_ewmh_connection_t *ewmh,
                              uint32_t new_width, uint32_t new_height)
{
  const uint32_t data[] = { new_width, new_height };

  return xcb_change_property(ewmh->connection, XCB_PROP_MODE_REPLACE, ewmh->root,
                             ewmh->_NET_DESKTOP_GEOMETRY, CARDINAL, 32, 2, data);
}

xcb_void_cookie_t
xcb_ewmh_set_desktop_geometry_checked(xcb_ewmh_connection_t *ewmh,
                                      uint32_t new_width, uint32_t new_height)
{
  const uint32_t data[] = { new_width, new_height };

  return xcb_change_property_checked(ewmh->connection, XCB_PROP_MODE_REPLACE,
                                     ewmh->root, ewmh->_NET_DESKTOP_GEOMETRY,
                                     CARDINAL, 32, 2, data);
}

xcb_void_cookie_t
xcb_ewmh_request_change_desktop_geometry(xcb_ewmh_connection_t *ewmh,
                                         uint32_t new_width, uint32_t new_height)
{
  const uint32_t data[] = { new_width, new_height };

  return xcb_ewmh_send_client_message(ewmh->connection, XCB_NONE, ewmh->root,
                                      ewmh->_NET_DESKTOP_GEOMETRY, 2, data);
}

uint8_t
xcb_ewmh_get_desktop_geometry_from_reply(uint32_t *width, uint32_t *height,
                                         xcb_get_property_reply_t *r)
{
  if(!r || r->type != CARDINAL || r->format != 32 ||
     xcb_get_property_value_length(r) != 8)
    return 0;

  uint32_t *value = (uint32_t *) xcb_get_property_value(r);

  *width = value[0];
  *height = value[1];

  return 1;
}

uint8_t
xcb_ewmh_get_desktop_geometry_reply(xcb_ewmh_connection_t *ewmh,
                                    xcb_get_property_cookie_t cookie,
                                    uint32_t *width, uint32_t *height,
                                    xcb_generic_error_t **e)
{
  xcb_get_property_reply_t *r = xcb_get_property_reply(ewmh->connection, cookie, e);
  const uint8_t ret = xcb_ewmh_get_desktop_geometry_from_reply(width, height, r);
  free(r);
  return ret;
}

/**
 * _NET_DESKTOP_VIEWPORT
 */

DO_ROOT_LIST_VALUES(_NET_DESKTOP_VIEWPORT, desktop_viewport, CARDINAL,
                    ewmh_coordinates, 1)

DO_REPLY_LIST_VALUES_ATOM(desktop_viewport, xcb_ewmh_coordinates_t, CARDINAL)

xcb_void_cookie_t
xcb_ewmh_request_change_desktop_viewport(xcb_ewmh_connection_t *ewmh,
                                         uint32_t x, uint32_t y)
{
  const uint32_t data[] = { x, y };

  return xcb_ewmh_send_client_message(ewmh->connection, XCB_NONE, ewmh->root,
                                      ewmh->_NET_DESKTOP_VIEWPORT, 2, data);
}

/**
 * _NET_CURRENT_DESKTOP
 */

DO_ROOT_SINGLE_VALUE(_NET_CURRENT_DESKTOP, current_desktop,
                     CARDINAL, uint32_t, cardinal)

xcb_void_cookie_t
xcb_ewmh_request_change_current_desktop(xcb_ewmh_connection_t *ewmh,
                                        uint32_t new_desktop,
                                        xcb_timestamp_t timestamp)
{
  const uint32_t data[] = { new_desktop, timestamp };

  return xcb_ewmh_send_client_message(ewmh->connection, XCB_NONE, ewmh->root,
                                      ewmh->_NET_CURRENT_DESKTOP, 2, data);
}

/**
 * _NET_DESKTOP_NAMES
 */
DO_ROOT_UTF8_STRING(_NET_DESKTOP_NAMES, desktop_names)

/**
 * _NET_ACTIVE_WINDOW
 */

DO_ROOT_SINGLE_VALUE(_NET_ACTIVE_WINDOW, active_window,
                     WINDOW, xcb_window_t, window)

xcb_void_cookie_t
xcb_ewmh_request_change_active_window(xcb_ewmh_connection_t *ewmh,
                                      xcb_window_t window_to_activate,
                                      xcb_ewmh_client_source_type_t source_indication,
                                      xcb_timestamp_t timestamp,
                                      xcb_window_t current_active_window)
{
  const uint32_t data[] = { source_indication, timestamp, current_active_window };

  return xcb_ewmh_send_client_message(ewmh->connection, window_to_activate,
                                      ewmh->root, ewmh->_NET_ACTIVE_WINDOW,
                                      3, data);
}

/**
 * _NET_WORKAREA
 */

DO_ROOT_LIST_VALUES(_NET_WORKAREA, workarea, CARDINAL, ewmh_geometry, 2)
DO_REPLY_LIST_VALUES_ATOM(workarea, xcb_ewmh_geometry_t, CARDINAL)

/**
 * _NET_SUPPORTING_WM_CHECK
 */

DO_ROOT_SINGLE_VALUE(_NET_SUPPORTING_WM_CHECK, supporting_wm_check,
                     WINDOW, xcb_window_t, window)

/**
 * _NET_VIRTUAL_ROOTS
 */

DO_ROOT_LIST_VALUES(_NET_VIRTUAL_ROOTS, virtual_roots, WINDOW, window, 0)

/**
 * _NET_DESKTOP_LAYOUT
 */

DO_GET_ROOT_PROPERTY(_NET_DESKTOP_LAYOUT, desktop_layout, CARDINAL, 4)
DO_REPLY_STRUCTURE(desktop_layout, xcb_ewmh_get_desktop_layout_reply_t)

xcb_void_cookie_t
xcb_ewmh_set_desktop_layout(xcb_ewmh_connection_t *ewmh,
                            xcb_ewmh_desktop_layout_orientation_t orientation,
                            uint32_t columns, uint32_t rows,
                            xcb_ewmh_desktop_layout_starting_corner_t starting_corner)
{
  const uint32_t data[] = { orientation, columns, rows, starting_corner };

  return xcb_change_property(ewmh->connection, XCB_PROP_MODE_REPLACE, ewmh->root,
                             ewmh->_NET_DESKTOP_LAYOUT, CARDINAL, 32, 2, data);
}

xcb_void_cookie_t
xcb_ewmh_set_desktop_layout_checked(xcb_ewmh_connection_t *ewmh,
                                    xcb_ewmh_desktop_layout_orientation_t orientation,
                                    uint32_t columns, uint32_t rows,
                                    xcb_ewmh_desktop_layout_starting_corner_t starting_corner)
{
  const uint32_t data[] = { orientation, columns, rows, starting_corner };

  return xcb_change_property_checked(ewmh->connection, XCB_PROP_MODE_REPLACE,
                                     ewmh->root, ewmh->_NET_DESKTOP_LAYOUT,
                                     CARDINAL, 32, 2, data);
}

/**
 * _NET_SHOWING_DESKTOP
 */

DO_ROOT_SINGLE_VALUE(_NET_SHOWING_DESKTOP, showing_desktop, CARDINAL,
                     uint32_t, cardinal)

/**
 * _NET_CLOSE_WINDOW
 */

xcb_void_cookie_t
xcb_ewmh_request_close_window(xcb_ewmh_connection_t *ewmh,
                              xcb_window_t window_to_close,
                              xcb_timestamp_t timestamp,
                              xcb_ewmh_client_source_type_t source_indication)
{
  const uint32_t data[] = { timestamp, source_indication };

  return xcb_ewmh_send_client_message(ewmh->connection, window_to_close, ewmh->root,
                                      ewmh->_NET_CLOSE_WINDOW, 2, data);
}

/**
 * _NET_MOVERESIZE_WINDOW
 */

/* x, y, width, height may be equal to -1 */
xcb_void_cookie_t
xcb_ewmh_request_moveresize_window(xcb_ewmh_connection_t *ewmh,
                                   xcb_window_t moveresize_window,
                                   xcb_gravity_t gravity,
                                   xcb_ewmh_client_source_type_t source_indication,
                                   xcb_ewmh_moveresize_window_opt_flags_t flags,
                                   uint32_t x, uint32_t y,
                                   uint32_t width, uint32_t height)
{
  const uint32_t data[] = { (gravity | flags |
                             GET_LEN_FROM_NB(source_indication, 12)),
                            x, y, width, height };

  return xcb_ewmh_send_client_message(ewmh->connection, moveresize_window,
                                      ewmh->root, ewmh->_NET_MOVERESIZE_WINDOW,
                                      5, data);
}

/**
 * _NET_WM_MOVERESIZE
 */

xcb_void_cookie_t
xcb_ewmh_request_wm_moveresize(xcb_ewmh_connection_t *ewmh,
                               xcb_window_t moveresize_window,
                               uint32_t x_root, uint32_t y_root,
                               xcb_ewmh_moveresize_direction_t direction,
                               xcb_button_index_t button,
                               xcb_ewmh_client_source_type_t source_indication)
{
  const uint32_t data[] = { x_root, y_root, direction, button, source_indication };

  return xcb_ewmh_send_client_message(ewmh->connection, moveresize_window,
                                      ewmh->root, ewmh->_NET_WM_MOVERESIZE,
                                      5, data);
}

/**
 * _NET_RESTACK_WINDOW
 */

xcb_void_cookie_t
xcb_ewmh_request_restack_window(xcb_ewmh_connection_t *ewmh,
                                xcb_window_t window_to_restack,
                                xcb_window_t sibling_window,
                                xcb_stack_mode_t detail)
{
  const uint32_t data[] = { XCB_EWMH_CLIENT_SOURCE_TYPE_OTHER, sibling_window,
                            detail };

  return xcb_ewmh_send_client_message(ewmh->connection, window_to_restack,
                                      ewmh->root, ewmh->_NET_RESTACK_WINDOW,
                                      3, data);
}

/**
 * _NET_WM_NAME
 */

DO_UTF8_STRING(_NET_WM_NAME, wm_name)

/**
 * _NET_WM_VISIBLE_NAME
 */

DO_UTF8_STRING(_NET_WM_VISIBLE_NAME, wm_visible_name)

/**
 * _NET_WM_ICON_NAME
 */

DO_UTF8_STRING(_NET_WM_ICON_NAME, wm_icon_name)

/**
 * _NET_WM_VISIBLE_ICON_NAME
 */

DO_UTF8_STRING(_NET_WM_VISIBLE_ICON_NAME, wm_visible_icon_name)

/**
 * _NET_WM_DESKTOP
 */

DO_SINGLE_VALUE(_NET_WM_DESKTOP, wm_desktop, CARDINAL, uint32_t, cardinal)

xcb_void_cookie_t
xcb_ewmh_request_change_wm_desktop(xcb_ewmh_connection_t *ewmh,
                                   xcb_window_t client_window,
                                   uint32_t new_desktop,
                                   xcb_ewmh_client_source_type_t source_indication)
{
  const uint32_t data[] = { new_desktop, source_indication };

  return xcb_ewmh_send_client_message(ewmh->connection, client_window, ewmh->root,
                                      ewmh->_NET_WM_DESKTOP, 2, data);
}

/**
 * _NET_WM_WINDOW_TYPE
 *
 * TODO: check possible atoms?
 */

DO_LIST_VALUES(_NET_WM_WINDOW_TYPE, wm_window_type, ATOM, atom)

/**
 * _NET_WM_STATE
 *
 * TODO: check possible atoms?
 */

DO_LIST_VALUES(_NET_WM_STATE, wm_state, ATOM, atom)

xcb_void_cookie_t
xcb_ewmh_request_change_wm_state(xcb_ewmh_connection_t *ewmh,
                                 xcb_window_t client_window,
                                 xcb_ewmh_wm_state_action_t action,
                                 xcb_atom_t first_property,
                                 xcb_atom_t second_property,
                                 xcb_ewmh_client_source_type_t source_indication)
{
  const uint32_t data[] = { action, first_property, second_property,
                            source_indication };

  return xcb_ewmh_send_client_message(ewmh->connection, client_window, ewmh->root,
                                      ewmh->_NET_WM_STATE, 4, data);
}

/**
 * _NET_WM_ALLOWED_ACTIONS
 *
 * TODO: check possible atoms?
 */

DO_LIST_VALUES(_NET_WM_ALLOWED_ACTIONS, wm_allowed_actions, ATOM, atom)

/**
 * _NET_WM_STRUT
 * _NET_WM_STRUT_PARTIAL
 */

xcb_void_cookie_t
xcb_ewmh_set_wm_strut(xcb_ewmh_connection_t *ewmh,
                      xcb_window_t window,
                      xcb_ewmh_wm_strut_t wm_strut)
{
  return xcb_change_property(ewmh->connection, XCB_PROP_MODE_REPLACE, window,
                             ewmh->_NET_WM_STRUT, CARDINAL, 32, 12, &wm_strut);
}

xcb_void_cookie_t
xcb_ewmh_set_wm_strut_checked(xcb_ewmh_connection_t *ewmh,
                              xcb_window_t window,
                              xcb_ewmh_wm_strut_t wm_strut)
{
  return xcb_change_property_checked(ewmh->connection, XCB_PROP_MODE_REPLACE,
                                     window, ewmh->_NET_WM_STRUT, CARDINAL, 32,
                                     12, &wm_strut);
}

DO_GET_PROPERTY(_NET_WM_STRUT, wm_strut, CARDINAL, 12)
DO_REPLY_STRUCTURE(wm_strut, xcb_ewmh_wm_strut_t)

/**
 * _NET_WM_ICON_GEOMETRY
 */

xcb_void_cookie_t
xcb_ewmh_set_wm_icon_geometry_checked(xcb_ewmh_connection_t *ewmh,
                                      xcb_window_t window,
                                      uint32_t left, uint32_t right,
                                      uint32_t top, uint32_t bottom)
{
  const uint32_t data[] = { left, right, top, bottom };

  return xcb_change_property_checked(ewmh->connection, XCB_PROP_MODE_REPLACE,
                                     window, ewmh->_NET_WM_ICON_GEOMETRY,
                                     CARDINAL, 32, 4, data);
}

xcb_void_cookie_t
xcb_ewmh_set_wm_icon_geometry(xcb_ewmh_connection_t *ewmh,
                              xcb_window_t window,
                              uint32_t left, uint32_t right,
                              uint32_t top, uint32_t bottom)
{
  const uint32_t data[] = { left, right, top, bottom };

  return xcb_change_property(ewmh->connection, XCB_PROP_MODE_REPLACE, window,
                             ewmh->_NET_WM_ICON_GEOMETRY, CARDINAL, 32, 4, data);
}

DO_GET_PROPERTY(_NET_WM_ICON_GEOMETRY, wm_icon_geometry, CARDINAL, 4)
DO_REPLY_STRUCTURE(wm_icon_geometry, xcb_ewmh_geometry_t)

/**
 * _NET_WM_ICON
 */

static inline void
set_wm_icon_data(uint32_t data[], uint32_t width, uint32_t height,
                 uint32_t img_len, uint32_t *img)
{
  data[0] = width;
  data[1] = height;

  memcpy(data + 2, img, img_len);
}

xcb_void_cookie_t
xcb_ewmh_set_wm_icon_checked(xcb_ewmh_connection_t *ewmh,
                             xcb_window_t window,
                             uint32_t width, uint32_t height,
                             uint32_t img_len, uint32_t *img)
{
  const uint32_t data_len = img_len + 2;
  uint32_t data[data_len];

  set_wm_icon_data(data, width, height, img_len, img);

  return xcb_change_property_checked(ewmh->connection, XCB_PROP_MODE_REPLACE,
                                     window, ewmh->_NET_WM_ICON, CARDINAL, 32,
                                     data_len, data);
}

xcb_void_cookie_t
xcb_ewmh_set_wm_icon(xcb_ewmh_connection_t *ewmh,
                     xcb_window_t window,
                     uint32_t width, uint32_t height,
                     uint32_t img_len, uint32_t *img)
{
  const uint32_t data_len = img_len + 2;
  uint32_t data[data_len];

  set_wm_icon_data(data, width, height, img_len, img);

  return xcb_change_property(ewmh->connection, XCB_PROP_MODE_REPLACE, window,
                             ewmh->_NET_WM_ICON, CARDINAL, 32, data_len, data);
}

DO_GET_PROPERTY(_NET_WM_ICON, wm_icon, CARDINAL, UINT_MAX)

uint8_t
xcb_ewmh_get_wm_icon_from_reply(xcb_ewmh_get_wm_icon_reply_t *wm_icon,
                                xcb_get_property_reply_t *r)
{
  if(!r || r->type != CARDINAL || r->format != 32 ||
     GET_NB_FROM_LEN(xcb_get_property_value_length(r), 2) <= 2)
    return 0;

  wm_icon->_reply = r;
  uint32_t *r_value = (uint32_t *) xcb_get_property_value(wm_icon->_reply);

  wm_icon->width = r_value[0];
  wm_icon->height = r_value[1];
  wm_icon->data = r_value + 2;

  return 1;
}

uint8_t
xcb_ewmh_get_wm_icon_reply(xcb_ewmh_connection_t *ewmh,
                           xcb_get_property_cookie_t cookie,
                           xcb_ewmh_get_wm_icon_reply_t *wm_icon,
                           xcb_generic_error_t **e)
{
  xcb_get_property_reply_t *r = xcb_get_property_reply(ewmh->connection, cookie, e);
  const uint8_t ret = xcb_ewmh_get_wm_icon_from_reply(wm_icon, r);
  if(!ret)
    free(r);

  return ret;
}

void
xcb_ewmh_get_wm_icon_reply_wipe(xcb_ewmh_get_wm_icon_reply_t *wm_icon)
{
  free(wm_icon->_reply);
}

/**
 * _NET_WM_PID
 */

DO_SINGLE_VALUE(_NET_WM_PID, wm_pid, CARDINAL, uint32_t,
                cardinal)

/**
 * _NET_WM_USER_TIME
 */

DO_SINGLE_VALUE(_NET_WM_USER_TIME, wm_user_time, CARDINAL,
                uint32_t, cardinal)

/**
 * _NET_WM_USER_TIME_WINDOW
 */

DO_SINGLE_VALUE(_NET_WM_USER_TIME_WINDOW, wm_user_time_window,
                CARDINAL, uint32_t, cardinal)

/**
 * _NET_FRAME_EXTENTS
 */

xcb_void_cookie_t
xcb_ewmh_set_frame_extents(xcb_ewmh_connection_t *ewmh,
                           xcb_window_t window,
                           uint32_t left, uint32_t right,
                           uint32_t top, uint32_t bottom)
{
  const uint32_t data[] = { left, right, top, bottom };

  return xcb_change_property(ewmh->connection, XCB_PROP_MODE_REPLACE, window,
                             ewmh->_NET_FRAME_EXTENTS, CARDINAL, 32, 4, data);
}

xcb_void_cookie_t
xcb_ewmh_set_frame_extents_checked(xcb_ewmh_connection_t *ewmh,
                                   xcb_window_t window,
                                   uint32_t left, uint32_t right,
                                   uint32_t top, uint32_t bottom)
{
  const uint32_t data[] = { left, right, top, bottom };

  return xcb_change_property_checked(ewmh->connection, XCB_PROP_MODE_REPLACE,
                                     window, ewmh->_NET_FRAME_EXTENTS, CARDINAL,
                                     32, 4, data);
}

DO_GET_PROPERTY(_NET_FRAME_EXTENTS, frame_extents, CARDINAL, 4)
DO_REPLY_STRUCTURE(frame_extents, xcb_ewmh_get_frame_extents_reply_t)

/**
 * _NET_WM_PING
 *
 * TODO: client resend function?
 */

xcb_void_cookie_t
xcb_ewmh_send_wm_ping(xcb_ewmh_connection_t *ewmh,
                      xcb_window_t window,
                      xcb_timestamp_t timestamp)
{
  const uint32_t data[] = { ewmh->_NET_WM_PING, timestamp, window };

  return xcb_ewmh_send_client_message(ewmh->connection, window, window,
                                      ewmh->WM_PROTOCOLS, 3, data);
}

/**
 * _NET_WM_SYNC_REQUES
 * _NET_WM_SYNC_REQUEST_COUNTER
 */

xcb_void_cookie_t
xcb_ewmh_set_wm_sync_request_counter(xcb_ewmh_connection_t *ewmh,
                                     xcb_window_t window,
                                     xcb_atom_t wm_sync_request_counter_atom,
                                     uint32_t low, uint32_t high)
{
  const uint32_t data[] = { low, high };

  return xcb_change_property(ewmh->connection, XCB_PROP_MODE_REPLACE, window,
                             ewmh->_NET_WM_SYNC_REQUEST, CARDINAL, 32, 2, data);
}

xcb_void_cookie_t
xcb_ewmh_set_wm_sync_request_counter_checked(xcb_ewmh_connection_t *ewmh,
                                             xcb_window_t window,
                                             xcb_atom_t wm_sync_request_counter_atom,
                                             uint32_t low, uint32_t high)
{
  const uint32_t data[] = { low, high };

  return xcb_change_property_checked(ewmh->connection, XCB_PROP_MODE_REPLACE,
                                     window, ewmh->_NET_WM_SYNC_REQUEST,
                                     CARDINAL, 32, 2, data);
}

DO_GET_PROPERTY(_NET_WM_SYNC_REQUEST, wm_sync_request_counter, CARDINAL, 2)

uint8_t
xcb_ewmh_get_wm_sync_request_counter_from_reply(uint64_t *counter,
                                                xcb_get_property_reply_t *r)
{
  /* 2 cardinals? */
  if(!r || r->type != CARDINAL || r->format != 32 ||
     xcb_get_property_value_length(r) != sizeof(uint64_t))
    return 0;

  uint32_t *r_value = (uint32_t *) xcb_get_property_value(r);
  *counter = (r_value[0] | GET_LEN_FROM_NB(r_value[1], 8));

  return 1;
}

uint8_t
xcb_ewmh_get_wm_sync_request_counter_reply(xcb_ewmh_connection_t *ewmh,
                                           xcb_get_property_cookie_t cookie,
                                           uint64_t *counter,
                                           xcb_generic_error_t **e)
{
  xcb_get_property_reply_t *r = xcb_get_property_reply(ewmh->connection, cookie, e);
  const uint8_t ret = xcb_ewmh_get_wm_sync_request_counter_from_reply(counter, r);
  free(r);
  return ret;
}

xcb_void_cookie_t
xcb_ewmh_send_wm_sync_request(xcb_ewmh_connection_t *ewmh,
                              xcb_window_t window,
                              xcb_atom_t wm_protocols_atom,
                              xcb_atom_t wm_sync_request_atom,
                              xcb_timestamp_t timestamp,
                              uint64_t counter)
{
  const uint32_t data[] = { ewmh->_NET_WM_SYNC_REQUEST, timestamp, counter,
                            GET_NB_FROM_LEN(counter, 32) };

  return xcb_ewmh_send_client_message(ewmh->connection, window, window,
                                      ewmh->WM_PROTOCOLS, 4, data);
}

/**
 * _NET_WM_FULLSCREEN_MONITORS
 */

xcb_void_cookie_t
xcb_ewmh_set_wm_fullscreen_monitors(xcb_ewmh_connection_t *ewmh,
                                    xcb_window_t window,
                                    uint32_t top, uint32_t bottom,
                                    uint32_t left, uint32_t right)
{
  const uint32_t data[] = { top, bottom, left, right };

  return xcb_change_property(ewmh->connection, XCB_PROP_MODE_REPLACE, window,
                             ewmh->_NET_WM_FULLSCREEN_MONITORS, CARDINAL, 32,
                             4, data);
}

xcb_void_cookie_t
xcb_ewmh_set_wm_fullscreen_monitors_checked(xcb_ewmh_connection_t *ewmh,
                                            xcb_window_t window,
                                            uint32_t top, uint32_t bottom,
                                            uint32_t left, uint32_t right)
{
  const uint32_t data[] = { top, bottom, left, right };

  return xcb_change_property_checked(ewmh->connection, XCB_PROP_MODE_REPLACE,
                                     window, ewmh->_NET_WM_FULLSCREEN_MONITORS,
                                     CARDINAL, 32, 4, data);
}

DO_GET_PROPERTY(_NET_WM_FULLSCREEN_MONITORS, wm_fullscreen_monitors, CARDINAL, 4)

DO_REPLY_STRUCTURE(wm_fullscreen_monitors,
                   xcb_ewmh_get_wm_fullscreen_monitors_reply_t)

xcb_void_cookie_t
xcb_ewmh_request_change_wm_fullscreen_monitors(xcb_ewmh_connection_t *ewmh,
                                               xcb_window_t window,
                                               uint32_t top, uint32_t bottom,
                                               uint32_t left, uint32_t right,
                                               xcb_ewmh_client_source_type_t source_indication)
{
  const uint32_t data[] = { top, bottom, left, right, source_indication };

  return xcb_ewmh_send_client_message(ewmh->connection, window, ewmh->root,
                                      ewmh->_NET_WM_FULLSCREEN_MONITORS, 5, data);
}

/**
 * _NET_WM_FULL_PLACEMENT
 */

/**
 * _NET_WM_CM_Sn
 */

xcb_get_selection_owner_cookie_t
xcb_ewmh_get_wm_cm_owner(xcb_ewmh_connection_t *ewmh)
{
  return xcb_get_selection_owner(ewmh->connection, ewmh->_NET_WM_CM_Sn);
}

xcb_get_selection_owner_cookie_t
xcb_ewmh_get_wm_cm_owner_unchecked(xcb_ewmh_connection_t *ewmh)
{
  return xcb_get_selection_owner_unchecked(ewmh->connection,
                                           ewmh->_NET_WM_CM_Sn);
}

uint8_t
xcb_ewmh_get_wm_cm_owner_from_reply(xcb_window_t *owner,
                                    xcb_get_selection_owner_reply_t *r)
{
  if(!r)
    return 0;

  *owner = r->owner;
  free(r);
  return 1;
}

uint8_t
xcb_ewmh_get_wm_cm_owner_reply(xcb_ewmh_connection_t *ewmh,
                               xcb_get_selection_owner_cookie_t cookie,
                               xcb_window_t *owner,
                               xcb_generic_error_t **e)
{
  xcb_get_selection_owner_reply_t *r =
    xcb_get_selection_owner_reply(ewmh->connection, cookie, e);

  return xcb_ewmh_get_wm_cm_owner_from_reply(owner, r);
}

/* TODO: section 2.1, 2.2 */
static xcb_void_cookie_t
set_wm_cm_owner_client_message(xcb_ewmh_connection_t *ewmh,
                               xcb_window_t owner,
                               xcb_timestamp_t timestamp,
                               uint32_t selection_data1,
                               uint32_t selection_data2)
{
  xcb_client_message_event_t ev;
  memset(&ev, 0, sizeof(xcb_client_message_event_t));

  ev.response_type = XCB_CLIENT_MESSAGE;
  ev.format = 32;
  ev.type = ewmh->MANAGER;
  ev.data.data32[0] = timestamp;
  ev.data.data32[1] = ewmh->_NET_WM_CM_Sn;
  ev.data.data32[2] = owner;
  ev.data.data32[3] = selection_data1;
  ev.data.data32[4] = selection_data2;

  return xcb_send_event(ewmh->connection, 0, ewmh->root,
                        XCB_EVENT_MASK_STRUCTURE_NOTIFY,
                        (char *) &ev);
}

/* TODO: check both */
xcb_void_cookie_t
xcb_ewmh_set_wm_cm_owner(xcb_ewmh_connection_t *ewmh,
                         xcb_window_t owner,
                         xcb_timestamp_t timestamp,
                         uint32_t selection_data1,
                         uint32_t selection_data2)
{
  xcb_set_selection_owner(ewmh->connection, owner, ewmh->_NET_WM_CM_Sn, 0);

  return set_wm_cm_owner_client_message(ewmh, owner, timestamp,
                                        selection_data1, selection_data2);
}

xcb_void_cookie_t
xcb_ewmh_set_wm_cm_owner_checked(xcb_ewmh_connection_t *ewmh,
                                 xcb_window_t owner,
                                 xcb_timestamp_t timestamp,
                                 uint32_t selection_data1,
                                 uint32_t selection_data2)
{
  xcb_set_selection_owner_checked(ewmh->connection, owner,
                                  ewmh->_NET_WM_CM_Sn, 0);

  return set_wm_cm_owner_client_message(ewmh, owner, timestamp,
                                        selection_data1, selection_data2);
}

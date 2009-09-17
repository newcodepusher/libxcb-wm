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

/** Store the root window as it won't change */
static xcb_window_t root_window;

#define ROOT_WINDOW_MESSAGE_EVENT_MASK (XCB_EVENT_MASK_SUBSTRUCTURE_NOTIFY |\
					XCB_EVENT_MASK_SUBSTRUCTURE_REDIRECT)

define(`DO', `ifelse(`$1', , , `xcb_atom_t $1;
DO(shift($@))')')dnl
include(atomlist.m4)dnl

/**
 * @brief The structure used on initialization
 */
typedef struct {
  /** Pointer to the Atom declared above */
  xcb_atom_t *value;
  /** The InternAtom request cookie */
  xcb_intern_atom_cookie_t cookie;
  /** The Atom name length */
  uint8_t name_len;
  /** The Atom name string */
  char *name;
} ewmh_atom_t;

define(`DO_ENTRY', `
  { &$1, { 0 }, sizeof("$1") - 1, "$1" }ifelse(`$2', , , `,')')dnl

define(`DO', `DO_ENTRY(`$1', `$2')ifelse(`$2', , , `DO(shift($@))')')dnl

static ewmh_atom_t ewmh_atoms_list[] = {dnl
  include(atomlist.m4)dnl
};

#define NB_EWMH_ATOMS countof(ewmh_atoms_list)

#define GET_NB_FROM_LEN(len, shift_value) ((len) >> (shift_value))
#define GET_LEN_FROM_NB(nb, shift_value) ((len) << (shift_value))

/**
 * Common functions and macro
 */

#define DO_GET_PROPERTY(atom, name, request_type, length)		\
  xcb_get_property_cookie_t						\
  xcb_ewmh_get_##name(xcb_connection_t *c,				\
		      xcb_window_t window)				\
  {									\
    return xcb_get_property(c, 0, window, atom, request_type, 0,	\
			    length);					\
  }									\
									\
  xcb_get_property_cookie_t						\
  xcb_ewmh_get_##name##_unchecked(xcb_connection_t *c,			\
				  xcb_window_t window)			\
  {									\
    return xcb_get_property_unchecked(c, 0, window, atom,		\
				      request_type, 0, length);		\
  }

#define DO_GET_ROOT_PROPERTY(atom, name, request_type, length)		\
  xcb_get_property_cookie_t						\
  xcb_ewmh_get_##name(xcb_connection_t *c)				\
  {									\
    return xcb_get_property(c, 0, root_window, atom, request_type, 0,	\
			    length);					\
  }									\
									\
  xcb_get_property_cookie_t						\
  xcb_ewmh_get_##name##_unchecked(xcb_connection_t *c)			\
  {									\
    return xcb_get_property_unchecked(c, 0, root_window, atom,		\
				      request_type, 0, length);		\
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
 * Macro defining function for set_property and get_property functions
 */
#define DO_SET_SINGLE_VALUE_PROPERTY(atom, name, name_type, request_type) \
  void									\
  xcb_ewmh_set_##name##_checked(xcb_connection_t *c,			\
                                xcb_window_t window,			\
				name_type value)			\
  {									\
    xcb_change_property_checked(c, XCB_PROP_MODE_REPLACE, window, atom,	\
				request_type, 32, 1, &value);		\
  }									\
									\
  void									\
  xcb_ewmh_set_##name(xcb_connection_t *c,				\
		      xcb_window_t window,				\
		      name_type value)					\
  {									\
    xcb_change_property(c, XCB_PROP_MODE_REPLACE, window, atom,		\
			request_type, 32, 1, &value);			\
  }

#define DO_SET_ROOT_SINGLE_VALUE_PROPERTY(atom, name, name_type, request_type) \
  void									\
  xcb_ewmh_set_##name##_checked(xcb_connection_t *c,			\
				name_type value)			\
  {									\
    xcb_change_property_checked(c, XCB_PROP_MODE_REPLACE, root_window, atom, \
				request_type, 32, 1, &value);		\
  }									\
									\
  void									\
  xcb_ewmh_set_##name(xcb_connection_t *c,				\
		      name_type value)					\
  {									\
    xcb_change_property(c, XCB_PROP_MODE_REPLACE, root_window, atom,	\
			request_type, 32, 1, &value);			\
  }

/**
 * Macro  defining a generic  function for  reply containing  a single
 * value
 */
#define DO_REPLY_SINGLE_VALUE_ATOM(name, name_type, reply_type)		\
  static uint8_t							\
  get_single_##name##_from_reply(name_type *atom_value,			\
				 xcb_get_property_reply_t *r)		\
  {									\
    if(!r || r->type != reply_type || r->format != 32 ||		\
       xcb_get_property_value_length(r) != 4)				\
      return 0;								\
									\
    *atom_value = *((name_type *) xcb_get_property_value(r));		\
    return 1;								\
  }									\
									\
  static uint8_t							\
  get_single_##name##_reply(xcb_connection_t *c,			\
			    xcb_get_property_cookie_t cookie,		\
			    name_type *atom_value,			\
			    xcb_generic_error_t **e)			\
  {									\
    xcb_get_property_reply_t *r = xcb_get_property_reply(c, cookie, e);	\
    const uint8_t ret = get_single_##name##_from_reply(atom_value, r);	\
    free(r);								\
    return ret;								\
  }

DO_REPLY_SINGLE_VALUE_ATOM(window, xcb_window_t, WINDOW)
DO_REPLY_SINGLE_VALUE_ATOM(cardinal, uint32_t, CARDINAL)

#define DO_ACCESSORS_SINGLE_VALUE_ATOM(atom, name, reply_type, out_type, func_reply) \
  DO_GET_PROPERTY(atom, name, reply_type, 1L)				\
  DO_SET_SINGLE_VALUE_PROPERTY(atom, name, out_type, reply_type)	\
  DO_ACCESSORS_GET_SINGLE_VALUE_ATOM(atom, name, reply_type, out_type, func_reply)

#define DO_ACCESSORS_ROOT_SINGLE_VALUE_ATOM(atom, name, reply_type, out_type, func_reply) \
  DO_GET_ROOT_PROPERTY(atom, name, reply_type, 1L)			\
  DO_SET_ROOT_SINGLE_VALUE_PROPERTY(atom, name, out_type, reply_type)	\
  DO_ACCESSORS_GET_SINGLE_VALUE_ATOM(atom, name, reply_type, out_type, func_reply)

#define DO_ACCESSORS_GET_SINGLE_VALUE_ATOM(atom, name, reply_type, out_type, func_reply) \
  uint8_t								\
  xcb_ewmh_get_##name##_from_reply(out_type *out,			\
				   xcb_get_property_reply_t *r)		\
  {									\
    return get_single_##func_reply##_from_reply(out, r);		\
  }									\
									\
  uint8_t								\
  xcb_ewmh_get_##name##_reply(xcb_connection_t *c,			\
			      xcb_get_property_cookie_t cookie,		\
			      out_type *out,				\
			      xcb_generic_error_t **e)			\
  {									\
    return get_single_##func_reply##_reply(c, cookie, out, e);		\
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

#define DO_SET_LIST_VALUES_PROPERTY(atom, name, name_type, request_type, len_shift) \
  void									\
  xcb_ewmh_set_##name##_checked(xcb_connection_t *c,			\
				xcb_window_t window,			\
				uint32_t list_len,			\
				name_type *list)			\
  {									\
    xcb_change_property_checked(c, XCB_PROP_MODE_REPLACE, window,	\
				atom, request_type, 32,			\
				GET_LEN_FROM_NB(list_len, len_shift), list); \
  }									\
									\
  void									\
  xcb_ewmh_set_##name(xcb_connection_t *c,				\
		      xcb_window_t window,				\
		      uint32_t list_len,				\
		      name_type *list)					\
  {									\
    xcb_change_property(c, XCB_PROP_MODE_REPLACE, window, atom,		\
			request_type, 32,				\
			GET_LEN_FROM_NB(list_len, len_shift),		\
			list);						\
  }

#define DO_SET_ROOT_LIST_VALUES_PROPERTY(atom, name, name_type, request_type, len_shift) \
  void									\
  xcb_ewmh_set_##name##_checked(xcb_connection_t *c,			\
				uint32_t list_len,			\
				name_type *list)			\
  {									\
    xcb_change_property_checked(c, XCB_PROP_MODE_REPLACE, root_window,	\
				atom, request_type, 32,			\
				GET_LEN_FROM_NB(list_len, len_shift),	\
				list);					\
  }									\
									\
  void									\
  xcb_ewmh_set_##name(xcb_connection_t *c,				\
		      uint32_t list_len,				\
		      name_type *list)					\
  {									\
    xcb_change_property(c, XCB_PROP_MODE_REPLACE, root_window, atom,	\
			request_type, 32,				\
			GET_LEN_FROM_NB(list_len, len_shift),		\
			list);						\
  }

/**
 * Macro defining  a generic function  for reply containing a  list of
 * values and also defines a function to wipe the reply.
 *
 * The length is right-shifted by  (len_shift + 2) respectively to get
 * the actual length of a list  values from a value made from multiple
 * component  (such as  coordinates), and  divide by  (r->format  / 8)
 * where r->format always equals to 32 in this case.
 */
#define DO_REPLY_LIST_VALUES_ATOM(visibility, name, name_type, reply_type, len_shift) \
  visibility uint8_t							\
  xcb_ewmh_get_##name##_from_reply(xcb_ewmh_get_##name##_reply_t *data, \
				   xcb_get_property_reply_t *r)		\
  {									\
    if(!r || r->type != reply_type || r->format != 32)                  \
      return 0;								\
									\
    data->_reply = r;							\
    data->name##_len = GET_NB_FROM_LEN(xcb_get_property_value_length(data->_reply), len_shift + 2); \
    data->name = (name_type *) xcb_get_property_value(data->_reply);	\
    return 1;								\
  }									\
									\
  visibility uint8_t							\
  xcb_ewmh_get_##name##_reply(xcb_connection_t *c,			\
			      xcb_get_property_cookie_t cookie,		\
			      xcb_ewmh_get_##name##_reply_t *data,	\
			      xcb_generic_error_t **e)			\
  {									\
    xcb_get_property_reply_t *r = xcb_get_property_reply(c, cookie, e);	\
    const uint8_t ret = xcb_ewmh_get_##name##_from_reply(data, r);	\
									\
    /* If the  last call  was not successful  (ret equals to  0), then	\
       just free the reply as the data value is not consistent */	\
    if(!ret)								\
      free(r);								\
									\
    return ret;								\
  }									\
									\
  void									\
  xcb_ewmh_get_##name##_reply_wipe(xcb_ewmh_get_##name##_reply_t *data)	\
  {									\
    free(data->_reply);							\
  }

DO_REPLY_LIST_VALUES_ATOM(static, windows, xcb_window_t, WINDOW, 0)
DO_REPLY_LIST_VALUES_ATOM(static, atoms, xcb_atom_t, ATOM, 0)

/**
 * UTF8_STRING handling
 */

static uint8_t
get_utf8_from_reply(xcb_ewmh_get_utf8_strings_reply_t *data,
		    xcb_get_property_reply_t *r)
{
  if(!r || r->type != UTF8_STRING || r->format != 8)
    return 0;

  data->_reply = r;
  data->strings_len = xcb_get_property_value_length(data->_reply);
  data->strings = (char *) xcb_get_property_value(data->_reply);

  return 1;
}

static uint8_t
get_utf8_reply(xcb_connection_t *c,
	       xcb_get_property_cookie_t cookie,
	       xcb_ewmh_get_utf8_strings_reply_t *data,
	       xcb_generic_error_t **e)
{
  xcb_get_property_reply_t *r = xcb_get_property_reply(c, cookie, e);
  const uint8_t ret = get_utf8_from_reply(data, r);

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

#define DO_ACCESSORS_COMMON_UTF8_STRING(atom, name)			\
  uint8_t								\
  xcb_ewmh_get_##name##_from_reply(xcb_ewmh_get_utf8_strings_reply_t *data, \
				   xcb_get_property_reply_t *r)		\
  {									\
    return get_utf8_from_reply(data, r);				\
  }									\
									\
  uint8_t								\
  xcb_ewmh_get_##name##_reply(xcb_connection_t *c,			\
			      xcb_get_property_cookie_t cookie,		\
			      xcb_ewmh_get_utf8_strings_reply_t *data,	\
			      xcb_generic_error_t **e)			\
  {									\
    return get_utf8_reply(c, cookie, data, e);				\
  }

#define DO_ACCESSORS_ROOT_UTF8_STRING(atom, name)			\
  DO_GET_ROOT_PROPERTY(atom, name, 0, UINT_MAX)				\
  DO_ACCESSORS_COMMON_UTF8_STRING(atom, name)				\
									\
  void									\
  xcb_ewmh_set_##name(xcb_connection_t *c,				\
		      uint32_t strings_len,				\
		      const char *strings)				\
  {									\
    xcb_change_property(c, XCB_PROP_MODE_REPLACE, root_window, atom,	\
			UTF8_STRING, 8,	strings_len, strings);		\
  }									\
									\
  void									\
  xcb_ewmh_set_##name##_checked(xcb_connection_t *c,			\
				uint32_t strings_len,			\
				const char *strings)			\
  {									\
    xcb_change_property_checked(c, XCB_PROP_MODE_REPLACE, root_window, atom, \
				UTF8_STRING, 8,	strings_len, strings);	\
  }

#define DO_ACCESSORS_UTF8_STRING(atom, name)				\
  DO_GET_PROPERTY(atom, name, 0, UINT_MAX)				\
  DO_ACCESSORS_COMMON_UTF8_STRING(atom, name)				\
									\
  void									\
  xcb_ewmh_set_##name(xcb_connection_t *c,				\
		      xcb_window_t window,				\
		      uint32_t strings_len,				\
		      const char *strings)				\
  {									\
    xcb_change_property(c, XCB_PROP_MODE_REPLACE, window, atom,		\
			UTF8_STRING, 8,	strings_len, strings);		\
  }									\
									\
  void									\
  xcb_ewmh_set_##name##_checked(xcb_connection_t *c,			\
				xcb_window_t window,			\
				uint32_t strings_len,			\
				const char *strings)			\
  {									\
    xcb_change_property_checked(c, XCB_PROP_MODE_REPLACE, window, atom,	\
				UTF8_STRING, 8,	strings_len, strings);	\
  }

/**
 * ClientMessage generic function
 */
void
send_client_message(xcb_connection_t *c,
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

  for(; data_len != 0; data_len--)
    ev.data.data32[0] = data[1];

  xcb_send_event(c, 0, dest, ROOT_WINDOW_MESSAGE_EVENT_MASK,
		 (char *) &ev);
}

/**
 * Atoms initialisation
 */

void
xcb_ewmh_init_atoms_list(xcb_connection_t *c,
			 const int screen_nbr)
{
  xcb_screen_t *screen = xcb_aux_get_screen(c, screen_nbr);
  if(!screen)
    return;

  /* Compute _NET_WM_CM_Sn according to the screen number 'n' */
  char wm_cm_sn[32];
  const int wm_cm_sn_len = snprintf(wm_cm_sn, 32, "_NET_WM_CM_S%d",
				    screen_nbr);

  assert(wm_cm_sn_len > 0 && wm_cm_sn_len < 32);

  root_window = screen->root;

  uint8_t i;
  for(i = 0; i < NB_EWMH_ATOMS; i++)
  {
    if(ewmh_atoms_list[i].value == &_NET_WM_CM_Sn)
      ewmh_atoms_list[i].cookie = xcb_intern_atom(c, 0,
						  wm_cm_sn_len,
						  wm_cm_sn);
    else
      ewmh_atoms_list[i].cookie = xcb_intern_atom(c, 0,
						  ewmh_atoms_list[i].name_len,
						  ewmh_atoms_list[i].name);
  }
}

uint8_t
xcb_ewmh_init_atoms_list_replies(xcb_connection_t *c,
				 xcb_generic_error_t **e)
{
  uint8_t i;
  xcb_intern_atom_reply_t *reply;
  for(i = 0; i < NB_EWMH_ATOMS; i++)
  {
    if((reply = xcb_intern_atom_reply(c, ewmh_atoms_list[i].cookie, e)) == NULL)
      return 0;

    *(ewmh_atoms_list[i].value) = reply->atom;
    free(reply);
  }

  return 1;
}

/**
 * _NET_SUPPORTED
 */

DO_GET_ROOT_PROPERTY(_NET_SUPPORTED, supported, ATOM, UINT_MAX)
DO_SET_ROOT_LIST_VALUES_PROPERTY(_NET_SUPPORTED, supported, xcb_atom_t, ATOM, 0)

uint8_t
xcb_ewmh_get_supported_from_reply(xcb_ewmh_get_atoms_reply_t *supported,
				  xcb_get_property_reply_t *r)
{
  return xcb_ewmh_get_atoms_from_reply(supported, r);
}

uint8_t
xcb_ewmh_get_supported_reply(xcb_connection_t *c,
			     xcb_get_property_cookie_t cookie,
			     xcb_ewmh_get_atoms_reply_t *supported,
			     xcb_generic_error_t **e)
{
  return xcb_ewmh_get_atoms_reply(c, cookie, supported, e);
}

/**
 * _NET_CLIENT_LIST
 * _NET_CLIENT_LIST_STACKING
 */

DO_GET_ROOT_PROPERTY(_NET_CLIENT_LIST, client_list, WINDOW, UINT_MAX)
DO_SET_ROOT_LIST_VALUES_PROPERTY(_NET_CLIENT_LIST, client_list, xcb_window_t,
				 WINDOW, 0)

DO_GET_ROOT_PROPERTY(_NET_CLIENT_LIST_STACKING, client_list_stacking, WINDOW, UINT_MAX)
DO_SET_ROOT_LIST_VALUES_PROPERTY(_NET_CLIENT_LIST_STACKING, client_list_stacking,
				 xcb_window_t, WINDOW, 0)

uint8_t
xcb_ewmh_get_client_list_from_reply(xcb_ewmh_get_windows_reply_t *clients,
				    xcb_get_property_reply_t *r)
{
  return xcb_ewmh_get_windows_from_reply(clients, r);
}

uint8_t
xcb_ewmh_get_client_list_reply(xcb_connection_t *c,
			       xcb_get_property_cookie_t cookie,
			       xcb_ewmh_get_windows_reply_t *clients,
			       xcb_generic_error_t **e)
{
  return xcb_ewmh_get_windows_reply(c, cookie, clients, e);
}

/**
 * _NET_NUMBER_OF_DESKTOPS
 */

DO_ACCESSORS_ROOT_SINGLE_VALUE_ATOM(_NET_NUMBER_OF_DESKTOPS, number_of_desktops,
				    CARDINAL, uint32_t, cardinal)

void
xcb_ewmh_request_change_number_of_desktops(xcb_connection_t *c,
					   uint32_t new_number_of_desktops)
{
  send_client_message(c, XCB_NONE, root_window, _NET_NUMBER_OF_DESKTOPS, 1,
		      &new_number_of_desktops);
}

/**
 * _NET_DESKTOP_GEOMETRY
 */

DO_GET_ROOT_PROPERTY(_NET_DESKTOP_GEOMETRY, desktop_geometry, CARDINAL, 2L)

void
xcb_ewmh_set_desktop_geometry(xcb_connection_t *c,
			      uint32_t new_width, uint32_t new_height)
{
  const uint32_t data[] = { new_width, new_height };
  xcb_change_property(c, XCB_PROP_MODE_REPLACE, root_window,
		      _NET_DESKTOP_GEOMETRY, CARDINAL, 32, 2, data);
}

void
xcb_ewmh_set_desktop_geometry_checked(xcb_connection_t *c,
				      uint32_t new_width, uint32_t new_height)
{
  const uint32_t data[] = { new_width, new_height };
  xcb_change_property_checked(c, XCB_PROP_MODE_REPLACE, root_window,
			      _NET_DESKTOP_GEOMETRY, CARDINAL, 32, 2, data);
}

void
xcb_ewmh_request_change_desktop_geometry(xcb_connection_t *c,
					 uint32_t new_width, uint32_t new_height)
{
  const uint32_t data[] = { new_width, new_height };
  send_client_message(c, XCB_NONE, root_window, _NET_DESKTOP_GEOMETRY, 2, data);
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
xcb_ewmh_get_desktop_geometry_reply(xcb_connection_t *c,
				    xcb_get_property_cookie_t cookie,
				    uint32_t *width, uint32_t *height,
				    xcb_generic_error_t **e)
{
  xcb_get_property_reply_t *r = xcb_get_property_reply(c, cookie, e);
  const uint8_t ret = xcb_ewmh_get_desktop_geometry_from_reply(width, height, r);
  free(r);
  return ret;
}

/**
 * _NET_DESKTOP_VIEWPORT
 */

DO_GET_ROOT_PROPERTY(_NET_DESKTOP_VIEWPORT, desktop_viewport, CARDINAL, UINT_MAX)
DO_SET_ROOT_LIST_VALUES_PROPERTY(_NET_DESKTOP_VIEWPORT, desktop_viewport,
				 xcb_ewmh_coordinates_t, CARDINAL, 1)

void
xcb_ewmh_request_change_desktop_viewport(xcb_connection_t *c,
					 uint32_t x, uint32_t y)
{
  const uint32_t data[] = { x, y };
  send_client_message(c, XCB_NONE, root_window, _NET_DESKTOP_VIEWPORT, 2, data);
}

DO_REPLY_LIST_VALUES_ATOM(extern, desktop_viewport, xcb_ewmh_coordinates_t, CARDINAL, 1)

/**
 * _NET_CURRENT_DESKTOP
 */

DO_ACCESSORS_ROOT_SINGLE_VALUE_ATOM(_NET_CURRENT_DESKTOP, current_desktop,
				    CARDINAL, uint32_t, cardinal)

void
xcb_ewmh_request_change_current_desktop(xcb_connection_t *c,
					uint32_t new_desktop,
					xcb_timestamp_t timestamp)
{
  const uint32_t data[] = { new_desktop, timestamp };
  send_client_message(c, XCB_NONE, root_window, _NET_CURRENT_DESKTOP, 2, data);
}

/**
 * _NET_DESKTOP_NAMES
 */
DO_ACCESSORS_ROOT_UTF8_STRING(_NET_DESKTOP_NAMES, desktop_names)

/**
 * _NET_ACTIVE_WINDOW
 */

DO_ACCESSORS_ROOT_SINGLE_VALUE_ATOM(_NET_ACTIVE_WINDOW, active_window,
				    WINDOW, xcb_window_t, window)

void
xcb_ewmh_request_change_active_window(xcb_connection_t *c,
				      xcb_window_t window_to_activate,
				      xcb_ewmh_client_source_type_t source_indication,
				      xcb_timestamp_t timestamp,
				      xcb_window_t current_active_window)
{
  const uint32_t data[] = { source_indication, timestamp, current_active_window };
  send_client_message(c, window_to_activate, root_window, _NET_ACTIVE_WINDOW, 3,
		      data);
}

/**
 * _NET_WORKAREA
 */

DO_GET_ROOT_PROPERTY(_NET_WORKAREA, workarea, CARDINAL, UINT_MAX)
DO_SET_ROOT_LIST_VALUES_PROPERTY(_NET_WORKAREA, workarea, xcb_ewmh_geometry_t, CARDINAL, 2)
DO_REPLY_LIST_VALUES_ATOM(extern, workarea, xcb_ewmh_geometry_t, CARDINAL, 2)

/**
 * _NET_SUPPORTING_WM_CHECK
 */

DO_ACCESSORS_ROOT_SINGLE_VALUE_ATOM(_NET_SUPPORTING_WM_CHECK, supporting_wm_check,
				    WINDOW, xcb_window_t, window)

/**
 * _NET_VIRTUAL_ROOTS
 */

DO_GET_ROOT_PROPERTY(_NET_VIRTUAL_ROOTS, virtual_roots, WINDOW, UINT_MAX)
DO_SET_LIST_VALUES_PROPERTY(_NET_VIRTUAL_ROOTS, virtual_roots, xcb_window_t, WINDOW, 0)

uint8_t
xcb_ewmh_get_virtual_roots_from_reply(xcb_ewmh_get_windows_reply_t *virtual_roots,
				      xcb_get_property_reply_t *r)
{
  return xcb_ewmh_get_windows_from_reply(virtual_roots, r);
}

uint8_t
xcb_ewmh_get_virtual_roots_reply(xcb_connection_t *c,
				 xcb_get_property_cookie_t cookie,
				 xcb_ewmh_get_windows_reply_t *virtual_roots,
				 xcb_generic_error_t **e)
{
  return xcb_ewmh_get_windows_reply(c, cookie, virtual_roots, e);
}

/**
 * _NET_DESKTOP_LAYOUT
 */

DO_GET_ROOT_PROPERTY(_NET_DESKTOP_LAYOUT, desktop_layout, CARDINAL, 4)

void
xcb_ewmh_set_desktop_layout(xcb_connection_t *c,
			    xcb_ewmh_desktop_layout_orientation_t orientation,
			    uint32_t columns, uint32_t rows,
			    xcb_ewmh_desktop_layout_starting_corner_t starting_corner)
{
  const uint32_t data[] = { orientation, columns, rows, starting_corner };
  xcb_change_property(c, XCB_PROP_MODE_REPLACE, root_window,
		      _NET_DESKTOP_LAYOUT, CARDINAL, 32, 2, data);
}

void
xcb_ewmh_set_desktop_layout_checked(xcb_connection_t *c,
				    xcb_ewmh_desktop_layout_orientation_t orientation,
				    uint32_t columns, uint32_t rows,
				    xcb_ewmh_desktop_layout_starting_corner_t starting_corner)
{
  const uint32_t data[] = { orientation, columns, rows, starting_corner };
  xcb_change_property_checked(c, XCB_PROP_MODE_REPLACE, root_window,
			      _NET_DESKTOP_LAYOUT, CARDINAL, 32, 2, data);
}

uint8_t
xcb_ewmh_get_desktop_layout_from_reply(xcb_ewmh_get_desktop_layout_reply_t *desktop_layout,
				       xcb_get_property_reply_t *r)
{
  if(!r || r->type != CARDINAL || r->format != 32 ||
     GET_NB_FROM_LEN(xcb_get_property_value_length(r), 2) != 4)
    return 0;

  memcpy(desktop_layout, xcb_get_property_value(r),
	 xcb_get_property_value_length(r));

  return 1;
}

uint8_t
xcb_ewmh_get_desktop_layout_reply(xcb_connection_t *c,
				  xcb_get_property_cookie_t cookie,
				  xcb_ewmh_get_desktop_layout_reply_t *desktop_layout,
				  xcb_generic_error_t **e)
{
  xcb_get_property_reply_t *r = xcb_get_property_reply(c, cookie, e);
  const uint8_t ret = xcb_ewmh_get_desktop_layout_from_reply(desktop_layout, r);
  free(r);
  return ret;
}

/**
 * _NET_SHOWING_DESKTOP
 */

DO_ACCESSORS_ROOT_SINGLE_VALUE_ATOM(_NET_SHOWING_DESKTOP, showing_desktop, CARDINAL,
				    uint32_t, cardinal)

void
xcb_ewmh_request_change_showing_desktop(xcb_connection_t *c,
					uint32_t enter)
{
  send_client_message(c, XCB_NONE, root_window, _NET_SHOWING_DESKTOP, 1,
		      &enter);
}

/**
 * _NET_CLOSE_WINDOW
 */

void
xcb_ewmh_request_close_window(xcb_connection_t *c,
			      xcb_window_t window_to_close,
			      xcb_timestamp_t timestamp,
			      xcb_ewmh_client_source_type_t source_indication)
{
  const uint32_t data[] = { timestamp, source_indication };
  send_client_message(c, window_to_close, root_window, _NET_CLOSE_WINDOW, 2,
		      data);
}

/**
 * _NET_MOVERESIZE_WINDOW
 */

/* x, y, width, height may be equal to -1 */
void
xcb_ewmh_request_moveresize_window(xcb_connection_t *c,
				   xcb_window_t moveresize_window,
				   xcb_gravity_t gravity,
				   xcb_ewmh_client_source_type_t source_indication,
				   xcb_ewmh_moveresize_window_opt_flags_t flags,
				   uint32_t x, uint32_t y,
				   uint32_t width, uint32_t height)
{
  const uint32_t data[] = { (gravity | flags | GET_LEN_FROM_NB(source_indication, 12)),
			    x, y, width, height };

  send_client_message(c, moveresize_window, root_window, _NET_MOVERESIZE_WINDOW,
		      5, data);
}

/**
 * _NET_WM_MOVERESIZE
 */

void
xcb_ewmh_request_wm_moveresize(xcb_connection_t *c,
			       xcb_window_t moveresize_window,
			       uint32_t x_root, uint32_t y_root,
			       xcb_ewmh_moveresize_direction_t direction,
			       xcb_button_index_t button,
			       xcb_ewmh_client_source_type_t source_indication)
{
  const uint32_t data[] = { x_root, y_root, direction, button, source_indication };

  send_client_message(c, moveresize_window, root_window, _NET_WM_MOVERESIZE, 5,
		      data);
}

/**
 * _NET_RESTACK_WINDOW
 */

void
xcb_ewmh_request_restack_window(xcb_connection_t *c,
				xcb_window_t window_to_restack,
				xcb_window_t sibling_window,
				xcb_stack_mode_t detail)
{
  const uint32_t data[] = { XCB_EWMH_CLIENT_SOURCE_TYPE_OTHER, sibling_window,
			    detail };

  send_client_message(c, window_to_restack, root_window, _NET_RESTACK_WINDOW, 3,
		      data);
}

void
xcb_ewmh_request_frame_extents(xcb_connection_t *c,
			       xcb_window_t client_window)
{
  send_client_message(c, client_window, root_window, _NET_REQUEST_FRAME_EXTENTS,
		      0, NULL);
}

/**
 * _NET_WM_NAME
 */

DO_ACCESSORS_UTF8_STRING(_NET_WM_NAME, wm_name)

/**
 * _NET_WM_VISIBLE_NAME
 */

DO_ACCESSORS_UTF8_STRING(_NET_WM_VISIBLE_NAME, wm_visible_name)

/**
 * _NET_WM_ICON_NAME
 */

DO_ACCESSORS_UTF8_STRING(_NET_WM_ICON_NAME, wm_icon_name)

/**
 * _NET_WM_VISIBLE_ICON_NAME
 */

DO_ACCESSORS_UTF8_STRING(_NET_WM_VISIBLE_ICON_NAME, wm_visible_icon_name)

/**
 * _NET_WM_DESKTOP
 */

DO_ACCESSORS_SINGLE_VALUE_ATOM(_NET_WM_DESKTOP, wm_desktop, CARDINAL, uint32_t, cardinal)

void
xcb_ewmh_request_change_wm_desktop(xcb_connection_t *c,
				   xcb_window_t client_window,
				   uint32_t new_desktop,
				   xcb_ewmh_client_source_type_t source_indication)
{
  const uint32_t data[] = { new_desktop, source_indication };

  send_client_message(c, client_window, root_window, _NET_WM_DESKTOP, 2, data);
}

/**
 * _NET_WM_WINDOW_TYPE
 *
 * TODO: check possible atoms?
 */

DO_GET_PROPERTY(_NET_WM_WINDOW_TYPE, wm_window_type, ATOM, UINT_MAX)
DO_SET_LIST_VALUES_PROPERTY(_NET_WM_WINDOW_TYPE, wm_window_type, xcb_atom_t, ATOM, 0)

uint8_t
xcb_ewmh_get_wm_window_type_from_reply(xcb_ewmh_get_atoms_reply_t *window_types,
				       xcb_get_property_reply_t *r)
{
  return xcb_ewmh_get_atoms_from_reply(window_types, r);
}

uint8_t
xcb_ewmh_get_wm_window_type_reply(xcb_connection_t *c,
				  xcb_get_property_cookie_t cookie,
				  xcb_ewmh_get_atoms_reply_t *window_types,
				  xcb_generic_error_t **e)
{
  return xcb_ewmh_get_atoms_reply(c, cookie, window_types, e);
}

/**
 * _NET_WM_STATE
 *
 * TODO: check possible atoms?
 */

DO_GET_PROPERTY(_NET_WM_STATE, wm_state, ATOM, UINT_MAX)
DO_SET_LIST_VALUES_PROPERTY(_NET_WM_STATE, wm_state, xcb_atom_t, ATOM, 0)

void
xcb_ewmh_request_change_wm_state(xcb_connection_t *c,
				 xcb_window_t client_window,
				 xcb_ewmh_wm_state_action_t action,
				 xcb_atom_t first_property,
				 xcb_atom_t second_property,
				 xcb_ewmh_client_source_type_t source_indication)
{
  const uint32_t data[] = { action, first_property, second_property, source_indication };

  send_client_message(c, client_window, root_window, _NET_WM_STATE, 4, data);
}

uint8_t
xcb_ewmh_get_wm_state_from_reply(xcb_ewmh_get_atoms_reply_t *wm_states,
				 xcb_get_property_reply_t *r)
{
  return xcb_ewmh_get_atoms_from_reply(wm_states, r);
}

uint8_t
xcb_ewmh_get_wm_state_reply(xcb_connection_t *c,
			    xcb_get_property_cookie_t cookie,
			    xcb_ewmh_get_atoms_reply_t *wm_states,
			    xcb_generic_error_t **e)
{
  return xcb_ewmh_get_atoms_reply(c, cookie, wm_states, e);
}

/**
 * _NET_WM_ALLOWED_ACTIONS
 *
 * TODO: check possible atoms?
 */

DO_GET_PROPERTY(_NET_WM_ALLOWED_ACTIONS, wm_allowed_actions, ATOM, UINT_MAX)
DO_SET_LIST_VALUES_PROPERTY(_NET_WM_ALLOWED_ACTIONS, wm_allowed_actions, xcb_atom_t, ATOM, 0)

uint8_t
xcb_ewmh_get_wm_allowed_actions_from_reply(xcb_ewmh_get_atoms_reply_t *wm_allowed_actions,
					   xcb_get_property_reply_t *r)
{
  return xcb_ewmh_get_atoms_from_reply(wm_allowed_actions, r);
}

uint8_t
xcb_ewmh_get_wm_allowed_actions_reply(xcb_connection_t *c,
				      xcb_get_property_cookie_t cookie,
				      xcb_ewmh_get_atoms_reply_t *wm_allowed_actions,
				      xcb_generic_error_t **e)
{
  return xcb_ewmh_get_atoms_reply(c, cookie, wm_allowed_actions, e);
}

/**
 * _NET_WM_STRUT
 * _NET_WM_STRUT_PARTIAL
 */

DO_GET_PROPERTY(_NET_WM_STRUT, wm_strut, CARDINAL, 12)

void
xcb_ewmh_set_wm_strut_checked(xcb_connection_t *c,
			      xcb_window_t window,
			      xcb_ewmh_wm_strut_t wm_strut)
{
  xcb_change_property_checked(c, XCB_PROP_MODE_REPLACE, window, _NET_WM_STRUT,
			      CARDINAL, 32, 12, &wm_strut);
}

void
xcb_ewmh_set_wm_strut(xcb_connection_t *c,
		      xcb_window_t window,
		      xcb_ewmh_wm_strut_t wm_strut)
{
  xcb_change_property(c, XCB_PROP_MODE_REPLACE, window, _NET_WM_STRUT, CARDINAL,
		      32, 12, &wm_strut);
}

uint8_t
xcb_ewmh_get_wm_strut_from_reply(xcb_ewmh_wm_strut_t *wm_strut,
				 xcb_get_property_reply_t *r)
{
  if(!r || r->type != CARDINAL || r->format != 32 ||
     GET_NB_FROM_LEN(xcb_get_property_value_length(r), 2) != 12)
    return 0;

  memset(wm_strut, 0, sizeof(wm_strut));

  memcpy(wm_strut, xcb_get_property_value(r),
	 xcb_get_property_value_length(r));

  return 1;
}

uint8_t
xcb_ewmh_get_wm_strut_reply(xcb_connection_t *c,
			    xcb_get_property_cookie_t cookie,
			    xcb_ewmh_wm_strut_t *wm_strut,
			    xcb_generic_error_t **e)
{
  xcb_get_property_reply_t *r = xcb_get_property_reply(c, cookie, e);
  const uint8_t ret = xcb_ewmh_get_wm_strut_from_reply(wm_strut, r);
  free(r);
  return ret;
}

/**
 * _NET_WM_ICON_GEOMETRY
 */

DO_GET_PROPERTY(_NET_WM_ICON_GEOMETRY, wm_icon_geometry, CARDINAL, 4)

void
xcb_ewmh_set_wm_icon_geometry_checked(xcb_connection_t *c,
				      xcb_window_t window,
				      uint32_t left, uint32_t right,
				      uint32_t top, uint32_t bottom)
{
  const uint32_t data[] = { left, right, top, bottom };

  xcb_change_property_checked(c, XCB_PROP_MODE_REPLACE, window,
			      _NET_WM_ICON_GEOMETRY, CARDINAL, 32, 4, data);
}

void
xcb_ewmh_set_wm_icon_geometry(xcb_connection_t *c,
			      xcb_window_t window,
			      uint32_t left, uint32_t right,
			      uint32_t top, uint32_t bottom)
{
  const uint32_t data[] = { left, right, top, bottom };

  xcb_change_property(c, XCB_PROP_MODE_REPLACE, window, _NET_WM_ICON_GEOMETRY,
		      CARDINAL, 32, 4, data);
}

uint8_t
xcb_ewmh_get_wm_icon_geometry_from_reply(xcb_ewmh_geometry_t *wm_icon_geometry,
					 xcb_get_property_reply_t *r)
{
  if(!r || r->type != CARDINAL || r->format != 32 ||
     GET_NB_FROM_LEN(xcb_get_property_value_length(r), 2) != 4)
    return 0;

  memcpy(wm_icon_geometry, xcb_get_property_value(r),
	 xcb_get_property_value_length(r));

  return 1;
}

uint8_t
xcb_ewmh_get_wm_icon_geometry_reply(xcb_connection_t *c,
				    xcb_get_property_cookie_t cookie,
				    xcb_ewmh_geometry_t *wm_icon_geometry,
				    xcb_generic_error_t **e)
{
  xcb_get_property_reply_t *r = xcb_get_property_reply(c, cookie, e);
  const uint8_t ret = xcb_ewmh_get_wm_icon_geometry_from_reply(wm_icon_geometry, r);
  free(r);
  return ret;
}

/**
 * _NET_WM_ICON
 */

DO_GET_PROPERTY(_NET_WM_ICON, wm_icon, CARDINAL, UINT_MAX)

static inline void
set_wm_icon_data(uint32_t data[], uint32_t width, uint32_t height,
		 uint32_t img_len, uint32_t *img)
{
  data[0] = width;
  data[1] = height;

  memcpy(data + 2, img, img_len);
}

void
xcb_ewmh_set_wm_icon_checked(xcb_connection_t *c,
			     xcb_window_t window,
			     uint32_t width, uint32_t height,
			     uint32_t img_len, uint32_t *img)
{
  const uint32_t data_len = img_len + 2;
  uint32_t data[data_len];

  set_wm_icon_data(data, width, height, img_len, img);

  xcb_change_property_checked(c, XCB_PROP_MODE_REPLACE, window, _NET_WM_ICON,
			      CARDINAL, 32, data_len, data);
}

void
xcb_ewmh_set_wm_icon(xcb_connection_t *c,
		     xcb_window_t window,
		     uint32_t width, uint32_t height,
		     uint32_t img_len, uint32_t *img)
{
  const uint32_t data_len = img_len + 2;
  uint32_t data[data_len];

  set_wm_icon_data(data, width, height, img_len, img);

  xcb_change_property(c, XCB_PROP_MODE_REPLACE, window, _NET_WM_ICON, CARDINAL,
		      32, data_len, data);
}

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
xcb_ewmh_get_wm_icon_reply(xcb_connection_t *c,
			   xcb_get_property_cookie_t cookie,
			   xcb_ewmh_get_wm_icon_reply_t *wm_icon,
			   xcb_generic_error_t **e)
{
  xcb_get_property_reply_t *r = xcb_get_property_reply(c, cookie, e);
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

DO_ACCESSORS_SINGLE_VALUE_ATOM(_NET_WM_PID, wm_pid, CARDINAL, uint32_t,
			       cardinal)

/**
 * _NET_WM_USER_TIME
 */

DO_ACCESSORS_SINGLE_VALUE_ATOM(_NET_WM_USER_TIME, wm_user_time, CARDINAL,
			       uint32_t, cardinal)

/**
 * _NET_WM_USER_TIME_WINDOW
 */

DO_ACCESSORS_SINGLE_VALUE_ATOM(_NET_WM_USER_TIME_WINDOW, wm_user_time_window,
			       CARDINAL, uint32_t, cardinal)

/**
 * _NET_FRAME_EXTENTS
 */

DO_GET_PROPERTY(_NET_FRAME_EXTENTS, frame_extents, CARDINAL, 4)

void
xcb_ewmh_set_frame_extents(xcb_connection_t *c,
			   xcb_window_t window,
			   uint32_t left, uint32_t right,
			   uint32_t top, uint32_t bottom)
{
  const uint32_t data[] = { left, right, top, bottom };

  xcb_change_property(c, XCB_PROP_MODE_REPLACE, window, _NET_FRAME_EXTENTS,
		      CARDINAL, 32, 4, data);
}

void
xcb_ewmh_set_frame_extents_checked(xcb_connection_t *c,
				   xcb_window_t window,
				   uint32_t left, uint32_t right,
				   uint32_t top, uint32_t bottom)
{
  const uint32_t data[] = { left, right, top, bottom };

  xcb_change_property_checked(c, XCB_PROP_MODE_REPLACE, window,
			      _NET_FRAME_EXTENTS, CARDINAL, 32, 4, data);
}

uint8_t
xcb_ewmh_get_frame_extents_from_reply(xcb_ewmh_get_frame_extents_reply_t *frame_extents,
				      xcb_get_property_reply_t *r)
{
  if(!r || r->type != CARDINAL || r->format != 32 ||
     GET_NB_FROM_LEN(xcb_get_property_value_length(r), 2) != 4)
    return 0;

  memcpy(frame_extents, xcb_get_property_value(r),
	 xcb_get_property_value_length(r));

  return 1;
}

uint8_t
xcb_ewmh_get_frame_extents_reply(xcb_connection_t *c,
				 xcb_get_property_cookie_t cookie,
				 xcb_ewmh_get_frame_extents_reply_t *frame_extents,
				 xcb_generic_error_t **e)
{
  xcb_get_property_reply_t *r = xcb_get_property_reply(c, cookie, e);
  const uint8_t ret = xcb_ewmh_get_frame_extents_from_reply(frame_extents, r);
  free(r);
  return ret;
}

/**
 * _NET_WM_PING
 *
 * TODO: client resend function?
 */

void
xcb_ewmh_send_wm_ping(xcb_connection_t *c,
		      xcb_window_t window,
		      xcb_timestamp_t timestamp)
{
  const uint32_t data[] = { _NET_WM_PING, timestamp, window };

  send_client_message(c, window, window, WM_PROTOCOLS, 3, data);
}

/**
 * _NET_WM_SYNC_REQUES
 * _NET_WM_SYNC_REQUEST_COUNTER
 */

DO_GET_PROPERTY(_NET_WM_SYNC_REQUEST, wm_sync_request_counter, CARDINAL, 2)

void
xcb_ewmh_set_wm_sync_request_counter(xcb_connection_t *c,
				     xcb_window_t window,
				     xcb_atom_t wm_sync_request_counter_atom,
				     uint32_t low, uint32_t high)
{
  const uint32_t data[] = { low, high };

  xcb_change_property(c, XCB_PROP_MODE_REPLACE, window, _NET_WM_SYNC_REQUEST,
		      CARDINAL, 32, 2, data);
}

void
xcb_ewmh_set_wm_sync_request_counter_checked(xcb_connection_t *c,
					     xcb_window_t window,
					     xcb_atom_t wm_sync_request_counter_atom,
					     uint32_t low, uint32_t high)
{
  const uint32_t data[] = { low, high };

  xcb_change_property_checked(c, XCB_PROP_MODE_REPLACE, window,
			      _NET_WM_SYNC_REQUEST, CARDINAL, 32, 2, data);
}

void
xcb_ewmh_send_wm_sync_request(xcb_connection_t *c,
			      xcb_window_t window,
			      xcb_atom_t wm_protocols_atom,
			      xcb_atom_t wm_sync_request_atom,
			      xcb_timestamp_t timestamp,
			      uint64_t counter)
{
  const uint32_t data[] = { _NET_WM_SYNC_REQUEST, timestamp, counter,
			    GET_NB_FROM_LEN(counter, 32) };

  send_client_message(c, window, window, WM_PROTOCOLS, 4, data);
}

uint8_t
xcb_ewmh_get_wm_sync_request_counter_from_reply(uint64_t *counter,
						xcb_get_property_reply_t *r)
{
  /* 2 cardinals? */
  if(!r || r->type != CARDINAL || r->format != 32 ||
     GET_NB_FROM_LEN(xcb_get_property_value_length(r), 2) != 2)
    return 0;

  uint32_t *r_value = (uint32_t *) xcb_get_property_value(r);
  *counter = (r_value[0] | GET_LEN_FROM_NB(r_value[1], 8));

  return 1;
}

uint8_t
xcb_ewmh_get_wm_sync_request_counter_reply(xcb_connection_t *c,
					   xcb_get_property_cookie_t cookie,
					   uint64_t *counter,
					   xcb_generic_error_t **e)
{
  xcb_get_property_reply_t *r = xcb_get_property_reply(c, cookie, e);
  const uint8_t ret = xcb_ewmh_get_wm_sync_request_counter_from_reply(counter, r);
  free(r);
  return ret;
}

/**
 * _NET_WM_FULLSCREEN_MONITORS
 */

DO_GET_PROPERTY(_NET_WM_FULLSCREEN_MONITORS, wm_fullscreen_monitors, CARDINAL, 4)

void
xcb_ewmh_set_wm_fullscreen_monitors(xcb_connection_t *c,
				    xcb_window_t window,
				    uint32_t top, uint32_t bottom,
				    uint32_t left, uint32_t right)
{
  const uint32_t data[] = { top, bottom, left, right };

  xcb_change_property(c, XCB_PROP_MODE_REPLACE, window,
		      _NET_WM_FULLSCREEN_MONITORS, CARDINAL, 32, 4, data);
}

void
xcb_ewmh_set_wm_fullscreen_monitors_checked(xcb_connection_t *c,
					    xcb_window_t window,
					    uint32_t top, uint32_t bottom,
					    uint32_t left, uint32_t right)
{
  const uint32_t data[] = { top, bottom, left, right };

  xcb_change_property_checked(c, XCB_PROP_MODE_REPLACE, window,
			      _NET_WM_FULLSCREEN_MONITORS, CARDINAL, 32, 4,
			      data);
}

void
xcb_ewmh_request_change_wm_fullscreen_monitors(xcb_connection_t *c,
					       xcb_window_t window,
					       uint32_t top, uint32_t bottom,
					       uint32_t left, uint32_t right,
					       xcb_ewmh_client_source_type_t source_indication)
{
  const uint32_t data[] = { top, bottom, left, right, source_indication };

  send_client_message(c, window, root_window, _NET_WM_FULLSCREEN_MONITORS, 5,
		      data);
}

uint8_t
xcb_ewmh_get_wm_fullscreen_monitors_from_reply(xcb_ewmh_get_wm_fullscreen_monitors_reply_t *wm_fullscreen_monitors,
					       xcb_get_property_reply_t *r)
{
  if(!r || r->type != CARDINAL || r->format != 32 ||
     GET_NB_FROM_LEN(xcb_get_property_value_length(r), 2) != 4)
    return 0;

  memcpy(wm_fullscreen_monitors, xcb_get_property_value(r),
	 xcb_get_property_value_length(r));

  return 1;
}

uint8_t
xcb_ewmh_get_wm_fullscreen_monitors_reply(xcb_connection_t *c,
					  xcb_get_property_cookie_t cookie,
					  xcb_ewmh_get_wm_fullscreen_monitors_reply_t *wm_fullscreen_monitors,
					  xcb_generic_error_t **e)
{
  xcb_get_property_reply_t *r = xcb_get_property_reply(c, cookie, e);
  const uint8_t ret = xcb_ewmh_get_wm_fullscreen_monitors_from_reply(wm_fullscreen_monitors, r);
  free(r);
  return ret;
}

/**
 * _NET_WM_FULL_PLACEMENT
 */

/**
 * _NET_WM_CM_Sn
 */

xcb_get_selection_owner_cookie_t
xcb_ewmh_get_wm_cm_owner(xcb_connection_t *c)
{
  return xcb_get_selection_owner(c, _NET_WM_CM_Sn);
}

xcb_get_selection_owner_cookie_t
xcb_ewmh_get_wm_cm_owner_unchecked(xcb_connection_t *c)
{
  return xcb_get_selection_owner_unchecked(c, _NET_WM_CM_Sn);
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
xcb_ewmh_get_wm_cm_owner_reply(xcb_connection_t *c,
			       xcb_get_selection_owner_cookie_t cookie,
			       xcb_window_t *owner,
			       xcb_generic_error_t **e)
{
  xcb_get_selection_owner_reply_t *r = xcb_get_selection_owner_reply(c, cookie, e);
  return xcb_ewmh_get_wm_cm_owner_from_reply(owner, r);
}

/* TODO: section 2.1, 2.2 */
static void
set_wm_cm_owner_client_message(xcb_connection_t *c,
			       xcb_window_t owner,
			       xcb_timestamp_t timestamp,
			       uint32_t selection_data1,
			       uint32_t selection_data2)
{
  xcb_client_message_event_t ev;
  memset(&ev, 0, sizeof(xcb_client_message_event_t));

  ev.response_type = XCB_CLIENT_MESSAGE;
  ev.format = 32;
  ev.type = MANAGER;
  ev.data.data32[0] = timestamp;
  ev.data.data32[1] = _NET_WM_CM_Sn;
  ev.data.data32[2] = owner;
  ev.data.data32[3] = selection_data1;
  ev.data.data32[4] = selection_data2;

  xcb_send_event(c, 0, root_window, XCB_EVENT_MASK_STRUCTURE_NOTIFY,
		 (char *) &ev);
}

void
xcb_ewmh_set_wm_cm_owner(xcb_connection_t *c,
			 xcb_window_t owner,
			 xcb_timestamp_t timestamp,
			 uint32_t selection_data1,
			 uint32_t selection_data2)
{
  xcb_set_selection_owner(c, owner, _NET_WM_CM_Sn, 0);
  set_wm_cm_owner_client_message(c, owner, timestamp,
				 selection_data1, selection_data2);
}

void
xcb_ewmh_set_wm_cm_owner_checked(xcb_connection_t *c,
				 xcb_window_t owner,
				 xcb_timestamp_t timestamp,
				 uint32_t selection_data1,
				 uint32_t selection_data2)
{
  xcb_set_selection_owner_checked(c, owner, _NET_WM_CM_Sn, 0);
  set_wm_cm_owner_client_message(c, owner, timestamp,
				 selection_data1, selection_data2);
}

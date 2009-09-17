#ifndef __XCB_EWMH_H__
#define __XCB_EWMH_H__

/*
 * Copyright (C) 2009 Arnaud Fontaine <arnau@debian.org>
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

/**
 * @defgroup xcb__ewmh_t XCB EWMH Functions
 *
 * These functions  allow easy handling  of the protocol  described in
 * the Extended Window Manager  Hints specification. The list of Atoms
 * is stored as an M4 file  (atomlist.m4) where each Atom is stored as
 * a variable defined in the header.
 *
 * Replies of requests generating a  list of pointers (such as list of
 * windows, atoms and UTF-8 strings)  are simply stored as a structure
 * holding  the XCB  reply which  should (usually)  never  be accessed
 * directly and has  to be wipe afterwards. This  structure provides a
 * convenient access to the list given in the reply itself.
 *
 * \todo Add  missing prototypes but  asks for advices on  XCB mailing
 *       list before.
 *
 * @{
 */

#include <xcb/xcb.h>

#ifdef __cplusplus
extern "C" {
#endif

/**
 * @brief Hold EWMH
 */
typedef struct {
  /** The X connection */
  xcb_connection_t *connection;
  /** The root window of this connection */
  xcb_window_t root;
  /** The EWMH atoms of this connection */dnl
define(`DO', `ifelse(`$1', , , `
  xcb_atom_t $1;DO(shift($@))')')dnl
include(atomlist.m4)dnl
} xcb_ewmh_connection_t;

/**
 * @brief Hold a GetProperty reply containing a list of Atoms
 */
typedef struct {
  /** The number of Atoms */
  uint32_t atoms_len;
  /** The list of Atoms */
  xcb_atom_t *atoms;
  /** The actual GetProperty reply */
  xcb_get_property_reply_t *_reply;
} xcb_ewmh_get_atoms_reply_t;

/**
 * @brief Hold a GetProperty reply containing a list of Windows
 */
typedef struct {
  /** The number of Windows */
  uint32_t windows_len;
  /** The list of Windows */
  xcb_window_t *windows;
  /** The actual GetProperty reply */
  xcb_get_property_reply_t *_reply;
} xcb_ewmh_get_windows_reply_t;

/**
 * @brief Hold a GetProperty reply containg a list of UTF-8 strings
 */
typedef struct {
  /** The number of UTF-8 strings */
  uint32_t strings_len;
  /** The list of UTF-8 strings */
  char *strings;
  /** The actual GetProperty reply */
  xcb_get_property_reply_t *_reply;
} xcb_ewmh_get_utf8_strings_reply_t;

/**
 * @brief Property values as coordinates
 */
typedef struct {
  /** The x coordinate */
  uint32_t x;
  /** The y coordinate */
  uint32_t y;
} xcb_ewmh_coordinates_t;

/**
 * @brief Hold reply of _NET_DESKTOP_VIEWPORT GetProperty
 */
typedef struct {
  /** The number of desktop viewports */
  uint32_t desktop_viewport_len;
  /** The desktop viewports */
  xcb_ewmh_coordinates_t *desktop_viewport;
  /** The actual GetProperty reply */
  xcb_get_property_reply_t *_reply;
} xcb_ewmh_get_desktop_viewport_reply_t;

/**
 * @brief Property values as a geometry
 */
typedef struct {
  /** The x coordinate */
  uint32_t x;
  /** The y coordinate */
  uint32_t y;
  /** The width */
  uint32_t width;
  /** The height */
  uint32_t height;
} xcb_ewmh_geometry_t;

/**
 * @brief Hold reply of a _NET_WORKAREA GetProperty
 */
typedef struct {
  /** The number of desktop workarea */
  uint32_t workarea_len;
  /** The list of desktop workarea */
  xcb_ewmh_geometry_t *workarea;
  /** The actual GetProperty reply */
  xcb_get_property_reply_t *_reply;
} xcb_ewmh_get_workarea_reply_t;

/**
 * @brief Source indication in requests
 */
typedef enum {
  /** No source at all (for clients supporting an older version of
      EWMH specification) */
  XCB_EWMH_CLIENT_SOURCE_TYPE_NONE = 0,
  /** Normal application */
  XCB_EWMH_CLIENT_SOURCE_TYPE_NORMAL = 1,
  /** Pagers and other clients that represent direct user actions */
  XCB_EWMH_CLIENT_SOURCE_TYPE_OTHER = 2
} xcb_ewmh_client_source_type_t;

/**
 * @brief _NET_DESKTOP_LAYOUT orientation
 */
typedef enum {
  /** Horizontal orientation (desktops laid out in rows) */
  XCB_EWMH_WM_ORIENTATION_HORZ = 0,
  /** Vertical orientation (desktops laid out in columns) */
  XCB_EWMH_WM_ORIENTATION_VERT = 1
} xcb_ewmh_desktop_layout_orientation_t;

/**
 * @brief _NET_DESKTOP_LAYOUT starting corner
 */
typedef enum {
  /** Starting corner on the top left */
  XCB_EWMH_WM_TOPLEFT = 0,
  /** Starting corner on the top right */
  XCB_EWMH_WM_TOPRIGHT = 1,
  /** Starting corner on the bottom right */
  XCB_EWMH_WM_BOTTOMRIGHT = 2,
  /** Starting corner on the bottom left */
  XCB_EWMH_WM_BOTTOMLEFT = 3
} xcb_ewmh_desktop_layout_starting_corner_t;

/**
 * @brief Hold reply of a _NET_DESKTOP_LAYOUT GetProperty
 * @see xcb_ewmh_desktop_layout_orientation_t
 * @see xcb_ewmh_desktop_layout_starting_corner_t
 */
typedef struct {
  /** The desktops orientation */
  uint32_t orientation;
  /** The number of columns */
  uint32_t columns;
  /** The number of rows */
  uint32_t rows;
  /** The desktops starting corner */
  uint32_t starting_corner;
} xcb_ewmh_get_desktop_layout_reply_t;

/**
 * @brief _NET_WM_MOVERESIZE value when moving via keyboard
 * @see xcb_ewmh_moveresize_direction_t
 */
typedef enum {
  /** The window x coordinate */
  XCB_EWMH_MOVERESIZE_WINDOW_X = (1 << 8),
  /** The window y coordinate */
  XCB_EWMH_MOVERESIZE_WINDOW_Y = (1 << 9),
  /** The window width */
  XCB_EWMH_MOVERESIZE_WINDOW_WIDTH = (1 << 10),
  /** The window height */
  XCB_EWMH_MOVERESIZE_WINDOW_HEIGHT = (1 << 11)
} xcb_ewmh_moveresize_window_opt_flags_t;

/**
 * @brief _NET_WM_MOVERESIZE window movement or resizing
 */
typedef enum {
  /** Resizing applied on the top left edge */
  XCB_EWMH_WM_MOVERESIZE_SIZE_TOPLEFT = 0,
  /** Resizing applied on the top edge */
  XCB_EWMH_WM_MOVERESIZE_SIZE_TOP = 1,
  /** Resizing applied on the top right edge */
  XCB_EWMH_WM_MOVERESIZE_SIZE_TOPRIGHT = 2,
  /** Resizing applied on the right edge */
  XCB_EWMH_WM_MOVERESIZE_SIZE_RIGHT = 3,
  /** Resizing applied on the bottom right edge */
  XCB_EWMH_WM_MOVERESIZE_SIZE_BOTTOMRIGHT = 4,
  /** Resizing applied on the bottom edge */
  XCB_EWMH_WM_MOVERESIZE_SIZE_BOTTOM = 5,
  /** Resizing applied on the bottom left edge */
  XCB_EWMH_WM_MOVERESIZE_SIZE_BOTTOMLEFT = 6,
  /** Resizing applied on the left edge */
  XCB_EWMH_WM_MOVERESIZE_SIZE_LEFT = 7,
  /* Movement only */
  XCB_EWMH_WM_MOVERESIZE_MOVE = 8,
  /* Size via keyboard */
  XCB_EWMH_WM_MOVERESIZE_SIZE_KEYBOARD = 9,
  /* Move via keyboard */
  XCB_EWMH_WM_MOVERESIZE_MOVE_KEYBOARD = 10,
  /* Cancel operation */
  XCB_EWMH_WM_MOVERESIZE_CANCEL = 11
} xcb_ewmh_moveresize_direction_t;

/**
 * @brief Action on the _NET_WM_STATE property
 */
typedef enum {
  /* Remove/unset property */
  XCB_EWMH_WM_STATE_REMOVE = 0,
  /* Add/set property */
  XCB_EWMH_WM_STATE_ADD = 1,
  /* Toggle property  */
  XCB_EWMH_WM_STATE_TOGGLE = 2
} xcb_ewmh_wm_state_action_t;

/**
 * @brief Hold reply of _NET_WM_STRUT_PARTIAL GetProperty
 */
typedef struct {
  /** Reserved space on the left border of the screen */
  uint32_t left;
  /** Reserved space on the right border of the screen */
  uint32_t right;
  /** Reserved space on the top border of the screen */
  uint32_t top;
  /** Reserved space on the bottom border of the screen */
  uint32_t bottom;
  /** Beginning y coordinate of the left strut */
  uint32_t left_start_y;
  /** Ending y coordinate of the left strut */
  uint32_t left_end_y;
  /** Beginning y coordinate of the right strut */
  uint32_t right_start_y;
  /** Ending y coordinate of the right strut */
  uint32_t right_end_y;
  /** Beginning x coordinate of the top strut */
  uint32_t top_start_x;
  /** Ending x coordinate of the top strut */
  uint32_t top_end_x;
  /** Beginning x coordinate of the bottom strut */
  uint32_t bottom_start_x;
  /** Ending x coordinate of the bottom strut */
  uint32_t bottom_end_x;
} xcb_ewmh_wm_strut_t;

/**
 * @brief Hold reply of _NET_WM_ICON GetProperty
 */
typedef struct {
  /** Icon width */
  uint32_t width;
  /** Icon height */
  uint32_t height;
  /** Rows, left to right and top to bottom of the CARDINAL ARGB */
  uint32_t *data;
  /** The actual GetProperty reply */
  xcb_get_property_reply_t *_reply;
} xcb_ewmh_get_wm_icon_reply_t;

/**
 * @brief Hold reply of _NET_REQUEST_FRAME_EXTENTS GetProperty
 */
typedef struct {
  /** Width of the left border */
  uint32_t left;
  /** Width of the right border */
  uint32_t right;
  /** Width of the top border */
  uint32_t top;
  /** Width of the bottom border */
  uint32_t bottom;
} xcb_ewmh_get_frame_extents_reply_t;

/**
 * @brief Hold reply of _NET_WM_FULLSCREEN_MONITORS GetProperty
 */
typedef struct {
  /** Monitor whose top edge defines the top edge of the fullscreen
      window */
  uint32_t top;
  /** Monitor whose bottom edge defines the bottom edge of the
      fullscreen window */
  uint32_t bottom;
  /** Monitor whose left edge defines the left edge of the fullscreen
      window */
  uint32_t left;
  /** Monitor whose right edge defines the right edge of the
      fullscreen window */
  uint32_t right;
} xcb_ewmh_get_wm_fullscreen_monitors_reply_t;

/**
 * @brief Send InternAtom requests for the EWMH atoms and its required atoms.
 * @param c The connection to the X server.
 * @param ewmh The information relative to EWMH.
 * @param screen_nbr The screen number.
 * @return The cookies corresponding to EWMH atoms.
 */
xcb_intern_atom_cookie_t *xcb_ewmh_init_atoms(xcb_connection_t *c,
					      xcb_ewmh_connection_t * const ewmh,
					      const int screen_nbr);

/**
 * @brief Process the replies previously sent
 * @param emwh The information relative to EWMH.
 * @param ewmh_cookies The cookies corresponding to EWMH atoms.
 * @param e Error if any.
 * @return Return 1 on success, 0 otherwise.
 */
uint8_t xcb_ewmh_init_atoms_replies(xcb_ewmh_connection_t * const ewmh,
				    xcb_intern_atom_cookie_t *ewmh_cookies,
				    xcb_generic_error_t **e);

/**
 * @brief Wipe the Atoms list reply.
 *
 * This function must be called to free the memory allocated for atoms
 * when the reply is requested in '_reply' functions.
 *
 * @param data The X reply to be freed.
 */
void xcb_ewmh_get_atoms_reply_wipe(xcb_ewmh_get_atoms_reply_t *data);

/**
 * @brief Wipe the Windows list reply.
 *
 * This function must  be called to the free  the memory allocated for
 * windows when the reply is requested in '_reply' functions.
 *
 * @param data The X reply to be freed.
 */
void xcb_ewmh_get_windows_reply_wipe(xcb_ewmh_get_windows_reply_t *data);

/**
 * @brief Send  GetProperty request to get  _NET_SUPPORTED root window
 *        property
 *
 * _NET_SUPPORTED, ATOM[]/32
 *
 * This property MUST  be set by the Window  Manager to indicate which
 * hints it supports. For example: considering _NET_WM_STATE both this
 * atom   and   all   supported  states   e.g.    _NET_WM_STATE_MODAL,
 * _NET_WM_STATE_STICKY, would be  listed. This assumes that backwards
 * incompatible changes will  not be made to the  hints (without being
 * renamed).
 *
 * This form can be used only if  the request will cause a reply to be
 * generated. Any returned error will be placed in the event queue.
 *
 * @param ewmh The information relative to EWMH.
 * @return The _NET_SUPPORTED cookie of the GetProperty request.
 */
xcb_get_property_cookie_t xcb_ewmh_get_supported_unchecked(xcb_ewmh_connection_t *ewmh);

/**
 * @brief Send  GetProperty request to get  _NET_SUPPORTED root window
 *        property
 *
 * @see xcb_ewmh_get_supported_unchecked
 * @param ewmh The information relative to EWMH.
 * @return The _NET_SUPPORTED cookie of the GetProperty request.
 */
xcb_get_property_cookie_t xcb_ewmh_get_supported(xcb_ewmh_connection_t *ewmh);

/**
 * @brief Get reply from the GetProperty _NET_SUPPORTED cookie
 *
 * The  parameter  e  supplied  to  this  function  must  be  NULL  if
 * xcb_get_window_supported_unchecked() is used.  Otherwise, it stores
 * the error if any.
 *
 * @param ewmh The information relative to EWMH.
 * @param cookie The _NET_SUPPORTED GetProperty request cookie.
 * @param supported The reply to be filled.
 * @param The xcb_generic_error_t supplied.
 * @return Return 1 on success, 0 otherwise.
 */
uint8_t xcb_ewmh_get_supported_reply(xcb_ewmh_connection_t *ewmh,
				     xcb_get_property_cookie_t cookie,
				     xcb_ewmh_get_atoms_reply_t *supported,
				     xcb_generic_error_t **e);

/**
 * @brief Send GetProperty request to get _NET_CLIENT_LIST root window
 *        property
 *
 * This  array   contains  all  X   Windows  managed  by   the  Window
 * Manager. _NET_CLIENT_LIST has  initial mapping order, starting with
 * the oldest window.  This property SHOULD be set  and updated by the
 * Window Manager.
 *
 * @param ewmh The information relative to EWMH.
 * @return The _NET_CLIENT_LIST cookie of the GetProperty request.
 */
xcb_get_property_cookie_t xcb_ewmh_get_client_list_unchecked(xcb_ewmh_connection_t *ewmh);

/**
 * @brief Send GetProperty request to get _NET_CLIENT_LIST root window
 *        property
 *
 * @see xcb_ewmh_get_client_list_unchecked
 * @param ewmh The information relative to EWMH.
 * @return The _NET_CLIENT_LIST cookie of the GetProperty request.
 */
xcb_get_property_cookie_t xcb_ewmh_get_client_list(xcb_ewmh_connection_t *ewmh);

/**
 * @brief Get reply from the GetProperty _NET_CLIENT_LIST cookie
 *
 * The  parameter  e  supplied  to  this  function  must  be  NULL  if
 * xcb_get_window_client_list_unchecked()  is   used.   Otherwise,  it
 * stores the error if any.
 *
 * @param ewmh The information relative to EWMH.
 * @param cookie The _NET_CLIENT_LIST GetProperty request cookie.
 * @param clients The list of clients to be filled.
 * @param The xcb_generic_error_t supplied.
 * @return Return 1 on success, 0 otherwise.
 */
uint8_t xcb_ewmh_get_client_list_reply(xcb_ewmh_connection_t *ewmh,
				       xcb_get_property_cookie_t cookie,
				       xcb_ewmh_get_windows_reply_t *clients,
				       xcb_generic_error_t **e);

/**
 * @brief  Send  GetProperty request  to  get _NET_ACTIVE_WINDOW  root
 *        window property
 *
 * The window ID  of the currently active window or  None if no window
 * has  the focus.  This is  a read-only  property set  by  the Window
 * Manager.  This property  SHOULD be  set and  updated by  the Window
 * Manager.
 *
 * This form can be used only if  the request will cause a reply to be
 * generated. Any returned error will be placed in the event queue.
 *
 * @param ewmh The information relative to EWMH.
 * @return The _NET_ACTIVE_WINDOW cookie of the GetProperty request.
 */
xcb_get_property_cookie_t xcb_ewmh_get_active_window_unchecked(xcb_ewmh_connection_t *ewmh);

/**
 * @brief  Send  GetProperty request  to  get _NET_ACTIVE_WINDOW  root
 *        window property
 *
 * @see xcb_ewmh_get_active_window_unchecked
 * @param ewmh The information relative to EWMH.
 * @return The _NET_ACTIVE_WINDOW cookie of the GetProperty request.
 */
xcb_get_property_cookie_t xcb_ewmh_get_active_window(xcb_ewmh_connection_t *ewmh);

/**
 * @brief Get reply from the GetProperty _NET_ACTIVE_WINDOW cookie
 *
 * The  parameter  e  supplied  to  this  function  must  be  NULL  if
 * xcb_get_active_window_unchecked()  is used.   Otherwise,  it stores
 * the error if any.
 *
 * @param ewmh The information relative to EWMH.
 * @param cookie The _NET_ACTIVE_WINDOW GetProperty request cookie.
 * @param active_window The reply to be filled.
 * @param The xcb_generic_error_t supplied.
 * @return Return 1 on success, 0 otherwise.
 */
uint8_t xcb_ewmh_get_active_window_reply(xcb_ewmh_connection_t *ewmh,
					 xcb_get_property_cookie_t cookie,
					 xcb_window_t *active_window,
					 xcb_generic_error_t **e);

/**
 * @brief Send ClientMessage requesting to change the _NET_ACTIVE_WINDOW
 *
 * The window ID  of the currently active window or  None if no window
 * has  the focus.  This  is a  read-only property  set by  the Window
 * Manager. If a Client wants to activate another window, it MUST send
 * a  _NET_ACTIVE_WINDOW  client  message  to  the  root  window.  The
 * timestamp is Client's  last user activity timestamp at  the time of
 * the request, and the currently active window is the Client's active
 * toplevel window, if any (the Window Manager may be e.g. more likely
 * to obey  the request  if it will  mean transferring focus  from one
 * active window to another).
 *
 * @see xcb_ewmh_client_source_type_t
 * @param ewmh The information relative to EWMH.
 * @param window_to_active The window ID to activate.
 * @param source_indication The source indication.
 * @param timestamp The client's last user activity timestamp.
 * @param current_active_window The currently active window or None
 */
void xcb_ewmh_request_change_active_window(xcb_ewmh_connection_t *ewmh,
					   xcb_window_t window_to_activate,
					   xcb_ewmh_client_source_type_t source_indication,
					   xcb_timestamp_t timestamp,
					   xcb_window_t current_active_window);

/**
 * @brief   Send  GetSelectOwner   request   to  get   the  owner   of
 *        _NET_WM_CM_Sn root window property
 *
 * @param ewmh The information relative to EWMH.
 * @return The _NET_WM_CM_Sn cookie of the GetSelectionOwner request.
 */
xcb_get_selection_owner_cookie_t xcb_ewmh_get_wm_cm_owner_unchecked(xcb_ewmh_connection_t *ewmh);

/**
 * @brief   Send  GetSelectOwner   request   to  get   the  owner   of
 *        _NET_WM_CM_Sn root window property
 *
 * @see xcb_ewmh_get_wm_cm_owner_unchecked
 * @param ewmh The information relative to EWMH.
 * @return The _NET_WM_CM_Sn cookie of the GetSelectionOwner request.
 */
xcb_get_selection_owner_cookie_t xcb_ewmh_get_wm_cm_owner(xcb_ewmh_connection_t *ewmh);

/**
 * @brief Get reply from the GetProperty _NET_CLIENT_LIST cookie
 *
 * The  parameter  e  supplied  to  this  function  must  be  NULL  if
 * xcb_get_window_client_list_unchecked()  is   used.   Otherwise,  it
 * stores the error if any.
 *
 * @param ewmh The information relative to EWMH.
 * @param cookie The _NET_WM_CM_Sn GetSelectionOwner request cookie.
 * @param owner The window ID which owns the selection or None.
 * @param The xcb_generic_error_t supplied.
 * @return Return 1 on success, 0 otherwise.
 */
uint8_t xcb_ewmh_get_wm_cm_owner_reply(xcb_ewmh_connection_t *ewmh,
				       xcb_get_selection_owner_cookie_t cookie,
				       xcb_window_t *owner,
				       xcb_generic_error_t **e);

/**
 * @brief Set _NET_WM_CM_Sn ownership to the given window
 *
 * For  each  screen they  manage,  compositing  manager MUST  acquire
 * ownership of a selection named _NET_WM_CM_Sn, where n is the screen
 * number.
 *
 * @param ewmh The information relative to EWMH.
 * @param owner The new owner of _NET_WM_CM_Sn selection.
 * @param timestamp The client's last user activity timestamp.
 * @param selection_data1 Optional data described by ICCCM
 * @param selection_data2 Optional data described by ICCCM
 */
void xcb_ewmh_set_wm_cm_owner(xcb_ewmh_connection_t *ewmh,
			      xcb_window_t owner,
			      xcb_timestamp_t timestamp,
			      uint32_t selection_data1,
			      uint32_t selection_data2);

#ifdef __cplusplus
}
#endif

/**
 * @}
 */

#endif /* __XCB_EWMH_H__ */

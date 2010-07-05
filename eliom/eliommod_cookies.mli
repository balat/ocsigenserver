val make_new_session_id : unit -> string

val get_cookie_info :
  float ->
  Eliom_common.sitedata ->
  Eliom_common.SessionCookies.key Ocsigen_lib.String_Table.t ->
  Eliom_common.SessionCookies.key Ocsigen_lib.String_Table.t ->
  string Ocsigen_lib.String_Table.t ->
  (Eliom_common.SessionCookies.key Ocsigen_lib.String_Table.t *
     Eliom_common.SessionCookies.key Ocsigen_lib.String_Table.t *
     string Ocsigen_lib.String_Table.t) option ->
  Eliom_common.tables Eliom_common.cookie_info *
  Ocsigen_lib.String_Table.key list

val new_service_cookie_table :
  unit -> Eliom_common.tables Eliom_common.servicecookiestable
val new_data_cookie_table : unit -> Eliom_common.datacookiestable
val compute_session_cookies_to_send :
  Eliom_common.sitedata ->
  Eliom_common.tables Eliom_common.cookie_info ->
  Ocsigen_http_frame.cookieset -> Ocsigen_http_frame.cookieset Lwt.t
val compute_cookies_to_send :
  Eliom_common.sitedata ->
  Eliom_common.tables Eliom_common.cookie_info ->
  Ocsigen_http_frame.cookieset -> Ocsigen_http_frame.cookieset Lwt.t
val add_cookie_list_to_send :
  Eliom_common.sitedata ->
  Eliom_common.cookie list -> Ocsigen_http_frame.cookieset -> Ocsigen_http_frame.cookieset
val compute_new_ri_cookies' :
  float ->
  string list ->
  string Ocsigen_lib.String_Table.t ->
  Eliom_common.cookie list -> string Ocsigen_lib.String_Table.t
val compute_new_ri_cookies :
  float ->
  string list ->
  string Ocsigen_lib.String_Table.t ->
  Eliom_common.tables Eliom_common.cookie_info ->
  Eliom_common.cookie list -> string Ocsigen_lib.String_Table.t Lwt.t

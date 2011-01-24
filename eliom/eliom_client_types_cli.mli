(* Ocsigen
 * http://www.ocsigen.org
 * Copyright (C) 2010 Vincent Balat
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, with linking exception;
 * either version 2.1 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 *)
type sitedata =
  {site_dir: Ocsigen_lib.url_path;
   site_dir_string: string;
  }

type server_params

val sp : server_params

type 'a data_key

val to_data_key_ : (int64 * int) -> 'a data_key
val of_data_key_ : 'a data_key -> (int64 * int)


(**/**)
type poly
type eliom_data_type =
    ((XML.ref_tree, (int * XML.ref_tree) list) Ocsigen_lib.leftright *
        ((int64 * int) * poly list) *
        Ocsigen_cookies.cookieset *
        string list (* on load scripts *) *
        string list (* on change scripts *) *
        Eliom_common.sess_info
    )

type eliom_appl_answer =
  | EAContent of (eliom_data_type * string)

val a_closure_id : int
val a_closure_id_string : string
val add_tab_cookies_to_get_form_id : int
val add_tab_cookies_to_get_form_id_string : string
val add_tab_cookies_to_post_form_id : int
val add_tab_cookies_to_post_form_id_string : string

val eliom_appl_answer_content_type : string

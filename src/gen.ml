open Cmdliner

let ocp_indent_template = {|
base = 2
type = 2
in = 0
with = 0
match_clause = 2
ppx_stritem_ext = 2
max_indent = 4
strict_with = never
strict_else = always
strict_comments = false
align_ops = true
align_params = auto
|}

let opam_template = {|
opam-version: "1.2"
version: "0.1.0"
maintainer: "<email>"
authors: "<author name>"
license: "<license>"
homepage: ""
bug-reports: ""
dev-repo: ""
tags: []
build: [
  "jbuilder" "build" "-p" name "-j" jobs
]
depends: [
  "jbuilder" { >= "1.0+beta16"}
  "ocamlfind"
  "js_of_ocaml" { >= "3.0.2"}
  "js_of_ocaml-ppx" { >= "3.0.2"}
]
available: [ocaml-version >= "4.05.0"]
|}

let topkg_template = {|
#use "topfind"
#require "topkg-jbuilder.auto"
                      |}

let project =
  let doc = "Target directory for project" in
  Arg.(value & opt string "." & info ["p"; "project"] ~docv:"project" ~doc)

let license =
  let doc = "The LICENSE of project" in
  Arg.(value & opt string "MIT" & info ["license"] ~docv:"LICENSE" ~doc)

let gen_topkg project =
  let pkg_path = Filename.concat project "pkg" in
  if not @@ Sys.file_exists pkg_path then
    Unix.mkdir pkg_path 0o755
  else
    ();

  let pkg_name = Filename.concat pkg_path "pkg.ml" in
  let os = open_out pkg_name in
  try
    output_string os topkg_template
  with _ -> ();
    close_out os

let gen_opam project license =
  let regex = Str.regexp "<license>" in
  let license_replaced = Str.replace_first regex license opam_template in

  if not @@ Sys.file_exists project then
    Term.exit ~term_err:1 (`Error `Exn)
  else
    ();

  let project_name = Filename.basename project in
  let os = open_out @@ Filename.(concat project (project_name ^ ".opam")) in
  try
    output_string os license_replaced
  with _ -> ();
    close_out os

let gen_ocp_indent project =
  let config_name = Filename.concat project ".ocp-indent" in
  let os = open_out config_name in
  try
    output_string os ocp_indent_template
  with _ -> ();
    close_out os

let gen project license =
  gen_opam project license;
  gen_topkg project;
  gen_ocp_indent project

let gen_t = Term.(const gen $ project $ license)

let info =
  let doc = "Generate initial project from simple template" in
  let man = [
    `S Manpage.s_bugs;
    `P "Email bug reports to <derutakayu@gmail.com>." ]
  in
  Term.info "ocaml-project-template" ~version:"‌0.1.0" ~doc ~exits:Term.default_exits ~man

let () =
  Term.exit @@ Term.eval (gen_t, info)

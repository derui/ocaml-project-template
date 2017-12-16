open Cmdliner

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
  "jbuilder" {build & >= "1.0+beta16"}
  "ocamlfind"
  "commonjs_of_ocaml" {>= "0.1.0"}
  "js_of_ocaml" {build & >= "2.8.4"}
  "js_of_ocaml-ppx" {build & >= "2.8.4"}
]
available: [ocaml-version >= "4.05.0"]
|}

let topkg_template = {|
#use "topfind"
#require "topkg-jbuilder.auto"
                      |}

let project =
  let doc = "Target directory for project" in
  Arg.(value & opt string "." & info ["p"; "project"] ~docv:"proejct" ~doc)

let license =
  let doc = "The LISENCE of project" in
  Arg.(value & opt string "MIT" & info ["";"lisence"] ~docv:"LISENCE" ~doc)


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
  with _ -> close_out os

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
  with _ -> close_out os

let gen project license =
  gen_opam project license;
  gen_topkg project

let gen_t = Term.(const gen $ project $ license)

let info =
  let doc = "Generate initial project from simple template" in
  let man = [
    `S Manpage.s_bugs;
    `P "Email bug reports to <derutakayu@gmail.com>." ]
  in
  Term.info "ocaml-project-template" ~version:"%‌%VERSION%%" ~doc ~exits:Term.default_exits ~man

let () =
  Term.exit @@ Term.eval (gen_t, info)

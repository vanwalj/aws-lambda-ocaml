FROM ocaml/opam2:alpine

RUN sudo apk update
RUN sudo apk add m4
RUN opam init
RUN sh -c "cd ~/opam-repository && git pull -q"
RUN opam update
RUN opam upgrade
RUN opam install dune

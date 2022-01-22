%.bzl: %.bzl.in
	m4 $^ > $@

all: base.bzl core_defs.bzl core_macros.bzl
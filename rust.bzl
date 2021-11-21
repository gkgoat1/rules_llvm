load("@rules_rust//rust/private:common.bzl", "rust_common")
load("@rules_rust//rust/private:rustc.bzl", "rustc_compile_action", "BuildInfo")
load(
    "@rules_rust//rust/private:utils.bzl",
    "crate_name_from_attr",
    "dedent",
    "determine_output_hash",
    "expand_dict_value_locations",
    "find_toolchain",
    "transform_deps",
)

def rs_ll_emit(target,ctx,pctx):
        # Find lib.rs
    crate_root = crate_root_src(ctx.attr, ctx.files.srcs, "lib")
    _assert_no_deprecated_attributes(ctx)
    _assert_correct_dep_mapping(ctx)

    toolchain = find_toolchain(ctx)

    # Determine unique hash for this rlib
    output_hash = determine_output_hash(crate_root)

    crate_name = crate_name_from_attr(ctx.attr)
    rust_lib_name = _determine_lib_name(
        crate_name,
        crate_type,
        toolchain,
        output_hash,
    )
    rust_lib = ctx.actions.declare_file(rust_lib_name)

    make_rust_providers_target_independent = toolchain._incompatible_make_rust_providers_target_independent
    deps = transform_deps(ctx.attr.deps, make_rust_providers_target_independent)
    proc_macro_deps = transform_deps(ctx.attr.proc_macro_deps, make_rust_providers_target_independent)

    r = rustc_compile_action(
        ctx = ctx,
        attr = ctx.attr,
        toolchain = toolchain,
        crate_info = rust_common.create_crate_info(
            name = crate_name,
            type = crate_type,
            root = crate_root,
            srcs = depset(ctx.files.srcs),
            deps = depset(deps),
            proc_macro_deps = depset(proc_macro_deps),
            aliases = ctx.attr.aliases,
            output = rust_lib,
            edition = get_edition(ctx.attr, toolchain),
            rustc_env = ctx.attr.rustc_env,
            is_test = False,
            compile_data = depset(ctx.files.compile_data),
            owner = ctx.label,
        ),
        output_hash = output_hash,
        rust_flags = ["--emit-llvm","-S"]
    )
    return [r[DefaultInfo].files]

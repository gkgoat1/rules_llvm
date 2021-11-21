load("//:rust.bzl","rs_ll_emit")
load("//:base.bzl","LLLibrary")
load("@rules_rust//rust/private:rustc.bzl", "BuildInfo")
load("@io_bazel_rules_go//:def.bzl",'GoLibrary')
def _ll_visit_impl(target,ctx):
    d = [dep[LLLibrary].files for d in ctx.deps]
    if BuildInfo in target:
        return LLLibrary(files = depset(rs_ll_emit(target,ctx.rule,ctx), transitive = d))
    if CCInfo in target:
        s = ctx.rule.srcs
        h = target[CCInfo].compilation_context.headers
        f = []
        for s in srcs:
            ff = ctx.actions.declare_file(s + ".ll")
            a = [s,"-S","--emit-llvm","-o",f]
            for i in target[CCInfo].compilation_context.includes:
                a += ["-I",i]
            ctx.actions.run(outputs = [ff],inputs = s + h,executable = "clang",args = a)
            f += [ff]
        return LLLibrary(files = depset(f, transitive = d))
    if GoLibrary in target:
        ll = ctx.actions.declare_file(target[GoLibrary].importpath + ".ll")
        ctx.actions.run(outputs = [ll], inputs = target.srcs, executable = "llvm-goc", arguments = ["-fgo-pkgpath=" + target[GoLibrary].importpath,"-S","--emit-llvm","-o",ll] + srcs)
        return LLLibrary(files = depset([ll], transitive = d))
    return LLLibrary(files = depset([], transitive = d))

ll_visit = aspect(
    implenentation = _ll_visit_impl,
    attr_aspects = ['deps']
)

def _ll_library_impl(ctx):
    return [DefaultInfo(files = ctx.attr.src[LLLibrary].files)]

ll_library = rule(
    implenentation = _ll_library_impl,
    attrs = {
        'src': attr.label(aspects = [ll_visit])
    }
)

def _llvm_cbe_impl(ctx):
    f = []
    for s in ctx.attr.src[DefaultInfo].files:
        ff = ctx.actions.declare_file(s + ".c")
        ctx.actions.run(inputs = [s],outputs = [ff],executable = "llvm-cbe",arguments = [s,"-o",ff])
        f = f + [ff]
    return [DefaultInfo(files = f)]

llvm_cbe = rule(
    implenentation = _llvm_cbe_impl,
    attrs = {
        'src': attr.label()
    }
)

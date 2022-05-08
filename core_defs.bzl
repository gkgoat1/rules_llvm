#m4_changequote([<,>])
load("//:rust.bzl","rs_ll_emit")
load("//:base.bzl","LLLibrary")
load("@rules_rust//rust/private:rustc.bzl", "BuildInfo")
load("@io_bazel_rules_go//:def.bzl",'GoLibrary')
def make_ll_library(ctx,files,aspect = True):
    cf = []
    for s in files:
        ff = ctx.actions.declare_file(s + ".c")
        ctx.actions.run(inputs = [s],outputs = [ff],executable = ctx.toolchains["//:llvm"].cbe.files,arguments = [s,"-o",ff])
        cf = cf + [ff]
    ef = []
    for s in cf:
        ff = ctx.actions.declare_file(s + ".eir")
        ctx.actions.run(inputs = [s],outputs = [ff],executable = ctx.toolchains["//:llvm"].elvm8cc,arguments = [s,"-c","-o",ff])
        ef = ef + [ff]
    return [LLLibrary(files = files,cRender = cf)] + make_eir_library(ctx,files = ef, aspect = aspect) + (if aspect then [] else [DefaultInfo(files = files)])
def make_eir_library(ctx,files,aspect = True):
    render = {}
    return [EiLibrary(files = files, render = render)]
def _ll_visit_impl(target,ctx):
    d = [dep[LLLibrary].files for d in ctx.deps]
    if BuildInfo in target:
        return make_ll_library(ctx,files = depset(rs_ll_emit(target,ctx.rule,ctx), transitive = d))
    if CCInfo in target:
        s = ctx.rule.srcs
        h = target[CCInfo].compilation_context.headers
        f = []
        for s in srcs:
            ff = ctx.actions.declare_file(s + ".ll")
            a = [s,"-S","--emit-llvm","-o",f]
            for i in target[CCInfo].compilation_context.includes:
                a += ["-I",i]
            ctx.actions.run(outputs = [ff],inputs = s + h,executable = ctx.toolchains["//:llvm"].clang.files,args = a)
            f += [ff]
        return make_ll_library(ctx,files = depset(f, transitive = d))
    if GoLibrary in target:
        ll = ctx.actions.declare_file(target[GoLibrary].importpath + ".ll")
        ctx.actions.run(outputs = [ll], inputs = target.srcs, executable = ctx.toolchains["//:llvm"].goc.files, arguments = ["-fgo-pkgpath=" + target[GoLibrary].importpath,"-S","--emit-llvm","-o",ll] + srcs)
        return make_ll_library(ctx,files = depset([ll], transitive = d))
    return make_ll_library(ctx,files = depset([], transitive = d))

ll_visit = aspect(
    implenentation = _ll_visit_impl,
    attr_aspects = ['deps'],
    toolchains = ["//:llvm"]
)

def _ll_library_impl(ctx):
    f = []
    for a in ctx.attr.deps:
        f = f + a[LLLibrary].files
    for l in ctx.attr.libs:
        f = f + l[LLLibrary].files
    return [DefaultInfo(files = ctx.attr.src[LLLibrary].files + f)] + make_ll_library(ctx,files = ctx.attr.src[LLLibrary].files + f)

ll_library = rule(
    implenentation = _ll_library_impl,
    attrs = {
        'src': attr.label(aspects = [ll_visit]),
        'libs': attr.label_list(aspects = [ll_visit]),
        'deps': attr.label_list()
    }
)

def _llvm_cbe_impl(ctx):
    return [DefaultInfo(files = ctx.attr.src[LLLibrary].cRender)]

llvm_cbe = rule(
    implenentation = _llvm_cbe_impl,
    attrs = {
        'src': attr.label()
    }
)

def _llvm_cbe_cat_impl(ctx):
    f = ctx.attr.src[LLLibrary].cRender
    o = ctx.actions.declare_file("output.c")
    ctx.actions.run_shell(inputs = f,outputs = [o],command = "t=\"$1\";shift 1;exec cat \"$@\" > $t",arguments = [o.path] + [ff.path for ff in f])
    return [DefaultInfo(files = [o])]

llvm_cbe_cat = rule(
    implenentation = _llvm_cbe_cat_impl,
    attrs = {
        'src': attr.label()
    }
)


def _elvm_target_impl(ctx):
    return [DefaultInfo(files = ctx.attr.src[EiLibrary].render[ctx.attr.target])]

elvm_target = rule(
    implenentation = _elvm_target_impl,
    attrs = {
        'src': attr.label(),
        'target': attr.string()
    }
)

def _llvm_transformer_impl(ctx):
    lf = ctx.attr.src[LLLibrary].files
    ff = []
    for l in lf:
        f = ctx.actions.declare_file(l + ".new.ll")
        ctx.actions.run(inputs = [l],outputs = [l],executable = ctx.attr.transformer,arguments = [l,f])
        ff += [f]
    return [DefaultInfo(files = depset(ff)),LLLibrary(files = depset(ff))]

llvm_transformer = rule(
    implenentation = _llvm_transformer_impl,
    attrs = {
        'src': attr.label(),
        'transformer': attr.label(allow_files = True,executable = True)
    }
)
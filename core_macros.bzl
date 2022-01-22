load("//:core_defs.bzl","ll_library","llvm_cbe")
def ll_cc_library(name,src):
    ll_library(name = name + "/ll",src = src)
    llvm_cbe(name = name + "/c",src = ":" + name + "/ll")
    cc_library(name = name,srcs = [":"+ name + "/c"])


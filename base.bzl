#m4_changequote([<,>])
LLLibrary = provider(fields = {
    "files": "files for LLVM",
    "cRender": "Rendered C source code files",
    "reducedCCode": "Reduced C code"
    })

EiLibrary = provider(fields = {
    "files": "Files for ELVM"
    "render": "rendered files"
})
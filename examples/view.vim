vim9script
# Note that this is NOT an example, this is the example viewer
# Usage: vim -S view.vim *.vim

import "../import/lines9.vim"

exec "source " .. argv()[0]
lines9.Init(g:lines9_config)
lines9.Enable()


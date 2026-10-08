-- unicode-fallback.lua — pandoc Lua filter (pandoc >= 2.0)
--
-- Appends the LaTeX header unicode-fallback.tex to the document's `header-includes`
-- metadata. Why a filter and not `pandoc -H`: -H sets the template *variable*
-- header-includes, which silently overrides a `header-includes:` block given in YAML
-- metadata (as in ConfigShell's header_tex.yaml). The filter keeps both.
--
-- Path of the .tex file: environment variable MD2PDF_UNICODE_FALLBACK, else the default
-- below. Only active for LaTeX output (pandoc -t latex / -t pdf via a LaTeX engine).
local path = os.getenv("MD2PDF_UNICODE_FALLBACK")
    or "/opt/ConfigShell/share/Markdown-Document/unicode-fallback.tex"

local function isList(v)
  if pandoc.utils and pandoc.utils.type then      -- pandoc >= 2.17
    return pandoc.utils.type(v) == "List"
  end
  return type(v) == "table" and v.t == "MetaList"  -- older pandoc
end

function Meta(meta)
  if not FORMAT:match("latex") and not FORMAT:match("beamer") then return nil end
  local f = io.open(path, "r")
  if not f then
    io.stderr:write("unicode-fallback.lua: cannot read " .. path .. " — Unicode fallback not applied\n")
    return nil
  end
  local tex = f:read("*a"); f:close()
  local block = pandoc.MetaBlocks({ pandoc.RawBlock("latex", tex) })
  local hi = meta["header-includes"]
  if hi == nil then
    meta["header-includes"] = pandoc.MetaList({ block })
  elseif isList(hi) then
    hi[#hi + 1] = block
    meta["header-includes"] = hi
  else
    meta["header-includes"] = pandoc.MetaList({ hi, block })
  end
  return meta
end

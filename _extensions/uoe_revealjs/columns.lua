-- columns.lua
-- Short aliases for common column layouts. The ratios are in the class name:
--
--   :::: {.cols-1-2}          1/3 : 2/3
--   :::: {.cols-2-1}          2/3 : 1/3
--   :::: {.cols-1-1-1}        three equal columns
--   :::: {.cols-1-2-1}        any ratio list works
--
-- Each direct child div becomes a column; no `.columns` / `.column` /
-- `width=` needed, e.g.
--
--   :::: {.cols-1-2}
--   ::: {}
--   left
--   :::
--   ::: {}
--   right
--   :::
--   ::::
--
-- Optional extra classes on the container:  .cols-center  (vertically centre
-- the columns)   .cols-bottom  (align to the bottom).

local function ratios_from(el)
  for _, c in ipairs(el.classes) do
    local spec = c:match("^cols%-(%d[%d%-]*)$")
    if spec then
      local r = {}
      for n in spec:gmatch("%d+") do table.insert(r, tonumber(n)) end
      return r
    end
  end
end

function Div(el)
  if not quarto.doc.is_format("revealjs") then return nil end
  local ratios = ratios_from(el)
  if not ratios then return nil end

  el.classes:insert("columns")
  el.classes:insert("uoe-cols")

  local i = 0
  for _, child in ipairs(el.content) do
    if child.t == "Div" then
      i = i + 1
      if not child.classes:includes("column") then child.classes:insert("column") end
      local r = ratios[i] or ratios[#ratios]
      local style = child.attributes["style"] or ""
      child.attributes["style"] = string.format("flex: %d 1 0; width: auto; %s", r, style)
    end
  end
  return el
end
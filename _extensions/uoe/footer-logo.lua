-- footer-logo.lua
-- Options (document or extension YAML, both default to true):
--   show-top-logo:    false  -> hide the logo in the top-right of the title bar
--   show-footer-logo: false  -> hide the logo in the bottom-right corner
--
-- 1. Adds a logo (optionally linked) to the default Quarto footer.
-- 2. Builds a persistent footer bar from `footer-text`, `footer-link[-text]`
--    and `footer-license[-text]`, injected into <body> with a tiny script so
--    Reveal's slide visibility rules cannot hide it.

-- true unless the option is explicitly set to false
local function enabled(doc, key)
  return doc.meta[key] ~= false
end

local function meta_str(doc, key)
  local v = doc.meta[key]
  return v and pandoc.utils.stringify(v) or nil
end

local function html_escape(s)
  return (s:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"):gsub('"', "&quot;"))
end

-- URL + text -> <a>; only URL -> <a> showing the URL; only text -> plain text.
local function link_part(url, text)
  if url and text then
    return '<a href="' .. html_escape(url) .. '">' .. html_escape(text) .. '</a>'
  elseif url then
    return '<a href="' .. html_escape(url) .. '">' .. html_escape(url) .. '</a>'
  elseif text then
    return html_escape(text)
  end
end

-- Escape a string for use inside a single-quoted JS string in an inline <script>.
local function js_escape(s)
  return (s:gsub("\\", "\\\\"):gsub("'", "\\'"):gsub("\n", "\\n"):gsub("\r", "\\r"):gsub("</", "<\\/"))
end

function Pandoc(doc)
  if not quarto.doc.is_format("revealjs") then
    return doc
  end

  -- 0. Top logo (created by Quarto from the `logo` option) ---------------------
  if not enabled(doc, 'show-top-logo') then
    quarto.doc.include_text('in-header', '<style>.reveal .slide-logo{display:none !important}</style>')
  end

  -- 1. Footer logo -----------------------------------------------------------
  local logo_path = meta_str(doc, 'footer-logo')
  if logo_path and enabled(doc, 'show-footer-logo') then
    local logo_link = meta_str(doc, 'footer-logo-link')
    local img = '<img src="' .. html_escape(logo_path) .. '" class="footer-logo" />'
    local inner = logo_link
        and ('<a href="' .. html_escape(logo_link) .. '" target="_blank">' .. img .. '</a>')
        or img
    local container = pandoc.RawBlock('html', '<div class="footer-logo-container">' .. inner .. '</div>')

    doc = doc:walk({
      Div = function(el)
        if el.classes:includes('footer-default') or el.classes:includes('footer')
            or el.classes:includes('reveal-footer') then
          table.insert(el.content, container)
          return el
        end
      end
    })
  end

  -- 2. Persistent footer ------------------------------------------------------
  local parts = {}
  local text = meta_str(doc, 'footer-text')
  if text then table.insert(parts, html_escape(text)) end

  local link = link_part(meta_str(doc, 'footer-link'), meta_str(doc, 'footer-link-text'))
  if link then table.insert(parts, link) end

  local license = link_part(meta_str(doc, 'footer-license'), meta_str(doc, 'footer-license-text'))
  if license then table.insert(parts, license) end

  if #parts > 0 then
    local script = string.format([[
<script>
document.addEventListener('DOMContentLoaded', function() {
  var el = document.createElement('div');
  el.className = 'persistent-footer';
  el.innerHTML = '%s';
  document.body.appendChild(el);
});
</script>
]], js_escape(table.concat(parts, " | ")))
    -- after-body, not doc.blocks: appending a block puts the script inside
    -- the last slide.
    quarto.doc.include_text('after-body', script)
  end

  return doc
end
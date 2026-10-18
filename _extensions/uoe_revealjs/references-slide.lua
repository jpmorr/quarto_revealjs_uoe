-- references-slide.lua
-- Quarto's default for reveal.js is to dump the bibliography at the bottom of
-- whatever slide happens to be last (and mark it .smaller .scrollable). This
-- filter gives the bibliography its own slide instead.
--
-- Does nothing if
--   * the document has no bibliography, or never cites anything, or
--   * you already placed a `::: {#refs}` div yourself (your placement wins), or
--   * you set `references-slide: false`.
-- Slide title: `reference-section-title` if set, else "References".

function Pandoc(doc)
  if not quarto.doc.is_format("revealjs") then return doc end
  if doc.meta['references-slide'] == false then return doc end
  if not (doc.meta.bibliography or doc.meta.references) then return doc end

  local cited, has_refs_div = false, false
  doc:walk({
    Cite = function() cited = true end,
    Div = function(el) if el.identifier == 'refs' then has_refs_div = true end end,
  })
  if doc.meta.nocite then cited = true end
  if has_refs_div or not cited then return doc end

  local title = doc.meta['reference-section-title']
      and pandoc.utils.stringify(doc.meta['reference-section-title'])
      or "References"

  table.insert(doc.blocks, pandoc.Header(2, title, pandoc.Attr('references-slide', {'smaller', 'scrollable', 'no-fragments'})))
  table.insert(doc.blocks, pandoc.Div({}, pandoc.Attr('refs')))
  return doc
end
local ok, m = pcall(require, "bit32")
assert(ok, "not bit support found")
-- compatible
if m.rol and not m.lrotate then
	m.lrotate = m.rol
end
if m.ror and not m.rrotate then
	m.rrotate = m.ror
end
return m

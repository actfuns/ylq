module(..., package.seeall)

function main()
	local dSchool = require("perform.school")
	local d = {}
	local function build(k, v)
		local dOne = {
			name = v.name,
			desc = v.desc,
			short_desc = v.short_desc,
			type_desc = v.type_desc,
			target_type = v.targetType,
			target_status = v.useTargetStatus,
			is_group = (v.skillGroupType == 2),
			is_physic = (v.skillAttackType == 1),
			skill_icon = (v.skill_icon ~= 0) and v.skill_icon or nil,
			sp = v.sp,
		}
		d[k] = dOne
	end
	for k, v in pairs(dSchool) do
		build(k, v)
	end

	local dPartner = require("perform.partner_perform")
	for k, v in pairs(dPartner) do
		build(k, v)
	end

	local s = table.dump(d, "DATA")
	SaveToFile("magic", s)
end

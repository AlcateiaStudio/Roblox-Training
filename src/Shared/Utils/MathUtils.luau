local MathUtils = {}

MathUtils.MaxNumber = math.huge
MathUtils.MinNumber = -math.huge

function MathUtils.Clamp(a: number, min: number, max: number) 
	if (a < min) then 
		return min
	elseif (a > max)  then
		return max
	else 
		return a
	end
end

function MathUtils.Lerp(start, goal, alpha)
	return start + (goal - start) * alpha
end

function MathUtils.SmoothLerp(variableA, variableB, fraction, deltaTime)
	local f = 1.0 - math.pow(1.0 - fraction, deltaTime )
	if (type(variableA) == "number") then
		return ((1-f) * variableA) + (variableB * f) 
	end
	return variableA:Lerp(variableB, f)
end

return MathUtils
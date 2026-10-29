local M={}
function M.new(goal,seconds)return{phase='READY',count=0,goal=goal,seconds=seconds,remaining=seconds}end
function M.start(s)s.phase='PLAYING';s.count=0;s.remaining=s.seconds end
function M.hit(s)if s.phase~='PLAYING'then return false end;s.count=s.count+1;if s.count>=s.goal then s.phase='WON'end;return true end
function M.tick(s,dt)if s.phase=='PLAYING'then s.remaining=math.max(0,s.remaining+(-dt));if s.remaining==0 then s.phase='LOST'end end end
return M

local UI=require('kit.ui')
local Controller=require('kit.controller')
local Rules=require('game.rules')
local Config=require('game.config')
local S={ready=false,attempts=0}
local points={{-270,30},{240,60},{-80,-90},{190,-80}}
local function render()
 local s=S.game
 S.score.text='已收集 '..s.count..' / '..s.goal
 S.clock.text=string.format('剩余 %.1f 秒',s.remaining)
 S.status.text=s.phase=='READY'and'点击开始，再点击圆形目标' or s.phase=='PLAYING'and'鼠标 / 触屏点击，手柄移动指针后确认' or s.phase=='WON'and'完成！'or'时间到了'
 S.start.label.text=s.phase=='READY'and'开始'or'重新开始'
 S.ui.show(S.target,s.phase=='PLAYING')
end
local function start()Rules.start(S.game);S.target:SetAnchoredPosition(points[1][1],points[1][2]);render()end
local function hit()
 if Rules.hit(S.game)then local p=points[S.game.count%#points+1];S.target:SetAnchoredPosition(p[1],p[2]);render()end
end
local function boot()
 local root=script.object;local U=UI.new(root,Config.nativeTemplates);if not U.fit()then return false end
 S.ui=U;S.game=Rules.new(Config.goal,Config.seconds)
 U.background=U.image('Background',0,0,1280,720,0xFF111B2D)
 S.controller=Controller.create({root=root,instance=function(k,p,n)return U.instance(k=='list'and'container'or k,p,n)end,pos=U.pos,rect=U.image,text=U.text,show=U.show,colors={gold=0xFFFFC85C,white=0xFFFFFFFF,up=0xFF5DDEAD},grids={},back=function()if S.game.phase=='PLAYING'then S.game.phase='READY';render()end end})
 U.input=S.controller
 U.text('Title',0,265,960,60,Config.title,34)
 S.status=U.text('Status',0,205,1000,42,'',22)
 S.score=U.text('Score',-290,140,350,40,'',24)
 S.clock=U.text('Clock',290,140,350,40,'',24)
 S.start=U.button('StartButton',0,-240,240,60,'开始',start)
 S.target=U.container('TargetGroup',0,0,110,110)
 U.image('TargetVisual',0,0,100,100,0xFF5DDEAD,S.target,100002)
 U.area('Target',0,0,110,110,S.target,hit,'收集目标')
 S.ready=true;U.fit();render();print('[启动包] 就绪');return true
end
function OnInit()S.ready=false end
function OnStart()script:EnableUpdate(true)end
function OnUpdate(dt)
 if not S.ready then S.attempts=S.attempts+1;if S.attempts<=120 then boot()elseif S.attempts==121 then printerr('画布初始化超时')end;return end
 S.ui.fit();Rules.tick(S.game,math.max(0,dt));S.controller.update(dt);render()
end
function OnDisable()if S.controller then S.controller.cancel()end end

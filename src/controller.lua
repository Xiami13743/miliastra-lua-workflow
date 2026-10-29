-- 通用手柄适配器：坐标/网格核心来自已实测实现，业务范围和按键回调由cfg注入。
local M={}
function M.create(cfg)
 local S={root=cfg.root};local C=cfg.colors
 local instance,pos,rect,text,show=cfg.instance,cfg.pos,cfg.rect,cfg.text,cfg.show
 local function ui_present()return not cfg.present or cfg.present()end
local function make_controller()
 local I={targets={},byControl={},gridRows={},x=0,y=0,precision=false,enabled=false}
 local function same(a,b)return a and b and(a.id or a.Id or a)==(b.id or b.Id or b)end
 local function activeScope()return cfg.scope and cfg.scope()or S.root end
 local function live(c)
  if not c or not c.alive or c.activeInHierarchy==false or c.interactable==false or c.raycastTarget==false then return false end
  local p=c;local allowed=false;local scope=I.scope or S.root
  while p do if p.active==false or p.visible==false then return false end;if same(p,scope)then allowed=true end;if same(p,S.root)then return allowed end;p=p.parent end;return false
 end
 function I.track(c,button)
  local id=c.id or c.Id or c
  local t=I.byControl[id];if not t then t={c=c,id=id,events={},button=button};I.byControl[id]=t;I.targets[#I.targets+1]=t else t.c=c end
  if button then t.button=true;c.canControllerFocus=false end;return t
 end
 function I.on(c,kind,fn)local t=I.track(c);t.events[kind]=t.events[kind]or{};t.events[kind][#t.events[kind]+1]=fn end
 function I.describe(c,title)I.track(c).title=title end
 function I.gridRow(c,grid,index,base)I.gridRows[c.id or c.Id or c]={control=c,grid=grid,index=index-(base or 0),base=base or 0}end
 -- 原生网格列表项的普通变换读数不保证反映布局后的行位置。
 -- 普通控件仍走实际父链；列表项单独用网格配置及原生滚动端点定位。
 local function parentOf(c)local row=I.gridRows[c.id or c.Id or c];return row and row.grid or c.parent end
 local function measure(c)
  local row=I.gridRows[c.id or c.Id or c];if row then local w,h=row.grid:GetItemSize();local px,py=c:GetPivot();return w,h,px,py end
  local w,h=c:GetSizeDelta();local ax,ay=c:GetAnchorMin();local bx,by=c:GetAnchorMax()
  if ax~=bx or ay~=by then
   local pw,ph;if same(c,S.root)or not c.parent then pw,ph=game.GetUICanvasSize()else pw,ph=measure(c.parent)end
   w=w+(bx-ax)*pw;h=h+(by-ay)*ph
  end
  local px,py=c:GetPivot();return w,h,px,py
 end
 local gridMetrics
 gridMetrics=function(grid)
  local id=grid.id or grid.Id or grid;local w,h=measure(grid);local iw,ih=grid:GetItemSize();local gx,gy=grid:GetItemSpacing();local top,bottom,left,right=grid:GetPadding();local count=grid.itemCount or 0
  local key=count..':'..w..':'..h..':'..iw..':'..ih..':'..gx..':'..gy..':'..top..':'..bottom..':'..left..':'..right
  I.gridMetricsCache=I.gridMetricsCache or{};local m=I.gridMetricsCache[id]
  if not m or m.key~=key then
   local base=0;for _,row in pairs(I.gridRows)do if same(row.grid,grid)then base=row.base;break end end
   local length=grid:GetContentLength();m={key=key,overflow=math.max(0,length-h),top=top,left=left,gap=gy,start=0,finish=1}
   if m.overflow>0 and count>0 then
    local previous=grid.scrollProgress or 0
    grid:ScrollToItemAt(base,Enum.ScrollAlignType.Top);m.start=grid.scrollProgress or 0
    grid:ScrollToItemAt(base+count-1,Enum.ScrollAlignType.Bottom);m.finish=grid.scrollProgress or 0
    grid.scrollProgress=previous;m.unresolved=math.abs(m.finish-m.start)<.00001
   end
   I.gridMetricsCache[id]=m
   print('[手柄网格] '..grid.name..' 项'..count..' 单元'..iw..'×'..ih..' 间距'..gy..' 上边距'..top..' 内容'..length..' 视高'..h..' 首末进度'..m.start..'/'..m.finish..(m.unresolved and' 校准未完成' or''))
  end
  return m
 end
 function I.gridProgress(grid)local m=gridMetrics(grid);if m.overflow<=0 or m.unresolved then return 0 end;return math.max(0,math.min(1,((grid.scrollProgress or m.start)-m.start)/(m.finish-m.start)))end
 function I.setGridProgress(grid,value)local m=gridMetrics(grid);if m.unresolved then return false end;grid.scrollProgress=m.start+(m.finish-m.start)*math.max(0,math.min(1,value));return true end
 local function layout(c,pw,ph,ppx,ppy)
  local row=I.gridRows[c.id or c.Id or c];local w,h,vx,vy=measure(c);local x,y
  if row then local m=gridMetrics(row.grid);x=-ppx*pw+m.left+w*vx;y=(1-ppy)*ph-m.top-h*(1-vy)-row.index*(h+m.gap)+I.gridProgress(row.grid)*m.overflow
  else local ax,ay=c:GetAnchorMin();local bx,by=c:GetAnchorMax();local px,py=c:GetAnchoredPosition();x=px+(ax+(bx-ax)*vx-ppx)*pw;y=py+(ay+(by-ay)*vy-ppy)*ph end
  local sx,sy=c:GetLocalScale();local _,_,angle=c:GetLocalRotation();return x,y,w,h,vx,vy,sx,sy,math.rad(angle or 0)
 end
 local function point(c,x,y)
  local chain={};local p=c;while p do table.insert(chain,1,p);if same(p,S.root)then break end;p=parentOf(p)end
  if not same(chain[1],S.root)then return nil end
  local cw,ch=game.GetUICanvasSize();x=x-cw/2;y=y-ch/2;local pw,ph,ppx,ppy=cw,ch,.5,.5
  local order={};local stretch=1
  for _,n in ipairs(chain)do
   local row=I.gridRows[n.id or n.Id or n];if row and gridMetrics(row.grid).unresolved then return nil end
   local px,py,w,h,vx,vy,sx,sy,a=layout(n,pw,ph,ppx,ppy);local dx,dy=x-px,y-py;local cs,sn=math.cos(a),math.sin(a)
   if math.abs(sx)<.00001 or math.abs(sy)<.00001 then return nil end
   stretch=stretch*math.max(math.abs(sx),math.abs(sy))
   x=(dx*cs+dy*sn)/sx;y=(-dx*sn+dy*cs)/sy
   pw,ph,ppx,ppy=w,h,vx,vy;order[#order+1]=n:GetSiblingIndex()
   if not same(n,c)and(cfg.isViewport and cfg.isViewport(n))and(x< -ppx*pw or x>(1-ppx)*pw or y< -ppy*ph or y>(1-ppy)*ph)then return nil end
  end
  return x,y,pw,ph,ppx,ppy,order,stretch
 end
 local function front(a,b)
  for n=1,math.min(#a,#b)do if a[n]~=b[n]then return a[n]>b[n]end end;return #a>#b
 end
 function I.hit(x,y)
  local best,rank
  for _,t in ipairs(I.targets)do if live(t.c)then local px,py,w,h,vx,vy,order=point(t.c,x,y)
   if px and px>=-vx*w and px<=(1-vx)*w and py>=-vy*h and py<=(1-vy)*h and(not rank or front(order,rank))then best=t;rank=order end
  end end;return best
 end
 local function toCanvas(c,x,y)
  local n=c
  while n do
   local parent=parentOf(n);local pw,ph,ppx,ppy
   if same(n,S.root)then pw,ph=game.GetUICanvasSize();ppx,ppy=.5,.5 else pw,ph,ppx,ppy=measure(parent)end
   local px,py,_,_,_,_,sx,sy,a=layout(n,pw,ph,ppx,ppy);local cs,sn=math.cos(a),math.sin(a)
   x,y=px+x*sx*cs-y*sy*sn,py+x*sx*sn+y*sy*cs
   if same(n,S.root)then local cw,ch=game.GetUICanvasSize();return x+cw/2,y+ch/2 end;n=parent
  end
 end
 function I.center(c)local w,h,vx,vy=measure(c);return toCanvas(c,(.5-vx)*w,(.5-vy)*h)end
 local function bounds(c)
  local w,h,vx,vy=measure(c);local l,b,r,t=math.huge,math.huge,-math.huge,-math.huge
  for _,q in ipairs({{-vx*w,-vy*h},{(1-vx)*w,-vy*h},{(1-vx)*w,(1-vy)*h},{-vx*w,(1-vy)*h}})do local x,y=toCanvas(c,q[1],q[2]);l=math.min(l,x);b=math.min(b,y);r=math.max(r,x);t=math.max(t,y)end
  return l,b,r,t
 end
 local function place(c,x,y)local px,py=point(S.root,x,y);c:SetAnchoredPosition(px,py)end
 local function tipPosition(w,h,target)
  local cw,ch=game.GetUICanvasSize();local sx,sy=S.root:GetLocalScale();w=w*math.abs(sx);h=h*math.abs(sy)
  local l,b,r,t=I.x-4,I.y-4,I.x+4,I.y+4
  if target and(target.button or target.events[Enum.CursorEventType.CursorClick])then l,b,r,t=bounds(target.c)end
  local gap=14*(I.uiScale or 1);local candidates={{r+gap+w/2,(b+t)/2},{l-gap-w/2,(b+t)/2},{(l+r)/2,t+gap+h/2},{(l+r)/2,b-gap-h/2}}
  local bestX,bestY,score
  for i,q in ipairs(candidates)do
   local x=math.max(w/2+4,math.min(cw-w/2-4,q[1]));local y=math.max(h/2+4,math.min(ch-h/2-4,q[2]))
   local overlap=math.max(0,math.min(x+w/2,r+gap)-math.max(x-w/2,l-gap))*math.max(0,math.min(y+h/2,t+gap)-math.max(y-h/2,b-gap))
   local value=overlap*1000+(x-q[1])^2+(y-q[2])^2+i
   if not score or value<score then bestX,bestY,score=x,y,value end
  end
  return bestX,bestY
 end
 local function event()
  local e={touchId=-71,dragging=I.held~=nil};function e:GetUIPos()return I.x,I.y end;function e:GetPressUIPos()return I.pressX or I.x,I.pressY or I.y end;function e:GetUIPosDelta()return I.dx or 0,I.dy or 0 end;return e
 end
 local function emit(t,kind)
  if not t or not live(t.c)then return end
  local fns=t.events[Enum.CursorEventType[kind]]
  if fns then for _,fn in ipairs(fns)do fn(event())end
  elseif kind=='CursorClick'and t.button then t.c:SimulateCursorClick()end
 end
 function I.cancel()
  if I.held then emit(I.held,'CursorExit')end;if I.hover and I.hover~=I.held then emit(I.hover,'CursorExit')end;I.hover=nil;I.held=nil;I.pressKey=nil;I.gridDrag=nil
  if cfg.cancel then cfg.cancel()end
 end
 function I.press(key)
  if not I.enabled then return false end;if (cfg.loading and cfg.loading()) or I.held then return true end
  I.held=I.hit(I.x,I.y);I.pressKey=key;I.pressX=I.x;I.pressY=I.y;I.moved=false
  local grid=I.gridAt(I.x,I.y,0);if grid then
   local x,y,w,h,vx,vy=point(grid,I.x,I.y);local content=grid:GetContentLength();local bar=x>(1-vx)*w-18
   if content>h then
    I.gridDrag={grid=grid,start=I.gridProgress(grid),y=y,range=bar and math.max(1,h-h*h/content)or math.max(1,content-h),bar=bar}
    if not I.held then I.held={c=grid,events={}}end
    if bar then I.setGridProgress(grid,((1-vy)*h-y)/h);I.gridDrag.start=I.gridProgress(grid);I.moved=true end
   end
  end
  emit(I.held,'CursorDown');return true
 end
 function I.release(key)
  if key~=I.pressKey then return false end
  local t=I.held;emit(t,'CursorUp');if I.moved then emit(t,'CursorEndDrag')elseif I.hit(I.x,I.y)==t then emit(t,'CursorClick')end
  I.held=nil;I.pressKey=nil;I.gridDrag=nil;return true
 end
 local function click(name)
  for _,t in ipairs(I.targets)do if t.c.name==name and live(t.c)then emit(t,'CursorClick');return true end end;return false
 end
 function I.back()I.cancel();if cfg.back then cfg.back()end;return true end
 function I.gridAt(x,y,margin)
  local best,rank;for _,grid in ipairs(cfg.grids or{})do if live(grid)then
   local px,py,w,h,vx,vy,order,stretch=point(grid,x,y);local pad=(margin or 0)*(I.uiScale or 1)/math.max(stretch or 1,.00001)
   if px and px>=-vx*w-pad and px<=(1-vx)*w+pad and py>=-vy*h-pad and py<=(1-vy)*h+pad and(not rank or front(order,rank))then best=grid;rank=order end
  end end;return best
 end
 function I.scroll(dir)
  local grid=I.gridAt(I.x,I.y,24)or(cfg.grids and cfg.grids[1])
  if grid and live(grid)then I.setGridProgress(grid,I.gridProgress(grid)+dir*.18);return true end;return false
 end
 local function bind(name,fn)
  local key=Enum.KeyEventType['Controller'..name];if key then S.root:AddKeyEventListener(key,function()if not I.enabled then return false end;return fn()~=false end)end
 end
 for _,name in ipairs({'MenuConfirmKey','InteractKey','NormalAttackKey'})do local key=name;bind(key..'Down',function()return I.press(key)end);bind(key..'Up',function()return I.release(key)end)end
 bind('MenuBackKeyDown',I.back)
 bind('JumpKeyDown',I.back) -- A is the visible back/pause action; continue has its B-click button.
 bind('CraftspersonKey3Down',function()I.precision=true end);bind('CraftspersonKey3Up',function()I.precision=false end)
 bind('CraftspersonKey1Down',function()if cfg.page then cfg.page()end end)
 bind('CraftspersonKey2Down',function()return I.scroll(1)end)
 -- Skill/shoulder chords are reserved for view controls, never direct trades.
 bind('CraftspersonKey4Down',function()if cfg.zoom then cfg.zoom(1)else I.scroll(-1)end end)
 bind('CraftspersonKey5Down',function()if cfg.zoom then cfg.zoom(-1)else I.scroll(1)end end)
 local cursor=instance('list',S.root,'手柄虚拟指针');for _,child in ipairs(cursor:GetChildren())do game.DestroyClientUIControl(child)end;pos(cursor,0,0,22,22);cursor.showCursor=false
 local h=rect('手柄指针横',0,0,18,3,C.gold,cursor);rect('手柄指针竖',0,0,3,18,C.gold,cursor)
 local dot=rect('手柄指针中心',0,0,4,4,C.white,cursor)
 local hint=text('手柄操作提示',0,0,400,34,'右摇杆 移动指针 · LT+摇杆 精细移动',13,C.white,S.root,Enum.TextHorizontalAlignment.Middle);hint.bgColor=0x47152B3B
 local popup=instance('list',S.root,'手柄悬停提示');for _,child in ipairs(popup:GetChildren())do game.DestroyClientUIControl(child)end;pos(popup,0,0,400,74)
 local tipBg=rect('手柄提示底',0,0,400,74,0x47152B3B,popup);tipBg.enableSoftEdge=false
 local action=text('手柄悬停操作',-40,18,300,34,'',14,C.white,popup,Enum.TextHorizontalAlignment.Left)
 local backLabel=text('手柄悬停返回动作',154,18,78,34,'A 返回',13,C.white,popup,Enum.TextHorizontalAlignment.Middle)
 local scrollHint=text('手柄网格滚动提示',0,-18,400,34,'左摇杆 ↑↓ 滚动 · 按住 B 拖动列表',13,C.white,popup,Enum.TextHorizontalAlignment.Middle)
 local fineHint=text('手柄精细移动提示',0,-18,400,34,'LT+摇杆 精细移动',13,C.white,popup,Enum.TextHorizontalAlignment.Middle)
 show(scrollHint,false)
 local function caption(t)
  if cfg.caption then local v=cfg.caption(t.c);if v then return v end end
  if t.title then return t.title end
  for _,child in ipairs(t.c:GetChildren())do if child.text and child.text~=''then return child.text:gsub('\n',' ')end end
  return t.c.name or'操作'
 end
 local function clickable(t)return t and(t.button or t.events[Enum.CursorEventType.CursorClick])end
 local function nearby(x,y)
  local best,rank;for _,t in ipairs(I.targets)do if live(t.c)and clickable(t)then local px,py,w,h,vx,vy,order,stretch=point(t.c,x,y)
   if px then local dx=math.max(-vx*w-px,0,px-(1-vx)*w);local dy=math.max(-vy*h-py,0,py-(1-vy)*h);local pad=18*(I.uiScale or 1)/stretch
    if dx*dx+dy*dy<=pad*pad and(not rank or front(order,rank))then best=t;rank=order end
   end
  end end;return best
 end
 show(cursor,false);show(hint,false);show(popup,false)
 function I.update(dt)
  local scope=activeScope();if not same(scope,I.scope)then I.cancel();I.scope=scope end
  local device=game.GetDevice();local enabled=device==Enum.Device.Controller or device==Enum.Device.MobileController
  if enabled and not I.enabled then
   S.root.canControllerFocus=true
   for _,dir in ipairs({'Up','Down','Left','Right'})do S.root:SetControllerNavigation(Enum.ControllerNavigationDir[dir],Enum.ControllerNavigationMode.None,nil)end
   game.SetControllerFocus(S.root)
  elseif I.enabled and not enabled then S.root.canControllerFocus=false end
  if I.enabled and not enabled then I.cancel();I.precision=false end;I.enabled=enabled
  I.cleanClock=(I.cleanClock or 0)+dt;if I.cleanClock>=1 then I.cleanClock=0;for i=#I.targets,1,-1 do if not I.targets[i].c.alive then I.byControl[I.targets[i].id]=nil;table.remove(I.targets,i)end end;for id,row in pairs(I.gridRows)do if not row.control.alive or not row.grid.alive then I.gridRows[id]=nil end end end
  local present=enabled and ui_present();show(cursor,present);show(hint,present);if not present then show(popup,false);return end
  local cw,ch=game.GetUICanvasSize();local scale=math.min(cw/1280,ch/720);I.uiScale=scale
  local rsx,rsy=S.root:GetLocalScale();local geometryKey=cw..':'..ch..':'..rsx..':'..rsy
  if I.geometryKey~=geometryKey then I.geometryKey=geometryKey;print('[手柄] 画布'..math.floor(cw)..'×'..math.floor(ch)..' 根缩放'..string.format('%.2f×%.2f',rsx,rsy))end
  if not I.initialized then I.x=cw/2;I.y=ch/2;I.initialized=true end
  local x,y=game.GetControllerRightStickAxis();local gameplay=(cfg.gameplay and cfg.gameplay())
  local lx,ly=game.GetControllerLeftStickAxis();local scrollGrid=not gameplay and not I.held and I.gridAt(I.x,I.y,0)
  local scrolling=scrollGrid and math.abs(ly)>.25 and math.abs(ly)>=math.abs(lx)
  if scrolling then local _,h=scrollGrid:GetSizeDelta();local overflow=scrollGrid:GetContentLength()-h;if overflow>0 then I.setGridProgress(scrollGrid,I.gridProgress(scrollGrid)-ly*320*math.min(dt,.05)/overflow)end
  elseif not gameplay and math.abs(x)+math.abs(y)<.15 then x,y=lx,ly end
  local mag=math.sqrt(x*x+y*y);local k=mag>.18 and((math.min(1,mag)-.18)/.82)^1.5/math.max(mag,.001)or 0
  local speed=(I.precision and 105 or 420)*scale;local oldX,oldY=I.x,I.y
  local rootX,rootY=S.root:GetLocalScale();local edgeX,edgeY=math.max(2,11*math.abs(rootX)),math.max(2,11*math.abs(rootY))
  I.x=math.max(edgeX,math.min(cw-edgeX,I.x+x*k*speed*math.min(dt,.05)));I.y=math.max(edgeY,math.min(ch-edgeY,I.y+y*k*speed*math.min(dt,.05)))
  I.dx=I.x-oldX;I.dy=I.y-oldY
  if I.held and(I.dx~=0 or I.dy~=0)then
   if not I.moved and math.abs(I.x-I.pressX)+math.abs(I.y-I.pressY)>5 then I.moved=true;emit(I.held,'CursorBeginDrag')end
   if I.moved then
    if I.gridDrag then local d=I.gridDrag;local _,y=point(d.grid,I.x,I.y);if y then I.setGridProgress(d.grid,d.start+(y-d.y)*(d.bar and-1 or 1)/d.range)end
    else emit(I.held,'CursorDrag')end
   end
  end
  local hovered=I.hit(I.x,I.y)
  local backAction=(cfg.backLabel and cfg.backLabel())or'返回'
  local backText='A '..backAction;if backLabel.text~=backText then backLabel.text=backText end
  hint.text='右摇杆 指针 · LT+摇杆 精细移动 · '..backText
  if hovered~=I.hover then if I.hover then emit(I.hover,'CursorExit')end;I.hover=hovered;if hovered then emit(hovered,'CursorEnter')end end
  dot.imageColor=I.held and C.up or hovered and C.gold or C.white
  place(cursor,I.x,I.y);cursor:SetAsLastSibling()
  local grid=I.gridAt(I.x,I.y,24);local target=clickable(hovered)and hovered or nearby(I.x,I.y)or hovered;local context=target~=nil or grid~=nil
  show(hint,not context and not (cfg.loading and cfg.loading()));if not context then local hx,hy=tipPosition(400,34);place(hint,hx,hy)end;hint:SetAsLastSibling()
  show(popup,context and not (cfg.loading and cfg.loading()))
  if context then local title=target and caption(target)or(grid and grid.name or'列表')
   local value=not target and grid and(title..' · B 点击条目')or title:find('按住 B',1,true)and title or(target and target~=hovered and'移入后 B 点击 · 'or'B 点击 · ')..title;if action.text~=value then action.text=value end
   local map=false;local extra=grid~=nil or map
   scrollHint.text=grid and(gameplay and'按住 B 拖动列表或滚动条 · LT+摇杆 精细移动'or'左摇杆滚动 · 按住 B 拖动列表 · LT+摇杆 精细移动')or'LB+Y 放大 · LB+X 缩小 · LT+摇杆 精细移动';show(scrollHint,extra);show(fineHint,not extra)
   local px,py=tipPosition(400,74,target);place(popup,px,py);popup:SetAsLastSibling()
  end
 end
 return I
end

 return make_controller()
end
return M

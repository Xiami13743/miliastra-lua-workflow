local M={}
function M.new(root,templates)
 local U={root=root,input=nil,ids=assert(templates,"请先配置原生UI模板ID / Configure native UI template IDs")}
 function U.pos(c,x,y,w,h)c:SetAnchorMin(.5,.5);c:SetAnchorMax(.5,.5);c:SetPivot(.5,.5);c:SetAnchoredPosition(x,y);c:SetSizeDelta(w,h)end
 function U.show(c,on)c:SetVisible(on);c:SetActive(on)end
 function U.instance(kind,parent,name)
  local id=U.ids[kind];assert(type(id)=='number'and id>0,'未配置模板ID / Missing template ID: '..kind);local c=game.InstantiateClientUIControl(id,parent or root);assert(c,'模板缺失 '..kind);c.name=name;U.show(c,true);return c
 end
 function U.container(name,x,y,w,h,parent)local c=U.instance('container',parent,name);U.pos(c,x,y,w,h);return c end
 function U.image(name,x,y,w,h,color,parent,id)
  local c=U.instance('image',parent,name);U.pos(c,x,y,w,h);c:SetImage(Enum.ImageSource.StaticReference,id or 100001);c.imageColor=color;c.enableSoftEdge=false;return c
 end
 function U.text(name,x,y,w,h,value,size,color,parent,align)
  local c=U.instance('text',parent,name);U.pos(c,x,y,w,h);c.minimumFontSize=12;c.fontSize=math.max(12,math.floor(size or 22));c.adaptiveFontSize=true;c.horizontalAlignment=align or Enum.TextHorizontalAlignment.Middle;c.verticalAlignment=Enum.TextVerticalAlignment.Middle;c.fontColor=color or 0xFFFFFFFF;c.bgColor=0;c.text=value;return c
 end
 function U.area(name,x,y,w,h,parent,callback,title)
  local c=U.instance('cursor',parent,name);U.pos(c,x,y,w,h);c:AddCursorEventListener(Enum.CursorEventType.CursorClick,callback)
  if U.input then U.input.on(c,Enum.CursorEventType.CursorClick,callback);U.input.describe(c,title or name)end;return c
 end
 function U.button(name,x,y,w,h,caption,callback)
  local c=U.container(name..'Group',x,y,w,h);U.image(name..'Fill',0,0,w,h,0xFF335E9E,c);local label=U.text(name..'Label',0,0,w-24,h-12,caption,22,0xFFFFFFFF,c);local hit=U.area(name,0,0,w,h,c,callback,caption);return{root=c,label=label,hit=hit}
 end
 function U.fit()
  local cw,ch=game.GetUICanvasSize();if not cw or not ch or cw<=0 or ch<=0 or cw~=cw or ch~=ch then return false end
  local scale=math.min(cw/1280,ch/720);U.pos(root,0,0,1280,720);root:SetLocalScale(scale,scale,1);root.showCursor=true
  if U.background then U.background:SetSizeDelta(cw/scale,ch/scale)end;return true
 end
 return U
end
return M

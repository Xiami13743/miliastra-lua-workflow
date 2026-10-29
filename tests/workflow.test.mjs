import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import {lua,lauxlib,lualib,to_luastring,to_jsstring} from 'fengari';
import {projectRoot,bundle,build,check,validateLua} from '../scripts/build.mjs';

function execute(source){
  const L=lauxlib.luaL_newstate();lualib.luaL_openlibs(L);
  try{
    const code=to_luastring(source);
    const loaded=lauxlib.luaL_loadbuffer(L,code,code.length,to_luastring('regression'));
    if(loaded!==lua.LUA_OK)throw Error(to_jsstring(lua.lua_tostring(L,-1)));
    if(lua.lua_pcall(L,0,0,0)!==lua.LUA_OK)throw Error(to_jsstring(lua.lua_tostring(L,-1)));
  }finally{lua.lua_close(L);}
}
const rules=fs.readFileSync(path.join(projectRoot,'src/rules.lua'),'utf8');
const prelude='local Rules=(function()\n'+rules+'\nend)()\n';
function cleanTemp(dir){
  assert.equal(path.dirname(path.resolve(dir)),path.resolve(os.tmpdir()));
  assert.match(path.basename(dir),/^miliastra-(workflow|invalid)-/);
  fs.rmSync(dir,{recursive:true,force:true});
}
test('complete round: pre-start input ignored, win locks outcome, restart resets',()=>{
  execute(prelude+[
    "local s=Rules.new(4,12)",
    "assert(s.phase=='READY' and not Rules.hit(s))",
    "Rules.start(s)",
    "for i=1,4 do assert(Rules.hit(s)) end",
    "assert(s.phase=='WON' and s.count==4)",
    "assert(not Rules.hit(s))",
    "Rules.tick(s,30);assert(s.phase=='WON')",
    "Rules.start(s);assert(s.phase=='PLAYING' and s.count==0 and s.remaining==12)"
  ].join('\n'));
});
test('timeout loses, blocks later hits and supports a fresh attempt',()=>{
  execute(prelude+[
    "local s=Rules.new(4,12);Rules.start(s)",
    "Rules.tick(s,11.5);assert(s.phase=='PLAYING')",
    "Rules.tick(s,1);assert(s.phase=='LOST' and s.remaining==0)",
    "assert(not Rules.hit(s));Rules.start(s);assert(Rules.hit(s))",
    "assert(s.phase=='PLAYING' and s.count==1)"
  ].join('\n'));
});
test('packaged modules load with the native lifecycle entry points',()=>{
  const output=bundle();
  execute(output.source+"\nassert(type(OnInit)=='function' and type(OnStart)=='function' and type(OnUpdate)=='function')");
  assert.equal(output.manifest.inputs.length,5);
});
test('UI adapter rejects unconfigured template IDs before native calls',()=>{
  const source=fs.readFileSync(path.join(projectRoot,'src/ui.lua'),'utf8');
  execute('local UI=(function()\n'+source+'\nend)()\n'+[
    "local U=UI.new({}, {container=0,image=0,text=0,cursor=0})",
    "local ok=pcall(function() U.container('Example',0,0,100,100) end)",
    "assert(not ok)"
  ].join('\n'));
});
test('generated source checks detect stale source or a modified bundle',()=>{
  const temp=fs.mkdtempSync(path.join(os.tmpdir(),'miliastra-workflow-'));
  try{
    fs.cpSync(path.join(projectRoot,'src'),path.join(temp,'src'),{recursive:true});
    fs.copyFileSync(path.join(projectRoot,'project.json'),path.join(temp,'project.json'));
    build(temp);assert.doesNotThrow(()=>check(temp));
    fs.appendFileSync(path.join(temp,'src/config.lua'),'\n-- changed after build\n');
    assert.throws(()=>check(temp),/stale/);
    build(temp);
    fs.appendFileSync(path.join(temp,'dist/main.lua'),'\n-- modified artifact\n');
    assert.throws(()=>check(temp),/stale/);
  }finally{cleanTemp(temp);}
});
test('syntax errors and module paths escaping the project are rejected',()=>{
  assert.throws(()=>validateLua('function broken(', 'invalid'));
  const temp=fs.mkdtempSync(path.join(os.tmpdir(),'miliastra-invalid-'));
  try{
    fs.writeFileSync(path.join(temp,'project.json'),JSON.stringify({
      entry:'src/main.lua',modules:[{module:'escape',path:'../outside.lua'}]}));
    assert.throws(()=>bundle(temp),/outside project/);
  }finally{cleanTemp(temp);}
});

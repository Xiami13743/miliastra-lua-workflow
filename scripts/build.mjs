// SPDX-License-Identifier: GPL-3.0-only
// Packs plain Lua sources only. No native stage-file parsing or writing.
import fs from 'node:fs';
import path from 'node:path';
import crypto from 'node:crypto';
import {fileURLToPath} from 'node:url';
import {lua,lauxlib,to_luastring,to_jsstring} from 'fengari';

export const projectRoot=path.resolve(path.dirname(fileURLToPath(import.meta.url)),'..');
const hash=text=>crypto.createHash('sha256').update(text).digest('hex');
function inside(root,name){
  const target=path.resolve(root,name);
  if(!target.startsWith(path.resolve(root)+path.sep))throw Error('Source path outside project');
  return target;
}
export function validateLua(source,label){
  const L=lauxlib.luaL_newstate();
  try{
    const code=to_luastring(source);
    if(lauxlib.luaL_loadbuffer(L,code,code.length,to_luastring(label))!==lua.LUA_OK){
      throw Error(to_jsstring(lua.lua_tostring(L,-1)));
    }
  }finally{lua.lua_close(L);}
}
export function bundle(root=projectRoot){
  const project=JSON.parse(fs.readFileSync(path.join(root,'project.json'),'utf8'));
  const names=new Set(),inputs=[];
  const pieces=['-- Generated Lua bundle. Edit src/*.lua, then npm run build.',
    '-- SPDX-License-Identifier: GPL-3.0-only',
    'local __loaders,__loaded={},{}',
    'local __native_require=require',
    'local function require(name)',
    ' if __loaded[name]~=nil then return __loaded[name] end',
    ' local loader=__loaders[name]',
    ' if not loader then return __native_require(name) end',
    ' local value=loader();if value==nil then value=true end',
    ' __loaded[name]=value;return value',
    'end'];
  for(const item of project.modules){
    if(!/^[A-Za-z0-9_.-]+$/.test(item.module)||names.has(item.module))throw Error('Invalid or duplicate module');
    names.add(item.module);
    const source=fs.readFileSync(inside(root,item.path),'utf8');
    validateLua(source,item.path);
    inputs.push({path:item.path,sha256:hash(source)});
    pieces.push('__loaders['+JSON.stringify(item.module)+']=function()\n'+source+'\nend');
  }
  const entry=fs.readFileSync(inside(root,project.entry),'utf8');
  validateLua(entry,project.entry);
  inputs.push({path:project.entry,sha256:hash(entry)});
  pieces.push(entry);
  const source=pieces.join('\n')+'\n';
  validateLua(source,'main.lua');
  return {source,manifest:{project:project.name,inputs,bundleSha256:hash(source),
    artifact:'dist/main.lua',nativeEditorVerified:false,
    requiredSetup:'Set nativeTemplates in src/config.lua to your own project template IDs.'}};
}
export function build(root=projectRoot){
  const output=bundle(root),dir=path.join(root,'dist');
  fs.mkdirSync(dir,{recursive:true});
  fs.writeFileSync(path.join(dir,'main.lua'),output.source);
  fs.writeFileSync(path.join(dir,'manifest.json'),JSON.stringify(output.manifest,null,2)+'\n');
  return output;
}
export function check(root=projectRoot){
  const expected=bundle(root),actual=fs.readFileSync(path.join(root,'dist/main.lua'),'utf8');
  const manifest=JSON.parse(fs.readFileSync(path.join(root,'dist/manifest.json'),'utf8'));
  if(actual!==expected.source||JSON.stringify(manifest)!==JSON.stringify(expected.manifest)){
    throw Error('Generated bundle is stale; run npm run build');
  }
  return expected.manifest;
}
if(process.argv[1]&&path.resolve(process.argv[1])===fileURLToPath(import.meta.url)){
  const output=process.argv.includes('--check')?check():build().manifest;
  console.log(JSON.stringify(output,null,2));
}

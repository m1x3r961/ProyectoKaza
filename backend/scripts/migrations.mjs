import {readFile,writeFile,mkdir} from 'node:fs/promises';
import {fileURLToPath} from 'node:url';
import {resolve} from 'node:path';

const root=new URL('../../supabase/',import.meta.url);
export async function migrationBundle(mode) {
 if(!['fresh','upgrade'].includes(mode)) throw new Error('Use fresh or upgrade');
 const order=JSON.parse(await readFile(new URL('migration-order.json',root),'utf8'));
 const files=mode==='fresh'?order:order.slice(order.findIndex(f=>f.startsWith('00023_')));
 const sql=await Promise.all(files.map(async f=>`-- SOURCE: ${f}\n${(await readFile(new URL('migrations/'+f,root),'utf8')).replace(/^(?:BEGIN|COMMIT);[\t ]*\r?$/gm,'')}`));
 const check=mode==='fresh'
  ? "IF to_regclass('public.profiles') IS NOT NULL THEN RAISE EXCEPTION 'Fresh installation requires an empty KAZA schema'; END IF;"
  : "IF to_regclass('public.mock_credit_applications') IS NULL OR to_regclass('public.dev_projects') IS NULL THEN RAISE EXCEPTION 'Reconcile legacy schema through migration 00022 before upgrading'; END IF;";
 return `-- Generated from migration-order.json. No seeds. Review before applying.\nBEGIN;\nSET LOCAL lock_timeout='10s';\nSET LOCAL statement_timeout='120s';\nSELECT pg_advisory_xact_lock(71629348);\nDO $$ BEGIN ${check} IF to_regclass('public.kaza_admins') IS NOT NULL THEN RAISE EXCEPTION 'Security migration already applied; do not replay'; END IF; END $$;\n${sql.join('\n')}\nCOMMIT;\n`;
}
if(process.argv[1] && resolve(process.argv[1])===fileURLToPath(import.meta.url)) {
 const mode=process.argv[2];const sql=await migrationBundle(mode);
 const folder=new URL(mode==='upgrade'?'manual/':'generated/',root);await mkdir(folder,{recursive:true});
 const target=new URL(`kaza-${mode}.sql`,folder);await writeFile(target,sql);
 console.log(fileURLToPath(target));
}

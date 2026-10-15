import {type Row} from './content.ts';

// Import results per register key. Dub documents report their own state via
// refresh_source_status; a failed import marks the key degraded on top of it.
export const healthKey:Record<string,string>={anime2you:'anime2you',myanimelist:'tenrai',schedule:'tenrai',adn:'adn',adn_news:'adn'};

export function importHealth(report:Record<string,unknown>):Record<string,'ok'|'degraded'> {
  const health:Record<string,'ok'|'degraded'>={};
  for(const [name,key] of Object.entries(healthKey)){
    const r=report[name] as Row|undefined;
    if(!r||r.state==='blocked'||r.state==='permission_pending')continue;
    const failed=!!r.error||r.state==='degraded'||(Array.isArray(r.failed)&&r.failed.length>0);
    health[key]=failed||health[key]==='degraded'?'degraded':'ok';
  }
  return health;
}


start
  = (nl / s)* entries:entries (nl / s)* { return { entries }; }


nl
  = "\n\r" / "\r\n" / "\n" / "\r"

empty
  = nl nl+

s
  = ([ \t] / !empty nl)+

keyword
  = first:[a-zA-Z] rest:[a-zA-Z0-9-_.]* { return first + rest.join(''); }



entries
  = first:entry empty rest:entries { return [first].concat(rest); }
  / entry:entry { return [entry]; }

entry
  = headword:headword s? "(" s? cls:cls s? ")" s? dfs:dfs s? etym:etym { return { headword, dfs, cls, etym }; }
  / headword:headword s? "(" s? cls:cls s? ")" s? dfs:dfs { return { headword, dfs, cls }; }
  / headword:headword s? dfs:dfs s? etym:etym { return { headword, dfs, etym }; }
  / headword:headword s? dfs:dfs { return { headword, dfs }; }
  / text:text { return { text }; }

text
  = chars:(!(empty "{") char:. { return char; })* { return chars.join(''); }

headword
  = "{" pref:chars "[" base:chars "]" suff:chars key:key "}" { return { form: pref + base + suff, base, key: key || base }; }
  / "{" form:chars "|" base:chars key:key "}" { return { form, base, key: key || base }; }
  / "{" form:chars key:key "}" { return { form, base: form, key: key || form }; }

key
  = "#" chars:chars { return chars; }
  / "" { return null; }

chars
  = chars:(!special char:. { return char; })* { return chars.join(''); }

special
  = "{" / "}" / "[" / "]" / "|" / "#"

cls
  = first:keyword s? ',' s? rest:cls { return [first].concat(rest); }
  / cl:keyword { return [cl]; }

dfs
  = first:df s? rest:dfs { return [first].concat(rest); }
  / df:df { return [df]; }

df
  = rel:rel s? lang:keyword s term:term s? "(" s? comment:comment s? ")" { return { rel, lang, term, comment }; }
  / rel:rel s? lang:keyword s term:term { return { rel, lang, term }; }
  / "==" s? gram:keyword { return { gram }; }

rel
  = "<" { return 'hypernym'; }
  / ">" { return 'hyponym'; }
  / "=" { return 'synonym'; }
  / "%" { return 'plesionym'; }

term
  = term:(!(s? (empty / rel / "(" / "@")) char:. { return char; })* { return term.join(''); }

comment
  = chars:(!(s? ")") char:. { return char })* { return chars.join(''); }

etym
  = "@" s? source:keyword s? "(" s? comment:comment s? ")" s? { return { source, comment }; }
  / "@" s? source:keyword { return { source }; }

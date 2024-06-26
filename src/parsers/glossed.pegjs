
{
  const stored = {};
}

start
  = (nl / s)* blocks:blocks (nl / s)* { return { blocks }; }


nl
  = "\n\r" / "\r\n" / "\n" / "\r"

empty
  = nl nl+

s
  = ([ \t] / !empty nl)+

special
  = "[" / "]" / "|" / "{" / "}" / "&" / "+" / "#" / "*" / "<" / ">" / "/" / "@"

punct
  = "..." / "-" /  "," / "." / "!" / "?" / ":" / ";" / "„" / "“"

keyword
  = first:[a-zA-Z0-9] rest:[a-zA-Z0-9-_.]* { return first + rest.join(''); }

blocks
  = first:block rest:blocks { return (first ? [first].concat(rest) : rest); }
  / block:block { return (block ? [block] : []); }

block
  = (nl / s)* "{" (nl / s)* glossed:glossed (nl / s)* "}" (nl / s)* { return { glossed }; }
  / (nl / s)* "@" s? keyword:keyword s word:word (nl / s)* { stored[keyword] = word; return null; }
  / (nl / s)* text:text { return { text }; }

text
  = chars:( !((nl / s)* "{") char:. { return char; })+ { return chars.join(''); }

glossed
  = first:sentence empty s? rest:glossed { return [first].concat(rest); }
  / sentence:sentence { return [sentence]; }

sentence
  = first:chunk s? rest:sentence { return [first].concat(rest); }
  / chunk:chunk { return [chunk]; }

chunk
  = punct:punct { return { punct }; }
  / sandhi:sandhi { return { sandhi }; }
  / word:word { return { word }; }

word
  = construction:construction "#" refs:refs { return Object.assign({ refs }, construction); }
  / construction:construction "#" {
      let ref = "";
      const crawl = function(x) {
        if (x.prefix) { ref += x.prefix.form; }
        if (x.root) { ref += x.root.form; }
        if (x.base) { crawl(x.base); }
        if (x.base1) { crawl(x.base1); }
        if (x.infix) { ref += x.infix.form; }
        if (x.base2) { crawl(x.base2); }
        if (x.suffix) { ref += x.suffix.form; }
      }
      crawl(construction);
      return Object.assign({ refs: [ { key: ref } ] }, construction);
    }
  / construction:construction { return construction; }
  / "@" keyword:keyword { return stored[keyword]; }

construction
  = prefix:optmorph "[" base1:word "]" infix:optmorph "[" base2:word "]" suffix:optmorph {
      if (prefix && suffix || prefix && infix || infix && suffix) {
        const refs = (prefix || {}).refs || (infix || {}).refs || (suffix || {}).refs;
        let r = { base1, base2 };
        if (prefix) { r.prefix = Object.assign(prefix, { refs, continued: true }); }
        if (infix)  { r.infix  = Object.assign(infix,  { refs, continues: !!prefix, continued: !!suffix }); }
        if (suffix) { r.suffix = Object.assign(suffix, { refs, continues: true }); }
        return r;
      } else {
        return { prefix, base1, infix, base2, suffix };
      }
    }
  / prefix:optmorph "[" base:word "]" suffix:optmorph {
      if (prefix && suffix) {
        const refs = prefix.refs || suffix.refs;
        return {
          prefix: Object.assign(prefix, { refs, continued: true }),
          base,
          suffix: Object.assign(suffix, { refs, continues: true })
        };
      } else {
        return { prefix, base, suffix };
      }
    }
  / root:morph { return { root }; }

sandhi
  = s? "+" s?

morph
  = form:form "|" refs:refs { return { form, refs }; }
  / form:nonemptyform "*" subkey:nonemptyform { return { form, refs: [ { subkey, key: form } ] }; }
  / form:nonemptyform { return { form, refs: [ { key: form } ] }; }

optmorph
  = "<" submorphs:submorphs "#" refs:refs ">" { return { submorphs, refs }; }
  / "<" submorphs:submorphs ">" { return { submorphs }; }
  / morph:morph { return morph; }
  / "" { return null; }

submorphs
  = first:morph "/" rest:submorphs { return [first].concat(rest); }
  / morph:morph { return [morph]; }

form
  = chars:formchar* { return chars.join(''); }

nonemptyform
  = chars:formchar+ { return chars.join(''); }

formchar
  = !punct !special !empty !s char:. { return char; }


refs
  = first:mainref "&" refstail:refstail { return [first].concat(refstail); }
  / mainref:mainref { return [mainref]; }

refstail
  = gram:nonemptyform "&" rest:refstail { return [ { gram } ].concat(rest); }
  / gram:nonemptyform { return [ { gram } ]; }

mainref
  = key:nonemptyform "*" subkey:nonemptyform { return { key, subkey } }
  / key:nonemptyform { return { key } }


start
  = (nl / s)* blocks:blocks (nl / s)* { return { blocks }; }


nl
  = "\n\r" / "\r\n" / "\n" / "\r"

empty
  = nl nl+

s
  = ([ \t] / !empty nl)+

special
  = "[" / "]" / "|" / "{" / "}" / "&" / "+" / "#"

punct
  = "..." / "-" /  "," / "." / "!" / "?" / ":" / ";"

keyword
  = first:[a-zA-Z0-9] rest:[a-zA-Z0-9-_.]* { return first + rest.join(''); }

blocks
  = first:block rest:blocks { return [first].concat(rest); }
  / block:block { return [block]; }

block
  = (nl / s)* "{" (nl / s)* glossed:glossed (nl / s)* "}" (nl / s)* { return { glossed }; }
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
        if (x.suffix) { ref += x.suffix.form; }
      }
      crawl(construction);
      return Object.assign({ refs: [ref] }, construction);
    }
  / construction:construction { return construction; }

construction
  = prefix:optmorph "[" base1:word "]" infix:optmorph "[" base2:word "]" suffix:optmorph {
      if (prefix && suffix || prefix && infix || infix && suffix) {
        const refs = (prefix || {}).refs || (infix || {}).refs || (suffix || {}).refs;
        let r = { base1, base2 };
        if (prefix) { r.prefix = { form: prefix.form, refs, continued: true }; }
        if (infix)  { r.infix  = { form: infix.form,  refs, continues: !!prefix, continued: !!suffix }; }
        if (suffix) { r.suffix = { form: suffix.form, refs, continues: true }; }
        return r;
      } else {
        return { prefix, base1, infix, base2, suffix };
      }
    }
  / prefix:optmorph "[" base:word "]" suffix:optmorph {
      if (prefix && suffix) {
        const refs = prefix.refs || suffix.refs;
        return {
          prefix: { form: prefix.form, refs, continued: true },
          base,
          suffix: { form: suffix.form, refs, continues: true }
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
  / form:nonemptyform { return { form, refs: [form] }; }

optmorph
  = morph:morph { return morph; }
  / "" { return null; }

form
  = chars:formchar* { return chars.join(''); }

nonemptyform
  = chars:formchar+ { return chars.join(''); }

formchar
  = !punct !special !empty !s char:. { return char; }

refs
  = first:nonemptyform "&" rest:refs { return [first].concat(rest); }
  / form:nonemptyform { return [form]; }
